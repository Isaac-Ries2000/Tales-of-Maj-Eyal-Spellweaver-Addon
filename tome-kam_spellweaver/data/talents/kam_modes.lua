local Map = require "engine.Map"
local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "spellweaving/damage", no_silence = true, is_spell = true, name = _t("damages", "talent type"), description = _t"Weave spells with the damage types." }

--[[ Reminder: Modes that have frequent special cases:
- Exploit Weakness, Elemental Shielding, Resistance Breaking
- WALLWEAVING
--]]
-- Some of the odd code here stems from the fact that I've redone a bunch of stuff in here like 3 times to account for weirder and weirder cases. (plus stuff like the special targeting)

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

local function getDamTypeManager(self, t)
	if (t.isKamDuo) then 
		return DamageType.KAM_SPELLWEAVE_DUO_MANAGER
	else 
		return DamageType.KAM_SPELLWEAVE_MANAGER
	end
end

-- Sets up targTable here too so that targets that get pushed or moved or anything can be held to apply like it's one thing.
local function onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	if t.isKamASCExact then -- Beams, Randoms, and Self targeting should all be focused on you.
		self.kam_spellweavers_spell_center_x = x
		self.kam_spellweavers_spell_center_y = y
	end
	local damFunction = function(px, py, tg, self) 
		local target = game.level.map(px, py, Map.ACTOR)
		if target then 
			table.insert(targTable, target)
			-- For Void Dance
			local voidDance = self:isTalentActive(self.T_KAM_ELEMENTS_OTHERWORLDLY_SUSTAIN)
			if voidDance and voidDance.waitTurns == 0 then 
				local doVoidDanceMovespeed = 0
				if target:knowTalent(target.T_MANA_POOL) and target.getMana and (target:getMana() <= target:getMaxMana() / 2) then 
					doVoidDanceMovespeed = 1
				elseif target:knowTalent(target.T_VIM_POOL) and target.getVim and (target:getVim() <= target:getMaxVim() / 2) then 
					doVoidDanceMovespeed = 1
				elseif target:knowTalent(target.T_POSITIVE_POOL) and target.getPositive and (target:getPositive() <= target:getMaxPositive() / 2) then 
					doVoidDanceMovespeed = 1
				elseif target:knowTalent(target.T_NEGATIVE_POOL) and target.getNegative and (target:getPositive() <= target:getMaxNegative() / 2) then 
					doVoidDanceMovespeed = 1
				end
				if target.hasEffect and target:hasEffect(target.EFF_CONGEAL_TIME) then 
					doVoidDanceMovespeed = doVoidDanceMovespeed + 1
				end
				if doVoidDanceMovespeed > 0 then 
					if doVoidDanceMovespeed > 1 then 
						doVoidDanceMovespeed = 1.5
					end
					local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY_SUSTAIN)
					tal.doGainMovespeed(self, tal, doVoidDanceMovespeed * t.getPowerModShape(self, t))
				end
			end
			
			
			local moltenDraining = self:isTalentActive(self.T_KAM_ELEMENTS_MOLTEN_SUSTAIN)
			if moltenDraining then
				if (target:hasEffect(target.EFF_KAM_MOLTEN_DRAIN_EFF)) then
					local draining = true
					if argsTable.element then
						if (argsTable.element == DamageType.KAM_MOLTEN_DAMAGE_TYPE) then
							draining = false
						end
					elseif argsTable.element11 then 
						if (argsTable.element11 == DamageType.KAM_MOLTEN_DAMAGE_TYPE or argsTable.element12 == DamageType.KAM_MOLTEN_DAMAGE_TYPE) then
							draining = false
						end
					end 
					if draining then
						local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_SUSTAIN)
						DamageType:get(DamageType.KAM_MOLTEN_DAMAGE_TYPE_DRAINING).projector(self, target.x, target.y, DamageType.KAM_MOLTEN_DAMAGE_TYPE_DRAINING, tal.getMoltenDrain(self, tal))
					end
				end
			end
		end
	end
	
	doApply(self, projectFunction, tg, x, y, {damFunction, argsTable})
	
	if KamCalc:talentContainsElement(self, t, DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE) then
		self:attr("kam_icestorm_count", 0, 0)
		for _, e in pairs(game.level.entities) do
			if e.rank and e.subtype and e.hasEffect and e:hasEffect(e.EFF_KAM_WIND_AND_RAIN_EFFECT) then
				self:attr("kam_icestorm_count", 1)
			end
		end
	end
end

