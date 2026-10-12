-- Pure deterministic, bounded plan for real Roblox smooth Terrain, not Part impostors.
-- This is a deliberate *border* art pass: ranch, village and teaching paths stay
-- on their validated authored ground. No random server-specific map generation.
local Plan={}
Plan.VERSION="VerdantVoxelRelief_01"
Plan.MAX_WRITES=48

-- Cliff shoulders are near the outer map edge so the spawn vista has depth.
-- A site's actual footprint is checked against reserved routes and live world
-- resource/tree locations before any terrain voxel is written.
Plan.sites={
 {name="WestGate",x=-311,z=-16,radius=27},
 {name="EastGate",x=330,z=-16,radius=27},
 {name="WestForest",x=-315,z=85,radius=25},
 {name="EastQuarry",x=315,z=85,radius=25},
 {name="WestGrove",x=-314,z=163,radius=27},
 {name="EastRidge",x=314,z=163,radius=27},
 {name="WestPine",x=-313,z=251,radius=27},
 {name="EastPine",x=313,z=251,radius=27},
 {name="FarWest",x=-275,z=320,radius=25},
 {name="FarEast",x=275,z=320,radius=25},
 {name="Northwest",x=-225,z=326,radius=26},
 {name="Northeast",x=225,z=326,radius=26},
 {name="NorthPines",x=-165,z=329,radius=26},
 {name="NorthQuarry",x=165,z=329,radius=26},
 {name="WestHorizon",x=-93,z=337,radius=27},
 {name="EastHorizon",x=93,z=337,radius=27},
}

local protectedRects={
 {x=0,z=-164,halfX=277,halfZ=90},   -- 12 ranch plots + level-6 fences
 {x=0,z=0,halfX=84,halfZ=61},      -- spawn plaza, station prompts
 {x=0,z=174,halfX=22,halfZ=139},  -- north teaching trail and beacon
 {x=-125,z=135,halfX=16,halfZ=98}, -- west forest branch
 {x=133,z=135,halfX=16,halfZ=98},  -- east quarry branch
}
local protectedCircles={
 {x=-215,z=45,radius=75}, -- lagoon and bridge
 {x=222,z=20,radius=76},  -- quarry entrance
}
local function distanceSquared(x1,z1,x2,z2)
 local dx=x1-x2
 local dz=z1-z2
 return dx*dx+dz*dz
end
function Plan.isClear(site,obstacles)
 if type(site)~="table" or type(site.x)~="number" or type(site.z)~="number"
  or type(site.radius)~="number" or site.radius<12 or site.radius>32 then
  return false
 end
 local buffer=6
 for _,rect in ipairs(protectedRects) do
  local dx=math.max(math.abs(site.x-rect.x)-rect.halfX,0)
  local dz=math.max(math.abs(site.z-rect.z)-rect.halfZ,0)
  if dx*dx+dz*dz<(site.radius+buffer)^2 then return false end
 end
 for _,circle in ipairs(protectedCircles) do
  if distanceSquared(site.x,site.z,circle.x,circle.z)<
   (site.radius+circle.radius+buffer)^2 then return false end
 end
 for _,obstacle in ipairs(obstacles or {}) do
  if type(obstacle.x)=="number" and type(obstacle.z)=="number" then
   local radius=obstacle.radius or 0
   if distanceSquared(site.x,site.z,obstacle.x,obstacle.z)<
    (site.radius+radius+buffer)^2 then return false end
  end
 end
 return true
end

-- Two nested fills form a slate foot and a soft grassy crest with a real
-- voxel slope. Both occupy the same guarded horizontal footprint.
function Plan.build(obstacles)
 local operations={}
 local accepted=0
 for _,site in ipairs(Plan.sites) do
  if Plan.isClear(site,obstacles) then
   local radius=site.radius
   accepted+=1
   table.insert(operations,{
    name=site.name.."_Rock",x=site.x,y=10-radius,z=site.z,
    radius=radius,material="Rock",
   })
   local grassRadius=radius*0.78
   table.insert(operations,{
    name=site.name.."_Grass",x=site.x,y=11-grassRadius,z=site.z,
    radius=grassRadius,material="Grass",
   })
  end
 end
 assert(#operations<=Plan.MAX_WRITES,"Terrain write budget exceeded")
 return operations,accepted
end
return Plan
