#!/usr/bin/env python3
"""Reject truncated or binary-corrupted release and design records."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

DOCUMENTS = {
    "docs/CONTINUOUS_IMPROVEMENT.md": (
        400,
        ("# Gorps Evolution", "## Resume procedure", "## NEXT ACTION",
         "DurableTrades=false", "GE-MAP-03v", "GE-CI-01"),
    ),
    "docs/RELEASE_GATES.md": (
        150,
        ("# Gorps Evolution", "## Phase 5", "Config.DurableTrades=false"),
    ),
    "docs/DESIGN_REFERENCES.md": (
        30,
        ("# Gorps Evolution", "## First five minutes", "## Studio acceptance checks"),
    ),
    "docs/RESOURCE_ART.md": (
        50,
        ("# Planet Verdant", "## Roblox Studio acceptance", "## Automated verification"),
    ),
    "docs/UI_QA.md": (
        30,
        ("# Gorps HUD", "## Test in Roblox Studio", "## Remaining release blockers"),
    ),
    "docs/MAP_QA.md": (
        300,
        ("# Planet Verdant", "## Roblox Studio acceptance", "GE-MAP-03v"),
    ),
    "docs/BIOME_ART.md": (
        50,
        ("# Planet Verdant", "## Implemented composition", "## Roblox Studio acceptance"),
    ),
    "docs/RANCH_ART.md": (
        40,
        ("# Planet Verdant", "## Implemented composition", "## Roblox Studio acceptance"),
    ),
    "docs/TRADE_RECOVERY.md": (
        120,
        ("# Durable player-trade recovery contract", "## Safety invariants",
         "DurableTrades` stays false"),
    ),
    "docs/COMPETITOR_DESIGN_RESEARCH.md": (
        180,
        ("# Research-to-build", "Confirmed primary sources", "GE-MAP-03v"),
    ),
    "docs/WORLD_ART_ROADMAP.md": (
        450,
        ("# Planet Verdant", "What is evidence", "GE-MAP-03v"),
    ),
}


def verify(path_text, minimum_lines, anchors):
    path = ROOT / path_text
    raw = path.read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as error:
        raise AssertionError(f"{path_text}: invalid UTF-8 at byte {error.start}") from error

    forbidden = sorted({byte for byte in raw if byte < 32 and byte not in (9, 10, 13)})
    assert not forbidden, f"{path_text}: forbidden control bytes {forbidden}"
    assert not text.startswith("\ufeff"), f"{path_text}: unexpected UTF-8 BOM"

    lines = text.splitlines()
    assert len(lines) >= minimum_lines, (
        f"{path_text}: only {len(lines)} lines; expected >= {minimum_lines}"
    )
    assert text.endswith("\n"), f"{path_text}: missing final newline"
    for anchor in anchors:
        assert anchor in text, f"{path_text}: missing required anchor {anchor!r}"
    return len(lines), len(raw)


def main():
    totals = {}
    for path_text, (minimum_lines, anchors) in DOCUMENTS.items():
        totals[path_text] = verify(path_text, minimum_lines, anchors)
    line_total = sum(lines for lines, _ in totals.values())
    byte_total = sum(size for _, size in totals.values())
    print(
        "PASS: repository documentation integrity; "
        f"files={len(totals)}, lines={line_total}, bytes={byte_total}"
    )


if __name__ == "__main__":
    main()
