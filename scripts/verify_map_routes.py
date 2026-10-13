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
BRANCH_POINTS = {
    "ForestRoute": [
        (-5.0, 56.0), (-20.0, 67.0), (-39.0, 76.0), (-60.0, 91.0),
        (-82.0, 103.0), (-103.0, 111.0), (-125.0, 116.0),
    ],
    "QuarryRoute": [
        (5.0, 56.0), (22.0, 68.0), (43.0, 80.0), (64.0, 94.0),
        (87.0, 106.0), (108.0, 114.0), (133.0, 120.0),
    ],
}
FIRST_PROMPTS = {"ForestRoute": "Tree_001", "QuarryRoute": "Tree_002"}
PROMPT_ACTIVATION_DISTANCE = 13.0
CONSERVATIVE_PLAYER_ROOT_Y = 3.0


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


def position3(item):
    props = properties(item)
    entries = props if props is not None else []
    frame = next((p for p in entries if p.get("name") == "CFrame"), None)
    if frame is None:
        raise AssertionError((value(item, "Name"), "missing CFrame"))
    return tuple(float(frame.find(component).text) for component in "XYZ")


def size(item):
    props = properties(item)
    entries = props if props is not None else []
    vector = next((p for p in entries if (p.get("name") or "").lower() == "size"), None)
    if vector is None:
        raise AssertionError((value(item, "Name"), "missing Size"))
    return tuple(float(vector.find(component).text) for component in "XYZ")


def world_aabb(item):
    """Return a conservative world-axis box for a rotated 3D part."""
    props = properties(item)
    entries = props if props is not None else []
    frame = next((p for p in entries if p.get("name") == "CFrame"), None)
    if frame is None:
        raise AssertionError((value(item, "Name"), "missing CFrame"))
    center = tuple(float(frame.find(component).text) for component in "XYZ")
    half_size = tuple(component/2 for component in size(item))
    extent = tuple(
        sum(abs(float(frame.find(f"R{row}{column}").text))*half_size[column]
            for column in range(3))
        for row in range(3)
    )
    return (
        tuple(center[axis]-extent[axis] for axis in range(3)),
        tuple(center[axis]+extent[axis] for axis in range(3)),
    )


def aabb_overlap(first, second):
    """Return positive XYZ overlap depths, or None when boxes are disjoint."""
    first_low, first_high = world_aabb(first)
    second_low, second_high = world_aabb(second)
    depth = tuple(
        min(first_high[axis], second_high[axis])
        - max(first_low[axis], second_low[axis])
        for axis in range(3)
    )
    return depth if min(depth) > 1e-3 else None


def footprint(item):
    """Return the XZ oriented bounding box as a counter-clockwise polygon."""
    props = properties(item)
    entries = props if props is not None else []
    frame = next((p for p in entries if p.get("name") == "CFrame"), None)
    if frame is None:
        raise AssertionError((value(item, "Name"), "missing CFrame"))
    center_x, center_z = float(frame.find("X").text), float(frame.find("Z").text)
    size_x, _, size_z = size(item)
    r00 = float(frame.find("R00").text)
    r02 = float(frame.find("R02").text)
    r20 = float(frame.find("R20").text)
    r22 = float(frame.find("R22").text)
    corners = [
        (-size_x/2, -size_z/2),
        (size_x/2, -size_z/2),
        (size_x/2, size_z/2),
        (-size_x/2, size_z/2),
    ]
    polygon = [
        (center_x+r00*x+r02*z, center_z+r20*x+r22*z)
        for x, z in corners
    ]
    if signed_area(polygon) < 0:
        polygon.reverse()
    return polygon


def signed_area(polygon):
    return sum(
        polygon[index][0]*polygon[(index+1) % len(polygon)][1]
        - polygon[(index+1) % len(polygon)][0]*polygon[index][1]
        for index in range(len(polygon))
    ) / 2


