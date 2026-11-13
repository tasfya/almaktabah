#!/usr/bin/env bash
# Downloads the audio and PDF files named in an import manifest with tdl, as
# <out_dir>/<message_id>_<original name>, then checks every expected file.
#
#   scripts/telegram/download_mtoon_media.sh <manifest.json> <out_dir> [text_key ...]
#
# With no text keys, every text in the manifest is downloaded. Needs a logged-in
# tdl session, jq, ffprobe and pdfinfo. Exits 1 if any file is missing or broken.
set -euo pipefail

manifest=${1:?manifest path}
out_dir=${2:?output directory}
shift 2
channel=$(jq -r '.source | sub("^t.me/"; "")' "$manifest")
keys_json=$(printf '%s\n' "$@" | jq -R . | jq -s 'map(select(length > 0))')

files=$(jq -r --argjson keys "$keys_json" '
  .texts[] | select(($keys | length) == 0 or (.key as $k | $keys | index($k)))
  | (.lessons[] | "\(.audio_message_id)\t\(.audio_file)"), "\(.matn.message_id)\t\(.matn.file)",
    (.transcripts[] | "\(.message_id)\t\(.file)")
' "$manifest")
if [[ -z "$files" ]]; then
  echo "no files selected: check the text keys ($*) against the manifest" >&2
  exit 1
fi

mkdir -p "$out_dir"
urls=()
while IFS=$'\t' read -r id _; do urls+=(-u "https://t.me/$channel/$id"); done <<<"$files"
tdl dl "${urls[@]}" -d "$out_dir" --template '{{ .MessageID }}_{{ .FileName }}' --skip-same

missing=0
while IFS=$'\t' read -r id name; do
  file="$out_dir/${id}_${name}"
  if [[ ! -s "$file" ]]; then
    echo "missing: ${id}_${name}" >&2; missing=1; continue
  fi
  case "$file" in
    *.mp3|*.MP3) ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" >/dev/null || { echo "unreadable audio: $file" >&2; missing=1; } ;;
    *.pdf|*.PDF) pdfinfo "$file" >/dev/null 2>&1 || { echo "unreadable pdf: $file" >&2; missing=1; } ;;
  esac
done <<<"$files"
echo "$(wc -l <<<"$files") files expected in $out_dir"
exit $missing
