---
name: zoho-bugbounty-hunter
description: >-
  Orchestrates an authorized, scope-compliant bug bounty workflow against Zoho /
  ManageEngine products enrolled in the official Zoho Vulnerability Reward Program
  (bugbounty.zohocorp.com). Use when a researcher wants to systematically hunt,
  triage, and report vulnerabilities in Zoho cloud apps or on-premise products
  (ManageEngine, Site24x7, etc.). Covers scope/authorization gating, recon,
  isolated-lab setup for downloadable .exe/.bin installers, a decompilation gate
  that extracts source from Java/.NET/native binaries, static (SAST) and dynamic
  (DAST) analysis, exploitability validation, and responsible-disclosure reporting
  in Zoho's required format. Trigger on "Zoho bug bounty", "ManageEngine pentest",
  "decompile ManageEngine", or "hunt bugs in a Zoho product".
---

# Zoho / ManageEngine Bug Bounty Hunter

A gated, automation-friendly workflow for an AI agent to hunt vulnerabilities in
products covered by the **official Zoho Vulnerability Reward Program** and report
them responsibly. Every stage is a **gate**: the agent must satisfy the gate's
exit criteria (and, where marked 🔒, get explicit human confirmation) before
advancing.

> ⚖️ **This skill is for authorized testing only.** It assumes the operator is an
> enrolled Zoho VRP researcher testing in-scope assets with their own or
> consented accounts. It builds the program's own rules — no DoS, no privacy
> violations, no data destruction, working-PoC requirement, responsible
> disclosure — directly into the pipeline. The skill must refuse to help attack
> out-of-scope targets, exfiltrate real user data, weaponize findings, or evade
> the vendor's defenses for any purpose other than demonstrating a reported bug
> to Zoho.

## How an agent drives this skill

1. Read this file top to bottom once to load the gate model.
2. Walk the gates in order, but follow the **path your Gate 1 classification
   selects** — a pure cloud app skips the isolated-lab/decompile gates (3 & 4) by
   design, and that is *not* "skipping ahead". The rule is: never *advance past* a
   gate whose exit criteria (and 🔒 confirmation) you have not met.
3. At the start of each gate, load the matching file in `references/` for the
   detailed checklist and commands (progressive disclosure — don't preload them
   all).
4. At each 🔒 gate, **stop and ask the operator to confirm** before running
   anything that touches a live target or executes a downloaded installer.
5. Record findings as you go into a working file (`findings.md`); never keep a
   finding only in chat.
6. Prefer the helper scripts in `"$SKILL/scripts/"` over ad-hoc commands so runs
   are reproducible and the safety defaults (isolation, read-only mounts, offline
   SAST) are preserved.

## Tooling bootstrap

The helper scripts and reference files live under the skill directory, which may
not be your working directory. Set a shortcut once so every command below
resolves no matter where you `cd`:

```bash
SKILL=.claude/skills/zoho-bugbounty-hunter   # adjust if your skills dir differs
"$SKILL/scripts/setup_tools.sh" --check      # which tools are present/missing
```

`"$SKILL/scripts/setup_tools.sh" --install` (in your lab, not on a host you care
about) bootstraps the **package-manager** tools (7-Zip, unzip, Java, nmap, and —
via pip — Semgrep, mitmproxy). The rest (jadx, Ghidra, CodeQL, the decompiler
JARs, apktool, projectdiscovery httpx/subfinder/nuclei) are fetched from the
links `--check` prints. The skill degrades gracefully: each script checks for its
tools and tells you what is missing. All reference paths below (`references/...`)
are relative to `$SKILL`.

## The gates