-- Apply any special effects that trigger on Spellwoven casting. Used to project, now uses targTable created by onTargetWithSpellweave (for safety with knocking back targets).
local function afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable)
	self.kam_spellweavers_spell_center_x = nil
	self.kam_spellweavers_spell_center_y = nil
	
	local commandingStaffArgsTable
	if self.attr and self:attr("kam_commanding_staff_attr") then
		local cmdstaffmult = self:attr("kam_commanding_staff_attr")
		local elements = {}
		for _, talent in pairs(self.talents_def) do
			if self:knowTalent(talent) then
				local talentTable = self:getTalentFromId(talent)
				if talentTable.isKamElement and not (talentTable.isKamDuo or talentTable.isKamPrismatic or talentTable.isKamElementRandom) then
					elements[#elements+1] = talentTable
				end
			end
		end
		local ele = rng.table(elements)
		commandingStaffArgsTable = {dam = ele.getElementDamage(self, ele) * cmdstaffmult, statusChance = ele.getStatusChance(self, ele) * cmdstaffmult, element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = nil}
	end
	
	--[[
	local trueElementalistArgsTable
	if self.knowTalent and self:knowTalent(self.T_KAM_ELEMENTALIST_MASTERY) then
		local trueElementalist = self:getTalentFromId(self.T_KAM_ELEMENTALIST_MASTERY)
		local trueElementalistMultiplier = trueElementalist.trueElementalistBonusPower(self, trueElementalist)
		local elements = {}
		for _, talent in pairs(self.talents_def) do
			if self:knowTalent(talent) then
				local talentTable = self:getTalentFromId(talent)
				if talentTable.isKamElement and not talentTable.isKamDuo then
					elements[#elements+1] = talentTable
				end
			end
		end
		local ele = rng.table(elements)
		local talentLevel = KamCalc:getAverageHighestElementTalentLevel(self, 5) * ele.points
		trueElementalistArgsTable = {dam = ele.getElementDamage(self, ele, talentLevel) * trueElementalistMultiplier, statusChance = ele.getStatusChance(self, ele, talentLevel) * trueElementalistMultiplier, element = ele.getElement(self, ele), second = ele.getSecond(self, ele), friendlyfire = false, selffire = false, talent = nil}
	end
	--]]

	for _, target in ipairs(targTable) do
		if target and not target.dead then 
			-- For Acidic Pestilence
			if self.attr and self:attr("kam_apestilence_diseaseChance") and self:knowTalent(self.T_KAM_ELEMENTS_RUIN) then 
				local chance = self:attr("kam_apestilence_diseaseChance") * t.getPowerModShape(self, t)
				if target:attr("disarmed") and target:attr("disarmed") > 0 then
					chance = chance * 2.5
				end
				if rng.percent(chance) then 
					if target:canBe("disease") then
						local tal = self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN)
						local str, dex, con = not target:hasEffect(self.EFF_KAM_EXHAUSTING_DISEASE) and target:getStr() or 0, not target:hasEffect(self.EFF_KAM_WEARYING_DISEASE) and target:getDex() or 0, not target:hasEffect(self.EFF_KAM_ENERVATING_DISEASE) and target:getCon() or 0
						local disease = nil
						
						if str >= dex and str >= con then
							disease = {self.EFF_KAM_EXHAUSTING_DISEASE, "str"}
						elseif dex >= con then
							disease = {self.EFF_KAM_WEARYING_DISEASE, "dex"}
						else
							disease = {self.EFF_KAM_ENERVATING_DISEASE, "con"}
						end
						
						target:setEffect(disease[1], 5, {self=self, [disease[2]]=tal.getDiseasePower(self, tal), apply_power=self:combatSpellpower()})
					else
						game.logSeen(target, "%s resists!", target:getName():capitalize())
					end
				end
			end
			
			-- For Unending Melting
			local burnWoundExtend = self:isTalentActive(self.T_KAM_ELEMENTS_MOLTEN_SUSTAIN)
			if burnWoundExtend then
				local extendBurn = true
				local extendWound = true
				if argsTable.element then
					if (argsTable.element == DamageType.FIRE) then 
						extendBurn = false
					elseif (argsTable.element == DamageType.PHYSICAL) then 
						extendWound = false
					end
				elseif argsTable.element11 then 
					if (argsTable.element11 == DamageType.FIRE or argsTable.element12 == DamageType.FIRE) then
						extendBurn = false
					end
					if (argsTable.element11 == DamageType.PHYSICAL or argsTable.element12 == DamageType.PHYSICAL) then
						extendWound = false
					end
				end 
				
				if extendWound then
					local wound = target:hasEffect(target.EFF_KAM_PHYSICAL_WOUNDS)
					if wound then 
						wound.dur = wound.dur + 1
					end
				end
				if extendBurn then
					local burn = target:hasEffect(target.EFF_KAM_FIRE_BURNING)
					if burn then 
						burn.dur = burn.dur + 1
					end
				end
			end
		end
	end
	
	local old_kam_spellweaver_random_element_level = game.state.kam_spellweaver_random_element_level
	game.state.kam_spellweaver_random_element_level = nil
	for _, target in ipairs(targTable) do -- Things that need to not use Forced Level
		if target and not target.dead then 
			if commandingStaffArgsTable then
				self:project({type = "hit"}, target.x, target.y, DamageType.KAM_SPELLWEAVE_MANAGER, commandingStaffArgsTable)
			end
			
			-- For True Elementalist
			--[[
			if trueElementalistArgsTable then
				self:project({type = "hit"}, target.x, target.y, DamageType.KAM_SPELLWEAVE_MANAGER, trueElementalistArgsTable)
			end
			--]]
		end
	end
	game.state.kam_spellweaver_random_element_level = old_kam_spellweaver_random_element_level
	
	local hailstorm = self:isTalentActive(self.T_KAM_ELEMENTS_WIND_AND_RAIN_SUSTAIN)
	if hailstorm then
		local hailstormTalent = self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN_SUSTAIN)
		if KamCalc:talentContainsElement(self, t, DamageType.COLD) or KamCalc:talentContainsElement(self, t, DamageType.LIGHTNING) or KamCalc:talentContainsElement(self, t, DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE) then
			if argsTable.element then
				local toAdd = argsTable.dam
				if t.isKamDoubleShape then 
					toAdd = toAdd / 2
				end
				toAdd = toAdd * hailstormTalent.getDamageBoost(self, hailstormTalent) * 0.01
				hailstorm.currentDamage = hailstorm.currentDamage + toAdd
			elseif argsTable.element11 then 
				local toAdd = argsTable.dam11 + argsTable.dam12
				if t.isKamDoubleShape then 
					toAdd = toAdd / 2
				end
				toAdd = toAdd * hailstormTalent.getDamageBoost(self, hailstormTalent) * 0.01 / 2
				hailstorm.currentDamage = hailstorm.currentDamage + toAdd
			end 
		else
			hailstormTalent.doOvercharge(self, hailstormTalent, hailstorm)
		end
	end
	local changeupEff = self:hasEffect(self.EFF_KAM_SPELLWEAVE_CHANGEUP)
	if (changeupEff) then -- Handle checking if Changeup applies if the buff is active.
		if KamCalc:compareSlots(self, changeupEff, t) then 
			table.insert(changeupEff.changeupStorage, t.kamSpellSlotNumber)
			table.insert(changeupEff.talentNames, t.name)
		end
	end
