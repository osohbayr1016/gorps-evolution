-- Combat is deterministic and resolves entirely on the server.
-- PvE creatures do not produce PvP-ranked wins or wager rewards.
local Rules=require(script.Parent.Rules)
local Adventure={}
function Adventure.hunt(profile,enemyLevel)
 if type(enemyLevel)~="number" or enemyLevel%1~=0 or enemyLevel<1 or enemyLevel>25 then
  return false,"Invalid wild creature",nil
 end
 local active=Rules.pet(profile,profile.ActiveId)
 if not active then return false,"Select a companion first",nil end
 local stats=Rules.stats(active)
 if not stats then return false,"Invalid companion",nil end
 local heroHP=stats.hp
 local beastHP=45+enemyLevel*17
 local beastAttack=4+enemyLevel*3
 local turns=0
 local totalDamage=0
 for round=1,18 do
  turns=round
  local heroDamage=stats.attack
  if stats.role=="Assassin" and round%3==1 then heroDamage=math.floor(heroDamage*1.8) end
  if stats.role=="Ranged" and round%4==0 then heroDamage=heroDamage+math.floor(heroDamage*.7) end
  beastHP-=heroDamage
  totalDamage+=heroDamage
  if beastHP<=0 then break end
  local retaliation=beastAttack
  if stats.role=="Tank" then retaliation=math.max(1,math.floor(retaliation*.72)) end
  heroHP-=retaliation
  if stats.role=="Support" and round%3==0 then
   heroHP=math.min(stats.hp,heroHP+math.floor(stats.hp*.08))
  end
  if heroHP<=0 then break end
 end
 if heroHP<=0 or beastHP>0 then
  return false,"Your "..active.species.." was defeated. Feed and train it before another hunt.",
   {victory=false,turns=turns,remainingHP=math.max(0,heroHP),enemyLevel=enemyLevel}
 end
 local meat=2+math.floor(enemyLevel/2)
 local coins=12+enemyLevel*6
 Rules.add(profile,{Meat=meat})
 profile.Coins+=coins
 Rules.xp(profile,10+enemyLevel*5)
 Rules.quest(profile,"Explorer",1)
 Rules.quest(profile,"Gatherer",meat)
 return true,active.species.." defeated a wild creature! +"..meat.." meat, +"..coins.." coins",
  {victory=true,turns=turns,remainingHP=heroHP,enemyLevel=enemyLevel,damage=totalDamage}
end
return Adventure