def footprint_overlap(first, second):
    """Calculate convex XZ overlap area with Sutherland-Hodgman clipping."""
    subject = footprint(first)
    clipper = footprint(second)
    for index, clip_start in enumerate(clipper):
        clip_end = clipper[(index+1) % len(clipper)]
        source = subject
        subject = []
        if not source:
            break

        def inside(point):
            return ((clip_end[0]-clip_start[0])*(point[1]-clip_start[1])
                    - (clip_end[1]-clip_start[1])*(point[0]-clip_start[0])) >= -1e-7

        def intersection(start, end):
            clip_delta = (clip_start[0]-clip_end[0], clip_start[1]-clip_end[1])
            edge_delta = (start[0]-end[0], start[1]-end[1])
            clip_cross = clip_start[0]*clip_end[1]-clip_start[1]*clip_end[0]
            edge_cross = start[0]*end[1]-start[1]*end[0]
            denominator = clip_delta[0]*edge_delta[1]-clip_delta[1]*edge_delta[0]
            assert abs(denominator) > 1e-9, ("parallel clipping edges", start, end)
            return (
                (clip_cross*edge_delta[0]-edge_cross*clip_delta[0]) / denominator,
                (clip_cross*edge_delta[1]-edge_cross*clip_delta[1]) / denominator,
            )

        start = source[-1]
        for end in source:
            if inside(end):
                if not inside(start):
                    subject.append(intersection(start, end))
                subject.append(end)
            elif inside(start):
                subject.append(intersection(start, end))
            start = end
    return abs(signed_area(subject)) if subject else 0


def point_segment_distance(point, start, end):
    """Return distance and nearest point on one XZ segment."""
    delta = (end[0]-start[0], end[1]-start[1])
    length_squared = delta[0]**2 + delta[1]**2
    assert length_squared > 0, ("zero-length route segment", start, end)
    offset = (point[0]-start[0], point[1]-start[1])
    t = max(0.0, min(1.0,
                     (offset[0]*delta[0] + offset[1]*delta[1]) / length_squared))
    nearest = (start[0]+t*delta[0], start[1]+t*delta[1])
    return math.dist(point, nearest), nearest


def point_polyline_distance(point, points):
    return min(point_segment_distance(point, start, end)
               for start, end in zip(points, points[1:]))


def segment_obb_interval(start, end, item):
    """Return the normalized 3D segment interval inside an oriented box."""
    props = properties(item)
    entries = props if props is not None else []
    frame = next((p for p in entries if p.get("name") == "CFrame"), None)
    if frame is None:
        return None
    center = tuple(float(frame.find(component).text) for component in "XYZ")
    rotation = tuple(
        tuple(float(frame.find(f"R{row}{column}").text) for column in range(3))
        for row in range(3)
    )

    def local(point):
        offset = tuple(point[axis]-center[axis] for axis in range(3))
        return tuple(
            sum(rotation[row][column]*offset[row] for row in range(3))
            for column in range(3)
        )

    local_start, local_end = local(start), local(end)
    direction = tuple(local_end[axis]-local_start[axis] for axis in range(3))
    half_size = tuple(component/2 for component in size(item))
    lower, upper = 0.0, 1.0
    for axis in range(3):
        if abs(direction[axis]) < 1e-9:
            if abs(local_start[axis]) > half_size[axis]:
                return None
            continue
        first = (-half_size[axis]-local_start[axis]) / direction[axis]
        second = (half_size[axis]-local_start[axis]) / direction[axis]
        lower = max(lower, min(first, second))
        upper = min(upper, max(first, second))
        if lower > upper:
            return None
    return lower, upper


