# Gate 3 — Isolated Lab Setup (🔒 Safety-critical)

A downloaded installer is untrusted, closed-source, SYSTEM/root-level software.
**Never run it on your workstation, a host you care about, or anything with
network reach to production or to your real data.** This gate exists to protect
the operator as much as to enable testing.

> 🔒 Get explicit operator confirmation before executing any installer. State
> which VM/snapshot you will use and that it is isolated.

## Required properties of the lab

1. **Disposable VM** (VirtualBox/VMware/KVM/Hyper-V) or a throwaway cloud
   instance — not a container when kernel isolation matters and the product
   installs drivers/services. Use the OS the installer targets (Windows for
   `.exe`, Linux for `.bin`).
2. **Snapshot before install**, so you can diff filesystem/registry changes and
   roll back cleanly.
3. **Host-only / internal network** by default. Give outbound internet only when
   a feature under test genuinely needs it, and never let the VM reach your real
   LAN, cloud credentials, or production Zoho tenants.
4. **No real secrets** in the VM. Use throwaway test accounts and license keys
   you're entitled to.
5. **Instrumentation ready**: an intercepting proxy (Burp/mitmproxy) on the host
   or a second VM, a decompiler host (can be your workstation — reading source is
   safe), and tooling to diff pre/post-install state.

## Suggested layout

```
[ Host / analysis box ]  -- reads decompiled source (safe), runs Burp/mitmproxy
        |  host-only net
[ Lab VM: product under test ]  -- runs the .exe/.bin, snapshotted, isolated
```

## Install & observe

```bash
# Linux .bin — run INSIDE the VM, capture what it does
chmod +x product.bin
./product.bin -i console        # or: ./product.bin -i silent -f response.properties
```

Capture during/after install (for Gate 5 context, not as findings on their own):

- Install path, service/daemon names, the user it runs as.
- Listening ports (`ss -tlnp` / `netstat -ano`).
- The `lib/` JAR tree, config files, bundled DB, default credentials in configs.
- Scheduled tasks / services / registry autoruns (Windows:
  `reg query` + Autoruns; Linux: systemd units).

> You will almost always get the source faster and more completely by
> **decompiling the bundled JARs (Gate 4)** than by reverse-engineering runtime
> behavior. Install mainly to (a) get a running instance for Gate 6 dynamic
> validation and (b) locate the real deployed artifacts on disk.

## Snapshot the running instance

Take a second snapshot of the *installed, configured, running* state. Gate 6
dynamic testing can then always reset to a known-good baseline — important
because the program forbids leaving services degraded, and lets you retry PoCs
cleanly.

## Gate exit criteria

- Installer executed only inside an isolated, snapshotted VM.
- Running instance reachable from your analysis box for Gate 6.
- On-disk artifact locations (JARs, WARs, configs) catalogued for Gate 4.
