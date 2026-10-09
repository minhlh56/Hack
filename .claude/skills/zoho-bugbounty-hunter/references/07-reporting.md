# Gate 7 — Triage & Responsible-Disclosure Report

Convert validated findings into Zoho VRP submissions and disclose responsibly.

## 7.1 Final triage against program rules

For each finding, confirm one last time:

- [ ] Target was in scope (Gate 0).
- [ ] Not on the out-of-scope list (self-XSS, enumeration, best-practice nits,
      known-vuln-lib-without-working-exploit, old-version-only, intended feature,
      pricing bypass, SPF/DKIM/DMARC, etc.).
- [ ] A **working PoC** exists and was confirmed on the **latest** version.
- [ ] No real user data was accessed; if any was inadvertently touched, you
      already stopped, notified Zoho, and deleted it.

Drop anything that fails. Reporting ineligible findings wastes the triage team's
time and yours.

## 7.2 Map severity to Zoho tiers

Rough guide (Zoho decides the final rating by severity/impact/exploitability):

| Example | Likely tier | Up to |
|---------|-------------|-------|
| Unauth RCE, auth bypass to admin, cross-tenant data access | Critical | $3,000 |
| Authenticated RCE, SSRF to internal/cloud metadata, significant IDOR | High | $800 |
| Stored XSS with real impact, limited SSRF, meaningful info disclosure | Medium | $200 |
| Lower-impact, authenticated, limited-blast-radius issues | Low | $50 |

## 7.3 Write the report

Use `templates/report-template.md`. Zoho requires: a clear **description**,
**reproduction steps**, and a **proof-of-concept**. Make it trivially
reproducible:

- One finding per report (don't bundle).
- Exact version/build, platform, and that the latest is affected.
- Numbered, copy-pasteable steps; include raw requests.
- Minimal PoC + evidence (screenshots, callback logs). Keep PoCs benign.
- Source→sink reference from decompilation as supporting analysis (optional but
  persuasive).
- Impact statement tied to a realistic attacker.
- Suggested remediation (shows depth, speeds the fix).

## 7.4 Submit & disclose responsibly

- Submit via the **"Submit Bug"** option on <https://bugbounty.zohocorp.com/bb/info>.
- First valid report of a duplicate wins — submit promptly once validated.
- Zoho aims to validate within ~3 days; respond to their questions and confirm
  the fix when asked.
- **Give Zoho reasonable time to fix before any public disclosure.** Do not
  publish, sell, or weaponize. Do not retain copies of any real data.

## 7.5 Clean up

- Destroy lab VMs/snapshots containing the vendor's software when done, or keep
  them isolated.
- Keep the quarantined extracted source only as long as needed for the report;
  don't redistribute it.

## Gate exit criteria

- Each eligible, validated finding submitted via the official portal in the
  required format.
- Disclosure timeline respected; no out-of-scope or unvalidated reports sent.
- Engagement artifacts cleaned up. Done.
