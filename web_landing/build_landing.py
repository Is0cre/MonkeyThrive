#!/usr/bin/env python3
"""Render the landing pages from web_landing/copy/*.json.

English is written to the site root. Any other locale file becomes a folder
with the same name, for example copy/sv.json -> sv/index.html. A language is
published only when its file exists. The script fills the CSP hash from the
JSON-LD actually written into each page.
"""

from __future__ import annotations

import base64
import hashlib
import html
import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent
COPY = ROOT / "copy"
SITE = "https://monkeythrive.app"
STRUCTURAL = {
    "lang",
    "dir",
    "ogLocale",
    "canonical",
    "alternates",
    "langSwitch",
    "cspSource",
}
LOCALE_NAME = re.compile(r"^[a-z]{2}(?:-[A-Z]{2})?$")
PLACEHOLDER = re.compile(r"\{\{([A-Za-z0-9]+)\}\}")


def load_locales() -> list[dict]:
    files = sorted(COPY.glob("*.json"))
    if not files:
        raise SystemExit(f"no locale files in {COPY}")
    locales = []
    for path in files:
        code = path.stem
        if not LOCALE_NAME.fullmatch(code):
            raise SystemExit(f"{path.name} is not a locale code such as sv or pt-BR")
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("lang") != code:
            raise SystemExit(f"{path.name} lang must be {code}")
        for field in ("dir", "ogLocale", "name", "strings"):
            if field not in data:
                raise SystemExit(f"{path.name} is missing {field}")
        if not isinstance(data["strings"], dict):
            raise SystemExit(f"{path.name} strings must be an object")
        data["_code"] = code
        locales.append(data)
    codes = [item["_code"] for item in locales]
    if "en" not in codes:
        raise SystemExit("copy/en.json is required")
    locales.sort(key=lambda item: (item["_code"] != "en", item["_code"]))
    return locales


def page_url(code: str, page: str) -> str:
    prefix = "" if code == "en" else f"/{code}"
    if page == "index":
        return "/" if code == "en" else f"{prefix}/"
    return f"{prefix}/safety.html"


def absolute(url: str) -> str:
    return SITE if url == "/" else f"{SITE}{url}"


def alternates(locales: list[dict], page: str) -> str:
    lines = []
    for item in locales:
        href = absolute(page_url(item["_code"], page))
        lines.append(
            f'  <link rel="alternate" hreflang="{item["lang"]}" href="{href}">'
        )
    default = absolute(page_url("en", page))
    lines.append(f'  <link rel="alternate" hreflang="x-default" href="{default}">')
    for item in locales:
        if item["_code"] == "en":
            continue
        lines.append(
            f'  <meta property="og:locale:alternate" content="{item["ogLocale"]}">'
        )
    return "\n".join(lines)


def language_switch(locales: list[dict], current: dict, page: str) -> str:
    if len(locales) < 2:
        return ""
    label = html.escape(current["strings"]["languagesLabel"], quote=True)
    links = []
    for item in locales:
        href = page_url(item["_code"], page)
        current_attr = ' aria-current="page"' if item is current else ""
        name = html.escape(item["name"], quote=True)
        links.append(
            f'<a href="{href}" hreflang="{item["lang"]}"{current_attr}>{name}</a>'
        )
    return f'<nav class="langs" aria-label="{label}">{"".join(links)}</nav>'


def apply_strings(template: str, strings: dict[str, str]) -> str:
    rendered = template
    for key, value in strings.items():
        token = "{{" + key + "}}"
        if key == "jsonLdDescription":
            replacement = json.dumps(value, ensure_ascii=False)[1:-1]
        else:
            replacement = html.escape(value, quote=True)
        count = rendered.count(token)
        if count == 0:
            continue
        rendered = rendered.replace(token, replacement)
    return rendered


def csp_hash(page: str) -> str:
    match = re.search(
        r'<script type="application/ld\+json">(.*?)</script>',
        page,
        flags=re.S,
    )
    if match is None:
        raise SystemExit("index template is missing the JSON-LD script")
    digest = hashlib.sha256(match.group(1).encode("utf-8")).digest()
    return "sha256-" + base64.b64encode(digest).decode("ascii")


