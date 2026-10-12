-- Runs the REAL pure terrain planner without Roblox Studio.
-- Behavior checks protect the ranch, village, paths and node exclusion ring.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local path="src/shared/TerrainPlan.lua"
local Plan=luau.load(fs.readFile(path),{debugName=path})()
local checks=0
local function expect(condition,message)
 checks+=1
 assert(condition,message)
end
local ops,sites=Plan.build({})
expect(sites>=10,"enough non-overlapping frontier hills exist")
expect(sites<=24,"terrain site budget")
expect(#ops==sites*2,"each landmark uses two authentic voxel fills")
expect(#ops<=Plan.MAX_WRITES,"fixed maximum work per server start")
expect(Plan.VERSION=="VerdantVoxelRelief_01","stable baked terrain version")
local ids={}
for i,site in ipairs(Plan.sites) do
 expect(Plan.isClear(site,{}),"site "..i.." avoids reserved route and ranch footprints")
 expect(not ids[site.name],"unique site ID")
 ids[site.name]=true
end
for index,entry in ipairs(ops) do
 expect(entry.material=="Grass" or entry.material=="Rock","supported voxel terrain material")
 expect(entry.radius>=12 and entry.radius<=32,"safe terrain sphere bounds")
 expect(entry.y+entry.radius<=12,"terrain elevations capped outside gameplay")
 expect(type(entry.x)=="number" and type(entry.z)=="number","stable numeric site")
 if index%2==0 then
  local rock=ops[index-1]
  expect(rock.material=="Rock" and entry.material=="Grass","slate before soft grass cap")
  expect(rock.x==entry.x and rock.z==entry.z,"paired voxel fills share site")
 end
end
local first=Plan.sites[1]
expect(not Plan.isClear(first,{{x=first.x,z=first.z,radius=16}}),"harvest point blocks terrain")
local blockedOps,blockedSites=Plan.build({{x=first.x,z=first.z,radius=16}})
expect(blockedSites==sites-1,"one dynamic harvest obstacle skips exactly one mound")
expect(#blockedOps==#ops-2,"blocked mound writes do not occur")
local duplicated=Plan.build({})
for i,entry in ipairs(ops) do
 local same=duplicated[i]
 expect(entry.name==same.name and entry.x==same.x and entry.y==same.y
  and entry.z==same.z and entry.radius==same.radius
  and entry.material==same.material,"identical terrain layout on every run")
end
expect(not Plan.isClear({x=0,z=0,radius=22},{}),"spawn plaza protected")
expect(not Plan.isClear({x=0,z=175,radius=22},{}),"north trail protected")
expect(not Plan.isClear({x=0,z=-170,radius=22},{}),"ranch corridor protected")
expect(not Plan.isClear({x=-215,z=45,radius=22},{}),"lagoon protected")
expect(not Plan.isClear({x=222,z=20,radius=22},{}),"quarry protected")
print("PASS:",checks,"terrain plan assertions; Roblox Terrain engine needs Studio QA")
