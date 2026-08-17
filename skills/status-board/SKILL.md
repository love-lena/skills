---
name: status-board
description: Create or update a self-contained HTML status board for an active pull-request stack, project roadmap, milestone sequence, or coding session. Use when the user asks for a status board or needs current state, blockers, and next action made visible. Optimize for dependent PRs and the engineer driving them.
---

# Status board

A status board is a **present-tense decision surface** for the engineer driving the work. It makes current position, active blockers, and the highest-leverage next action obvious within five seconds.

This skill specifies the board, not its research workflow. Use available context, tools, and other skills to establish facts.

## Deliver the artifact

- Update an existing status-board artifact or HTML file in place. Create a parallel snapshot only when the user asks.
- Otherwise follow project or agent guidance for artifact location; fall back to `/tmp`.
- Produce one self-contained HTML file. Inline any CSS, JavaScript, or SVG; load no external runtime, CDN, font, image, or stylesheet.
- In Claude Code, use the Claude artifact tool when available.
- Use `$caveman` when available to compress visible copy without losing technical substance. It is optional.

## Build the shipping spine

Keep these elements in order. The rest of the board is conditional.

1. **Current position.** Lead with an outcome-oriented headline that names the phase, gate, or result. Add one short orienting sentence only when needed.
2. **Next move.** Make the single highest-leverage action the first and most visually prominent line item. Name the PR, decision, command, review, deploy, or verification step precisely enough to execute.
3. **Active units.** Show PRs or equivalent units in dependency or shipping order. Put each unit's next action first, followed by its purpose, precise current state, dependency, and active review or check blocker. Link identifiers when links are available.
4. **Path to shipped.** Show the complete ordered sequence from now to done. Keep steps short and testable; expose parallel branches and convergence points.

Prefer states such as `ready to merge`, `needs review`, `checks failing`, `draft`, and `blocked by #123` over unlabeled red/yellow/green status.

The shipping spine is complete when reading it alone answers where the work is, what blocks it, and what to do next.

## Apply the present-tense filter

Every visible statement must change what the human understands or does now.

- Remove resolved blockers, obsolete explanations, and superseded paths on every update.
- Keep history only when it changes a current human decision or prevents a current mistake.
- Leave code-level bugs, implementation notes, and agent instructions in their plan or spec files unless the human must act on them.
- Translate plans into current gates and shipping order instead of reproducing them.
- Omit unsupported claims. When missing information itself changes the next action, label the gap briefly as `unknown`, `needs decision`, or `needs verification`.
- State the useful status directly. Leave out research logs, confidence commentary, source-verification narration, and changelogs.

## Add context that earns space

Add a section only when it changes understanding or action:

- **Dependency map** for branching stacks, parallel tracks, or non-obvious ordering.
- **Milestones** when broader stages have observable exit gates.
- **Rollout sequence** for deploys, canaries, migrations, policy changes, or manual operations outside the merge path.
- **Open decisions, risks, or constraints** when they block or materially reshape the path.
- **Architecture** when a boundary or ownership detail explains a dependency, rollout, or decision.

Use inline SVG for relationships that benefit from spatial explanation. Give each diagram `role="img"` and a useful `aria-label`. Prefer prose or a short list when space adds no meaning.

## Use an editorial planning-map aesthetic

- Build on an off-white or near-white canvas with dark ink, muted blue-gray structure, and sparse teal or amber status accents.
- Use a strong headline, readable body, small tracked monospace labels, thin rules, numbered sections, generous spacing, and dense but uncrowded information.
- Encode dependencies with aligned nodes, rails, arrows, and lines. Let structure carry meaning.
- Prefer a clear reading path and mostly flat sections over generic card grids, KPI tiles, decorative gradients, excessive rounded containers, glass effects, or ornamental charts.
- Make the page responsive and printable. Reflow the hierarchy on narrow screens instead of shrinking a desktop canvas.
- Use JavaScript only when interaction helps navigate or hide secondary detail. Keep the board legible without it.

## Completion criteria

Finish only when:

- A five-second read yields current position, active blocker, and next move.
- The shipping spine's dependencies agree with its path to shipped.
- Every conditional section passes the present-tense filter.
- The self-contained HTML opens locally and remains readable at desktop and mobile widths.
