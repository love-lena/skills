# Dense dashboards

The approved example is a log explorer with 10,690 synthetic events, shared filters, a volume histogram, and Logs / Patterns / Services / Live tail views. Treat it as a reference for information hierarchy, not a requirement to turn every dashboard into log search.

## Hierarchy and interaction

Make search the primary surface: a generous field and clear submit action, with quieter, consistently aligned filters below. Keep example queries in the search region as neutral actions. Separate search from its results with a clear boundary.

Use a compact title line. Put capture time and snapshot/replay state with the search overview, where they qualify the data. Avoid floating badges detached from their meaning.

A shared chart belongs in the overview. Place result tabs at the top of a visibly bounded panel below it; use generous hit areas and an active underline attached to that panel. A tab-specific graph belongs inside that tab. Name or explain selection scope when a chart filters only part of the page.

Make the entire record row clickable for expansion, retaining a native button for keyboard access. Keep secondary actions inside expanded details or explicitly separate controls, and prevent their clicks from toggling the parent. Use a bounded table viewport and pagination or virtualization for large results. Offer full fields and raw records without widening the whole page.

Calculate counts, rates, percentiles, and plots from the same stated selection. Show denominators for rates and gaps for missing chart observations. Search syntax errors, no matches, paused updates, and simulation state should be visible. A tail needs pause/resume and a bounded buffer; it should not force movement while a reader is inspecting paused records.

## Reuse the source

`assets/dashboard/src/` contains the approved React example using actual shadcn/ui cards, tabs, buttons, badges, tables, tooltips, and chart wrappers with Recharts. Source and lockfile are included; `dist/` permits immediate rendering without installation. The example's native filters are intentional. Retain its Plain palette instead of importing a second theme.

Copy `assets/dashboard/` into the task workspace before adapting it. Edit `src/App.tsx`, `src/data.ts`, and `src/workbench.css` there, then build from that copy:

```bash
npm ci --no-audit --no-fund
node build.mjs
npx @tailwindcss/cli -i src/workbench.css -o dist/theme.css --minify
```

Render from the skill directory using the adapted bundle:

```bash
python3 scripts/render.py --shape dashboard --dashboard-dir /path/to/copied-dashboard --title "Activity" --output /tmp/activity.html
```

Replace synthetic fields and generation with task-appropriate data; connect a real service only when the task authorizes it. Preserve source licenses and notices when bundling. For a small dashboard, use semantic HTML and small scripts instead of inheriting this entire application.
