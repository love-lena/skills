---
name: manta
description: Use when sending files to your Supernote Manta for handwritten annotation, pulling annotated files back, or generating editorial-format PDFs (large font, double-spaced, generous bottom margin) suitable for redlining on the device. Triggers include "send this to my manta", "print an editor version", "redline on the manta", "pull my annotations from the manta", "flatten the mark file".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Agent
---

# Manta workflow

Send files to a Supernote Manta, pull annotated files back, and generate editorial-format PDFs sized for redlining. The round trip goes through a **self-hosted Supernote private cloud** via the `supernote cloud` CLI — no desktop sync app required.

**Platform:** macOS for editorial-PDF rendering (Chrome paths; Linux fallbacks included). The cloud round trip is OS-agnostic.

**Prerequisites:**
- `pandoc` + a Chrome/Chromium-family browser (editorial PDF rendering).
- A reachable Supernote private cloud (e.g. an `allenporter/supernote` self-host) and a one-time login (below).
- The cloud client + notebook tooling are auto-installed into `~/.cache/manta/.venv` on first run.

## Setup (one-time)

Log in to your cloud once; the host + token cache at `~/.cache/supernote.pkl` (nothing secret lives in this skill):
```bash
# build the venv if you haven't run a script yet
bash skills/manta/cloud.sh >/dev/null 2>&1 || true
~/.cache/manta/.venv/bin/supernote cloud login <your-account> --url <your-cloud-url>
```
Override the venv location with `SN_VENV` if desired.

## The round trip (cloud folders)

Two standard device folders define the workflow — the scripts target them automatically:

| Folder | Direction | Used by |
|---|---|---|
| `/INBOX` | Claude **uploads** docs here; you review/annotate from it | `editorial.sh --to-manta` |
| `/EXPORT` | You **file** finished annotated docs here for Claude to pull | `flatten.sh` (searched first) |

The device pulls an uploaded `/INBOX` file on its next sync — immediately if your cloud has the push channel, otherwise on the device's normal sync cycle. Annotations come back as `.pdf.mark` sidecars in `/EXPORT` (or `/INBOX` if you annotate in place).

## Scripts (in this skill's directory)

| Command | What it does |
|---|---|
| `editorial.sh <input.md> [--to-manta \| --to <path>]` | Markdown → editorial PDF. Default: `~/Downloads/<name>.pdf`. `--to-manta` **uploads** to the cloud `/INBOX`; `--to <path>` writes anywhere — use it to review locally before sending. |
| `flatten.sh <name-or-path> [--to <path>]` | Composite `.pdf.mark` annotations onto the source PDF. Downloads `<name>.pdf` + `.pdf.mark` from `/EXPORT` first, then `/INBOX` (or pass a local path). Default output: `~/Downloads/<name> annotated.pdf`. |

Both `source cloud.sh` for the cloud helpers, so run them from anywhere.

## Sending a file TO the Manta

Review locally first (recommended), then send:
```bash
skills/manta/editorial.sh "path/to/doc.md" --to /tmp/preview.pdf   # inspect
skills/manta/editorial.sh "path/to/doc.md" --to-manta              # upload to /INBOX
```

For an existing PDF, upload it directly:
```bash
~/.cache/manta/.venv/bin/supernote cloud upload "source.pdf" "/INBOX/<Title>.pdf"
```

## Verify

Confirm the upload landed and check what's on the cloud:
```bash
~/.cache/manta/.venv/bin/supernote cloud ls /INBOX
```
If the device hasn't pulled it, wake the device or wait for its sync cycle. If a command errors with a login/connection message, re-check `cloud login` and that your cloud is reachable.

## Pulling annotated files FROM the Manta

File finished annotations in the device's **EXPORT** folder, then pull one back:
```bash
skills/manta/flatten.sh "<Title>"
```
`flatten.sh` downloads from `/EXPORT` first, then `/INBOX` — so it works whether you exported the file or annotated it in place.

Output lands in `~/Downloads/<Title> annotated.pdf`. Ink renders black (matches device appearance — color did not help interpretation). If `flatten.sh` reports it can't find the `.pdf.mark`, sync probably hasn't pushed the annotations back yet — wait for the device to sync, don't assume the page is unmarked.

**Page placement caveat:** Supernote stores only the *annotated* pages, in order, with no recoverable PDF-page index, so `flatten.sh` maps the Nth annotated page onto PDF page N. That's correct for the usual top-to-bottom redline (annotate from page 1, contiguously). If leading pages were skipped, ink shifts earlier than intended — the Opus reading pass below is the check: it renders the *flattened* result, so misplaced ink shows up as annotations that don't match the page's text.

## Reading the annotations (Opus over the flattened PDF wins)

To recover what the annotations say, **dispatch an Opus subagent** over the flattened PDF. This outperforms glm-ocr meaningfully — Opus catches small marks (insertions, tilde flags, strikethrough boundaries) and provides position context for each annotation. glm-ocr captures prose-only annotations cleanly but misses edit semantics.

**Recipe — Opus annotation pass:**

1. Render the flattened PDF to per-page PNGs (clear the dir first to avoid stale pages):
   ```bash
   rm -rf /tmp/manta-pages && mkdir -p /tmp/manta-pages
   mutool draw -o /tmp/manta-pages/page-%d.png -r 200 "<title> annotated.pdf"
   ```
   `mutool` numbers pages from 1.
2. Dispatch `Agent` with `model: opus`, instructing it to **Read each `page-N.png`** and, per page, report:
   - Each discrete annotation (strikethrough, underline, insertion, marginal note, arrow)
   - WHERE it sits (which sentence/word it's anchored to)
   - WHAT it says or what edit it represents
   - `[unclear]` placeholder for illegible bits
3. To merge into the source draft: dispatch a second Opus subagent with the source markdown **plus the rendered PNGs** (not the raw PDF — a subagent can't read a PDF as images), asking it to write a revised MD plus an edit log of `[applied | flagged | not applied]` items. Bold the modified prose so changes are easy to scan.

**Don't reach for glm-ocr unless** you want a quick prose-only OCR dump. The composited-PDF glm-ocr pass is OK for "current draft state" but loses edit semantics.

## Editorial format (baked into editorial.css)

13pt Georgia body, 2.0 line-height, sans-serif headings, 3.5in bottom margin on **every** page (the redline space), styled tables/code/blockquotes.

**Pagination:** a forced break before a section fires only on the 3rd-plus top-level `#` heading (`h1:nth-of-type(n+3)`). A doc that is one `#` title + `##`/`###` sections **flows continuously** — no per-section page breaks, just the 3.5in bottom margin on each page. That's expected; don't add extra `#` headings to force breaks.

## Common Mistakes

- **Not logged in** — the scripts need a one-time `supernote cloud login` (see Setup). A login/connection error means re-check that, and that your cloud is reachable.
- **Passing `--metadata title=` (or `-s`/`--standalone`) to pandoc** — emits a duplicate title block. Let the source's own `# Title` heading be the title.
- **Expecting `##` sections to start new pages** — they don't (see Pagination).
- **Treating "no .mark sidecar" as unmarked** — usually means the device hasn't synced the annotation back yet.
- **Black ink is intentional** — matches device appearance; color didn't aid interpretation.
