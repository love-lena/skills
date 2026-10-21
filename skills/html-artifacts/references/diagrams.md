# Explanatory diagrams

Use the diagram as the explanation's visual thesis. A reader should recognize the important abstractions, boundaries, and relationships before reading the surrounding prose. Choose the level of detail that helps the decision; implementation machinery belongs only when it changes the argument.

Prefer custom SVG or deliberate HTML/CSS for standalone pages. Group related components into labelled regions. Label non-obvious relationships, make arrow direction explicit, and distinguish flow types only when their meaning differs. In a Plain document, use horizontal space for topology, then return to a single prose column. In other compositions, integrate the diagram with the chosen reading path.

For substantial diagrams:

- Make relationship directions clear and keep peer nodes at a comparable abstraction level.
- Route parallel branches through explicit split and join points. Give feedback paths their own route. Keep arrows and group labels out of each other's way.
- Keep text legible at the intended size. On narrow displays, reflow or provide local scrolling/full-size access rather than permanently shrinking labels.
- If building an interactive graph that needs exploration, support pan/zoom, Fit/reset, and keyboard navigation. When nodes are draggable, distinguish a drag from a click so panning does not select one. An expanded view can help large graphs. Static illustrations do not require graph controls.
- In an interactive graph, selection may highlight direct relationships and details, but the unselected graph must communicate the basic system on its own.
- Supply a text equivalent for the full flow. Use semantic SVG titles and descriptions; interactive nodes need accessible names and keyboard actions.

[architecture.js](../assets/architecture.js) is the approved 16-component, five-stage example. Its node and edge definitions describe a fictional offline-pack workflow. Adapt those definitions and the companion HTML to the real system; preserve pan, zoom, click suppression, focus handling, and modal cleanup when reusing the interaction code. The small `svg[data-flow]` renderer in [runtime.js](../assets/runtime.js) reflows simple three-node diagrams vertically on narrow pages.

Inspect rendered arrows, labels, boundaries, and feedback paths in each supported appearance and at desktop and mobile widths. Source code alone cannot establish that a graph is readable.
