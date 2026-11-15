#!/usr/bin/env bash
# Build one MonkeyThrive expansion pack from a folder of classical recordings.
#
# Usage:
#   tools/build_expansion.sh SOURCE_DIR PACK_NAME [OUTPUT_DIR]
#
# Example:
#   tools/build_expansion.sh ~/music/satie satie_expansion
#
# Each audio file is converted to 96 kbps Ogg Vorbis. The source sample rate
# is kept, so the low end is not resampled away. A manifest.json is written
# beside the new files. An existing manifest keeps composer, title,
# movement, key, and bpm already filled in for that filename. The ogg files
# and the manifest are zipped at the top level of PACK_NAME.zip. The
# manifest is a list of track objects.
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: tools/build_expansion.sh SOURCE_DIR PACK_NAME [OUTPUT_DIR]" >&2
  exit 2
fi

source_dir=$1
pack_name=$2
output_dir=${3:-"$PWD/dist/expansions"}

if [[ ! $pack_name =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$ ]]; then
  echo "PACK_NAME must be letters, numbers, _ or -, and start with a letter or number." >&2
  exit 2
fi

if [[ ! -d $source_dir ]]; then
  echo "source directory not found: $source_dir" >&2
  exit 2
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required." >&2
  exit 1
fi

staging="$output_dir/$pack_name"
mkdir -p "$staging"

shopt -s nullglob
sources=()
while IFS= read -r -d '' path; do
  sources+=("$path")
done < <(find "$source_dir" -maxdepth 1 -xtype f \( \
  -iname '*.mp3' -o -iname '*.wav' -o -iname '*.flac' -o \
  -iname '*.aif' -o -iname '*.aiff' -o -iname '*.ogg' -o \
  -iname '*.m4a' -o -iname '*.opus' \) -print0 | sort -z)

if [[ ${#sources[@]} -eq 0 ]]; then
  echo "no audio files in $source_dir" >&2
  exit 1
fi

ogg_names=()
for src in "${sources[@]}"; do
  base=$(basename "$src")
  stem=${base%.*}
  if [[ ! $stem =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]]; then
    echo "skipping unsafe filename: $base" >&2
    exit 1
  fi
  dest="$staging/$stem.ogg"
  echo "encode $base"
  ffmpeg -y -hide_banner -loglevel error \
    -i "$src" -vn -map_metadata -1 \
    -c:a libvorbis -b:a 96k \
    "$dest"
  ogg_names+=("$stem.ogg")
done

python3 - "$staging" "$output_dir/$pack_name.zip" "${ogg_names[@]}" <<'PY'
import json
import sys
import zipfile
from pathlib import Path

staging = Path(sys.argv[1])
zip_path = Path(sys.argv[2])
names = sys.argv[3:]
manifest_path = staging / "manifest.json"
previous = {}
if manifest_path.is_file():
    try:
        loaded = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        loaded = None
    rows = []
    if isinstance(loaded, dict):
        rows = [
            {"file": name, **entry}
            for name, entry in loaded.items()
            if isinstance(entry, dict)
        ]
    elif isinstance(loaded, list):
        rows = [entry for entry in loaded if isinstance(entry, dict)]
    for entry in rows:
        filename = entry.get("file")
        if isinstance(filename, str):
            previous[filename] = entry

manifest = []
for name in names:
    entry = previous.get(name)
    if not isinstance(entry, dict):
        entry = {}
    key = ""
    bpm = 0
    raw_key = entry.get("key")
    raw_bpm = entry.get("bpm")
    if isinstance(raw_key, str):
        key = raw_key
    if isinstance(raw_bpm, bool):
        bpm = 0
    elif isinstance(raw_bpm, int) and raw_bpm >= 0:
        bpm = raw_bpm
    elif isinstance(raw_bpm, float) and raw_bpm >= 0 and raw_bpm.is_integer():
        bpm = int(raw_bpm)
    item = {"file": name}
    for field in ("composer", "title", "movement"):
        raw = entry.get(field)
        if isinstance(raw, str) and raw:
            item[field] = raw
    item["key"] = key
    item["bpm"] = bpm
    manifest.append(item)

manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for name in names:
        archive.write(staging / name, arcname=name)
    archive.write(manifest_path, arcname="manifest.json")
print(zip_path)
PY
