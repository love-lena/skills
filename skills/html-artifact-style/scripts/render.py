#!/usr/bin/env python3
"""Render approved Plain examples or an authored HTML body into standalone HTML."""
import argparse
import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
SHAPES = {
    "document": ("index.html", "Document"),
    "dashboard": ("dashboard.html", "Dashboard"),
    "status": ("status.html", "Status board"),
    "comparison": ("comparison.html", "Comparison"),
    "system": ("system.html", "System explainer"),
}


def render(shape, title, content=None, extra_css="", extra_js="", dashboard_dir=None, gallery=False):
    css = (ASSETS / "plain.css").read_text()
    js = (ASSETS / "runtime.js").read_text()
    if content is None and shape == "dashboard":
        dashboard = dashboard_dir or ASSETS / "dashboard"
        css = "@layer base {" + css + "}\n" + (dashboard / "dist/theme.css").read_text()
        js += "\n" + (dashboard / "dist/app.js").read_text()
        body = '<div id="log-root"></div><noscript>This interactive dashboard requires JavaScript.</noscript>'
    else:
        body = content if content is not None else (ASSETS / "shapes" / f"{shape}.html").read_text()
        if content is None and shape == "system":
            js += "\n" + (ASSETS / "architecture.js").read_text()
    css += "\n" + extra_css
    js += "\n" + extra_js
    controls = ''
    if gallery:
        options = ''.join(
            f'<option value="{filename}"{" selected" if key == shape else ""}>{label}</option>'
            for key, (filename, label) in SHAPES.items()
        )
        controls += f'<label>Page shape · Plain style<select data-control="shape">{options}</select></label>'
    controls += '<label>Appearance<select data-control="appearance"><option value="system">Follow system</option><option value="light">Light</option><option value="dark">Dark</option></select></label>'
    if gallery:
        controls += '<label>Preview width<select data-control="width"><option value="desktop">Desktop</option><option value="mobile">Mobile — 390 px</option></select></label>'
    else:
        css += '\n.artifact-controls{max-width:1180px;margin:auto;padding:16px 32px 0;display:flex;justify-content:flex-end}.artifact-controls label{display:flex;gap:8px;align-items:center;font-size:12px;color:var(--quiet)}.artifact-controls select{font-size:12px;min-height:32px;padding:4px 8px}@media print{.artifact-controls{display:none}}'
    nav_class = "sampler-controls" if gallery else "artifact-controls"
    # End-tag escapes protect the embedding boundary while retaining JS strings.
    js = re.sub(r"</script", r"<\\/script", js, flags=re.I)
    css = re.sub(r"</style", r"<\\/style", css, flags=re.I)
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="light dark"><title>{html.escape(title)}</title><link rel="icon" href="data:,"><style>{css}</style></head>
<body><nav class="{nav_class}" aria-label="{'Example preview' if gallery else 'Artifact appearance'}">{controls}</nav><main class="page"><article class="content">{body}</article></main><script>{js}</script></body></html>
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--output", type=Path, help="Write one self-contained HTML file")
    target.add_argument("--gallery", action="store_true", help="Render all five approved examples with preview controls")
    parser.add_argument("--output-dir", type=Path, help="Directory for --gallery")
    parser.add_argument("--shape", choices=SHAPES, default="document")
    parser.add_argument("--title", help="Browser tab title")
    parser.add_argument("--content", type=Path, help="Authored HTML body fragment; otherwise use illustrative example content")
    parser.add_argument("--css", type=Path, help="Additional CSS to embed")
    parser.add_argument("--script", type=Path, help="Additional JavaScript to embed")
    parser.add_argument("--dashboard-dir", type=Path, help="Adapted dashboard directory containing dist/app.js and dist/theme.css")
    args = parser.parse_args()
    if args.gallery and not args.output_dir:
        parser.error("--gallery requires --output-dir")
    if args.gallery and any((args.content, args.css, args.script, args.title)):
        parser.error("Use --output for custom content, CSS, JavaScript, or title")
    if args.output_dir and not args.gallery:
        parser.error("--output-dir requires --gallery")
    if args.dashboard_dir and (args.content or (not args.gallery and args.shape != 'dashboard')):
        parser.error("--dashboard-dir applies to the dashboard application, without --content")
    if args.gallery:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        for shape, (filename, label) in SHAPES.items():
            output = args.output_dir / filename
            output.write_text(render(shape, label + " — Plain examples", dashboard_dir=args.dashboard_dir, gallery=True))
            print(output.resolve())
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(render(
            args.shape, args.title or SHAPES[args.shape][1],
            content=args.content.read_text() if args.content else None,
            extra_css=args.css.read_text() if args.css else "",
            extra_js=args.script.read_text() if args.script else "",
            dashboard_dir=args.dashboard_dir,
        ))
        print(args.output.resolve())


if __name__ == "__main__":
    main()
