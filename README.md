# lena's skills

A collection of [open agent skills](https://skills.sh) for Claude Code, Cursor, Codex, OpenCode, and the other agents that support the [`skills`](https://skills.sh) CLI.

## Install

All skills:

```bash
npx skills add love-lena/skills
```

A specific skill:

```bash
npx skills add love-lena/skills --skill change-story
```

Globally (available across all projects):

```bash
npx skills add love-lena/skills -g
```

## Skills

### [`change-story`](./skills/change-story/SKILL.md)

Tell the story of a code change — a single PR, a stack of PRs, or any diff — as a two-column walkthrough:

- **Left column** — a continuous prose chapter that names the change and tells the reader what to care about.
- **Right column** — a surface-grouped *code map* that covers every hunk in the diff and frames the load-bearing ones with paragraphs of context.

The prose names *consequences* and points "chips" (line-range markdown links) at the map; the map covers every hunk and explains the *mechanics* next to the code.

Outputs three portable markdown artifacts: `prose.md`, `map.md`, `diff.patch`. The files are readable on their own; a renderer that understands the chip-and-fence convention can also lay them out as a two-column page.

## License

[MIT](./LICENSE).
