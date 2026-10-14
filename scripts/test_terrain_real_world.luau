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
assert(fixture.counts.backdrops==4,"boundary backdrops absent")
assert(fixture.counts.escarpments==56,"authored escarpment solids absent")
assert(#fixture.escarpments==14*4,"fixture loses an authored escarpment layer")
assert(#anchors==fixture.counts.resources+fixture.counts.trees+fixture.counts.knolls+fixture.counts.mushrooms,
 "fixture loses a live collision anchor")
local writes,accepted,inland=Plan.build(anchors)
assert(inland==Plan.MAX_INLAND_SITES,
 "actual authored terrain should fill its inland budget: "..tostring(inland))
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
assert(west==6 and east==6,
 "world sculpt ignores one side (west="..tostring(west)..", east="..tostring(east)..")")
local seen={}
local minimumBackdropClearance=math.huge
local minimumEscarpmentClearance=math.huge
local minimumOuterEscarpmentClearance=math.huge
local minimumGroundInset=math.huge
local escarpmentIntersections={}
local function pointEllipsoidDistance(point,ellipsoid)
 local delta={
  math.abs(point.x-ellipsoid.x),
  math.abs(point.y-ellipsoid.y),
  math.abs(point.z-ellipsoid.z),
 }
 local axes={ellipsoid.halfX,ellipsoid.halfY,ellipsoid.halfZ}
 local normalized=0
 for axis=1,3 do normalized+=(delta[axis]/axes[axis])^2 end
 if normalized<=1 then return 0 end

 local function residual(lambda)
  local total=0
  for axis=1,3 do
   local squared=axes[axis]^2
   total+=(axes[axis]*delta[axis]/(lambda+squared))^2
  end
  return total-1
 end
 local low,high=0,1
 while residual(high)>0 do high*=2 end
 for _=1,80 do
  local middle=(low+high)/2
  if residual(middle)>0 then low=middle else high=middle end
 end
 local lambda=(low+high)/2
 local distanceSquared=0
 for axis=1,3 do
  local squared=axes[axis]^2
  local nearest=squared*delta[axis]/(lambda+squared)
  distanceSquared+=(delta[axis]-nearest)^2
 end
 return math.sqrt(distanceSquared)
end


-- Conservative sphere-to-oriented-box separation. Roblox's authored Ball and
-- WedgePart silhouettes occupy no more volume than these boxes, so a positive
-- result guarantees that the planned voxel ball cannot cut any of the 56 live
-- escarpment parts without pretending to simulate Studio voxel rasterization.
local function sphereBoxClearance(sphere,box)
 local dx=sphere.x-box.x
 local dy=sphere.y-box.y
 local dz=sphere.z-box.z
 local localX=dx*box.r00+dy*box.r10+dz*box.r20
 local localY=dx*box.r01+dy*box.r11+dz*box.r21
 local localZ=dx*box.r02+dy*box.r12+dz*box.r22
 local outsideX=math.max(math.abs(localX)-box.halfX,0)
 local outsideY=math.max(math.abs(localY)-box.halfY,0)
 local outsideZ=math.max(math.abs(localZ)-box.halfZ,0)
 return math.sqrt(outsideX^2+outsideY^2+outsideZ^2)-sphere.radius
end

for _,op in ipairs(writes) do
 assert(not seen[op.name],"duplicated terrain operation "..op.name)
 seen[op.name]=true
 assert(op.radius>=6 and op.radius<=32,"unsafe radius")
 assert(op.y+op.radius<=12,"terrain encroaches above safe elevations")
 local isOuter=string.match(op.name,"_Rock$") or string.match(op.name,"_Grass$")
 if not isOuter then
  local xInset=Plan.GROUND_HALF_EXTENT-(math.abs(op.x)+op.radius+Plan.VOXEL_GUARD)
  local zInset=Plan.GROUND_HALF_EXTENT-(math.abs(op.z)+op.radius+Plan.VOXEL_GUARD)
  minimumGroundInset=math.min(minimumGroundInset,xInset,zInset)
  assert(xInset>=Plan.MIN_GROUND_INSET and zInset>=Plan.MIN_GROUND_INSET,
   "runtime inland voxel guard extends beyond authored ground: "..op.name)
 end
 for _,backdrop in ipairs(fixture.backdrops) do
  local clearance=pointEllipsoidDistance(op,backdrop)-op.radius
  minimumBackdropClearance=math.min(minimumBackdropClearance,clearance)
  assert(clearance>=0.5,
   "runtime voxel fill intersects authored backdrop: "..op.name.." / "
    ..backdrop.name.." clearance="..tostring(clearance))
 end
 for _,escarpment in ipairs(fixture.escarpments) do
  local clearance=sphereBoxClearance(op,escarpment)
  if isOuter then
   -- The original perimeter Terrain deliberately seats into the authored
   -- boundary kit. Track it, but gate the new playable-area contours only.
   minimumOuterEscarpmentClearance=math.min(minimumOuterEscarpmentClearance,clearance)
  else
   minimumEscarpmentClearance=math.min(minimumEscarpmentClearance,clearance)
   if clearance<0.5 then
    table.insert(escarpmentIntersections,
     op.name.." / "..escarpment.model.."/"..escarpment.name
      .." clearance="..string.format("%.3f",clearance))
   end
  end
 end
end
assert(#escarpmentIntersections==0,
 "runtime inland voxel fills intersect authored escarpments:\n"
  ..table.concat(escarpmentIntersections,"\n"))
assert(seen.EastOuterClearingHillock_Foundation,
 "positive-inset east clearing hillock was not selected")
assert(not seen.EastEscarpmentGapHillock_Foundation,
 "zero-inset east boundary contour returned")
assert(seen.EastNorthHillock_Foundation,
 "ground-bounded east-north hillock was not selected")
assert(not seen.EastRimHillock_Foundation,
 "voxel hillock returned inside QuarryBackdropHill")
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
 ..", western="..west..", eastern="..east..", fills="..#writes
 ..", minimum backdrop clearance="..string.format("%.3f",minimumBackdropClearance)
 ..", minimum inland escarpment clearance="..string.format("%.3f",minimumEscarpmentClearance)
 ..", minimum guarded ground inset="..string.format("%.3f",minimumGroundInset)
 ..", perimeter seating="..string.format("%.3f",minimumOuterEscarpmentClearance))
