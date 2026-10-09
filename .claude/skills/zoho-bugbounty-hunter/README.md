# zoho-bugbounty-hunter

An AI-agent **skill** that runs an authorized, scope-compliant bug bounty
workflow against products in the official **Zoho Vulnerability Reward Program**
(<https://bugbounty.zohocorp.com/bb/info>) — Zoho cloud apps and on-premise
ManageEngine / Site24x7 / etc. products.

It is built around a chain of **gates**. The agent can only advance a gate after
meeting its exit criteria, and must pause for human confirmation at the 🔒 gates
(authorization, live-target recon, running an installer, cloud PoCs). The gate
the request specifically asked for — **decompiling the downloadable `.exe`/`.bin`
products to extract source** — is Gate 4.

## Who this is for

Enrolled Zoho VRP researchers (14+, not in a sanctioned country, not a Zoho
employee/family member) testing **in-scope** assets with **their own or
consented** accounts. The skill bakes the program's rules into every stage: no
DoS, no privacy violations, no data destruction, a mandatory working PoC, and
responsible disclosure. It will not help attack out-of-scope targets, touch real
users' data, or weaponize/publicly disclose findings.

## The pipeline

```
Gate 0  Authorization & Scope            🔒 hard block
Gate 1  Target intake & classification      (cloud vs on-prem vs thick/mobile)
Gate 2  Recon & attack-surface mapping    🔒 (low-impact on prod; aggressive in lab)
Gate 3  Isolated lab setup                🔒 (run installers ONLY in a throwaway VM)
Gate 4  Decompilation / source extraction    (.exe/.bin → JAR/DLL/native → source)
Gate 5  Static analysis (SAST)               (secrets, sinks, unauth-reachable code)
Gate 6  Dynamic validation & exploitability 🔒 (minimal, benign, working PoC)
Gate 7  Triage & responsible-disclosure report
```

See `SKILL.md` for the orchestration and `references/0X-*.md` for each gate's
checklist and commands.

## Layout

```
SKILL.md                     # agent-facing orchestration + gate model
references/                  # one file per gate (loaded on demand)
  00-scope-and-authorization.md
  01-target-intake.md
  02-recon.md
  03-isolation-lab.md
  04-decompilation.md        # the .exe/.bin decompilation gate
  05-sast.md
  06-dast-validation.md
  07-reporting.md
scripts/                     # reproducible helper wrappers (defensive defaults)
  setup_tools.sh             # check/install the open-source toolchain
  extract_installer.sh       # unpack InstallAnywhere .exe/.bin (offset-aware)
  decompile.sh               # batch-decompile JAR/WAR (jadx → CFR → Procyon)
  sast_scan.sh               # offline secrets + sink + semgrep pass
templates/
  report-template.md         # Zoho VRP submission format
```

## Quick start

```bash
# 0. check your toolbox (install missing pieces in a disposable box)
.claude/skills/zoho-bugbounty-hunter/scripts/setup_tools.sh --check

# Then invoke the skill in the agent and walk the gates:
#   "Use the zoho-bugbounty-hunter skill on <in-scope product>."
# The agent will start at Gate 0 and confirm authorization/scope before anything else.
```

## Reference toolchain (all open source)

7-Zip/unzip, jadx, CFR, Procyon, Fernflower, Bytecode-Viewer (Java);
ILSpy/dnSpy (.NET); Ghidra (native); apktool (Android); Semgrep, CodeQL,
trufflehog (SAST/secrets); subfinder, httpx, nuclei, nmap (recon); Burp /
mitmproxy (dynamic).

## Legal & ethics

Reverse engineering here is of software the vendor invited researchers to test
under the VRP, for the sole purpose of finding and privately reporting bugs to
Zoho. Stay in scope, keep PoCs benign, respect the disclosure timeline, and
destroy or quarantine extracted source and lab VMs when done. When in doubt about
scope or an action, re-read Gate 0 and ask the operator.
