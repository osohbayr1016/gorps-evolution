#!/usr/bin/env python3
"""Validate ranch composition contracts in source and packaged Roblox XML.

This proves that the path-facing facade, separated crop/worker zones, visible
upgrade tiers and quiet authored plot reserves are shipped. It cannot prove
Roblox physics, visual quality, player comprehension or device performance.
"""
from __future__ import annotations

from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def property_value(item, name, default=None):
    props = item.find("Properties")
    entries = props if props is not None else []
    return next(
        (entry.text for entry in entries if entry.get("name") == name),
        default,
    )


def direct_children(item):
    return [child for child in item if child.tag == "Item"]


def position(item):
    props = item.find("Properties")
    assert props is not None
    frame = next(entry for entry in props if entry.get("name") == "CFrame")
    return float(frame.find("X").text), float(frame.find("Z").text)


def packaged_world_source(root):
    matches = [
        item
        for item in root.iter("Item")
        if item.get("class") == "ModuleScript"
        and property_value(item, "Name") == "World"
    ]
    assert len(matches) == 1, ("packaged place", "expected one World module", len(matches))
    source = property_value(matches[0], "Source", "") or ""
    assert len(source) > 1000, ("packaged place", "World source missing")
    return source


def validate_runtime(source, label):
    required = {
        'local function decor(': "non-colliding decoration helper",
        'p.CanCollide=false;p.CanTouch=false;p.CanQuery=false': "decoration collision contract",
        'part(base,"FenceRailFront"': "split path-facing fence rails",
        'part(base,"GatePost"': "wide arrival gate",
        'part(base,"RoofPanel"': "pitched homestead roof",
        'part(base,"FrontPorch"': "path-facing porch",
        'local front=assignedSpot.front': "row-aware arrival orientation",
        'part(base,"Door",Vector3.new(4,6,0.45),CFrame.new(pos.X,4.1,pos.Z-front*3.8)': "path-facing door",
        'part(base,"CropBed_"..i': "named crop rows",
        'decor(base,"IrrigationChannel"': "readable farm zone",
        'local wx=pos.X+6+((workerOffset-1)%3)*5': "east-side worker yard",
        'assigned[player]={index=index,pos=spots[index],front=index<=6 and 1 or -1}': "opposed ranch rows",
        'slot.pos+Vector3.new(0,6,slot.front*15)': "path-side spawn",
        'math.min(worker.count,5)': "worker visual cap",
        'if level>=2 then': "level-two storage upgrade",
        'if level>=4 then': "level-four greenhouse upgrade",
        'local greenhouseX=pos.X-houseWidth/2-6': "greenhouse clears expanded house",
        'if level>=6 then': "level-six beacon upgrade",
    }
    for token, purpose in required.items():
        assert token in source, (label, "missing", purpose, token)

    forbidden = {
        'pos.Z-16.2': "door faces away from ranch path",
        'pos.X-half+6+(workerOffset%6)*5': "workers overlap west crop beds",
        'part(base,"Roof",Vector3.new(18+profile.BaseLevel*2,2,15)': "flat slab roof",
    }
    for token, defect in forbidden.items():
        assert token not in source, (label, defect, token)


def validate_plot_reserves(root, label):
    plots = [
        item
        for item in root.iter("Item")
        if item.get("class") == "Model"
        and (property_value(item, "Name", "") or "").startswith("RanchPlot_")
    ]
    assert len(plots) == 12, (label, "expected 12 ranch reserves", len(plots))
    for plot in plots:
        plot_name = property_value(plot, "Name", "")
        children = direct_children(plot)
        names = [property_value(child, "Name", "") for child in children]
        assert names.count("Land") == 1, (label, "missing plot land")
        assert names.count("HomesteadPad") == 1, (label, "missing homestead pad")
        assert names.count("ArrivalPath") == 1, (label, "missing arrival path")
        assert names.count("PlotCorner") == 4, (label, "plot corner drift", names)
        assert "FencePost" not in names, (label, "authored fence duplicates runtime fence")
        assert "Foundation" not in names, (label, "legacy foundation intersects runtime house")
        index = int(plot_name.rsplit("_", 1)[1])
        front = 1 if index <= 6 else -1
        by_name = {property_value(child, "Name", ""): child for child in children}
        _, center_z = position(by_name["Land"])
        _, pad_z = position(by_name["HomesteadPad"])
        _, arrival_z = position(by_name["ArrivalPath"])
        assert abs(pad_z - (center_z - front * 10)) < 0.01, (
            label, plot_name, "homestead does not face center path"
        )
        assert abs(arrival_z - (center_z + front * 30)) < 0.01, (
            label, plot_name, "arrival path does not face center path"
        )


source_path, authored_path, packaged_path = map(Path, sys.argv[1:])
source = source_path.read_text(encoding="utf-8")
authored = ET.parse(authored_path).getroot()
packaged = ET.parse(packaged_path).getroot()

validate_runtime(source, "source World.lua")
validate_runtime(packaged_world_source(packaged), "packaged World module")
validate_plot_reserves(authored, "source world")
validate_plot_reserves(packaged, "packaged place")
print(
    "PASS ranch art: path-facing homestead, separated farm/worker zones, "
    "three visible upgrade tiers and 12 non-duplicated plot reserves"
)
