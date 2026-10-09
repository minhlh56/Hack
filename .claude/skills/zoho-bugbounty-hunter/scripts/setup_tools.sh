#!/usr/bin/env bash
# setup_tools.sh — check for / install the open-source toolchain used by the
# zoho-bugbounty-hunter skill. Run --install INSIDE a disposable analysis box.
#
# Usage:
#   scripts/setup_tools.sh --check      # report what's present/missing
#   scripts/setup_tools.sh --install    # best-effort install via common managers
set -euo pipefail

# tool -> human hint for how to get it
declare -A TOOLS=(
  [7z]="p7zip / 7-Zip (installer & archive extraction)"
  [unzip]="unzip (archive extraction)"
  [java]="JRE/JDK (runs CFR/Procyon/Fernflower)"
  [jadx]="jadx (Java/APK decompiler) https://github.com/skylot/jadx"
  [semgrep]="semgrep (SAST) pip install semgrep"
  [trufflehog]="trufflehog (secret scanning) https://github.com/trufflesecurity/trufflehog"
  [nmap]="nmap (local lab port mapping)"
  [httpx]="projectdiscovery httpx (web probing)"
  [subfinder]="projectdiscovery subfinder (passive subdomains)"
  [nuclei]="projectdiscovery nuclei (template checks — validate, never spray prod)"
  [mitmproxy]="mitmproxy (intercept/replay)"
  [codeql]="CodeQL CLI (deep taint analysis) https://github.com/github/codeql-cli-binaries"
  [ilspycmd]="ILSpy CLI (.NET decompiler) dotnet tool install -g ilspycmd"
)

# Standalone JARs the skill expects under $TOOLS_DIR (set or default ~/.bb-tools)
TOOLS_DIR="${BB_TOOLS_DIR:-$HOME/.bb-tools}"
declare -A JARS=(
  [cfr.jar]="https://github.com/leibnitz27/cfr/releases (CFR decompiler)"
  [procyon.jar]="https://github.com/mstrobel/procyon/releases (Procyon decompiler)"
  [fernflower.jar]="build from IntelliJ community / https://github.com/fesh0r/fernflower"
)

have() { command -v "$1" >/dev/null 2>&1; }

check() {
  echo "== CLI tools =="
  for t in "${!TOOLS[@]}"; do
    if have "$t"; then printf "  [ok]   %-12s\n" "$t"
    else printf "  [MISS] %-12s -> %s\n" "$t" "${TOOLS[$t]}"; fi
  done | sort
  echo "== Decompiler JARs (in $TOOLS_DIR) =="
  for j in "${!JARS[@]}"; do
    if [ -f "$TOOLS_DIR/$j" ]; then printf "  [ok]   %-16s\n" "$j"
    else printf "  [MISS] %-16s -> %s\n" "$j" "${JARS[$j]}"; fi
  done | sort
  echo
  echo "Install missing CLI tools with your package manager / the hints above,"
  echo "and drop the decompiler JARs into: $TOOLS_DIR"
}

install() {
  echo "[*] Best-effort install. Review before running on a host you care about."
  mkdir -p "$TOOLS_DIR"
  if have apt-get; then
    sudo apt-get update
    sudo apt-get install -y p7zip-full unzip default-jre nmap python3-pip || true
  elif have brew; then
    brew install p7zip unzip openjdk nmap || true
  elif have dnf; then
    sudo dnf install -y p7zip unzip java-latest-openjdk nmap python3-pip || true
  fi
  have pip3 && pip3 install --user semgrep mitmproxy || true
  echo "[*] projectdiscovery tools (httpx/subfinder/nuclei): install via 'go install' or release binaries."
  echo "[*] jadx / CodeQL / ilspycmd / decompiler JARs: fetch from the URLs in --check."
  check
}

case "${1:---check}" in
  --check) check ;;
  --install) install ;;
  *) echo "usage: $0 [--check|--install]"; exit 2 ;;
esac
