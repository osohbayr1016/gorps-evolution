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


def block(parent, name, pos, size, rgb, shape="Block", solid=True, material="SmoothPlastic"):
    global count
    count += 1
    obj, props = item(parent, "Part", name)
    cf = ET.SubElement(props, "CoordinateFrame", {"name": "CFrame"})
    for component, value in zip("XYZ", pos):
        ET.SubElement(cf, component).text = f"{value:.5f}"
    for r in range(3):
        for c in range(3):
            ET.SubElement(cf, f"R{r}{c}").text = "1" if r == c else "0"
    vector(props, "Size", size)
    color(props, rgb)
    prop(props, "bool", "Anchored", True)
    prop(props, "bool", "CanCollide", solid)
    prop(props, "bool", "CastShadow", True)
    prop(props, "token", "Shape", {"Ball": 0, "Block": 1, "Cylinder": 2}[shape])
    # Enum.Material identifiers are stable values in Roblox.
    material_id = {"SmoothPlastic":272,"Grass":1280,"Wood":512,
                   "Slate":800,"Neon":288,"Metal":1088,"Sand":1296}
    prop(props, "token", "Material", material_id.get(material, 272))
    return obj


def group(parent, name):
    return item(parent, "Model", name)[0]


world = group(document, "PlanetVerdant")
terrain = group(world, "TerrainAndPaths")
block(terrain, "Ground", (0, 0, 0), (648, 2, 648), (64, 121, 100), material="Grass")
block(terrain, "SpawnCourtyard", (0, 1.18, 0), (60, .45, 50), (220, 198, 151), material="Sand")
block(terrain, "MainRoadNorth", (0, 1.15, 98), (15, .35, 175), (188, 174, 143))
block(terrain, "MainRoadSouth", (0, 1.15, -110), (15, .35, 175), (188, 174, 143))
block(terrain, "RanchPath", (0, 1.15, -163), (515, .35, 10), (192, 181, 155))
block(terrain, "ForestPath", (-125, 1.15, 115), (11, .35, 205), (172, 161, 137))
block(terrain, "MinesPath", (133, 1.15, 120), (11, .35, 205), (172, 161, 137))
for i in range(8):
    angle = math.tau * i / 8
    x, z = math.cos(angle)*47, math.sin(angle)*40
    block(terrain, f"GardenStone_{i:02d}", (x, 1.08, z), (12, .4, 8),
          (167, 162, 151), shape="Ball")
for x, z, sx, sz in [(-185,130,75,65),(185,155,75,70),(-240,265,70,65),(246,265,68,68)]:
    block(terrain, "LowHill", (x, 4, z), (sx, 9, sz), (77, 131, 105), shape="Ball", material="Grass")

hub = group(world, "VillageHub")
block(hub, "WelcomePlatform", (0, 1.7, 8), (42, 1.3, 26), (218, 194, 149), material="Wood")
block(hub, "FountainBasin", (0, 3.1, 4), (15, 2.3, 15), (127, 158, 167), shape="Cylinder", material="Slate")
block(hub, "FountainWater", (0, 4.4, 4), (12, .6, 12), (87, 205, 212), shape="Cylinder", material="Neon")
block(hub, "FountainColumn", (0, 7.5, 4), (2.6, 7, 2.6), (141, 173, 177), shape="Cylinder")
block(hub, "FountainTop", (0, 11.5, 4), (5, 2.5, 5), (112, 221, 227), shape="Ball", solid=False, material="Neon")

def hut(parent, title, x, z, theme):
    h=group(parent,title)
    block(h, "Floor", (x, 2, z), (22, 2, 17), (161, 126, 98), material="Wood")
    block(h, "Walls", (x, 8, z), (19, 11, 15), theme, material="Wood")
    block(h, "Roof", (x, 14.3, z), (24, 3, 19), (71, 91, 105), material="Slate")
    block(h, "Door", (x, 5.5, z-8), (5, 7, .5), (74, 83, 88), material="Wood")
    block(h, "DoorGlow", (x, 7, z-8.4), (1, 1, .4), (231, 203, 121), material="Neon")
    for dx in [-6,6]:
        block(h, "Window", (x+dx, 9, z-7.6), (3, 3, .4), (130, 212, 225),
              material="Neon")
    return h

hut(hub,"TradingPost",-62,6,(180,153,120))
hut(hub,"CraftingWorkshop",61,6,(169,164,153))
hut(hub,"FarmerGuild",-52,-51,(153,176,131))
hut(hub,"CreatureNursery",54,-51,(210,158,173))

for k, (x,z) in enumerate([(34,32),(-34,32),(34,-30),(-34,-30)]):
    block(hub,"LanternPost_%d"%k,(x,5,z),(.9,8,.9),(87,81,75),material="Wood")
    block(hub,"LanternLight_%d"%k,(x,9.4,z),(3,3,3),(255,215,136),
          shape="Ball",solid=False,material="Neon")

ranches=group(world,"RanchPlots")
for row in range(2):
    for col in range(6):
        index=row*6+col+1
        x=(col-2.5)*89
        z=-210+row*93
        plot=group(ranches, f"RanchPlot_{index:02d}")
        block(plot,"Land", (x,1.1,z),(55,.35,55),(103,153,110),material="Grass")
        block(plot,"Foundation",(x,1.5,z-10),(18,1,15),(187,158,122),material="Wood")
        block(plot,"PlotMarker",(x,3.3,z+18),(7,3,3),(244,207,112),solid=False)
        for side in (-1,1):
            for step in (-27,-18,-9,0,9,18,27):
                block(plot,"FencePost",(x+step,3,z+side*27),(1.1,4,1.1),
                      (159,124,89),material="Wood")
                block(plot,"FencePost",(x+side*27,3,z+step),(1.1,4,1.1),
                      (159,124,89),material="Wood")

