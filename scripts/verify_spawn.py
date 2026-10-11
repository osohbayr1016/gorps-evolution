"""Regression test: Rojo must bake a collidable ground and neutral spawn into the place."""
import json
import sys
import xml.etree.ElementTree as ET

project_file, place_file = sys.argv[1:]
project = json.load(open(project_file, encoding="utf-8"))
world = project["tree"]["Workspace"]

def check_config(name, kind):
    item = world[name]
    props = item["$properties"]
    assert item["$className"] == kind, f"{name}: wrong Roblox class"
    assert props["Anchored"] is True and props["CanCollide"] is True, f"{name}: collision disabled"
    return props

ground = check_config("Baseplate", "Part")
spawn = check_config("SafetySpawn", "SpawnLocation")
assert ground["Size"][0] >= 650 and ground["Size"][2] >= 650, "Baseplate is too small"
assert spawn["Neutral"] and spawn["Enabled"], "No usable neutral player spawn"
assert spawn["Position"][1] > ground["Position"][1] + ground["Size"][1] / 2, "Spawn is below ground"
root = ET.parse(place_file).getroot()

def get_item(name, class_name):
    for item in root.iter("Item"):
        if item.get("class") != class_name:
            continue
        properties = item.find("Properties")
        if properties is None:
            continue
        for prop in properties:
            if prop.get("name") == "Name" and prop.text == name:
                return properties
    raise AssertionError(f"{name} ({class_name}) missing from built .rbxlx")

for name, class_name in (("Baseplate", "Part"), ("SafetySpawn", "SpawnLocation")):
    properties = get_item(name, class_name)
    for property_name in ("Anchored", "CanCollide"):
        value = next((p.text for p in properties if p.get("name") == property_name), None)
        assert value == "true", f"{name}.{property_name} is not true in built place"

print("PASS: packaged place contains permanent collidable baseplate and safe SpawnLocation")
