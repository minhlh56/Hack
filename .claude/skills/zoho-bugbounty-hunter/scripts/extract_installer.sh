#!/usr/bin/env bash
# extract_installer.sh — unpack a ManageEngine/Zoho installer (.exe/.bin) or an
# archive into a quarantined output dir. InstallAnywhere installers are ZIP
# archives behind a native launcher stub; this tries the robust extractors first,
# then falls back to scanning for the ZIP (PK) signature at an offset.
#
# Usage: extract_installer.sh <installer-or-archive> <output-dir>
#
# SAFETY: this only *extracts*. It never executes the installer. Output is
# untrusted third-party code — read/scan it, don't run it, and don't run build
# tools from inside it.
set -euo pipefail

SRC="${1:?usage: extract_installer.sh <installer> <output-dir>}"
OUT="${2:?usage: extract_installer.sh <installer> <output-dir>}"
[ -f "$SRC" ] || { echo "no such file: $SRC" >&2; exit 1; }
mkdir -p "$OUT"

echo "[*] input : $SRC"
echo "[*] output: $OUT"
echo "[*] type  : $(file -b "$SRC" 2>/dev/null || echo unknown)"
sha256sum "$SRC" 2>/dev/null || shasum -a 256 "$SRC" 2>/dev/null || true

try_7z()    { command -v 7z   >/dev/null 2>&1 && 7z x -y -o"$OUT" "$SRC" >/dev/null 2>&1; }
try_unzip() { command -v unzip>/dev/null 2>&1 && unzip -o -q "$SRC" -d "$OUT" >/dev/null 2>&1; }
try_tar()   { tar xf "$SRC" -C "$OUT" >/dev/null 2>&1; }

# 1) direct extractors
if try_7z;    then echo "[ok] extracted with 7z"; FOUND=1
elif try_unzip; then echo "[ok] extracted with unzip"; FOUND=1
elif try_tar;   then echo "[ok] extracted with tar"; FOUND=1
else FOUND=0; fi

# 2) offset fallback: find the embedded ZIP central directory / local header
if [ "${FOUND:-0}" -ne 1 ]; then
  echo "[*] direct extraction failed; scanning for embedded ZIP (PK\\x03\\x04)…"
  # byte offset of first local-file-header signature
  OFF=$(grep -aboF $'PK\x03\x04' "$SRC" | head -1 | cut -d: -f1 || true)
  if [ -n "${OFF:-}" ]; then
    echo "[*] ZIP data appears at offset $OFF; carving…"
    CARVED="$OUT/_carved.zip"
    dd if="$SRC" of="$CARVED" bs=1 skip="$OFF" status=none
    if command -v 7z >/dev/null 2>&1; then 7z x -y -o"$OUT" "$CARVED" >/dev/null 2>&1 && FOUND=1
    elif command -v unzip >/dev/null 2>&1; then unzip -o -q "$CARVED" -d "$OUT" >/dev/null 2>&1 && FOUND=1; fi
    [ "${FOUND:-0}" -eq 1 ] && echo "[ok] extracted carved ZIP" && rm -f "$CARVED"
  fi
fi

if [ "${FOUND:-0}" -ne 1 ]; then
  cat >&2 <<EOF
[!] Could not extract directly. Fallbacks:
    - Open the file in 7-Zip/Total Commander GUI (handles odd stubs).
    - Run a SILENT INSTALL inside the Gate 3 isolated VM, then copy the deployed
      tree (lib/, conf/, webapps/, bin/) off disk — see references/04-decompilation.md.
EOF
  exit 3
fi

echo "[*] inventory of interesting artifacts:"
echo "    JAR/WAR:"; find "$OUT" -type f \( -iname '*.jar' -o -iname '*.war' \) | head -40
echo "    configs:"; find "$OUT" -type f \( -iname '*.properties' -o -iname '*.xml' -o -iname '*.conf' \) | head -40
echo "[*] next: scripts/decompile.sh \"$OUT\" <src-out-dir>"
