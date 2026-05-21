# change-story

An open agent skill for telling the story of a code change — a single PR, a stack of PRs, or any diff — as a two-column walkthrough.

- **Left column** — a continuous prose chapter that names the change and tells the reader what to care about.
- **Right column** — a surface-grouped *code map* that covers every hunk in the diff and frames the load-bearing ones with paragraphs of context.

The prose names *consequences* and points "chips" (line-range markdown links) at the map; the map covers every hunk and explains the *mechanics* next to the code. Standard diff views fragment a multi-file or stacked change into a flat list of hunks; this skill formalizes the discipline of separating the story from the evidence so the reviewer doesn't have to re-derive the shape of the work from scratch.

## Install

For Claude Code, Cursor, Codex, OpenCode and the other agents that support the [`skills`](https://skills.sh) CLI:

```bash
npx skills add love-lena/change-story
```

Or globally, across all projects:

```bash
npx skills add love-lena/change-story -g
```

## What it produces

Three artifacts:

- `prose.md` — the continuous chapter (left column).
- `map.md` — the surface-grouped code map (right column).
- `diff.patch` — the raw unified diff, verbatim.

The format is portable markdown. The three files are readable on their own; a renderer that understands the chip-and-fence convention can also lay them out as a two-column page.

## Format at a glance

- **Chips** in the prose: `[label](path/to/file.ts#L7-L13)` — standard markdown link with a GitHub-style line-range fragment.
- **Hunk fences** in the map: `` ```diff path="..." lines="A-B" `` with an empty body. A renderer slices the matching lines out of `diff.patch`.
- **Comprehensive map, curated prose.** Every hunk in the diff appears in the map. The prose names what to care about.

See [`SKILL.md`](./SKILL.md) for the full spec and writing discipline.

## License

MIT.