end

local function buildArgsTableElement(self, t, argsTable, modifiers)
	modifiers = modifiers or {dam = 1, statusChance = 1}
	argsTable.src = self
	if modifiers.statusChance == 0 then
		argsTable.noStatuses = true
	end
	local critStatus = self:spellCrit(1) -- It all crits together or nothing crits. Otherwise you end up with critting so many times. Double shapes can do twice, but otherwise only once.
	argsTable.critStatus = critStatus -- Added for the sake of prismatic duo hailstorms.
	argsTable.modifiers = modifiers
	argsTable.talent = t
	if (t.isKamDoubleShape) then 
		if (t.isKamSpellSplitOne) then 
			argsTable.spellweavePower = t.getPowerMod1(self, t)
			if not (t.isKamDuo1) then
				argsTable.element = t.getElement1(self, t)
				argsTable.second = t.getSecond1(self, t)
				argsTable.elementInfo = t.getSpellElementInfo1
				argsTable.status = t.getSecond1(self, t)
				argsTable.dam = critStatus * t.getElementDamage1(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod1(self, t) * (modifiers.dam)
				argsTable.statusChance = t.getStatusChance1(self, t) * t.getPowerMod1(self, t) * (modifiers.statusChance)
			else 
				argsTable.element11 = t.getElement11(self, t)
				argsTable.element12 = t.getElement12(self, t)
				argsTable.second11 = t.getSecond11(self, t)
				argsTable.second12 = t.getSecond12(self, t)
				argsTable.elementInfo11 = t.getSpellElementInfo11
				argsTable.elementInfo12 = t.getSpellElementInfo12
				argsTable.status11 = t.getSecond11(self, t)
				argsTable.status12 = t.getSecond12(self, t)
				argsTable.dam11 = critStatus * t.getElementDamage11(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod1(self, t) * (modifiers.dam)
				argsTable.statusChance11 = t.getStatusChance11(self, t) * t.getPowerMod1(self, t) * (modifiers.statusChance)
				argsTable.dam12 = critStatus * t.getElementDamage12(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod1(self, t) * (modifiers.dam)
				argsTable.statusChance12 = t.getStatusChance12(self, t) * t.getPowerMod1(self, t) * (modifiers.statusChance)
			end
		else 
			argsTable.spellweavePower = t.getPowerMod2(self, t)
			if not (t.isKamDuo2) then
				argsTable.element = t.getElement2(self, t)
				argsTable.second = t.getSecond2(self, t)
				argsTable.elementInfo = t.getSpellElementInfo2
				argsTable.status = t.getSecond2(self, t)
				argsTable.dam = critStatus * t.getElementDamage2(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod2(self, t) * (modifiers.dam)
				argsTable.statusChance = t.getStatusChance2(self, t) * t.getPowerMod2(self, t) * (modifiers.statusChance)
			else 
				argsTable.element11 = t.getElement21(self, t)
				argsTable.element12 = t.getElement22(self, t)
				argsTable.second11 = t.getSecond21(self, t)
				argsTable.second12 = t.getSecond22(self, t)
				argsTable.elementInfo11 = t.getSpellElementInfo21
				argsTable.elementInfo12 = t.getSpellElementInfo22
				argsTable.status11 = t.getSecond21(self, t)
				argsTable.status12 = t.getSecond22(self, t)
				argsTable.dam11 = critStatus * t.getElementDamage21(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod2(self, t) * (modifiers.dam)
				argsTable.statusChance11 = t.getStatusChance21(self, t) * t.getPowerMod2(self, t) * (modifiers.statusChance)
				argsTable.dam12 = critStatus * t.getElementDamage22(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod2(self, t) * (modifiers.dam)
				argsTable.statusChance12 = t.getStatusChance22(self, t) * t.getPowerMod2(self, t) * (modifiers.statusChance)
			end
		end
	else
		argsTable.spellweavePower = t.getPowerMod(self, t)
		if not (t.isKamDuo) then
			argsTable.element = t.getElement(self, t)
			argsTable.second = t.getSecond(self, t)
			argsTable.elementInfo = t.getSpellElementInfo
			argsTable.status = t.getSecond(self, t)
			argsTable.dam = critStatus * t.getElementDamage(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod(self, t) * (modifiers.dam)
			argsTable.statusChance = t.getStatusChance(self, t) * t.getPowerMod(self, t) * (modifiers.statusChance)
		else 
			argsTable.element11 = t.getElement11(self, t)
			argsTable.element12 = t.getElement12(self, t)
			argsTable.second11 = t.getSecond11(self, t)
			argsTable.second12 = t.getSecond12(self, t)
			argsTable.elementInfo11 = t.getSpellElementInfo11
			argsTable.elementInfo12 = t.getSpellElementInfo12
			argsTable.status11 = t.getSecond11(self, t)
			argsTable.status12 = t.getSecond12(self, t)
			argsTable.dam11 = critStatus * t.getElementDamage11(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod(self, t) * (modifiers.dam)
			argsTable.statusChance11 = t.getStatusChance11(self, t) * t.getPowerMod(self, t) * (modifiers.statusChance)
			argsTable.dam12 = critStatus * t.getElementDamage12(self, t, nil, modifiers.useFlatDamage) * t.getPowerMod(self, t) * (modifiers.dam)
			argsTable.statusChance12 = t.getStatusChance12(self, t) * t.getPowerMod(self, t) * (modifiers.statusChance)
		end
	end
end
--[[ -- This used to be part of a thing to add subtypes to DoT effects, but it really didn't matter so.
local function doGetStatusEffectTypes(self, t)
	if (t.isKamDoubleShape) then 
		if (t.isKamSpellSplitOne) then 
			return t.getStatusEffectTypes1
		else 
			return t.getStatusEffectTypes2
		end
	else
		return t.getStatusEffectTypes
	end
end
--]]

local function defaultDoApply(self, apply, tg, x, y, args)
	return apply(self, tg, x, y, unpack(args))
end

local function skipProject(self, tg, px, py, damtype, dam)
	local typ = engine.Target:getType(tg)
	local act = game.level.map(px, py, engine.Map.ACTOR)
	if act and (typ.act_exclude and typ.act_exclude[act.uid]) or act == self and not ((type(typ.selffire) == "number" and rng.percent(typ.selffire)) or (type(typ.selffire) ~= "number" and typ.selffire)) then
		return
	elseif act and self.reactionToward and (self:reactionToward(act) >= 0) and not ((type(typ.friendlyfire) == "number" and rng.percent(typ.friendlyfire)) or (type(typ.friendlyfire) ~= "number" and typ.friendlyfire)) then
		return
	else
		if type(damtype) == "function" then
			damtype(px, py, tg, self)
		else 
			DamageType:get(damtype).projector(self, px, py, damtype, dam, {}, nil) 
		end
	end
end

newTalent{
	name = "Basic Damage",
	short_name = "KAM_MODE_DAMAGE",
	image = "talents/shockwave_bomb.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Harm",
	no_npc_use = true,
	getDamageFunction = function(self, t, tg, x, y)
		local argsTable = {}
		local targTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit" -- Convert the tg's type to hit since we only want to hit the one target (but we still want wall passing stuff, friendlyfire).
			tg.range = nil -- Ignore range, the system will handle it.
			tg.radius = 0 -- 0 radius.
			tg.x = nil 
			tg.y = nil -- Probably fine?
		end
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Deal direct damage, without modifications. Spellweave Multiplier: 1.]])
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = "damage directly.",
}

newTalent{
	name = "Damage Over Time",
	short_name = "KAM_MODE_DOT",
	image = "talents/haste.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Constant Harm",
	no_npc_use = true,
	getElement = function(self, t) 
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getPowerMode = function(self, t)
		return nil
	end,
	getDamageFunction = function(self, t, tg, x, y)
		local argsTable = {}
		local targTable = {}
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit" -- Convert the tg's type to hit since we only want to hit the one target (but we still want wall passing stuff, friendlyfire).
			tg.range = nil -- Ignore range, the system will handle it.
			tg.radius = 0 -- 0 radius.
			tg.x = nil 
			tg.y = nil -- Probably fine?
		end
		buildArgsTableElement(self, t, argsTable)
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		local damType = function(px, py, tg, self) 
			local target = game.level.map(px, py, Map.ACTOR)
			if target then
				target:setEffect(target.EFF_KAM_SPELLWEAVE_DOT_EFFECT, 5, table.clone(argsTable, true)) -- This has to be table.clone or BIZARRE errors will happen because they'll all share the table.
			end
		end
		doApply(self, projectFunction, tg, x, y, {damType, argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 0.3
	end,
	info = function(self, t)
		return ([[Deal damage as an over-time effect, hitting each target with the damage every turn for 5 turns, potentially inflicting any bonus effects each time. These effects will not stack, with new versions always replacing old versions.
This effect is always applied, but can still be cleared as normal for a magical status effect. Spellweave Multiplier: 0.3.]])
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = "damage each turn for five turns, potentially inflicting effects each turn.",
}

newTalent{
	name = "Applying",
	short_name = "KAM_MODE_APPLY",
	image = "talents/carrier.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Infliction",
	no_npc_use = true,
	getElement = function(self, t) 
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getDamageMod = function(self, t) 
		return 0.6
	end,
	getStatusMod = function(self, t)
		return 1.35
	end,
	getPowerMode = function(self, t)
		return nil
	end,
	getDamageFunction = function(self, t, tg, x, y)
		local argsTable = {}
		local targTable = {}
		buildArgsTableElement(self, t, argsTable, {dam = 0.6, statusChance = 1.5})
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Reduces direct damage by 40%, but multiplies effective Spellweave Multiplier for status effects by 1.35 (both are applied multiplicatively). Spellweave Multiplier: 1.]])
	end,
	getSpellModeInfo = "dealing a reduced",
	getSpellModeInfoTwo = "damage with increased status infliction.",
}

newTalent{
	name = "Exploit Weakness",
	short_name = "KAM_MODE_EXPLOIT",
	image = "talents/focused_channeling.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Precision",
	no_npc_use = true,
	getElement = function(self, t) 
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getPowerMode = function(self, t)
		return nil
	end,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)

		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type = "hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil
			tg.y = nil
		end
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		if (t.isKamDuo) then 
			local inputTable1 = {dam = argsTable.dam11, statusChance = argsTable.statusChance11, second = argsTable.second11, element = argsTable.element11}
			local inputTable2 = {dam = argsTable.dam12, statusChance = argsTable.statusChance12, second = argsTable.second12, element = argsTable.element12}
			if inputTable1.element == DamageType.KAM_SPELLWEAVE_PRISMATIC then
				doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_PRISMATIC_EXPLOIT, inputTable1})
			else 
				doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_EXPLOIT, inputTable1})
			end
			if inputTable2.element == DamageType.KAM_SPELLWEAVE_PRISMATIC then
				doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_PRISMATIC_EXPLOIT, inputTable2})
			else 
				doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_EXPLOIT, inputTable2})
			end
		else
			if argsTable.element == DamageType.KAM_SPELLWEAVE_PRISMATIC then
				doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_PRISMATIC_EXPLOIT, argsTable})
			else 
				doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_EXPLOIT, argsTable})
			end
		end
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Deal direct damage, with damage and status power modified by an additional 50% of resistances before resistance is normally applied. Spellweave Multiplier: 1.]])
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = "damage, affected by an additional 50% of resistances.",
}

