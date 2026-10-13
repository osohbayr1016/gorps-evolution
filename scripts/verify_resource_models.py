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

def value(item, prop_name, default=None):
  props=item.find("Properties")
  return next((p.text for p in props or [] if p.get("name")==prop_name),default)

def vector(item, prop_name):
  props=item.find("Properties")
  entry=next((p for p in props or [] if p.get("name")==prop_name),None)
  assert entry is not None,(value(item,"Name"),"missing",prop_name)
  return tuple(float(entry.find(axis).text) for axis in "XYZ")

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
    effects=[item.get("class") for child in children for item in child.iter("Item")
             if item.get("class") in {"PointLight","ParticleEmitter","Beam","Trail"}]
    assert not effects,(path,model_name,"resource gained unbounded visual effects",effects)
    if prefix=="Crystal":
      tips=[child for child in children if value(child,"Name")=="CrystalTip"]
      materials=Counter(value(tip,"Material") for tip in tips)
      assert len(tips)==5,(path,model_name,"crystal tip count drifted",len(tips))
      assert materials==Counter({"1568":4,"288":1}),(
        path,model_name,"crystal needs one static Neon crown and four Glass tips",materials)
      neon_tip=next(tip for tip in tips if value(tip,"Material")=="288")
      assert value(neon_tip,"CanCollide")=="false",(
        path,model_name,"rare-resource cue must not affect collision")
      interact=next(child for child in children if value(child,"Name")=="Interact")
      anchors=[item for item in interact if item.tag=="Item"
               and item.get("class")=="Attachment"
               and value(item,"Name")=="PromptAnchor"]
      assert len(anchors)==1,(path,model_name,"needs one authored prompt anchor",len(anchors))
      assert vector(anchors[0],"Position")== (0.0,4.7,0.0),(
        path,model_name,"prompt anchor drifted",vector(anchors[0],"Position"))
      assert not any(item.get("class")=="ProximityPrompt" for item in interact.iter("Item")),(
        path,model_name,"runtime prompt must not be duplicated in authored asset")
    else:
      assert not any(item.get("class")=="Attachment" for child in children
                     for item in child.iter("Item")),(
        path,model_name,"common resource unexpectedly gained prompt anchor")
  counts=Counter(key.split("_",1)[0] for key in models)
  assert counts==expected,(path,"resource counts drifted",counts,expected)
  print("PASS",path,"70 modeled harvestables",dict(counts))

source=sys.argv[1]
build=sys.argv[2]
expected=Counter({"Tree":18,"Rock":9,"Ore":9,"Bush":9,"Crystal":9,"Fiber":8,"Wild":8})
verify(source,expected)
verify(build,expected)
