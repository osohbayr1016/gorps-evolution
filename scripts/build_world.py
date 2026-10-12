#!/usr/bin/env python3
"""Generate a deterministic, editable Roblox world Model (.rbxmx).

Run before Rojo starts. This is an actual authored map asset, not geometry
created by a running server script. The map stays visible in Studio Edit mode.
Only the Python standard library is required.
"""
from __future__ import annotations

import math
from pathlib import Path
import random
import xml.etree.ElementTree as ET
from resource_models import build_resource

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "world" / "PlanetVerdant.rbxmx"
rng = random.Random(20261011)
document = ET.Element("roblox", {"version": "4"})
ET.SubElement(document, "External").text = "null"
ET.SubElement(document, "External").text = "nil"
serial = 0
count = 0


def prop(parent, tag, name, value):
    el = ET.SubElement(parent, tag, {"name": name})
    el.text = str(value).lower() if isinstance(value, bool) else str(value)
    return el


def item(parent, kind, name):
    global serial
    serial += 1
    obj = ET.SubElement(parent, "Item", {"class": kind, "referent": "RBX" + str(serial)})
    props = ET.SubElement(obj, "Properties")
    prop(props, "string", "Name", name)
    return obj, props


def vector(props, name, values, tag="Vector3"):
    el = ET.SubElement(props, tag, {"name": name})
    for component, value in zip("XYZ", values):
        ET.SubElement(el, component).text = f"{value:.5f}"


def color(props, rgb):
    c = ET.SubElement(props, "Color3", {"name": "Color"})
    for key, value in zip("RGB", rgb):
        ET.SubElement(c, key).text = f"{value / 255:.6f}"


def block(parent, name, pos, size, rgb, shape="Block", solid=True, material="SmoothPlastic",
          rotation=(0,0,0), part_class="Part"):
    global count
    count += 1
    obj, props = item(parent, part_class, name)
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "CFrame"})
    for component, value in zip("XYZ", pos):
        ET.SubElement(cf, component).text = f"{value:.5f}"
    pitch,yaw,roll=[math.radians(x) for x in rotation]
    cp,sp=math.cos(pitch),math.sin(pitch)
    cy,sy=math.cos(yaw),math.sin(yaw)
    cr,sr=math.cos(roll),math.sin(roll)
    matrix=[
        (cy*cr, cr*sy*sp-sr*cp, cr*sy*cp+sr*sp),
        (cy*sr, sr*sy*sp+cr*cp, sr*sy*cp-cr*sp),
        (-sy,cy*sp,cy*cp)
    ]
    for r in range(3):
        for c in range(3):
            ET.SubElement(cf, f"R{r}{c}").text = f"{matrix[r][c]:.6f}"
    vector(props, "Size", size)
    color(props, rgb)
    prop(props, "bool", "Anchored", True)
    prop(props, "bool", "CanCollide", solid)
    prop(props, "bool", "CastShadow", True)
    if part_class=="Part":
        prop(props, "token", "Shape", {"Ball": 0, "Block": 1, "Cylinder": 2}[shape])
    # Enum.Material identifiers are stable values in Roblox.
    material_id = {"SmoothPlastic":272,"Grass":1280,"Wood":512,
                   "Slate":800,"Neon":288,"Metal":1088,"Sand":1296,
                   "Glass":1568,"Fabric":1298,"Ground":1360}
    prop(props, "token", "Material", material_id.get(material, 272))
    return obj


def group(parent, name):
    return item(parent, "Model", name)[0]


def point_light(part, name, rgb, brightness=0.65, radius=20):
    """Attach a bounded non-shadow-casting Roblox PointLight to a real Part."""
    _, properties = item(part, "PointLight", name)
    color(properties, rgb)
    prop(properties, "float", "Brightness", brightness)
    prop(properties, "float", "Range", radius)
    prop(properties, "bool", "Shadows", False)


world = group(document, "PlanetVerdant")
terrain = group(world, "TerrainAndPaths")
block(terrain, "Ground", (0, 0, 0), (648, 2, 648), (79, 129, 101), material="Grass")
block(terrain, "SpawnCourtyard", (0, 1.18, 0), (60, .45, 50), (165, 153, 128), material="Slate")
block(terrain, "MainRoadNorth", (0, 1.15, 98), (15, .35, 175), (159, 150, 128))
block(terrain, "MainRoadSouth", (0, 1.15, -110), (15, .35, 175), (159, 150, 128))
block(terrain, "RanchPath", (0, 1.15, -163), (515, .35, 10), (153, 147, 126))
block(terrain, "ForestPath", (-125, 1.15, 115), (11, .35, 205), (152, 149, 128))
block(terrain, "MinesPath", (133, 1.15, 120), (11, .35, 205), (152, 149, 128))
for i in range(8):
    angle = math.tau * i / 8
    x, z = math.cos(angle)*47, math.sin(angle)*40
    block(terrain, f"GardenStone_{i:02d}", (x, 1.08, z), (12, .4, 8),
          (167, 162, 151), shape="Ball")
