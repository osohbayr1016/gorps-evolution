#!/usr/bin/env python3
"""Static contract for the first-session map route in source and Rojo output.

This validates authored positions and silhouettes only. It cannot establish
Roblox character navigation, visibility, device FPS, or visual art quality.
"""
from __future__ import annotations

import math
import sys
import xml.etree.ElementTree as ET


RESOURCE_TYPES = {"Tree", "Rock", "Ore", "Bush", "Crystal", "Fiber", "Wild"}
STARTER = {
    "Tree_001": (-42.0, 68.0),
    "Tree_002": (42.0, 68.0),
    "Rock_003": (64.0, 92.0),
    "Ore_004": (92.0, 122.0),
    "Bush_005": (-64.0, 92.0),
    "Crystal_006": (-92.0, 122.0),
    "Fiber_007": (-45.0, 132.0),
    "Wild_008": (55.0, 155.0),
}


def properties(item):
    return item.find("Properties")


def value(item, prop_name, default=None):
    props = properties(item)
    return next((p.text for p in props or [] if p.get("name") == prop_name), default)


def position(item):
    props = properties(item)
    frame = next((p for p in props or [] if p.get("name") == "CFrame"), None)
    if frame is None:
        raise AssertionError((value(item, "Name"), "missing CFrame"))
    return float(frame.find("X").text), float(frame.find("Z").text)


def direct_children(item):
    return [child for child in item if child.tag == "Item"]


def validate(path):
    root = ET.parse(path).getroot()
    named = {}
    for item in root.iter("Item"):
        named.setdefault(value(item, "Name", ""), []).append(item)

    resources = {}
    for model in root.iter("Item"):
        if model.get("class") != "Model":
            continue
        name = value(model, "Name", "")
        prefix = name.split("_", 1)[0]
        if prefix not in RESOURCE_TYPES:
            continue
        interact = next(
            (child for child in direct_children(model) if value(child, "Name") == "Interact"),
            None,
        )
        assert interact is not None, (path, name, "missing Interact root")
        resources[name] = position(interact)

    assert len(resources) == 70, (path, "expected 70 resource nodes", len(resources))
    assert RESOURCE_TYPES == {name.split("_", 1)[0] for name in STARTER}, (
        "starter circuit does not teach every resource category"
    )
    for name, expected in STARTER.items():
        actual = resources.get(name)
        assert actual is not None, (path, "missing starter node", name)
        assert math.dist(actual, expected) < 0.01, (path, name, actual, expected)
        assert math.hypot(*actual) <= 170, (path, name, "outside starter circuit")

    points = list(resources.items())
    for index, (name, (x, z)) in enumerate(points):
        assert not (abs(x) < 19 and 35 < z < 302), (
            path, name, "blocks the main north navigation corridor", (x, z)
        )
        for other_name, other in points[index + 1:]:
            assert math.dist((x, z), other) >= 17.9, (
                path, name, other_name, "overlapping resource silhouettes"
            )

    assert len(named.get("TrailheadPad", [])) == 1, (path, "missing resource trailhead")
    assert len(named.get("TrailPost", [])) == 0, (path, "ambiguous unsuffixed trail post")
    assert sum(len(named.get(f"TrailPost_{i}", [])) for i in range(1, 6)) == 5
    assert sum(len(named.get(f"TrailArrow_{i}", [])) for i in range(1, 6)) == 5
    for station in ("TradingPost", "CraftingWorkshop", "FarmerGuild", "CreatureNursery"):
        model = named.get(station, [])
        assert len(model) == 1, (path, "missing village station", station)
        roof_names = {value(child, "Name") for child in direct_children(model[0])}
        assert {"RoofLeft", "RoofRight", "RoofRidge"} <= roof_names, (
            path, station, "unfinished flat roof"
        )

    for cylinder_name in ("FountainBasin", "FountainWater", "FountainColumn", "Saucer", "NorthBeacon"):
        candidates = named.get(cylinder_name, [])
        assert len(candidates) == 1, (path, "missing authored cylinder", cylinder_name)
        props = properties(candidates[0])
        frame = next(p for p in props or [] if p.get("name") == "CFrame")
        assert abs(float(frame.find("R00").text)) < 0.01, (
            path, cylinder_name, "cylinder axis was not rotated vertical"
        )

    print(
        f"PASS {path}: 8-node teaching circuit, 70 spaced resources, "
        "clear north route, five markers and pitched village roofs"
    )


for artifact in sys.argv[1:]:
    validate(artifact)
