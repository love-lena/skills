---
name: manta
description: Use when sending files to your Supernote Manta for reading and handwritten annotation, pulling annotated files back, or generating editorial reading versions of documents (a reflowable EPUB by default, or a large-font redline PDF) for the device. Triggers include "send this to my manta", "print an editor version", "redline on the manta", "pull my annotations from the manta", "flatten the mark file".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Agent
---

# Manta workflow

Send files to a Supernote Manta, pull annotated files back, and generate editorial reading versions of documents. The round trip goes through a **self-hosted Supernote private cloud** via the `supernote cloud` CLI — no desktop sync app required.

**Platform:** macOS for the `--pdf` redline render (Chrome paths; Linux fallbacks included). The default EPUB path and the cloud round trip are OS-agnostic.

**Prerequisites:**
- `pandoc` (always). A Chrome/Chromium-family browser is needed only for `--pdf`.
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
| `editorial.sh <input.md> [--pdf] [--to-manta \| --to <path>]` | Markdown → **editorial EPUB** (default; reflowable, styled for on-device reading) or **redline PDF** (`--pdf`). `--to-manta` uploads to `/INBOX`; `--to <path>` writes locally (review first). Output: `~/Downloads/<name>.epub` (or `.pdf`). |
| `pull.sh <name> [--to <path>]` | **Pull an annotated doc back** into `~/Downloads`. Grabs a flattened device **Export** from `/EXPORT` directly; falls back to `flatten.sh` when it finds a `.pdf.mark` sidecar. The everyday "get my redlines back" command. |
| `flatten.sh <name-or-path> [--to <path>]` | Composite a `.pdf.mark` sidecar onto the source PDF (the fallback `pull.sh` uses; also works on a local path). Default output: `~/Downloads/<name> annotated.pdf`. |

All `source cloud.sh` for the cloud helpers, so run them from anywhere.

## Sending a file TO the Manta

The default is an **editorial EPUB** — reflowable, styled for reading and annotating on the device. Send it straight, or review locally first:
```bash
skills/manta/editorial.sh "path/to/doc.md" --to-manta          # editorial EPUB -> /INBOX
skills/manta/editorial.sh "path/to/doc.md" --to /tmp/x.epub     # inspect locally first
skills/manta/editorial.sh "path/to/doc.md" --pdf --to-manta    # redline PDF instead
```

For an existing file (PDF/EPUB), upload it directly:
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

The device hands work back two ways, and `pull.sh` handles both:

- **Export to PDF** (on the device) → a *flattened* PDF lands in `/EXPORT`, ink baked in, no sidecar. `pull.sh` downloads it directly.
- **Annotate in place** → the ink syncs back as a `<name>.pdf.mark` sidecar beside the original. `pull.sh` detects the sidecar and composites via `flatten.sh`.

```bash
skills/manta/pull.sh "<Title>"     # -> ~/Downloads/<Title> annotated.pdf
```

`pull.sh` searches `/EXPORT` first, then `/INBOX`. It only composites when it finds a `.pdf.mark` (then the matching `.pdf` is the un-inked original); otherwise it grabs the flattened export. Use `flatten.sh` directly for a local file or to force compositing.

Output lands in `~/Downloads/<Title> annotated.pdf`. Ink renders black (matches device appearance — color did not help interpretation). If `pull.sh` finds nothing, sync probably hasn't pushed the work back yet — wait for the device to sync, don't assume the page is unmarked.

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

## Editorial formats

**EPUB (default) — `epub.css`.** A reflowable reading layout: serif body, sans-serif ruled section headings, styled blockquotes/lists/tables, monospace code. Size, line spacing, and page margins are **set on the device** (Display Settings — keep "Document default setting", or choose User-defined), so reading comfort is dialed there, not baked in. Title-page handling is automatic: a YAML `title:` (web clippings) keeps pandoc's title page; a body `#` title (ADRs/plain md) suppresses it via `--epub-title-page=false` so it isn't an "UNTITLED" page or a duplicate.

> **EPUB is for reading, not redlining.** On-device EPUB annotations do NOT reliably round-trip: the device stores ink in a `.epub.mark` with **no text context** (reflowable — there's no fixed page to composite onto) and the sync is **conflict-prone** (repeated edits spawn blank `_CONFLICT_` copies). So `pull.sh` is PDF-only by design. **For anything you'll mark up and need back, send `--pdf`** — its annotations round-trip cleanly (see Pulling).

On-device CSS support (verified on the Manta/Chauvet reader): **font-family, font-size, text-align, color, and borders are honored; font-weight is NOT** (the serif has no bold face). So emphasis can't rely on bold — `epub.css` renders `strong`/`**bold**` in the **sans face**, which pops against the serif body. Body is left-aligned (justify makes rivers at large e-ink sizes).

**PDF redline — `--pdf`, `editorial.css`.** The fixed print format: 13pt Georgia, 2.0 line-height, sans headings, 3.5in bottom margin on every page (the redline space). Use when you specifically want that layout. Pagination: a forced section break fires only on the 3rd-plus top-level `#` (`h1:nth-of-type(n+3)`); a single `#` title + `##`/`###` sections flows continuously — don't add extra `#` headings to force breaks.

## Common Mistakes

- **Not logged in** — the scripts need a one-time `supernote cloud login` (see Setup). A login/connection error means re-check that, and that your cloud is reachable.
- **Passing `--metadata title=` (or `-s`/`--standalone`) to pandoc for the PDF** — emits a duplicate title block. Let the source's own `# Title` heading be the title.
- **Relying on bold in EPUB** — the device drops font-weight; `epub.css` carries emphasis via the sans face instead. Don't move emphasis back to font-weight.
- **Expecting `##` sections to start new pages** — they don't (see Pagination).
- **Treating "no .mark sidecar" as unmarked** — usually means the device hasn't synced the annotation back yet.
- **Black ink is intentional** — matches device appearance; color didn't aid interpretation.