for x, z, sx, sz in [(-185,130,75,65),(185,155,75,70),(-240,265,70,65),(246,265,68,68)]:
    block(terrain, "LowHill", (x, 4, z), (sx, 9, sz), (77, 131, 105), shape="Ball", material="Grass")

# Large, low organic color fields break up the single flat green plane without
# creating collision steps. Roads sit slightly above these non-collidable mats.
biome_surfaces = group(terrain, "BiomeSurfaces")
for index, (x, z, sx, sz, tint, material) in enumerate([
    (-220, 125, 118, 92, (61, 111, 83), "Grass"),
    (-238, 230, 128, 116, (68, 116, 91), "Grass"),
    (-132, 230, 98, 112, (74, 126, 91), "Grass"),
    (-74, 175, 92, 88, (82, 137, 96), "Grass"),
    (76, 178, 98, 92, (91, 137, 91), "Grass"),
    (165, 226, 120, 112, (104, 135, 91), "Grass"),
    (244, 138, 112, 96, (124, 126, 102), "Slate"),
    (252, 248, 118, 112, (117, 126, 102), "Slate"),
    (174, 92, 88, 72, (133, 126, 98), "Ground"),
    (-186, 68, 86, 68, (70, 122, 99), "Grass"),
    (-258, 30, 80, 62, (73, 119, 101), "Grass"),
    (0, 246, 126, 74, (88, 137, 96), "Grass"),
]):
    block(biome_surfaces, f"BiomeFloor_{index:02d}", (x, 1.055, z),
          (sx, .16, sz), tint, shape="Ball", material=material, solid=False)

hub = group(world, "VillageHub")
block(hub, "WelcomePlatform", (0, 1.7, 8), (42, 1.3, 26), (169, 150, 119), material="Slate")
block(hub, "FountainBasin", (0, 3.1, 4), (2.3, 15, 15), (127, 158, 167),
      shape="Cylinder", material="Slate", rotation=(0, 0, 90))
block(hub, "FountainWater", (0, 4.4, 4), (.6, 12, 12), (92, 163, 159),
      shape="Cylinder", material="Glass", rotation=(0, 0, 90))
block(hub, "FountainColumn", (0, 7.5, 4), (7, 2.6, 2.6), (141, 173, 177),
      shape="Cylinder", rotation=(0, 0, 90))
block(hub, "FountainTop", (0, 11.5, 4), (5, 2.5, 5), (149, 209, 195), shape="Ball", solid=False, material="Glass")

# Four recognizable silhouettes share a small, reusable kit but never identical facades.
# Geometry is authored in Edit mode and interaction doors retain their names.
SHOP_KIT = {
    "TradingPost": {"roof": (113, 74, 59), "trim": (227, 182, 115),
                    "wood": (93, 68, 58), "mark": "Coin"},
    "CraftingWorkshop": {"roof": (76, 91, 104), "trim": (118, 179, 190),
                         "wood": (77, 83, 88), "mark": "Tools"},
    "FarmerGuild": {"roof": (99, 117, 76), "trim": (194, 187, 112),
                    "wood": (103, 90, 63), "mark": "Sheaf"},
    "CreatureNursery": {"roof": (127, 97, 125), "trim": (222, 170, 194),
                        "wood": (112, 82, 101), "mark": "Egg"},
}


