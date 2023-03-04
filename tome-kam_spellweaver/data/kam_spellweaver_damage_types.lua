local KamCalc = require "mod.KamHelperFunctions"
local initState = DamageType.initState
local useImplicitCrit = DamageType.useImplicitCrit

newDamageType{ -- The generic damage type manager. 
	name = _t("spellwoven", "damage type"), type = "KAM_SPELLWEAVE_MANAGER",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local mod = dam.kamAllMod or 1
		if dam.second.kam_is_apply_first and (not dam.noStatuses) then -- Skeletonize needs to be first.
			DamageType:get(dam.second).projector(src, x, y, dam.second, mod * dam.statusChance, state)
		end
		local realdam = DamageType:get(dam.element).projector(src, x, y, dam.element, mod * dam.dam, state)
		if (not dam.second.kam_is_apply_first) and (not dam.noStatuses) then
			DamageType:get(dam.second).projector(src, x, y, dam.second, mod * dam.statusChance, state)
		end
		return realdam
	end,
}

newDamageType{ -- Special damage type manager for the Exploit Weakness Mode. Does NOT use Spellweave Manager damtype
	name = _t("precise spellwoven", "damage type"), type = "KAM_SPELLWEAVE_MANAGER_EXPLOIT",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local damage = dam.dam
		if target then
			if target.resists then
				local useElement = dam.element
				local checkElement = DamageType:get(dam.element)
				if checkElement.kamUnderlyingElement then
					useElement = checkElement.kamUnderlyingElement
				end
				local ele1 = (DamageType:get(useElement)).kamFirstElement
				if ele1 then
					local ele2 = (DamageType:get(useElement)).kamSecondElement
					local resOne = target:combatGetResist(ele1)
					local resTwo = target:combatGetResist(ele2)
					local dam1 = dam.dam / 2
					local dam2 = dam.dam / 2
					if resOne >= 100 then 
						dam1 = 0
					elseif resOne <= -100 then 
						dam1 = dam1 * 1.5
					else
						dam1 = dam1 * (100 - resOne/2) / 100
					end
					if resTwo >= 100 then 
						dam2 = 0
					elseif resTwo <= -100 then 
						dam2 = dam2 * 1.5
					else
						dam2 = dam2 * (100 - resTwo/2) / 100
					end
					if dam.second.kam_is_apply_first and (not dam.noStatuses) then -- Skeletonize needs to be first.
						DamageType:get(dam.second).projector(src, x, y, dam.second, dam.statusChance, state)
					end
					local realdam = DamageType:get(ele1).projector(src, x, y, ele1, dam1, state)
					realdam = realdam + DamageType:get(ele1).projector(src, x, y, ele2, dam2, state)
					if (not dam.second.kam_is_apply_first) and (not dam.noStatuses) then -- Don't double up.
						DamageType:get(dam.second).projector(src, x, y, dam.second, dam.statusChance, state)
					end
					return realdam
				else
					local res = target:combatGetResist(useElement)
					if res >= 100 then 
						damage = 0
					elseif res <= -100 then 
						damage = damage * 1.5
					else
						damage = damage * (100 - res/2) / 100
					end
				end
			end
		end
		if dam.second.kam_is_apply_first and (not dam.noStatuses) then -- Skeletonize needs to be first.
			DamageType:get(dam.second).projector(src, x, y, dam.second, dam.statusChance, state)
		end
		local realdam = DamageType:get(dam.element).projector(src, x, y, dam.element, damage, state)
		if (not dam.second.kam_is_apply_first) and (not dam.noStatuses) then -- Don't double up.
			DamageType:get(dam.second).projector(src, x, y, dam.second, dam.statusChance, state)
		end
		return realdam
	end,
}

local function prismaticExploitDoResists(target, element) -- Just so I don't have to write this out like 20 times. Addon makers, please don't handle things like I have prismatic. (Actually it's not so bad now, just weird)
	if target.resists then
		local res = target:combatGetResist(element)
		if res >= 100 then 
			return 0
		elseif res <= -100 then 
			return 1.5
		else 
			return ((100 - res/2) / 100)
		end
	else 
		return 1
	end
end

newDamageType{ -- Special damage type manager for the Prismatic/Exploit Weakness special case.
	name = _t("spellwoven", "damage type"), type = "KAM_SPELLWEAVE_MANAGER_PRISMATIC_EXPLOIT",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			local prisma = src:getTalentFromId(src.T_KAM_ELEMENT_PRISMA)
			local dam = dam.dam / 10
			if dam > 0 then
				realdam = realdam + DamageType:get(DamageType.DARKNESS).projector(src, x, y, DamageType.DARKNESS, dam * prismaticExploitDoResists(target, DamageType.DARKNESS), state)
				realdam = realdam + DamageType:get(DamageType.LIGHT).projector(src, x, y, DamageType.LIGHT, dam * prismaticExploitDoResists(target, DamageType.LIGHT), state)
				realdam = realdam + DamageType:get(DamageType.LIGHTNING).projector(src, x, y, DamageType.LIGHTNING, dam * prismaticExploitDoResists(target, DamageType.LIGHTNING), state)
				realdam = realdam + DamageType:get(DamageType.COLD).projector(src, x, y, DamageType.COLD, dam * prismaticExploitDoResists(target, DamageType.COLD), state)
				realdam = realdam + DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam * prismaticExploitDoResists(target, DamageType.FIRE), state)
				realdam = realdam + DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam * prismaticExploitDoResists(target, DamageType.PHYSICAL), state)
				realdam = realdam + DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam * prismaticExploitDoResists(target, DamageType.ARCANE), state)
				realdam = realdam + DamageType:get(DamageType.TEMPORAL).projector(src, x, y, DamageType.TEMPORAL, dam * prismaticExploitDoResists(target, DamageType.TEMPORAL), state)
				realdam = realdam + DamageType:get(DamageType.BLIGHT).projector(src, x, y, DamageType.BLIGHT, dam * prismaticExploitDoResists(target, DamageType.BLIGHT), state)
				realdam = realdam + DamageType:get(DamageType.ACID).projector(src, x, y, DamageType.ACID, dam * prismaticExploitDoResists(target, DamageType.ACID), state)
			end
		end
		
		DamageType:get(DamageType.KAM_SPELLWEAVE_PRISMATIC_SECONDARY).projector(src, x, y, DamageType.KAM_SPELLWEAVE_PRISMATIC_SECONDARY, dam.statusChance, state)
		return realdam
	end,
}

