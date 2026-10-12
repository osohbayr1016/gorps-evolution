-- Test the ACTUAL pure TerrainPlan against 70 generated harvest nodes,
-- 64 authored trees, handcrafted knolls and Glowcap mushroom stems.
-- Unlike the synthetic/empty-plan suite this observes a real map snapshot.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local serde=require("@lune/serde")
local file="src/shared/TerrainPlan.lua"
local Plan=luau.load(fs.readFile(file),{debugName=file})()
local fixture=serde.decode("json",fs.readFile("terrain_obstacles.json"))
local anchors=fixture.obstacles
assert(fixture.counts.resources==70,"resource roots absent")
assert(fixture.counts.trees==64,"tree roots absent")
assert(fixture.counts.knolls>=6,"knoll roots absent")
assert(fixture.counts.mushrooms==16,"glowcap roots absent")
assert(#anchors==fixture.counts.resources+fixture.counts.trees+fixture.counts.knolls+fixture.counts.mushrooms,
 "fixture loses a live collision anchor")
local writes,accepted,inland=Plan.build(anchors)
assert(inland>=6,"actual authored terrain has too few inland contours: "..tostring(inland))
assert(inland<=Plan.MAX_INLAND_SITES,"inland site budget exceeded")
assert(#writes<=Plan.MAX_WRITES,"terrain write budget exceeded")
local west,east=0,0
for _,site in ipairs(Plan.inlandCandidates) do
 local marker=site.name.."_Foundation"
 for _,op in ipairs(writes) do
  if op.name==marker then
   assert(Plan.isClear(site,anchors),"accepted hill intersects a real map anchor: "..site.name)
   if site.x<0 then west+=1 else east+=1 end
   break
  end
 end
end
assert(west>=2 and east>=2,
 "world sculpt ignores one side (west="..tostring(west)..", east="..tostring(east)..")")
local seen={}
for _,op in ipairs(writes) do
 assert(not seen[op.name],"duplicated terrain operation "..op.name)
 seen[op.name]=true
 assert(op.radius>=9 and op.radius<=32,"unsafe radius")
 assert(op.y+op.radius<=12,"terrain encroaches above safe elevations")
end
local again,totalAgain,inlandAgain=Plan.build(anchors)
assert(totalAgain==accepted and inlandAgain==inland and #again==#writes,
 "terrain plan changed with identical source world")
for i,op in ipairs(writes) do
 local b=again[i]
 assert(op.name==b.name and op.x==b.x and op.y==b.y and op.z==b.z
  and op.radius==b.radius and op.material==b.material,
  "terrain writes are nondeterministic")
end
print("PASS: authored-world real obstacle terrain acceptance; inland="..inland
 ..", western="..west..", eastern="..east..", fills="..#writes)