def render_index(template: str, locales: list[dict], current: dict) -> str:
    """Fill the index, then set the CSP hash from the finished JSON-LD."""
    strings = current["strings"]
    rendered = apply_strings(template, strings)
    canonical = absolute(page_url(current["_code"], "index"))
    structural = {
        "lang": current["lang"],
        "dir": current["dir"],
        "ogLocale": html.escape(current["ogLocale"], quote=True),
        "canonical": canonical,
        "alternates": alternates(locales, "index"),
        "langSwitch": language_switch(locales, current, "index"),
    }
    for key, value in structural.items():
        rendered = rendered.replace("{{" + key + "}}", value)
    digest = csp_hash(rendered)
    rendered = rendered.replace("{{cspSource}}", digest, 1)
    leftover = PLACEHOLDER.findall(rendered)
    if leftover:
        raise SystemExit(f"unfilled index placeholders: {', '.join(leftover)}")
    return rendered


def render_safety(template: str, locales: list[dict], current: dict) -> str:
    strings = current["strings"]
    rendered = apply_strings(template, strings)
    canonical = absolute(page_url(current["_code"], "safety"))
    structural = {
        "lang": current["lang"],
        "dir": current["dir"],
        "canonical": canonical,
        "alternates": alternates(locales, "safety"),
        "langSwitch": language_switch(locales, current, "safety"),
    }
    for key, value in structural.items():
        rendered = rendered.replace("{{" + key + "}}", value)
    leftover = PLACEHOLDER.findall(rendered)
    if leftover:
        raise SystemExit(f"unfilled safety placeholders: {', '.join(leftover)}")
    return rendered


def sitemap(locales: list[dict]) -> str:
    today = date.today().isoformat()
    urls = []
    for page, priority, freq in (
        ("index", "1.0", "monthly"),
        ("safety", "0.5", "yearly"),
    ):
        for item in locales:
            loc = absolute(page_url(item["_code"], page))
            links = []
            for alt in locales:
                href = absolute(page_url(alt["_code"], page))
                links.append(
                    f'    <xhtml:link rel="alternate" hreflang="{alt["lang"]}" href="{href}"/>'
                )
            links.append(
                f'    <xhtml:link rel="alternate" hreflang="x-default" href="{absolute(page_url("en", page))}"/>'
            )
            body = "\n".join(links)
            urls.append(
                "  <url>\n"
                f"    <loc>{loc}</loc>\n"
                f"{body}\n"
                f"    <lastmod>{today}</lastmod>\n"
                f"    <changefreq>{freq}</changefreq>\n"
                f"    <priority>{priority}</priority>\n"
                "  </url>"
            )
    joined = "\n".join(urls)
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
        '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
        f"{joined}\n"
        "</urlset>\n"
    )


def required_keys(index: str, safety: str) -> set[str]:
    return set(PLACEHOLDER.findall(index + safety)) - STRUCTURAL


def build(output: Path) -> None:
    locales = load_locales()
    index_template = (ROOT / "index.html").read_text(encoding="utf-8")
    safety_template = (ROOT / "safety.html").read_text(encoding="utf-8")
    needed = required_keys(index_template, safety_template) | {"languagesLabel"}
    for item in locales:
        missing = sorted(needed - set(item["strings"]))
        if missing:
            raise SystemExit(f'{item["_code"]} is missing {", ".join(missing)}')
    output.mkdir(parents=True, exist_ok=True)
    for item in locales:
        folder = output if item["_code"] == "en" else output / item["_code"]
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "index.html").write_text(
            render_index(index_template, locales, item),
            encoding="utf-8",
        )
        (folder / "safety.html").write_text(
            render_safety(safety_template, locales, item),
            encoding="utf-8",
        )
    (output / "sitemap.xml").write_text(sitemap(locales), encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: build_landing.py OUTPUT_DIR")
    build(Path(sys.argv[1]))


if __name__ == "__main__":
    main()