newDamageType{ -- The duo generic damage type manager.
	name = _t("spellwoven", "damage type"), type = "KAM_SPELLWEAVE_DUO_MANAGER",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local mod = dam.kamAllMod or 1
		if not dam.noStatuses then
			if (dam.second11.kam_is_apply_first) then -- Skeletonize needs to be first.
				DamageType:get(dam.second11).projector(src, x, y, dam.second11, mod * dam.statusChance11 * 0.5, state)		
			end
			if (dam.second12.kam_is_apply_first) then
				DamageType:get(dam.second12).projector(src, x, y, dam.second12, mod * dam.statusChance12 * 0.5, state)
			end
		end
		local realdam = DamageType:get(dam.element11).projector(src, x, y, dam.element11, mod * dam.dam11 * 0.5, state)
		realdam = realdam + DamageType:get(dam.element12).projector(src, x, y, dam.element12, mod * dam.dam12 * 0.5, state)
		if not dam.noStatuses then
			if not (dam.second11.kam_is_apply_first) then -- Don't duplicate them.
				DamageType:get(dam.second11).projector(src, x, y, dam.second11, mod * dam.statusChance11 * 0.5, state)
			end
			if not (dam.second12.kam_is_apply_first) then
				DamageType:get(dam.second12).projector(src, x, y, dam.second12, mod * dam.statusChance12 * 0.5, state)		
			end
		end
		return realdam
	end,
}

newDamageType{ -- The handler for Prismatic damage inflicting.
	name = _t("prismatic", "damage type"), type = "KAM_SPELLWEAVE_PRISMATIC",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			local prisma = src:getTalentFromId(src.T_KAM_ELEMENT_PRISMA)
			local dam = dam / 10
			if dam > 0 then
				realdam = realdam + DamageType:get(DamageType.DARKNESS).projector(src, x, y, DamageType.DARKNESS, dam)
				realdam = realdam + DamageType:get(DamageType.LIGHT).projector(src, x, y, DamageType.LIGHT, dam)
				realdam = realdam + DamageType:get(DamageType.LIGHTNING).projector(src, x, y, DamageType.LIGHTNING, dam)
				realdam = realdam + DamageType:get(DamageType.COLD).projector(src, x, y, DamageType.COLD, dam)
				realdam = realdam + DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam)
				realdam = realdam + DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam)
				realdam = realdam + DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam)
				realdam = realdam + DamageType:get(DamageType.TEMPORAL).projector(src, x, y, DamageType.TEMPORAL, dam)
				realdam = realdam + DamageType:get(DamageType.BLIGHT).projector(src, x, y, DamageType.BLIGHT, dam)
				realdam = realdam + DamageType:get(DamageType.ACID).projector(src, x, y, DamageType.ACID, dam)
			end
		end
		return realdam
	end,
}

