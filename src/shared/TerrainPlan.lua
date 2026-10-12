-- Pure deterministic, bounded plan for real Roblox smooth Terrain, not Part impostors.
-- This is a deliberate *border* art pass: ranch, village and teaching paths stay
-- on their validated authored ground. No random server-specific map generation.
local Plan={}
Plan.VERSION="VerdantVoxelRelief_04"
Plan.MAX_WRITES=80
Plan.MAX_INLAND_SITES=12

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

-- Ordered left/right in pairs to sculpt both meadow-to-forest and
-- meadow-to-quarry transitions rather than a handful of distant mountains.
-- The server skips candidates crowded by live resource roots or tree trunks.
-- radius is the entire *horizontal* safety footprint of three blended lobes.
Plan.inlandCandidates={
 {name="WestMeadowShoulder",x=-142,z=-36,radius=19},
 {name="EastMeadowShoulder",x=112,z=-42,radius=19},
 {name="WestForestTerrace",x=-232,z=154,radius=19},
 {name="EastQuarryTerrace",x=230,z=154,radius=19},
 {name="WestGroveRise",x=-185,z=184,radius=19},
 {name="EastStoneRise",x=177,z=184,radius=19},
 {name="WestCanopyHill",x=-213,z=235,radius=19},
 {name="EastCanopyHill",x=219,z=235,radius=19},
 {name="WestHighMeadow",x=-165,z=258,radius=19},
 {name="EastHighMeadow",x=160,z=258,radius=19},
 {name="WestWayfinderHill",x=-90,z=278,radius=19},
 {name="EastWayfinderHill",x=91,z=278,radius=19},
 {name="WestClearing",x=-71,z=214,radius=19},
 {name="EastClearing",x=79,z=214,radius=19},
 {name="WestOuterClearing",x=-260,z=204,radius=19},
 {name="EastOuterClearing",x=264,z=204,radius=19},
 {name="WestNorthClearing",x=-268,z=283,radius=19},
 {name="EastNorthClearing",x=264,z=283,radius=19},
 {name="WestSidePass",x=-266,z=138,radius=19},
 {name="EastSidePass",x=267,z=138,radius=19},
 {name="WestGroveEdge",x=-180,z=284,radius=19},
 {name="EastGroveEdge",x=184,z=284,radius=19},
}

-- Compact fallback hillocks occupy measured open pockets in the generated
-- authored map. Their 12-stud validated footprint and four-stud buffer remain
-- larger than the actual ten-stud rock fill, while avoiding the unrealistic
-- 42-stud exclusion diameter that rejected every inland site in GE-MAP-02d.
-- These coordinates are still checked against live obstacles at runtime.
local fallbackCandidates={
 {name="WestTrailHillock",x=-92,z=76},
 {name="EastTrailHillock",x=100,z=90},
 {name="WestGroveHillock",x=-76,z=150},
 {name="EastRimHillock",x=288,z=116},
 {name="WestForestHillock",x=-180,z=162},
 {name="EastQuarryHillock",x=256,z=136},
 {name="WestCanopyHillock",x=-194,z=226},
 {name="EastHighHillock",x=144,z=286},
 {name="WestPineHillock",x=-160,z=230},
 {name="EastWayfinderHillock",x=70,z=290},
 {name="WestNorthHillock",x=-114,z=294},
 {name="EastNorthHillock",x=250,z=290},
}
for _,site in ipairs(fallbackCandidates) do
 site.radius=12
 site.buffer=4
 table.insert(Plan.inlandCandidates,site)
end

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
 local buffer=site.buffer or 6
 if type(buffer)~="number" or buffer<4 or buffer>6 then return false end
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

local function farFromSites(site,placed)
 for _,other in ipairs(placed) do
  if distanceSquared(site.x,site.z,other.x,other.z)<
   (site.radius+other.radius+4)^2 then return false end
 end
 return true
end

-- Each inland contour consists of THREE connected voxel fills, not three
-- independent perfect round hills. The offset crest sits inside its entire
-- radius-19 validated footprint. West is grassy woodland; east has dry quarry
-- soil. All heights stay <=11 studs above the flat teaching-route ground.
local function inlandContour(site,operations)
 local dry=site.x>0
 local shoulderRadius=math.min(14,site.radius-2)
 local capRadius=shoulderRadius*0.82
 local crestRadius=math.max(6,shoulderRadius-4)
 local offset=math.min(6,site.radius-7)
 local offsetX=site.x<0 and offset or -offset
 table.insert(operations,{
  name=site.name.."_Foundation",x=site.x,y=9-shoulderRadius,z=site.z,
  radius=shoulderRadius,material="Rock",
 })
 table.insert(operations,{
  name=site.name.."_Hillside",x=site.x,y=10-capRadius,z=site.z,
  radius=capRadius,material=dry and "Ground" or "Grass",
 })
 table.insert(operations,{
  name=site.name.."_Crest",x=site.x+offsetX,y=11-crestRadius,z=site.z+2,
  radius=crestRadius,material=dry and "Ground" or "Grass",
 })
end

-- The original outer horizon remains intact. Interior contours are strictly
-- opt-in by geometric clearance and are spread over both biome shoulders.
function Plan.build(obstacles)
 local operations={}
 local accepted=0
 local placed={}
 for _,site in ipairs(Plan.sites) do
  if Plan.isClear(site,obstacles) then
   local radius=site.radius
   accepted+=1
   table.insert(placed,site)
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
 local inland=0
 for _,site in ipairs(Plan.inlandCandidates) do
  if inland>=Plan.MAX_INLAND_SITES then break end
  if Plan.isClear(site,obstacles) and farFromSites(site,placed) then
   inland+=1
   accepted+=1
   table.insert(placed,site)
   inlandContour(site,operations)
  end
 end
 assert(#operations<=Plan.MAX_WRITES,"Terrain write budget exceeded")
 return operations,accepted,inland
end
return Plan
