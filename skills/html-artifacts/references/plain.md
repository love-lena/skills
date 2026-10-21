# Plain

The default presentation: neutral system sans-serif, quiet rules and surfaces, and one restrained accent. A clear hierarchy comes from alignment, spacing, and meaning. Use the supplied light/dark tokens, follow the system initially, and provide an explicit appearance choice.

## Choose a shape

| Shape | Use when | Starting material |
| --- | --- | --- |
| Document | An argument, report, or explanation needs a reading path | [document.html](../assets/shapes/document.html) |
| Dashboard | Search, measurements, and many records need exploration | [dashboard guide](dashboard.md), [source](../assets/dashboard/src/App.tsx) |
| Status board | Current position, blockers, next action, and path to done matter | [status.html](../assets/shapes/status.html) |
| Comparison | Aligned criteria support a recommendation | [comparison.html](../assets/shapes/comparison.html) |
| System explainer | Boundaries, dependencies, and failure behavior are central | [diagram guide](diagrams.md), [system.html](../assets/shapes/system.html), [architecture.js](../assets/architecture.js) |

These examples are starting points, not required section lists or factual inputs. Replace their names, claims, metrics, and diagram models. Label illustrative data when the requested artifact is a mockup.

## Composition and interaction

- Bound prose to a comfortable reading width with generous margins. Stack independent prose and content sections. Use horizontal space for meaningful diagram relationships, aligned comparisons, or related measurements.
- Use economical titles. Keep metadata beside the content it qualifies and attach tabs to the region they control.
- Make the primary action dominant; align related controls. Separate input, summaries, and detailed results with space and quiet boundaries.
- Use numbered footnotes with return links for short definitions, sources, and qualifications. Use disclosure for longer optional detail. Keep decision-changing uncertainty visible.
- Reflow narrow layouts while keeping text readable. Confine necessary scrolling to a dense table or diagram. Inspect light and dark appearances.

## Render

Use [plain.css](../assets/plain.css) and [runtime.js](../assets/runtime.js). Run these commands from this skill's root:

```sh
python3 scripts/render.py --gallery --output-dir /tmp/plain-examples
python3 scripts/render.py --shape document --content /path/to/body.html --title "Proposal" --output /path/to/proposal.html
```

The first command renders all five examples. The second embeds an authored semantic HTML body in a self-contained page. `scripts/render.py --help` describes custom CSS, JavaScript, and dashboard source options. Gallery controls belong only to the example gallery; ordinary artifacts get an appearance control.

For a small dashboard, use semantic HTML and small scripts. The bundled React example is useful when its search, filtering, charts, and record exploration match the task. The supplied CSS targets current browsers with `light-dark()`, `color-mix()`, and container queries; adapt it when the user needs older browser support.