-- Helper function to add to the list without duplicates
local function kamAddElement(list, element)
	local doAdd = true
	for i = 1, table.getn(list) do 
		if (list[i] == element) then
			doAdd = false
			break
		end
	end
	if (doAdd) then
		table.insert(list, element)
		return true
	end
	return false
end

local function makeEffectArgsElementList(t, argsTable)
	local effectArgsList = {}
	if (t.isKamPrismatic) then 
		effectArgsList.isPrismatic = true
	else
		local elements = {}
		if (t.isKamDuo) then
			local damtype = DamageType:get(argsTable.element11)
			if (damtype.isKamDoubleElement) then 
				kamAddElement(elements, DamageType:get(argsTable.element11).kamFirstElement)
				kamAddElement(elements, DamageType:get(argsTable.element11).kamSecondElement)
			else
				if damtype.kamUnderlyingElement then
					kamAddElement(elements, damtype.kamUnderlyingElement)
				else
					kamAddElement(elements, argsTable.element11)
				end
			end
			
			damtype = DamageType:get(argsTable.element12)
			if (damtype.isKamDoubleElement) then 
				kamAddElement(elements, DamageType:get(argsTable.element12).kamFirstElement)
				kamAddElement(elements, DamageType:get(argsTable.element12).kamSecondElement)
			else
				if damtype.kamUnderlyingElement then
					kamAddElement(elements, damtype.kamUnderlyingElement)
				else
					kamAddElement(elements, argsTable.element12)
				end
			end
		else 
			local damtype = DamageType:get(argsTable.element)
			if (damtype.isKamDoubleElement) then 
				kamAddElement(elements, DamageType:get(argsTable.element).kamFirstElement)
				kamAddElement(elements, DamageType:get(argsTable.element).kamSecondElement)
			else 
				if damtype.kamUnderlyingElement then
					kamAddElement(elements, damtype.kamUnderlyingElement)
				else
					kamAddElement(elements, argsTable.element)
				end
			end
		end
		effectArgsList.elements = elements
	end
	return effectArgsList
