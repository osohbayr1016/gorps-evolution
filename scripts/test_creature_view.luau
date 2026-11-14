-- Run the actual presentation-only CreatureView helper under headless Luau.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local cfg=luau.load(fs.readFile("src/shared/Config.lua"),{
 debugName="src/shared/Config.lua",
})()
local view=luau.load(fs.readFile("src/shared/CreatureView.lua"),{
 debugName="src/shared/CreatureView.lua",
 environment={
  script={Parent={Config="Config"}},
  require=function(dependency)
   assert(dependency=="Config","Unexpected view dependency")
   return cfg
  end,
 },
})()
local pets={
 {id=5,species="Shade",rarity="Uncommon",level=3},
 {id=2,species="Gorp",rarity="Common",level=10},
 {id=9,species="Bloom",rarity="Rare",level=4,favorite=true},
 {id=3,species="Mole",rarity="Common",level=8},
}
local checks=0
local function equal(actual,expected,label)
 checks+=1
 assert(actual==expected,label..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function order(mode,role,expected)
 local result=view.list(pets,mode,role)
 equal(#result,#expected,mode.." / "..role.." length")
 for i,id in ipairs(expected) do equal(result[i].id,id,mode.." / "..role.." #"..i) end
 return result
end
local acquired=order("Acquired","All",{2,3,5,9})
order("Favorites","All",{9,2,3,5})
order("Level","All",{2,3,9,5})
order("Rarity","All",{9,5,2,3})
order("Species","All",{9,2,3,5})
order("Level","Support",{2,9})
order("Acquired","Miner",{3})
order("Acquired","Tank",{})
order("Acquired","Transport",{})
order("Acquired","Assassin",{5})
order("Unknown","Unlisted",{2,3,5,9})
equal(acquired~=pets,true,"sorted list never aliases authoritative collection")
equal(pets[1].id,5,"sorting never mutates first saved pet")
equal(pets[2].id,2,"sorting never mutates second saved pet")
equal(view.nextSort("Acquired"),"Favorites","sort cycle begins with protected favorites")
equal(view.nextSort("Favorites"),"Level","favorites sort cycles to strongest level")
equal(view.nextSort("Level"),"Rarity","sort cycle reaches rarity")
equal(view.nextSort("Rarity"),"Species","sort cycle reaches species")
equal(view.nextSort("Species"),"Acquired","sort cycle wraps")
equal(view.nextSort("Unknown"),"Acquired","invalid sort resets safely")
equal(view.nextRole("All"),"Support","role filter starts at Support")
equal(view.nextRole("Ranged"),"All","role filter wraps")
equal(view.nextRole("Unknown"),"All","invalid role resets safely")
equal(#view.list(nil,"Level","All"),0,"nil client profile never crashes the listing")
local broken={{id=1,species="Invalid",rarity="Rare",level=3}}
equal(#view.list(broken,"Level","All"),0,"unknown species cannot break renderer")

print("PASS: "..checks.." creature collection sorting and role filtering assertions.")