def hut(parent, title, x, z, theme):
    kit = SHOP_KIT[title]
    h = group(parent, title)
    stone = (150, 141, 125)
    timber = kit["wood"]
    accent = kit["trim"]
    roof = kit["roof"]

    # The front faces south (-Z); keep Door exactly where world shop prompts expect.
    block(h, "Floor", (x, 2, z), (24, 2, 19), stone, material="Slate")
    block(h, "Walls", (x, 8, z), (19, 11, 15), theme, material="Wood")
    block(h, "PlinthFront", (x, 2.8, z-8.1), (22, 1.15, 2.8), timber, material="Wood")
    for side in (-1, 1):
        dx = side * 9.6
        block(h, "CornerPost", (x+dx, 8.8, z-7.9), (1.5, 12.1, 1.8), timber, material="Wood")
        block(h, "WindowFrame", (x+side*6, 9, z-7.95), (4.6, 4.7, .85),
              timber, material="Wood", solid=False)
        block(h, "Window", (x+side*6, 9, z-8.5), (3.0, 3.2, .28),
              (151, 199, 198), material="Glass", solid=False)
        block(h, "WindowSill", (x+side*6, 6.75, z-8.65), (4.8, .52, 1.2),
              stone, material="Slate", solid=False)
        block(h, "WindowShutter", (x+side*9.1, 9, z-8.45), (.55, 4.5, .65),
              accent, material="Wood", solid=False)
    for height in (4.0, 12.65):
        block(h, "FacadeBeam", (x, height, z-8.0), (21, .65, 1.4),
              timber, material="Wood", solid=False)

    block(h, "RoofLeft", (x, 15.1, z-4.5), (26.5, 1.6, 11.3),
          roof, material="Slate", rotation=(24, 0, 0))
    block(h, "RoofRight", (x, 15.1, z+4.5), (26.5, 1.6, 11.3),
          roof, material="Slate", rotation=(-24, 0, 0))
    block(h, "RoofRidge", (x, 17.35, z), (27, 1.0, 1.7), timber, material="Wood")
    # Distinct high roofline details read from the spawn/overview camera.
    for side in (-1, 1):
        block(h, "RoofFinial", (x+side*12, 17.4, z), (1.2, 2.7, 1.2),
              accent, material="Wood", solid=False)
        block(h, "EaveFront", (x+side*6.2, 13.5, z-9.2), (12.8, .5, .75),
              timber, material="Wood", solid=False)

    block(h, "Door", (x, 5.5, z-8), (5, 7, .5), timber, material="Wood")
    block(h, "DoorFrameTop", (x, 9.2, z-8.8), (6.9, .9, .9),
          accent, material="Wood", solid=False)
    block(h, "DoorHandle", (x+1.7, 5.3, z-8.55), (.55, .55, .55),
          accent, shape="Ball", solid=False, material="Metal")
    block(h, "Awning", (x, 12.2, z-10.2), (11.6, .8, 4.2),
          roof, material="Wood", rotation=(-8, 0, 0), solid=False)
    block(h, "SignBoard", (x, 13.2, z-10.8), (10.5, 3.4, .7),
          timber, material="Wood", solid=False)
    block(h, "SignTrim", (x, 13.2, z-11.25), (9.3, 2.55, .18),
          accent, material="Wood", solid=False)

    # Solid icon silhouettes are not glowing floating rectangles. Their color
    # and shapes pair with native UI dock icons and indicate shop purpose.
    if kit["mark"] == "Coin":
        block(h, "MerchantCoin", (x, 13.2, z-11.5), (1.1, 2.0, 2.0),
              (238, 205, 123), shape="Cylinder", rotation=(0, 90, 0),
              material="Metal", solid=False)
        for dx in (-3.4, 3.4):
            block(h, "MerchantCrate", (x+dx, 3.2, z-11.4), (3.4, 2.0, 2.9),
                  (155, 116, 77), material="Wood", solid=False)
    elif kit["mark"] == "Tools":
        for slope in (-35, 35):
            block(h, "CrossedTool", (x, 13.3, z-11.65), (.65, 2.55, .4),
                  (55, 77, 84), material="Metal", rotation=(0, 0, slope),
                  solid=False)
        block(h, "ForgeChimney", (x+6.9, 19.1, z+4), (3.4, 8.5, 3.4),
              (108, 110, 113), material="Slate")
        block(h, "ForgeCap", (x+6.9, 23.7, z+4), (4.8, .7, 4.8),
              timber, material="Metal")
    elif kit["mark"] == "Sheaf":
        for dx in (-1.0, 0, 1.0):
            block(h, "WheatIcon", (x+dx, 13.2, z-11.6), (.65, 2.2, .5),
                  (238, 208, 126), material="Wood", rotation=(0, 0, dx*18),
                  solid=False)
        for side in (-1, 1):
            block(h, "FarmBarrel", (x+side*10, 3.3, z-11),
                  (3.0, 3.2, 3.0), (128, 104, 69),
                  shape="Cylinder", material="Wood", solid=False, rotation=(0,0,90))
    elif kit["mark"] == "Egg":
        block(h, "EggIcon", (x, 13.3, z-11.7), (1.8, 2.35, .65),
              (253, 225, 184), shape="Ball", solid=False)
        for side in (-1, 1):
            block(h, "NestStand", (x+side*10.2, 2.7, z-11.3),
                  (4.0, 1.2, 4), timber, solid=False, material="Wood")
            block(h, "NestEgg", (x+side*10.2, 4.15, z-11.3),
                  (2.4, 3.0, 2.4), (234, 207, 212),
                  shape="Ball", solid=False)
    return h