end

local makeElementsTextList = function(self, elements)
	local buildString = (DamageType:get(elements[1])).name:capitalize()
	for i = 2, table.getn(elements) - 1 do
		buildString = buildString..", "..(DamageType:get(elements[i])).name:capitalize()
	end
	if #elements > 2 then
		buildString = buildString..", and "..(DamageType:get(elements[#elements])).name:capitalize()
	elseif #elements == 2 then
		buildString = buildString.." and "..(DamageType:get(elements[#elements])).name:capitalize()
	end
	return buildString
end

local function buildElementArgsTable(self, t, argsTable, isSpellSplit) -- Builds a short list of elements for the use of this whole mess of functions.
	if (t.isKamDoubleShape) then 
		if (isSpellSplit and isSpellSplit == 0) then 
			if not (t.isKamDuo1) then
				argsTable.element = t.getElement1(self, t)
			else 
				argsTable.element11 = t.getElement11(self, t)
				argsTable.element12 = t.getElement12(self, t)
			end
		else 
			if not (t.isKamDuo2) then
				argsTable.element = t.getElement2(self, t)
			else 
				argsTable.element11 = t.getElement21(self, t)
				argsTable.element12 = t.getElement22(self, t)
			end
		end
	else
		if not (t.isKamDuo) then
			argsTable.element = t.getElement(self, t)
		else 
			argsTable.element11 = t.getElement11(self, t)
			argsTable.element12 = t.getElement12(self, t)
		end
	end
end

newTalent{
	name = "Elemental Shielding",
	short_name = "KAM_MODE_ELEMENTAL_SHIELD",
	image = "talents/bind.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Protecting",
	no_npc_use = true,
	getElement = function(self, t) 
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getPowerMode = function(self, t)
		return nil
	end,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		local effectArgsList = makeEffectArgsElementList(t, argsTable)
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		if not self:hasEffect(self.EFF_KAM_SPELLWEAVE_ELESHIELD_EFFECT) then
			self:setEffect(self.EFF_KAM_SPELLWEAVE_ELESHIELD_EFFECT, 4, effectArgsList)
		end
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 0.7
	end,
	info = function(self, t)
		return ([[Deal reduced damage, then gain a 30% resistance to the spell's element for 4 turns. If this mode's spell has two elements, instead gain a 25% resistance to both. If it has three or more, gain 20% resist to each of them. If any of the mode's elements are prismatic, instead gain 15% resist all. Only one set of resistances can be gained this way at once, and the oldest will always be kept, so if two instances of Elemental Shielding are used in one spell, only the first will be applied. Spellweave Multiplier: 0.7.]])
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = function(self, t, isSpellSplit)
		local argsTable = {}
		buildElementArgsTable(self, t, argsTable, isSpellSplit)
		local effectArgsList = makeEffectArgsElementList(t, argsTable)
		if effectArgsList.isPrismatic then 
			return "damage directly and gaining 15% all resistance for 4 turns."
		else
			local elementTextList = makeElementsTextList(self, effectArgsList.elements)
			local resistance = 0
			local elementsCount = #(effectArgsList.elements)
			if elementsCount > 2 then
				resistance = 20
			elseif elementsCount > 1 then
				resistance = 25
			else
				resistance = 30
			end
			return ([[damage directly and gaining %d%% %s resistance for 4 turns.]]):tformat(resistance, elementTextList)
		end
	end,
}

newTalent{
	name = "Resistance Breaking",
	short_name = "KAM_MODE_EXPOSING",
	image = "talents/ashes_to_ashes.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Exposing",
	no_npc_use = true,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		local effectArgsList = makeEffectArgsElementList(t, argsTable)
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		local resistbreakDamFunc = function(px, py, tg, self) 
			local target = game.level.map(px, py, Map.ACTOR)
			if target then 
				if not target:hasEffect(target.EFF_KAM_SPELLWEAVE_RESISTANCE_REDUCE_EFFECT) then
					target:setEffect(target.EFF_KAM_SPELLWEAVE_RESISTANCE_REDUCE_EFFECT, 4, effectArgsList)
				end
			end
		end
		doApply(self, projectFunction, tg, x, y, {resistbreakDamFunc, argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 0.7
	end,
	info = function(self, t)
		return ([[Deal reduced damage and reduce affected enemies resistances to the spell's element by 30%% for 4 turns. If this mode's spell has two elements, instead reduce both resistances by 25%%. If the mode has three or more elements, reduce all of their resistances by 20%%. If either element of the mode is prismatic, instead reduce all of their resistances by 15%%. This effect does not stack, and the oldest will always be kept, so if two instance of Resitance Breaking are used in one spell, it will only be applied for the first of them. Spellweave Multiplier: 0.7.]]):tformat()
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = function(self, t, isSpellSplit)
		local argsTable = {}
		buildElementArgsTable(self, t, argsTable, isSpellSplit)
		local effectArgsList = makeEffectArgsElementList(t, argsTable)
		if effectArgsList.isPrismatic then 
			return "damage directly and reducing target's all resistance by 15% for 4 turns."
		else
			local elementTextList = makeElementsTextList(self, effectArgsList.elements)
			local resistance = 0
			local elementsCount = #(effectArgsList.elements)
			if elementsCount > 2 then
				resistance = 20
			elseif elementsCount > 1 then
				resistance = 25
			else
				resistance = 30
			end
			return ([[damage directly and reducing target's %s resistance by %d%% for 4 turns.]]):tformat(elementTextList, resistance)
		end
	end,
}

newTalent{
	name = "Forceful",
	short_name = "KAM_MODE_FORCEFUL",
	image = "talents/arcane_power.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Force",
	no_npc_use = true,
	kamModeUseFlatElementDamage = true,
	getElement = function(self, t) 
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getDamageMod = function(self, t) 
		return 1.5
	end,
	getStatusMod = function(self, t)
		return 0
	end,
	getPowerMode = function(self, t)
		return nil
	end,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable, {dam = 1.5, statusChance = 0, useFlatDamage = true})
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Increases direct damage by 50%, but any status effects associated with the elements are removed. Normal elements with inherent damage modifiers instead use their unmodified values (Random element and other specialty elements may not be affected). Spellweave Multiplier: 1.]])
	end,
	getSpellModeInfo = "dealing an increased",
	getSpellModeInfoTwo = "damage without any status infliction",
}

newTalent{
	name = "Lingering",
	short_name = "KAM_MODE_LINGERING",
	image = "talents/mudslide.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Lingering Harm",
	no_npc_use = true,
	getElement = function(self, t) 
		return nil
	end,
	getElementDamage = function(self, t)
		return nil
	end,
	getPowerMode = function(self, t)
		return nil
	end,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		local applicationTg = table.clone(tg, true)
		applicationTg.selffire = true -- For the actual creation of tiles, this can hit you (since the tiles won't hurt you anyways)
		applicationTg.friendlyfire = true
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		local grids = doApply(self, projectFunction, applicationTg, x, y, {function() end, {}})
		if (t.isKamDuo) then 
			local kamaniColorsTable1 = {}
			local kamaniColorsTable2 = {}
			t.getElementColors11(self, kamaniColorsTable1, t)
			t.getElementColors12(self, kamaniColorsTable2, t)
			--[[ Old code. This caused random color selection to be a tad more complex instead of just averaged, but only worked when every tile was an individual map effect instead of all being one.
			local kamaniColorCount = 0
			local kamaniColorTrue = true
			local kamaniColorsDecider = function()
				if (kamaniColorCount == 0) then 
					kamaniColorTrue = rng.percent(50)
				end
				kamaniColorCount = (kamaniColorCount + 1) % 3
				return kamaniColorTrue
			end
			--]] -- color_bg=(kamaniColorsDecider() and kamaniColorsTable1.colorGLow) or kamaniColorsTable2.colorGLow
			local color_r = (kamaniColorsTable1.colorRLow + kamaniColorsTable2.colorRLow + kamaniColorsTable1.colorRTop + kamaniColorsTable2.colorRTop) / 4
			local color_g = (kamaniColorsTable1.colorGLow + kamaniColorsTable2.colorGLow + kamaniColorsTable1.colorGTop + kamaniColorsTable2.colorGTop) / 4
			local color_b = (kamaniColorsTable1.colorBLow + kamaniColorsTable2.colorBLow + kamaniColorsTable1.colorBTop + kamaniColorsTable2.colorBTop) / 4
			game.level.map:addEffect(self,
				x, y, 5,
				getDamTypeManager(self, t), argsTable,
				0,
				nil, grids,
				engine.MapEffect.new{zdepth = 3, color_br=color_r, color_bg=color_g, color_bb=color_b, effect_shader="shader_images/ice_effect.png"},
				nil, false, false
			)
		else 
			local kamaniColorsTable = {}
			t.getElementColors(self, kamaniColorsTable, t)
			game.level.map:addEffect(self,
				x, y, 5,
				getDamTypeManager(self, t), argsTable,
				0,
				nil, grids,
				engine.MapEffect.new{color_br=kamaniColorsTable.colorRLow, color_bg=kamaniColorsTable.colorGLow, color_bb=kamaniColorsTable.colorGLow, effect_shader="shader_images/ice_effect.png"},
				nil, false, false
			)
		end
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 0.5
	end,
	info = function(self, t)
		return ([[Rather than deal damage directly, create persistent damaging tiles that last 5 turns and deal damage each turn to anything in them, potentially inflicting status effects each time. Spellweave Multiplier: 0.5.]])
	end,
	getSpellModeInfo = "creating persistent damaging spaces on the ground that deal",
	getSpellModeInfoTwo = "damage each turn, potentially inflicting any status effects each time.",
}

newTalent{ -- Thank Dreamforge for this wacky thing.
	name = "Wallweaving",
	short_name = "KAM_MODE_WALLS",
	image = "talents/anomaly_entomb.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	isKamNoDoubleMode = true,
	kamSpellweaverModeCooldownIncrease = 7,
	mode = "passive",
	getSpellNameMode = "Wallweave",
	no_npc_use = true,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction) -- Cheat this, since damage done isn't immediately done anyways and the walls will mess up the results otherwise
		local wallChance = t.getPowerMod(self, t) * 3.25 * 100
		if (t.isKamDoubleWallChance) then 
			wallChance = wallChance * 2 -- One-tile spells should be guarenteed, checkerboard spells deserve it.
		end
		local colorsTable = {}
		if t.isKamDuo then
			local tempColorsTable = {}
			t.getElementColors11(self, colorsTable, t)
			t.getElementColors12(self, tempColorsTable, t)
			colorsTable.colorRLow = (colorsTable.colorRLow + tempColorsTable.colorRLow) / 2
			colorsTable.colorGLow = (colorsTable.colorGLow + tempColorsTable.colorGLow) / 2
			colorsTable.colorBLow = (colorsTable.colorBLow + tempColorsTable.colorBLow) / 2
			colorsTable.colorALow = (colorsTable.colorALow + tempColorsTable.colorALow) / 2
			
			colorsTable.colorRTop = (colorsTable.colorRTop + tempColorsTable.colorRTop) / 2
			colorsTable.colorGTop = (colorsTable.colorGTop + tempColorsTable.colorGTop) / 2
			colorsTable.colorBTop = (colorsTable.colorBTop + tempColorsTable.colorBTop) / 2
			colorsTable.colorATop = (colorsTable.colorATop + tempColorsTable.colorATop) / 2
		else
			t.getElementColors(self, colorsTable, t)
		end
		
		local wallMakeDamFunction = function(px, py, tg, self)
			local oe = game.level.map(px, py, Map.TERRAIN)
			if not rng.percent(wallChance) or not oe or oe:attr("temporary") or game.level.map:checkAllEntities(px, py, "block_move") then return end

			local e = Object.new{
				old_feat = oe,
				type = oe.type, subtype = oe.subtype,
				name = ("%s's spellwoven barrier"):tformat(self:getName():capitalize()),
				image = "terrain/solidwall/solid_wall1.png",
				display = '#', color=colors.PURPLE, back_color=colors.DARK_GREY,
				shader = "shadow_simulacrum",
				shader_args = { color = {rng.range(colorsTable.colorRLow, colorsTable.colorRTop)/255,
					rng.range(colorsTable.colorGLow, colorsTable.colorGTop)/255, 
					rng.range(colorsTable.colorBLow, colorsTable.colorBTop)/255}, base = 0.9, time_factor = 1500 },
				always_remember = true,
				desc = _t"a spellwoven wall of magical energy",
				type = "wall",
				can_pass = {pass_wall=1},
				does_block_move = true,
				show_tooltip = true,
				block_move = true,
				block_sight = true,
				temporary = 5,
				x = px, y = py,
				canAct = false,
				damageType = getDamTypeManager(self, t),
				damageArgs = argsTable,
				tal = t,
				radius = 1, -- Uncertain of if this does anything...
				act = function(self)
					local tg = {type="ball", range=0, friendlyfire=false, radius = 1, talent=self.tal, x=self.x, y=self.y,}
					self.summoner.__project_source = self
					self.summoner:project(tg, self.x, self.y, self.damageType, self.damageArgs)
					self.summoner.__project_source = nil
					self:useEnergy()
					self.temporary = self.temporary - 1
					if self.temporary <= 0 then
						game.level.map(self.x, self.y, engine.Map.TERRAIN, self.old_feat)
						game.level:removeEntity(self)
						game.level.map:updateMap(self.x, self.y)
						game.nicer_tiles:updateAround(game.level, self.x, self.y)
					end
				end,
				dig = function(src, x, y, old)
					game.level:removeEntity(old, true)
					return nil, old.old_feat
				end,
				summoner_gain_exp = true,
				summoner = self,
			}
			e.tooltip = mod.class.Grid.tooltip
			game.level:addEntity(e)
			game.level.map(px, py, Map.TERRAIN, e)
			game.nicer_tiles:updateAround(game.level, px, py)
			game.level.map:updateMap(px, py)
		end
		doApply(self, projectFunction, tg, x, y, {wallMakeDamFunction, argsTable})
	end,
	getPowerModMode = function(self, t) -- This seems like nothing, but given that it lasts for 5 turns, can hit with multiple walls a turn, and makes walls...
		return 0.2
	end,
	info = function(self, t)
		return ([[Create walls that last for 5 turns, inflicting the effects of the spell on adjacent enemies each turn. Chance to create walls is equal to Spellweave Multiplier times 325 (and doubled for spells using Checkerboard shapes or shapes that target only one tile). Spellweave Multiplier: 0.2.
		Because of the mental fortitude required to create walls, the cooldown of spells including the Wallweaving mode is increased by 7 turns (12 turns compared to the normal 5), and Wallweaving may only be used once in shapes that call for two modes, like the Checkerboard shape.]])
	end,
	getSpellModeInfo = "randomly creating walls that last 5 turns and deal",
	getSpellModeInfoTwo = function (self, t, isSpellSplit)
		local powerMod = 1
		if (isSpellSplit) then
			if (isSpellSplit == 0) then 
				powerMod = t.getPowerMod1(self, t)
			else 
				powerMod = t.getPowerMod2(self, t)
			end
		else
			powerMod = t.getPowerMod(self, t)
		end
		local wallChance = powerMod * 3.25 * 100
		if (t.isKamDoubleWallChance) then 
			wallChance = wallChance * 2
		end
		wallChance = math.min(wallChance, 100) -- Cap at 100% since higher than 100% simply has no effect here.
		return ([[damage each turn to adjacent enemies, potentially inflicting any status effects. Each affected tile has a %d%% chance to have a wall created.]]):tformat(wallChance)
	end
}

newTalent{
	name = "Powerful Opening",
	short_name = "KAM_MODE_GOODSTART", -- ... goodstart. This makes me deeply happy.
	image = "talents/disruption_shield.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Opening",
	no_npc_use = true,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		if (t.isKamDuo) then 
			doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_OPENING_DUO, argsTable})
		else
			doApply(self, projectFunction, tg, x, y, {DamageType.KAM_SPELLWEAVE_MANAGER_OPENING, argsTable})
		end
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Deal direct damage, with power and status power doubled for undamaged targets. Spellweave Multiplier: %d.]]):tformat(t.getPowerModMode(self, t))
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = "damage, with damage and status chance and power doubled against undamaged enemies.",
}

newTalent{ -- This talent could get weird, but I'm hoping it's not OP.
	name = "Digging",
	short_name = "KAM_MODE_DIGGING",
	image = "talents/dig.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	isKamIgnoreWalls = true,
	mode = "passive",
	getSpellNameMode = "Digging",
	no_npc_use = true,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type = "hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
		tg.pass_terrain = true
		
		local tg2 = {type="beam", range = core.fov.distance(self.x, self.y, x, y), friendlyfire = false, pass_terrain = true}
		if (t.isKamASCExact) then
			self:project(tg2, x, y, DamageType.DIG, 1)
		end
		doApply(self, projectFunction, tg, x, y, {DamageType.DIG, 1})
		tg.pass_terrain = false
		tg2.pass_terrain = false
		if not (t.isKamNoCheckCanProject) then
			self.kamRecheckProjectParticles = true
			local _ _, checkX, checkY = self:canProject(tg2, x, y)
			x = checkX
			y = checkY
		end

		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 0.5
	end,
	info = function(self, t)
		return ([[Cast a substantially weaker spell that pierces walls and destroys every wall it hits. If the shape does not target you, also dig a beam torwards the target. Cannot be used in shapes that use multiple modes. Spellweave Multiplier: %d.
		Additionally, this will not deal damage through walls that it cannot dig through.]]):tformat(t.getPowerModMode(self, t))
	end, -- So basically, I couldn't figure out a good way to prevent this from targeting through walls while still DISPLAYING through walls, so it also digs a beam to the target so you can't use it to snipe through walls quite as much.
	getSpellModeInfo = "dealing a reduced",
	getSpellModeInfoTwo = "damage, piercing and destroying walls.",
}

newTalent{
	name = "Changeup",
	short_name = "KAM_MODE_CHANGEUP",
	image = "talents/flurry_of_fists.png",
	type = {"spellweaving/damage", 1},
	points = 1,
	isKamMode = true,
	mode = "passive",
	getSpellNameMode = "Changeup",
	no_npc_use = true,
	getDamageFunction = function(self, t, tg, x, y)
		local targTable = {}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable)
		
		local doApply = defaultDoApply
		local projectFunction = self.project
		if (tg.projectHandlerFunction) then
			doApply = tg.projectHandlerFunction
			projectFunction = skipProject
			tg.type="hit"
			tg.range = nil
			tg.radius = 0
			tg.x = nil 
			tg.y = nil
		end
				
		onTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
		if not self:hasEffect(self.EFF_KAM_SPELLWEAVE_CHANGEUP) then
			self:setEffect(self.EFF_KAM_SPELLWEAVE_CHANGEUP, 3, { talentNames = {t.name}, changeupStorage = {t.kamSpellSlotNumber} })
		end
		doApply(self, projectFunction, tg, x, y, {getDamTypeManager(self, t), argsTable})
		afterTargetWithSpellweave(self, tg, t, x, y, doApply, argsTable, targTable, projectFunction)
	end,
	getPowerModMode = function(self, t)
		return 0.5
	end,
	getSpellweavePowerBoost = 1.4,
	info = function(self, t)
		return ([[Deal reduced damage, then gain Changeup for 3 turns, which multiplies Spellweave Multiplier by %0.1f for Spellwoven attack spells sharing no Spellweaving components (excluding Duo) with this spell and any spells that benefited from this effect. This effect does not stack, and the oldest instance will always be kept. Spellweave Multiplier: %0.1f.]]):tformat(t.getSpellweavePowerBoost, t.getPowerModMode(self, t))
	end,
	getSpellModeInfo = "dealing",
	getSpellModeInfoTwo = "damage directly and granting you Changeup for 3 turns, which multiplies Spellweave Multiplier by 1.4 for Spellwoven attack spells sharing no Spellweaving components (excluding Duo) with this spell and any spells that benefited from that Changeup. Changeup does not stack, and the oldest instance will always be kept.",
}

-- Huge crit boost, reduced damaged?