local version = 0.02
local scriptName = "beatenByALittleGirl"
SourceUpdater(scriptName, version, "raw.github.com", "/gnomgrol/BeatenByALittleGirl/master/beatenByALittleGirl.lua", SCRIPT_PATH..GetCurrentEnv().FILE_NAME, "/gnomgrol/BeatenByALittleGirl/master/beatenByALittleGirl.version"):CheckUpdate()


require "AllClass"



if myHero.charName ~= "Annie" then return end

        
local hasIgnite, hasFlash = nil, nil
if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then hasIgnite = SUMMONER_1 end
if myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then hasIgnite = SUMMONER_2 end
if myHero:GetSpellData(SUMMONER_1).name:find("SummonerFlash") then hasFlash = SUMMONER_1 end
if myHero:GetSpellData(SUMMONER_2).name:find("SummonerFlash") then hasFlash = SUMMONER_2 end



local flashUltPos, optimalConePos = nil, nil
local ultiRange, ultiRadius, range, wRadius = 600, 230, 620, 200
local wRange, wAngle = 600, 45
local fRange = 400

local stunReady, existTibbers = false, false
local ts = TargetSelector(TARGET_LOW_HP, range )
local flashTs = TargetSelector(TARGET_LOW_HP, range+fRange )
local enemyList = {}
local combos = {}
local DCConfig
local enemysInRange = {}

local tibbersObj = nil


