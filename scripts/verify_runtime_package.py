"""Check that Rojo's packaged place really contains executable game scripts.

A build can succeed while the game is an empty baseplate if source paths are not mapped
into Roblox services.  Parse the generated XML, not just the project JSON.
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

root=ET.parse(Path(sys.argv[1])).getroot()
found={}
def name_of(item):
 props=item.find("Properties")
 if props is None:
  return "<unnamed>"
 for element in props:
  if element.attrib.get("name")=="Name":
   return element.text or ""
 return "<unnamed>"
def check(item,prefix=""):
 if item.tag!="Item":
  for child in item:
   check(child,prefix)
  return
 name=name_of(item)
 path=f"{prefix}/{name}" if prefix else name
 kind=item.attrib.get("class")
 found[path]=(kind,item)
 for child in item:
  if child.tag=="Item":
   check(child,path)
check(root)
required={
 "ServerScriptService/GorpsServer/Main":"Script",
 "ServerScriptService/GorpsServer/WorldBootstrap":"Script",
 "ServerScriptService/GorpsServer/SpawnSafety":"Script",
 "ReplicatedStorage/Shared/Config":"ModuleScript",
 "ReplicatedStorage/Shared/Onboarding":"ModuleScript",
 "ReplicatedStorage/Shared/CreatureFactory":"ModuleScript",
 "ReplicatedStorage/Shared/CreaturePose":"ModuleScript",
 "StarterPlayer/StarterPlayerScripts/GorpsClient/Companions":"LocalScript",
 "ReplicatedStorage/Shared/Rules":"ModuleScript",
 "ReplicatedStorage/Shared/Economy":"ModuleScript",
 "StarterPlayer/StarterPlayerScripts/GorpsClient/Icons":"ModuleScript",
 "StarterPlayer/StarterPlayerScripts/GorpsClient/Widgets":"ModuleScript",
 "StarterPlayer/StarterPlayerScripts/GorpsClient/Ui":"ModuleScript",
 "StarterPlayer/StarterPlayerScripts/GorpsClient/Main":"LocalScript",
 "StarterPlayer/StarterPlayerScripts/GorpsClient/Status":"LocalScript",
}
for path,kind in required.items():
 if path not in found:
  print("PACKAGED PATHS:",sorted(k for k in found if any(t in k for t in ("Gorps","Shared","ServerScriptService","StarterPlayer"))))
  raise AssertionError(f"Missing {kind}: {path}")
 actual,item=found[path]
 assert actual==kind, f"{path}: expected {kind}, found {actual}"
 props=item.find("Properties")
 sources=[p for p in props if p.attrib.get("name")=="Source"] if props is not None else []
 assert sources and sources[0].text and len(sources[0].text)>75, f"Empty code: {path}"
 for p in props:
  if p.attrib.get("name")=="Disabled":
   assert p.text!="true", f"Script disabled: {path}"
  if p.attrib.get("name")=="Enabled":
   assert p.text!="false",f"Script not enabled: {path}"
 print(f"PASS: packaged {kind} {path} ({len(sources[0].text)} source chars)")
assert found["ServerStorage/CreatureRigs"][0]=="Folder", "missing editable rig shelf"
for species in ("Gorp","Shade","Boulder","Bloom","Carrier","Mole","Dart"):
 prefix="ServerStorage/CreatureRigs/"+species
 assert found[prefix][0]=="Model", "missing editable species rig: "+species
 motors=[kind for path,(kind,_) in found.items() if path.startswith(prefix+"/") and kind=="Motor6D"]
 assert len(motors)>=6, "missing packaged creature joints: "+species
 assert found[prefix+"/AnimationController"][0]=="AnimationController", "missing authoring controller"
 print("PASS: packaged editable rig",species,"with",len(motors),"joints")
print("PASS: all critical scripts and original editable creature rigs are packaged (not Studio execution)")

