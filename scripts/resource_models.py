"""Original resource set for Planet Verdant.

All seven resources are multi-part, named Roblox Models with visible silhouettes,
not unidentifiable floating neon balls. Generated into an .rbxmx so Rojo displays
them in Studio Edit mode without asset IDs or external marketplace dependencies.

For production mesh/PBR versions replace each Model in Studio with a privately
owned MeshPart asset. Keep the "Interact" BasePart name for the harvesting engine.
"""
from __future__ import annotations
import math


def build_resource(node, kind, x, z, block, attachment, rng):
    def part(name, dx, y, dz, size, color, shape="Block", material="SmoothPlastic",
             solid=False, pitch=0, yaw=0, roll=0, kind_of="Part"):
        return block(node, name, (x+dx,y,z+dz), size, color, shape=shape,
                     solid=solid, material=material, rotation=(pitch,yaw,roll),
                     part_class=kind_of)

    if kind == "Tree":
        part("Interact", 0, 6.4, 0, (3.5, 10.8, 3.4), (117,79,53),
             material="Wood", solid=True)
        for i, (dx,dz,angle) in enumerate(((2.1,1.2,34),(-2.4,-.8,-28),(0,2.4,16))):
            part("Root",dx,1.6,dz,(2.1,2.8,3.9),(112,78,55),
                 material="Wood",roll=angle)
        for dx,y,dz,roll in ((-3.2,10,-.3,-42),(3.1,12,1.4,38),(0,11,3,21)):
            part("Branch",dx,y,dz,(1.7,6.7,1.7),(111,73,51),material="Wood",roll=roll)
        foliage=[(0,14.8,0,9,6.2,8),(3.5,13.8,1,7,5.5,6),(-3.5,13.8,-1,7,5.5,6),
                 (-1.3,17.7,.8,7.8,5.6,7.3),(2.6,17,1.2,6.6,5,6.4)]
        for i,(dx,y,dz,sx,sy,sz) in enumerate(foliage):
            part("Crown",dx,y,dz,(sx,sy,sz),
                 [(64,125,77),(83,142,83),(94,153,89),(71,131,80)][i%4],
                 shape="Ball",material="Grass")
        for dx,dz in ((-2,-1),(2,1),(0,-2)):
            part("LeafAccent",dx,19,dz,(1.5,.55,1.4),(146,187,104),
                 shape="Ball",material="Grass")

    elif kind == "Rock":
        part("Interact",0,2.45,0,(6.2,4.1,5.8),(111,124,128),
             material="Slate",solid=True,kind_of="WedgePart",yaw=18)
        part("RockFacet",1.9,2.9,1.1,(3.5,3.8,4.9),(138,149,148),
             material="Slate",kind_of="WedgePart",yaw=135)
        part("RockFacet",-1.9,1.8,-1.6,(4.1,2.8,3.1),(87,112,111),
             material="Slate",kind_of="WedgePart",yaw=245)
        for dx,dz in ((-2.7,2.6),(3,-1.8)):
            part("Pebble",dx,1.45,dz,(2.4,1.5,2.2),(124,139,137),
                 material="Slate",kind_of="WedgePart",yaw=70)

    elif kind == "Ore":
        part("Interact",0,2.6,0,(7.1,4.3,5.6),(93,111,125),
             material="Slate",solid=True,kind_of="WedgePart",yaw=22)
        part("StoneLayer",2,2.5,1,(4.2,4.3,4.8),(107,127,137),
             material="Slate",kind_of="WedgePart",yaw=160)
        for dx,y,dz,sx,sy,sz,angle in (
            (-2.2,4.4,-1.7,1.6,3.8,1.8,-15),
            (.3,5,-.8,1.7,3.6,1.4,20),
            (2.1,3.8,-1.6,1.4,2.9,1.6,32),
            (1,3.5,2.3,1.1,3.3,1.1,12)):
            part("IronVein",dx,y,dz,(sx,sy,sz),(179,180,171),
                 material="Metal",kind_of="WedgePart",roll=angle)
        part("IronSpot",-.8,2.1,-3,(1.2,.7,.3),(218,161,101),
             material="Metal")

    elif kind == "Crystal":
        interact = part("Interact",0,1.8,0,(7,3.4,6.4),(101,112,131),
                        material="Slate",solid=True,kind_of="WedgePart",yaw=30)
        # Keep the authoritative harvest root/security distance unchanged, but
        # project the cross-input prompt beside the readable crystal body
        # instead of from inside its low slate base. Attachment adds no render,
        # collision, light, particle, animation or per-frame cost.
        attachment(interact,"PromptAnchor",(0,4.7,0))
        crystal_colors=[(137,117,205),(98,169,215),(161,137,218),(113,184,187)]
        for i,(dx,dz,height,angle) in enumerate((
           (0,0,8,0),(-2,1,5.7,-19),(2.2,.8,6.1,20),(-.8,-2,4,-12),(2.9,-1.4,3.8,27))):
            part("CrystalSpire",dx,2.8+height/2,dz,(1.8,height,1.9),
                 crystal_colors[i%len(crystal_colors)],material="Glass",
                 kind_of="WedgePart",roll=angle)
            # One static emissive crown makes the highest-value harvest node
            # distinguishable without a PointLight, transparent particle
            # stack, animation loop, or reduced-motion exception. The four
            # smaller tips remain Glass so the full cluster does not bloom.
            tip_material = "Neon" if i == 0 else "Glass"
            tip_color = (210,221,255) if i == 0 else (183,194,239)
            part("CrystalTip",dx+math.sin(math.radians(angle))*.6,
                 3+height,dz,(1.1,1.6,1.1),tip_color,
                 material=tip_material,kind_of="WedgePart",roll=angle)
        for dx,dz in ((-2.8,-2.2),(3.1,2.2)):
            part("StoneBase",dx,1.3,dz,(2.3,1.7,2.6),(105,115,134),
                 material="Slate",kind_of="WedgePart",yaw=65)

    elif kind == "Bush":
        part("Interact",0,1.7,0,(4.5,2.6,4.5),(74,122,65),
             material="Grass",solid=False,shape="Ball")
        for i,(dx,y,dz,size) in enumerate((
            (-1.5,3,-.2,3.9),(1.5,2.9,.2,3.7),(-.1,3.8,1.1,3.7),
            (.3,2.6,-1.8,3.2),(1,4.3,-.6,2.7))):
            part("Foliage",dx,y,dz,(size,size*.82,size),
                 [(78,145,78),(63,132,74),(100,157,78)][i%3],
                 shape="Ball",material="Grass")
        for dx,y,dz in ((-2.2,3,-1),(1.5,3,-2.2),(1.2,4.2,.4),(-1,4.3,1.6),
                        (0,2.6,-2.5),(-2,3.8,.2)):
            part("Berry",dx,y,dz,(.85,.9,.85),(203,77,89),
                 shape="Ball",material="SmoothPlastic")
        part("Twig",0,1.1,0,(.65,2.1,.8),(107,77,56),material="Wood")

    elif kind == "Fiber":
        part("Interact",0,1.2,0,(3.1,1.6,3.4),(93,129,76),
             material="Grass",solid=False)
        for i in range(11):
            a=(i/11)*2*math.pi
            dist=1.5 if i%2==0 else .7
            blade_height=4.5+(i%4)*1.2
            part("ReedBlade",math.cos(a)*dist,1.2+blade_height/2,
                 math.sin(a)*dist,(.38,blade_height,.7),
                 [(112,153,81),(165,168,90),(140,181,103)][i%3],
                 material="Grass",kind_of="WedgePart",
                 pitch=math.cos(a)*15,roll=math.sin(a)*15)
        for dx,dz in ((-1.2,1.2),(1.3,-.5)):
            part("SeedHead",dx,5.7,dz,(.65,1.7,.7),(190,165,102),
                 shape="Ball",material="Grass")

    elif kind == "Wild":
        # Boar-like creature: a collectible hunter's target, never a floating sphere.
        part("Interact",0,3.25,0,(6.1,3.9,8.2),(156,112,83),
             material="SmoothPlastic",solid=True,shape="Ball")
        part("Neck",0,3.4,-3.2,(4.8,3.8,3.8),(166,122,91),
             shape="Ball")
        part("Snout",0,2.9,-5,(3,2.2,2.4),(205,145,123),
             shape="Ball")
        for side in (-1,1):
            part("Eye",side*1.35,4,-4.7,(.45,.45,.45),(32,31,31),shape="Ball")
            part("Tusk",side*1.5,2.6,-5.3,(.6,1.45,.5),(242,225,198),
                 material="SmoothPlastic",kind_of="WedgePart",roll=side*15)
            part("Ear",side*2,5.2,-3.1,(1.5,2.4,.55),(121,77,61),
                 material="SmoothPlastic",kind_of="WedgePart",roll=side*22)
        for dx in (-1.7,1.7):
            for dz in (-2.4,2.8):
                part("Leg",dx,1.55,dz,(1.25,2.7,1.25),(101,73,65),
                     material="SmoothPlastic")
                part("Hoof",dx,.45,dz-.3,(1.5,.9,1.6),(69,62,65),
                     material="Slate")
        part("Tail",0,4.15,4.1,(.65,.7,3),(124,89,68),
             material="SmoothPlastic",roll=18)
