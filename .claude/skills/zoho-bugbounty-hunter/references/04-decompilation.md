# Gate 4 — Decompilation / Source Extraction

This is the gate that turns a shipped `.exe` / `.bin` (or `.jar`, `.war`, `.dll`,
`.apk`, native ELF/PE) into **readable source you can audit in Gate 5**. It is
legitimate reverse engineering of software the vendor invited you to test under
the VRP — but keep the extracted tree quarantined (see hygiene note) and use it
only to find and report bugs.

Driver script: `scripts/extract_installer.sh` (unpacks installers) and
`scripts/decompile.sh` (runs the decompilers). Both are defensive wrappers that
pick the right tool from the file type and keep output in a quarantined dir.

## 4.0 Hygiene (mandatory)

- Output goes to `engagements/<product>-<date>/extracted/` — its own directory.
- **Never execute** anything from `extracted/`, and never run a build tool
  (`mvn`, `gradle`, `npm`, `python setup.py`) from inside it — a planted script
  could run. Reading and grepping are safe; execution happens only in the Gate 3
  lab.
- If you must run a helper Python script against extracted files, use
  `python3 -I` and pass paths as arguments.

## 4.1 Unpack the installer (.exe / .bin)

ManageEngine installers are built with **InstallAnywhere** (Flexera/Revenera).
They're essentially ZIP archives behind a native launcher stub, so a general
archiver can usually open them.

```bash
# Try, in order of success rate:
7z x product.bin -o extracted/_installer           # 7-Zip handles the stub+offset best
# or
unzip -o product.exe -d extracted/_installer        # works when the stub is thin
# or, if the ZIP central directory is at an offset the tool won't find:
scripts/extract_installer.sh product.bin extracted/_installer   # scans for the PK header
```

If the archive won't open directly, the fallback is a **silent install in the
Gate 3 VM**, then copy the deployed tree off disk:

```bash
./product.bin -i silent -f response.properties     # inside the isolated VM
# then collect $INSTALL_DIR (lib/, conf/, webapps/, bin/, jre/)
```

After unpacking you're looking for:

- `**/lib/**/*.jar` and `**/*.war` — the application code (primary target).
- `**/conf/`, `**/*.properties`, `**/*.xml` — configs, sometimes default creds.
- `**/webapps/` or embedded JSP/HTML — web layer.
- bundled `jre/`, `pgsql/` — ignore for source (third-party), note versions.

## 4.2 Decompile Java (the common case)

Use **multiple decompilers and compare** — each fails on different constructs
(lambdas, switch-on-string, generics, obfuscated names). Running two or three and
diffing recovers far more than any single tool.

| Tool | Strength | Invocation |
|------|----------|------------|
| **jadx** | Best all-round, great for batch + GUI browsing; handles modern Java | `jadx -d out/ app.jar` |
| **CFR** | Modern language features, single JAR, robust | `java -jar cfr.jar app.jar --outputdir out/` |
| **Procyon** | Good on generics/annotations | `java -jar procyon.jar app.jar -o out/` |
| **Fernflower** | IntelliJ's engine; writes `.java` back into a JAR | `java -jar fernflower.jar app.jar out/` |
| **Bytecode-Viewer** | Runs several at once in a GUI, side-by-side | GUI |

```bash
# batch every JAR in the extracted tree with the preferred decompiler + fallback
scripts/decompile.sh extracted/_installer extracted/src
```

Tips:

- Raise JVM heap for large JARs: `java -Xmx4g -jar cfr.jar ...`.
- Decompile `WEB-INF/classes` and the app's own `com.<vendor>...` packages first;
  skip third-party libs (spring, log4j, etc.) unless a sink leads into them.
- Keep `web.xml`, `struts.xml`, Spring `*-servlet.xml`, annotations — they are the
  **endpoint → class** map Gate 5 depends on.

## 4.3 Other artifact types

- **.NET (.exe/.dll)** — `ilspycmd app.dll -o out/` (ILSpy CLI) or dnSpy (GUI).
  Watch for config in `app.config` / embedded resources.
- **Native ELF/PE (C/C++)** — load in **Ghidra** (headless:
  `analyzeHeadless <proj> -import binary -postScript DecompileToC.java`). Export
  pseudo-C for the functions reachable from network input.
- **Android `.apk`** — `jadx -d out/ app.apk` for Java; `apktool d app.apk` for
  resources/smali and `AndroidManifest.xml` (exported components, deep links).
- **iOS `.ipa`** — unzip, analyze the Mach-O with Ghidra/Hopper; focus on
  `class-dump`-style interfaces and ATS/URL-scheme config.
- **Electron/JS thick clients** (e.g. some agents) — `npx @electron/asar extract
  app.asar out/`; the source is JavaScript, often barely minified.

## 4.4 Reconstruct a navigable tree

```bash
# normalize into a single src/ you can grep and open in an editor
rsync -a extracted/src/ engagements/<product>-<date>/src/
# index of recovered endpoints for Gate 5
grep -rilE '@(Request|Get|Post|Put|Delete)Mapping|extends HttpServlet|<servlet-mapping>' \
     engagements/<product>-<date>/src/ > sast/endpoint-files.txt
```

## Gate exit criteria

- Installer unpacked; application JARs/WARs/DLLs located.
- Source recovered (ideally via 2+ decompilers on the critical JARs) into a
  quarantined `src/` tree.
- Endpoint/servlet/controller map extracted and saved for Gate 5. Proceed to
  Gate 5.