| # | Gate | File | 🔒 | Purpose |
|---|------|------|----|---------|
| 0 | **Authorization & Scope** | `references/00-scope-and-authorization.md` | 🔒 | Prove eligibility + target in scope; load rules of engagement. Hard block. |
| 1 | **Target Intake & Classification** | `references/01-target-intake.md` | | Cloud web app vs. on-prem downloadable; collect version/installer. |
| 2 | **Recon & Attack-Surface Mapping** | `references/02-recon.md` | 🔒 | Discover assets/endpoints within rate limits; no intrusive scans on prod. |
| 3 | **Isolated Lab Setup** | `references/03-isolation-lab.md` | 🔒 | Run installers ONLY in a throwaway, network-isolated VM/container. |
| 4 | **Decompilation / Source Extraction** | `references/04-decompilation.md` | | Extract .exe/.bin → JAR/DLL/native → readable source. (The user-requested gate.) |
| 5 | **Static Analysis (SAST)** | `references/05-sast.md` | | Secrets, dangerous sinks, unauth-reachable code paths over extracted source. |
| 6 | **Dynamic Validation (DAST) & Exploitability** | `references/06-dast-validation.md` | 🔒 | Confirm findings against the LOCAL lab instance with a minimal, non-destructive PoC. |
| 7 | **Triage & Responsible-Disclosure Report** | `references/07-reporting.md` | | Filter out-of-scope classes, map severity to Zoho tiers, write the submission. |

## Gate 0 — Authorization & Scope (🔒 HARD BLOCK)

Do not run recon, downloads, installs, or analysis until **all** of these are
confirmed by the operator. If any fails, stop and explain why you cannot proceed.

- [ ] Operator is an enrolled Zoho VRP researcher, 14+, not resident in a
      US-sanctioned country, and not a current/recent Zoho employee or their
      family member.
- [ ] Target is **in scope**: a Zoho-branded product (zoho.com), a ManageEngine
      product (manageengine.com), Site24x7, Qntrl, TrainerCentral, Vani, Arattai,
      Ulaa Browser, Zoho POS, or another Zoho Corp-owned asset. (Full list in the
      reference file.)
- [ ] Testing uses only the operator's own account(s) or accounts whose owner
      gave explicit consent.
- [ ] Operator accepts the rules of engagement: no DoS/DDoS, no service
      degradation, no privacy violations, no data destruction; stop–notify–delete
      if unauthorized data is accessed; report and give Zoho reasonable time
      before any public disclosure.

See `references/00-scope-and-authorization.md` for the full scope list,
out-of-scope classes (so you don't waste effort on ineligible findings), and the
legal reality: the Zoho VRP grants **no safe harbor**. Participation is a binding
agreement with a liability-limitation clause and a license of your submissions to
Zoho; out-of-bounds activity (DoS, non-consented testing, acting outside scope)
can carry real legal consequences. Your only protection is staying in scope,
testing with consent, and re-reading the live terms before you start.

## Working-file convention

Keep all run artifacts under a per-engagement directory the operator names,
e.g. `engagements/<product>-<date>/`:

```
engagements/<product>-<date>/   # cd here after Gate 0; paths below are relative to it
├── scope.md            # frozen copy of Gate 0 answers
├── recon/              # Gate 2 output
├── lab/                # Gate 3 VM notes, snapshot ids
├── extracted/          # Gate 4 raw unpack + per-jar decompiler output (_installer/, src/) — UNTRUSTED
├── src/                # Gate 4 normalized, grep-able source tree — what Gate 5 scans
├── sast/               # Gate 5 reports
├── findings.md         # running list, one block per candidate
└── reports/            # Gate 7 final submissions
```

> 🧪 **Untrusted-input hygiene:** everything extracted in Gate 4 is third-party
> code. Keep it in its own directory, never run it or its build tooling from
> inside that directory, and pass paths as arguments. Run any helper Python with
> `python3 -I`. The decompiled tree is for *reading and scanning*, not execution —
> execution only happens inside the Gate 3 lab.

## Non-negotiables (apply at every gate)

- Never target an asset you have not confirmed in scope at Gate 0.
- Never run a downloaded installer outside the Gate 3 isolated lab.
- Never access, copy, or exfiltrate real users' data; PoCs use your own test
  accounts and benign markers.
- Never perform DoS, brute force at harmful volume, or anything that degrades a
  production service.
- Never publicly disclose, sell, or weaponize a finding; the only destination is
  the Zoho report.
- A finding is reportable only with a **validated, working PoC** (the program
  rejects unvalidated scanner output and theoretical issues).
