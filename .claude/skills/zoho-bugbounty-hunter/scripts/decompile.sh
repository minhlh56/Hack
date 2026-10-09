#!/usr/bin/env bash
# decompile.sh — batch-decompile every JAR/WAR found under <input-dir> into
# readable Java source under <output-dir>. Prefers jadx; falls back to CFR, then
# Procyon (decompiler JARs live in $BB_TOOLS_DIR, default ~/.bb-tools).
#
# Usage: decompile.sh <input-dir> <output-dir> [--only <pkg-substr>]
#
# SAFETY: produces source for READING/SCANNING only. Do not execute it or run
# build tools from the output tree. Third-party libs are skipped by default to
# focus on the vendor's own code (set BB_INCLUDE_LIBS=1 to include them).
set -euo pipefail

IN="${1:?usage: decompile.sh <input-dir> <output-dir> [--only <substr>]}"
OUT="${2:?usage: decompile.sh <input-dir> <output-dir> [--only <substr>]}"
ONLY=""
[ "${3:-}" = "--only" ] && ONLY="${4:-}"
TOOLS_DIR="${BB_TOOLS_DIR:-$HOME/.bb-tools}"
mkdir -p "$OUT"

# Skip obvious third-party libraries unless asked to include them.
skip_lib() {
  [ "${BB_INCLUDE_LIBS:-0}" = "1" ] && return 1
  case "$(basename "$1")" in
    spring-*|log4j*|slf4j*|jackson-*|gson-*|guava-*|commons-*|netty-*|tomcat-*|\
    hibernate-*|xml-*|jaxb-*|bcprov-*|junit-*|mysql-*|postgresql-*|h2-*) return 0 ;;
    *) return 1 ;;
  esac
}

decompile_one() {
  local jar="$1" dest="$2"
  mkdir -p "$dest"
  if command -v jadx >/dev/null 2>&1; then
    jadx -q -d "$dest" "$jar" >/dev/null 2>&1 && return 0
  fi
  if [ -f "$TOOLS_DIR/cfr.jar" ]; then
    java -Xmx4g -jar "$TOOLS_DIR/cfr.jar" "$jar" --outputdir "$dest" >/dev/null 2>&1 && return 0
  fi
  if [ -f "$TOOLS_DIR/procyon.jar" ]; then
    java -Xmx4g -jar "$TOOLS_DIR/procyon.jar" "$jar" -o "$dest" >/dev/null 2>&1 && return 0
  fi
  echo "    [!] no working decompiler for $jar (need jadx, or cfr.jar/procyon.jar in $TOOLS_DIR)" >&2
  return 1
}

count=0; ok=0
while IFS= read -r -d '' jar; do
  if [ -n "$ONLY" ] && ! echo "$jar" | grep -qi "$ONLY"; then continue; fi
  if skip_lib "$jar"; then continue; fi
  count=$((count+1))
  rel="$(basename "${jar%.*}")"
  echo "[*] decompiling: $jar"
  if decompile_one "$jar" "$OUT/$rel"; then ok=$((ok+1)); fi
done < <(find "$IN" -type f \( -iname '*.jar' -o -iname '*.war' \) -print0)

echo "[*] decompiled $ok/$count archive(s) into $OUT"
echo "[*] endpoint/handler map:"
grep -rilE '@(Request|Get|Post|Put|Delete)Mapping|extends HttpServlet|<servlet-mapping>|struts' \
     "$OUT" 2>/dev/null | tee "$OUT/_endpoint-files.txt" | head -20 || true
echo "[*] next: $(dirname "$0")/sast_scan.sh \"$OUT\" <sast-out-dir>"
