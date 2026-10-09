# Gate 0 — Authorization & Scope (🔒 Hard block)

Source of truth: the Zoho Bug Bounty program page, <https://bugbounty.zohocorp.com/bb/info>.
Re-fetch it at the start of every engagement — scope and rules change and this
file is a cached snapshot, not the authority.

## Eligibility (confirm with the operator)

- 14 years or older. Minors need parent/guardian permission.
- Not a resident of a US-sanctioned country.
- Not a current Zoho employee, nor a former one who left within the last 6 months.
- Not a family member of a Zoho employee.

## In-scope assets

- **All Zoho-branded products/apps** listed at `zoho.com`.
- **All ManageEngine-branded products/apps** listed at `manageengine.com`
  (this is where most downloadable on-prem `.exe` / `.bin` products live —
  OpManager, ServiceDesk Plus, ADManager/ADSelfService Plus, Analytics Plus,
  Endpoint Central, PAM360, Applications Manager, etc.).
- Site24x7 (`site24x7.com`), Qntrl (`qntrl.com`), TrainerCentral
  (`trainercentral.com`), Vani (`vanihq.com`), Arattai (`arattai.in`),
  Ulaa Browser (`ulaa.com`), Zoho POS (`zoho.com/en-in/pos/`).
- Other assets owned by Zoho Corporation.

## Rules of engagement (build these into every later gate)

- Avoid privacy violations, service degradation, infrastructure disruption, and
  data destruction.
- Test only with your own account, or an account whose owner gave explicit
  consent.
- Use a discovered bug **only** to test/demonstrate it — do not exploit it for
  any other purpose.
- If you inadvertently access unauthorized information: **stop, notify Zoho,
  delete the information.**
- Report every bug and give Zoho reasonable time to fix before any public
  disclosure.
- Breaking these rules = immediate termination from the program.

## Explicitly prohibited

- DDoS / DoS testing, or any activity that could cause degradation, disruption,
  or outage.
- Social engineering.
- Physical access attacks.

## Out-of-scope finding classes (do NOT spend effort here — ineligible)

Filter candidates against this list *before* investing in a PoC:

- Missing best practices that aren't vulnerabilities; self-XSS; username/email
  enumeration; email bombing; HTML injection.
- XSS on sandbox/user-content domains; open redirects; tabnabbing.
- Clickjacking on unauthenticated pages or pages without significant
  state-changing actions.
- Logout CSRF / unauthenticated CSRF; missing flags on non-sensitive cookies;
  missing security headers that don't directly lead to a vulnerability.
- **Unvalidated findings from automated tools or scans** (a working PoC is
  mandatory).
- CSV injection; broken-link hijacking; missing rate limits without security
  impact.
- Hosting malware; **known-vulnerable libraries without evidence of
  exploitability** (you must prove a working exploit path).
- Pricing / paid-feature bypasses; SPF/DKIM/DMARC issues; password-policy issues.
- Zero-days in third-party software within 10 days of disclosure.
- Issues affecting only old versions, or only rooted/jailbroken devices.
- Intended features (queries/scripts/workflows run by privileged users).

### On-prem-specific exclusions (very relevant to ManageEngine installers)

- Applications running as the SYSTEM user (by itself).
- Ability to upload/download executables (by itself).
- Vulns from deployments that don't follow Zoho's deployment guidelines.
- UDP-based unauthenticated protocols a user can disable.
- Issues that don't affect the **latest** version.
- Known-vulnerable components **without a working exploit**.

> Implication for the decompilation gate: finding an old/vulnerable library
> bundled in a JAR is *not* a report on its own. You must build a working,
> in-product exploit path and confirm it against the **latest** version.

## Reward tiers (USD, up to)

| Severity | Reward |
|----------|--------|
| Low | $50 |
| Medium | $200 |
| High | $800 |
| Critical | $3,000 |

Rewards are discretionary (severity, impact, exploitability). First valid report
of a duplicate wins.

## Submission requirements (shape your work toward these from the start)

- Submit via the "Submit Bug" option on the program page.
- Must include: vulnerability description, **clear reproduction steps**, and a
  **proof-of-concept**.
- Zoho aims to validate within ~3 days; you may confirm the fix later.

## Gate exit criteria

Freeze the operator's answers into `engagements/<product>-<date>/scope.md` and
only then proceed to Gate 1. If the target isn't clearly in scope, or any
eligibility item fails, **do not proceed** — explain the blocker and stop.
