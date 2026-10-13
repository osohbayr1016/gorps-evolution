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


def position3(item):
    properties = props(item)
    frame = next(entry for entry in properties if entry.get("name") == "CFrame")
    return tuple(float(frame.find(axis).text) for axis in ("X", "Y", "Z"))


def size(item):
    properties = props(item)
    vector = next(entry for entry in properties if entry.get("name") in {"Size", "size"})
    return tuple(float(vector.find(axis).text) for axis in ("X", "Y", "Z"))


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
    stems = named.get("MushroomStem", [])
    assert len(stems) == 16, (path, "glowcap stem layout drifted", len(stems))
    clearing = named.get("GroveClearing", [])
    assert len(clearing) == 1, (path, "missing protected grove clearing")
    clearing = clearing[0]
    clearing_center = position(clearing)
    assert math.dist(clearing_center, (-204, 228)) <= 0.1
    assert size(clearing) == (46.0, 0.28, 34.0)
    assert value(clearing, "CanCollide") == "false"
    assert value(clearing, "Material") == "1360", (path, "clearing is not Ground")
    stem_points = [position(stem) for stem in stems]
    assert min(math.dist(point, clearing_center) for point in stem_points) >= 50, (
        path, "mushroom entered protected walkable interior"
    )
    assert min(
        math.dist(point, other)
        for index, point in enumerate(stem_points)
        for other in stem_points[index + 1:]
    ) >= 19, (path, "grove ring silhouettes overlap")
    stem_heights = [size(stem)[1] for stem in stems]
    assert len(set(stem_heights)) >= 8, (path, "grove height hierarchy flattened")
    assert max(stem_heights) >= 15 and min(stem_heights) <= 6
    cap_widths = [size(cap)[0] for cap in named.get("Glowcap", [])]
    assert max(cap_widths) >= 11.5 and sum(width >= 9 for width in cap_widths) == 3, (
        path, "north focal cap hierarchy drifted", cap_widths
    )
    grove_interacts = [
        item for item in named.get("Interact", [])
        if -310 < position(item)[0] < -140 and 150 < position(item)[1] < 305
    ]
    assert grove_interacts, (path, "missing harvest evidence around grove")
    assert min(math.dist(position(item), clearing_center) for item in grove_interacts) >= 30, (
        path, "harvest prompt intrudes on grove clearing"
    )


# Region-art regression: solid landforms add true elevation without putting
# new parts onto the mandatory resource trail or overwriting ranch pads.
    ridges = [item for item in root.iter("Item")
              if item.get("class") == "Model" and value(item, "Name", "").startswith("Escarpment_")]
    knolls = [item for item in root.iter("Item")
              if item.get("class") == "Model" and value(item, "Name", "").startswith("TerrainKnoll_")]
    assert len(ridges) == 14, (path, "missing tall outer escarpments", len(ridges))
    assert len(knolls) >= 6, (path, "insufficient true 3D ground relief", len(knolls))
    ridge_profiles = []
    ridge_tops = []
    for ridge in ridges:
        pieces = {value(part, "Name"): part for part in children(ridge)}
        names = set(pieces)
        assert names == {"RockFoot", "CliffSlope", "StrataShelf", "GrassCrest"}
        slope = pieces["CliffSlope"]
        assert slope.get("class") == "WedgePart" and value(slope, "CanCollide") == "true"
        depth = math.dist(position(pieces["RockFoot"]), position(pieces["GrassCrest"]))
        assert depth >= 7.9, (path, value(ridge, "Name"), "flat aligned skyline stack", depth)
        assert value(pieces["StrataShelf"], "CastShadow") == "false"
        assert value(pieces["GrassCrest"], "CastShadow") == "false"
        ridge_profiles.append(tuple(round(component, 2) for part_name in (
            "CliffSlope", "StrataShelf", "GrassCrest"
        ) for component in size(pieces[part_name])) + (round(depth, 2),))
        crest_y = position3(pieces["GrassCrest"])[1]
        ridge_tops.append(round(crest_y + size(pieces["GrassCrest"])[1] / 2, 2))
    assert len(set(ridge_profiles)) >= 13, (
        path, "outer skyline regressed to repeated profiles", len(set(ridge_profiles))
    )
    assert len(set(ridge_tops)) >= 10 and max(ridge_tops) - min(ridge_tops) >= 8, (
        path, "outer skyline lost its height hierarchy", ridge_tops
    )
    for west_index, east_index in zip(range(4), range(4, 8)):
        assert ridge_profiles[west_index] != ridge_profiles[east_index], (
            path, "west/east skyline pair is exactly mirrored", west_index, east_index
        )
    resources = [item for item in root.iter("Item") if value(item, "Name") == "Interact"]
    for knoll in knolls:
        slope = next(p for p in children(knoll) if value(p, "Name") == "RisingSlope")
        x, z = position(slope)
        assert not (abs(x) < 36 and 20 < z < 308), (path, "knoll blocks north path", (x,z))
        for node in resources:
            assert math.dist((x,z), position(node)) >= 27.9, (path, "knoll overlaps harvest", (x,z))
    lights = [item for item in root.iter("Item") if item.get("class") == "PointLight"]
    assert len(lights) == 8, (path, "village and grove lights must be bounded", len(lights))
    light_names = Counter(value(light, "Name") for light in lights)
    assert light_names == Counter({"VillageLanternLight": 4, "GroveLight": 4}), (
        path, "local-light ownership drifted", light_names
    )
    for light in lights:
        assert float(value(light, "Range")) <= 20
        assert value(light, "Shadows") == "false"
    assert sum(float(value(light, "Range")) for light in lights) == 136
    assert abs(sum(float(value(light, "Brightness")) for light in lights)-4.12) < 1e-6
    animated_effects = [item for item in root.iter("Item")
                        if item.get("class") in {"ParticleEmitter", "Beam", "Trail"}]
    assert not animated_effects, (
        path, "static world-art milestone added animated/transparent effects",
        [value(item, "Name") for item in animated_effects],
    )

    base_parts = [item for item in root.iter("Item") if item.get("class") in {"Part", "WedgePart"}]
    assert len(base_parts) <= 2350, (path, "static BasePart budget exceeded", len(base_parts))
    print(
        f"PASS {path}: four 16-tree silhouettes, 12 biome fields, six fallen logs, "
        f"16 glass glowcaps, {len(base_parts)} static parts"
    )


for artifact in sys.argv[1:]:
    validate(artifact)
