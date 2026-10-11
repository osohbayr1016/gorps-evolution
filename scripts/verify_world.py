#!/usr/bin/env python3
"""Reject blank-map Roblox artifacts. Verify both source and built map XML."""
import sys
import xml.etree.ElementTree as ET
from collections import Counter

source,built=sys.argv[1:]
def collect(path):
 root=ET.parse(path).getroot()
 result=[]
 def visit(obj,parents=()):
  if obj.tag!="Item":
   for item in obj:
    visit(item,parents)
   return
  props=obj.find("Properties")
  n=next((p.text for p in props or [] if p.get("name")=="Name"),"")
  full=parents+(n,)
  result.append((full,obj.get("class"),props))
  for child in obj:
   if child.tag=="Item":
    visit(child,full)
 visit(root)
 return result

src=collect(source)
out=collect(built)
def validate(records,tag):
 parts=[r for r in records if r[1]=="Part"]
 resources=[r for r in records if r[1]=="Model" and
            len(r[0])>=3 and r[0][-2]=="ResourceNodes"]
 plots=[r for r in records if r[1]=="Model" and
        len(r[0])>=3 and r[0][-2]=="RanchPlots"]
 paths=["/".join(r[0]) for r in records]
 assert len(parts)>=350,(tag,"not enough authored 3D parts",len(parts))
 assert len(resources)==70,(tag,"expected exactly 70 resource nodes",len(resources))
 assert len(plots)==12,(tag,"expected exactly 12 player plots",len(plots))
 assert any(p.endswith("/PlanetVerdant/TerrainAndPaths/Ground") or p=="PlanetVerdant/TerrainAndPaths/Ground" for p in paths), (tag,"no authored terrain")
 assert any(p.endswith("/PlanetVerdant/VillageHub/WelcomePlatform") or p=="PlanetVerdant/VillageHub/WelcomePlatform" for p in paths),(tag,"missing gameplay hub")
 assert any("/PlanetVerdant/UFO/" in p or p.startswith("PlanetVerdant/UFO/") for p in paths),(tag,"missing UFO")
 print(f"PASS {tag}: {len(parts)} visible 3D parts, {len(resources)} gathering nodes, {len(plots)} ranch plots")

validate(src,"source world")
validate(out,"packaged Roblox place")
