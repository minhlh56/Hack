# Gate 5 — Static Analysis (SAST) over extracted source

Audit the quarantined `src/` from Gate 4. Goal: a ranked list of **candidate**
vulnerabilities with a concrete source→sink hypothesis each. Static findings are
leads, not reports — the program requires a working PoC, which Gate 6 produces.

Driver: `scripts/sast_scan.sh engagements/<product>-<date>/src engagements/<product>-<date>/sast`

> Run all scanners **offline** against local files. Do not upload the vendor's
> source to any third-party SaaS analyzer.

## 5.1 Secrets & default credentials

```bash
trufflehog filesystem src/ --only-verified --json > sast/secrets.json
grep -rniE 'password|passwd|secret|api[_-]?key|token|aws_|private_key' \
     src/ --include=*.{java,xml,properties,conf,json,js} | head -200 > sast/secret-grep.txt
```

Look for: hardcoded admin creds, default DB passwords in `*.properties`, signing
keys, shared HMAC secrets used across installs (a classic on-prem issue — same
key in every customer's build). A static default secret is only reportable if you
can show it yields a real, working attack on the latest version (Gate 6).

## 5.2 Dangerous-sink grep (fast first pass)

Map user-reachable input to dangerous sinks. Prioritize sinks reachable
**pre-authentication** (cross-reference the endpoint map from Gate 4).

```bash
# Command execution
grep -rniE 'Runtime\.getRuntime\(\)\.exec|ProcessBuilder|getRuntime\(\).exec' src/
# SQL injection (string-built queries)
grep -rniE 'createStatement\(\)|Statement\s|"\s*\+\s*.*(select|insert|update|delete)' src/
# Deserialization (CWE-502)
grep -rniE 'ObjectInputStream|readObject|XMLDecoder|XStream|readUnshared|SerializationUtils\.deserialize' src/
# XXE
grep -rniE 'DocumentBuilderFactory|SAXParserFactory|XMLInputFactory|TransformerFactory|SAXReader' src/
# SSRF
grep -rniE 'new URL\(|HttpURLConnection|HttpClient|RestTemplate|WebClient|OkHttpClient|IOUtils\.toString\(new URL' src/
# Path traversal / arbitrary file read-write / upload
grep -rniE 'new File\(|Files\.(copy|write|newOutputStream)|getRealPath|FileInputStream|MultipartFile' src/
# SSTI / expression injection
grep -rniE 'freemarker|velocity|SpelExpressionParser|ScriptEngine|OgnlUtil|Thymeleaf' src/
# Auth bypass smells
grep -rniE 'equals\(.*password|== null|isAdmin|bypass|skipAuth|DISABLE_|debug.*=.*true' src/
```

Every hit is a **hypothesis**, not a finding. Trace each: is the argument
attacker-controlled? Does a real request reach it? Is there a filter in between?

## 5.3 Semgrep (ruleset-driven, lower noise than raw grep)

```bash
semgrep --config p/java --config p/secrets --config p/owasp-top-ten \
        --config p/command-injection --sarif -o sast/semgrep.sarif src/
# Spring-specific taint rules catch SQLi / SSRF / path sinks with data flow:
semgrep --config "r/java.spring.security" src/ --json -o sast/semgrep-spring.json
```

Relevant rule families: `java.lang.security.*` (deserialization/CWE-502, command
injection), `java.spring.security.injection.*` (tainted SQL string, tainted URL
host → SSRF, tainted file path). Triage: keep taint-mode hits with a clear
source; discard pattern-only hits you can't tie to real input.

## 5.4 CodeQL (deepest, when you can build a DB)

For recovered source you can compile, or via the Java "build-less" extractor:

```bash
codeql database create sast/codeqldb --language=java --source-root=src --build-mode=none
codeql database analyze sast/codeqldb codeql/java-queries \
       --format=sarifv2.1.0 --output=sast/codeql.sarif
```

The standard `codeql/java-queries` pack ships taint-tracking queries for
deserialization, SSRF, SQLi, path injection, command injection, and XXE — these
give the best source→sink dataflow evidence to design a Gate 6 PoC.

## 5.5 Endpoint-driven review (the high-yield manual pass)

For each **pre-auth-reachable** endpoint from Gate 4:

1. Find its handler class/method.
2. Follow each request parameter to a sink.
3. Note any auth/authorization check and whether it can be skipped (e.g. a filter
   that only matches certain URL patterns, a first-run/setup servlet left
   enabled, an API that trusts a client-supplied user id → IDOR).

This manual pass, guided by the decompiled endpoint map, is where the real
Critical/High bugs (unauth RCE, auth bypass, SSRF-to-internal) usually come from —
not the raw grep.

## 5.6 Rank candidates

Write each to `findings.md`:

```
### CANDIDATE: <short title>
- Type / CWE:
- Endpoint & reachability (pre-auth? which role?):
- Source → sink trace (file:line → file:line):
- Why exploitable (hypothesis):
- Out-of-scope check: (passes the Gate 0 exclusion list? y/n)
- Planned PoC for Gate 6:
```

Drop anything that hits the Gate 0 out-of-scope list (e.g. "old bundled library"
with no working path, best-practice nits) before Gate 6.

## Gate exit criteria

- SAST run (grep + Semgrep, ideally CodeQL); secrets scanned.
- Ranked candidate list with source→sink traces, each passing the out-of-scope
  filter. Proceed to Gate 6 to validate.
