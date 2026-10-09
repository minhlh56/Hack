# Zoho VRP Report — <Short, specific title>

> One finding per report. Submit via the "Submit Bug" option on
> https://bugbounty.zohocorp.com/bb/info

## Summary
<One or two sentences: what the bug is and the impact, in plain terms.>

## Affected product & version
- Product: <e.g. ManageEngine ServiceDesk Plus>
- Version/build tested: <exact build>
- Platform: <Windows .exe / Linux .bin / cloud>
- **Latest version affected?** <yes — tested on current build X> (required: the
  program excludes old-version-only issues)

## Vulnerability class
- Type: <e.g. Unauthenticated SSRF>
- CWE: <e.g. CWE-918>
- Authentication required: <none / user / admin>
- Severity (self-assessed): <Low/Medium/High/Critical> — rationale: <impact + exploitability>

## Reproduction steps
1. <Numbered, copy-pasteable. Start from a clean install / your own test account.>
2. ...
3. ...

### Proof-of-concept
```
<Raw HTTP request(s) or exact commands. Keep it minimal and benign — markers,
canaries, your own accounts. No destructive payloads, no real-user data.>
```

### Observed result (evidence)
<Response excerpt, screenshot reference, or OOB/callback log that proves impact.
State clearly what it demonstrates.>

## Impact
<What a realistic attacker gains: data exposed, action performed, blast radius —
pre-auth vs authenticated, single- vs cross-tenant.>

## Root cause (supporting analysis — optional but persuasive)
<From the decompiled source: the source→sink path, file:line references, and the
missing/bypassed check. This corroborates the dynamic PoC.>

## Suggested remediation
<Concrete fix: validate/allowlist input, enforce authz at the handler, use safe
APIs, etc.>

## Disclosure
Reported privately to Zoho via the VRP. No public disclosure until fixed and
with Zoho's reasonable timeline. No real user data was accessed or retained; any
test data was created by the reporter.
