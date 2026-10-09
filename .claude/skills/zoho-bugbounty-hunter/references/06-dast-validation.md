# Gate 6 — Dynamic Validation & Exploitability (🔒)

Turn each Gate 5 candidate into a **validated, working, minimal, non-destructive
PoC** — against the **local lab instance** (on-prem) or your **own test tenant**
(cloud). The program rejects unvalidated/theoretical findings, so this gate is
what makes a finding reportable.

> 🔒 For cloud targets, every validation request hits Zoho infrastructure:
> confirm with the operator, keep it to a single benign PoC on your own account,
> and never use payloads that could degrade service or touch other tenants' data.
> For on-prem, hammer your own VM freely.

## 6.1 Set up interception

```bash
# Route the product UI/API through a proxy so you can read and replay requests
mitmproxy --mode regular --listen-port 8080     # or Burp Suite
# configure the lab VM / your browser to use the proxy
```

**Mobile targets** (the Gate 1 mobile path skips the VM lab) need a runtime to
validate against: run the APK/IPA in an emulator (Android Studio AVD / a test
device) or simulator, point it at the proxy above, and install the proxy's CA so
TLS can be inspected. Expect certificate pinning on hardened apps — be ready to
patch/repackage with the Gate 4 `apktool` output or use a Frida pinning-bypass on
your own test device. From there, validate Gate 5 candidates exactly as below.

## 6.2 Validate by class (minimal, benign PoCs)

Design PoCs that **prove** the bug without causing harm. Use benign markers, your
own accounts, and canary values — never destructive payloads or real-user data.

- **Unauth access / auth bypass** — request the protected endpoint with no / a
  low-priv session; show it returns privileged data or performs a privileged
  action. Benign proof: read a value only an admin should see, created by you.
- **IDOR / authz** — two of *your own* test accounts; show account A reading or
  changing account B's object by id. Never use a stranger's object.
- **SQL injection** — prove with a boolean/time check or `version()` readback on
  your lab DB. Do **not** dump real data or run destructive SQL.
- **RCE / command injection** — prove with a harmless, reversible marker:
  `id`/`whoami`, a DNS/HTTP callback to your own collaborator, or writing a
  canary file. Never install persistence, pivot, or run destructive commands.
- **SSRF** — hit an interaction server you control (`Burp Collaborator`,
  `interactsh`) or a lab-internal canary; show the server made the request. Don't
  pivot into real internal infrastructure.
- **Deserialization** — demonstrate controlled code path / callback with a
  benign gadget on the lab box; stop at proof of execution.
- **XXE** — exfiltrate a canary file you placed (`/tmp/canary`) or trigger an
  OOB callback; not real sensitive files.
- **File upload / path traversal** — upload a benign marker and show
  write/retrieve at an unexpected path; a classic chain is upload → path control →
  web-reachable. Prove reachability, don't deploy a real web shell to a live
  service.
- **Stored/reflected XSS** (in-scope contexts only) — `alert(document.domain)`
  on your own session; confirm it isn't one of the out-of-scope XSS classes
  (sandbox/user-content domain, self-XSS).

## 6.3 Confirm against the latest version

Re-run the validated PoC on the **current** product build. The program excludes
issues that only affect old versions, so a finding that's already patched in the
latest release is not reportable. If you tested an older build, update the lab
and re-confirm.

## 6.4 Capture evidence

For each confirmed bug record, in the engagement dir:

- Exact HTTP request(s)/steps (ready to paste as reproduction steps).
- Response/screenshot/callback log proving impact.
- The source→sink reference from Gate 4/5 (strong corroboration for the report).
- Affected version(s) confirmed, and that the latest is affected.
- Blast radius: pre-auth vs authenticated, single- vs cross-tenant, impact.

## 6.5 Reset the lab

Restore the Gate 3 snapshot between destructive-ish tests so the instance stays
clean and you can reproduce from a known baseline.

## Gate exit criteria

- Each reportable candidate has a **working, minimal, non-destructive PoC**
  confirmed on the latest version, with evidence captured.
- Non-reproducible or out-of-scope candidates dropped. Proceed to Gate 7.