def visual_blockers(root, start, end, ignored=()):
    """Find opaque authored parts crossing a fixed shoulder-height sightline."""
    ignored = set(ignored)
    blockers = []
    for item in root.iter("Item"):
        if item in ignored or item.get("class") not in {"Part", "WedgePart", "MeshPart"}:
            continue
        if float(value(item, "Transparency", "0") or 0) >= .85:
            continue
        interval = segment_obb_interval(start, end, item)
        if interval is not None and .02 < interval[0] < .98:
            blockers.append((value(item, "Name"), position3(item), interval))
    return blockers


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

    starter_crystal = named["Crystal_006"][0]
    starter_crystal_parts = direct_children(starter_crystal)
    rare_crowns = [part for part in starter_crystal_parts
                   if value(part, "Name") == "CrystalTip"
                   and value(part, "Material") == "288"]
    assert len(rare_crowns) == 1, (
        path, "starter crystal must expose one restrained static rare cue"
    )
    rare_crown = rare_crowns[0]
    assert position3(rare_crown) == (-92.0, 11.0, 122.0), (
        path, "starter rare cue moved off the tallest crystal spire",
        position3(rare_crown),
    )
    rare_blockers = visual_blockers(
        root,
        (-92.5, 6.0, 107.0),
        position3(rare_crown),
        starter_crystal.iter("Item"),
    )
    assert not rare_blockers, (
        path, "starter rare cue is occluded from ForestRoute_05", rare_blockers
    )

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
    trailhead = named["TrailheadPad"][0]
    assert footprint_overlap(named["MainRoadNorth"][0], trailhead) >= 200, (
        path, "north road has an insufficient trailhead handoff"
    )
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
        assert footprint_overlap(trailhead, route[0]) >= 60, (
            path, prefix, "trailhead-to-branch surface seam is too narrow"
        )
        for first, second in zip(route, route[1:]):
            assert footprint_overlap(first, second) >= 12, (
                path, prefix, value(first, "Name"), value(second, "Name"),
                "branch surface seam is too narrow",
            )

        prompt_model = named[FIRST_PROMPTS[prefix]][0]
        prompt_base = next(child for child in direct_children(prompt_model)
                           if value(child, "Name") == "Interact")
        horizontal, nearest = point_polyline_distance(
            position(prompt_base), BRANCH_POINTS[prefix]
        )
        vertical = elevation(prompt_base)-CONSERVATIVE_PLAYER_ROOT_Y
        approach_distance = math.hypot(horizontal, vertical)
        assert approach_distance <= PROMPT_ACTIVATION_DISTANCE-2, (
            path, FIRST_PROMPTS[prefix], "first prompt has insufficient route margin",
            approach_distance, PROMPT_ACTIVATION_DISTANCE-approach_distance,
        )
        blockers = visual_blockers(
            root,
            (nearest[0], 6.0, nearest[1]),
            position3(prompt_base),
            prompt_model.iter("Item"),
        )
        assert not blockers, (
            path, FIRST_PROMPTS[prefix], "first prompt projection is occluded", blockers
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
    assert value(water, "shape") == "2", (
        path, "lagoon water must retain its level elliptical cylinder"
    )
    assert size(water) == (.8, 58.0, 55.0)
    water_frame = next(
        prop for prop in properties(water) if prop.get("name") == "CFrame"
    )
    assert abs(abs(float(water_frame.find("R10").text))-1) < 1e-5, (
        path, "lagoon cylinder axis is not vertical"
    )
    exits = [
        lagoon_parts.get("LagoonExitNorth"),
        lagoon_parts.get("LagoonExitSouth"),
    ]
    assert all(part is not None for part in exits), (
        path, "lagoon east bank needs two independent return shelves"
    )
    assert [position(part) for part in exits] == [(-185.0, 31.0), (-185.0, 59.0)]
    assert all(size(part) == (11.0, 1.0, 7.0) for part in exits)
    assert all(value(part, "Material") == "800" for part in exits)
    assert all(value(part, "CanCollide") == "true" for part in exits)
    assert all(abs(elevation(part)-1.5) < .01 for part in exits)
    # The west end of each shelf is deliberately embedded in the solid Ball
    # rim, while its east end returns to the y=1 global ground. Validate the
    # authored ellipsoid surface instead of treating the Ball as a box.
    rim_center_x, rim_center_z = position(lagoon_parts["LagoonRockRim"])
    rim_center_y = elevation(lagoon_parts["LagoonRockRim"])
    rim_radius_x, rim_diameter_y, rim_radius_z = size(lagoon_parts["LagoonRockRim"])
    rim_radius_x /= 2
    rim_radius_z /= 2
    rim_radius_y = rim_diameter_y/2
    water_bottom = elevation(water)-size(water)[0]/2
    water_top = elevation(water)+size(water)[0]/2
    water_center_x, water_center_z = position(water)
    water_radius_x = size(water)[1]/2
    water_radius_z = size(water)[2]/2
    perimeter_gaps = []
    for sample_x, sample_z in (
        (water_center_x-water_radius_x, water_center_z),
        (water_center_x+water_radius_x, water_center_z),
        (water_center_x, water_center_z-water_radius_z),
        (water_center_x, water_center_z+water_radius_z),
    ):
        normalized = (
            ((sample_x-rim_center_x)/rim_radius_x)**2
            + ((sample_z-rim_center_z)/rim_radius_z)**2
        )
        assert normalized < 1, (path, "water footprint escapes solid rim")
        rim_top = rim_center_y + rim_radius_y*math.sqrt(1-normalized)
        perimeter_gaps.append(water_bottom-rim_top)
    assert min(perimeter_gaps) >= -.15 and max(perimeter_gaps) <= .05, (
        path, "water perimeter floats above or buries into rim", perimeter_gaps
    )
    for exit_part in exits:
        frame = next(
            prop for prop in properties(exit_part) if prop.get("name") == "CFrame"
        )
        center_x, center_z = position(exit_part)
        half_length = size(exit_part)[0]/2
        x_axis_x = float(frame.find("R00").text)
        x_axis_z = float(frame.find("R20").text)
        water_end = (
            center_x-half_length*x_axis_x,
            center_z-half_length*x_axis_z,
        )
        land_end = (
            center_x+half_length*x_axis_x,
            center_z+half_length*x_axis_z,
        )
        normalized = (
            ((water_end[0]-rim_center_x)/rim_radius_x)**2
            + ((water_end[1]-rim_center_z)/rim_radius_z)**2
        )
        assert normalized < 1, (path, "shore exit misses solid rim", water_end)
        rim_top = rim_center_y + rim_radius_y*math.sqrt(1-normalized)
        shelf_top = elevation(exit_part)+size(exit_part)[1]/2
        assert 0 <= shelf_top-rim_top <= .55, (
            path, "shore exit has an unsafe rim step", shelf_top, rim_top
        )
        assert land_end[0] > rim_center_x+rim_radius_x, (
            path, "shore exit does not reach the open ground", land_end
        )
        assert shelf_top-1.0 <= 1.0, (
            path, "shore exit has an unsafe ground step", shelf_top
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
    lily_bottoms = [elevation(part)-size(part)[1]/2 for part in lilies]
    assert all(abs(bottom-water_top) <= .02 for bottom in lily_bottoms), (
        path, "lily pad no longer seats on level water", lily_bottoms, water_top
    )
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
    approach = lagoon_parts.get("ReedBridgeApproach")
    assert approach is not None, (path, "bridge is missing its walkable approach")
    assert value(approach, "Material") == "512"
    assert value(approach, "CanCollide") == "true"
    approach_props = properties(approach)
    approach_frame = next(
        prop for prop in approach_props if prop.get("name") == "CFrame"
    )
    approach_size = size(approach)
    approach_y = elevation(approach)
    local_y_to_world_y = float(approach_frame.find("R11").text)
    local_z_to_world_y = float(approach_frame.find("R12").text)
    low_top = (approach_y + approach_size[2]/2*local_z_to_world_y
               + approach_size[1]/2*local_y_to_world_y)
    high_top = (approach_y - approach_size[2]/2*local_z_to_world_y
                + approach_size[1]/2*local_y_to_world_y)
    link_top = elevation(named["LagoonLink_01"][0]) + size(named["LagoonLink_01"][0])[1]/2
    deck_top = elevation(decks[-1]) + size(decks[-1])[1]/2
    assert abs(low_top-link_top) <= .1, (
        path, "bridge approach no longer meets LagoonLink", low_top, link_top
    )
    assert abs(high_top-deck_top) <= .1, (
        path, "bridge approach no longer meets first deck", high_top, deck_top
    )
    bridge_rails = [
        lagoon_parts.get("BridgeRailNorth"),
        lagoon_parts.get("BridgeRailSouth"),
        lagoon_parts.get("BridgeRailWest"),
    ]
    assert all(part is not None for part in bridge_rails), (
        path, "bridge overlook is missing its U-guard"
    )
    assert all(value(part, "Material") == "512" for part in bridge_rails)
    assert all(value(part, "CanCollide") == "true" for part in bridge_rails), (
        path, "bridge water-edge guard must remain collidable"
    )
    side_rails = bridge_rails[:2]
    corridor_width = (
        abs(position(side_rails[1])[1]-position(side_rails[0])[1])
        - size(side_rails[0])[2]/2 - size(side_rails[1])[2]/2
    )
    assert corridor_width >= 6.5, (
        path, "bridge guard makes the return corridor too narrow", corridor_width
    )
    rail_bottoms = [elevation(part)-size(part)[1]/2 for part in bridge_rails]
    assert all(4.55 <= bottom <= 4.65 for bottom in rail_bottoms), (
        path, "bridge guard no longer seats at deck height", rail_bottoms
    )
    assert footprint_overlap(decks[0], bridge_rails[2]) >= 3, (
        path, "bridge end guard no longer closes the water edge",
        footprint_overlap(decks[0], bridge_rails[2]),
    )
    lagoon_lights = [item for item in lagoon.iter("Item") if item.get("class") == "PointLight"]
    assert not lagoon_lights, (path, "lagoon milestone must not add local lights")
    for part in list(crescent_parts.values()) + decks + [approach] + exits:
        part_point = position(part)
        for resource_name, resource_point in resources.items():
            assert math.dist(part_point, resource_point) >= 15, (
                path, resource_name, "lagoon landmark crowds resource", part_point
            )

    handoff_models = named.get("MoonwaterGroveHandoff", [])
    assert len(handoff_models) == 1, (path, "missing lagoon-to-grove handoff")
    handoff = handoff_models[0]
    link_contracts = {
        "LagoonLink": (4, (-163.0, 49.0), (-129.5, 72.5), 1),
        "GroveLink": (5, (-127.5, 188.5), (-172.5, 228.5), -1),
    }
    for prefix, (count, expected_start, expected_end, x_direction) in link_contracts.items():
        segments = [named[f"{prefix}_{index:02d}"][0]
                    for index in range(1, count+1)]
        centers = [position(part) for part in segments]
        assert all(part in list(handoff.iter("Item")) for part in segments)
        assert all(value(part, "Material") == "1360" for part in segments)
        assert all(value(part, "CanCollide") == "false" for part in segments)
        assert math.dist(centers[0], expected_start) < .01
        assert math.dist(centers[-1], expected_end) < .01
        assert all(centers[index][1] < centers[index+1][1]
                   for index in range(len(centers)-1)), (
            path, prefix, "handoff must progress north"
        )
        assert all(x_direction*centers[index][0] < x_direction*centers[index+1][0]
                   for index in range(len(centers)-1)), (
            path, prefix, "handoff doubles back horizontally"
        )
        for center in centers:
            for resource_name, resource_point in resources.items():
                assert math.dist(center, resource_point) >= 20, (
                    path, prefix, resource_name, "handoff crowds resource", center
                )
    surface_joints = (
        (decks[-1], named["LagoonLink_01"][0], 25),
        (named["LagoonLink_04"][0], named["ForestPath"][0], 40),
        (named["ForestPath"][0], named["GroveLink_01"][0], 60),
    )
    for first, second, minimum_overlap in surface_joints:
        overlap = footprint_overlap(first, second)
        assert overlap >= minimum_overlap, (
            path, value(first, "Name"), value(second, "Name"),
            "insufficient route-surface overlap", overlap,
        )
    moonwater_guides = named.get("MoonwaterTurnGuide", [])
    assert len(moonwater_guides) == 1, (path, "missing Moonwater turn guide")
    moonwater_guide = {
        value(child, "Name"): child for child in direct_children(moonwater_guides[0])
    }
    assert set(moonwater_guide) == {
        "GuideFoot", "GuideStem", "GuideLens", "GuideRune"
    }
    assert all(value(part, "CanCollide") == "false"
               for part in moonwater_guide.values())
    assert value(moonwater_guide["GuideLens"], "Material") == "1568"
    assert value(moonwater_guide["GuideRune"], "Material") == "288"
    guide_point = position(moonwater_guide["GuideStem"])
    assert guide_point == (-116.0, 104.0), (
        path, "Moonwater guide left the ForestPath junction shoulder", guide_point
    )
    for resource_name, resource_point in resources.items():
        assert math.dist(guide_point, resource_point) >= 20, (
            path, resource_name, "Moonwater guide crowds resource prompt", guide_point
        )
    incoming = (
        BRANCH_POINTS["ForestRoute"][-1][0]-BRANCH_POINTS["ForestRoute"][-2][0],
        BRANCH_POINTS["ForestRoute"][-1][1]-BRANCH_POINTS["ForestRoute"][-2][1],
    )
    moonwater_exit = (
        -125.0-BRANCH_POINTS["ForestRoute"][-1][0],
        76.0-BRANCH_POINTS["ForestRoute"][-1][1],
    )
    turn_angle = math.degrees(math.acos(max(-1.0, min(1.0,
        (incoming[0]*moonwater_exit[0]+incoming[1]*moonwater_exit[1])
        / (math.hypot(*incoming)*math.hypot(*moonwater_exit))
    ))))
    assert 90 <= turn_angle <= 115, (
        path, "unexpected forest-to-Moonwater junction angle", turn_angle
    )
    guide_blockers = visual_blockers(
        root,
        (-92.5, 6.0, 107.0),
        position3(moonwater_guide["GuideLens"]),
        moonwater_guide.values(),
    )
    assert not guide_blockers, (
        path, "Moonwater guide is hidden on forest approach", guide_blockers
    )
    crescent_blockers = visual_blockers(
        root,
        (guide_point[0], 6.0, guide_point[1]),
        position3(crescent_parts["CrescentSpire"]),
        crescent_parts.values(),
    )
    assert not crescent_blockers, (
        path, "Moonwater destination is hidden after the guide", crescent_blockers
    )
    lagoon_route = [(-171.0, 45.0), (-155.0, 53.0), (-144.0, 61.0),
                    (-134.0, 69.0), (-125.0, 76.0)]
    lagoon_prompt_clearance = min(
        point_polyline_distance(resource_point, lagoon_route)[0]
        for resource_point in resources.values()
    )
    assert lagoon_prompt_clearance >= 30, (
        path, "lagoon route crowds a harvest prompt", lagoon_prompt_clearance
    )
    assert len(named.get("Glowcap", [])) == 16
    grove_end_part = named["GroveLink_05"][0]
    grove_clearing = named.get("GroveClearing", [])
    assert len(grove_clearing) == 1, (path, "grove handoff has no destination clearing")
    thresholds = named.get("GroveThreshold", [])
    assert len(thresholds) == 1, (path, "grove handoff has no seam-safe threshold")
    threshold = thresholds[0]
    assert value(threshold, "Material") == "1360"
    assert value(threshold, "CanCollide") == "false"
    assert footprint_overlap(grove_end_part, threshold) >= 20, (
        path, "final ribbon has insufficient threshold overlap",
        footprint_overlap(grove_end_part, threshold),
    )
    assert footprint_overlap(threshold, grove_clearing[0]) >= 30, (
        path, "threshold has insufficient clearing overlap",
        footprint_overlap(threshold, grove_clearing[0]),
    )
    for resource_name, resource_point in resources.items():
        assert math.dist(position(threshold), resource_point) >= 20, (
            path, resource_name, "grove threshold crowds resource prompt"
        )
    guide_models = named.get("GlowcapGuide", [])
    assert len(guide_models) == 1, (path, "missing Glowcap turn guide")
    guide_parts = {value(child, "Name"): child
                   for child in direct_children(guide_models[0])}
    assert set(guide_parts) == {"GuideFoot", "GuideStem", "GuideCap", "GuideRune"}
    assert all(value(part, "CanCollide") == "false" for part in guide_parts.values())
    assert value(guide_parts["GuideCap"], "Material") == "1568"
    assert value(guide_parts["GuideRune"], "Material") == "288"
    assert not [item for item in handoff.iter("Item")
                if item.get("class") == "PointLight"], (
        path, "handoff milestone must not add local lights"
    )
    focal_caps = [part for part in named["Glowcap"]
                  if math.dist(position(part), (-219, 292)) < .01]
    assert len(focal_caps) == 1, (path, "missing north Grove focal cap")
    backdrop_specs = {
        "ForestBackdropHill": ((-308.0, 6.5, 131.0), (30.0, 15.0, 24.0)),
        "QuarryBackdropHill": ((286.0, 7.0, 116.0), (28.0, 16.0, 52.0)),
        "GroveBackdropHill": ((-306.0, 6.5, 291.0), (34.0, 15.0, 16.0)),
        "SunstoneBackdropHill": ((285.0, 7.5, 257.0), (26.0, 17.0, 48.0)),
    }
    assert not named.get("LowHill"), (path, "resource-burying LowHill returned")
    escarpment_parts = []
    for model in root.iter("Item"):
        if (model.get("class") == "Model"
                and value(model, "Name", "").startswith("Escarpment_")):
            escarpment_parts.extend(direct_children(model))
    assert len(escarpment_parts) == 56, (path, "expected 14 four-part escarpments")
    backdrop_profiles = set()
    backdrop_parts = {}
    for backdrop_name, (expected_position, expected_size) in backdrop_specs.items():
        backdrop_hills = named.get(backdrop_name, [])
        assert len(backdrop_hills) == 1, (
            path, backdrop_name, "missing boundary backdrop relief"
        )
        backdrop = backdrop_hills[0]
        assert position3(backdrop) == expected_position
        assert size(backdrop) == expected_size
        assert value(backdrop, "Material") == "1280"
        assert value(backdrop, "CanCollide") == "true"
        backdrop_center = position(backdrop)
        backdrop_half = (size(backdrop)[0] / 2, size(backdrop)[2] / 2)
        assert abs(backdrop_center[0]) + backdrop_half[0] <= 324
        assert abs(backdrop_center[1]) + backdrop_half[1] <= 324
        backdrop_profiles.add(size(backdrop))
        backdrop_parts[backdrop_name] = backdrop
        escarpment_overlaps = []
        for part in escarpment_parts:
            overlap = aabb_overlap(backdrop, part)
            if overlap is not None:
                escarpment_overlaps.append((value(part, "Name"), overlap))
        assert escarpment_overlaps, (
            path, backdrop_name, "boundary shoulder floats away from escarpment feet"
        )
        assert all(part_name == "RockFoot"
                   for part_name, _ in escarpment_overlaps), (
            path, backdrop_name, "boundary shoulder cuts through upper escarpment",
            escarpment_overlaps,
        )
        for resource_name, resource_point in resources.items():
            assert not (
                abs(resource_point[0] - backdrop_center[0]) <= backdrop_half[0] + 12
                and abs(resource_point[1] - backdrop_center[1]) <= backdrop_half[1] + 12
            ), (path, resource_name, backdrop_name, "backdrop crowds a harvest root")
        for stem in named.get("MushroomStem", []):
            stem_point = position(stem)
            assert not (
                abs(stem_point[0] - backdrop_center[0]) <= backdrop_half[0] + 6
                and abs(stem_point[1] - backdrop_center[1]) <= backdrop_half[1] + 6
            ), (path, backdrop_name, "backdrop crowds a Glowcap stem", stem_point)
    assert len(backdrop_profiles) == len(backdrop_specs), (
        path, "boundary relief regressed to repeated silhouettes", backdrop_profiles
    )
    forest_route_end = position(named["ForestRoute_06"][0])
    quarry_route_end = position(named["QuarryRoute_06"][0])
    boundary_sightlines = []
    for start, backdrop_name in (
        ((forest_route_end[0], 6.0, forest_route_end[1]), "ForestBackdropHill"),
        ((quarry_route_end[0], 6.0, quarry_route_end[1]), "QuarryBackdropHill"),
    ):
        backdrop = backdrop_parts[backdrop_name]
        center = position3(backdrop)
        boundary_sightlines.append((
            start,
            (center[0], center[1]+size(backdrop)[1]/2-.5, center[2]),
            (backdrop,),
        ))
    fixed_sightlines = (
        ((-168, 6, 45), (-125, 6, 76), ()),
        ((-125, 6, 182), position3(guide_parts["GuideCap"]), guide_parts.values()),
        ((-183, 6, 230), position3(focal_caps[0]), (focal_caps[0],)),
        ((-204, 6, 228), position3(focal_caps[0]), (focal_caps[0],)),
    ) + tuple(boundary_sightlines)
    for start, end, ignored in fixed_sightlines:
        blockers = visual_blockers(root, start, end, ignored)
        assert not blockers, (path, "fixed route sightline is occluded", start, end, blockers)

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
    station_profiles = []
    wall_names = {
        "RearWall", "SideWallLeft", "SideWallRight",
        "FrontWallLeft", "FrontWallRight", "FrontHeader",
    }
    for station in ("TradingPost", "CraftingWorkshop", "FarmerGuild", "CreatureNursery"):
        model = named.get(station, [])
        assert len(model) == 1, (path, "missing village station", station)
        station_parts = direct_children(model[0])
        roof_names = {value(child, "Name") for child in station_parts}
        assert {"RoofLeft", "RoofRight", "RoofRidge"} <= roof_names, (
            path, station, "unfinished flat roof"
        )
        assert "Walls" not in roof_names and wall_names <= roof_names, (
            path, station, "station regressed to one box shell", roof_names
        )
        pieces = {name: [child for child in station_parts if value(child, "Name") == name]
                  for name in roof_names}
        assert all(len(pieces[name]) == 1 for name in wall_names), (
            path, station, "missing modular wall piece"
        )
        door = pieces["Door"][0]
        assert size(door) == (5.0, 7.0, 0.5), (path, station, "door contract moved")
        assert value(door, "CanCollide") == "true"
        profile = tuple(size(pieces[name][0]) for name in (
            "RearWall", "SideWallLeft", "RoofLeft", "RoofRidge"
        ))
        station_profiles.append(profile)
        collidable = [part for part in station_parts if value(part, "CanCollide") == "true"]
        assert min(abs(position(part)[0]) - size(part)[0] / 2 for part in collidable) >= 24, (
            path, station, "station crowds protected central travel lane"
        )
    assert len(set(station_profiles)) == 4, (
        path, "village stations share repeated box/roof profile", station_profiles
    )
    ridge_tops = [
        elevation(next(child for child in direct_children(named[station][0])
                       if value(child, "Name") == "RoofRidge"))
        for station in ("TradingPost", "CraftingWorkshop", "FarmerGuild", "CreatureNursery")
    ]
    assert len(set(ridge_tops)) == 4 and max(ridge_tops) - min(ridge_tops) >= 2.5, (
        path, "village roof hierarchy flattened", ridge_tops
    )

    fountain = {name: named.get(name, []) for name in (
        "FountainBasin", "FountainWater", "FountainColumn", "FountainTop"
    )}
    assert all(len(parts) == 1 for parts in fountain.values()), (
        path, "missing or repeated fountain piece", fountain
    )
    fountain = {name: parts[0] for name, parts in fountain.items()}
    fountain_centers = {position(part) for part in fountain.values()}
    assert fountain_centers == {(-15.5, 12.0)}, (
        path, "fountain lost its left-shoulder composition", fountain_centers
    )
    assert size(fountain["FountainBasin"]) == (2.3, 11.5, 11.5)
    assert size(fountain["FountainWater"]) == (0.6, 9.0, 9.0)
    assert value(fountain["FountainBasin"], "CanCollide") == "true"
    assert value(fountain["FountainColumn"], "CanCollide") == "true"
    assert value(fountain["FountainWater"], "CanCollide") == "false"
    assert value(fountain["FountainTop"], "CanCollide") == "false"

    # SafetySpawn is a fixed 18x18 project object at (0, 0). Approximate the
    # vertical basin cylinder by its exact circular XZ footprint and require a
    # positive body-width margin from the spawn rectangle.
    basin_x, basin_z = position(fountain["FountainBasin"])
    basin_radius = size(fountain["FountainBasin"])[1] / 2
    nearest_spawn_x = min(9.0, max(-9.0, basin_x))
    nearest_spawn_z = min(9.0, max(-9.0, basin_z))
    spawn_clearance = math.dist(
        (basin_x, basin_z), (nearest_spawn_x, nearest_spawn_z)
    ) - basin_radius
    assert spawn_clearance >= 1.25, (
        path, "fountain overlaps or crowds SafetySpawn", spawn_clearance
    )
    assert abs(basin_x) - basin_radius >= 9.5, (
        path, "fountain crowds the protected spawn-to-gate lane"
    )

    gate_crests = named.get("GateCrest", [])
    assert len(gate_crests) == 1, (path, "missing north gate crest")
    spawn_gate_blockers = visual_blockers(
        root, (0.0, 6.0, 0.0), position3(gate_crests[0]), gate_crests
    )
    assert not spawn_gate_blockers, (
        path, "spawn-to-gate shoulder-height sightline is occluded",
        spawn_gate_blockers,
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
        "clear north route, two curved branches, paired waystones, five markers, "
        "lagoon-to-grove handoff, four station profiles, clear spawn vista and distinct destinations"
    )


for artifact in sys.argv[1:]:
    validate(artifact)
