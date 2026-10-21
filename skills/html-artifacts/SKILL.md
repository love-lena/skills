---
name: html-artifacts
description: Create standalone HTML documents, dashboards, prototypes, and visual explainers. Use Plain by default or expressive Fancy compositions when requested. Preserve an existing product's design system when editing its application UI.
---

# HTML Artifacts

One entrypoint for presentation and visual explanation. Content workflows still determine the argument, evidence, status, and decisions; this skill determines how the reader encounters and works with them.

## Choose the presentation

| Request | Read |
| --- | --- |
| Unspecified, simple, or Plain | [Plain](references/plain.md), the default |
| Fancy, expressive, or a named composition | [Fancy](references/fancy.md), then the chosen style guide |
| Edit an existing artifact | Preserve its established design unless the user requests a change; use the relevant guide |

For Fancy, choose one composition suited to the task unless the user requests alternatives. Explain the choice briefly and proceed; no preference questionnaire is needed. Explicit user references and styling choices take precedence over these defaults.

When the task is to **teach through visuals**, also read [Visual Explainer](references/visual-explainer.md). This is a teaching method that combines with either presentation. A dashboard or form alone does not call for it. Picture-led explanation defaults to Plain unless Fancy is requested.

For substantial relationship diagrams, read [Diagrams](references/diagrams.md). For a dense Plain data explorer, read [Dashboards](references/dashboard.md). Load only the branches needed.

## Build and inspect

- Use semantic HTML for real tables, forms, and controls; SVG for precise visual relationships. A pictured control in an SVG is a mockup, not a working prototype. Implement the requested interactions and distinguish illustrative data from live state.
- Preserve facts, units, uncertainty, and relationship meaning through composition changes. For substantial diagrams, provide a text equivalent as well as accessible SVG labels.
- Copy or adapt resources into the task workspace. Prefer self-contained HTML; bundle dependencies when needed. The installed examples are calibration material, not task output locations.
- Inspect the rendered result at desktop and around 390 px. Check text contrast, label/path collisions, local overflow, keyboard operation of implemented controls, and every supported appearance. If a large figure needs scrolling or a full-size view, make that access clear.
- When producing alternatives, compare their thumbnails as well as full-size renders. Entry point, reading order, density, proportions, dominant object, and use of empty space should distinguish them even in grayscale.
- Open the finished artifact when useful and report any verification that could not be completed. Creating a local artifact does not itself publish it.

## Publishing and compatibility

When asked to upload to artifacts.lena.dog, use the separately installed `upload-artifact` skill. Its hosted sandbox constraints affect packaging and supported interactions; read them before building when hosting is already requested. This skill is otherwise independent of that service.

All rendering resources and style guidance live here. `html-artifact-style`, `fancy-html-artifacts`, and `visual-explainer` are optional compatibility entrypoints; this folder works without them.
