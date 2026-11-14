-- Presentation-only creature ordering and role filtering.
-- Never mutate the authoritative profile.Pets array or persist client view state.
local Config=require(script.Parent.Config)
local View={}
View.SortModes={"Acquired","Favorites","Level","Rarity","Species"}
View.Roles={"All","Support","Assassin","Tank","Transport","Miner","Ranged"}
local function cycle(items,current)
 for index,id in ipairs(items) do
  if id==current then return items[index%#items+1] end
 end
 return items[1]
end
function View.nextSort(mode) return cycle(View.SortModes,mode) end
function View.nextRole(role) return cycle(View.Roles,role) end
function View.list(pets,mode,role)
 local result={}
 if type(pets)~="table" then return result end
 local validSort=table.find(View.SortModes,mode)~=nil
 local sort=validSort and mode or "Acquired"
 local filter=table.find(View.Roles,role) and role or "All"
 for _,pet in ipairs(pets) do
  if type(pet)=="table" then
   local species=Config.Species[pet.species]
   if species and (filter=="All" or species.role==filter) then
    table.insert(result,pet)
   end
  end
 end
 local function rarity(pet)
  return table.find(Config.Rarities,pet.rarity) or 1
 end
 table.sort(result,function(a,b)
  if sort=="Favorites" and (a.favorite==true)~=(b.favorite==true) then
   return a.favorite==true
  end
  if sort=="Level" and a.level~=b.level then return a.level>b.level end
  if sort=="Rarity" and rarity(a)~=rarity(b) then return rarity(a)>rarity(b) end
  if sort=="Species" and a.species~=b.species then return a.species<b.species end
  return a.id<b.id
 end)
 return result
end
return View
