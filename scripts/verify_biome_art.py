#!/usr/bin/env python3
"""Validate the authored Planet Verdant forest and terrain art contracts.

This guards asset variety, route spacing and a static part budget. It does not
claim Roblox Studio render quality, avatar navigation or device performance.
"""
from __future__ import annotations

from collections import Counter
import math
import sys
import xml.etree.ElementTree as ET


ARCHETYPES = {
    "Broadleaf": {"BroadleafTrunk", "CrownBranch", "CrownMain", "CrownLeft", "CrownRight"},
    "Pine": {"PineTrunk", "PineBough_0", "PineBough_1", "PineBough_2", "PineBough_3", "PineTip"},
    "Birch": {"BirchTrunk", "BirchBand_0", "BirchBand_1", "BirchCrown", "BirchCrownHigh"},
    "Ancient": {"AncientTrunk", "AncientBranch", "AncientFan"},
}


def props(item):
    return item.find("Properties")


def value(item, property_name, default=None):
    properties = props(item)
    entries = properties if properties is not None else []
    return next((entry.text for entry in entries if entry.get("name") == property_name), default)


def children(item):
    return [child for child in item if child.tag == "Item"]


def position(item):
    properties = props(item)
    frame = next(entry for entry in properties if entry.get("name") == "CFrame")
    return float(frame.find("X").text), float(frame.find("Z").text)


def validate(path):
    root = ET.parse(path).getroot()
    named = {}
    for item in root.iter("Item"):
        named.setdefault(value(item, "Name", ""), []).append(item)

    trees = []
    counts = Counter()
    for model in root.iter("Item"):
        if model.get("class") != "Model":
            continue
        name = value(model, "Name", "")
        if not name.startswith("CanopyTree_"):
            continue
        archetype = next((kind for kind in ARCHETYPES if f"_{kind}_" in name), None)
        assert archetype is not None, (path, name, "unknown forest archetype")
        parts = children(model)
        part_names = {value(part, "Name", "") for part in parts}
        missing = ARCHETYPES[archetype] - part_names
        assert not missing, (path, name, "missing silhouette pieces", sorted(missing))
        assert not any(part.startswith("Leaves_") for part in part_names), (
            path, name, "regressed to generic three-ball canopy"
        )
        if archetype in {"Pine", "Ancient"}:
            assert any(part.get("class") == "WedgePart" for part in parts), (
                path, name, "missing angular silhouette"
            )
        trunk = next(part for part in parts if "Trunk" in value(part, "Name", ""))
        assert value(trunk, "CanCollide") == "true", (path, name, "trunk collision missing")
        for part in parts:
            if any(token in value(part, "Name", "") for token in ("Crown", "Bough", "Fan", "Tip")):
                assert value(part, "CanCollide") == "false", (
                    path, name, value(part, "Name"), "foliage blocks players"
                )
        trees.append((name, position(trunk)))
        counts[archetype] += 1

    assert counts == Counter({kind: 16 for kind in ARCHETYPES}), (
        path, "forest variety drifted", counts
    )
    for index, (name, point) in enumerate(trees):
        x, z = point
        assert not (abs(x) < 20 and 35 < z < 302), (
            path, name, "tree blocks main resource route", point
        )
        for other_name, other in trees[index + 1:]:
            assert math.dist(point, other) >= 11.9, (
                path, name, other_name, "tree silhouettes overlap"
            )

    assert len(named.get("BiomeSurfaces", [])) == 1, (path, "missing biome surface layer")
    assert sum(len(named.get(f"BiomeFloor_{index:02d}", [])) for index in range(12)) == 12
    assert sum(len(named.get(f"FallenLog_{index}", [])) for index in range(6)) == 6
    assert sum(len(named.get(f"LogMoss_{index}", [])) for index in range(6)) == 6
    assert len(named.get("Glowcap", [])) == 16, (path, "glowcap density drifted")
    assert len(named.get("GlowDot", [])) == 32, (path, "glowcap light budget drifted")
    assert all(value(cap, "Material") == "1568" for cap in named.get("Glowcap", [])), (
        path, "glowcaps must use Glass instead of broad Neon caps"
    )

    base_parts = [item for item in root.iter("Item") if item.get("class") in {"Part", "WedgePart"}]
    assert len(base_parts) <= 2350, (path, "static BasePart budget exceeded", len(base_parts))
    print(
        f"PASS {path}: four 16-tree silhouettes, 12 biome fields, six fallen logs, "
        f"16 glass glowcaps, {len(base_parts)} static parts"
    )


for artifact in sys.argv[1:]:
    validate(artifact)
