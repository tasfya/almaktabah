#!/usr/bin/env python3
"""
S3 Bulk Arabic Transcription Script
Transcribes every audio file under an S3 prefix using Whisper (large-v3, best
for Arabic) and writes a CSV mapping each S3 key to its local transcription
file. Useful for identifying unlabeled audio (unknown scholar/title) by
skimming the transcript text.

Uses the same Whisper backend logic as local_transcriber.py.

Setup:
  For Apple Silicon (recommended):
     pip install mlx-whisper boto3

  For NVIDIA GPU or CPU:
     pip install faster-whisper boto3

  AWS credentials are picked up from the normal AWS CLI chain (env vars,
  ~/.aws/credentials, profile, etc) - nothing extra to configure if
  `aws s3 ls` already works on this machine.

  Run:
     python s3_transcriber.py --bucket my-bucket [--prefix miraath/]

Optional environment variables:
  AWS_S3_BUCKET: default bucket if --bucket is not passed
  AWS_S3_PREFIX: default prefix (default: "miraath/")
  AWS_PROFILE: AWS CLI profile to use
  DOWNLOAD_DIR: where to store temp audio (default: ~/s3_transcription_downloads)
  OUTPUT_DIR: where transcription JSON files are written (default: ~/s3_transcriptions)
  OUTPUT_CSV: CSV manifest path (default: ./s3_transcriptions.csv)
  WHISPER_MODEL: model size (default: large-v3)
  WHISPER_BACKEND: mlx, faster-whisper, or auto (default: auto)
  TRANSCRIPTION_LIMIT: max items to process this run (default: unlimited)
"""

import argparse
import csv
import logging
import os
import platform
import sys
from pathlib import Path
from typing import Optional

import boto3

# Detect backend
WHISPER_BACKEND = os.environ.get("WHISPER_BACKEND", "auto")


def get_backend():
    """Determine which whisper backend to use"""
    if WHISPER_BACKEND != "auto":
        return WHISPER_BACKEND

    # On Apple Silicon, prefer mlx-whisper for GPU acceleration
    if platform.system() == "Darwin" and platform.machine() == "arm64":
        try:
            import mlx_whisper
            return "mlx"
        except ImportError:
            pass

    # Fall back to faster-whisper
    try:
        from faster_whisper import WhisperModel
        return "faster-whisper"
    except ImportError:
        pass

    raise ImportError("No whisper backend found. Install mlx-whisper (Apple Silicon) or faster-whisper")


BACKEND = get_backend()

# Configuration
DOWNLOAD_DIR = Path(os.environ.get("DOWNLOAD_DIR", Path.home() / "s3_transcription_downloads"))
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", Path.home() / "s3_transcriptions"))
OUTPUT_CSV = Path(os.environ.get("OUTPUT_CSV", "s3_transcriptions.csv"))
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "large-v3")
TRANSCRIPTION_LIMIT = int(os.environ.get("TRANSCRIPTION_LIMIT", "0")) or None

AUDIO_EXTENSIONS = {".mp3", ".m4a", ".wav", ".ogg", ".wma", ".aac", ".flac"}
CSV_FIELDS = ["s3_key", "status", "transcription_file", "duration_seconds", "language", "text_preview"]

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger(__name__)


