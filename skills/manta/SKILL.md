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

Send files to a Supernote Manta, pull annotated files back, and generate editorial-format PDFs sized for redlining.

**Platform:** macOS. The sync-folder path targets the macOS Supernote Partner.app container; browser detection includes Linux fallbacks, but the device paths assume macOS.

**Prerequisites:** `pandoc` + a Chrome/Chromium-family browser (editorial PDF); `mutool` / mupdf-tools (reading recipe). The supernotelib venv is auto-built on first `flatten.sh` run. Supernote Partner.app must be running for sync (focused or unfocused).

## Sync folder & the round trip

The desktop app's Document folder is **bidirectional** — files copied in propagate to the device; annotations propagate back as `.pdf.mark` sidecars. The folder lives under the Partner.app container at a per-registration numeric id that **changes on re-pair/reinstall**, so the scripts resolve it dynamically via `paths.sh` (`sn_resolve_doc`). Never hardcode it.

Two subfolders define the workflow — the scripts target them automatically:

| Folder | Direction | Used by |
|---|---|---|
| `INBOX/For Review` | Claude **drops** docs here; you review/annotate from it | `editorial.sh --to-manta` |
| `Exports` | You **file** finished annotated docs here for Claude to pull | `flatten.sh` (searched first) |

Get a resolved path for a raw `cp`:
```bash
DOC="$(.claude/skills/manta/paths.sh)"            # Document root
INBOX="$(.claude/skills/manta/paths.sh --inbox)"  # send target
EXPORTS="$(.claude/skills/manta/paths.sh --exports)"  # pull source
```

## Scripts (in this skill's directory)

| Command | What it does |
|---|---|
| `editorial.sh <input.md> [--to-manta \| --to <path>]` | Markdown → editorial PDF. Default: `~/Downloads/<name> - PRINT EDITORIAL.pdf`. `--to-manta` drops into the review inbox (created if missing); `--to <path>` writes anywhere — use it to review locally before sending. |
| `flatten.sh <name-or-path> [--to <path>]` | Composite `.pdf.mark` annotations onto the source PDF. Finds the source in the `Exports` folder first (then inbox/root/recursive). Default output: `~/Downloads/<name> annotated.pdf`. Auto-builds the venv at `~/.cache/manta/.venv` on first run. |

`editorial.sh` resolves its CSS via `$BASH_SOURCE`; `flatten.sh` keeps its venv at `~/.cache/manta`. Both `source paths.sh` for the device folder, so run from anywhere.

## Sending a file TO the Manta

Review locally first (recommended), then send:
```bash
.claude/skills/manta/editorial.sh "path/to/doc.md" --to /tmp/preview.pdf   # inspect
.claude/skills/manta/editorial.sh "path/to/doc.md" --to-manta              # send
```

For an existing PDF, drop it into the inbox (the `--inbox` path is created on first send by `editorial.sh`; `mkdir -p` it for a raw `cp`):
```bash
INBOX="$(.claude/skills/manta/paths.sh --inbox)"; mkdir -p "$INBOX"
cp source.pdf "$INBOX/<Title> - PRINT EDITORIAL.pdf"
```

## Verify sync

A `cp`/`--to-manta` only reaches the device if Partner.app is running. Check it, then confirm the file landed in the inbox:
```bash
pgrep -f Supernote >/dev/null || echo "Partner.app not running — nothing will sync"
ls "$(.claude/skills/manta/paths.sh --inbox)"
```
If Partner.app is unfocused, click it briefly to nudge the sync cycle. The file shows up on-device within ~minutes.

## Pulling annotated files FROM the Manta

File finished annotations in the device's **`Exports`** folder, then pull one back:
```bash
.claude/skills/manta/flatten.sh "<Title> - PRINT EDITORIAL"
```
`flatten.sh` looks in `Exports` first, then the inbox and Document root, then anywhere under Document — so it works whether the file was exported or annotated in place.

Output lands in `~/Downloads/<Title> - PRINT EDITORIAL annotated.pdf`. Ink renders black (matches device appearance — color did not help interpretation). If `flatten.sh` can't find the file or reports "no .mark sidecar," sync probably hasn't pushed the annotations back yet — wait for Partner.app, don't assume the page is unmarked.

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

- **Hardcoding the sync path** — the numeric id changes on re-pair. Use `paths.sh` / `sn_resolve_doc`.
- **Passing `--metadata title=` (or `-s`/`--standalone`) to pandoc** — emits a duplicate title block. Let the source's own `# Title` heading be the title.
- **Expecting `##` sections to start new pages** — they don't (see Pagination).
- **Assuming a send worked without Partner.app** — no Partner.app = no sync. Verify it's running.
- **Treating "no .mark sidecar" as unmarked** — usually means sync hasn't completed yet.
- **Black ink is intentional** — matches device appearance; color didn't aid interpretation.