hut(hub,"TradingPost",-62,6,(185,167,142))
hut(hub,"CraftingWorkshop",61,6,(157,171,166))
hut(hub,"FarmerGuild",-52,-51,(172,181,148))
hut(hub,"CreatureNursery",54,-51,(191,168,179))


# A recognizable gate frames the first resource route without blocking its
# 15-stud-wide walkable center. This is a fixed visual compass, not a portal.
wayfinder = group(hub, "VerdantWayfinder")
for side in (-1, 1):
    px = side * 18.5
    block(wayfinder, "GateFoot", (px, 2, 43), (6.0, 2.0, 6.0),
          (133, 128, 111), material="Slate")
    block(wayfinder, "GatePillar", (px, 9.7, 43), (3.6, 14.0, 3.6),
          (119, 119, 100), material="Slate")
    block(wayfinder, "GateCap", (px, 17.3, 43), (5.2, 1.4, 5.2),
          (199, 172, 117), material="Slate")
    block(wayfinder, "GuideBanner", (px, 12, 40.7), (2.7, 7, .4),
          (side==-1 and 98 or 196, side==-1 and 170 or 154, 136),
          material="Fabric", solid=False)
block(wayfinder, "GateLintel", (0, 17.2, 43), (37.4, 2.3, 3.6),
      (102, 110, 97), material="Slate")
block(wayfinder, "GateCrest", (0, 19.7, 43), (8.2, 2.8, 2.8),
      (205, 184, 124), material="Wood", solid=False)
for side in (-1, 1):
    # Seats and garden pots live outside the central travel lane.
    px = side * 22
    for z in (-9, 15):
        block(hub, "PlazaPlanter", (px, 2.3, z), (7.5, 2.3, 7.5),
              (139, 122, 103), material="Slate", solid=False)
        block(hub, "PlanterFoliage", (px, 4.1, z), (6.6, 2.5, 6.6),
              (94, 155, 113), shape="Ball", material="Grass", solid=False)
    block(hub, "PlazaBench", (px, 3, 4), (8, 1.2, 2.2),
          (144, 112, 83), material="Wood", solid=False)
    block(hub, "BenchBack", (px, 4.7, 5), (8, 2.3, .8),
          (121, 94, 73), material="Wood", solid=False)

for k, (x,z) in enumerate([(34,32),(-34,32),(34,-30),(-34,-30)]):
    block(hub,"LanternPost_%d"%k,(x,5,z),(.9,8,.9),(87,81,75),material="Wood")
    lantern = block(hub,"LanternLight_%d"%k,(x,9.4,z),(3,3,3),(255,215,136),
          shape="Ball",solid=False,material="Neon")
    point_light(lantern, "VillageLanternLight", (255, 208, 151), 0.48, 16)

ranches=group(world,"RanchPlots")
for row in range(2):
    for col in range(6):
        index=row*6+col+1
        x=(col-2.5)*89
        z=-210+row*93
        front=1 if row==0 else -1
        plot=group(ranches, f"RanchPlot_{index:02d}")
        block(plot,"Land", (x,1.1,z),(55,.35,55),(103,153,110),material="Grass")
        # Empty plots remain intentionally quiet. Runtime ranches supply their
        # own expandable perimeter and homestead; duplicated authored fences
        # previously intersected levelled ranch fences and inflated part count.
        block(plot,"HomesteadPad",(x,1.35,z-front*10),(20,.5,16),(166,139,103),
              material="Wood",solid=False)
        block(plot,"ArrivalPath",(x,1.31,z+front*30),(9,.18,9),(153,147,126),
              material="Ground",solid=False)
        for sx,sz in ((-1,-1),(-1,1),(1,-1),(1,1)):
            block(plot,"PlotCorner",(x+sx*26,1.7,z+sz*26),(2.5,1.2,2.5),
                  (132,126,111),material="Slate",solid=False)

forest=group(world,"ForestsAndWildlife")
starter_positions=[
    (-42,68),(42,68),(64,92),(92,122),
    (-64,92),(-92,122),(-45,132),(55,155),
]

def reserved_route(x,z,padding=0):
    """Keep authored movement corridors and landmarks visually readable."""
    if abs(x)<14+padding and 35-padding<z<302: return True
    if abs(x+125)<9+padding and 42-padding<z<221: return True
    if abs(x-133)<9+padding and 42-padding<z<221: return True
    if abs(x)<82+padding and -74-padding<z<52+padding: return True
    if math.hypot(x+215,z-45)<52+padding: return True
    if math.hypot(x-222,z-20)<54+padding: return True
    return False

