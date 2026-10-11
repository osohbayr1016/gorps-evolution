#!/usr/bin/env python3
"""Validate *rendered-in-place* Roblox resource models in both rbxmx and rbxlx.

CI must reject returning to seven colored spheres or deleting harvest prompts.
This is a static asset verification, not an actual Roblox engine render test.
"""
import sys
import xml.etree.ElementTree as ET
from collections import Counter

REQUIREMENTS={
 "Tree":{"Interact","Root","Branch","Crown"},
 "Rock":{"Interact","RockFacet","Pebble"},
 "Ore":{"Interact","StoneLayer","IronVein"},
 "Crystal":{"Interact","CrystalSpire","CrystalTip"},
 "Bush":{"Interact","Foliage","Berry"},
 "Fiber":{"Interact","ReedBlade","SeedHead"},
 "Wild":{"Interact","Neck","Snout","Eye","Leg","Hoof"}
}

def find_models(root):
  result={}
  def name(item):
    props=item.find("Properties")
    return next((p.text for p in props or [] if p.get("name")=="Name"),"")
  for model in root.iter("Item"):
    if model.get("class")!="Model":
      continue
    n=name(model)
    if "_" not in n:
      continue
    prefix,_=n.split("_",1)
    if prefix not in REQUIREMENTS:
      continue
    children=[c for c in model if c.tag=="Item"]
    kinds=Counter(name(x) for x in children)
    result[n]=(kinds,children)
  return result

def verify(path,expected):
  models=find_models(ET.parse(path).getroot())
  assert len(models)==70,(path,"expected 70 harvestable models",len(models))
  for model_name,(names,children) in models.items():
    prefix=model_name.split("_",1)[0]
    missing=REQUIREMENTS[prefix]-names.keys()
    assert not missing,(path,model_name,"missing modeled parts",sorted(missing))
    assert len(children)>=5,(path,model_name,"still a placeholder ball")
    if prefix in {"Rock","Ore","Crystal","Fiber","Wild"}:
      assert any(c.get("class")=="WedgePart" for c in children), (
        path,model_name,"missing intentional 3D angular shape")
    for child in children:
      if child.get("class") not in ("Part","WedgePart"):
        raise AssertionError((path,model_name,"unexpected asset type"))
  counts=Counter(key.split("_",1)[0] for key in models)
  assert counts==expected,(path,"resource counts drifted",counts,expected)
  print("PASS",path,"70 modeled harvestables",dict(counts))

source=sys.argv[1]
build=sys.argv[2]
expected=Counter({"Tree":18,"Rock":9,"Ore":9,"Bush":9,"Crystal":9,"Fiber":8,"Wild":8})
verify(source,expected)
verify(build,expected)
