#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$ROOT}"
mkdir -p "$OUT" /tmp/chrome-pdf-build

print_pdf() {
  local html="$1"
  local pdf="$2"
  local udir
  udir="$(mktemp -d /tmp/chrome-pdf-build/run.XXXXXX)"
  google-chrome --headless --disable-gpu --no-pdf-header-footer \
    --user-data-dir="$udir" \
    --print-to-pdf="$pdf" "file://$html" >/tmp/chrome-pdf-build/last.log 2>&1 &
  local pid=$!
  for _ in $(seq 1 40); do
    if [[ -f "$pdf" ]] && [[ -s "$pdf" ]]; then
      # wait a moment for write to finish
      sleep 1
      if grep -q "bytes written" /tmp/chrome-pdf-build/last.log 2>/dev/null || [[ -s "$pdf" ]]; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        return 0
      fi
    fi
    sleep 0.5
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  [[ -s "$pdf" ]]
}

print_pdf "$ROOT/cv.html" "$OUT/Ioannis_Gander_CV_LizardIsland.pdf"
print_pdf "$ROOT/cover-letter.html" "$OUT/Ioannis_Gander_CoverLetter_LizardIsland.pdf"
echo "Wrote PDFs to $OUT"