canopy_positions=[]
forest_types=("Broadleaf","Pine","Birch","Ancient")
for i in range(64):
    for _ in range(200):
        x=rng.uniform(-302,302);z=rng.uniform(48,301)
        if reserved_route(x,z,6): continue
        if any(math.hypot(x-sx,z-sz)<15 for sx,sz in starter_positions): continue
        if any(math.hypot(x-tx,z-tz)<12 for tx,tz in canopy_positions): continue
        break
    else:
        raise RuntimeError("Could not place canopy tree outside a travel route")
    canopy_positions.append((x,z))
    archetype=forest_types[i%len(forest_types)]
    tree=group(forest,f"CanopyTree_{archetype}_{i:03d}")
    yaw=rng.uniform(-28,28)
    if archetype=="Broadleaf":
        h=rng.uniform(12,17)
        block(tree,"BroadleafTrunk",(x,h/2+1,z),(h,3.1,3.1),(105,78,61),
              shape="Cylinder",material="Wood",rotation=(0,0,90))
        for side in (-1,1):
            block(tree,"CrownBranch",(x+side*2.6,h-1,z),(6.8,1.4,1.5),
                  (101,76,59),material="Wood",rotation=(0,side*18,side*26),solid=False)
        for name,dx,dz,scale,tint in [
            ("CrownMain",0,0,13,(70,139,91)),
            ("CrownLeft",-5,1,9,(83,153,95)),
            ("CrownRight",4,-2,10,(93,163,101)),
        ]:
            block(tree,name,(x+dx,h+3,z+dz),(scale,8,scale*.82),tint,
                  shape="Ball",solid=False,material="Grass")
    elif archetype=="Pine":
        h=rng.uniform(15,21)
        block(tree,"PineTrunk",(x,h/2+1,z),(h,2.4,2.4),(92,70,56),
              shape="Cylinder",material="Wood",rotation=(0,0,90))
        for tier,(height,width,tint) in enumerate([
            (h*.48,12,(54,111,83)),(h*.68,9,(61,126,89)),
            (h*.84,6.5,(72,141,94)),(h*.96,4,(84,151,99)),
        ]):
            block(tree,f"PineBough_{tier}",(x,height+2,z),(width,5.0,width*.72),
                  tint,part_class="WedgePart",rotation=(0,yaw+tier*90,0),
                  solid=False,material="Grass")
        block(tree,"PineTip",(x,h+2.2,z),(2.2,4,2.2),(94,161,105),
              part_class="WedgePart",rotation=(0,yaw,0),solid=False,material="Grass")
    elif archetype=="Birch":
        h=rng.uniform(11,16)
        block(tree,"BirchTrunk",(x,h/2+1,z),(h,2.5,2.5),(213,207,183),
              shape="Cylinder",material="Wood",rotation=(0,0,90))
        for band,height in enumerate((h*.35,h*.68)):
            block(tree,f"BirchBand_{band}",(x,height+1,z),(.35,2.7,2.7),
                  (76,72,66),shape="Cylinder",rotation=(0,0,90),solid=False)
        block(tree,"BirchCrown",(x,h+2,z),(10,7.5,8),(113,167,103),
              shape="Ball",solid=False,material="Grass")
        block(tree,"BirchCrownHigh",(x+2,h+6,z-1),(7,6,6),(137,183,112),
              shape="Ball",solid=False,material="Grass")
    else:
        h=rng.uniform(10,15)
        block(tree,"AncientTrunk",(x,h/2+1,z),(3.8,h,3.8),(91,69,57),
              material="Wood",rotation=(0,yaw,6))
        for side in (-1,1):
            block(tree,"AncientBranch",(x+side*3.0,h-1,z+side),
                  (7.5,1.8,1.8),(91,69,57),material="Wood",
                  rotation=(0,side*28,side*34),solid=False)
            block(tree,"AncientFan",(x+side*5.0,h+2,z+side),
                  (8.5,6.5,5.5),side==-1 and (75,135,92) or (100,153,94),
                  part_class="WedgePart",rotation=(0,side*45,0),
                  solid=False,material="Grass")

# A few authored props make the forest floor feel inhabited while staying
# outside protected routes. They reuse native parts and do not add asset loads.
for index,(x,z,length,yaw) in enumerate([
    (-270,112,12,18),(-196,155,10,-24),(-245,252,13,8),
    (-92,242,11,31),(112,245,12,-18),(205,193,10,26),
]):
    block(forest,f"FallenLog_{index}",(x,2.2,z),(length,3.0,3.0),
          (98,72,56),shape="Cylinder",material="Wood",rotation=(0,yaw,0),
          solid=False)
    block(forest,f"LogMoss_{index}",(x,3.45,z),(length*.72,.6,2.2),
          (82,132,83),shape="Ball",material="Grass",solid=False,
          rotation=(0,yaw,0))

