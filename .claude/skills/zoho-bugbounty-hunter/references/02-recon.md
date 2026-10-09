# Gate 2 — Recon & Attack-Surface Mapping (🔒 for live targets)

Recon posture depends on target type. **Against production cloud assets, stay
passive/low-impact and within rate limits** — the program forbids service
degradation and rejects unvalidated scanner noise. Against your **own isolated
lab instance** (Gate 3), you can be as aggressive as you like.

> 🔒 Before any request that leaves your machine toward a Zoho-owned asset,
> confirm with the operator. Keep concurrency and request rates low; identify
> your traffic with a researcher tag in the User-Agent where practical.

## A. Cloud web app recon (passive-first)

```bash
# subdomains (passive sources; avoid brute forcing prod)
subfinder -d <in-scope-domain> -silent | sort -u > recon/subs.txt

# which are alive + tech fingerprint (low rate)
httpx -l recon/subs.txt -rate-limit 10 -title -tech-detect -status-code \
      -o recon/httpx.txt

# content discovery: prefer crawling + known paths over heavy brute force on prod
# (reserve wordlist brute force for the lab instance)
```

What to capture:

- Live hosts, titles, tech stack, status codes.
- Login/SSO flows, API base paths (`/api`, `/restapi`, `/rest`), docs/Swagger.
- Version banners (map to the product build you'll decompile).
- Features that smell state-changing or multi-tenant (IDOR/authz candidates).

Avoid on prod: high-volume fuzzing, credential brute force, anything that could
degrade service, automated exploit scanners firing unvalidated payloads.

## B. On-prem product recon (do this against the lab instance)

Once installed in Gate 3, enumerate the local instance thoroughly:

```bash
# local port/service map of the lab VM
nmap -sV -p- -T4 <lab-ip> -oN recon/nmap.txt

# web surface of the product UI/API
httpx -u https://<lab-ip>:<port> -title -tech-detect -status-code
# directory + endpoint discovery is fair game here (it's your box)
```

Cross-reference with Gate 4/5: the decompiled `web.xml`, servlet mappings, and
Spring `@RequestMapping`s give you the *complete* endpoint list — far better than
black-box crawling. Recon and decompilation feed each other.

## C. Deliverables

Write `recon/surface.md`:

- Enumerated endpoints (black-box) + endpoints recovered from source (Gate 4).
- Which endpoints are reachable pre-authentication (highest priority).
- Candidate sink areas tied to the Gate 1 hypothesis.

## Gate exit criteria

- Attack surface mapped; pre-auth endpoints flagged.
- No prohibited intrusive testing performed against production.
- Priority target list written for Gates 5/6. Proceed to Gate 3 (on-prem/thick)
  or jump to Gate 6 (pure cloud app).