newDamageType{ -- The handler for Prismatic status inflicting.
	name = _t("prismatic status", "damage type"), type = "KAM_SPELLWEAVE_PRISMATIC_SECONDARY",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local prisma = src:getTalentFromId(src.T_KAM_ELEMENT_PRISMA)
			local talentLevel = KamCalc:getAverageHighestElementTalentLevel(src, 3) * 5
			if talentLevel > 0 then
				local eclipse = src:getTalentFromId(src.T_KAM_ELEMENTS_ECLIPSE)
				local dark = src:getTalentFromId(src.T_KAM_ELEMENT_DARKNESS)
				DamageType:get(dark.getSecond(src, dark)).projector(src, x, y, dark.getSecond(src, dark), math.max(1, eclipse.getBlindChance(src, eclipse, talentLevel) / 10 * dam), state)
				local ligh = src:getTalentFromId(src.T_KAM_ELEMENT_LIGHT)
				DamageType:get(ligh.getSecond(src, ligh)).projector(src, x, y, ligh.getSecond(src, ligh), math.max(1, eclipse.getIlluminateChance(src, eclipse, talentLevel) / 10 * dam), state)
				
				local molten = src:getTalentFromId(src.T_KAM_ELEMENTS_MOLTEN)
				local phys = src:getTalentFromId(src.T_KAM_ELEMENT_PHYSICAL)
				DamageType:get(phys.getSecond(src, phys)).projector(src, x, y, phys.getSecond(src, phys), math.max(1, molten.getWoundChance(src, molten, talentLevel) / 10 * dam), state)
				local fire = src:getTalentFromId(src.T_KAM_ELEMENT_FLAME)
				DamageType:get(fire.getSecond(src, fire)).projector(src, x, y, fire.getSecond(src, fire), math.max(1, molten.getBurnPower(src, molten, talentLevel) / 10 * dam), state)

				local windAndRain = src:getTalentFromId(src.T_KAM_ELEMENTS_WIND_AND_RAIN)
				local thun = src:getTalentFromId(src.T_KAM_ELEMENT_LIGHTNING)
				DamageType:get(thun.getSecond(src, thun)).projector(src, x, y, thun.getSecond(src, thun), math.max(1, windAndRain.getDazeChance(src, windAndRain, talentLevel) / 10 * dam), state)
				local cold = src:getTalentFromId(src.T_KAM_ELEMENT_COLD)
				DamageType:get(cold.getSecond(src, cold)).projector(src, x, y, cold.getSecond(src, cold), math.max(1, windAndRain.getPinChance(src, windAndRain, talentLevel) / 10 * dam), state)

				local otherworldly = src:getTalentFromId(src.T_KAM_ELEMENTS_OTHERWORLDLY)
				local arca = src:getTalentFromId(src.T_KAM_ELEMENT_ARCANE)
				DamageType:get(arca.getSecond(src, arca)).projector(src, x, y, arca.getSecond(src, arca), math.max(1, otherworldly.getManaburning(src, otherworldly, talentLevel) / 10 * dam), state)
				local temp = src:getTalentFromId(src.T_KAM_ELEMENT_TEMPORAL)
				DamageType:get(temp.getSecond(src, temp)).projector(src, x, y, temp.getSecond(src, temp), math.max(1, otherworldly.getSlowChance(src, otherworldly, talentLevel) / 10 * dam), state)

				local ruin = src:getTalentFromId(src.T_KAM_ELEMENTS_RUIN)
				local blig = src:getTalentFromId(src.T_KAM_ELEMENT_BLIGHT)
				DamageType:get(blig.getSecond(src, blig)).projector(src, x, y, blig.getSecond(src, blig), math.max(1, ruin.getDiseaseChance(src, ruin, talentLevel) / 10 * dam), state)
				local acid = src:getTalentFromId(src.T_KAM_ELEMENT_ACID)
				DamageType:get(acid.getSecond(src, acid)).projector(src, x, y, acid.getSecond(src, acid), math.max(1, ruin.getDisarmChance(src, ruin, talentLevel) / 10 * dam), state)
			end
		end
	end,
}

newDamageType{ -- Special damage type manager for the Powerful Opening Mode
	name = _t("spellwoven", "damage type"), type = "KAM_SPELLWEAVE_MANAGER_OPENING",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			if (target.life > (target.max_life * 0.99)) then -- Doesn't actually need to be 100% exactly.
				dam.kamAllMod = 2
			else
				dam.kamAllMod = 1
			end
		else
			dam.kamAllMod = 1
		end
		return DamageType:get(DamageType.KAM_SPELLWEAVE_MANAGER).projector(src, x, y, DamageType.KAM_SPELLWEAVE_MANAGER, dam, state)
	end,
}

newDamageType{ -- Special damage type manager for the Powerful Opening Mode with Duo to just redirect it to duo after doubling them for this weird case.
	name = _t("spellwoven", "damage type"), type = "KAM_SPELLWEAVE_MANAGER_OPENING_DUO",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			if (target.life > (target.max_life * 0.99)) then -- Doesn't actually need to be 100% exactly.
				dam.kamAllMod = 2
			else
				dam.kamAllMod = 1
			end
		else
			dam.kamAllMod = 1
		end
		return DamageType:get(DamageType.KAM_SPELLWEAVE_DUO_MANAGER).projector(src, x, y, DamageType.KAM_SPELLWEAVE_DUO_MANAGER, dam, state)
	end,
}

newDamageType{
	name = _t("blinding dark", "damage type"), type = "KAM_BLIND_DARK",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			if target:canBe("blind") then
				target:setEffect(target.EFF_BLINDED, 5, {src=src, apply_power=src:combatSpellpower()})
			else
				game.logSeen(target, "%s resists!", target:getName():capitalize())
			end
		end
	end,
}

newDamageType{
	name = _t("revealing light", "damage type"), type = "KAM_ILLUMINATING_LIGHT",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			target:setEffect(target.EFF_LUMINESCENCE, 5, {src=src, apply_power=src:combatSpellpower()})
		end
	end,
}

newDamageType{
	name = _t("burning fire", "damage type"), type = "KAM_BURNING_FIRE",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local power = dam / 4
			target:setEffect(target.EFF_KAM_FIRE_BURNING, 4, {src=src, no_ct_effect = true, power = power})
		end
	end,
}

