#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: bash load_docker_release.sh [MANIFEST.sha256 | LEGACY-ARCHIVE.tar.gz]"
  echo "Keep the manifest and all its .part-* files together. No reassembled file is created."
  [[ $# -le 1 ]] && exit 0
  exit 1
fi

if [[ $# -eq 0 ]]; then
  case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64) arch=x86_64 ;;
    *) echo "Unsupported host architecture; provide a manifest path." >&2; exit 1 ;;
  esac
  input="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/FinAgent-Docker-${arch}.tar.gz.sha256"
  if [[ ! -f "$input" && -f "${input%.sha256}" ]]; then
    input="${input%.sha256}"
  fi
else
  input="$1"
fi

[[ -f "$input" ]] || { echo "Release manifest/archive not found: $input" >&2; exit 1; }
command -v docker >/dev/null || { echo "Docker is required." >&2; exit 1; }
case "$input" in
  *.tar.gz) exec docker load --input "$input" ;;
  *.sha256) ;;
  *) echo "Expected a .tar.gz.sha256 manifest or legacy .tar.gz archive." >&2; exit 1 ;;
esac

directory="$(cd "$(dirname "$input")" && pwd)"
archive="$(basename "${input%.sha256}")"
case "$archive" in
  FinAgent-Docker-x86_64.tar.gz|FinAgent-Docker-arm64.tar.gz) ;;
  *) echo "Unrecognized manifest name: $input" >&2; exit 1 ;;
esac
if command -v sha256sum >/dev/null; then
  hash_command=(sha256sum)
elif command -v shasum >/dev/null; then
  hash_command=(shasum -a 256)
else
  echo "sha256sum or shasum is required to verify the download." >&2
  exit 1
fi

parts=()
index=1
pattern='^([0-9a-f]{64})  (.+)$'
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ $pattern ]] || { echo "Invalid checksum manifest entry." >&2; exit 1; }
  digest="${BASH_REMATCH[1]}"
  name="${BASH_REMATCH[2]}"
  printf -v expected '%s.part-%06d' "$archive" "$index"
  [[ "$name" == "$expected" ]] || { echo "Unexpected or out-of-order part: $name" >&2; exit 1; }
  part="$directory/$name"
  [[ -f "$part" && ! -L "$part" ]] || { echo "Missing part (or symlink): $name" >&2; exit 1; }
  actual="$("${hash_command[@]}" "$part")"
  [[ "${actual%% *}" == "$digest" ]] || { echo "Checksum mismatch: $name" >&2; exit 1; }
  parts+=("$part")
  index=$((index + 1))
done < "$input"
[[ "$index" -gt 1 ]] || { echo "The checksum manifest is empty." >&2; exit 1; }

echo "Checksums verified. Checking the complete compressed archive..."
cat -- "${parts[@]}" | gzip -t
echo "Loading Docker image without creating a combined archive..."
cat -- "${parts[@]}" | docker load
