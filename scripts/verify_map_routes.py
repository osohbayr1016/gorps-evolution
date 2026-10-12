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
BRANCHES = {
    "ForestRoute": ((-5.0, 56.0), (-125.0, 116.0)),
    "QuarryRoute": ((5.0, 56.0), (133.0, 120.0)),
}


def properties(item):
    return item.find("Properties")


def value(item, prop_name, default=None):
    props = properties(item)
    entries = props if props is not None else []
    return next((p.text for p in entries if p.get("name") == prop_name), default)


def position(item):
    props = properties(item)
    entries = props if props is not None else []
    frame = next((p for p in entries if p.get("name") == "CFrame"), None)
    if frame is None:
        raise AssertionError((value(item, "Name"), "missing CFrame"))
    return float(frame.find("X").text), float(frame.find("Z").text)


def elevation(item):
    props = properties(item)
    entries = props if props is not None else []
    frame = next((p for p in entries if p.get("name") == "CFrame"), None)
    if frame is None:
        raise AssertionError((value(item, "Name"), "missing CFrame"))
    return float(frame.find("Y").text)


def size(item):
    props = properties(item)
    entries = props if props is not None else []
    vector = next((p for p in entries if (p.get("name") or "").lower() == "size"), None)
    if vector is None:
        raise AssertionError((value(item, "Name"), "missing Size"))
    return tuple(float(vector.find(component).text) for component in "XYZ")


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
    for prefix, (expected_start, expected_end) in BRANCHES.items():
        route = [named[f"{prefix}_{index:02d}"][0] for index in range(1, 7)]
        centers = [position(part) for part in route]
        assert all(value(part, "CanCollide") == "false" for part in route), (
            path, prefix, "route ribbon must not obstruct players"
        )
        assert all(value(part, "Material") == "1360" for part in route), (
            path, prefix, "route ribbon must retain Ground material"
        )
        assert math.dist(centers[0], expected_start) < 15, (path, prefix, "misses trailhead")
        assert math.dist(centers[-1], expected_end) < 16, (path, prefix, "misses branch road")
        assert all(centers[index][1] < centers[index+1][1]
                   for index in range(len(centers)-1)), (
            path, prefix, "route must progress north without doubling back"
        )
        direction = -1 if prefix == "ForestRoute" else 1
        assert all(direction*centers[index][0] < direction*centers[index+1][0]
                   for index in range(len(centers)-1)), (
            path, prefix, "route must progressively branch from center"
        )
    for stone_name, side in (("ForestWaystone", -1), ("QuarryWaystone", 1)):
        stones = named.get(stone_name, [])
        assert len(stones) == 1, (path, "missing branch landmark", stone_name)
        pieces = {value(child, "Name"): child for child in direct_children(stones[0])}
        assert set(pieces) == {"TerraceFoot", "WaystoneSpire", "RouteBand", "RouteRune"}
        x, z = position(pieces["WaystoneSpire"])
        assert side*x >= 20 and z == 96, (path, stone_name, "wrong visual branch")
        assert value(pieces["RouteBand"], "Material") == "288"
        assert value(pieces["RouteBand"], "CanCollide") == "false"
        for resource_name, resource_point in resources.items():
            assert math.dist((x, z), resource_point) >= 20, (
                path, stone_name, resource_name, "landmark crowds resource prompt"
            )

    lagoon_models = named.get("MoonwaterLagoon", [])
    assert len(lagoon_models) == 1, (path, "missing lagoon destination")
    lagoon = lagoon_models[0]
    lagoon_parts = {value(child, "Name"): child for child in direct_children(lagoon)}
    shore_names = ("LagoonRockRim", "NorthShore", "SouthShore", "WestShore")
    assert all(name in lagoon_parts for name in shore_names), (
        path, "lagoon is missing its layered shore"
    )
    assert max(elevation(lagoon_parts[name]) for name in shore_names[1:]) \
        - elevation(lagoon_parts[shore_names[0]]) >= 1.7, (
            path, "lagoon shore regressed to one flat oval"
        )
    water = lagoon_parts.get("GlowingWater")
    assert water is not None and value(water, "Material") == "288", (
        path, "lagoon water must retain its authored emissive cue"
    )
    assert value(water, "CanCollide") == "false", (
        path, "lagoon water cue must not become a collision shelf"
    )
    lilies = [lagoon_parts[f"WaterLily_{index:02d}"] for index in range(1, 8)]
    flowers = [lagoon_parts[f"LilyFlower_{index:02d}"] for index in range(1, 8)]
    assert len({size(part) for part in lilies}) == 7, (
        path, "lagoon regressed to repeated equal lily pads"
    )
    lily_angles = sorted(round(math.atan2(position(part)[1]-45,
                                          position(part)[0]+215), 2)
                         for part in lilies)
    angle_gaps = [round(lily_angles[index+1]-lily_angles[index], 2)
                  for index in range(len(lily_angles)-1)]
    assert len(set(angle_gaps)) >= 4, (path, "lilies regressed to a radial grid")
    assert all(value(part, "CanCollide") == "false" for part in lilies+flowers)
    crescent_models = named.get("MoonstoneCrescent", [])
    assert len(crescent_models) == 1, (path, "missing lagoon skyline landmark")
    crescent_parts = {
        value(child, "Name"): child for child in direct_children(crescent_models[0])
    }
    assert set(crescent_parts) == {
        "CrescentBase", "CrescentSpire", "CrescentHorn", "MoonVein"
    }
    assert elevation(crescent_parts["CrescentSpire"]) \
        > elevation(crescent_parts["CrescentHorn"]) \
        > elevation(crescent_parts["CrescentBase"]), (
            path, "moonstone silhouette must rise above the lagoon"
        )
    assert value(crescent_parts["MoonVein"], "Material") == "288"
    assert value(crescent_parts["MoonVein"], "CanCollide") == "false"
    decks = [lagoon_parts[f"ReedBridgeDeck_{index:02d}"] for index in range(1, 4)]
    assert max(elevation(part) for part in decks) - min(elevation(part) for part in decks) <= .31
    assert all(value(part, "CanCollide") == "true" for part in decks)
    lagoon_lights = [item for item in lagoon.iter("Item") if item.get("class") == "PointLight"]
    assert not lagoon_lights, (path, "lagoon milestone must not add local lights")
    for part in list(crescent_parts.values()) + decks:
        part_point = position(part)
        for resource_name, resource_point in resources.items():
            assert math.dist(part_point, resource_point) >= 15, (
                path, resource_name, "lagoon landmark crowds resource", part_point
            )

    quarry_models = named.get("SunstoneQuarry", [])
    assert len(quarry_models) == 1, (path, "missing quarry destination")
    quarry_parts = {value(child, "Name"): child for child in direct_children(quarry_models[0])}
    tiers = [quarry_parts[name] for name in (
        "QuarryTerraceLow", "QuarryTerraceMid", "QuarryCrown"
    )]
    assert [elevation(part) for part in tiers] == sorted(elevation(part) for part in tiers), (
        path, "quarry terraces do not rise toward the skyline"
    )
    assert size(tiers[0])[0] > size(tiers[1])[0] > size(tiers[2])[0], (
        path, "quarry silhouette does not taper"
    )
    portal_models = named.get("QuarryPortal", [])
    assert len(portal_models) == 1, (path, "missing quarry portal landmark")
    portal_parts = {value(child, "Name"): child for child in direct_children(portal_models[0])}
    assert set(portal_parts) == {
        "PortalButtressLeft", "PortalButtressRight", "PortalLintel",
        "Entrance", "SunstoneCrest",
    }
    assert value(portal_parts["Entrance"], "CanCollide") == "false"
    assert value(portal_parts["SunstoneCrest"], "Material") == "288"
    assert value(portal_parts["SunstoneCrest"], "CanCollide") == "false"
    boulders = [quarry_parts[f"OreBoulder_{index:02d}"] for index in range(1, 10)]
    gems = [quarry_parts[f"OreGem_{index:02d}"] for index in range(1, 10)]
    assert len({size(part) for part in boulders}) >= 7, (
        path, "quarry regressed to repeated equal boulders"
    )
    assert all(value(part, "Material") == "288" and value(part, "CanCollide") == "false"
               for part in gems), (path, "ore highlights must be bounded nonblocking Neon")
    for boulder in boulders:
        boulder_point = position(boulder)
        for resource_name, resource_point in resources.items():
            assert math.dist(boulder_point, resource_point) >= 15, (
                path, resource_name, "quarry cluster crowds resource", boulder_point
            )
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
        entries = props if props is not None else []
        frame = next(p for p in entries if p.get("name") == "CFrame")
        assert abs(float(frame.find("R00").text)) < 0.01, (
            path, cylinder_name, "cylinder axis was not rotated vertical"
        )

    print(
        f"PASS {path}: 8-node teaching circuit, 70 spaced resources, "
        "clear north route, two curved branches, paired waystones, five markers "
        "and pitched village roofs plus distinct lagoon/quarry destinations"
    )


for artifact in sys.argv[1:]:
    validate(artifact)
