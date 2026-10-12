#!/usr/bin/env python3
"""Check restrained world lighting is authored AND actually packaged by Rojo."""
import json
import sys
import xml.etree.ElementTree as ET

project_path, place_path = sys.argv[1:]
lighting = json.load(open(project_path, encoding="utf-8"))["tree"]["Lighting"]
assert 1.5 <= lighting["$properties"]["Brightness"] <= 2.5
expected = {
    "VerdantAtmosphere": "Atmosphere",
    "VerdantBloom": "BloomEffect",
    "VerdantColorGrade": "ColorCorrectionEffect",
    "VerdantSunRays": "SunRaysEffect",
}
for name, cls in expected.items():
    assert lighting[name]["$className"] == cls, (name, "missing source lighting")
bloom = lighting["VerdantBloom"]["$properties"]
assert 0 < bloom["Intensity"] <= 0.25 and bloom["Threshold"] >= 1.4
atmosphere = lighting["VerdantAtmosphere"]["$properties"]
assert 0 < atmosphere["Density"] <= 0.27
assert lighting["VerdantSunRays"]["$properties"]["Intensity"] <= 0.04
root = ET.parse(place_path).getroot()
found = {}
for item in root.iter("Item"):
    props = item.find("Properties")
    name = next((p.text for p in props if p.get("name") == "Name"), "") if props is not None else ""
    if name in expected:
        found[name] = item.get("class")
assert found == expected, ("lighting missing from Rojo package", found)
print("PASS: packaged Atmosphere, restrained Bloom, color grade, sun rays")
