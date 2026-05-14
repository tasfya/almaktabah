#!/usr/bin/env python3
"""
Local Arabic Transcription Script
Transcribes audio using faster-whisper with large-v3 model (best for Arabic)

Setup:
  1. Install dependencies:
     pip install faster-whisper requests

  2. Set environment variables:
     export ALMAKTABAH_SERVER_URL="https://3ilm.org"
     export ALMAKTABAH_API_TOKEN="your-secret-token"

  3. Run:
     python local_transcriber.py

Optional environment variables:
  DOWNLOAD_DIR: Where to store temp audio (default: ~/transcription_downloads)
  TRANSCRIPTION_LIMIT: Max items per run (default: 5)
  WHISPER_MODEL: Model size (default: large-v3)
  WHISPER_DEVICE: cpu, cuda, or auto (default: auto)
  RESOURCE_TYPE: Lecture, Lesson, or Fatwa (default: all)
"""

import os
import sys
import json
import logging
import tempfile
from pathlib import Path
from typing import Optional

import requests
from faster_whisper import WhisperModel

# Configuration
SERVER_URL = os.environ.get("ALMAKTABAH_SERVER_URL", "https://3ilm.org")
API_TOKEN = os.environ.get("ALMAKTABAH_API_TOKEN")
DOWNLOAD_DIR = Path(os.environ.get("DOWNLOAD_DIR", Path.home() / "transcription_downloads"))
TRANSCRIPTION_LIMIT = int(os.environ.get("TRANSCRIPTION_LIMIT", "5"))
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "large-v3")
WHISPER_DEVICE = os.environ.get("WHISPER_DEVICE", "auto")
RESOURCE_TYPE = os.environ.get("RESOURCE_TYPE", "")  # empty = all types

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger(__name__)


class LocalTranscriber:
    def __init__(self):
        if not API_TOKEN:
            raise ValueError("ALMAKTABAH_API_TOKEN environment variable not set")

        DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
        self.model: Optional[WhisperModel] = None
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {API_TOKEN}",
            "Content-Type": "application/json"
        })

    def load_model(self):
        """Load Whisper model (lazy loading to save memory)"""
        if self.model is not None:
            return

        logger.info(f"Loading Whisper model: {WHISPER_MODEL}")

        # Determine compute type based on device
        device = WHISPER_DEVICE
        if device == "auto":
            # Check for Apple Silicon MPS or CUDA
            try:
                import torch
                if torch.backends.mps.is_available():
                    device = "cpu"  # faster-whisper doesn't support MPS directly, but uses optimized CPU
                    compute_type = "int8"
                elif torch.cuda.is_available():
                    device = "cuda"
                    compute_type = "float16"
                else:
                    device = "cpu"
                    compute_type = "int8"
            except ImportError:
                device = "cpu"
                compute_type = "int8"
        else:
            compute_type = "float16" if device == "cuda" else "int8"

        logger.info(f"Using device: {device}, compute_type: {compute_type}")

        self.model = WhisperModel(
            WHISPER_MODEL,
            device=device,
            compute_type=compute_type
        )
        logger.info("Model loaded successfully")

    def run(self):
        """Main run loop"""
        logger.info("Starting transcription run...")
        logger.info(f"Server: {SERVER_URL}")
        logger.info(f"Model: {WHISPER_MODEL}")

        pending = self.fetch_pending()
        if not pending:
            logger.info("No pending transcriptions")
            return

        logger.info(f"Found {len(pending)} items to transcribe")

        # Load model only when we have work to do
        self.load_model()

        for i, item in enumerate(pending):
            logger.info(f"[{i+1}/{len(pending)}] Processing: {item['title']}")
            try:
                self.process_item(item)
            except Exception as e:
                logger.error(f"Failed to process {item['type']}#{item['id']}: {e}")
                continue

        logger.info("Transcription run complete!")

    def fetch_pending(self) -> list:
        """Fetch pending transcriptions from server"""
        url = f"{SERVER_URL}/api/transcriptions/pending"
        params = {"limit": TRANSCRIPTION_LIMIT}
        if RESOURCE_TYPE:
            params["type"] = RESOURCE_TYPE

        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json().get("pending", [])
        except Exception as e:
            logger.error(f"Failed to fetch pending transcriptions: {e}")
            return []

    def process_item(self, item: dict):
        """Process a single item: download, transcribe, upload"""
        item_id = item["id"]
        item_type = item["type"]
        audio_url = item["audio_url"]

        # Download audio
        audio_path = self.download_audio(audio_url, item_type, item_id)
        if not audio_path:
            return

        try:
            # Transcribe
            transcription = self.transcribe(audio_path)
            if not transcription:
                return

            # Upload
            self.upload_transcription(item_type, item_id, transcription)
        finally:
            # Cleanup
            if audio_path.exists():
                audio_path.unlink()

    def download_audio(self, url: str, item_type: str, item_id: int) -> Optional[Path]:
        """Download audio file from server"""
        logger.info(f"Downloading audio...")

        try:
            response = self.session.get(url, stream=True, timeout=300)
            response.raise_for_status()

            # Get extension from content-type or URL
            content_type = response.headers.get("content-type", "")
            if "mp3" in content_type or url.endswith(".mp3"):
                ext = ".mp3"
            elif "mp4" in content_type or "m4a" in content_type:
                ext = ".m4a"
            elif "wav" in content_type:
                ext = ".wav"
            else:
                ext = ".mp3"

            audio_path = DOWNLOAD_DIR / f"{item_type.lower()}_{item_id}{ext}"

            with open(audio_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            size_mb = audio_path.stat().st_size / 1024 / 1024
            logger.info(f"Downloaded: {audio_path.name} ({size_mb:.2f} MB)")
            return audio_path

        except Exception as e:
            logger.error(f"Failed to download audio: {e}")
            return None

    def transcribe(self, audio_path: Path) -> Optional[dict]:
        """Transcribe audio using Whisper"""
        logger.info("Transcribing with Whisper...")

        try:
            segments, info = self.model.transcribe(
                str(audio_path),
                language="ar",
                task="transcribe",
                vad_filter=True,  # Filter out silence
                vad_parameters=dict(
                    min_silence_duration_ms=500,
                ),
                word_timestamps=True,
                beam_size=5,
            )

            # Convert to our format
            result_segments = []
            full_text = []

            for segment in segments:
                result_segments.append({
                    "start": round(segment.start, 3),
                    "end": round(segment.end, 3),
                    "text": segment.text.strip()
                })
                full_text.append(segment.text.strip())

            transcription = {
                "text": " ".join(full_text),
                "segments": result_segments,
                "language": info.language,
                "duration": info.duration
            }

            logger.info(f"Transcribed {len(result_segments)} segments, {info.duration:.1f}s duration")
            return transcription

        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            return None

    def upload_transcription(self, item_type: str, item_id: int, transcription: dict):
        """Upload transcription to server"""
        logger.info("Uploading transcription...")

        url = f"{SERVER_URL}/api/transcriptions/{item_type}/{item_id}/upload"

        try:
            response = self.session.post(
                url,
                json={"transcription_json": json.dumps(transcription, ensure_ascii=False)},
                timeout=60
            )
            response.raise_for_status()
            logger.info(f"Upload successful for {item_type}#{item_id}")
        except Exception as e:
            logger.error(f"Failed to upload transcription: {e}")


def main():
    try:
        transcriber = LocalTranscriber()
        transcriber.run()
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
