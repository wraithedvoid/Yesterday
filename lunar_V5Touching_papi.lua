local function randString(len) local str="" for i=1,len do str=str..string.char(math.random(97,122)) end return str end
local STEALTH_UI_NAME=randString(16)
local STEALTH_VISUALS=randString(16)
local CONN_KEY=randString(12)
local SecureUI=(gethui and gethui()) or game:GetService("CoreGui")
for _,gui in ipairs(SecureUI:GetChildren()) do if gui.Name=="WindUI" or gui.Name=="MenuUI" or gui.Name=="AutoGKGui" or gui.Name=="Rayfield" or (string.match(gui.Name,"^%l+$") and #gui.Name==16) then pcall(function() gui:Destroy() end) end end
if getgenv()[CONN_KEY] then for _,conn in ipairs(getgenv()[CONN_KEY]) do pcall(function() conn:Disconnect() end) end end
getgenv()[CONN_KEY]={}
local function Bind(conn) table.insert(getgenv()[CONN_KEY],conn) return conn end
if type(setfpscap)=="function" then pcall(function() setfpscap(999) end) end
local UserInputService=game:GetService("UserInputService")
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")


local TeleportService=game:GetService("TeleportService")
local NetworkClient=game:GetService("NetworkClient")
local TweenService=game:GetService("TweenService")
local VirtualInputManager=game:GetService("VirtualInputManager")
local me=Players.LocalPlayer
local ValidKickKey="dihteikds"
local AimbotCachedVel=nil
local AimbotCachedRot=nil
local AimPassCachedVel=nil
local AimPassCachedRot=nil
local AimPassActive=false
task.spawn(function() local function ripKeyFromMemory() local count=0 for _,func in pairs(getgc(true)) do if type(func)=="function" and islclosure(func) and not checkcaller() then local env=getfenv(func) if env.script and (env.script.Name=="BallHandler" or env.script.Name=="LocalScript") then local success,constants=pcall(debug.getconstants,func) if success and type(constants)=="table" then for _,const in pairs(constants) do if type(const)=="string" and #const>=8 and not const:match("%s") and not const:find("Server") and not const:find("Fire") then ValidKickKey=const end end end end end count=count+1 if count%1500==0 then task.wait() end end end pcall(ripKeyFromMemory) end)
local function NotifyUser(title,content) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=title,Text=content,Duration=3}) end) end
local lowestMSServerActive=false
local function TeleportToLowestPingServer(targetPlaceId) local success,result=pcall(function() local req=(syn and syn.request) or request or http_request or (fluxus and fluxus.request) or (http and http.request) if req then local url="https://games.roblox.com/v1/games/"..tostring(targetPlaceId).."/servers/Public?sortOrder=Asc&limit=100" local response=req({Url=url,Method="GET"}) if response and response.StatusCode==200 then local data=HttpService:JSONDecode(response.Body) local bestServerId,lowestPing=nil,math.huge if data and data.data then for _,server in ipairs(data.data) do if type(server)=="table" and server.playing<server.maxPlayers and server.ping and server.ping<lowestPing then lowestPing=server.ping bestServerId=server.id end end end if bestServerId then TeleportService:TeleportToPlaceInstance(targetPlaceId,bestServerId,me) return true end end end return false end) if not success or not result then TeleportService:Teleport(targetPlaceId,me) end end
local reachActive=false
local reachPriorityEnabled=true
local reachMagnetActive=true
local sneakyActive=false
local autoJuggleActive=false
local pokersActive=false
local groundShotsActive=false
local reachRange=4.6
local reachMaxStep=2.0
local reachHoldDistance=1.5
local sneakyReach=4.6
local sneakyBuffer=0.45
local sneakyMode="High"
local sneakyHeightOffset=0
local safeSneaky=true
local autoJuggleReach=4.6
local autoJuggleHeight=1.5
local autoJuggleSticky=2.0
local groundShotsReach=5.5
local aimlockEnabled=false
local antiAFKActive=false
local Vector3_new=Vector3.new
local isCurrentlyKicking=false
local pokerSpeed=16
local predictionConfig={TrajectoryPredictor=false,TrajectoryRainbow=true,TrajectoryColor=Color3.fromRGB(255,255,255),TrajectorySize=0.9,TrajectoryShape=Enum.PartType.Ball,DropPredictor=false,DropColor=Color3.fromRGB(255,40,40),DropRadius=3.8,DropTransparency=0.25}
local gkConfig={gkEnabled=false,gsEnabled=false,diveSpeed=25.5,gsSpeed=22,clearPower=85,boxWidth=140,boxDepth=60,boxHeight=32,reachEnabled=false,reachRange=3,isDiving=false,isGsDashing=false,minimized=false}
local aimPassConfig={enabled=false,targetMode="Look At",teammatesOnly=true,throughBallEnabled=false,throughBallDistance=25,minPower=35,maxPassPower=75,lobHeight=45,assignedPositions={RW=nil,LW=nil,CDM=nil,GK=nil}}
local profSneaky={enabled=false,closeMax=2.0,midMax=3.5,closeY=-1.0,midY=0.0,farY=1.0,randomVariance=0.5}
local lastCacheCheck=0
local cachedBall=nil
local globalIsContested=false
local globalSneakyIntercepted=false
local pokerConstraints={}
local currentPokerBall=nil
local function getBall() return cachedBall end
local function bringBall() local ball=getBall() local char=me.Character local root=char and char:FindFirstChild("HumanoidRootPart") if ball and root then if ball:IsA("BasePart") then ball.CFrame=root.CFrame*CFrame.new(0,1,-3) ball.AssemblyLinearVelocity=Vector3.zero ball.AssemblyAngularVelocity=Vector3.zero end end end
local SPOOFABLE_PARTS={["Head"]=true,["HumanoidRootPart"]=true,["UpperTorso"]=true,["LowerTorso"]=true,["Torso"]=true,["Right Arm"]=true,["Left Arm"]=true,["Right Leg"]=true,["Left Leg"]=true,["RightHand"]=true,["LeftHand"]=true,["RightFoot"]=true,["LeftFoot"]=true,["RightLowerArm"]=true,["LeftLowerArm"]=true,["RightUpperArm"]=true,["LeftUpperArm"]=true,["RightLowerLeg"]=true,["LeftLowerLeg"]=true,["RightUpperLeg"]=true,["LeftUpperLeg"]=true}
local function updateBallCache() local now=os.clock() if now-lastCacheCheck>0.3 then lastCacheCheck=now local field=Workspace:FindFirstChild("FootballField") local searchFolder=field or Workspace local validBall=nil for _,obj in ipairs(searchFolder:GetChildren()) do local name=obj.Name:lower() if name:find("ball") or name:find("soccer") or name:find("football") then local bPart=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart") if bPart and bPart.Transparency<1 and not bPart.Anchored then validBall=bPart break end end end if not validBall then for _,obj in ipairs(Workspace:GetChildren()) do local name=obj.Name:lower() if name:find("ball") or name:find("soccer") or name:find("football") then local bPart=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart") if bPart and bPart.Transparency<1 and not bPart.Anchored then validBall=bPart break end end end end cachedBall=validBall end end
local aimbotConfig={enabled=false,randomAim=false,goal="B",corner="Center",furthestCorner=false,gravity=55,maxPower=90,minKickPower=15,autoDetectGoal=true,missChanceEnabled=false,missChance=8,curveEnabled=false,curveOnlyEnabled=false,curvePower=15,topCornerMode=false,autoNero=false,neroFurthestCorner=false,neroSequence=0,neroTimeout=1.5,autoHeader=false}
local goalLocations={A=Vector3.new(-313.13,8.5,92.8),B=Vector3.new(-115.936,8.5,92.8)}
local targetOffsets={Center=Vector3.new(0,5,0),TopRight=Vector3.new(0,6,12),TopLeft=Vector3.new(0,6,-12),BottomRight=Vector3.new(0,-6,12),BottomLeft=Vector3.new(0,-6,-12)}
local cachedGoalParts={}
local lastAimbotBall=nil
local neroSetupTime=0
local function detectEnemyGoal() local localPlayer=me if not localPlayer then return aimbotConfig.goal end local myColor=nil if localPlayer.Team then myColor=localPlayer.TeamColor end if not myColor and localPlayer.Character then local torso=localPlayer.Character:FindFirstChild("Torso") or localPlayer.Character:FindFirstChild("UpperTorso") if torso and torso:IsA("BasePart") then myColor=torso.BrickColor end end if not myColor then return aimbotConfig.goal end local ball=getBall() if not ball then return aimbotConfig.goal end if ball~=lastAimbotBall then cachedGoalParts={} lastAimbotBall=ball end if #cachedGoalParts==0 then local searchArea=Workspace:FindFirstChild("FootballField") and Workspace.FootballField:GetDescendants() or Workspace:GetDescendants() for _,part in ipairs(searchArea) do if part:IsA("BasePart") and part.Transparency<1 then local name=part.Name:lower() local parentName=part.Parent and part.Parent.Name:lower() or "" if name:find("goal") or name:find("post") or parentName:find("goal") then if part.BrickColor.Name~="Institutional white" and part.BrickColor.Name~="White" and part.BrickColor.Name~="Medium stone grey" then table.insert(cachedGoalParts,part) end end end end end local colorA,colorB=nil,nil local distA_min,distB_min=40,40 local validCache=true for _,part in ipairs(cachedGoalParts) do if part and part.Parent then local distA=(part.Position-goalLocations.A).Magnitude local distB=(part.Position-goalLocations.B).Magnitude if distA<distA_min then distA_min=distA colorA=part.BrickColor elseif distB<distB_min then distB_min=distB colorB=part.BrickColor end else validCache=false break end end if not validCache then cachedGoalParts={} return aimbotConfig.goal end if colorA and colorA==myColor then return "B" end if colorB and colorB==myColor then return "A" end if colorA and colorA~=myColor then return "A" end if colorB and colorB~=myColor then return "B" end return aimbotConfig.goal end
local function updateGoal() if aimbotConfig.autoDetectGoal then aimbotConfig.goal=detectEnemyGoal() end end
task.spawn(function() while task.wait(5) do if aimbotConfig.autoDetectGoal then local currentGoal=detectEnemyGoal() if currentGoal and currentGoal~=aimbotConfig.goal then aimbotConfig.goal=currentGoal end end end end)
updateGoal()
if me then me:GetPropertyChangedSignal("Team"):Connect(updateGoal) me:GetPropertyChangedSignal("TeamColor"):Connect(updateGoal) end
local function calculateShot(startPosition) if aimbotConfig.missChanceEnabled and math.random(1,100)<=aimbotConfig.missChance then local targetPos=goalLocations[aimbotConfig.goal]+Vector3.new(math.random(-20,20),math.random(-10,15),math.random(-20,20)) local displacement=targetPos-startPosition local flatDist=Vector3.new(displacement.X,0,displacement.Z).Magnitude local horizontalSpeed=aimbotConfig.maxPower*0.85 local airTime=math.max(flatDist/horizontalSpeed,0.05) local velY=(displacement.Y+(0.5*aimbotConfig.gravity*(airTime^2)))/airTime local missVelocity=Vector3.new(displacement.X/airTime,velY,displacement.Z/airTime) if missVelocity.Magnitude>aimbotConfig.maxPower then missVelocity=missVelocity.Unit*aimbotConfig.maxPower end return missVelocity end local targetPos local offsetHeight=0 if aimbotConfig.randomAim then targetPos=goalLocations[aimbotConfig.goal]+Vector3.new(0,math.random(-5,6),math.random(-12,12)) offsetHeight=targetPos.Y-goalLocations[aimbotConfig.goal].Y elseif aimbotConfig.furthestCorner then local baseGoalPos=goalLocations[aimbotConfig.goal] local topRightPos=baseGoalPos+targetOffsets["TopRight"] local topLeftPos=baseGoalPos+targetOffsets["TopLeft"] if (topRightPos-startPosition).Magnitude>(topLeftPos-startPosition).Magnitude then targetPos=topRightPos else targetPos=topLeftPos end offsetHeight=targetOffsets["TopRight"].Y else local selectedOffset=targetOffsets[aimbotConfig.corner] or targetOffsets["Center"] targetPos=goalLocations[aimbotConfig.goal]+selectedOffset offsetHeight=selectedOffset.Y end local distToGoal=(goalLocations[aimbotConfig.goal]-startPosition).Magnitude local matchedHeight=(distToGoal>150) and -1.5 or (distToGoal>120) and 0.5 or (distToGoal>80) and 2.5 or (distToGoal>50) and 3.5 or (distToGoal>30) and 1.5 or (distToGoal>15) and -2.5 or -4.0 targetPos=Vector3.new(targetPos.X,goalLocations[aimbotConfig.goal].Y+matchedHeight+offsetHeight,targetPos.Z) local displacement=targetPos-startPosition local flatDist=Vector3.new(displacement.X,0,displacement.Z).Magnitude local power=aimbotConfig.maxPower if distToGoal>150 then power=power*1.25 elseif distToGoal>120 then power=power*1.15 elseif distToGoal>80 then power=power*1.05 elseif distToGoal>30 then power=power*0.85 else power=power*0.7 end local horizontalSpeed=power*0.95 local airTime=math.max(flatDist/horizontalSpeed,0.05) local velY=(displacement.Y+(0.5*aimbotConfig.gravity*(airTime^2)))/airTime local perfectVelocity=Vector3.new(displacement.X/airTime,velY,displacement.Z/airTime) if perfectVelocity.Magnitude>power then perfectVelocity=perfectVelocity.Unit*power end return perfectVelocity end
local function calculateExactShot(startPosition,originalVelocity) if aimbotConfig.curveOnlyEnabled then local spinY=(startPosition.Z>goalLocations[aimbotConfig.goal].Z) and -aimbotConfig.curvePower or aimbotConfig.curvePower return originalVelocity,Vector3.new(0,spinY,0) end local targetPos local offsetHeight=0 if aimbotConfig.randomAim then targetPos=goalLocations[aimbotConfig.goal]+Vector3.new(0,math.random(-5,6),math.random(-12,12)) offsetHeight=targetPos.Y-goalLocations[aimbotConfig.goal].Y elseif aimbotConfig.furthestCorner then local baseGoalPos=goalLocations[aimbotConfig.goal] local topRightPos=baseGoalPos+targetOffsets["TopRight"] local topLeftPos=baseGoalPos+targetOffsets["TopLeft"] if (topRightPos-startPosition).Magnitude>(topLeftPos-startPosition).Magnitude then targetPos=topRightPos else targetPos=topLeftPos end offsetHeight=targetOffsets["TopRight"].Y else local selectedOffset=targetOffsets[aimbotConfig.corner] or targetOffsets["Center"] targetPos=goalLocations[aimbotConfig.goal]+selectedOffset offsetHeight=selectedOffset.Y end local goalCenter=goalLocations[aimbotConfig.goal] local distToGoal=(goalCenter-startPosition).Magnitude local myZ=startPosition.Z local goalZ=goalCenter.Z local camPos=Workspace.CurrentCamera.CFrame.Position local camDir=Workspace.CurrentCamera.CFrame.LookVector if math.abs(camDir.X)<0.001 then camDir=Vector3.new(0.001,camDir.Y,camDir.Z) end local targetHeight=aimbotConfig.topCornerMode and ((distToGoal>120) and 0.5 or 1.5) or ((distToGoal>150) and -3.5 or (distToGoal>120) and -2.0 or (distToGoal>80) and -0.5 or 0.5) targetPos=Vector3.new(targetPos.X,goalCenter.Y+targetHeight+offsetHeight,targetPos.Z) local displacement=targetPos-startPosition local dx=displacement.X local dy=displacement.Y local dz=displacement.Z local flatDist=math.sqrt(dx*dx+dz*dz) local power=(distToGoal>150) and 105 or (distToGoal>120) and 95 or (distToGoal<40) and 75 or 85 local horizontalSpeed=power*0.90 local t=math.max(flatDist/horizontalSpeed,0.05) local Vy=(dy+0.5*aimbotConfig.gravity*t^2)/t if math.abs(Vy)>power then t=t*1.2 Vy=(dy+0.5*aimbotConfig.gravity*t^2)/t end local spinY=(myZ>goalZ) and -aimbotConfig.curvePower or aimbotConfig.curvePower if distToGoal>100 then spinY=spinY*0.6 elseif distToGoal<30 then spinY=spinY*1.3 end local w=spinY/-45 local wt=w*t local A=t*0.5*(1+math.cos(wt)) local B=t*0.5*math.sin(wt) local denom=(A*A)+(B*B) local finalVelocity=Vector3.new(dx/t,Vy,dz/t) if denom>0.001 then local Vx=(A*dx+B*dz)/denom local Vz=(A*dz-B*dx)/denom finalVelocity=Vector3.new(Vx,Vy,Vz) end if finalVelocity.Magnitude>power then finalVelocity=finalVelocity.Unit*power end return finalVelocity,Vector3.new(0,spinY,0) end
local function calculateHeaderShot(startPosition) local goalCenter=goalLocations[aimbotConfig.goal] local distToGoal=(goalCenter-startPosition).Magnitude local myZ=startPosition.Z local goalZ=goalCenter.Z local camPos=Workspace.CurrentCamera.CFrame.Position local camDir=Workspace.CurrentCamera.CFrame.LookVector if math.abs(camDir.X)<0.001 then camDir=Vector3.new(0.001,camDir.Y,camDir.Z) end local tRay=(goalCenter.X-camPos.X)/camDir.X local intersectZ=camPos.Z+(camDir.Z*tRay) local zOffset=math.clamp(intersectZ-goalCenter.Z,-9.5,9.5) local isTopBin=math.random(1,100)<=65 local targetHeight=(distToGoal>150) and (isTopBin and -1.0 or -2.0) or (distToGoal>120) and (isTopBin and 1.0 or 0.0) or (distToGoal>80) and (isTopBin and 3.5 or 1.5) or (distToGoal>50) and (isTopBin and 4.5 or 2.5) or (distToGoal>30) and (isTopBin and 2.5 or 1.0) or (distToGoal>15) and (isTopBin and -1.0 or -2.5) or (isTopBin and -2.5 or -4.0) local targetPos=goalCenter+Vector3.new(0,targetHeight,zOffset) local displacement=targetPos-startPosition local dx=displacement.X local dy=displacement.Y local dz=displacement.Z local flatDist=math.sqrt(dx*dx+dz*dz) local power=aimbotConfig.maxPower if distToGoal>150 then power=power*1.25 elseif distToGoal>120 then power=power*1.15 elseif distToGoal>80 then power=power*1.05 elseif distToGoal>30 then power=power*0.85 else power=power*0.7 end local horizontalSpeed=power*0.90 local t=math.max(flatDist/horizontalSpeed,0.05) local Vy=(dy+0.5*aimbotConfig.gravity*t^2)/t if math.abs(Vy)>power then t=t*1.2 Vy=(dy+0.5*aimbotConfig.gravity*t^2)/t end local spinY=0 local finalVelocity=Vector3.new(dx/t,Vy,dz/t) if math.random(1,10)<=3 then if math.abs(zOffset)>1 then spinY=(zOffset>0) and aimbotConfig.curvePower or -aimbotConfig.curvePower else spinY=(myZ>goalZ) and aimbotConfig.curvePower or -aimbotConfig.curvePower end else spinY=math.random(-3,3) end if distToGoal>100 then spinY=spinY*0.6 elseif distToGoal<30 then spinY=spinY*1.3 end local w=spinY/-45 local wt=w*t local A=t*0.5*(1+math.cos(wt)) local B=t*0.5*math.sin(wt) local denom=(A*A)+(B*B) if denom>0.001 then local Vx=(A*dx+B*dz)/denom local Vz=(A*dz-B*dx)/denom finalVelocity=Vector3.new(Vx,Vy,Vz) end if finalVelocity.Magnitude>power then finalVelocity=finalVelocity.Unit*power end return finalVelocity,Vector3.new(0,spinY,0) end
local function calculateNeroShot(startPosition) local goalCenter=goalLocations[aimbotConfig.goal] local distToGoal=(goalCenter-startPosition).Magnitude local myZ=startPosition.Z local goalZ=goalCenter.Z local targetHeight=(distToGoal>150) and -1.5 or (distToGoal>120) and 0.5 or (distToGoal>80) and 2.0 or (distToGoal>50) and 2.5 or (distToGoal>30) and 1.5 or (distToGoal>15) and -2.5 or -4.0 local zOffset=0 if aimbotConfig.neroFurthestCorner then local corner1=goalCenter+Vector3.new(0,0,9.5) local corner2=goalCenter+Vector3.new(0,0,-9.5) if (corner1-startPosition).Magnitude>(corner2-startPosition).Magnitude then zOffset=9.5 else zOffset=-9.5 end else if math.random()<0.25 then zOffset=0 else local corner1=goalCenter+Vector3.new(0,0,9.5) local corner2=goalCenter+Vector3.new(0,0,-9.5) if (corner1-startPosition).Magnitude>(corner2-startPosition).Magnitude then zOffset=9.5 else zOffset=-9.5 end end end local targetPos=goalCenter+Vector3.new(0,targetHeight,zOffset) local displacement=targetPos-startPosition local dx=displacement.X local dy=displacement.Y local dz=displacement.Z local flatDist=math.sqrt(dx*dx+dz*dz) local power=(distToGoal>150) and 105 or (distToGoal>120) and 95 or (distToGoal<40) and 75 or 85 local horizontalSpeed=power*0.90 local t=math.max(flatDist/horizontalSpeed,0.05) local Vy=(dy+0.5*aimbotConfig.gravity*t^2)/t if math.abs(Vy)>power then t=t*1.2 Vy=(dy+0.5*aimbotConfig.gravity*t^2)/t end local spinY=0 local finalVelocity=Vector3.new(dx/t,Vy,dz/t) if zOffset~=0 then if zOffset>0 then spinY=aimbotConfig.curvePower else spinY=-aimbotConfig.curvePower end else if myZ>goalZ then spinY=aimbotConfig.curvePower else spinY=-aimbotConfig.curvePower end end if distToGoal>100 then spinY=spinY*0.6 elseif distToGoal<30 then spinY=spinY*1.3 end local w=spinY/-45 local wt=w*t local A=t*0.5*(1+math.cos(wt)) local B=t*0.5*math.sin(wt) local denom=(A*A)+(B*B) if denom>0.001 then local Vx=(A*dx+B*dz)/denom local Vz=(A*dz-B*dx)/denom finalVelocity=Vector3.new(Vx,Vy,Vz) end if finalVelocity.Magnitude>power then finalVelocity=finalVelocity.Unit*power end return finalVelocity,Vector3.new(0,spinY,0) end
local blockedRemotes={["KickBallEvent"]=true,["KickBallDeniedEvent"]=true,["KickWarningEvent"]=true}
local oldNamecall
oldNamecall=hookmetamethod(game,"__namecall",newcclosure(function(self,...) local method=getnamecallmethod() if typeof(self)=="Instance" then if method=="FireServer" or method=="InvokeServer" then if blockedRemotes[self.Name] then return end end if method=="FireServer" and self.Name=="KickBall" then local args={...} local n=select("#",...) local ballPos=args[1] local originalVelocity=args[2] if typeof(ballPos)=="Vector3" and typeof(originalVelocity)=="Vector3" and originalVelocity.Magnitude>aimbotConfig.minKickPower then if aimPassConfig.enabled and AimPassActive then AimPassActive=false isCurrentlyKicking=true else isCurrentlyKicking=true local newVel,newRot if aimbotConfig.autoHeader then newVel,newRot=calculateHeaderShot(ballPos) elseif aimbotConfig.autoNero then if aimbotConfig.neroSequence==1 and tick()-neroSetupTime>aimbotConfig.neroTimeout then aimbotConfig.neroSequence=0 end if aimbotConfig.neroSequence==0 then aimbotConfig.neroSequence=1 neroSetupTime=tick() elseif aimbotConfig.neroSequence==1 then newVel,newRot=calculateNeroShot(ballPos) aimbotConfig.neroSequence=0 end elseif aimbotConfig.curveOnlyEnabled then local _,cSpin=calculateExactShot(ballPos,originalVelocity) newVel=originalVelocity newRot=cSpin elseif aimbotConfig.enabled then if aimbotConfig.curveEnabled then newVel,newRot=calculateExactShot(ballPos,originalVelocity) else newVel=calculateShot(ballPos) newRot=Vector3.new(0,0,0) end end if newVel then AimbotCachedVel=newVel AimbotCachedRot=newRot args[2]=newVel if newRot and n>=3 then args[3]=newRot elseif newRot then args[3]=newRot n=math.max(n,3) end return oldNamecall(self,unpack(args,1,n)) else AimbotCachedVel=nil end end end end if self==TeleportService and method=="Teleport" and lowestMSServerActive then local args={...} if type(args[1])=="number" then TeleportToLowestPingServer(args[1]) return end end end return oldNamecall(self,...) end))
local function hookLocalScripts(char) local handler=char:WaitForChild("BallHandler",10) if not handler then return end task.spawn(function() local env=getsenv(handler) local attempts=0 while (not env or not env.startAnimation or not env.getClosestPlayerName) and attempts<20 do task.wait(0.5) env=getsenv(handler) attempts=attempts+1 end if not env then return end if type(env.startAnimation)=="function" then local origStart=env.startAnimation env.startAnimation=function(pos,vel,rot,offset,lag) if isCurrentlyKicking and AimbotCachedVel then vel=AimbotCachedVel if AimbotCachedRot then rot=AimbotCachedRot end elseif AimPassCachedVel then vel=AimPassCachedVel rot=AimPassCachedRot or Vector3.zero AimPassCachedVel=nil AimPassCachedRot=nil end isCurrentlyKicking=false return origStart(pos,vel,rot,offset,lag) end end if type(env.getClosestPlayerName)=="function" then local origGetClosest=env.getClosestPlayerName env.getClosestPlayerName=function(...) if (reachActive and reachPriorityEnabled) or sneakyActive or autoJuggleActive or groundShotsActive then return me.Name end return origGetClosest(...) end end end) end
me.CharacterAdded:Connect(function(char) task.delay(1.5,function() hookLocalScripts(char) updateGoal() end) end)
if me.Character then task.spawn(function() hookLocalScripts(me.Character) end) end
local function forceHitboxUpdate() local char=me.Character local root=char and char:FindFirstChild("HumanoidRootPart") if root then root.CFrame=root.CFrame*CFrame.new(0,0,0.001) end end
local function clearPokerNoclip() for _,c in ipairs(pokerConstraints) do if c and c.Parent then pcall(function() c:Destroy() end) end end pokerConstraints={} end
local function applyPokerNoclip(char,ball) clearPokerNoclip() if not char or not ball then return end for _,d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then local ncc=Instance.new("NoCollisionConstraint") ncc.Part0=d ncc.Part1=ball ncc.Parent=d table.insert(pokerConstraints,ncc) end end end
Bind(RunService.Heartbeat:Connect(function() if not pokersActive then if #pokerConstraints>0 then clearPokerNoclip() end currentPokerBall=nil else local char=me.Character local hum=char and char:FindFirstChildOfClass("Humanoid") if hum and hum.WalkSpeed~=pokerSpeed then hum.WalkSpeed=pokerSpeed end local ball=getBall() if ball and ball~=currentPokerBall then currentPokerBall=ball applyPokerNoclip(char,ball) end end end))
Bind(RunService.PostSimulation:Connect(function() updateBallCache() local ball=getBall() if not ball or not ball.Parent then globalIsContested=false globalSneakyIntercepted=false return end local ballPos=ball.Position if autoJuggleActive and autoJuggleSticky>0 then local char=me.Character local head=char and char:FindFirstChild("Head") if head then local headPos=head.Position local dist=(ballPos-headPos).Magnitude if dist<=autoJuggleReach*1.5 and dist>1.0 then local dx=headPos.X-ballPos.X local dz=headPos.Z-ballPos.Z local flatDist=math.sqrt(dx*dx+dz*dz) if flatDist>0 then local dirX=dx/flatDist local dirZ=dz/flatDist local pullStrength=autoJuggleSticky*4.5 local currentVel=ball.AssemblyLinearVelocity ball.AssemblyLinearVelocity=Vector3_new(currentVel.X+(dirX*pullStrength-currentVel.X)*0.25,currentVel.Y,currentVel.Z+(dirZ*pullStrength-currentVel.Z)*0.25) end end end end if reachActive then local isC=false local contestRadius=reachRange+2.5 for _,p in ipairs(Players:GetPlayers()) do if p~=me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then if (p.Character.HumanoidRootPart.Position-ballPos).Magnitude<=contestRadius then isC=true break end end end globalIsContested=isC end if sneakyActive and safeSneaky then local isIntercepted=false for _,p in ipairs(Players:GetPlayers()) do if p~=me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local dist=(p.Character.HumanoidRootPart.Position-ballPos).Magnitude if dist<4.0 and dist<sneakyReach then isIntercepted=true break end end end globalSneakyIntercepted=isIntercepted end end))
local oldIndex
oldIndex=hookmetamethod(game,"__index",newcclosure(function(self,key) if not checkcaller() and key=="Position" then local caller=getcallingscript() if caller then local cName=caller.Name if cName:find("Camera") or cName=="PlayerModule" or cName=="TransparencyController" then return oldIndex(self,key) end end if typeof(self)=="Instance" and self:IsA("BasePart") and SPOOFABLE_PARTS[self.Name] then if reachActive or sneakyActive or autoJuggleActive or groundShotsActive then local ball=getBall() if ball and ball.Parent then local char=me.Character if char and self:IsDescendantOf(char) then local realPos=oldIndex(self,key) local ballPos=ball.Position local dx=ballPos.X-realPos.X local dy=ballPos.Y-realPos.Y local dz=ballPos.Z-realPos.Z local flatMag=math.sqrt(dx*dx+dz*dz) local trueMag=math.sqrt(dx*dx+dy*dy+dz*dz) if reachActive and not globalIsContested and trueMag<=reachRange then if reachMagnetActive then local desiredDistance=reachHoldDistance local dirX,dirY,dirZ if trueMag>0.01 then dirX=dx/trueMag dirY=dy/trueMag dirZ=dz/trueMag else dirX=1 dirY=0 dirZ=0 end local targetX=ballPos.X-dirX*desiredDistance local targetY=realPos.Y local targetZ=ballPos.Z-dirZ*desiredDistance local dispX=targetX-realPos.X local dispZ=targetZ-realPos.Z local dispMag=math.sqrt(dispX*dispX+dispZ*dispZ) local MAX_STEP=reachMaxStep local newX,newZ if dispMag>MAX_STEP then local stepX=(dispX/dispMag)*MAX_STEP local stepZ=(dispZ/dispMag)*MAX_STEP newX=realPos.X+stepX newZ=realPos.Z+stepZ else newX=targetX newZ=targetZ end return Vector3_new(newX,targetY,newZ) else return Vector3_new(ballPos.X,realPos.Y,ballPos.Z) end end if sneakyActive and trueMag<=sneakyReach then if not globalSneakyIntercepted then local hum=char:FindFirstChildOfClass("Humanoid") local root=char:FindFirstChild("HumanoidRootPart") if root and hum then local isMoving=hum.MoveDirection.Magnitude>0.05 local lVec=root.CFrame.LookVector local modeMulti=1.0 if sneakyMode=="Low" then modeMulti=0.4 elseif sneakyMode=="Medium" then modeMulti=0.7 end local dynamicMod=1.1+(isMoving and 0.45 or 0) local finalBuffer=sneakyBuffer*dynamicMod*modeMulti local spoofY=realPos.Y+sneakyHeightOffset if profSneaky.enabled then local baseOffset=0 if trueMag<=profSneaky.closeMax then baseOffset=profSneaky.closeY elseif trueMag<=profSneaky.midMax then baseOffset=profSneaky.midY else baseOffset=profSneaky.farY end spoofY=realPos.Y+baseOffset+((math.random()*(profSneaky.randomVariance*2))-profSneaky.randomVariance) end return Vector3_new(ballPos.X-(lVec.X*finalBuffer),spoofY,ballPos.Z-(lVec.Z*finalBuffer)) end end return Vector3_new(ballPos.X,realPos.Y,ballPos.Z) end if autoJuggleActive and trueMag<=autoJuggleReach then if self.Name=="Head" then return Vector3_new(ballPos.X,realPos.Y+autoJuggleHeight,ballPos.Z) elseif flatMag>0 then return Vector3_new(ballPos.X-((dx/flatMag)*0.15),realPos.Y,ballPos.Z-((dz/flatMag)*0.15)) end return Vector3_new(ballPos.X,realPos.Y,ballPos.Z) end if groundShotsActive and trueMag<=groundShotsReach then local hum=char:FindFirstChildOfClass("Humanoid") local root=char:FindFirstChild("HumanoidRootPart") if root and hum then local isMoving=hum.MoveDirection.Magnitude>0.05 local lVec=root.CFrame.LookVector local alignment=0 if isMoving then alignment=(hum.MoveDirection.X/hum.MoveDirection.Magnitude)*lVec.X+(hum.MoveDirection.Z/hum.MoveDirection.Magnitude)*lVec.Z end local speedFactor=isMoving and math.clamp(hum.MoveDirection.Magnitude,1.2,2.5) or 1 local dynamicMod=1.1+(alignment*0.45)*speedFactor if self.Name=="Head" then return Vector3_new(ballPos.X-(lVec.X*(0.12*dynamicMod)),ballPos.Y-1.0,ballPos.Z-(lVec.Z*(0.12*dynamicMod))) else if flatMag>0 then return Vector3_new(ballPos.X-((dx/flatMag)*(0.18*dynamicMod)),ballPos.Y-1.3,ballPos.Z-((dz/flatMag)*(0.18*dynamicMod))) end end end return Vector3_new(ballPos.X,ballPos.Y-1.3,ballPos.Z) end end end end end end return oldIndex(self,key) end))
local function touchDetect() local LocalPlayer=me local SoccerBall=getBall() if LocalPlayer and LocalPlayer.Character and SoccerBall then local UpperTorso=LocalPlayer.Character:FindFirstChild("UpperTorso") local Humanoid=LocalPlayer.Character:FindFirstChild("Humanoid") local HumanoidRootPart=LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if UpperTorso and Humanoid and HumanoidRootPart then local UpperTorsoPosition=UpperTorso.Position local SoccerBallPosition2=SoccerBall.Position local Magnitude=(SoccerBallPosition2-UpperTorsoPosition).Magnitude if Magnitude>0.01 and Magnitude<=(reachRange*1.5) then local v203=UpperTorsoPosition+Vector3.new(0,-3,0) local v204=UpperTorsoPosition+Vector3.new(0,1.2999999523162842,0) local n18=34 local v206 if (v204-SoccerBallPosition2).Magnitude<(v203-SoccerBallPosition2).Magnitude then v206=SoccerBallPosition2-v204 n18=0 else local v207=SoccerBallPosition2-v203 v206=Vector3.new(v207.X,0,v207.Z) end local Unit=v206.Unit if Unit.Magnitude>0.01 then local vector3=Vector3.new(0,0,0) local LookVector=HumanoidRootPart.CFrame.LookVector local Unit2=Vector3.new(LookVector.X,0,LookVector.Z).Unit local v212=math.atan2(Unit2.X,Unit2.Z)-math.atan2(Unit.X,Unit.Z) local v213=math.deg(math.abs(v212)) if v213<=20 then Unit=(Unit2+Unit).Unit end if v213<90 then local v214=v213/3 if not (v212<0) then vector3=Vector3.new(0,-v214,0) else vector3=Vector3.new(0,v214,0) end end local WalkSpeed=Humanoid.WalkSpeed if WalkSpeed<=23 then local vector3_2 if WalkSpeed>=19 then local v216=(WalkSpeed-19)*10+40 local vector3_3=Vector3.new(0,n18,0) local v218=v216+Vector3.new(SoccerBall.AssemblyLinearVelocity.X,0,SoccerBall.AssemblyLinearVelocity.Z).Magnitude if v218>85 then v218=85 end local v219=Unit*v218+vector3_3 vector3_2=Vector3.new(v219.X,math.min(v219.Y,40),v219.Z) else if WalkSpeed~=16 then vector3_2=Unit*((WalkSpeed-16)*15+25)+Vector3.new(0,5,0) else vector3_2=Unit*20+Vector3.new(0,0,0) end end local n9=0.5 if SoccerBall.Position.Y<n9 then pcall(function() SoccerBall.CFrame=CFrame.new(SoccerBall.Position.X,n9,SoccerBall.Position.Z) end) end pcall(function() local kb=ReplicatedStorage:FindFirstChild("KickBall") if kb then kb:FireServer(SoccerBall.Position,vector3_2,vector3,Magnitude,ValidKickKey) end end) end end end end end end
local visualFolder=Workspace:FindFirstChild(STEALTH_VISUALS)
if not visualFolder then visualFolder=Instance.new("Folder") visualFolder.Name=STEALTH_VISUALS visualFolder.Parent=Workspace end
local trajectoryVisualFolder=visualFolder:FindFirstChild("TrajectoryVisuals") or Instance.new("Folder")
trajectoryVisualFolder.Name="TrajectoryVisuals" trajectoryVisualFolder.Parent=visualFolder
local dropVisualFolder=visualFolder:FindFirstChild("DropSegments") or Instance.new("Folder")
dropVisualFolder.Name="DropSegments" dropVisualFolder.Parent=visualFolder
local activeTrajectoryDots={}
local function clearTrajectoryVisuals() trajectoryVisualFolder:ClearAllChildren() table.clear(activeTrajectoryDots) end
local function drawTrajectoryPath(points) for i=1,#points do local pos=points[i] local adjustedPos=Vector3.new(pos.X,math.max(pos.Y,5.473),pos.Z) if i==#points then local endSphere=Instance.new("Part") endSphere.Shape=predictionConfig.TrajectoryShape endSphere.Material=Enum.Material.Neon endSphere.Color=predictionConfig.TrajectoryRainbow and Color3.new(1,0,0) or predictionConfig.TrajectoryColor endSphere.Size=Vector3.new(2.4,2.4,2.4)*(predictionConfig.TrajectorySize/0.9) endSphere.Anchored=true endSphere.CanCollide=false endSphere.CastShadow=false endSphere.Position=adjustedPos endSphere.Parent=trajectoryVisualFolder else if i%2==0 then local dot=Instance.new("Part") dot.Shape=predictionConfig.TrajectoryShape dot.Material=Enum.Material.Neon dot.Size=Vector3.new(predictionConfig.TrajectorySize,predictionConfig.TrajectorySize,predictionConfig.TrajectorySize) dot.Anchored=true dot.CanCollide=false dot.CastShadow=false dot.Position=adjustedPos if not predictionConfig.TrajectoryRainbow then dot.Color=predictionConfig.TrajectoryColor end dot.Parent=trajectoryVisualFolder table.insert(activeTrajectoryDots,{instance=dot,offset=i/#points}) end end end end
local KickBallEvent=ReplicatedStorage:FindFirstChild("KickBallEvent")
if KickBallEvent then KickBallEvent.OnClientEvent:Connect(function(...) if not predictionConfig.TrajectoryPredictor then return end clearTrajectoryVisuals() local char=me.Character local handlerModule=char and char:FindFirstChild("BallHandler") if not handlerModule then return end local ok,BallHandler=pcall(getsenv,handlerModule) if not ok or not BallHandler or not BallHandler.recordBallAnimation then return end local args={...} local pos,vel,spin=args[2],args[3],args[4] if typeof(pos)~="Vector3" and typeof(args[1])=="Vector3" then pos,vel,spin=args[1],args[2],args[3] end if typeof(pos)=="Vector3" and typeof(vel)=="Vector3" then local pts pcall(function() pts=BallHandler.recordBallAnimation(pos,vel,spin or Vector3.zero) end) if pts and #pts>=2 then task.defer(function() drawTrajectoryPath(pts) end) end end end) end
local dropMarker=Instance.new("CylinderHandleAdornment")
dropMarker.Radius=predictionConfig.DropRadius dropMarker.Height=0.2
dropMarker.Color3=predictionConfig.DropColor dropMarker.Transparency=predictionConfig.DropTransparency
dropMarker.ZIndex=5 dropMarker.AlwaysOnTop=true
dropMarker.Adornee=Workspace.Terrain dropMarker.Parent=dropVisualFolder dropMarker.Visible=false
local function calculateLandingPosition(pos,vel,gravity,groundY) if vel.Y<=0 and pos.Y<=groundY+0.5 then return nil end local a=0.5*gravity local b=-vel.Y local c=-(pos.Y-groundY) local discriminant=b*b-4*a*c if discriminant<0 then return nil end local t1=(-b+math.sqrt(discriminant))/(2*a) local t2=(-b-math.sqrt(discriminant))/(2*a) local t=math.max(t1,t2) if t<0 then return nil end return pos+Vector3.new(vel.X*t,0,vel.Z*t)-Vector3.new(0,pos.Y-groundY,0) end
Bind(RunService.RenderStepped:Connect(function() if predictionConfig.TrajectoryPredictor and predictionConfig.TrajectoryRainbow and #activeTrajectoryDots>0 then local currentTick=tick()*1.5 for _,dotData in ipairs(activeTrajectoryDots) do if dotData.instance.Parent then local hue=(currentTick-dotData.offset)%1 dotData.instance.Color=Color3.fromHSV(hue,1,1) end end end if predictionConfig.DropPredictor then local ball=getBall() if ball and ball.Position.Y>6 and ball.AssemblyLinearVelocity.Magnitude>10 then local landingPos=calculateLandingPosition(ball.Position,ball.AssemblyLinearVelocity,55,5.473) if landingPos then dropMarker.CFrame=CFrame.new(landingPos)*CFrame.Angles(math.rad(90),0,0) dropMarker.Radius=predictionConfig.DropRadius dropMarker.Color3=predictionConfig.DropColor dropMarker.Transparency=predictionConfig.DropTransparency dropMarker.Visible=true else dropMarker.Visible=false end else dropMarker.Visible=false end else dropMarker.Visible=false end end))
local gkRunningConnections={}
local cachedGoalCenter=nil
local lastGoalUpdate=0
local function setupGK(character) local humanoid=character:WaitForChild("Humanoid",10) local rootPart=character:WaitForChild("HumanoidRootPart",10) if not humanoid or not rootPart then return end local function getDefendingGoalCenter() if cachedGoalCenter and (tick()-lastGoalUpdate)<5 then return cachedGoalCenter end local field=Workspace:FindFirstChild("FootballField") local targets=field and (field:FindFirstChild("Goals") or field) or Workspace local closestGoal=nil local minDistance=math.huge if rootPart then local myPos=rootPart.Position for _,obj in pairs(targets:GetDescendants()) do if obj:IsA("BasePart") and (obj.Name:lower():find("goal") or obj.Name:lower():find("net") or obj.Name:lower():find("post")) then local dist=(obj.Position-myPos).Magnitude if dist<minDistance then minDistance=dist closestGoal=obj end end end end lastGoalUpdate=tick() if not closestGoal and rootPart then cachedGoalCenter=rootPart.Position-Vector3.new(0,0,5) return cachedGoalCenter end cachedGoalCenter=closestGoal and closestGoal.Position or nil return cachedGoalCenter end local function isInsideGKBox(rootPos) local goalCenter=getDefendingGoalCenter() if not goalCenter then return true end local dx=math.abs(rootPos.X-goalCenter.X) local dz=(rootPos.Z-goalCenter.Z) local dy=rootPos.Y-goalCenter.Y return (dx<=gkConfig.boxWidth/2) and (math.abs(dz)<=gkConfig.boxDepth) and (dy<=gkConfig.boxHeight) end local lastBallVel=Vector3.new() local ballAccel=Vector3.new() local ballAccelConn=RunService.PostSimulation:Connect(function() local ball=getBall() if ball then local currentVel=ball.AssemblyLinearVelocity ballAccel=ballAccel:Lerp(currentVel-lastBallVel,0.25) lastBallVel=currentVel end end) local function isTrajectoryHeadingToGoal(ballPos,ballVel,goalCenter) if not goalCenter then return true end if ballVel.Magnitude<1.0 then return false end local directionToGoalLine=(goalCenter.Z-ballPos.Z) if (directionToGoalLine>0 and ballVel.Z<0) or (directionToGoalLine<0 and ballVel.Z>0) then return false end local timeToGoalPlane=(goalCenter.Z-ballPos.Z)/ballVel.Z if timeToGoalPlane<0 or timeToGoalPlane>8.0 then return false end local dist=(goalCenter-ballPos).Magnitude local useAccel=(dist>25) and ballAccel or Vector3.new() local predictedCrossX=ballPos.X+(ballVel.X*timeToGoalPlane)+(0.5*useAccel.X*timeToGoalPlane^2) local predictedCrossY=ballPos.Y+(ballVel.Y*timeToGoalPlane)-(0.5*workspace.Gravity*timeToGoalPlane^2) local goalWidthLimit=35 return (math.abs(predictedCrossX-goalCenter.X)<=goalWidthLimit) and (predictedCrossY>=-3 and predictedCrossY<=20) end local function getGKIntersection(ball,root,goalCenter) local ballPos=ball.Position local ballVel=ball.AssemblyLinearVelocity local rootPos=root.Position if ballVel.Magnitude<1.0 then return nil,0 end if not isTrajectoryHeadingToGoal(ballPos,ballVel,goalCenter) then return nil,0 end local pathVector=(rootPos-ballPos) local time=pathVector.Magnitude/ballVel.Magnitude if time<0 or time>8.0 then return nil,0 end local dist=pathVector.Magnitude local useAccel=(dist>25) and ballAccel or Vector3.new() local point=ballPos+(ballVel*time)+(0.5*useAccel*time^2)-Vector3.new(0,0.5*workspace.Gravity*time^2,0) local horizontalDist=(Vector3.new(point.X,0,point.Z)-Vector3.new(rootPos.X,0,rootPos.Z)).Magnitude local heightDelta=point.Y-rootPos.Y if horizontalDist<=120 and heightDelta>=0.2 and heightDelta<=20 then return point,time end return nil,0 end local function getGSIntersection(ball,root,goalCenter) local ballPos=ball.Position local ballVel=ball.AssemblyLinearVelocity local rootPos=root.Position if ballVel.Magnitude<1.0 then return nil end if not isTrajectoryHeadingToGoal(ballPos,ballVel,goalCenter) then local directDist=(rootPos-ballPos).Magnitude if directDist>30 then return nil end end local pathVector=(rootPos-ballPos) local time=pathVector.Magnitude/ballVel.Magnitude if time<0 or time>8.0 then return nil end local dist=pathVector.Magnitude local useAccel=(dist>25) and ballAccel or Vector3.new() local point=ballPos+(ballVel*time)+(0.5*useAccel*time^2)-Vector3.new(0,0.5*workspace.Gravity*time^2,0) local horizontalDist=(Vector3.new(point.X,0,point.Z)-Vector3.new(rootPos.X,0,rootPos.Z)).Magnitude local heightDelta=point.Y-rootPos.Y if horizontalDist<=120 and heightDelta>=-4.0 and heightDelta<=6.0 then return point end return nil end local function getInterceptVector(point,root,topCheck,isPenaltyMode) if topCheck then return Vector3.new(0,1,0) end local rootPos=root.Position local flatPoint=Vector3.new(point.X,rootPos.Y,point.Z) local diff=(flatPoint-rootPos) if diff.Magnitude<0.01 then return Vector3.new(0,0,0) end local dir=diff.Unit if isPenaltyMode then local goalCenter=getDefendingGoalCenter() if goalCenter then local vectorToGoal=(goalCenter-rootPos).Unit local lateralRight=Vector3.new(-vectorToGoal.Z,0,vectorToGoal.X).Unit local dot=dir:Dot(lateralRight) return lateralRight*dot end end return dir end local function kickBall(ball,root) local targetDir=(root.CFrame.LookVector*0.7+Vector3.new(0,0.4,0)).Unit pcall(function() ball.CanCollide=true ball.AssemblyLinearVelocity=targetDir*gkConfig.clearPower ball.AssemblyAngularVelocity=Vector3.new(0,0,0) end) local currentTool=character and character:FindFirstChildOfClass("Tool") if currentTool and currentTool:FindFirstChild("RemoteEvent") then currentTool.RemoteEvent:FireServer(ball,targetDir*gkConfig.clearPower) elseif ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Kick") then ReplicatedStorage.Remotes.Kick:FireServer(ball,targetDir*gkConfig.clearPower) end end local function processGoalkeeping() if not gkConfig.gkEnabled or gkConfig.isDiving or gkConfig.isGsDashing then return end local goalCenter=getDefendingGoalCenter() local ball=getBall() if not ball then return end local headingToGoal=isTrajectoryHeadingToGoal(ball.Position,ball.AssemblyLinearVelocity,goalCenter) if not headingToGoal then return end local directDist=(rootPart.Position-ball.Position).Magnitude local ballHeadingToMe=ball.AssemblyLinearVelocity.Unit:Dot((rootPart.Position-ball.Position).Unit)>0.45 local isCloseShot=(directDist<=40) or (directDist<=65 and ballHeadingToMe and ball.AssemblyLinearVelocity.Magnitude>22) if not isCloseShot and not isInsideGKBox(rootPart.Position) then return end local intersectPoint,timeToArrival=getGKIntersection(ball,rootPart,goalCenter) if not intersectPoint then return end local distToIntersect=(Vector3.new(intersectPoint.X,rootPart.Position.Y,intersectPoint.Z)-rootPart.Position).Magnitude local timeRequiredToReach=distToIntersect/gkConfig.diveSpeed if timeToArrival>timeRequiredToReach+0.35 then return end local localPoint=rootPart.CFrame:PointToObjectSpace(intersectPoint) local heightDelta=intersectPoint.Y-rootPart.Position.Y local isHighShot=(heightDelta>=5.5 and heightDelta<=19) local isPenaltyMode=(directDist<26) local safeVelocity=math.clamp(ball.AssemblyLinearVelocity.Magnitude,1,55) local arrivalThreshold=math.clamp((directDist/safeVelocity)*0.82,0.15,0.35) if isPenaltyMode then arrivalThreshold=arrivalThreshold*0.7 end local shouldPrejump=false if isCloseShot then shouldPrejump=isHighShot and (ball.AssemblyLinearVelocity.Magnitude>12) else shouldPrejump=(timeToArrival<=arrivalThreshold and isHighShot) end if shouldPrejump and humanoid:GetState()~=Enum.HumanoidStateType.Jumping and humanoid.FloorMaterial~=Enum.Material.Air then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) local upVelocity=isPenaltyMode and 12.0 or 18.5 rootPart.AssemblyLinearVelocity=Vector3.new(rootPart.AssemblyLinearVelocity.X,upVelocity,rootPart.AssemblyLinearVelocity.Z) end local isMidAir=(humanoid:GetState()==Enum.HumanoidStateType.Jumping or humanoid:GetState()==Enum.HumanoidStateType.FreeFall or humanoid.FloorMaterial==Enum.Material.Air) if (isMidAir or shouldPrejump or isCloseShot) and not gkConfig.isDiving then local topCheck=math.abs(localPoint.X)<=5.0 and localPoint.Y>2.8 gkConfig.isDiving=true local executionSpeed=gkConfig.diveSpeed if isPenaltyMode then executionSpeed=math.clamp(directDist*1.05,12,gkConfig.diveSpeed) end local moveVector=getInterceptVector(intersectPoint,rootPart,topCheck,isPenaltyMode) local bv=Instance.new("BodyVelocity") bv.Name="GK_StealthDive" bv.MaxForce=Vector3.new(160000,0,160000) bv.Velocity=Vector3.new(moveVector.X*executionSpeed,0,moveVector.Z*executionSpeed) bv.Parent=rootPart local loopConnection local creationTime=tick() local smoothVector=moveVector loopConnection=RunService.Heartbeat:Connect(function() local activeBall=getBall() local now=tick() local elapsed=(now-creationTime) if not activeBall or elapsed>1.0 or not gkConfig.isDiving then if elapsed>0.22 or not activeBall then gkConfig.isDiving=false task.spawn(function() if bv then for i=1,5 do if bv and bv.Parent then bv.Velocity=bv.Velocity*0.42 task.wait(0.01) end end if bv then bv:Destroy() end end end) loopConnection:Disconnect() return end end local liveIntersect,_=getGKIntersection(activeBall,rootPart,goalCenter) if not liveIntersect then liveIntersect=activeBall.Position+(activeBall.AssemblyLinearVelocity*0.12) end if liveIntersect and bv and bv.Parent and elapsed>0.15 then local realDir=getInterceptVector(liveIntersect,rootPart,topCheck,isPenaltyMode) smoothVector=smoothVector:Lerp(realDir,0.35) bv.Velocity=Vector3.new(smoothVector.X*executionSpeed,0,smoothVector.Z*executionSpeed) end local playerPos=rootPart.Position local ballPos=activeBall.Position local cylinderDist=Vector2.new(playerPos.X-ballPos.X,playerPos.Z-ballPos.Z).Magnitude local verticalDist=ballPos.Y-playerPos.Y local touchDistance=isPenaltyMode and 14.5 or 12.5 if (cylinderDist<=touchDistance and verticalDist>=-4.5 and verticalDist<=19) or (playerPos-ballPos).Magnitude<touchDistance then kickBall(activeBall,rootPart) gkConfig.isDiving=false if bv then bv:Destroy() end loopConnection:Disconnect() end end) end end local function handleGroundShot() if not gkConfig.gkEnabled or not gkConfig.gsEnabled or gkConfig.isGsDashing or gkConfig.isDiving then return end local ball=getBall() if not ball then return end local goalCenter=getDefendingGoalCenter() local headingToGoal=isTrajectoryHeadingToGoal(ball.Position,ball.AssemblyLinearVelocity,goalCenter) if not headingToGoal then return end local directDist=(rootPart.Position-ball.Position).Magnitude local ballHeadingToMe=ball.AssemblyLinearVelocity.Unit:Dot((rootPart.Position-ball.Position).Unit)>0.45 local isCloseShot=(directDist<=40) or (directDist<=65 and ballHeadingToMe and ball.AssemblyLinearVelocity.Magnitude>22) if not isCloseShot and not isInsideGKBox(rootPart.Position) then return end local intersectPoint=getGSIntersection(ball,rootPart,goalCenter) if not intersectPoint then return end local timeToHit=directDist/math.max(ball.AssemblyLinearVelocity.Magnitude,1) local distToIntersect=(Vector3.new(intersectPoint.X,rootPart.Position.Y,intersectPoint.Z)-rootPart.Position).Magnitude local timeRequiredToReach=distToIntersect/gkConfig.gsSpeed if timeToHit>timeRequiredToReach+0.35 then return end local localPoint=rootPart.CFrame:PointToObjectSpace(intersectPoint) local isFloorHit=(intersectPoint.Y-rootPart.Position.Y)<=2.5 local predHeight=ball.Position.Y+(ball.AssemblyLinearVelocity.Y*timeToHit)-(0.5*workspace.Gravity*timeToHit^2) local isLowBall=(predHeight-rootPart.Position.Y)<=3.8 if (isFloorHit or isLowBall or directDist<12) and math.abs(localPoint.X)>0.5 then gkConfig.isGsDashing=true local activeSpeed=gkConfig.gsSpeed if directDist<25 then activeSpeed=math.clamp(directDist*1.1,12,gkConfig.gsSpeed) elseif math.abs(ball.AssemblyLinearVelocity.X)>activeSpeed then activeSpeed=math.clamp(math.abs(ball.AssemblyLinearVelocity.X)*1.02,gkConfig.gsSpeed,gkConfig.diveSpeed) end local moveVector=getInterceptVector(intersectPoint,rootPart,false,(directDist<26)) local bv=Instance.new("BodyVelocity") bv.Name="GS_StealthDash" bv.MaxForce=Vector3.new(140000,0,140000) bv.Velocity=Vector3.new(moveVector.X*activeSpeed,0,moveVector.Z*activeSpeed) bv.Parent=rootPart local loopConnection local creationTime=tick() local smoothVector=moveVector loopConnection=RunService.Heartbeat:Connect(function() local activeBall=getBall() local now=tick() local elapsed=(now-creationTime) if not activeBall or not gkConfig.isGsDashing or elapsed>1.0 then if elapsed>0.18 or not activeBall then gkConfig.isGsDashing=false task.spawn(function() if bv then for i=1,4 do if bv and bv.Parent then bv.Velocity=bv.Velocity*0.45 task.wait(0.01) end end if bv then bv:Destroy() end end end) loopConnection:Disconnect() return end end local liveIntersect=getGSIntersection(activeBall,rootPart,goalCenter) if not liveIntersect then liveIntersect=activeBall.Position+(activeBall.AssemblyLinearVelocity*0.10) end if elapsed>0.12 then local realDir=getInterceptVector(liveIntersect,rootPart,false,(directDist<26)) smoothVector=smoothVector:Lerp(realDir,0.35) end if bv and bv.Parent then bv.Velocity=Vector3.new(smoothVector.X*activeSpeed,0,smoothVector.Z*activeSpeed) end local touchDistance=(directDist<25) and 12.5 or 10.5 if (rootPart.Position-activeBall.Position).Magnitude<touchDistance then kickBall(activeBall,rootPart) gkConfig.isGsDashing=false if bv then bv:Destroy() end loopConnection:Disconnect() end end) end end local gsConnection=RunService.Heartbeat:Connect(handleGroundShot) local gkConnection=RunService.Heartbeat:Connect(processGoalkeeping) humanoid.StateChanged:Connect(function(oldState,newState) if (newState==Enum.HumanoidStateType.Landed or newState==Enum.HumanoidStateType.Running) and not gkConfig.isDiving and not gkConfig.isGsDashing then gkConfig.isDiving=false gkConfig.isGsDashing=false local existingBv=rootPart:FindFirstChild("GK_StealthDive") or rootPart:FindFirstChild("GS_StealthDash") if existingBv then existingBv:Destroy() end end end) character.Destroying:Connect(function() if gsConnection then gsConnection:Disconnect() end if gkConnection then gkConnection:Disconnect() end if ballAccelConn then ballAccelConn:Disconnect() end end) end
me.CharacterAdded:Connect(function(char) task.delay(1,function() setupGK(char) end) end)
if me.Character then task.spawn(function() setupGK(me.Character) end) end
local function isTeammateAimPass(player) local myChar=me.Character local theirChar=player.Character if myChar and theirChar then local myTorso=myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso") local theirTorso=theirChar:FindFirstChild("Torso") or theirChar:FindFirstChild("UpperTorso") if myTorso and theirTorso then return myTorso.BrickColor==theirTorso.BrickColor end end if player.Team and me.Team then return player.Team==me.Team end return false end
local function isValidTargetAimPass(player) if player==me then return false end if aimPassConfig.teammatesOnly then return isTeammateAimPass(player) end return true end
local GoalA=Vector3.new(-315,12,93)
local GoalB=Vector3.new(-114,12,93)
local function getLookAtTarget() local bestTarget=nil local maxDot=-math.huge local camCFrame=Workspace.CurrentCamera.CFrame for _,p in ipairs(Players:GetPlayers()) do if isValidTargetAimPass(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local dir=(p.Character.HumanoidRootPart.Position-camCFrame.Position).Unit local dot=camCFrame.LookVector:Dot(dir) if dot>maxDot and dot>0.75 then maxDot=dot bestTarget=p end end end return bestTarget end
local function getTacticalTarget() local myRoot=me.Character and me.Character:FindFirstChild("HumanoidRootPart") if not myRoot then return nil end local myLook=myRoot.CFrame.LookVector local oppGoal=((GoalB-myRoot.Position).Unit:Dot(myLook)>(GoalA-myRoot.Position).Unit:Dot(myLook)) and GoalB or GoalA local bestTarget=nil local minDist=math.huge for _,p in ipairs(Players:GetPlayers()) do if isValidTargetAimPass(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local dist=(p.Character.HumanoidRootPart.Position-oppGoal).Magnitude if dist<minDist then minDist=dist bestTarget=p end end end return bestTarget end
local currentTargetPlayer=nil
local targetHighlight=Instance.new("Highlight")
targetHighlight.Name=randString(12)
targetHighlight.FillColor=Color3.fromRGB(50,255,50)
targetHighlight.OutlineColor=Color3.fromRGB(255,255,255)
targetHighlight.FillTransparency=0.5
targetHighlight.Adornee=nil
targetHighlight.Parent=SecureUI
local highlightFolder=Instance.new("Folder",Workspace)
highlightFolder.Name=randString(12)
local function getAimPassTarget() if not aimPassConfig.enabled then currentTargetPlayer=nil return nil end if aimPassConfig.targetMode=="Look At" then currentTargetPlayer=getLookAtTarget() elseif aimPassConfig.targetMode=="Tactical (Goal)" then currentTargetPlayer=getTacticalTarget() elseif aimPassConfig.assignedPositions[aimPassConfig.targetMode] then currentTargetPlayer=aimPassConfig.assignedPositions[aimPassConfig.targetMode] if currentTargetPlayer and not currentTargetPlayer.Parent then currentTargetPlayer=nil end else currentTargetPlayer=Players:FindFirstChild(aimPassConfig.targetMode) end if currentTargetPlayer and currentTargetPlayer.Character then if isTeammateAimPass(currentTargetPlayer) then targetHighlight.FillColor=Color3.fromRGB(50,255,50) else targetHighlight.FillColor=Color3.fromRGB(255,50,50) end targetHighlight.Adornee=currentTargetPlayer.Character else targetHighlight.Adornee=nil end return currentTargetPlayer end
Bind(RunService.RenderStepped:Connect(function() getAimPassTarget() end))
local KickBallRemote=ReplicatedStorage:WaitForChild("KickBall")
local pendingPassVelocity=nil
local pendingPassSpin=nil
local pendingPassTime=0
local hookedFunctions={}
local aimPassCooldown_u2=0
local aimPassCooldown_u3=0
local aimPass_u10=5.473
local function startAnimation(p153,p154,p155,p156,p157) pendingPassVelocity=p154 pendingPassSpin=p155 pendingPassTime=tick() end
local function hookAnimations() task.spawn(function() for _,func in pairs(getgc(true)) do if type(func)=="function" and islclosure(func) and not hookedFunctions[func] then local successInfo,info=pcall(debug.getinfo,func) if successInfo and info and info.numparams==3 then local successConst,constants=pcall(debug.getconstants,func) if successConst and type(constants)=="table" then for _,val in pairs(constants) do if val==161.748 or val==23.443 or val==-45 then hookedFunctions[func]=true local oldRecordAnimation oldRecordAnimation=hookfunction(func,newcclosure(function(pos,velocity,spin) if aimPassConfig.enabled and pendingPassVelocity and (tick()-pendingPassTime<0.5) then velocity=pendingPassVelocity spin=pendingPassSpin pendingPassVelocity=nil end return oldRecordAnimation(pos,velocity,spin) end)) break end end end end end end end) end
local function onCharacterRespawnAimPass(character) hookAnimations() end
me.CharacterAdded:Connect(onCharacterRespawnAimPass)
if me.Character then onCharacterRespawnAimPass(me.Character) end
local function aimPassTouchDetect() if not aimPassConfig.enabled then return end if not me.Character then return end local ball=getBall() if not ball then return end if tick()-aimPassCooldown_u2>=0.6 and tick()-aimPassCooldown_u3>=0.3 then local UpperTorso=me.Character:FindFirstChild("UpperTorso") or me.Character:FindFirstChild("HumanoidRootPart") if not UpperTorso then return end local Position=UpperTorso.Position local Position2=ball.Position local Magnitude=(Position2-Position).Magnitude if Magnitude>0.01 and Magnitude<=4 then if not currentTargetPlayer or not currentTargetPlayer.Character then return end local targetRoot=currentTargetPlayer.Character:FindFirstChild("HumanoidRootPart") if not targetRoot then return end aimPassCooldown_u2=tick() local targetPos=targetRoot.Position local targetVel=targetRoot.AssemblyLinearVelocity if aimPassConfig.throughBallEnabled then if targetVel.Magnitude>3 then local moveDirection=Vector3.new(targetVel.X,0,targetVel.Z).Unit targetPos=targetPos+(moveDirection*aimPassConfig.throughBallDistance) else local lookDirection=Vector3.new(targetRoot.CFrame.LookVector.X,0,targetRoot.CFrame.LookVector.Z).Unit targetPos=targetPos+(lookDirection*aimPassConfig.throughBallDistance) end else targetPos=targetPos+(targetVel*0.4) end local distToTarget=(targetPos-Position2).Magnitude local v180=Vector3.new(targetPos.X-Position2.X,0,targetPos.Z-Position2.Z) local Unit=v180.Unit if Unit.Magnitude>0.01 then local Humanoid=me.Character:FindFirstChildOfClass("Humanoid") local WalkSpeed=Humanoid and Humanoid.WalkSpeed or 16 local maxLegalPower=85 if WalkSpeed>=19 then maxLegalPower=(WalkSpeed-19)*10+40+Vector3.new(ball.AssemblyLinearVelocity.X,0,ball.AssemblyLinearVelocity.Z).Magnitude elseif WalkSpeed==16 then maxLegalPower=20 else maxLegalPower=(WalkSpeed-16)*15+25 end local distanceScale=math.clamp(distToTarget/120,0,1) local requiredPower=aimPassConfig.minPower+(distanceScale*(aimPassConfig.maxPassPower-aimPassConfig.minPower)) local finalPower=math.min(requiredPower,maxLegalPower) local v187 local v182=Vector3.new(0,0,0) local isLob=(WalkSpeed>17) or (finalPower>=70) if isLob then local lobScale=math.clamp(distToTarget/150,0,1) local lobHeight=10+(lobScale*(aimPassConfig.lobHeight-10)) local v190=Unit*finalPower+Vector3.new(0,lobHeight,0) v187=Vector3.new(v190.X,math.min(v190.Y,aimPassConfig.lobHeight),v190.Z) else v187=Unit*finalPower end if v187.Magnitude>85 then v187=v187.Unit*85 end if ball.Position.Y<aimPass_u10 then pcall(function() ball.CFrame=CFrame.new(ball.Position.X,aimPass_u10,ball.Position.Z) end) end AimPassCachedVel=v187 AimPassCachedRot=v182 AimPassActive=true KickBallRemote:FireServer(ball.Position,v187,v182,Magnitude,ValidKickKey) startAnimation(ball.Position,v187,v182,Vector3.new(0,0,0),0) end end end end
Bind(RunService.Heartbeat:Connect(function() pcall(aimPassTouchDetect) end))
Bind(RunService.Heartbeat:Connect(function() pcall(touchDetect) end))

-- ═══════════════════════════════════════
-- AIRFLOW UI
-- ═══════════════════════════════════════
local AirFlow = loadstring(game:HttpGet("https://raw.githubusercontent.com/7ox/airflow/main/source.lua"))()

local Window = AirFlow:CreateWindow({
    Name = "Novex Hub",
    Subtitle = "Novex Hub",
    Size = UDim2.fromOffset(580, 440),
    Theme = "Default",
    Toggleable = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Elements = {}

-- ── AIMBOT TAB ──
local TabAimbot = Window:CreateTab({ Name = "Aimbot" })
TabAimbot:Section("Main Aimbot Engine")
Elements.ToggleAimbotConfig = TabAimbot:Toggle({
    Name = "Enable Aimbot", Default = false,
    Callback = function(v) aimbotConfig.enabled = v if v and Elements.RandomCurve then Elements.RandomCurve:Set(false) end end
})
Elements.AimbotRandomAim = TabAimbot:Toggle({
    Name = "Random Aim (Best Position)", Default = false,
    Callback = function(v) aimbotConfig.randomAim = v end
})
Elements.AimbotFurthestCorner = TabAimbot:Toggle({
    Name = "Furthest Top Corner", Default = false,
    Callback = function(v) aimbotConfig.furthestCorner = v end
})
Elements.AimbotCorner = TabAimbot:Dropdown({
    Name = "Target Corner",
    Options = {"Center","TopRight","TopLeft","BottomRight","BottomLeft"},
    Default = "Center",
    Callback = function(v) aimbotConfig.corner = v end
})
Elements.AimbotMissChance = TabAimbot:Toggle({
    Name = "8% Miss Chance (Legit)", Default = false,
    Callback = function(v) aimbotConfig.missChanceEnabled = v end
})
Elements.AimbotMaxPower = TabAimbot:Input({
    Name = "Max Kick Power (20-150)", Placeholder = "90",
    Callback = function(v) local n=tonumber(v) if n then aimbotConfig.maxPower=math.clamp(n,20,150) end end
})
TabAimbot:Section("Curve Aimbot")
Elements.EnableCurveAimbot = TabAimbot:Toggle({
    Name = "Enable Curve Aimbot", Default = false,
    Callback = function(v) aimbotConfig.curveEnabled = v end
})
Elements.CurvePower = TabAimbot:Slider({
    Name = "Curve Power", Min = 5, Max = 50, Default = 15, Step = 1,
    Callback = function(v) aimbotConfig.curvePower = v end
})
Elements.AimbotTopCorner = TabAimbot:Toggle({
    Name = "Top Corner Mode", Default = false,
    Callback = function(v) aimbotConfig.topCornerMode = v end
})
TabAimbot:Section("Goal Detection")
Elements.AimbotAutoDetect = TabAimbot:Toggle({
    Name = "Auto-Detect Enemy Goal", Default = true,
    Callback = function(v) aimbotConfig.autoDetectGoal = v end
})
TabAimbot:Button({
    Name = "Force Refresh Goal Detection",
    Callback = function()
        cachedGoalParts = {}
        if aimbotConfig.autoDetectGoal then
            aimbotConfig.goal = detectEnemyGoal()
            NotifyUser("Detection Refreshed","Locked onto Goal: "..tostring(aimbotConfig.goal))
        else
            NotifyUser("Auto-Detect Off","Enable Auto-Detect first.")
        end
    end
})
Elements.AimbotManualGoal = TabAimbot:Dropdown({
    Name = "Manual Goal Selection", Options = {"A","B"}, Default = "B",
    Callback = function(v) if not aimbotConfig.autoDetectGoal then aimbotConfig.goal = v end end
})

-- ── REACH TAB ──
local TabReach = Window:CreateTab({ Name = "Reach" })
TabReach:Section("Reach Customization")
Elements.ToggleReach = TabReach:Toggle({
    Name = "Enable Reach", Default = false,
    Callback = function(v) reachActive = v forceHitboxUpdate() end
})
Elements.ToggleReachPriority = TabReach:Toggle({
    Name = "Enable Reach Priority", Default = true,
    Callback = function(v) reachPriorityEnabled = v forceHitboxUpdate() end
})
Elements.ReachRadiusSlider = TabReach:Slider({
    Name = "Reach Radius", Min = 1, Max = 10, Default = 4.6, Step = 0.1,
    Callback = function(v) reachRange = v end
})
Elements.ToggleReachMagnet = TabReach:Toggle({
    Name = "Reach Magnet (Smooth Pull)", Default = true,
    Callback = function(v) reachMagnetActive = v end
})
Elements.ReachMaxStepSlider = TabReach:Slider({
    Name = "Max Step Size", Min = 0.5, Max = 5.0, Default = 2.0, Step = 0.1,
    Callback = function(v) reachMaxStep = v end
})
Elements.ReachHoldDistSlider = TabReach:Slider({
    Name = "Hold Distance", Min = 0.5, Max = 4.0, Default = 1.5, Step = 0.1,
    Callback = function(v) reachHoldDistance = v end
})

-- ── AIMPASS TAB ──
local TabAimPass = Window:CreateTab({ Name = "AimPass" })
TabAimPass:Section("AimPass Main")
local AimPassTargetDropdown
local AimPassPosDropdowns = {}
local function UpdateAimPassPlayerLists()
    local mainList = {"Look At","Tactical (Goal)","RW","LW","CDM","GK"}
    local posList = {"None"}
    for _,p in ipairs(Players:GetPlayers()) do
        if isValidTargetAimPass(p) then
            table.insert(mainList, p.Name)
            table.insert(posList, p.Name)
        end
    end
    if AimPassTargetDropdown then AimPassTargetDropdown:Refresh(mainList, true) end
    for _,dd in pairs(AimPassPosDropdowns) do if dd then dd:Refresh(posList, true) end end
end
Elements.ToggleAimPass = TabAimPass:Toggle({
    Name = "Enable AimPass", Default = false,
    Callback = function(v) aimPassConfig.enabled = v end
})
Elements.ToggleAimPassTeammates = TabAimPass:Toggle({
    Name = "Teammates Only", Default = true,
    Callback = function(v) aimPassConfig.teammatesOnly = v UpdateAimPassPlayerLists() end
})
AimPassTargetDropdown = TabAimPass:Dropdown({
    Name = "Active Target Override",
    Options = {"Look At","Tactical (Goal)","RW","LW","CDM","GK"},
    Default = "Look At",
    Callback = function(v) aimPassConfig.targetMode = v end
})
TabAimPass:Button({ Name = "Refresh Player List", Callback = function() UpdateAimPassPlayerLists() end })
TabAimPass:Section("Position Assignments")
local positionsToCreate = {"RW","LW","CDM","GK"}
local defaultKeys = {RW="Z",LW="X",CDM="C",GK="V"}
for _,pos in ipairs(positionsToCreate) do
    TabAimPass:Section(pos.." Assign & Bind")
    AimPassPosDropdowns[pos] = TabAimPass:Dropdown({
        Name = "Assign "..pos, Options = {"None"}, Default = "None",
        Callback = function(v)
            if v=="None" then aimPassConfig.assignedPositions[pos]=nil
            else aimPassConfig.assignedPositions[pos]=Players:FindFirstChild(v) end
        end
    })
    TabAimPass:Keybind({
        Name = "Target "..pos, Default = defaultKeys[pos],
        Callback = function()
            if aimPassConfig.assignedPositions[pos] then
                aimPassConfig.targetMode = pos
                if AimPassTargetDropdown then AimPassTargetDropdown:Set(pos) end
            end
        end
    })
end
UpdateAimPassPlayerLists()
TabAimPass:Section("Physics & Power")
Elements.ToggleAimPassThroughBall = TabAimPass:Toggle({
    Name = "Through Balls", Default = false,
    Callback = function(v) aimPassConfig.throughBallEnabled = v end
})
Elements.SliderAimPassThroughDist = TabAimPass:Slider({
    Name = "Through Ball Distance", Min = 5, Max = 60, Default = 25, Step = 1,
    Callback = function(v) aimPassConfig.throughBallDistance = v end
})
Elements.SliderAimPassMinPower = TabAimPass:Slider({
    Name = "Min Pass Power", Min = 10, Max = 85, Default = 35, Step = 1,
    Callback = function(v) aimPassConfig.minPower = v end
})
Elements.SliderAimPassMaxPower = TabAimPass:Slider({
    Name = "Max Pass Power", Min = 10, Max = 85, Default = 75, Step = 1,
    Callback = function(v) aimPassConfig.maxPassPower = v end
})
Elements.SliderAimPassLobHeight = TabAimPass:Slider({
    Name = "Max Lob Height", Min = 15, Max = 100, Default = 45, Step = 1,
    Callback = function(v) aimPassConfig.lobHeight = v end
})

-- ── GOALKEEPER TAB ──
local TabGoalkeeper = Window:CreateTab({ Name = "Goalkeeper" })
TabGoalkeeper:Section("Auto Goalkeeper")
Elements.ToggleGK = TabGoalkeeper:Toggle({
    Name = "Auto GK", Default = false,
    Callback = function(v) gkConfig.gkEnabled = v end
})
Elements.ToggleGS = TabGoalkeeper:Toggle({
    Name = "Auto GS (Ground Shots)", Default = false,
    Callback = function(v) gkConfig.gsEnabled = v end
})
Elements.SliderDiveSpeed = TabGoalkeeper:Slider({
    Name = "Dive Speed", Min = 10, Max = 40, Default = 25, Step = 1,
    Callback = function(v) gkConfig.diveSpeed = v end
})
Elements.SliderGSSpeed = TabGoalkeeper:Slider({
    Name = "GS Speed", Min = 10, Max = 40, Default = 22, Step = 1,
    Callback = function(v) gkConfig.gsSpeed = v end
})
Elements.SliderClearPower = TabGoalkeeper:Slider({
    Name = "Clear Power", Min = 40, Max = 120, Default = 85, Step = 5,
    Callback = function(v) gkConfig.clearPower = v end
})
Elements.ToggleGKReach = TabGoalkeeper:Toggle({
    Name = "GK Reach Assist", Default = false,
    Callback = function(v) gkConfig.reachEnabled = v end
})
Elements.SliderGKReach = TabGoalkeeper:Slider({
    Name = "GK Reach Range", Min = 1, Max = 8, Default = 3, Step = 0.5,
    Callback = function(v) gkConfig.reachRange = v end
})
TabGoalkeeper:Section("GK Box Size")
Elements.SliderBoxWidth = TabGoalkeeper:Slider({
    Name = "Box Width", Min = 50, Max = 200, Default = 140, Step = 5,
    Callback = function(v) gkConfig.boxWidth = v end
})
Elements.SliderBoxDepth = TabGoalkeeper:Slider({
    Name = "Box Depth", Min = 20, Max = 100, Default = 60, Step = 5,
    Callback = function(v) gkConfig.boxDepth = v end
})
Elements.SliderBoxHeight = TabGoalkeeper:Slider({
    Name = "Box Height", Min = 10, Max = 50, Default = 32, Step = 2,
    Callback = function(v) gkConfig.boxHeight = v end
})

-- ── SKILLS TAB ──
local TabSkills = Window:CreateTab({ Name = "Skills" })
TabSkills:Section("Sneaky")
Elements.ToggleSneaky = TabSkills:Toggle({
    Name = "Enable Sneaky", Default = false,
    Callback = function(v) sneakyActive = v forceHitboxUpdate() end
})
Elements.SneakyModeDrop = TabSkills:Dropdown({
    Name = "Sneaky Mode", Options = {"Low","Medium","High"}, Default = "High",
    Callback = function(v) sneakyMode = v end
})
Elements.SafeSneaky = TabSkills:Toggle({
    Name = "Safe Sneaky (Anti-Intercept)", Default = true,
    Callback = function(v) safeSneaky = v end
})
Elements.SneakyReachSlider = TabSkills:Slider({
    Name = "Sneaky Reach", Min = 1, Max = 7, Default = 4.6, Step = 0.1,
    Callback = function(v) sneakyReach = v end
})
Elements.SneakyBufferSlider = TabSkills:Slider({
    Name = "Sneaky Buffer", Min = 0.1, Max = 1.0, Default = 0.45, Step = 0.05,
    Callback = function(v) sneakyBuffer = v end
})
Elements.SneakyHeight = TabSkills:Slider({
    Name = "Sneaky Height Offset", Min = -3.0, Max = 3.0, Default = 0, Step = 0.1,
    Callback = function(v) sneakyHeightOffset = v end
})
TabSkills:Section("Professional Sneaky")
Elements.TProSneaky = TabSkills:Toggle({
    Name = "Pro Sneaky Customization", Default = false,
    Callback = function(v) profSneaky.enabled = v end
})
Elements.ProCloseDist = TabSkills:Slider({ Name = "Close Range Max Dist", Min = 1, Max = 5, Default = 2.0, Step = 0.1, Callback = function(v) profSneaky.closeMax = v end })
Elements.ProMidDist = TabSkills:Slider({ Name = "Mid Range Max Dist", Min = 2, Max = 10, Default = 3.5, Step = 0.1, Callback = function(v) profSneaky.midMax = v end })
Elements.ProCloseY = TabSkills:Slider({ Name = "Close Hit Height Y", Min = -3.0, Max = 3.0, Default = -1.0, Step = 0.1, Callback = function(v) profSneaky.closeY = v end })
Elements.ProMidY = TabSkills:Slider({ Name = "Mid Hit Height Y", Min = -3.0, Max = 3.0, Default = 0.0, Step = 0.1, Callback = function(v) profSneaky.midY = v end })
Elements.ProFarY = TabSkills:Slider({ Name = "Far Hit Height Y", Min = -3.0, Max = 3.0, Default = 1.0, Step = 0.1, Callback = function(v) profSneaky.farY = v end })
Elements.ProVariance = TabSkills:Slider({ Name = "Random Height Variance", Min = 0.0, Max = 2.0, Default = 0.5, Step = 0.1, Callback = function(v) profSneaky.randomVariance = v end })
TabSkills:Section("Pokers")
Elements.TogglePokers = TabSkills:Toggle({
    Name = "Enable Pokers", Default = false,
    Callback = function(v) pokersActive = v local char=me.Character local hum=char and char:FindFirstChild("Humanoid") if not v and hum then hum.WalkSpeed=23 end end
})
Elements.SliderPokerSpeed = TabSkills:Slider({ Name = "Poker Speed", Min = 10, Max = 23, Default = 16, Step = 1, Callback = function(v) pokerSpeed = v end })
TabSkills:Section("Auto Juggle Pro")
Elements.ToggleAutoJuggle = TabSkills:Toggle({
    Name = "Enable Auto Juggle Pro", Default = false,
    Callback = function(v) autoJuggleActive = v forceHitboxUpdate() end
})
Elements.AutoJuggleReach = TabSkills:Slider({ Name = "Auto Juggle Reach", Min = 1, Max = 7, Default = 4.6, Step = 0.1, Callback = function(v) autoJuggleReach = v end })
Elements.AutoJuggleHeight = TabSkills:Slider({ Name = "Juggle Height", Min = 1, Max = 6, Default = 1.5, Step = 0.1, Callback = function(v) autoJuggleHeight = v end })
Elements.AutoJuggleSticky = TabSkills:Slider({ Name = "Sticky Pull", Min = 0, Max = 5, Default = 2.0, Step = 0.1, Callback = function(v) autoJuggleSticky = v end })

-- ── SCRIPTS TAB ──
local TabScripts = Window:CreateTab({ Name = "Scripts" })
TabScripts:Section("Special Shots")
Elements.AutoNeroToggle = TabScripts:Toggle({
    Name = "Auto Nero", Default = false,
    Callback = function(v) aimbotConfig.autoNero = v aimbotConfig.neroSequence = 0 end
})
Elements.NeroFurthestCornerToggle = TabScripts:Toggle({
    Name = "Nero Furthest Corner", Default = false,
    Callback = function(v) aimbotConfig.neroFurthestCorner = v end
})
Elements.AutoNeroTimeout = TabScripts:Slider({ Name = "Auto Nero Timeout (s)", Min = 0.5, Max = 5.0, Default = 1.5, Step = 0.1, Callback = function(v) aimbotConfig.neroTimeout = v end })
Elements.AutoHeaderToggle = TabScripts:Toggle({
    Name = "Auto Header", Default = false,
    Callback = function(v) aimbotConfig.autoHeader = v end
})
TabScripts:Section("Manual Functions")
Elements.RandomCurve = TabScripts:Toggle({
    Name = "Random Curve", Default = false,
    Callback = function(v)
        aimbotConfig.curveOnlyEnabled = v
        if v and Elements.ToggleAimbotConfig then Elements.ToggleAimbotConfig:Set(false) end
    end
})
TabScripts:Section("Ground Control")
Elements.ToggleGroundShots = TabScripts:Toggle({
    Name = "Enable Ground Shots", Default = false,
    Callback = function(v) groundShotsActive = v forceHitboxUpdate() end
})
Elements.GroundShotsReach = TabScripts:Slider({ Name = "Ground Shots Reach", Min = 1, Max = 7, Default = 5.5, Step = 0.1, Callback = function(v) groundShotsReach = v end })
TabScripts:Section("Utility Features")
Elements.ToggleAimlock = TabScripts:Toggle({
    Name = "Ball Aimlock", Default = false,
    Callback = function(v) aimlockEnabled = v end
})
TabScripts:Button({ Name = "Bring Ball To You", Callback = function() bringBall() end })

-- Anti Phase
local antiPhaseActive = false
local antiPhaseConfig = {Multiplier=25.0, ActivationRadius=150}
local antiPhaseHitbox = Instance.new("Part")
antiPhaseHitbox.Name = randString(12)
antiPhaseHitbox.Size = Vector3.new(12,12,12)
antiPhaseHitbox.CanCollide = false
antiPhaseHitbox.Massless = true
antiPhaseHitbox.Anchored = true
antiPhaseHitbox.Transparency = 1
antiPhaseHitbox.Color = Color3.fromRGB(255,50,50)
antiPhaseHitbox.Position = Vector3.new(0,-1000,0)
antiPhaseHitbox.Parent = Workspace
Elements.ToggleAntiPhase = TabScripts:Toggle({
    Name = "Strong Anti-Phase", Default = false,
    Callback = function(v)
        antiPhaseActive = v
        if not v then antiPhaseHitbox.Position = Vector3.new(0,-1000,0) end
    end
})
Bind(RunService.RenderStepped:Connect(function()
    pcall(function()
        if not antiPhaseActive then return end
        local character = me.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not character or not rootPart or not humanoid or humanoid.Health<=0 then return end
        local targetBall = getBall()
        if not targetBall then antiPhaseHitbox.Position = Vector3.new(0,-1000,0) return end
        local distance = (targetBall.Position - rootPart.Position).Magnitude
        if distance > antiPhaseConfig.ActivationRadius then antiPhaseHitbox.Position = Vector3.new(0,-1000,0) return end
        local flatTorsoPos = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
        local flatBallPos = Vector3.new(targetBall.Position.X, 0, targetBall.Position.Z)
        local direction = (flatBallPos - flatTorsoPos).Unit
        if direction.X == direction.X and (flatBallPos - flatTorsoPos).Magnitude > 0.01 then
            local newPos = flatTorsoPos + (direction * antiPhaseConfig.Multiplier)
            antiPhaseHitbox.Position = Vector3.new(newPos.X, rootPart.Position.Y, newPos.Z)
            antiPhaseHitbox.CFrame = CFrame.lookAt(antiPhaseHitbox.Position, Vector3.new(targetBall.Position.X, antiPhaseHitbox.Position.Y, targetBall.Position.Z))
        end
    end)
end))

-- Ball Aimlock Logic
Bind(RunService.RenderStepped:Connect(function()
    if not aimlockEnabled then return end
    pcall(function()
        local char = me.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local ball = getBall()
        if not ball then return end
        local cam = Workspace.CurrentCamera
        local ballPos = ball.Position
        local camPos = cam.CFrame.Position
        local direction = (ballPos - camPos).Unit
        cam.CFrame = CFrame.new(camPos, camPos + direction)
    end)
end))

-- Rank Portals
local rankPortals = {["Elite"]=16876418704, ["Pro"]=16452698027}
local portalNames = {}
for name in pairs(rankPortals) do table.insert(portalNames, name) end
table.sort(portalNames)
local selectedPortal = portalNames[1]
TabScripts:Section("Rank Bypasser")
Elements.RankBypassDropdown = TabScripts:Dropdown({
    Name = "Select Gamemode", Options = portalNames, Default = selectedPortal,
    Callback = function(v) selectedPortal = v end
})
TabScripts:Button({
    Name = "Teleport to Gamemode (Lowest Ping)",
    Callback = function()
        local placeId = rankPortals[selectedPortal]
        if placeId then
            NotifyUser("Teleporting","Joining "..selectedPortal.." (Lowest MS)...")
            TeleportToLowestPingServer(placeId)
        end
    end
})

-- ── VISUALS TAB ──
local TabVisuals = Window:CreateTab({ Name = "Visuals" })
TabVisuals:Section("Fun Visuals")
local rainbowCharActive = false
local ballHighlightActive = false
local ballTrailActive = false
local currentHighlight = nil
local currentTrail = nil
local att0, att1 = nil, nil
local cachedCharParts = {}
local function updateCharCache()
    if not me.Character then return end
    cachedCharParts = {}
    for _,part in ipairs(me.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
            table.insert(cachedCharParts, {inst=part, origColor=part.Color, origMat=part.Material})
        end
    end
end
me.CharacterAdded:Connect(function() task.delay(0.5, updateCharCache) end)
if me.Character then task.delay(0.5, updateCharCache) end
Elements.ToggleRGBChar = TabVisuals:Toggle({
    Name = "RGB Character (Neon Glow)", Default = false,
    Callback = function(v)
        rainbowCharActive = v
        if not v and me.Character then
            task.spawn(function()
                for _,data in ipairs(cachedCharParts) do
                    if data.inst and data.inst.Parent then
                        data.inst.Color = data.origColor
                        data.inst.Material = data.origMat
                    end
                end
            end)
        end
    end
})
Elements.ToggleBallESP = TabVisuals:Toggle({
    Name = "Ball ESP (Highlight)", Default = false,
    Callback = function(v)
        ballHighlightActive = v
        if not v and currentHighlight then currentHighlight:Destroy() currentHighlight = nil end
    end
})
Elements.ToggleBallTrail = TabVisuals:Toggle({
    Name = "Ball Trail", Default = false,
    Callback = function(v)
        ballTrailActive = v
        if not v then
            if currentTrail then currentTrail:Destroy() end
            if att0 then att0:Destroy() end
            if att1 then att1:Destroy() end
        end
    end
})
TabVisuals:Section("Field Visuals")
local fieldParts = {}
local function cacheFieldParts()
    table.clear(fieldParts)
    local field = Workspace:FindFirstChild("FootballField") or Workspace
    for _,part in ipairs(field:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name:lower():find("grass") or part.Name:lower():find("field") or part.Name:lower():find("ground")) then
            table.insert(fieldParts, part)
        end
    end
end
cacheFieldParts()
Elements.FieldColorPicker = TabVisuals:Dropdown({
    Name = "Field Color",
    Options = {"Default","Red","Blue","Purple","Black","White","Pink","Orange","Cyan"},
    Default = "Default",
    Callback = function(opt)
        local colors = {Default=Color3.fromRGB(50,140,50),Red=Color3.fromRGB(140,30,30),Blue=Color3.fromRGB(30,30,140),Purple=Color3.fromRGB(100,30,140),Black=Color3.fromRGB(20,20,20),White=Color3.fromRGB(200,200,200),Pink=Color3.fromRGB(200,100,150),Orange=Color3.fromRGB(200,120,30),Cyan=Color3.fromRGB(30,180,180)}
        task.spawn(function()
            for _,part in ipairs(fieldParts) do if part and part.Parent then part.Color = colors[opt] end end
        end)
    end
})
Elements.TimeOfDaySlider = TabVisuals:Slider({
    Name = "Time of Day", Min = 0, Max = 24, Default = Lighting.ClockTime, Step = 0.5,
    Callback = function(v) Lighting.ClockTime = v end
})
local hue = 0
Bind(RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        hue = (hue + dt * 0.3) % 1
        local currentRainbowColor = Color3.fromHSV(hue,1,1)
        if rainbowCharActive and me.Character then
            for _,data in ipairs(cachedCharParts) do
                if data.inst and data.inst.Parent then
                    data.inst.Color = currentRainbowColor
                    data.inst.Material = Enum.Material.Neon
                end
            end
        end
        if ballHighlightActive then
            local ball = getBall()
            if ball and (not currentHighlight or currentHighlight.Parent~=ball) then
                if currentHighlight then currentHighlight:Destroy() end
                currentHighlight = Instance.new("Highlight")
                currentHighlight.FillColor = Color3.fromRGB(220,20,60)
                currentHighlight.OutlineColor = Color3.fromRGB(255,182,193)
                currentHighlight.FillTransparency = 0.5
                currentHighlight.Parent = ball
            end
        end
        if ballTrailActive then
            local ball = getBall()
            if ball and ball:IsA("BasePart") and (not currentTrail or currentTrail.Parent~=ball) then
                if currentTrail then currentTrail:Destroy() end
                if att0 then att0:Destroy() end
                if att1 then att1:Destroy() end
                att0 = Instance.new("Attachment", ball) att0.Position = Vector3.new(0,0.5,0)
                att1 = Instance.new("Attachment", ball) att1.Position = Vector3.new(0,-0.5,0)
                currentTrail = Instance.new("Trail", ball)
                currentTrail.Attachment0 = att0
                currentTrail.Attachment1 = att1
                currentTrail.Color = ColorSequence.new(Color3.fromRGB(255,182,193), Color3.fromRGB(220,20,60))
                currentTrail.Lifetime = 0.5
                currentTrail.MinLength = 0.1
            end
        end
    end)
end))

-- ── PERFORMANCE TAB ──
local TabPerformance = Window:CreateTab({ Name = "Performance" })
TabPerformance:Section("FPS Engine")
Elements.ToggleFPSBoost = TabPerformance:Toggle({
    Name = "Smart FPS Booster", Default = false,
    Callback = function(v)
        if v then
            task.spawn(function()
                local protectedNames={"field","grass","goal","ball","soccer","football","torso","head","humanoid","root"}
                for _,obj in ipairs(Workspace:GetDescendants()) do
                    local name=obj.Name:lower()
                    local shouldProtect=false
                    for _,pn in ipairs(protectedNames) do if name:find(pn) then shouldProtect=true break end end
                    if not shouldProtect then
                        if name:find("crowd") or name:find("audience") or name:find("spectator") or name:find("bench") or name:find("billboard") or name:find("ad") or name:find("sign") or name:find("tree") or name:find("plant") or name:find("bush") or name:find("fence") or name:find("railing") or name:find("light") or name:find("lamp") or name:find("pole") or name:find("flag") or name:find("banner") then
                            pcall(function() obj:Destroy() end)
                        end
                        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then obj.Enabled=false end
                        if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") and not shouldProtect then obj.Material=Enum.Material.SmoothPlastic obj.Reflectance=0 end
                        if obj:IsA("Decal") or obj:IsA("Texture") then if name:find("ad") or name:find("logo") or name:find("sponsor") then pcall(function() obj:Destroy() end) end end
                    end
                end
                Lighting.GlobalShadows=false Lighting.FogEnd=9e9 Lighting.Brightness=2
                Workspace.Terrain.Decoration=false Workspace.Terrain.WaterWaveSize=0 Workspace.Terrain.WaterWaveSpeed=0
                Workspace.CurrentCamera.FieldOfView=70
                NotifyUser("FPS Booster","Game cleaned.")
            end)
        end
    end
})

-- ── KEYBINDS TAB ──
local TabKeybinds = Window:CreateTab({ Name = "Keybinds" })
TabKeybinds:Section("PC Keybinds")
Elements.KB_Reach = TabKeybinds:Keybind({ Name = "Reach", Default = "None", Callback = function() if Elements.ToggleReach then Elements.ToggleReach:Set(not reachActive) end end })
Elements.KB_Sneaky = TabKeybinds:Keybind({ Name = "Sneaky", Default = "None", Callback = function() if Elements.ToggleSneaky then Elements.ToggleSneaky:Set(not sneakyActive) end end })
Elements.KB_Pokers = TabKeybinds:Keybind({ Name = "Pokers", Default = "None", Callback = function() if Elements.TogglePokers then Elements.TogglePokers:Set(not pokersActive) end end })
Elements.KB_Juggle = TabKeybinds:Keybind({ Name = "Auto Juggle", Default = "None", Callback = function() if Elements.ToggleAutoJuggle then Elements.ToggleAutoJuggle:Set(not autoJuggleActive) end end })
Elements.KB_Ground = TabKeybinds:Keybind({ Name = "Ground Shots", Default = "None", Callback = function() if Elements.ToggleGroundShots then Elements.ToggleGroundShots:Set(not groundShotsActive) end end })
Elements.KB_Aimbot = TabKeybinds:Keybind({ Name = "Main Aimbot", Default = "None", Callback = function() if Elements.ToggleAimbotConfig then Elements.ToggleAimbotConfig:Set(not aimbotConfig.enabled) end end })
Elements.KB_CurveAimbot = TabKeybinds:Keybind({ Name = "Curve Aimbot", Default = "None", Callback = function() if Elements.EnableCurveAimbot then Elements.EnableCurveAimbot:Set(not aimbotConfig.curveEnabled) end end })
Elements.KB_RandCurve = TabKeybinds:Keybind({ Name = "Random Curve", Default = "None", Callback = function() if Elements.RandomCurve then Elements.RandomCurve:Set(not aimbotConfig.curveOnlyEnabled) end end })
Elements.KB_AutoNero = TabKeybinds:Keybind({ Name = "Auto Nero", Default = "None", Callback = function() if Elements.AutoNeroToggle then Elements.AutoNeroToggle:Set(not aimbotConfig.autoNero) end end })
Elements.KB_AutoHeader = TabKeybinds:Keybind({ Name = "Auto Header", Default = "None", Callback = function() if Elements.AutoHeaderToggle then Elements.AutoHeaderToggle:Set(not aimbotConfig.autoHeader) end end })
Elements.KB_AntiPhase = TabKeybinds:Keybind({ Name = "Anti-Phase", Default = "None", Callback = function() if Elements.ToggleAntiPhase then Elements.ToggleAntiPhase:Set(not antiPhaseActive) end end })
Elements.KB_Aimlock = TabKeybinds:Keybind({ Name = "Ball Aimlock", Default = "None", Callback = function() if Elements.ToggleAimlock then Elements.ToggleAimlock:Set(not aimlockEnabled) end end })
Elements.KB_BringBall = TabKeybinds:Keybind({ Name = "Bring Ball", Default = "None", Callback = function() bringBall() end })
Elements.KB_AimPassToggle = TabKeybinds:Keybind({ Name = "Toggle AimPass", Default = "None", Callback = function() if Elements.ToggleAimPass then Elements.ToggleAimPass:Set(not aimPassConfig.enabled) end end })
Elements.KB_AutoGK = TabKeybinds:Keybind({ Name = "Toggle Auto GK", Default = "None", Callback = function() if Elements.ToggleGK then Elements.ToggleGK:Set(not gkConfig.gkEnabled) end end })
Elements.KB_AutoGS = TabKeybinds:Keybind({ Name = "Toggle Auto GS", Default = "None", Callback = function() if Elements.ToggleGS then Elements.ToggleGS:Set(not gkConfig.gsEnabled) end end })

-- ── SETTINGS TAB ──
local TabSettings = Window:CreateTab({ Name = "Settings" })
TabSettings:Section("Server Tools")
TabSettings:Button({
    Name = "Auto Rejoin Server",
    Callback = function()
        task.spawn(function()
            local currentPlaceId = game.PlaceId
            pcall(function() TeleportService:Teleport(currentPlaceId, me) end)
        end)
    end
})
Elements.ToggleLowestMS = TabSettings:Toggle({
    Name = "Auto Best Server (Lowest Ping)", Default = false,
    Callback = function(v) lowestMSServerActive = v end
})
TabSettings:Section("Safety & Utilities")
Elements.AntiAFKToggle = TabSettings:Toggle({
    Name = "Anti-AFK (Undetected)", Default = false,
    Callback = function(v) antiAFKActive = v end
})
Bind(Players.LocalPlayer.Idled:Connect(function()
    if antiAFKActive then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end))
TabSettings:Button({
    Name = "Force Respawn Character",
    Callback = function()
        local char = me.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
})
TabSettings:Button({
    Name = "Destroy Script UI",
    Callback = function()
        pcall(function() Window:Destroy() end)
    end
})

-- ── PREDICTIONS TAB ──
local TabPredictions = Window:CreateTab({ Name = "Predictions" })
TabPredictions:Section("Trajectory")
Elements.ToggleTrajectory = TabPredictions:Toggle({
    Name = "Trajectory Predictor", Default = false,
    Callback = function(v) predictionConfig.TrajectoryPredictor = v if not v then clearTrajectoryVisuals() end end
})
Elements.ToggleRainbow = TabPredictions:Toggle({
    Name = "Rainbow Mode", Default = true,
    Callback = function(v) predictionConfig.TrajectoryRainbow = v end
})
Elements.ColorTrajectory = TabPredictions:ColorPicker({
    Name = "Trajectory Color", Default = Color3.fromRGB(255,255,255),
    Callback = function(v) predictionConfig.TrajectoryColor = v end
})
Elements.SliderTrajectorySize = TabPredictions:Slider({
    Name = "Trajectory Size", Min = 0.2, Max = 3.0, Default = 0.9, Step = 0.1,
    Callback = function(v) predictionConfig.TrajectorySize = v end
})
Elements.DropdownShape = TabPredictions:Dropdown({
    Name = "Trajectory Shape", Options = {"Ball","Block","Cylinder"}, Default = "Ball",
    Callback = function(v)
        if v=="Ball" then predictionConfig.TrajectoryShape = Enum.PartType.Ball
        elseif v=="Block" then predictionConfig.TrajectoryShape = Enum.PartType.Block
        elseif v=="Cylinder" then predictionConfig.TrajectoryShape = Enum.PartType.Cylinder end
    end
})
TabPredictions:Section("Drop Predictor")
Elements.ToggleDropPredictor = TabPredictions:Toggle({
    Name = "Real-Time Drop Predictor", Default = false,
    Callback = function(v) predictionConfig.DropPredictor = v end
})
Elements.ColorDrop = TabPredictions:ColorPicker({
    Name = "Drop Marker Color", Default = Color3.fromRGB(255,40,40),
    Callback = function(v) predictionConfig.DropColor = v end
})
Elements.SliderDropRadius = TabPredictions:Slider({
    Name = "Drop Marker Radius", Min = 1.0, Max = 10.0, Default = 3.8, Step = 0.5,
    Callback = function(v) predictionConfig.DropRadius = v end
})

-- ── DEFENCE TAB ──
local TabDefence = Window:CreateTab({ Name = "Defence" })
TabDefence:Section("Defence")
TabDefence:Label({ Text = "Defence features coming soon." })

-- ── PRO MODE TAB ──
local TabProMode = Window:CreateTab({ Name = "Pro Mode" })
TabProMode:Section("Pro Mode")
TabProMode:Label({ Text = "Pro Mode features coming soon." })

-- ── CONFIG TAB ──
local TabConfig = Window:CreateTab({ Name = "Config" })
TabConfig:Section("Configuration")
TabConfig:Label({ Text = "Configs are managed directly through the Airflow UI." })
TabConfig:Label({ Text = "Use the built-in save/load system in the UI toggle menu (RightControl)." })