class S3Transcriber:
    def __init__(self, bucket: str, prefix: str):
        self.bucket = bucket
        self.prefix = prefix

        DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

        self.model = None
        self.s3 = boto3.client("s3")
        self.done_keys = self.load_done_keys()

    def load_done_keys(self) -> set:
        """Read the CSV manifest (if any) so re-runs skip already-transcribed keys"""
        if not OUTPUT_CSV.exists():
            return set()

        done = set()
        with open(OUTPUT_CSV, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                if row.get("status") == "ok":
                    done.add(row["s3_key"])
        if done:
            logger.info(f"Resuming: {len(done)} keys already transcribed, will be skipped")
        return done

    def open_csv_writer(self):
        """Open the CSV manifest in append mode, writing the header if new"""
        is_new = not OUTPUT_CSV.exists()
        f = open(OUTPUT_CSV, "a", newline="", encoding="utf-8")
        writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
        if is_new:
            writer.writeheader()
            f.flush()
        return f, writer

    def load_model(self):
        """Load Whisper model (lazy loading to save memory)"""
        if self.model is not None:
            return

        logger.info(f"Loading Whisper model: {WHISPER_MODEL}")
        logger.info(f"Using backend: {BACKEND}")

        if BACKEND == "mlx":
            # MLX backend for Apple Silicon - uses GPU automatically
            import mlx_whisper
            self.model = "mlx"  # mlx_whisper uses model name directly in transcribe
            logger.info("Using MLX backend (Apple Silicon GPU)")
        else:
            # faster-whisper backend
            from faster_whisper import WhisperModel

            # Determine device
            try:
                import torch
                if torch.cuda.is_available():
                    device = "cuda"
                    compute_type = "float16"
                else:
                    device = "cpu"
                    compute_type = "int8"
            except ImportError:
                device = "cpu"
                compute_type = "int8"

            logger.info(f"Using device: {device}, compute_type: {compute_type}")

            self.model = WhisperModel(
                WHISPER_MODEL,
                device=device,
                compute_type=compute_type
            )

        logger.info("Model loaded successfully")

    def run(self):
        """Main run loop"""
        logger.info("Starting S3 transcription run...")
        logger.info(f"Bucket: {self.bucket}, prefix: {self.prefix}")
        logger.info(f"Model: {WHISPER_MODEL}")

        keys = self.list_audio_keys()
        pending = [k for k in keys if k not in self.done_keys]
        logger.info(f"Found {len(keys)} audio files ({len(pending)} pending)")

        if not pending:
            logger.info("Nothing to do")
            return

        if TRANSCRIPTION_LIMIT:
            pending = pending[:TRANSCRIPTION_LIMIT]
            logger.info(f"Limiting this run to {len(pending)} items")

        # Load model only when we have work to do
        self.load_model()

        csv_file, writer = self.open_csv_writer()
        try:
            for i, key in enumerate(pending):
                logger.info(f"[{i+1}/{len(pending)}] Processing: {key}")
                row = self.process_key(key)
                writer.writerow(row)
                csv_file.flush()
        finally:
            csv_file.close()

        logger.info("Transcription run complete!")
        logger.info(f"Manifest written to {OUTPUT_CSV}")

    def list_audio_keys(self) -> list:
        """List every audio object under the bucket/prefix"""
        keys = []
        paginator = self.s3.get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=self.bucket, Prefix=self.prefix):
            for obj in page.get("Contents", []):
                key = obj["Key"]
                if Path(key).suffix.lower() in AUDIO_EXTENSIONS:
                    keys.append(key)
        return keys

    def process_key(self, key: str) -> dict:
        """Download, transcribe, and save one S3 object. Returns a CSV row dict."""
        audio_path = self.download_object(key)
        if not audio_path:
            return {"s3_key": key, "status": "download_failed", "transcription_file": "",
                    "duration_seconds": "", "language": "", "text_preview": ""}

        try:
            transcription = self.transcribe(audio_path)
            if not transcription:
                return {"s3_key": key, "status": "transcription_failed", "transcription_file": "",
                        "duration_seconds": "", "language": "", "text_preview": ""}

            transcription_file = self.save_transcription(key, transcription)
            preview = transcription["text"][:200].replace("\n", " ").strip()

            return {
                "s3_key": key,
                "status": "ok",
                "transcription_file": str(transcription_file),
                "duration_seconds": round(transcription["duration"], 1),
                "language": transcription["language"],
                "text_preview": preview,
            }
        finally:
            if audio_path.exists():
                audio_path.unlink()

    def download_object(self, key: str) -> Optional[Path]:
        """Download an S3 object to DOWNLOAD_DIR"""
        logger.info("Downloading audio...")

        local_name = key.replace("/", "__")
        audio_path = DOWNLOAD_DIR / local_name

        try:
            self.s3.download_file(self.bucket, key, str(audio_path))
            size_mb = audio_path.stat().st_size / 1024 / 1024
            logger.info(f"Downloaded: {audio_path.name} ({size_mb:.2f} MB)")
            return audio_path
        except Exception as e:
            logger.error(f"Failed to download {key}: {e}")
            return None

    def transcribe(self, audio_path: Path) -> Optional[dict]:
        """Transcribe audio using Whisper"""
        logger.info("Transcribing with Whisper...")

        try:
            if BACKEND == "mlx":
                return self._transcribe_mlx(audio_path)
            else:
                return self._transcribe_faster_whisper(audio_path)
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            return None

    def _transcribe_mlx(self, audio_path: Path) -> Optional[dict]:
        """Transcribe using MLX backend (Apple Silicon)"""
        import mlx_whisper

        result = mlx_whisper.transcribe(
            str(audio_path),
            path_or_hf_repo=f"mlx-community/whisper-{WHISPER_MODEL}-mlx",
            language="ar",
            task="transcribe",
            word_timestamps=True,
        )

        result_segments = []
        full_text = []

        for segment in result.get("segments", []):
            result_segments.append({
                "start": round(segment["start"], 3),
                "end": round(segment["end"], 3),
                "text": segment["text"].strip()
            })
            full_text.append(segment["text"].strip())

        duration = result_segments[-1]["end"] if result_segments else 0

        transcription = {
            "text": " ".join(full_text),
            "segments": result_segments,
            "language": result.get("language", "ar"),
            "duration": duration
        }

        logger.info(f"Transcribed {len(result_segments)} segments, {duration:.1f}s duration")
        return transcription

    def _transcribe_faster_whisper(self, audio_path: Path) -> Optional[dict]:
        """Transcribe using faster-whisper backend"""
        segments, info = self.model.transcribe(
            str(audio_path),
            language="ar",
            task="transcribe",
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=500,
            ),
            word_timestamps=True,
            beam_size=5,
        )

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

    def save_transcription(self, key: str, transcription: dict) -> Path:
        """Write the transcription JSON to OUTPUT_DIR, mirroring the S3 key"""
        import json

        local_name = key.replace("/", "__")
        out_path = OUTPUT_DIR / f"{local_name}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(transcription, f, ensure_ascii=False, indent=2)
        return out_path


def main():
    parser = argparse.ArgumentParser(description="Bulk-transcribe audio from an S3 prefix")
    parser.add_argument("--bucket", default=os.environ.get("AWS_S3_BUCKET"),
                         help="S3 bucket name (or set AWS_S3_BUCKET)")
    parser.add_argument("--prefix", default=os.environ.get("AWS_S3_PREFIX", "miraath/"),
                         help="S3 prefix/folder to scan (default: miraath/)")
    args = parser.parse_args()

    if not args.bucket:
        parser.error("--bucket is required (or set AWS_S3_BUCKET)")

    try:
        transcriber = S3Transcriber(bucket=args.bucket, prefix=args.prefix)
        transcriber.run()
    except KeyboardInterrupt:
        logger.info("Interrupted by user - progress is saved in the CSV, re-run to resume")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
