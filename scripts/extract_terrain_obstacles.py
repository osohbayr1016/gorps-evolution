#!/usr/bin/env python3
"""Extract ACTUAL generated-world collision anchors for pure Luau terrain-plan QA.

This intentionally mirrors WorldTerrain.obstaclesIn's exact authored models, not
an empty or synthetic candidate list. It is only a CI fixture; Roblox Studio
must still verify physics, appearance and streaming.
"""
import json
import sys
from pathlib import Path
import xml.etree.ElementTree as ET


def name(item):
    props = item.find("Properties")
    values = props if props is not None else []
    return next((p.text or "" for p in values if p.get("name") == "Name"), "")


def children(item):
    return [child for child in item if child.tag == "Item"]


def child(item, expected):
    return next((o for o in children(item) if name(o) == expected), None)


def coords(part):
    frame = next((p for p in part.find("Properties") if p.get("name") == "CFrame"), None)
    assert frame is not None, f"{name(part)} missing CFrame"
    return float(frame.find("X").text), float(frame.find("Z").text)


def append_obstacle(obstacles, part, radius):
    assert part is not None and part.get("class") in {"Part", "WedgePart"}, "Missing BasePart obstacle root"
    x, z = coords(part)
    obstacles.append({"x": x, "z": z, "radius": radius})


def main(source, output):
    root = ET.parse(source).getroot()
    planet = next((o for o in root.iter("Item") if name(o) == "PlanetVerdant"), None)
    assert planet is not None, "missing authored planet"
    nodes = child(planet, "ResourceNodes")
    forest = child(planet, "ForestsAndWildlife")
    relief = child(planet, "WorldRelief")
    landmarks = child(planet, "SignatureLandmarks")
    assert all(x is not None for x in (nodes, forest, relief, landmarks)), "missing terrain obstruction source"
    obstacles = []
    counts = {}
    for node in children(nodes):
        if node.get("class") == "Model":
            append_obstacle(obstacles, child(node, "Interact"), 16)
    counts["resources"] = len(obstacles)
    assert counts["resources"] == 70, ("resource obstacle coverage", counts)

    for tree in children(forest):
        if tree.get("class") == "Model" and name(tree).startswith("CanopyTree_"):
            trunk = next((part for part in children(tree) if part.get("class") in {"Part", "WedgePart"} and "Trunk" in name(part)), None)
            append_obstacle(obstacles, trunk, 9)
    counts["trees"] = len(obstacles) - counts["resources"]
    assert counts["trees"] == 64, ("tree obstacle coverage", counts)

    for knoll in children(relief):
        if knoll.get("class") == "Model" and name(knoll).startswith("TerrainKnoll_"):
            append_obstacle(obstacles, child(knoll, "RisingSlope"), 13)
    counts["knolls"] = len(obstacles) - counts["resources"] - counts["trees"]
    assert counts["knolls"] >= 6, ("knoll obstacle coverage", counts)

    grove = child(landmarks, "GlowcapGrove")
    assert grove is not None, "missing grove"
    for part in children(grove):
        if part.get("class") in {"Part", "WedgePart"} and name(part) == "MushroomStem":
            append_obstacle(obstacles, part, 4)
    counts["mushrooms"] = len(obstacles) - sum(counts.values())
    assert counts["mushrooms"] == 16, ("mushroom obstacle coverage", counts)

    Path(output).write_text(json.dumps({"counts": counts, "obstacles": obstacles}, indent=2) + "\n", encoding="utf-8")
    print("PASS: exact map terrain obstacle fixture", counts)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: extract_terrain_obstacles.py WORLD.rbxmx output.json")
    main(sys.argv[1], sys.argv[2])
