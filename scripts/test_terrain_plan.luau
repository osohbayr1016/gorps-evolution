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
local ops,sites,inland=Plan.build({})
expect(sites>=20,"frontier and meadow transitions both get modeled")
expect(sites<=#Plan.sites+Plan.MAX_INLAND_SITES,"bounded site count")
expect(inland>=8,"free interior biome shoulders produce visible ridges")
expect(inland<=Plan.MAX_INLAND_SITES,"inland site limit")
expect(#ops==#Plan.sites*2+inland*3,"outer paired and inner triple-lobed real voxel fills")
expect(#ops<=Plan.MAX_WRITES,"fixed maximum work per server start")
expect(Plan.VERSION=="VerdantVoxelRelief_06","new art version invalidates old bake tag")
local ids={}
for i,site in ipairs(Plan.sites) do
 expect(Plan.isClear(site,{}),"site "..i.." avoids reserved route and ranch footprints")
 expect(not ids[site.name],"unique site ID")
 ids[site.name]=true
end
for index,entry in ipairs(ops) do
 expect(entry.material=="Grass" or entry.material=="Rock" or entry.material=="Ground","supported voxel terrain material")
 expect(entry.radius>=6 and entry.radius<=32,"safe terrain sphere bounds")
 expect(entry.y+entry.radius<=12,"terrain elevations capped outside gameplay")
 expect(type(entry.x)=="number" and type(entry.z)=="number","stable numeric site")
 if index<=#Plan.sites*2 and index%2==0 then
  local rock=ops[index-1]
  expect(rock.material=="Rock" and entry.material=="Grass","slate before soft grass cap")
  expect(rock.x==entry.x and rock.z==entry.z,"paired voxel fills share site")
 end
 if index>#Plan.sites*2 and (index-#Plan.sites*2)%3==0 then
  local rock=ops[index-2]
  local hill=ops[index-1]
  expect(rock.material=="Rock" and hill.material~="Rock","organic terrain starts at rock")
  expect(rock.x==hill.x and rock.z==hill.z,"grass rises from rock core")
  expect(math.abs(entry.x-rock.x)<=7 and math.abs(entry.z-rock.z)<=2,
   "inner crest fits inside cleared site footprint")
 end
end
local first=Plan.sites[1]
expect(not Plan.isClear(first,{{x=first.x,z=first.z,radius=16}}),"harvest point blocks terrain")
local blockedOps,blockedSites=Plan.build({{x=first.x,z=first.z,radius=16}})
expect(blockedSites==sites-1,"one dynamic harvest obstacle skips exactly one mound")
expect(#blockedOps==#ops-2,"blocked outer mound writes do not occur")
local inner=Plan.inlandCandidates[1]
expect(Plan.isClear(inner,{}),"first central transition site clears static routes")
local innerOps,innerTotal,innerCount=Plan.build({{x=inner.x,z=inner.z,radius=16}})
local blockedName=inner.name.."_Foundation"
local wasPresent=false
for _,entry in ipairs(innerOps) do
 if entry.name==blockedName then wasPresent=true end
end
expect(not wasPresent,"dynamic resource at inland transition prevents terrain writes")
expect(innerTotal<=#Plan.sites+Plan.MAX_INLAND_SITES,"dynamic obstruction keeps total bound")
expect(innerCount<=Plan.MAX_INLAND_SITES,"dynamic obstruction keeps inland bound")
local inlandSites={}
for _,entry in ipairs(ops) do
 if string.find(entry.name,"_Foundation",1,true) then
  local name=string.gsub(entry.name,"_Foundation","")
  inlandSites[name]=true
 end
end
for _,site in ipairs(Plan.inlandCandidates) do
 if inlandSites[site.name] then
  expect(Plan.isClear(site,{}),"chosen inland site stays outside every protected route")
 end
end
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
expect(not Plan.isClear({x=280,z=280,radius=12,buffer=0},{}),"invalid clearance buffer rejected")
print("PASS:",checks,"terrain plan assertions; Roblox Terrain engine needs Studio QA")
