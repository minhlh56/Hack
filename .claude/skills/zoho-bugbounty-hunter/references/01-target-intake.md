# Gate 1 — Target Intake & Classification

Goal: decide *what kind* of target this is, because the rest of the pipeline
forks here.

## Step 1 — Classify

Ask the operator (or infer from the target):

| Signal | Classification | Path |
|--------|---------------|------|
| A URL like `*.zoho.com`, `*.manageengine.com`, `site24x7.com`, SaaS login | **Cloud web app** | Gates 2 → 6 → 7 (skip install/decompile unless a downloadable agent exists) |
| A downloadable installer (`.exe`, `.bin`, `.dmg`, `.deb`, `.rpm`, `.tar.gz`) | **On-prem product** | Full pipeline, Gates 2 → 3 → 4 → 5 → 6 → 7 |
| A desktop/agent binary (monitoring agent, Ulaa browser, POS client) | **Thick client** | Gates 3 → 4 → 5 → 6 → 7 |
| A mobile app (`.apk` / `.ipa`) | **Mobile** | Gate 4 (jadx/apktool) → 5 → 6 → 7 |

Most ManageEngine products are **on-prem, Java-based**, shipped as
InstallAnywhere `.exe` (Windows) / `.bin` (Linux). They bundle their own web
server (Apache/Tomcat-style), database (often bundled PostgreSQL), and a large
`lib/` tree of JARs — an ideal decompilation target.

## Step 2 — Acquire the artifact legitimately

- Download **only** the official build from the vendor's own download page for
  the product you confirmed in scope.
- Record: product name, exact version/build number, platform, download URL,
  SHA-256 of the file.
- Confirm it is the **latest** version — the program excludes issues that only
  affect old versions, so always test current.

```bash
# record provenance (run in the engagement dir)
sha256sum <installer> | tee engagements/<product>-<date>/lab/installer.sha256
```

> Put the downloaded installer in its own fresh, empty directory. It is
> untrusted until proven otherwise and must never be executed outside the Gate 3
> lab.

## Step 3 — Fingerprint before opening

```bash
file <installer>            # ELF stub (.bin) vs PE (.exe) vs archive
ls -lh <installer>          # size hints at bundled JRE/DB
strings -n 8 <installer> | grep -iE 'installanywhere|zerog|jre|tomcat|postgres|version' | head
```

InstallAnywhere installers identify themselves in strings (`ZeroG`,
`InstallAnywhere`, `com.zerog...`). That tells Gate 4 how to unpack them.

## Step 4 — Build the attack-surface hypothesis

From product docs, note (to guide Gates 2/5/6):

- Default listening ports and protocols (web UI, API, agent channel).
- Authentication model (local users, AD/LDAP, SAML/SSO).
- Known historically weak areas for this product family: unauthenticated API
  servlets, file-upload endpoints, SSRF in connector/integration features,
  deserialization in agent-server channels, XXE in XML import, SSTI in report
  templating, auth bypass on setup/first-run endpoints.
- Whether a management agent is distributed (another binary to decompile).

## Gate exit criteria

- Classification chosen and pipeline path selected.
- Artifact acquired (latest version), provenance recorded.
- Attack-surface hypothesis written to `findings.md` as a checklist of areas to
  probe. Proceed to Gate 2.