newDamageType{
	name = _t("wounding physical", "damage type"), type = "KAM_WOUNDING_PHYSICAL",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			if target:canBe("cut") then
				local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_MOLTEN)
				local reduction = 0
				if tal then 
					reduction = tal.getWoundPower(src, tal)
				end
				target:setEffect(target.EFF_KAM_PHYSICAL_WOUNDS, 4, {src=src, apply_power=src:combatSpellpower(), healingReduction = reduction})
			else
				game.logSeen(target, "%s resists!", target:getName():capitalize())
			end
		end
	end,
}

newDamageType{ -- Note: Not the same as LIGHTNING_DAZE
	name = _t("dazing lighting", "damage type"), type = "KAM_DAZING_LIGHTNING",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			if target:canBe("stun") then
				target:setEffect(target.EFF_DAZED, 3, {src=src, apply_power=src:combatSpellpower()})
			else
				game.logSeen(target, "%s resists!", target:getName():capitalize())
			end
		end
	end,
}

newDamageType{ -- Note: Not the same as COLDNEVERMOVE
	name = _t("freezing cold", "damage type"), type = "KAM_PINNING_COLD",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR) -- Theoretically should probably test levitation and flying but those are really weird mechanics so eh.
		if target and rng.range(1,100) <= dam then
			if target:canBe("pin") then
				target:setEffect(target.EFF_FROZEN_FEET, 4, {src=src, apply_power=src:combatSpellpower()})
			else
				game.logSeen(target, "%s resists!", target:getName():capitalize())
			end
		end
	end,
}

newDamageType{ -- Deals 50% of normal manaburn damage, and is not affected by normal bonuses. You're not an antimage, you're just a weird arcane mage.
	name = _t("manaburning arcane", "damage type"), type = "KAM_MANABURN", text_color = "#PURPLE#",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			dam = target.burnArcaneResources and target:burnArcaneResources(dam) or 0
			return DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam/2, state)
		end
		return 0
	end,
}

newDamageType{ -- Note: Similar to CONGEAL_TIME, but with less duration and more chance.
	name = _t("slowing time", "damage type"), type = "KAM_SLOWING_TIME",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			target:setEffect(target.EFF_CONGEAL_TIME, 4, {src=src, slow=0.35, proj=50, apply_power=src:combatSpellpower()})
		end
	end,
}

newDamageType{ 
	name = _t("diseasing blight", "damage type"), type = "KAM_DISEASING_BLIGHT",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			if target:canBe("disease") then
				local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_RUIN)
				local str, dex, con = not target:hasEffect(src.EFF_KAM_EXHAUSTING_DISEASE) and target:getStr() or 0, not target:hasEffect(src.EFF_KAM_WEARYING_DISEASE) and target:getDex() or 0, not target:hasEffect(src.EFF_KAM_ENERVATING_DISEASE) and target:getCon() or 0
				local disease = nil
				
				if str >= dex and str >= con then
					disease = {src.EFF_KAM_EXHAUSTING_DISEASE, "str"}
				elseif dex >= con then
					disease = {src.EFF_KAM_WEARYING_DISEASE, "dex"}
				else
					disease = {src.EFF_KAM_ENERVATING_DISEASE, "con"}
				end
				
				target:setEffect(disease[1], 5, {src=src, [disease[2]]=tal.getDiseasePower(src, tal), apply_power=src:combatSpellpower()})
			else
				game.logSeen(target, "%s resists!", target:getName():capitalize())
			end
		end
	end,
}

newDamageType{
	name = _t("disarming acid", "damage type"), type = "KAM_DISARMING_ACID",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			target:setEffect(target.EFF_DISARMED, 3, {src=src, apply_power=src:combatSpellpower()})
		end
	end,
}