function OnLoad()



	print("[---] FUTURE SCRIPT: Beaten by a little girl test[---]")
	
	DCConfig = scriptConfig("Beaten by a little girl", "UJISTD")
	DCConfig:addSubMenu("General: ", "general")
	DCConfig.general:addParam("autoCarryKey", "Infight Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte(" "))
	DCConfig.general:addParam("flashComboKey", "Full commit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	DCConfig.general:addParam("mouseWalk", "Mousewalk when infight", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.general:addParam("autoZhonyas", "Auto-Zhonyas on low hp when attacked", SCRIPT_PARAM_ONOFF, true, 32)
	
	DCConfig:addSubMenu("Lasthitting: ", "cs")
	DCConfig.cs:addParam("lasthitWithQ", "Lasthit with Q", SCRIPT_PARAM_LIST, 1, {"Always", "Never", "No enemys close" })
	DCConfig.cs:addParam("useStunToLasthit", "Use stun to lasthit", SCRIPT_PARAM_LIST, 3, {"Always", "Never", "No enemys close" })
	DCConfig.cs:addParam("lasthitHealthEnemy", "Only lasthit if enemy health over: ", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
	DCConfig.cs:addParam("lasthitHealthMe", "Only lasthit if own health over: ", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
	
	
	DCConfig:addSubMenu("Ultimate: ", "ult")
	DCConfig.ult:addParam("finishKills", "Finish low people with combo", SCRIPT_PARAM_ONOFF, false, 32)
	DCConfig.ult:addParam("whenToIgnite", "Use Ignite in attack", SCRIPT_PARAM_LIST, 2, {"SBTW", "Only with ult", "Never" })
	DCConfig.ult:addParam("useAutoUlt", "Auto flash-stun-ult:", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.ult:addParam("autoUltCount", "Auto flash-stun-ult if hits:", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	
	
	DCConfig:addSubMenu("Harass: ", "harass")
	DCConfig.harass:addParam("autoE", "Auto-E when attacked", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.harass:addParam("autoQ", "Auto-Q to harass", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.harass:addParam("autoW", "Auto-W to harass", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.harass:addParam("autoHarassCount", "Only harass if enemys less than:", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)

	
	DCConfig:addSubMenu("Render: ", "render")
	DCConfig.render:addParam("renderUltMarker", "Render best-ult marker:", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.render:addParam("enemyRadius", "Enemys 'close' radius:", SCRIPT_PARAM_SLICE, 2000, 500, 4000, 0)
	DCConfig.render:addParam("renderFlashUltRange", "Render flash-ult range:", SCRIPT_PARAM_ONOFF, true, 32)
	DCConfig.render:addParam("renderComboRange", "Render combo range:", SCRIPT_PARAM_ONOFF, true, 32)
	
	
	for i = 1, heroManager.iCount, 1 do
		local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then
			table.insert(enemyList, hero)
		end
	end
end





function OnTick()

	ts:update()
	flashTs:update()
	
	if isRecalling(myHero) then return end

	if DCConfig.render.enemyRadius == nil then
	DCConfig.render.enemyRadius = 2000
	end
	
	local closest = DCConfig.render.enemyRadius+1
	enemysInRange = {}
	local enemysInRangeCount = 0
	local lowestEnemyHealth = 101
	
	
	for _, hero in pairs(enemyList) do
		local dist = myHero:GetDistance(hero)
		if myHero:GetDistance(hero) < closest and myHero:GetDistance(hero) > 0 and not hero.dead and hero.visible then
			closest = myHero:GetDistance(hero)
		end
		if myHero:GetDistance(hero) < DCConfig.render.enemyRadius and myHero:GetDistance(hero) > 0 and ValidTarget(hero, DCConfig.enemyRadius) then
			table.insert(enemysInRange, hero)
			enemysInRangeCount = enemysInRangeCount+1
			if hero.health/hero.maxHealth*100 < lowestEnemyHealth then
				lowestEnemyHealth = hero.health/hero.maxHealth*100
			end
		end
	end
	
	for _, hero in pairs(enemyList) do
		if DCConfig.ult.finishKills and enemysInRangeCount < 3 then 
			if fullComboDmg(hero) > hero.health and stunReady then
				if myHero:GetDistance(hero) > range and myHero:GetDistance(hero) < range+fRange then
					CastSpell(hasFlash, hero.x, hero.z)				
				end
				fullCombo(true)
			end
		end
	end
	
	if DCConfig.general.autoCarryKey then
		fullCombo(false)
	end
	
	
	if DCConfig.general.flashComboKey then

		if ValidTarget(flashTs.target) then
			if stunReady then
				if myHero:GetDistance(flashTs.target) > range then
					CastSpell(hasFlash, flashTs.target.x,flashTs.target.z)				
				end
				CastSpell(_Q, flashTs.target)
				fullCombo(true)
			else
				fullCombo(true)
			end
		end
	end	
	
	

	
	-- AUTO Q HARASS and W on multitarget 
	optimalConePos = getOptimalPosCone(wRange, wAngle)

	if stunReady then
		if enemysInRangeCount < 2 then
			if DCConfig.harass.autoQ and myHero:CanUseSpell(_Q) == READY and ValidTarget(ts.target, range) then
				CastSpell(_Q, ts.target)
			end		
		else
			if optimalConePos ~= nil and optimalConePos.hits > DCConfig.ult.autoUltCount then
				CastSpell(_W, optimalConePos.pos.x, optimalConePos.pos.z)
			end		
		end
	else
		if enemysInRangeCount < DCConfig.harass.autoHarassCount then
			if DCConfig.harass.autoQ and myHero:CanUseSpell(_Q) == READY and ValidTarget(ts.target, range) then
				CastSpell(_Q, ts.target)			
			end
		
			if DCConfig.harass.autoW and myHero:CanUseSpell(_W) == READY and ValidTarget(ts.target, wRange) then
				if enemysInRangeCount < 2 and not ts.target.canMove then
					CastSpell(_W, ts.target)	
				else
					if optimalConePos ~= nil and optimalConePos.hits > 1 then
						CastSpell(_W, optimalConePos.pos.x, optimalConePos.pos.z)
					end
				end
			end
		end
	end
	
	
	
	
	-- if enemy tibbers!
	--[[if tibbersObj ~= nil and tibbersObj.team ~= myHero.team then
		print(tibbersObj.team)
		tibbersObj = nil
		existTibbers = false
	end]]
	
	-- tibbers autoattack
	if ValidTarget(ts.target) and existTibbers then
		local tD = GetDistance(tibbersObj, ts.target)
		if tD > 300 and myHero:CanUseSpell(_R) == READY then
			CastSpell(_R, ts.target)
		end
	end	

	
	-- AUTO FLASH ULT
	if DCConfig.ult.useAutoUlt then
		flashUltPos = getOptimalPos(ultiRange+fRange, ultiRadius)
			
		if flashUltPos ~= nil and flashUltPos.hits >= DCConfig.ult.autoUltCount then
			if stunReady and myHero:CanUseSpell(_R) == READY and not existTibbers then
				
				local vec = flashUltPos.pos
				if GetDistance(myHero.pos, vec) > ultiRange then
					CastSpell(hasFlash, flashUltPos.pos.x, flashUltPos.pos.z)
				end
				CastSpell(_R, flashUltPos.pos.x,flashUltPos.pos.z)
			end
		end
	end
	
	

	
	
	
	-- LASTHITTING
	if myHero.health/myHero.maxHealth*100 < DCConfig.cs.lasthitHealthMe and enemysInRangeCount > 0 then return end
	if lowestEnemyHealth < DCConfig.cs.lasthitHealthEnemy then return end
	if DCConfig.general.autoCarryKey then return end --dont lasthit when infight mode
	if DCConfig.general.flashComboKey then return end
	
	if DCConfig.cs.lasthitWithQ == 1 or DCConfig.cs.lasthitWithQ == 3 then
		local enemyMinions = minionManager(MINION_ENEMY, range, player, MINION_SORT_HEALTH_ASC)
		for i, minion in pairs(enemyMinions.objects) do
			if minion ~= nil then
				lowestMinion = minion
				break;
			end
		end
		
		
		if ValidTarget(lowestMinion) and myHero:CanUseSpell(_Q) == READY and lowestMinion.health < getDmg("Q",lowestMinion,myHero) then
			if myHero:GetDistance(lowestMinion) < range then
				
				if not stunReady then
					if DCConfig.cs.lasthitWithQ == 1 then
						CastSpell(_Q, lowestMinion)
					else
						if closest > DCConfig.render.enemyRadius then
							CastSpell(_Q, lowestMinion)
						end
					end
				else
					if DCConfig.cs.useStunToLasthit == 1 then
						CastSpell(_Q, lowestMinion)
					end
					if DCConfig.cs.useStunToLasthit == 3 then
						if closest > DCConfig.render.enemyRadius then
							CastSpell(_Q, lowestMinion)
						end						
					end					
				end
				
			end
		end
	end
	-- LASTHITTING END
end
	



function OnDraw()
	if not myHero.dead then
		if DCConfig.render.renderComboRange then
		DrawCircle(myHero.x, myHero.y, myHero.z, range, ARGB(100, 0, 150, 255))
		end
		if DCConfig.render.renderFlashUltRange then
		DrawCircle(myHero.x, myHero.y, myHero.z, ultiRange+fRange, ARGB(100, 0, 150, 255))
		end
	end
	
	
	if flashUltPos ~= nil and DCConfig.ult.useAutoUlt and DCConfig.render.renderUltMarker and myHero:CanUseSpell(_R) == READY and not existTibbers then
		DrawText3D(tostring(flashUltPos.hits) .. " hits - Dmg: " .. tostring(math.floor(flashUltPos.dmg)),flashUltPos.pos.x, flashUltPos.pos.y, flashUltPos.pos.z, 16, RGB(255,255,255), true)
		DrawCircle(flashUltPos.pos.x, flashUltPos.pos.y, flashUltPos.pos.z, ultiRadius, 0x444400)
	end

	
	
	for _, hero in pairs(enemyList) do
		if ValidTarget(hero, DCConfig.render.enemyRadius) then

			
			if fullComboDmg(hero) > hero.health then
				DrawText3D("CAN KILL",hero.x, hero.y+100, hero.z, 16, RGB(255,255,255), true)
			end
			
		end
	end
	
	
end



function fullCombo(fullCommit)
	-- WOMBO COMBO
	if DCConfig.general.mouseWalk then
	myHero:MoveTo(mousePos.x,mousePos.z)
	end
	
	if ValidTarget(ts.target, range) then
	
		if fullCommit then
			DFGSlot = GetInventorySlotItem(3128)
			DFGREADY = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
			if DFGREADY then CastSpell(DFGSlot, ts.target) end
		end
				
		CastSpell(_Q, ts.target)
		
		if optimalConePos ~= nil and optimalConePos.hits > 1 then
			CastSpell(_W, optimalConePos.pos.x, optimalConePos.pos.z)
		else
			CastSpell(_W, ts.target)
		end
		
		CastSpell(_E)
		
		if myHero:CanUseSpell(_R) == READY and not existTibbers and fullCommit then -- and stunReady
			
			local p = getOptimalPos(ultiRange, ultiRadius)
			if p ~= nil then
			
				CastSpell(_R, p.pos.x,p.pos.z)
				
				if DCConfig.ult.whenToIgnite == 2 then
					if hasIgnite ~= nil then
						CastSpell(hasIgnite, ts.target) 
					end	
				end
				
				--else cast anyway?
			end
			
		end
		
		if DCConfig.ult.whenToIgnite == 1 and fullCommit then
			if hasIgnite ~= nil then
				CastSpell(hasIgnite, ts.target) 
			end	
		end
		
	end
	-- WOMBO COMBO END

end





function OnProcessSpell(unit, spell)
	
	

	if unit ~= nil and spell ~= nil then
		if not (spell.name:find("Minion_") or spell.name:find("Odin")) then
		
			if spell.target == myHero and unit.team ~= myHero.team then
				if myHero:CanUseSpell(_E) == READY  and DCConfig.harass.autoE then
					CastSpell(_E)
				end
				
				if DCConfig.general.autoZhonyas then
					local ZhonyaSlot = GetInventorySlotItem(3157)
					ZhonyaREADY = (ZhonyaSlot ~= nil and myHero:CanUseSpell(ZhonyaSlot) == READY)
					
					if myHero.health/myHero.maxHealth < 0.25 and ZhonyaREADY then
						CastSpell(ZhonyaSlot)
					end
				end
				
			end
		end
	end
end


-- IS STUN READY OR EXISTS TIBBERS ??
function OnCreateObj(object)

        if object.name == "StunReady.troy" then stunReady = true end
        
		if object.name == "AnnieTibbers_Idle_body.troy" then 

			existTibbers = true
			tibbersObj = object

		end
end
 
 
function OnDeleteObj(object)
        if object.name == "StunReady.troy" then stunReady = false end
        if object.name == "AnnieTibbers_Idle_body.troy" then
			existTibbers = false 
			tibbersObj = nil
		end  
	
end



function isInCircle(center, point, radius)
	if point == nil or center == nil or radius == nil then return false end
	
	local testIfInCircle = (point.x - center.x)*(point.x - center.x) + (point.z - center.z)*(point.z - center.z)
	if testIfInCircle < radius*radius then
		return true
	else
		return false
	end
end


-- CALCULATES THE OPTIMAL POSITION FOR ULTERINO
function getOptimalPos(rangeIn, radiusIn)
	
	local possibleUltPositions = {}
	
	local enemysInUltRange = {}
	local enemysInUltRangeCount = 0
	for _, hero in pairs(enemyList) do
		local dist = myHero:GetDistance(hero)
		if myHero:GetDistance(hero) < rangeIn and myHero:GetDistance(hero) > 0 and not hero.dead and hero.visible then
			table.insert(enemysInUltRange, hero)
			enemysInUltRangeCount = enemysInUltRangeCount+1
		end	
	end
	
	if enemysInUltRangeCount == 0 then
		return nil
	end
	
	if enemysInUltRangeCount == 1 then
		return {pos = enemysInUltRange[1].pos, dmg = getDmg("R",enemysInUltRange[1],myHero), hits = 1}
	end
	
	
	combos= {}
		
	local pass = {}
	local passNum = 0
	for c, enemy in pairs(enemysInUltRange) do
		table.insert(pass, c)
		passNum = passNum + 1
	end
	for d, enemy in pairs(enemysInUltRange) do
		--if d ~= 0 then
		combinations(pass, {}, 0, passNum, 0, d)
		--end
	end
	
	
	for l, com in pairs(combos) do
		local currentCombHeros = {}
		for s, id in pairs(com) do
			table.insert(currentCombHeros, enemysInUltRange[s])
		end
		
		
		local finalPos = {x = 0, y = 0, z = 0}
		
		for _, hero in pairs(currentCombHeros) do
			local dist = myHero:GetDistance(hero)
			if dist < rangeIn and dist > 0 and not hero.dead and hero.visible then
				if finalPos.x == 0 then 
					finalPos.x = hero.x 
					finalPos.y = hero.y 
					finalPos.z = hero.z
				else
					finalPos.x = ( hero.x + finalPos.x ) / 2
					finalPos.y = ( hero.y + finalPos.y ) / 2
					finalPos.z = ( hero.z + finalPos.z ) / 2
				end
			end
		end
		
		local allInCircle = true
		local dmgDone, currentCombHerosNum = 0, 0
		for _, hero in pairs(currentCombHeros) do
			if not isInCircle(finalPos, hero.pos, radiusIn) then 
				allInCircle = false
			else
				dmgDone = dmgDone + getDmg("R",hero,myHero)
				currentCombHerosNum = currentCombHerosNum + 1
			end
		end
		
		if allInCircle then
			table.insert(possibleUltPositions, {pos = finalPos, dmg = dmgDone, hits = currentCombHerosNum}) 
		end	
		
	end
	
	local highestDmgOutput = 0
	local bestLocation 
	for _, location in pairs(possibleUltPositions) do
		if location.dmg > highestDmgOutput then
			bestLocation = location
		end
	end

	return bestLocation
end



function getOptimalPosCone(rangeIn, angle)

	local possibleConePositions = {}
	
	local enemysInConeRange = {}
	local enemysInConeRangeCount = 0
	for _, hero in pairs(enemyList) do
		local dist = myHero:GetDistance(hero)
		if myHero:GetDistance(hero) < rangeIn and myHero:GetDistance(hero) > 0 and not hero.dead and hero.visible then
			table.insert(enemysInConeRange, hero)
			enemysInConeRangeCount = enemysInConeRangeCount+1
		end	
	end
	
	if enemysInConeRangeCount == 0 then
		return nil
	end
	
	if enemysInConeRangeCount == 1 then
		return {pos = enemysInConeRange[1].pos, dmg = getDmg("W",enemysInConeRange[1],myHero), hits = 1}
	end
	
	
	combos= {}
		
	local pass = {}
	local passNum = 0
	for c, enemy in pairs(enemysInConeRange) do
		table.insert(pass, c)
		passNum = passNum + 1
	end
	for d, enemy in pairs(enemysInConeRange) do
		--if d ~= 0 then
		combinations(pass, {}, 0, passNum, 0, d)
		--end
	end
	
	
	for l, com in pairs(combos) do
		local currentCombHeros = {}
		for s, id in pairs(com) do
			table.insert(currentCombHeros, enemysInConeRange[s])
		end
		
		
		
		local finalPos = {x = 0, y = 0, z = 0}
		
		
		for _, hero in pairs(currentCombHeros) do
			local dist = myHero:GetDistance(hero)
			if dist < rangeIn and dist > 0 and not hero.dead and hero.visible then
				if finalPos.x == 0 then 
					finalPos.x = hero.x 
					finalPos.y = hero.y 
					finalPos.z = hero.z
				else
					finalPos.x = ( hero.x + finalPos.x ) / 2
					finalPos.y = ( hero.y + finalPos.y ) / 2
					finalPos.z = ( hero.z + finalPos.z ) / 2
				end
			end
		end
		
		
		local dir = {x = myHero.x - finalPos.x, y = myHero.y - finalPos.y, z = myHero.z - finalPos.z}
		
		local allInCone = true
		local dmgDone, currentCombHerosNum = 0, 0
		for _, hero in pairs(currentCombHeros) do
			if not CheckPointInCone(dir, angle, hero.pos)then
				allInCone = false
				
			else
				dmgDone = dmgDone + getDmg("W",hero,myHero)
				currentCombHerosNum = currentCombHerosNum + 1
			end
		end
		
		if allInCone then
			table.insert(possibleConePositions, {pos = finalPos, dmg = dmgDone, hits = currentCombHerosNum}) 
		end	
		
	end
	
	local highestNumHit = 0
	local bestLocation 
	for _, location in pairs(possibleConePositions) do
		if location.hits > highestNumHit then
			bestLocation = location
			highestNumHit = location.hits
		end
	end

	return bestLocation

end



function fullComboDmg(hero)

	if not ValidTarget(hero) then
		return 0
	end


	local fullComboDmg = 0
	
	DFGSlot = GetInventorySlotItem(3128)
	DFGREADY = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	if DFGREADY then fullComboDmg = fullComboDmg + getDmg("DFG",hero,myHero) end
	
	if myHero:CanUseSpell(_Q) == READY then
		fullComboDmg = fullComboDmg + getDmg("Q",hero,myHero)
	end
	if myHero:CanUseSpell(_W) == READY then
		fullComboDmg = fullComboDmg + getDmg("W",hero,myHero)
	end
	if myHero:CanUseSpell(_R) == READY then
		fullComboDmg = fullComboDmg + getDmg("R",hero,myHero)
	end
	if hasIgnite ~= nil and myHero:CanUseSpell(hasIgnite) then 
		fullComboDmg = fullComboDmg + getDmg("IGNITE",hero,myHero)
	end
	return fullComboDmg
end




-- GET NUM OF POINTS IN CONE
	function CheckPointInCone(direction, angle, point)
		angle = (angle < math.pi * 2) and angle or (angle * math.pi / 180)

		local dir = Vector(myHero.pos - point):normalized()
		local pos = Vector(direction):normalized()
		
		local v = dir:dotP(pos)
		local av = math.acos(v)
		
		if av < (angle) then
			return true
		else
			return false
		end
		
	end
-- GET NUM OF POINTS IN CONE -- END

	
function isRecalling(hero)
	if hero ~= nil and hero.valid then 
		for i = 1, hero.buffCount, 1 do
			local buff = hero:getBuff(i)
			if buff == "Recall" or buff == "SummonerTeleport" or buff == "RecallImproved" then return true end
		end
    end
	return false
end

-- A: number, comb: contains combinations, start:
function combinations(A,comb,start,n,current_k,k)
	
	
    if k < 0 then return end 
       
    -- Base case just print all the numbers 1 at a time
    if k==0 then
		local fin = {}
        for i=1, n do
			table.insert(fin, A[i])
		end
		table.insert(combos, fin)
		return
    end

    --current_k goes from 0 to k-1 and simulates a total of k iterations
    if current_k < k then
    
        -- if current_k = 0, and k = 3 (i.e. we need to find combinations of 4) 
        -- then we need to leave out 3 numbers from the end because there are 3 more nested loops
        for i = start, (n-(k-current_k)) do
            -- Store the number in the comb array and recursively call with the remaining sub-array
            comb[current_k] = A[i+1]
            -- This will basically pass a sub array starting at index 'start' and going till n-1
            combinations(A,comb,i+1,n,current_k+1,k)
        end
    elseif current_k == k then
        for i = start, n-1 do
            comb[current_k] = A[i+1]
			
			local fin = {}
			local j = 0
            while j <= k do
                table.insert(fin, comb[j])
				j = j + 1
			end
			table.insert(combos, fin)
			
        end
    
    else
        return
	end
end