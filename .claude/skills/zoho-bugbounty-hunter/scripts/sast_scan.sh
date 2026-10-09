#!/usr/bin/env bash
# sast_scan.sh — offline static analysis over decompiled/extracted source.
# Runs: secret grep (+trufflehog if present), a dangerous-sink grep pass, and
# Semgrep rulesets if installed. Output is a set of LEADS to validate in Gate 6,
# not findings — the Zoho VRP requires a working PoC.
#
# Usage: sast_scan.sh <src-dir> <out-dir>
#
# SAFETY: runs entirely LOCALLY. Never upload the vendor's source to a SaaS
# analyzer. Reads files only; executes nothing from the source tree.
set -euo pipefail

SRC="${1:?usage: sast_scan.sh <src-dir> <out-dir>}"
OUT="${2:?usage: sast_scan.sh <src-dir> <out-dir>}"
mkdir -p "$OUT"
g() { grep -rniE --include=*.{java,jsp,js,xml,properties,conf,json} "$1" "$SRC" 2>/dev/null; }

echo "[*] 1/4 secrets"
{
  g 'password|passwd|secret|api[_-]?key|access[_-]?key|token|private_key|aws_(secret|access)' || true
} > "$OUT/secrets-grep.txt"
if command -v trufflehog >/dev/null 2>&1; then
  trufflehog filesystem "$SRC" --no-update --json > "$OUT/trufflehog.json" 2>/dev/null || true
fi
echo "    -> $OUT/secrets-grep.txt ($(wc -l < "$OUT/secrets-grep.txt") hits)"

echo "[*] 2/4 dangerous sinks"
{
  echo "### command execution";      g 'Runtime\.getRuntime\(\)\.exec|new ProcessBuilder'
  echo "### sql (string-built)";      g 'createStatement\(|Statement .*execute|"\s*\+\s*.*(select|insert|update|delete)'
  echo "### deserialization";         g 'ObjectInputStream|readObject|XMLDecoder|XStream|readUnshared|SerializationUtils\.deserialize'
  echo "### xxe";                      g 'DocumentBuilderFactory|SAXParserFactory|XMLInputFactory|TransformerFactory|SAXReader'
  echo "### ssrf";                     g 'new URL\(|HttpURLConnection|RestTemplate|WebClient|OkHttpClient|HttpClients?\.'
  echo "### path / file / upload";     g 'new File\(|Files\.(copy|write|newOutputStream)|getRealPath|MultipartFile'
  echo "### ssti / expression";        g 'freemarker|velocity|SpelExpressionParser|ScriptEngine|OgnlUtil|Thymeleaf'
  echo "### auth bypass smells";       g 'skipAuth|bypass|isAdmin|DISABLE_AUTH|debug\s*=\s*true|== *null'
} > "$OUT/sinks.txt"
echo "    -> $OUT/sinks.txt ($(grep -cvE '^###|^$' "$OUT/sinks.txt") hits)"

echo "[*] 3/4 endpoints (where attacker input enters)"
grep -rniE '@(Request|Get|Post|Put|Delete)Mapping|extends HttpServlet|<servlet-mapping>|<url-pattern>' \
     "$SRC" 2>/dev/null > "$OUT/endpoints.txt" || true
echo "    -> $OUT/endpoints.txt ($(wc -l < "$OUT/endpoints.txt") hits)"

echo "[*] 4/4 semgrep"
if command -v semgrep >/dev/null 2>&1; then
  semgrep --quiet --config p/java --config p/secrets --config p/owasp-top-ten \
          --config p/command-injection --sarif -o "$OUT/semgrep.sarif" "$SRC" \
          2>"$OUT/semgrep.log" || echo "    [!] semgrep exited non-zero; see $OUT/semgrep.log"
  echo "    -> $OUT/semgrep.sarif"
else
  echo "    [skip] semgrep not installed (pip install semgrep)"
fi

cat <<EOF

[*] SAST pass complete. These are LEADS, not findings.
    Next (references/05-sast.md): for each pre-auth-reachable endpoint, trace
    request params to a sink, drop Gate 0 out-of-scope classes, then validate a
    working PoC against your LAB instance in Gate 6.
EOF