nodes=group(world,"ResourceNodes")
kinds=["Tree","Tree","Rock","Ore","Bush","Crystal","Fiber","Wild"]
placed=[]
for i in range(70):
    kind=kinds[i%len(kinds)]
    if i<len(starter_positions):
        x,z=starter_positions[i]
    else:
        # Rejection sampling is seeded and deterministic. It prevents the old
        # z=37 clamp from stacking many nodes in a wall across the trail.
        for _ in range(500):
            x=rng.uniform(-286,286);z=rng.uniform(62,286)
            if reserved_route(x,z,5): continue
            if any(math.hypot(x-px,z-pz)<18 for px,pz in placed): continue
            if any(math.hypot(x-tx,z-tz)<9 for tx,tz in canopy_positions): continue
            break
        else:
            raise RuntimeError("Could not place spaced resource node")
    placed.append((x,z))
    node=group(nodes,f"{kind}_{i+1:03d}")
    build_resource(node,kind,x,z,block,rng)

# The starter circuit is visible from the north village exit. Mint markers
# point to food/wood; amber markers lead to stone/ore; violet marks hunting.
trail=group(world,"StarterResourceTrail")
block(trail,"TrailheadPad",(0,1.35,52),(34,.55,16),(203,188,149),material="Sand")
for i,(x,z,marker_color,yaw) in enumerate([
    (-18,61,(102,207,153),-35),(18,61,(236,186,111),35),
    (-28,116,(102,207,153),-20),(31,119,(236,186,111),20),
    (31,151,(184,142,224),18),
]):
    block(trail,f"TrailPost_{i+1}",(x,4.1,z),(1.1,6,1.1),(113,88,68),material="Wood")
    block(trail,f"TrailArrow_{i+1}",(x,7.1,z),(5,2.4,1.2),marker_color,
          solid=False,material="Neon",rotation=(0,yaw,0),part_class="WedgePart")
for z in (72,94,116,138):
    block(trail,"TrailStone",(-7,1.32,z),(5,.48,3.2),(177,171,153),
          shape="Ball",material="Slate")
    block(trail,"TrailStone",(7,1.32,z),(5,.48,3.2),(177,171,153),
          shape="Ball",material="Slate")

ufo=group(world,"UFO")
block(ufo,"Saucer",(0,30,155),(4,22,22),(121,198,210),
      shape="Cylinder",solid=False,material="Metal",rotation=(0,0,90))
block(ufo,"Dome",(0,34,155),(12,8,12),(175,153,228),
      shape="Ball",solid=False,material="Neon")
for i in range(8):
    a=math.tau*i/8
    block(ufo,"UfoLight",(math.cos(a)*9,30,155+math.sin(a)*9),
          (2.3,1.6,2.3),(255,203,117),shape="Ball",solid=False,material="Neon")
block(world,"NorthBeacon",(0,11,296),(20,8,8),(99,221,204),
      shape="Cylinder",solid=False,material="Neon",rotation=(0,0,90))

# Hand-designed readable biome landmarks instead of a featureless island.
landmarks=group(world,"SignatureLandmarks")
lake=group(landmarks,"MoonwaterLagoon")
block(lake,"LagoonRockRim",(-215,1.1,45),(66,1.7,65),(132,155,147),
      shape="Ball",material="Slate")
block(lake,"GlowingWater",(-215,2.2,45),(59,.8,58),(83,190,195),
      shape="Ball",solid=False,material="Neon")
for i in range(10):
    a=math.tau*i/10
    x=-215+math.cos(a)*24
    z=45+math.sin(a)*24
    block(lake,"WaterLily",(x,2.9,z),(5,.45,4),(95,171,128),
          shape="Ball",solid=False,material="Grass")
    block(lake,"Flower",(x,3.5,z),(1.5,.9,1.5),(247,194,211),
          shape="Ball",solid=False)
block(lake,"ReedBridge",(-175,4,45),(18,1,8),(184,149,113),material="Wood")
for i in range(6):
    block(lake,"BridgePost",(-182+i*3,5.6,41),(1,3.4,1),
          (128,97,77),material="Wood")
quarry=group(landmarks,"SunstoneQuarry")
block(quarry,"MineRidge",(222,3,20),(74,8,66),(101,113,124),
      shape="Ball",material="Slate")