-- Split elements:
newDamageType{
	name = _t("wind and rain", "damage type"), type = "KAM_WIND_AND_RAIN_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.COLD,
	kamSecondElement = DamageType.LIGHTNING,
	damdesc_split = function(src)
		return { {DamageType.COLD, 0.5}, {DamageType.LIGHTNING, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			local oldundaze
			if src.turn_procs then src.turn_procs.dealing_damage_dont_undaze, oldundaze = true, src.turn_procs.dealing_damage_dont_undaze end
			realdam = DamageType:get(DamageType.COLD).projector(src, x, y, DamageType.COLD, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.LIGHTNING).projector(src, x, y, DamageType.LIGHTNING, dam*0.5, state)
			if src.turn_procs then src.turn_procs.dealing_damage_dont_undaze = oldundaze end
		end
		return realdam
	end,
}

newDamageType{
	name = _t("eclipse", "damage type"), type = "KAM_ECLIPSE_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.LIGHT,
	kamSecondElement = DamageType.DARKNESS,
	damdesc_split = function(src)
		return { {DamageType.LIGHT, 0.5}, {DamageType.DARKNESS, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.LIGHT).projector(src, x, y, DamageType.LIGHT, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.DARKNESS).projector(src, x, y, DamageType.DARKNESS, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("molten", "damage type"), type = "KAM_MOLTEN_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.FIRE,
	kamSecondElement = DamageType.PHYSICAL,
	damdesc_split = function(src)
		return { {DamageType.FIRE, 0.5}, {DamageType.PHYSICAL, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("otherworldly", "damage type"), type = "KAM_OTHERWORLDLY_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.ARCANE,
	kamSecondElement = DamageType.TEMPORAL,
	damdesc_split = function(src)
		return { {DamageType.ARCANE, 0.5}, {DamageType.TEMPORAL, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.TEMPORAL).projector(src, x, y, DamageType.TEMPORAL, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("ruin", "damage type"), type = "KAM_RUIN_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.ACID,
	kamSecondElement = DamageType.BLIGHT,
	damdesc_split = function(src)
		return { {DamageType.ACID, 0.5}, {DamageType.BLIGHT, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.ACID).projector(src, x, y, DamageType.ACID, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.BLIGHT).projector(src, x, y, DamageType.BLIGHT, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("gravechill", "damage type"), type = "KAM_GRAVECHILL_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.COLD,
	kamSecondElement = DamageType.DARKNESS,
	damdesc_split = function(src)
		return { {DamageType.COLD, 0.5}, {DamageType.DARKNESS, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.COLD).projector(src, x, y, DamageType.COLD, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.DARKNESS).projector(src, x, y, DamageType.DARKNESS, dam*0.5, state)
		end
		return realdam 
	end,
}

newDamageType{
	name = _t("gravitic", "damage type"), type = "KAM_GRAVITY_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.PHYSICAL,
	kamSecondElement = DamageType.TEMPORAL,
	damdesc_split = function(src)
		return { {DamageType.PHYSICAL, 0.5}, {DamageType.TEMPORAL, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.TEMPORAL).projector(src, x, y, DamageType.TEMPORAL, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("plaguefire", "damage type"), type = "KAM_FEVER_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.BLIGHT,
	kamSecondElement = DamageType.FIRE,
	damdesc_split = function(src)
		return { {DamageType.BLIGHT, 0.5}, {DamageType.FIRE, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.BLIGHT).projector(src, x, y, DamageType.BLIGHT, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("manastorm", "damage type"), type = "KAM_MANASTORM_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.ARCANE,
	kamSecondElement = DamageType.LIGHTNING,
	damdesc_split = function(src)
		return { {DamageType.ARCANE, 0.5}, {DamageType.LIGHTNING, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.LIGHTNING).projector(src, x, y, DamageType.LIGHTNING, dam*0.5, state)
		end
		return realdam
	end,
}

newDamageType{
	name = _t("corrosive brilliance", "damage type"), type = "KAM_CORRODING_BRILLIANCE_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.ACID,
	kamSecondElement = DamageType.LIGHT,
	damdesc_split = function(src)
		return { {DamageType.ACID, 0.5}, {DamageType.LIGHT, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = DamageType:get(DamageType.ACID).projector(src, x, y, DamageType.ACID, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.LIGHT).projector(src, x, y, DamageType.LIGHT, dam*0.5, state)
		end
		return realdam
	end,
}

-- Split effects:
newDamageType{
	name = _t("eclipsing corona", "damage type"), type = "KAM_ECLIPSE_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_ECLIPSE_MASTERY)
			if tal then
				target:setEffect(target.EFF_KAM_ECLIPSING_CORONA, 4, {resistanceReduction = tal.getResistanceBreaking(src, tal), defenseReduction = tal.getDefensesPenalty(src, tal), armorReduction = tal.getArmorPenalty(src, tal)})
			end
		end
	end,
}

newDamageType{
	name = _t("earthscorcher", "damage type"), type = "KAM_MOLTEN_SECOND",
	kamAlwaysTriggerSecond = true,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_MOLTEN_MASTERY)
		if tal then
			local damage = tal.getMoltenDamage(src, tal)
			local reduction = tal.getHealReduction(src, tal)
			local duration = tal.getMoltenFloorTurns(src, tal)
			if rng.range(1,100) <= dam then
				game.level.map:addEffect(src,
					x, y, duration,
					DamageType.KAM_MOLTEN_FLOOR_DAMAGE, {source = src, dam = damage, reduction = reduction},
					0,
					5, nil,
					engine.MapEffect.new{zdepth=3, color_br=255, color_bg=80, color_bb=50, effect_shader="shader_images/crumbling_earth_ground_gfx.png"},
					function(e, update_shape_only)
						if not update_shape_only then e.radius = e.radius end
						return true
					end,
					false
				)
			end
		end
	end,
}

newDamageType{
	name = _t("timestealing", "damage type"), type = "KAM_OTHERWORLDLY_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY)
			if tal then
				local duration = tal.getDuration(src, tal)
				local maxEffects = tal.effectNumber(src, tal)
				local durationYou = tal.getDurationYou(src, tal)
				local effNum = 0
				for eff_id, p in pairs(target.tmp) do
					local e = target.tempeffect_def[eff_id]
					if e.status == "beneficial" and e.type ~= "other" and e.decrease ~= 0 then			
						p.dur = p.dur - duration
						
						if p.dur <= 0 then
							target:dispel(eff_id, src)
						end
						
						effNum = effNum + 1
						if effNum >= maxEffects then break end
					end
				end
				
				local effNumYou = 0
				for eff_id, p in pairs(src.tmp) do
					local e = src.tempeffect_def[eff_id]
					if e.status == "beneficial" and e.type ~= "other" then
						p.dur = p.dur + durationYou
						
						effNumYou = effNumYou + 1
						if effNumYou >= effNum then break end
					end
				end
			end
		end
	end,
}

newDamageType{
	name = _t("wind and rain", "damage type"), type = "KAM_WIND_AND_RAIN_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY)
			dam = dam * tal.getChanceMod(src, tal)
			if rng.range(1,100) <= dam then
				if tal then
					target:setEffect(target.EFF_KAM_WIND_AND_RAIN_EFFECT, tal.getDuration(src, tal), {src = src, damage = tal.getIcestormDamage(src, tal), radius = tal.getRadius(src, tal)})
				end
			end
		end
	end,
}

newDamageType{
	name = _t("exhausting ruin", "damage type"), type = "KAM_RUIN_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_RUIN_MASTERY)
			if tal then
				target:setEffect(target.EFF_KAM_RUINOUS_EXHAUSTION, 4, {damageReduction = tal.getDamageBreaking(src, tal), powerReduction = tal.getPowerReduction(src, tal), accuracyPenReduction = tal.getAccuracyPenReduction(src, tal)})
			end
		end
	end,
}

newDamageType{
	name = _t("chill of the grave", "damage type"), type = "KAM_GRAVECHILL_SECOND",
	kam_is_apply_first = true,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_GRAVECHILL)
			local skeletonChance = tal.getSkeletonChance(src, tal) * dam
			local armor = tal.getArmor(src, tal) * dam
			if tal then
				target:setEffect(target.EFF_KAM_CHILL_OF_THE_GRAVE, 10, {src = src, chance = skeletonChance})
				src:setEffect(src.EFF_KAM_CHILL_OF_THE_GRAVE_ARMORBONUS, 5, {src = src, armor = armor})
			end
		end
	end,
}

newDamageType{
	name = _t("gravitic", "damage type"), type = "KAM_GRAVITY_SECOND",
	kam_is_apply_first = true,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and not (target.turn_procs and target.turn_procs.kam_was_gravity_pushed) then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_GRAVITY)
			if tal then
				local pushDistance = tal.getPushDist(src, tal) * dam
				local doSlam = false
				-- Based on the spell Repulsion Blast
				if target:canBe("knockback") then
					if target.turn_procs then
						target.turn_procs.kam_was_gravity_pushed = true
					end
					pushDistance = math.max(pushDistance, 1) -- Knockback distance should always be 1.
					local x, y = src.x, src.y
					if src.kam_spellweavers_spell_center_x and src.kam_spellweavers_spell_center_y then
						x, y = src.kam_spellweavers_spell_center_x, src.kam_spellweavers_spell_center_y
					end
					target:knockback(x, y, pushDistance, false, function(g, tx, ty)
						if game.level.map:checkAllEntities(tx, ty, "block_move", target) then
							doSlam = true
						end
					end)
				end
				target:setEffect(target.EFF_KAM_GRAVITIC_EXHAUSTION, tal.getGraviticExhaustionDuration(src, tal), {src = src, power = tal.getGraviticExhaustion(src, tal)})
				if doSlam then
					src:project({type="hit"}, target.x, target.y, DamageType.KAM_GRAVITY_DAMAGE_TYPE, tal.getDamage(src, tal) * dam * 0.2)
					game.logSeen(target, "%s slams into something solid!", target:getName():capitalize())
				end
			end
		end
	end,
}

newDamageType{
	name = _t("gravitic", "damage type"), type = "KAM_GRAVITY_PULL_SECOND",
	kam_is_apply_first = true,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and not (target.turn_procs and target.turn_procs.kam_was_gravity_pushed) then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_GRAVITY)
			if tal then
				local pullDistance = tal.getPushDist(src, tal) * dam
				if target:canBe("knockback") then
					if target.turn_procs then
						target.turn_procs.kam_was_gravity_pushed = true
					end
					pullDistance = math.max(pullDistance, 1) -- Knockback distance should always be 1.
					local x, y = src.x, src.y
					if src.kam_spellweavers_spell_center_x and src.kam_spellweavers_spell_center_y then
						x, y = src.kam_spellweavers_spell_center_x, src.kam_spellweavers_spell_center_y
					end
					target:pull(x, y, pullDistance, false)
				end
				target:setEffect(target.EFF_KAM_GRAVITIC_EXHAUSTION, tal.getGraviticExhaustionDuration(src, tal), {src = src, power = tal.getGraviticExhaustion(src, tal)})
			end
		end
	end,
}

newDamageType{ 
	name = _t("feverish", "damage type"), type = "KAM_FEVER_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_FEVER)
			if tal then	
				if target:canBe("disease") then
					local feverDamage = tal.getFeverDamage(src, tal) * dam
					local feverDuration = tal.getFeverDuration(src, tal)
					local feverPower = tal.getFeverPower(src, tal) * dam
					
					local cun, mag, wil = not target:hasEffect(src.EFF_KAM_CONFUSING_DISEASE) and target:getCun() or 0, not target:hasEffect(src.EFF_KAM_MYSTICAL_DISEASE) and target:getMag() or 0, not target:hasEffect(src.EFF_KAM_NAUSEATING_DISEASE) and target:getWil() or 0
					local disease = nil
					
					if cun >= mag and cun >= wil then
						disease = {src.EFF_KAM_CONFUSING_DISEASE, "cun"}
					elseif mag >= wil then
						disease = {src.EFF_KAM_MYSTICAL_DISEASE, "mag"}
					else
						disease = {src.EFF_KAM_NAUSEATING_DISEASE, "wil"}
					end
					
					target:setEffect(disease[1], feverDuration, {src=src, [disease[2]]=feverPower, apply_power=src:combatSpellpower(), feverDamage = feverDamage / feverDuration})
				else
					game.logSeen(target, "%s resists!", target:getName():capitalize())
				end
			end
		end
	end,
}

newDamageType{
	name = _t("manastorm", "damage type"), type = "KAM_MANASTORM_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_MANASTORM)
			dam = dam * tal.getChanceMod(src, tal)
			if rng.range(1,100) <= dam then
				if tal then
					target:setEffect(target.EFF_KAM_MANASTORM_EFFECT, tal.getDuration(src, tal), {src = src, draining = tal.getResourceDrain(src, tal), radius = tal.getRadius(src, tal)})
				end
			end
		end
	end,
}

newDamageType{ 
	name = _t("corroding brilliance", "damage type"), type = "KAM_CORRODING_BRILLIANCE_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local tal = src:getTalentFromId(src.T_KAM_ELEMENTS_CORRODING_BRILLIANCE)
			if tal then	
				local repeatChance = tal.getRepeatChance(src, tal) * dam
				local drainPower = tal.getDrain(src, tal) * dam
				local radiamarkDuration = tal.getDuration(src, tal)
				target:setEffect(target.EFF_KAM_RADIAMARK_EFFECT, radiamarkDuration, {src=src, repeatChance = repeatChance, drainPower = drainPower})
			end
		end
	end,
}

-- Split effect assisting damage types.
newDamageType{
	name = _t("molten floor damage", "damage type"), type = "KAM_MOLTEN_FLOOR_DAMAGE",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			realdam = realdam + DamageType:get(DamageType.FIRE).projector(dam.source, x, y, DamageType.FIRE, dam.dam, state)
			realdam = realdam + DamageType:get(DamageType.PHYSICAL).projector(dam.source, x, y, DamageType.PHYSICAL, dam.dam, state)
			target:setEffect(target.EFF_KAM_MOLTEN_DRAIN_EFF, 1, {src = dam.source, reduction = dam.reduction})
		end
		return realdam
	end,
}

newDamageType{ -- Draining Molten for Endless Melting
	name = _t("draining molten", "damage type"), type = "KAM_MOLTEN_DAMAGE_TYPE_DRAINING",
	damdesc_split = function(src)
		return { {DamageType.FIRE, 0.5}, {DamageType.PHYSICAL, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = {crit_set = true, crit_type = false, crit_power = 1}
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local realdam = DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam*0.5, state)
			realdam = realdam + DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam*0.5, state)
			if realdam > 0 and not src:attr("dead") then 
				src:heal(realdam, src)
			end
		end
	end,
}

newDamageType{
	name = _t("draining fever", "damage type"), type = "KAM_DRAINING_FEVER_DAMAGE_TYPE",
	isKamDoubleElement = true,
	kamFirstElement = DamageType.BLIGHT,
	kamSecondElement = DamageType.FIRE,
	damdesc_split = function(src)
		return { {DamageType.BLIGHT, 0.5}, {DamageType.FIRE, 0.5} }
	end,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local realdam = DamageType:get(DamageType.BLIGHT).projector(src, x, y, DamageType.BLIGHT, dam * 0.5, state)
			realdam = realdam + DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam * 0.5, state)
			if realdam > 0 and not src:attr("dead") then 
				src:heal(realdam, src)
			end
		end
	end,
}

newDamageType{
	name = _t("draining manastorm", "damage type"), type = "KAM_DRAINING_MANASTORM_DAMTYPE",
	isKamDoubleElement = true,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			local drain = KamCalc:kam_burn_all_resources(target, dam) or 0
			
			if (drain > 0) then
				src:incMana(drain)
			--	game:delayedLogMessage(src, target, "drained" ,("#PURPLE##Source# absorbs %d mana from #Target#!#LAST#"):tformat(drain)) -- ... the chat horrors that would emerge.
			end
		end
	end,
}

newDamageType{
	name = _t("piercing elementless", "damage type"), type = "KAM_PIERCING_ELEMENTLESS_DAMAGE", text_color = "#C2C2C2#",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		
		local target = game.level.map(x, y, Map.ACTOR)
		local resistChange
		if target and target.resists and target.resists.all then
			resistChange = target.resists.all / 2
			target.resists.all = target.resists.all - resistChange
		end
		
		local realdam = DamageType:get(DamageType.KAM_ELEMENTLESS_DAMAGE).projector(src, x, y, DamageType.KAM_ELEMENTLESS_DAMAGE, dam, state)
		
		if target and target.resists and target.resists.all then
			target.resists.all = target.resists.all + resistChange
		end
		return realdam
	end,
	death_message = {_t"emptied", _t"nullified", _t"vanished"},
}

newDamageType{
	name = _t("elementless", "damage type"), type = "KAM_ELEMENTLESS_DAMAGE", text_color = "#C2C2C2#",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local realdam = DamageType.defaultProjector(src, x, y, type, dam, state)

		return realdam
	end,
	death_message = {_t"emptied", _t"nullified", _t"vanished"},
}

newDamageType{
	name = _t("elemental nullification", "damage type"), type = "KAM_ELEMENTLESS_SECOND",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target and rng.range(1,100) <= dam then
			target:setEffect(target.EFF_KAM_ELEMENTAL_NULLIFICATION, 5, {src=src})
		end
	end,
}

newDamageType{
	name = _t("Elementalist's Prismatic", "damage type"), type = "KAM_ELEMENTALISTS_GLOVES_DAMAGE_TYPE",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		
		local target = game.level.map(x, y, Map.ACTOR)
		local realdam = 0
		if target then
			local elementsTable = {1/10, 1/10, 1/10, 1/10, 1/10, 1/10, 1/10, 1/10, 1/10, 1/10}
			if src.combatGetDamageIncrease then
				local dark = math.max(0, (src:combatGetDamageIncrease(DamageType.DARKNESS) or 0) * 2 + 100)
				local light = math.max(0, (src:combatGetDamageIncrease(DamageType.LIGHT) or 0) * 2 + 100)
				local lightning = math.max(0, (src:combatGetDamageIncrease(DamageType.LIGHTNING) or 0) * 2 + 100)
				local cold = math.max(0, (src:combatGetDamageIncrease(DamageType.COLD) or 0) * 2 + 100)
				local fire = math.max(0, (src:combatGetDamageIncrease(DamageType.FIRE) or 0) * 2 + 100)
				local physical = math.max(0, (src:combatGetDamageIncrease(DamageType.PHYSICAL) or 0) * 2 + 100)
				local arcane = math.max(0, (src:combatGetDamageIncrease(DamageType.ARCANE) or 0) * 2 + 100)
				local temporal = math.max(0, (src:combatGetDamageIncrease(DamageType.TEMPORAL) or 0) * 2 + 100)
				local blight = math.max(0, (src:combatGetDamageIncrease(DamageType.BLIGHT) or 0) * 2 + 100)
				local acid = math.max(0, (src:combatGetDamageIncrease(DamageType.ACID) or 0) * 2 + 100)
				total = dark + light + lightning + cold + fire + physical + arcane + temporal + blight + acid
				if total > 0 then
					elementsTable[1] = dark / total
					elementsTable[2] = light / total
					elementsTable[3] = lightning / total
					elementsTable[4] = cold / total
					elementsTable[5] = fire / total
					elementsTable[6] = physical / total
					elementsTable[7] = arcane / total
					elementsTable[8] = temporal / total
					elementsTable[9] = blight / total
					elementsTable[10] = acid / total
				end
			end
			realdam = realdam + DamageType:get(DamageType.DARKNESS).projector(src, x, y, DamageType.DARKNESS, dam * elementsTable[1], state)
			realdam = realdam + DamageType:get(DamageType.LIGHT).projector(src, x, y, DamageType.LIGHT, dam * elementsTable[2], state)
			realdam = realdam + DamageType:get(DamageType.LIGHTNING).projector(src, x, y, DamageType.LIGHTNING, dam * elementsTable[3], state)
			realdam = realdam + DamageType:get(DamageType.COLD).projector(src, x, y, DamageType.COLD, dam * elementsTable[4], state)
			realdam = realdam + DamageType:get(DamageType.FIRE).projector(src, x, y, DamageType.FIRE, dam * elementsTable[5], state)
			realdam = realdam + DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam * elementsTable[6], state)
			realdam = realdam + DamageType:get(DamageType.ARCANE).projector(src, x, y, DamageType.ARCANE, dam * elementsTable[7], state)
			realdam = realdam + DamageType:get(DamageType.TEMPORAL).projector(src, x, y, DamageType.TEMPORAL, dam * elementsTable[8], state)
			realdam = realdam + DamageType:get(DamageType.BLIGHT).projector(src, x, y, DamageType.BLIGHT, dam * elementsTable[9], state)
			realdam = realdam + DamageType:get(DamageType.ACID).projector(src, x, y, DamageType.ACID, dam * elementsTable[10], state)		
		end
		return realdam
	end,
}

newDamageType{
	name = _t("daze-safe lightning", "damage type"), type = "KAM_LIGHTNING_NO_UNDAZE",
	kamUnderlyingElement = DamageType.LIGHTNING,
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local oldundaze
		if src.turn_procs then src.turn_procs.dealing_damage_dont_undaze, oldundaze = true, src.turn_procs.dealing_damage_dont_undaze end
		local realdam = DamageType:get(DamageType.LIGHTNING).projector(src, x, y, DamageType.LIGHTNING, dam, state)
		if src.turn_procs then src.turn_procs.dealing_damage_dont_undaze = oldundaze end
		local target = game.level.map(x, y, Map.ACTOR)
		return realdam
	end,
}