forest=group(world,"ForestsAndWildlife")
for i in range(85):
    x=rng.uniform(-302,302);z=rng.uniform(48,301)
    if abs(x)<33 or (-78<x<78 and z<94):
        x+=90 if x>=0 else -90
    tree=group(forest,f"CanopyTree_{i:03d}")
    h=rng.uniform(9,17)
    block(tree,"Trunk",(x,h/2+1,z),(3,h,3),(115,86,68),material="Wood")
    for j,(offx,offz) in enumerate([(0,0),(4,1),(-4,-1)]):
        block(tree,f"Leaves_{j}",(x+offx,h+3+j*.8,z+offz),
              (11,10,11),rng.choice([(79,155,103),(97,177,110),(110,179,120)]),
              shape="Ball",solid=False,material="Grass")

nodes=group(world,"ResourceNodes")
kinds=["Tree","Tree","Rock","Ore","Bush","Crystal","Fiber","Wild"]
for i in range(70):
    kind=kinds[i%len(kinds)]
    angle=(i+1)*2.3999632
    dist=85+(i%6)*29
    x=math.cos(angle)*dist
    z=min(286,max(37,math.sin(angle)*dist+156))
    if abs(x)<25: x+=42 if x>=0 else -42
    node=group(nodes,f"{kind}_{i+1:03d}")
    if kind=="Tree":
        block(node,"Interact",(x,5.5,z),(4,9,4),(141,100,67),material="Wood")
        for j in range(3):
            block(node,f"Leaves{j}",(x,11+j*3,z),(12-j*2,8,12-j*2),
                  (57+j*15,151+j*12,101),shape="Ball",solid=False,material="Grass")
    elif kind in ("Rock","Ore","Crystal"):
        palette={"Rock":(130,143,147),"Ore":(114,166,185),"Crystal":(151,114,232)}
        block(node,"Interact",(x,4,z),(7,6,6),palette[kind],
              shape="Ball",material="Neon" if kind=="Crystal" else "Slate")
        if kind!="Rock":
            for j in (-1,1):
                block(node,"Shard",(x+j*2,6.3,z+2),(2,5,2),
                      (194,218,224) if kind=="Ore" else (183,153,250),
                      solid=False,material="Neon")
    elif kind=="Wild":
        block(node,"Interact",(x,4,z),(6,4,5),(217,129,116),shape="Ball")
        block(node,"Head",(x,5.2,z-3),(4,3.5,4),(224,153,126),shape="Ball",solid=False)
        for dx in (-2,2):
            block(node,"Ear",(x+dx,7,z-3),(1.4,4,1.4),(206,126,121),
                  shape="Ball",solid=False)
    else:
        rgb={"Bush":(91,180,113),"Fiber":(197,196,109)}
        block(node,"Interact",(x,2.8,z),(6,4.5,6),rgb[kind],shape="Ball")
        for dx in (-2,2):
            block(node,"Fruit",(x+dx,5,z-1),(1.5,1.5,1.5),
                  (239,135,137) if kind=="Bush" else (236,210,123),
                  shape="Ball",solid=False)

ufo=group(world,"UFO")
block(ufo,"Saucer",(0,30,155),(22,4,22),(121,198,210),
      shape="Cylinder",solid=False,material="Metal")
block(ufo,"Dome",(0,34,155),(12,8,12),(175,153,228),
      shape="Ball",solid=False,material="Neon")
for i in range(8):
    a=math.tau*i/8
    block(ufo,"UfoLight",(math.cos(a)*9,30,155+math.sin(a)*9),
          (2.3,1.6,2.3),(255,203,117),shape="Ball",solid=False,material="Neon")
block(world,"NorthBeacon",(0,11,296),(8,20,8),(99,221,204),
      shape="Cylinder",solid=False,material="Neon")

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
for i in range(29):
    x=rng.uniform(-290,-175)
    z=rng.uniform(175,298)
    h=rng.uniform(4,10)
    block(mushrooms,"MushroomStem",(x,h/2+1,z),(1.9,h,1.9),
          (225,214,192),material="SmoothPlastic")
    cap_color=rng.choice([(210,131,199),(119,178,228),(239,166,152),(196,164,234)])
    block(mushrooms,"Glowcap",(x,h+1,z),(rng.uniform(5,9),3.7,7),cap_color,
          shape="Ball",solid=False,material="Neon")
    for j in range(3):
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
for i in range(55):
    x=rng.uniform(-306,306)
    z=rng.uniform(-302,295)
    if abs(x)<55 and abs(z)<42: continue
    size=rng.uniform(1.1,2.1)
    block(scenery,"WildflowerStem",(x,1.8,z),(.22,2,.22),
          (73,155,101),solid=False,material="Grass")
    block(scenery,"Wildflower",(x,2.9,z),(size,size/1.8,size),
          rng.choice([(246,189,163),(245,210,124),(168,169,235),(195,220,181)]),
          shape="Ball",solid=False)
for i in range(20):
    a=math.tau*i/20
    d=285+rng.uniform(-10,20)
    x=math.cos(a)*d
    z=math.sin(a)*d
    block(scenery,"OuterStone",(x,2.5,z),(rng.uniform(5,11),rng.uniform(5,10),rng.uniform(6,13)),
          (110,145,131),shape="Ball",material="Slate")

OUT.parent.mkdir(parents=True,exist_ok=True)
ET.indent(document,space="  ")
ET.ElementTree(document).write(OUT,encoding="utf-8",xml_declaration=True)
print(f"Generated {OUT.relative_to(ROOT)}: {count} anchored 3D parts, 12 ranch plots, 70 resource nodes")