block(quarry,"Entrance",(222,7,-16),(23,13,6),(48,58,69),material="Slate")
for i in range(12):
    x=196+(i%4)*16
    z=-7+(i//4)*16
    block(quarry,"OreBoulder",(x,6,z),(9,9,9),(119,133,142),shape="Ball",material="Slate")
    block(quarry,"OreGem",(x+2,9,z-1),(3,4,3),rng.choice([(113,209,218),(175,150,238),(245,202,120)]),
          shape="Ball",solid=False,material="Neon")
for i in range(7):
    x=189+i*9
    block(quarry,"QuarryLantern",(x,3,-27),(1,3,1),(136,111,78),material="Wood")
    block(quarry,"LanternGlow",(x,5,-27),(2.3,2.3,2.3),(254,211,124),
          shape="Ball",solid=False,material="Neon")
mushrooms=group(landmarks,"GlowcapGrove")
for i in range(16):
    x=rng.uniform(-290,-175)
    z=rng.uniform(175,298)
    h=rng.uniform(4,10)
    block(mushrooms,"MushroomStem",(x,h/2+1,z),(1.9,h,1.9),
          (225,214,192),material="SmoothPlastic")
    cap_color=rng.choice([(210,131,199),(119,178,228),(239,166,152),(196,164,234)])
    cap = block(mushrooms,"Glowcap",(x,h+1,z),(rng.uniform(5,9),3.7,7),cap_color,
          shape="Ball",solid=False,material="Glass")
    if i % 4 == 0:
        point_light(cap, "GroveLight", cap_color, 0.55, 18)
    for j in range(2):
        block(mushrooms,"GlowDot",(x+rng.uniform(-2,2),h+2.8,z+rng.uniform(-2,2)),
              (.6,.6,.6),(249,233,208),shape="Ball",solid=False,material="Neon")
markets=group(landmarks,"MarketDecor")
for x,z,fabric_color in [(-37,27,(117,204,172)),(38,27,(233,180,130)),
                  (-26,-32,(218,143,172)),(28,-32,(125,168,219))]:
    stall=group(markets,"MarketStall")
    block(stall,"Counter",(x,3.6,z),(11,2.2,5),(165,128,99),material="Wood")
    for side in [-1,1]:
        block(stall,"CanopySupport",(x+side*4.8,6.1,z),(1,6,1),(121,93,72),material="Wood")
    block(stall,"Canopy",(x,9.3,z),(13,1.4,8),fabric_color,material="SmoothPlastic")
    for k in range(3):
        block(stall,"MarketCrate",(x-3+k*3,5.1,z),(2.5,1.4,2.2),
              (184,148,100),material="Wood")
        block(stall,"MarketProduce",(x-3+k*3,6.1,z),(1.7,1.5,1.8),
              rng.choice([(97,198,142),(239,168,124),(161,132,215)]),
              shape="Ball",solid=False)
scenery=group(world,"WorldDecor")
flowers=0
while flowers<55:
    x=rng.uniform(-306,306)
    z=rng.uniform(-302,295)
    if reserved_route(x,z,2): continue
    if any(math.hypot(x-sx,z-sz)<10 for sx,sz in starter_positions): continue
    size=rng.uniform(1.1,2.1)
    block(scenery,"WildflowerStem",(x,1.8,z),(.22,2,.22),
          (73,155,101),solid=False,material="Grass")
    block(scenery,"Wildflower",(x,2.9,z),(size,size/1.8,size),
          rng.choice([(246,189,163),(245,210,124),(168,169,235),(195,220,181)]),
          shape="Ball",solid=False)
    flowers+=1
for i in range(20):
    a=math.tau*i/20
    d=285+rng.uniform(-10,20)
    x=math.cos(a)*d
    z=math.sin(a)*d
    block(scenery,"OuterStone",(x,2.5,z),(rng.uniform(5,11),rng.uniform(5,10),rng.uniform(6,13)),
          (110,145,131),shape="Ball",material="Slate")



# Sculpted solid outskirts and small playable-area knolls break the uniform
# horizon without moving starter objectives, ranch pads, harvest IDs or roads.
# The far escarpments are deliberately outside resource/plot corridors; the
# smaller knolls must pass clearance checks against every harvest and tree root.
relief = group(world, "WorldRelief")
edge_ridges = [
    (-320, 20, 37, 51), (-320, 92, 39, 56), (-319, 171, 37, 55),
    (-320, 256, 40, 54), (320, 20, 37, 51), (320, 92, 39, 56),
    (319, 171, 37, 55), (320, 256, 40, 54),
    (-260, 320, 54, 37), (-175, 319, 57, 38), (-95, 320, 49, 38),
    (95, 320, 49, 38), (175, 319, 57, 38), (260, 320, 54, 37),
]
for index, (x, z, sx, sz) in enumerate(edge_ridges):
    ridge = group(relief, f"Escarpment_{index:02d}")
    factor = 1.0 + (index % 4) * 0.11
    block(ridge, "RockFoot", (x, 4.7, z), (sx * 1.18, 9.2, sz * 1.12),
          (99, 115, 107), shape="Ball", material="Slate")
    block(ridge, "CliffSlope", (x, 10.0 * factor, z), (sx * .9, 16 * factor, sz * .88),
          (116, 126, 112), material="Slate", part_class="WedgePart",
          rotation=(0, (index % 3 - 1) * 17, 0))
    block(ridge, "StrataShelf", (x, 17.4 * factor, z), (sx * .8, 3.8, sz * .75),
          (144, 149, 126), shape="Ball", material="Slate")
    block(ridge, "GrassCrest", (x, 19.6 * factor, z), (sx * .67, 4.4, sz * .7),
          (73, 118, 92), shape="Ball", material="Grass")

knoll_centers = []
# Prefer open meadow shoulders first, then gently relieved forest pockets;
# row-first enumeration distributes knolls across west/east rather than
# concentrating the first nine on one edge.
for z in (-58, -18, 22, 85, 128, 171, 214, 257):
    for x in range(-258, 259, 43):
        if reserved_route(x, z, 22):
            continue
        if any(math.hypot(x - nx, z - nz) < 28 for nx, nz in placed):
            continue
        if any(math.hypot(x - tx, z - tz) < 23 for tx, tz in canopy_positions):
            continue
        if any(math.hypot(x - kx, z - kz) < 48 for kx, kz in knoll_centers):
            continue
        knoll_centers.append((x, z))
        knoll = group(relief, f"TerrainKnoll_{len(knoll_centers):02d}")
        block(knoll, "StoneRoot", (x, 2.1, z), (25, 4.6, 27),
              (99, 118, 104), shape="Ball", material="Slate")
        block(knoll, "RisingSlope", (x, 3.3, z), (22, 6.3, 24),
              (74, 123, 91), shape="Ball", material="Grass")
        block(knoll, "TurfCap", (x, 6.1, z), (13, 2.8, 15),
              (90, 138, 98), shape="Ball", material="Grass", solid=False)
        if len(knoll_centers) == 9:
            break
    if len(knoll_centers) == 9:
        break

# Asset regression contracts run each time the generator runs (including CI).
# They check authored structure/route clearance, not Studio render quality.
def verify_village_kit():
    named = {}
    for obj in document.iter("Item"):
        props = obj.find("Properties")
        name = next((entry.text for entry in (props if props is not None else [])
                     if entry.get("name") == "Name"), None)
        if name:
            named.setdefault(name, []).append(obj)
    for station, kit in SHOP_KIT.items():
        models = named.get(station, [])
        assert len(models) == 1, (station, "missing distinctive station")
        parts = {
            next((entry.text for entry in child.find("Properties")
                  if entry.get("name") == "Name"), None)
            for child in models[0] if child.tag == "Item"
        }
        expected = {"Door", "SignBoard", "SignTrim", "Awning", "WindowFrame",
                    "RoofLeft", "RoofRight", "RoofRidge", "RoofFinial"}
        unique = {"Coin": "MerchantCoin", "Tools": "CrossedTool",
                  "Sheaf": "WheatIcon", "Egg": "EggIcon"}[kit["mark"]]
        assert expected | {unique} <= parts, (station, "missing kit piece", expected - parts)
        assert sum(part == "Door" for part in parts) == 1, (station, "prompt entry lost")
    gate = named.get("VerdantWayfinder", [])
    assert len(gate) == 1, "missing village-to-harvest focal landmark"
    for obj in gate[0].iter("Item"):
        props = obj.find("Properties")
        if props is None:
            continue
        name = next((p.text for p in props if p.get("name") == "Name"), "")
        if name not in {"GateFoot", "GatePillar", "GateCap", "GuideBanner"}:
            continue
        frame = next(p for p in props if p.get("name") == "CFrame")
        x = float(frame.find("X").text)
        assert abs(x) >= 15.0, (name, "gate blocks walking center")
    assert count < 2300, "village art overran current static part budget"


verify_village_kit()

OUT.parent.mkdir(parents=True,exist_ok=True)
ET.indent(document,space="  ")
ET.ElementTree(document).write(OUT,encoding="utf-8",xml_declaration=True)
print(f"Generated {OUT.relative_to(ROOT)}: {count} anchored 3D parts, 12 ranch plots, 70 resource nodes")
