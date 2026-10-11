-- Presentation-only pose rules. No rewards, damage or profile mutations live here.
local Pose={}
Pose.Duration={Feed=2.2,Gather=1.3,Hunt=1.5,Evolve=2.6,SelectPet=1.6}
function Pose.state(action,age)
 local duration=Pose.Duration[action]
 if duration and age>=0 and age<duration then return action,age/duration end
 return "Idle",0
end
function Pose.joint(kind,side,front,time,moving,action,progress)
 local gait=math.sin(time*9+((side*front)<0 and math.pi or 0))*moving
 local pulse=math.sin(progress*math.pi)
 if kind=="Paw" then
  return CFrame.new(0,math.max(0,gait)*.3,-gait*.35)
   *CFrame.Angles(gait*.55,0,action=="Evolve" and side*pulse*.25 or 0)
 elseif kind=="Head" then
  local nod=action=="Feed" and math.sin(progress*math.pi*6)*.3
   or ((action=="Gather" or action=="Hunt") and -pulse*.4 or 0)
  return CFrame.Angles(nod+math.sin(time*2)*.035,math.sin(time*1.4)*.06,0)
 elseif kind=="Tail" then
  return CFrame.Angles(0,math.sin(time*(action=="Feed" and 12 or 4))*.3,0)
 elseif kind=="Wing" then
  return CFrame.Angles(0,0,side*math.sin(time*(moving>.1 and 10 or 3))*.22)
 end
 return CFrame.new()
end
function Pose.lunge(action,progress)
 return math.sin(progress*math.pi)*(action=="Hunt" and 1.3 or (action=="Gather" and .3 or 0))
end
function Pose.bounce(time,moving,action,progress)
 if action=="Evolve" or action=="SelectPet" then return math.sin(progress*math.pi)*1.3 end
 if action=="Hunt" then return math.sin(progress*math.pi)*.55 end
 return math.abs(math.sin(time*9))*.18*moving+math.sin(time*2)*.035
end
return Pose
