---
name: html-artifact-style
description: Create or restyle standalone HTML documents, dashboards, status boards, comparisons, and system explainers in Lena's Plain style. Use for HTML artifacts and reusable page layouts; preserve an existing product's design system when editing its application UI.
---

# Plain HTML artifacts

Apply a consistent visual language while preserving the artifact's purpose. Content-specific workflows still decide the argument, evidence, status, and decisions; this skill supplies presentation and interaction.

## Build from the approved shapes

Choose the closest shape, then adapt its structure to the actual content:

| Shape | Use when | Starting material |
| --- | --- | --- |
| Document | An argument, RFC, report, or explanation needs a reading path | `assets/shapes/document.html` |
| Dashboard | Search, measurements, and many records need exploration | Read [dashboard.md](references/dashboard.md); adapt `assets/dashboard/` |
| Status board | Current position, blockers, next action, and path to done matter | `assets/shapes/status.html` |
| Comparison | Aligned criteria should support a recommendation | `assets/shapes/comparison.html` |
| System explainer | Components, boundaries, dependencies, and failure behavior are central | Read [diagrams.md](references/diagrams.md); start from `assets/shapes/system.html` and `assets/architecture.js` |

These are approved examples, not required section lists or factual inputs. Replace example names, claims, metrics, and diagram models for the user's task. Keep illustrative data explicitly labelled when the requested artifact is itself a mockup.

Use `assets/plain.css` for shared tokens and layout. Render the examples with:

```bash
python3 scripts/render.py --gallery --output-dir /tmp/plain-examples
```

For an ordinary artifact, write its semantic HTML body and render a self-contained file:

```bash
python3 scripts/render.py --shape document --content /tmp/body.html --title "Design proposal" --output /tmp/proposal.html
```

Paths in these commands are relative to this skill's directory. Run `scripts/render.py --help` for custom CSS, JavaScript, and dashboard source options. Gallery controls are for comparing examples; ordinary outputs include only an appearance control. Put task outputs in the task workspace or a user-chosen destination, leaving the installed skill unchanged.

## Visual defaults

- **Plain only:** neutral system sans-serif, quiet rules and surfaces, one restrained accent. Use the supplied light and dark tokens; follow the system initially and provide an explicit appearance choice.
- **Desktop first, responsive:** give prose a bounded reading width and generous margins. Reflow mobile layouts while keeping text readable. Confine necessary horizontal scrolling to dense tables or diagrams.
- **One reading column:** stack independent prose and content blocks vertically. Use horizontal arrangement for meaningful relationships inside a diagram, aligned comparisons, or a compact strip of related measurements.
- **Economical headers:** use a title and only context that helps the reader act. Keep metadata beside the content it describes. A title sandwiched between an eyebrow and a redundant subtitle wastes space, especially in dashboards.
- **Visible hierarchy:** make the primary action dominant, align related controls, and separate inputs, summaries, and detailed results with clear spacing and boundaries. Attach tabs to the region they control.
- **Secondary detail:** prefer inline numbered footnotes for short qualifications, definitions, and sources, with a return link. Use disclosure for longer optional detail. Keep decision-changing uncertainty in the main flow. The document shape demonstrates footnotes.

For substantial graphs, read [diagrams.md](references/diagrams.md). For dense interactive data, read [dashboard.md](references/dashboard.md). Load only the branch needed.

## Deliver the actual page

Produce real HTML and inspect it in a browser; embedded conversation widgets are not the visual reference for this style. Prefer a single file with embedded CSS, JavaScript, and required assets. Bundle dependencies when the interaction warrants them; ordinary documents need only HTML, CSS, and small scripts.

Before delivery, inspect the rendered desktop layout and a narrow layout around 390 px, check light and dark appearances, and exercise the interactions changed for this artifact. Verify readable diagrams, local rather than page-wide overflow, meaningful empty states, and working footnote/return links where present. Open the finished page in Codex's browser when available and requested or useful. Report any rendering or interaction checks that could not be completed.
