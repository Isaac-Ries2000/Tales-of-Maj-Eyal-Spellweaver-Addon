local class = require "engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local DamageType = require "engine.DamageType"
local Target = require "engine.Target"
local Entity = require "engine.Entity"

module(..., package.seeall, class.make)

_M.defaults = {}

local spellwovenTalentDisplayEntities = {}

function _M:setupSpellwovenTalentEntities(self)
	spellwovenTalentDisplayEntities.attack = {}
	spellwovenTalentDisplayEntities.teleport = {}
	spellwovenTalentDisplayEntities.shield = {}
	for i = 0, 6 do
		spellwovenTalentDisplayEntities.attack[i] = Entity.new{image="talents/kam_spellweaver_spellslot_attack_"..i..".png", is_talent=true}
	end
	for i = 0, 6 do
		spellwovenTalentDisplayEntities.teleport[i] = Entity.new{image="talents/kam_spellweaver_spellslot_teleport_"..i..".png", is_talent=true}
	end
	for i = 0, 6 do
		spellwovenTalentDisplayEntities.shield[i] = Entity.new{image="talents/kam_spellweaver_spellslot_shield_"..i..".png", is_talent=true}
	end
	spellwovenTalentDisplayEntities.teleport[14] = engine.interface.ActorTalents.talents_def.T_KAM_SPELL_SLOT_TELEPORT_UNIQUE.display_entity
end

-- Directly from engine\utils.lua
local function deltaCoordsToReal(dx, dy, source_x, source_y)
	if util.isHex() then
		dy = dy + (math.floor(math.abs(dx) + 0.5) % 2) * (0.5 - math.floor(source_x) % 2)
		dx = dx * math.sqrt(3) / 2
	end
	return dx, dy
end

local function deltaRealToCoords(dx, dy, source_x, source_y)
	if util.isHex() then
		dx = dx < 0 and math.ceil(dx * 2 / math.sqrt(3) - 0.5) or math.floor(dx * 2 / math.sqrt(3) + 0.5)
		dy = dy - (math.floor(math.abs(dx) + 0.5) % 2) * (0.5 - math.floor(source_x) % 2)
	end
	return source_x + dx, source_y + dy
end

local function cleanReplaceTable(t, nt) -- To make sure tables don't have ghost values, this cleans and replaces with a blank talent.
	for k, v in pairs(t) do 
		if k ~= "id" and k ~= "short_name" and k ~= "kamSpellSlotNumber" and k ~= "image" and k ~= "display_entity" and k ~= "isKamSpellSlot" and k ~= "isKamTeleportSpellSlot" then 
			t[k] = nil
		end
	end 
	for k, v in pairs(nt) do 
		if k ~= "id" and k ~= "short_name" and k ~= "kamSpellSlotNumber" and k ~= "image" and k ~= "display_entity" and k ~= "isKamSpellSlot" and k ~= "isKamTeleportSpellSlot" then 
			t[k] = v
		end
	end
end

-- Variant of combatTalentSpellDamage that takes in a max talent level
function _M:combatTalentSpellDamageLevelVariable(self, t, base, max, spellpower_override, maxTalentLevel)
	if (type(t) == 'table') then t = self:getTalentLevel(t) end
	-- Compute at "max"
	local mod = max / ((base + 100) * ((math.sqrt(maxTalentLevel) - 1) * 0.8 + 1))
	-- Compute real
	return self:rescaleDamage((base + (spellpower_override or self:combatSpellpower())) * ((math.sqrt(t) - 1) * 0.8 + 1) * mod)
end

-- This is the damage that all elements do as their base. For easier adjustment.
function _M:coreSpellweaveElementDamageFunction(self, t, maxPoints) 
	local maxPoints = maxPoints or (type(t) == "table" and t.points) or 5
	return _M:combatTalentSpellDamageLevelVariable(self, t, 20, 225, nil, maxPoints)
end

-- Used by all elemental trees second talents for determining resistance piercing and damage increasing.
function _M:getResistancePiercingForElementTalents(self, t)
	return self:combatTalentLimit(t, 40, 5, 25) -- Numbers reduced substantially to account for being much easier to get than the ones I originally based it on.
end
function _M:getDamageIncForElementTalents(self, t)
	return self:combatTalentScale(t, 2.5, 12)
end

-- As a minor bonus, get 2% res piercing for each point in the fourth talent (to make up a bit of the difference from main resistance piercing.
-- Since Spellweavers have access to a lot of elements, they kind of need it, and a 10% or so boost is pretty minor. 
-- These talents are really only beneficial if you use the elements, so this is a minor boost for if you don't.
function _M:getLesserResistancePiercingForElementTalents(self, t)
	return self:combatTalentScale(t, 2, 10)
end

function _M:kam_before_build_spells(self, ids)
	local tal = self.talents_def[ids.slot]
	if tal.mode == "sustained" and self:isTalentActive(tal.id) then -- Make sure sustains are always broken on use.
		self:forceUseTalent(tal.id, {ignore_energy = true, silent = true})
	end
	if tal.onBuildover then
		tal.onBuildover(self, tal)
	end
end

function _M:kam_build_spell_from_ids(ids)
	_M:kam_before_build_spells(self, ids)
	local tal = self.talents_def[ids.slot]
	cleanReplaceTable(tal, ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	tal.image = "talents/kam_spellweaver_spellslot_attack_"..tal.kamSpellSlotNumber..".png"
	tal.display_entity = spellwovenTalentDisplayEntities.attack[tal.kamSpellSlotNumber]
	local shape = self.talents_def[ids.shape]
	
	tal.no_silence = true
	
	tal.range = shape.range
	tal.isKamAttackSpell = true
	tal.isKamASCBeam = shape.isKamASCBeam
	tal.isKamASCExact = shape.isKamASCExact
	tal.isKamASCSelf = shape.isKamASCSelf
	tal.isKamASCRand = shape.isKamASCRand
	tal.isKamDoubleShape = shape.isKamDoubleShape
	tal.isKamDoubleWallChance = shape.isKamDoubleWallChance
	tal.isKamNoNeedTarget = shape.isKamNoNeedTarget
	tal.isKamBarrage = ids.isKamBarrage
	tal.isKamPrismatic = false
	local barrageString = ""
	local barrageName = ""
	if tal.isKamBarrage then 
		barrageString = ([[Apply three times: 
]]):tformat()
		barrageName = "Triple "
	end
	if not (tal.isKamDoubleShape) then 
		tal.getPowerMod = function(self, t)
			return (t.getPowerModMode(self, t) * t.getPowerModShape(self, t) * t.getPowerModBonus(self, t))
		end
		local mode = self.talents_def[ids.mode1]
		if mode.kamSpellweaverModeCooldownIncrease then
			tal.cooldown = tal.cooldown + mode.kamSpellweaverModeCooldownIncrease
		end
		tal.isKamIgnoreWalls = mode.isKamIgnoreWalls
		tal.kamModeUseFlatElementDamage = mode.kamModeUseFlatElementDamage
		local element = self.talents_def[ids.element1]
		tal.isKamDuo = element.isKamDuo
		if not (tal.isKamDuo) then 
			tal.getElement = element.getElement
			tal.isKamElementRandom = element.isKamElementRandom
			tal.isKamPrismatic = element.isKamPrismatic 
			tal.getElementDamage = element.getElementDamage
			tal.getSecond = element.getSecond 
			tal.isKamDoubleElement = element.isKamDoubleElement
			
			tal.getDamageFunction = mode.getDamageFunction 
			tal.getPowerModMode = mode.getPowerModMode
			
			tal.getDamageMod = mode.getDamageMod or function(self, t) return 1 end
			tal.getStatusMod = mode.getStatusMod or function(self, t) return 1 end
			
			tal.target = shape.target
			tal.getPowerModShape = shape.getPowerModShape
			tal.name = barrageName..""..shape.getSpellNameShape..""..element.getSpellNameElement..""..mode.getSpellNameMode
			tal.getSpellShapeInfo = shape.getSpellShapeInfo
			tal.getSpellModeInfo = mode.getSpellModeInfo 
			tal.getSpellElementInfo = element.getSpellElementInfo 
			tal.getSpellModeInfoTwo = mode.getSpellModeInfoTwo
			tal.getElementColors = element.getElementColors
			tal.makeParticles = shape.makeParticles
			tal.getStatusChance = element.getStatusChance
			tal.getSpellStatusInflict1 = element.getSpellStatusInflict
--			tal.getStatusEffectTypes = element.getStatusEffectTypes
			tal.radius = shape.radius
			tal.range = shape.range 
			tal.isKamNoCheckCanProject = shape.isKamNoCheckCanProject

			tal.info = function(self, t)
				local spellModeInfoTwoData = nil 
				if type(t.getSpellModeInfoTwo) == "function" then 
					spellModeInfoTwoData = t.getSpellModeInfoTwo(self, t)
				else 
					spellModeInfoTwoData = t.getSpellModeInfoTwo
				end
				local inflictText = ""
				if t.getStatusMod(self, t) > 0 then
					inflictText = ([[ %s]]):tformat(t.getSpellStatusInflict1(self, t, t.getStatusChance(self, t)*t.getPowerMod(self, t)*t.getStatusMod(self,t)))
				end
				return ([[%s%s %s %d %s %s%s.]]):tformat(
					barrageString,
					t.getSpellShapeInfo(self, t), 
					t.getSpellModeInfo, 
					self:damDesc(t.getElement(self, t), t.getElementDamage(self, t, nil, t.kamModeUseFlatElementDamage)*t.getPowerMod(self, t)*t.getDamageMod(self,t)), 
					t.getSpellElementInfo, 
					spellModeInfoTwoData, 
					inflictText
				)
			end
		else 
			local element11 = self.talents_def[ids.element11]
			local element12 = self.talents_def[ids.element12]
			tal.isKamElementRandom = element11.isKamElementRandom or element12.isKamElementRandom
			tal.isKamPrismatic = element11.isKamPrismatic
			tal.isKamPrismatic11 = element11.isKamPrismatic
			tal.isKamPrismatic = tal.isKamPrismatic or element12.isKamPrismatic 
			tal.isKamPrismatic12 = element12.isKamPrismatic
			tal.getElement = element.getElement 
			tal.getElement11 = element11.getElement
			tal.getElement12 = element12.getElement
			tal.getElementDamage11 = element11.getElementDamage
			tal.getElementDamage12 = element12.getElementDamage
			tal.getSecond11 = element11.getSecond 
			tal.getSecond12 = element12.getSecond
			tal.isKamDoubleElement1 = element11.isKamDoubleElement
			tal.isKamDoubleElement2 = element12.isKamDoubleElement
			
			tal.getDamageFunction = mode.getDamageFunction 
			tal.getPowerModMode = mode.getPowerModMode
			
			tal.getDamageMod = mode.getDamageMod or function(self, t) return 1 end
			tal.getStatusMod = mode.getStatusMod or function(self, t) return 1 end
			
			tal.target = shape.target
			tal.getPowerModShape = shape.getPowerModShape
			tal.name = barrageName..""..shape.getSpellNameShape..""..element11.getSpellNameElement.."and "..element12.getSpellNameElement..mode.getSpellNameMode
			tal.getSpellShapeInfo = shape.getSpellShapeInfo
			tal.getSpellModeInfo = mode.getSpellModeInfo
			tal.getSpellElementInfo11 = element11.getSpellElementInfo 
			tal.getSpellElementInfo12 = element12.getSpellElementInfo 
			tal.getSpellModeInfoTwo = mode.getSpellModeInfoTwo
			tal.getElementColors11 = element11.getElementColors
			tal.getElementColors12 = element12.getElementColors
			tal.makeParticles = shape.makeParticles
			tal.getStatusChance11 = element11.getStatusChance
			tal.getStatusChance12 = element12.getStatusChance
			tal.getSpellStatusInflict11 = element11.getSpellStatusInflict
			tal.getSpellStatusInflict12 = element12.getSpellStatusInflict
--			tal.getStatusEffectTypes = table.mergeAdd((table.mergeAdd({},element11.getStatusEffectTypes)),element12.getStatusEffectTypes)
			tal.radius = shape.radius
			tal.range = shape.range 
			tal.isKamNoCheckCanProject = shape.isKamNoCheckCanProject
			
			tal.info = function(self, t)
				local spellModeInfoTwoData = nil 
				if type(t.getSpellModeInfoTwo) == "function" then 
					spellModeInfoTwoData = t.getSpellModeInfoTwo(self, t)
				else 
					spellModeInfoTwoData = t.getSpellModeInfoTwo
				end
				local inflictText = ""
				if t.getStatusMod(self, t) > 0 then
					inflictText = ([[ %s %s]]):tformat(
						t.getSpellStatusInflict11(self, t, t.getStatusChance11(self, t) * t.getPowerMod(self, t)*t.getStatusMod(self,t)*0.5),
						t.getSpellStatusInflict12(self, t, t.getStatusChance12(self, t) * t.getPowerMod(self, t)*t.getStatusMod(self,t)*0.5, true)
					)
				end
				return ([[%s%s %s %d %s damage and %d %s %s%s.]]):tformat(
					barrageString,
					t.getSpellShapeInfo(self, t), 
					t.getSpellModeInfo, 
					self:damDesc(t.getElement11(self, t), t.getElementDamage11(self, t, nil, t.kamModeUseFlatElementDamage)*t.getPowerMod(self, t)*t.getDamageMod(self,t)*0.5), 
					t.getSpellElementInfo11, 
					self:damDesc(t.getElement12(self, t), t.getElementDamage12(self, t, nil, t.kamModeUseFlatElementDamage)*t.getPowerMod(self, t)*t.getDamageMod(self,t)*0.5), 
					t.getSpellElementInfo12, 
					spellModeInfoTwoData, 
					inflictText
				)
			end
		end
	else 
		local mode1 = self.talents_def[ids.mode1]
		if mode1.kamSpellweaverModeCooldownIncrease then
			tal.cooldown = tal.cooldown + mode1.kamSpellweaverModeCooldownIncrease
		end
		tal.isKamIgnoreWalls = false
		tal.swapSpellOrder = mode1.isKamNoDoubleMode -- If true, then put this last. Walls mess up other effects so they need to swap.
		tal.getPowerMod = function(self, t) -- I figured this would always be the same but I guess not.
			if (t.isKamSpellSplitOne) then 
				return t.getPowerMod1(self, t)
			else 
				return t.getPowerMod2(self, t)
			end
		end
		tal.getPowerMod1 = function(self, t)
			return (t.getPowerModMode1(self, t) * t.getPowerModShape(self, t) * t.getPowerModBonus(self, t))
		end
		tal.getPowerMod2 = function(self, t)
			return (t.getPowerModMode2(self, t) * t.getPowerModShape(self, t) * t.getPowerModBonus(self, t))
		end
		tal.getElementColors = function(self, argsList, t)
			if (t.isKamSpellSplitOne) then 
				t.getElementColors1(self, argsList, t)
			else 
				t.getElementColors2(self, argsList, t)
			end
		end
		tal.getElementColors11 = function(self, argsList, t)
			if (t.isKamSpellSplitOne) then 
				t.getElementColors01(self, argsList, t)
			else 
				t.getElementColors21(self, argsList, t)
			end
		end
		tal.getElementColors12 = function(self, argsList, t)
			if (t.isKamSpellSplitOne) then 
				t.getElementColors02(self, argsList, t)
			else 
				t.getElementColors22(self, argsList, t)
			end
		end
		local element1 = self.talents_def[ids.element1]
		tal.isKamDuo1 = element1.isKamDuo
		local mode2 = self.talents_def[ids.mode2]
		if mode2.kamSpellweaverModeCooldownIncrease then
			tal.cooldown = tal.cooldown + mode2.kamSpellweaverModeCooldownIncrease
		end
		tal.kamModeUseFlatElementDamage1 = mode1.kamModeUseFlatElementDamage
		tal.kamModeUseFlatElementDamage2 = mode2.kamModeUseFlatElementDamage
		local element2 = self.talents_def[ids.element2]
		tal.isKamDuo2 = element2.isKamDuo
--		tal.getStatusEffectTypes1 = {}
--		tal.getStatusEffectTypes2 = {}
		tal.getElement1 = element1.getElement 
		tal.getElement2 = element2.getElement
		tal.getSpellElementInfo1Text = element1.getSpellElementInfo
		tal.getSpellElementInfo2Text = element2.getSpellElementInfo
		local elementNameOne = ""
		local elementNameTwo = ""
		if (tal.isKamDuo1) then 
			local element11 = self.talents_def[ids.element11]
			local element12 = self.talents_def[ids.element12]
			elementNameOne = element11.getSpellNameElement.."and "..element12.getSpellNameElement
			tal.isKamElementRandom1 = element11.isKamElementRandom or element12.isKamElementRandom
			tal.getElement11 = element11.getElement
			tal.getElement12 = element12.getElement
			tal.isKamPrismatic1 = element11.isKamPrismatic 
			tal.isKamPrismatic11 = element11.isKamPrismatic
			tal.isKamPrismatic1 = tal.isKamPrismatic1 or element12.isKamPrismatic 
			tal.isKamPrismatic12 = element12.isKamPrismatic
			tal.getElementDamage11 = element11.getElementDamage
			tal.getElementDamage12 = element12.getElementDamage
			tal.getSecond11 = element11.getSecond 
			tal.getSecond12 = element12.getSecond
			tal.getSpellElementInfo11 = element11.getSpellElementInfo 
			tal.getSpellElementInfo12 = element12.getSpellElementInfo 
			tal.getElementColors01 = element11.getElementColors -- Renamed to use 0 because the getter function is named 11 for use purposes.
			tal.getElementColors02 = element12.getElementColors -- Again, this was questionable planning, don't code like this.
			tal.getStatusChance11 = element11.getStatusChance
			tal.getStatusChance12 = element12.getStatusChance
			tal.getSpellStatusInflict11 = element11.getSpellStatusInflict
			tal.getSpellStatusInflict12 = element12.getSpellStatusInflict
--			table.mergeAdd(tal.getStatusEffectTypes1, element11.getStatusEffectTypes)
--			table.mergeAdd(tal.getStatusEffectTypes1, element12.getStatusEffectTypes)
			tal.isKamDoubleElement01 = element11.isKamDoubleElement
			tal.isKamDoubleElement02 = element12.isKamDoubleElement
		else
			elementNameOne = element1.getSpellNameElement
			tal.isKamPrismatic1 = element1.isKamPrismatic 
			tal.isKamElementRandom1 = element1.isKamElementRandom
			tal.getStatusChance1 = element1.getStatusChance
			tal.getSpellStatusInflict1 = element1.getSpellStatusInflict
			tal.getElementColors1 = element1.getElementColors
			tal.getSpellElementInfo1 = element1.getSpellElementInfo 
			tal.getElementDamage1 = element1.getElementDamage
			tal.getSecond1 = element1.getSecond
--			table.mergeAdd(tal.getStatusEffectTypes1, element1.getStatusEffectTypes)
			tal.isKamDoubleElement1 = element1.isKamDoubleElement
		end 
		if (tal.isKamDuo2) then 
			local element21 = self.talents_def[ids.element21]
			local element22 = self.talents_def[ids.element22]
			elementNameTwo = element21.getSpellNameElement.."and "..element22.getSpellNameElement
			tal.isKamElementRandom2 = element21.isKamElementRandom or element22.isKamElementRandom
			tal.getElement21 = element21.getElement
			tal.getElement22 = element22.getElement
			tal.isKamPrismatic2 = element21.isKamPrismatic 
			tal.isKamPrismatic21 = element21.isKamPrismatic
			tal.isKamPrismatic2 = tal.isKamPrismatic2 or element22.isKamPrismatic 
			tal.isKamPrismatic22 = element22.isKamPrismatic
			tal.getElementDamage21 = element21.getElementDamage
			tal.getElementDamage22 = element22.getElementDamage
			tal.getSecond21 = element21.getSecond 
			tal.getSecond22 = element22.getSecond
			tal.getSpellElementInfo21 = element21.getSpellElementInfo 
			tal.getSpellElementInfo22 = element22.getSpellElementInfo 
			tal.getElementColors21 = element21.getElementColors
			tal.getElementColors22 = element22.getElementColors
			tal.getStatusChance21 = element21.getStatusChance
			tal.getStatusChance22 = element22.getStatusChance
			tal.getSpellStatusInflict21 = element21.getSpellStatusInflict
			tal.getSpellStatusInflict22 = element22.getSpellStatusInflict
--			table.mergeAdd(tal.getStatusEffectTypes2, element21.getStatusEffectTypes)
--			table.mergeAdd(tal.getStatusEffectTypes2, element22.getStatusEffectTypes)
			tal.isKamDoubleElement21 = element21.isKamDoubleElement
			tal.isKamDoubleElement22 = element22.isKamDoubleElement
		else
			elementNameTwo = element2.getSpellNameElement
			tal.isKamPrismatic2 = element2.isKamPrismatic
			tal.isKamElementRandom2 = element2.isKamElementRandom
			tal.getStatusChance2 = element2.getStatusChance
			tal.getSpellStatusInflict2 = element2.getSpellStatusInflict
			tal.getSpellElementInfo2 = element2.getSpellElementInfo 
			tal.getElementDamage2 = element2.getElementDamage
			tal.getElementColors2 = element2.getElementColors
			tal.getSecond2 = element2.getSecond
--			table.mergeAdd(tal.getStatusEffectTypes2, element2.getStatusEffectTypes)
			tal.isKamDoubleElement2 = element2.isKamDoubleElement
		end
		tal.getSpellElementInfo1 = function(self, t)
			if t.isKamDuo1 then
				return t.getSpellElementInfo11.." and "..t.getSpellElementInfo12
			else 
				return t.getSpellElementInfo1Text
			end
		end
		tal.getSpellElementInfo2 = function(self, t)
			if t.isKamDuo2 then
				return t.getSpellElementInfo21.." and "..t.getSpellElementInfo22
			else 
				return t.getSpellElementInfo2Text
			end
		end
		
		tal.getDamageFunction1 = mode1.getDamageFunction 
		tal.getPowerModMode1 = mode1.getPowerModMode
		tal.getDamageFunction2 = mode2.getDamageFunction 
		tal.getPowerModMode2 = mode2.getPowerModMode
		tal.getDamageMod1 = mode1.getDamageMod or function(self, t) return 1 end
		tal.getStatusMod1 = mode1.getStatusMod or function(self, t) return 1 end
		tal.getDamageMod2 = mode2.getDamageMod or function(self, t) return 1 end
		tal.getStatusMod2 = mode2.getStatusMod or function(self, t) return 1 end
		tal.getSpellModeInfo1 = mode1.getSpellModeInfo 
		tal.getSpellModeInfoTwo1 = mode1.getSpellModeInfoTwo
		tal.getSpellModeInfo2 = mode2.getSpellModeInfo 
		tal.getSpellModeInfoTwo2 = mode2.getSpellModeInfoTwo
		
		
		tal.target = shape.target
		tal.getPowerModShape = shape.getPowerModShape

		tal.name = barrageName..""..shape.getSpellNameShape..""..elementNameOne.. ""..mode1.getSpellNameMode.." and "..elementNameTwo..""..mode2.getSpellNameMode

		tal.getSpellShapeInfo = shape.getSpellShapeInfo
		tal.makeParticles = shape.makeParticles
		tal.radius = shape.radius
		tal.range = shape.range 
		tal.isKamNoCheckCanProject = shape.isKamNoCheckCanProject
		tal.getSpellInfoGreen = function(self, t)
			if (t.isKamDuo1) then 
				local spellModeInfoTwoData = nil 
				if type(t.getSpellModeInfoTwo1) == "function" then 
					spellModeInfoTwoData = t.getSpellModeInfoTwo1(self, t, 0)
				else 
					spellModeInfoTwoData = t.getSpellModeInfoTwo1
				end
				local inflictText = ""
				if t.getStatusMod1(self, t) > 0 then
					inflictText = ([[ %s %s]]):tformat(
						t.getSpellStatusInflict11(self, t, t.getStatusChance11(self, t) * t.getPowerMod1(self, t)*t.getStatusMod1(self,t)*0.5),
						t.getSpellStatusInflict12(self, t, t.getStatusChance12(self, t) * t.getPowerMod1(self, t)*t.getStatusMod1(self,t)*0.5, true)
					)
				end
				return ([[%s%s %d %s damage and %d %s %s%s.]]):tformat(
					barrageString,
					t.getSpellModeInfo1, 
					self:damDesc(t.getElement11(self, t), t.getElementDamage11(self, t, nil, t.kamModeUseFlatElementDamage1) * t.getPowerMod1(self, t) * t.getDamageMod1(self,t) * 0.5),
					t.getSpellElementInfo11, 
					self:damDesc(t.getElement12(self, t), t.getElementDamage12(self, t, nil, t.kamModeUseFlatElementDamage1) * t.getPowerMod1(self, t) * t.getDamageMod1(self,t) * 0.5),
					t.getSpellElementInfo12, 
					spellModeInfoTwoData, 
					inflictText
				)
			else 
				local spellModeInfoTwoData = nil 
				if type(t.getSpellModeInfoTwo1) == "function" then 
					spellModeInfoTwoData = t.getSpellModeInfoTwo1(self, t, 0)
				else 
					spellModeInfoTwoData = t.getSpellModeInfoTwo1
				end
				local inflictText = ""
				if t.getStatusMod1(self, t) > 0 then
					inflictText = ([[ %s]]):tformat(t.getSpellStatusInflict1(self, t, t.getStatusChance1(self, t) * t.getPowerMod1(self, t)*t.getStatusMod1(self,t)))
				end
				return ([[%s%s %d %s %s%s.]]):tformat(
					barrageString,
					t.getSpellModeInfo1, 
					self:damDesc(t.getElement1(self, t), t.getElementDamage1(self, t, nil, t.kamModeUseFlatElementDamage1) * t.getPowerMod1(self, t) * t.getDamageMod1(self,t)), 
					t.getSpellElementInfo1(self, t),
					spellModeInfoTwoData,
					inflictText
				)
			end
		end
		tal.getSpellInfoPurple = function(self, t)
			if (t.isKamDuo2) then 
				local spellModeInfoTwoData = nil 
				if type(t.getSpellModeInfoTwo2) == "function" then 
					spellModeInfoTwoData = t.getSpellModeInfoTwo2(self, t, 1)
				else 
					spellModeInfoTwoData = t.getSpellModeInfoTwo2
				end
				local inflictText = ""
				if t.getStatusMod2(self, t) > 0 then
					inflictText = ([[ %s %s]]):tformat(
						t.getSpellStatusInflict21(self, t, t.getStatusChance21(self, t) * t.getPowerMod2(self, t)*t.getStatusMod2(self,t)*0.5),
						t.getSpellStatusInflict22(self, t, t.getStatusChance22(self, t) * t.getPowerMod2(self, t)*t.getStatusMod2(self,t)*0.5, true)
					)
				end
				return ([[%s %d %s damage and %d %s %s%s.]]):tformat(
					t.getSpellModeInfo2,
					self:damDesc(t.getElement21(self, t), t.getElementDamage21(self, t, nil, t.kamModeUseFlatElementDamage2) * t.getPowerMod2(self, t) * t.getDamageMod2(self,t) * 0.5),
					t.getSpellElementInfo21, 
					self:damDesc(t.getElement22(self, t), t.getElementDamage22(self, t, nil, t.kamModeUseFlatElementDamage2) * t.getPowerMod2(self, t) * t.getDamageMod2(self,t) * 0.5),
					t.getSpellElementInfo22, 
					spellModeInfoTwoData, 
					inflictText
				)
			else 
				local spellModeInfoTwoData = nil 
				if type(t.getSpellModeInfoTwo2) == "function" then 
					spellModeInfoTwoData = t.getSpellModeInfoTwo2(self, t, 1)
				else 
					spellModeInfoTwoData = t.getSpellModeInfoTwo2
				end
				local inflictText = ""
				if t.getStatusMod2(self, t) > 0 then
					inflictText = ([[ %s]]):tformat(t.getSpellStatusInflict2(self, t, t.getStatusChance2(self, t) * t.getPowerMod2(self, t)*t.getStatusMod2(self,t)))
				end
				return ([[%s %d %s %s%s.]]):tformat( 
					t.getSpellModeInfo2, 
					self:damDesc(t.getElement2(self, t), t.getElementDamage2(self, t, nil, t.kamModeUseFlatElementDamage2) * t.getPowerMod2(self, t) * t.getDamageMod2(self,t)), 
					t.getSpellElementInfo2(self, t), 
					spellModeInfoTwoData, 
					inflictText
				)
			end
		end
		
		tal.info = function(self, t)			
			local spellModeInfoTwoData = nil 
			if type(t.getSpellModeInfoTwo) == "function" then 
				spellModeInfoTwoData = t.getSpellModeInfoTwo(self, t)
			else 
				spellModeInfoTwoData = t.getSpellModeInfoTwo
			end
			return ([[%s%s, where each off the "on" and "off" tiles have a different effect.
Green squares are spells %s

Purple squares are spells %s]]):tformat(
				barrageString,
				t.getSpellShapeInfo(self, t), 
				t.getSpellInfoGreen(self, t),
				t.getSpellInfoPurple(self, t)
			)
		end
	end
	tal.isKamSpellCrafted = true
end

function _M:kam_build_shield_spell_from_ids(ids)
	_M:kam_before_build_spells(self, ids)
	local tal = self.talents_def[ids.slot]
	tal.image = "talents/kam_spellweaver_spellslot_shield_"..tal.kamSpellSlotNumber..".png"
	tal.display_entity = spellwovenTalentDisplayEntities.shield[tal.kamSpellSlotNumber]
	local mode = self.talents_def[ids.mode]
	
	if mode.short_name == "KAM_SHIELDMODE_SUSTAINED" then -- Special case for sustained shield.
		cleanReplaceTable(tal, ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_SHIELD_SUSTAIN])
	elseif mode.short_name == "KAM_SHIELDMODE_CONTINGENCY" then 
		cleanReplaceTable(tal, ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_SHIELD_CONTINGENCY])
	else
		cleanReplaceTable(tal, ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_SHIELD])
	end
	
	tal.no_silence = not mode.kamNoSilence
	
	tal.getShieldFunction = mode.getShieldFunction
	tal.getPowerModMode = mode.getPowerModMode
	local bonus = self.talents_def[ids.bonus]
	tal.doBonus = bonus.doBonus
	tal.getPowerModBonus = bonus.getPowerModBonus

	tal.getModeDescriptor = mode.getModeDescriptor
	tal.getBonusDescriptor = bonus.getBonusDescriptor
	
	tal.bonusType = bonus.bonusType -- Explanation: bonus = 0 is for no bonus, 1 is for bonus on shield break, 2 is for bonus on each hit affecting damage inflictor, 3 is for constant bonus, 4 is for bonus on each hit affecting self, 5 is on setup/teardown (for things that use temporary values).
	tal.bonusAssociatedFunction = bonus.bonusAssociatedFunction -- Any function for the bonus to make listing it easier.
	
	local eleName = ""
	if ids.element then -- I forgot how busy I made elements.
		if ids.element1 and ids.element2 then 
			local element1 = self.talents_def[ids.element1]
			local element2 = self.talents_def[ids.element2]
			tal.isKamElementRandom = element1.isKamElementRandom or element2.isKamElementRandom
			tal.isKamDuo = true
			tal.getElement1 = element1.getElement
			tal.getElementDamage1 = element1.getElementDamage
			tal.getSecond1 = element1.getSecond
			tal.getStatusChance1 = element1.getStatusChance
			tal.getElementColors1 = element1.getElementColors
			tal.getSpellStatusInflict1 = element1.getSpellStatusInflict
			tal.getSpellElementInfo1 = element1.getSpellElementInfo
			tal.isKamPrismatic1 = element1.isKamPrismatic
			
			tal.getElement2 = element2.getElement
			tal.getElementDamage2 = element2.getElementDamage
			tal.getSecond2 = element2.getSecond
			tal.getStatusChance2 = element2.getStatusChance
			tal.getElementColors2 = element2.getElementColors
			tal.getSpellStatusInflict2 = element2.getSpellStatusInflict
			tal.getSpellElementInfo2 = element2.getSpellElementInfo
			tal.isKamPrismatic2 = element2.isKamPrismatic
			
			tal.getSpellStatusInflict = function(self, t, mod)
				mod = mod or 1
				local descriptor1 = tal.getSpellStatusInflict1(self, t, mod * t.getStatusChance1(self, t) * t.getPowerMod(self, t) * 0.5, false, true)
				local descriptor2 = tal.getSpellStatusInflict2(self, t, mod * t.getStatusChance2(self, t) * t.getPowerMod(self, t) * 0.5, true)
				return descriptor1.." ".. descriptor2
			end
			eleName = element1.getSpellNameElement.."and "..element2.getSpellNameElement
		else
			local element = self.talents_def[ids.element]
			tal.isKamElementRandom = element.isKamElementRandom
			tal.isKamDuo = false
			tal.getElement = element.getElement
			tal.getElementDamage = element.getElementDamage
			tal.getSecond = element.getSecond
			tal.getStatusChance = element.getStatusChance
			tal.getElementColors = element.getElementColors
			tal.getSpellStatusInflictHold = element.getSpellStatusInflict
			tal.getSpellElementInfo = element.getSpellElementInfo
			tal.isKamPrismatic = element.isKamPrismatic
			
			tal.getSpellStatusInflict = function(self, t, mod)
				return tal.getSpellStatusInflictHold(self, t, mod * t.getStatusChance(self, t) * t.getPowerMod(self, t), false, true)
			end
			eleName = element.getSpellNameElement
		end
		tal.shieldUsesKamElement = true
	end
	
	tal.name = eleName..mode.getModeName..""..bonus.getBonusName
	
	if mode.speedMod then 
		tal.kamOldSpeed = tal.speed
		tal.kamModeSpeedMod = mode.speedMod
		tal.speed = function(self, t) 
			return tal.kamOldSpeed(self, t) + tal.kamModeSpeedMod
		end
	end
	
	tal.onBuildover = mode.onBuildover
	tal.info = function(self, t)
		local modeDescription = t.getModeDescriptor(self, t)
		local bonusDescription = t.getBonusDescriptor(self, t)
		return ([[%s %s]]):tformat(modeDescription, bonusDescription)
	end
	tal.isKamSpellCrafted = true
end

function _M:kam_build_teleport_spell_from_ids(ids)
	_M:kam_before_build_spells(self, ids)
	local tal = self.talents_def[ids.slot]
	local mode = self.talents_def[ids.mode]
	tal.image = "talents/kam_spellweaver_spellslot_teleport_"..tal.kamSpellSlotNumber..".png"
	tal.display_entity = spellwovenTalentDisplayEntities.teleport[tal.kamSpellSlotNumber]
	
	cleanReplaceTable(tal, ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_MOVEMENT])
	
	tal.getTeleportFunction = mode.getTeleportFunction
	tal.getPowerModMode = mode.getPowerModMode
	local bonus = self.talents_def[ids.bonus]
	tal.doBonus = bonus.doBonus
	tal.getPowerModBonus = bonus.getPowerModBonus

	tal.getModeDescriptor = mode.getModeDescriptor
	tal.getBonusDescriptor = bonus.getBonusDescriptor
	tal.replaceParticles = bonus.replaceParticles
	
	tal.no_silence = not mode.kamNoSilence

	tal.no_energy = mode.kamIsInstant
	
	tal.bonusType = bonus.bonusType -- Explanation: bonus = 0 is for no bonus, 1 is for teleport end, 2 is for teleport start, 3 is for both.
	tal.bonusAssociatedFunction = bonus.bonusAssociatedFunction -- Any function for the bonus to make listing it easier.
	
	local eleName = ""
	if ids.element then -- I forgot how busy I made elements.
		if ids.element1 and ids.element2 then 
			local element1 = self.talents_def[ids.element1]
			local element2 = self.talents_def[ids.element2]
			tal.isKamElementRandom = element1.isKamElementRandom or element2.isKamElementRandom
			tal.isKamDuo = true
			tal.getElement1 = element1.getElement
			tal.getElementDamage1 = element1.getElementDamage
			tal.getSecond1 = element1.getSecond
			tal.getStatusChance1 = element1.getStatusChance
			tal.getElementColors1 = element1.getElementColors
			tal.getSpellStatusInflict1 = element1.getSpellStatusInflict
			tal.getSpellElementInfo1 = element1.getSpellElementInfo
			tal.isKamPrismatic1 = element1.isKamPrismatic
			
			tal.getElement2 = element2.getElement
			tal.getElementDamage2 = element2.getElementDamage
			tal.getSecond2 = element2.getSecond
			tal.getStatusChance2 = element2.getStatusChance
			tal.getElementColors2 = element2.getElementColors
			tal.getSpellStatusInflict2 = element2.getSpellStatusInflict
			tal.getSpellElementInfo2 = element2.getSpellElementInfo
			tal.isKamPrismatic2 = element2.isKamPrismatic
			
			tal.getSpellStatusInflict = function(self, t)
				local descriptor1 = tal.getSpellStatusInflict1(self, t, t.getStatusChance1(self, t) * t.getPowerMod(self, t) * 0.5 / 3, false, true)
				local descriptor2 = tal.getSpellStatusInflict2(self, t, t.getStatusChance2(self, t) * t.getPowerMod(self, t) * 0.5 / 3, true)
				return descriptor1.." ".. descriptor2
			end
			eleName = element1.getSpellNameElement.."and "..element2.getSpellNameElement
		else
			local element = self.talents_def[ids.element]
			tal.isKamElementRandom = element.isKamElementRandom
			tal.isKamDuo = false
			tal.getElement = element.getElement
			tal.getElementDamage = element.getElementDamage
			tal.getSecond = element.getSecond
			tal.getStatusChance = element.getStatusChance
			tal.getElementColors = element.getElementColors
			tal.getSpellStatusInflictHold = element.getSpellStatusInflict
			tal.getSpellElementInfo = element.getSpellElementInfo
			tal.isKamPrismatic = element.isKamPrismatic
			
			tal.getSpellStatusInflict = function(self, t)
				return tal.getSpellStatusInflictHold(self, t, t.getStatusChance(self, t) * t.getPowerMod(self, t) / 3, false, true)
			end
			eleName = element.getSpellNameElement
		end
	end
	tal.name = eleName..bonus.getBonusName..mode.getModeName
	
	tal.onBuildover = mode.onBuildover
	tal.kamOnReloadToME = mode.kamOnReloadToME -- Upvalue related fix
	tal.info = function(self, t)
		local modeDescription = t.getModeDescriptor(self, t)
		local bonusDescription = t.getBonusDescriptor(self, t)
		return ([[%s %s]]):tformat(modeDescription, bonusDescription)
	end
	tal.isKamSpellCrafted = true
end

function _M:kam_calc_cross(x, y, w, h, size, block, apply)
	apply(_, x, y)
	if (type(block) ~= "function") then
		local blockCheck = block
		block = function(_, x, y)
			if blockCheck then
				return game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move")
			end
			return false
		end
	end
	for i=1, size do
		if (x+i) > w then break end
		if block(_, x+i, y) then 
			apply(_, x+i, y)
			break
		end
		apply(_, x+i, y)
	end
	
	for i=1, size do
		if (x-i) < 0 then break end
		if block(_, x-i, y) then
			apply(_, x-i, y)
			break
		end
		apply(_, x-i, y)
	end
	
	for i=1, size do
		if (y+i) > h then break end
		if block(_, x, y+i) then
			apply(_, x, y+i)
			break
		end
		apply(_, x, y+i)
	end
	
	for i=1, size do
		if (y-i) < 0 then break end
		if block(_, x, y-i) then
			apply(_, x, y-i)
			break
		end
		apply(_, x, y-i)
	end
end

function _M:kam_calc_spiral(x, y, w, h, size, source_x, source_y, delta_x, delta_y, block, apply, forcedDir, forcedDirStep)
	apply(_, x, y)
	if not ((type(block) == "function" and block(_, x, y)) or (type(block) ~= "function" and block and game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move"))) then 
		local curX = x
		local curY = y
		local dir = 0
		local dirStep = 1
		if forcedDir then
			dir = forcedDir
			dirStep = forcedDirStep
		else
			local angle = math.deg(math.atan2(delta_y, delta_x))
			if angle < 45 and angle >= -45 then 
				dir = 0
			elseif angle < 135 and angle >= 45 then 
				dir = 3
			elseif angle < -135 or angle >= 135 then 
				dir = 2
			elseif angle < -45 and angle >= -135 then 
				dir = 1
			end
			if (angle % 90 < 45) then -- Potentially remove if targeting is too complex
				dirStep = -1
			else 
				dirStep = 1
			end
		end
		local breakAll = false
		for i=1, size do 
			for i2=1, i do
				if dir == 0 then 
					curX = curX + 1
					if curX > w then 
						breakAll = true
						break 
					end
				elseif dir == 1 then 
					curY = curY - 1
					if curY < 0 then 
						breakAll = true
						break 
					end
				elseif dir == 2 then 
					curX = curX - 1
					if curX < 0 then 
						breakAll = true
						break 
					end
				elseif dir == 3 then 
					curY = curY + 1
					if curY > h then 
						breakAll = true
						break 
					end
				end
				if (type(block) == "function" and block(_, curX, curY)) or (block and game.level.map:checkEntity(curX, curY, engine.Map.TERRAIN, "block_move")) then 
					apply(_, curX, curY)
					breakAll = true
					break
				end
				apply(_, curX, curY)
			end
			if breakAll then 
				break
			end
			dir = dir + dirStep
			if dir > 3 then 
				dir = 0
			elseif dir < 0 then 
				dir = 3
			end
		end
	end
end

function _M:kam_calc_doublespiral(x, y, w, h, offset, size, source_x, source_y, delta_x, delta_y, block, apply, apply2)
	local a1
	local a2

	if (offset ~= 0) then
		a1 = apply2
		a2 = apply
	else
		a1 = apply
		a2 = apply2
	end

	local dir1
	local dir2
	local dirStep
	local angle = math.deg(math.atan2(delta_y, delta_x))
	if angle < 45 and angle >= -45 then 
		dir1 = 0
		dir2 = 2
	elseif angle < 135 and angle >= 45 then 
		dir1 = 3
		dir2 = 1
	elseif angle < -135 or angle >= 135 then 
		dir1 = 2
		dir2 = 0
	elseif angle < -45 and angle >= -135 then 
		dir1 = 1
		dir2 = 3
	end
	if (angle % 90 < 45) then
		dirStep = -1
	else 
		dirStep = 1
	end

	if a1 then
		_M:kam_calc_spiral(
			x,
			y,
			w,
			h,
			size,
			source_x,
			source_y,
			delta_x,
			delta_y,
			block,
			a1,
			dir1,
			dirStep,
		nil)
	end
	
	if a2 then
		local xMod = 0
		local yMod = 0
		if angle < 45 and angle >= -45 then 
			yMod = -1
		elseif angle < 135 and angle >= 45 then 
			xMod = -1
		elseif angle < -135 or angle >= 135 then 
			yMod = 1
		elseif angle < -45 and angle >= -135 then 
			xMod = 1
		end
		if ((angle < 90 and angle >= 0) or (angle < -90 or angle == 180)) then
			xMod = -1 * xMod
			yMod = -1 * yMod
		end
		_M:kam_calc_spiral(
			x + xMod,
			y + yMod,
			w,
			h,
			size,
			source_x,
			source_y,
			delta_y,
			delta_x,
			block,
			a2,
			dir2,
			dirStep,
		nil)
	end
end

function _M:kam_calc_doublespiral_endpoints(x, y, w, h, offset, size, source_x, source_y, delta_x, delta_y, block, apply, apply2)
	local a1
	local a2

	if (offset ~= 0) then
		a1 = apply2
		a2 = apply
	else
		a1 = apply
		a2 = apply2
	end

	local dir1
	local dir2
	local dirStep
	local angle = math.deg(math.atan2(delta_y, delta_x))
	if angle < 45 and angle >= -45 then 
		dir1 = 0
		dir2 = 2
	elseif angle < 135 and angle >= 45 then 
		dir1 = 3
		dir2 = 1
	elseif angle < -135 or angle >= 135 then 
		dir1 = 2
		dir2 = 0
	elseif angle < -45 and angle >= -135 then 
		dir1 = 1
		dir2 = 3
	end
	if (angle % 90 < 45) then
		dirStep = -1
	else 
		dirStep = 1
	end

	if a1 then
		_M:kam_calc_spiral_endpoints(
			x,
			y,
			w,
			h,
			size,
			source_x,
			source_y,
			delta_x,
			delta_y,
			block,
			a1,
			dir1,
			dirStep,
		nil)
	end
	
	if a2 then
		local xMod = 0
		local yMod = 0
		if angle < 45 and angle >= -45 then 
			yMod = -1
		elseif angle < 135 and angle >= 45 then 
			xMod = -1
		elseif angle < -135 or angle >= 135 then 
			yMod = 1
		elseif angle < -45 and angle >= -135 then 
			xMod = 1
		end
		if ((angle < 90 and angle >= 0) or (angle < -90 or angle == 180)) then
			xMod = -1 * xMod
			yMod = -1 * yMod
		end
		_M:kam_calc_spiral_endpoints(
			x + xMod,
			y + yMod,
			w,
			h,
			size,
			source_x + xMod,
			source_y + yMod,
			delta_y,
			delta_x,
			block,
			a2,
			dir2,
			dirStep,
		nil)
	end
end

function _M:kam_calc_wall_endpoints(x, y, w, h, halflength, halfmax_spots, source_x, source_y, delta_x, delta_y, block, apply)
	delta_x, delta_y = deltaCoordsToReal(delta_x, delta_y, source_x, source_y)

	local angle = math.atan2(delta_y, delta_x) + math.pi / 2

	local dx, dy = math.cos(angle) * halflength, math.sin(angle) * halflength
	local adx, ady = math.abs(dx), math.abs(dy)

	local x1, y1 = deltaRealToCoords( dx,  dy, x, y)
	local x2, y2 = deltaRealToCoords(-dx, -dy, x, y)

	local spots = 1
	local wall_block_corner = function(_, bx, by)
		if halfmax_spots and spots > halfmax_spots or math.floor(core.fov.distance(x2, y2, bx, by, true) - 0.25) > 2*halflength then return true end
		--apply(_, bx, by)
		spots = spots + 1
		return block(_, bx, by)
	end

	local l = core.fov.line(x+0.5, y+0.5, x1+0.5, y1+0.5, function(_, bx, by) return true end)
	l:set_corner_block(wall_block_corner)
	-- use the correct tangent (not approximate) and round corner tie-breakers toward the player (via wiggles!)
	if adx < ady then
		l:change_step(dx/ady, dy/ady)
		if delta_y < 0 then l:wiggle(true) else l:wiggle() end
	else
		l:change_step(dx/adx, dy/adx)
		if delta_x < 0 then l:wiggle(true) else l:wiggle() end
	end
	--local cx = x
	--local cy = y
	while true do
		local lx, ly, is_corner_blocked = l:step(true)
		if not lx or is_corner_blocked or halfmax_spots and spots > halfmax_spots or math.floor(core.fov.distance(x2, y2, lx, ly, true) + 0.25) > 2*halflength then 
			apply(_, lx, ly)
			break 
		end
		spots = spots + 1
		if block(_, lx, ly) then 
			apply(_, lx, ly)
			break 
		end
		--cx, cy = lx, ly
	end

	spots = 1
	wall_block_corner = function(_, bx, by)
		if halfmax_spots and spots > halfmax_spots or math.floor(core.fov.distance(x1, y1, bx, by, true) - 0.25) > 2*halflength then return true end
		--apply(_, bx, by)
		spots = spots + 1
		return block(_, bx, by)
	end

	local l = core.fov.line(x+0.5, y+0.5, x2+0.5, y2+0.5, function(_, bx, by) return true end)
	l:set_corner_block(wall_block_corner)
	-- use the correct tangent (not approximate) and round corner tie-breakers toward the player (via wiggles!)
	if adx < ady then
		l:change_step(-dx/ady, -dy/ady)
		if delta_y < 0 then l:wiggle(true) else l:wiggle() end
	else
		l:change_step(-dx/adx, -dy/adx)
		if delta_x < 0 then l:wiggle(true) else l:wiggle() end
	end
	--cx = x
	--cy = y
	while true do
		local lx, ly, is_corner_blocked = l:step(true)
		if not lx or is_corner_blocked or halfmax_spots and spots > halfmax_spots or math.floor(core.fov.distance(x1, y1, lx, ly, true) + 0.25) > 2*halflength then 
			apply(_, lx, ly)
			break 
		end
		spots = spots + 1
		if block(_, lx, ly) then 
			apply(_, lx, ly)
			break 
		end
		--cx, cy = lx, ly
	end
end

-- Runs the apply function on the previous and current X and Y values whenever the spiral hits an end point. Always spirals out from source location.
function _M:kam_calc_spiral_endpoints(x, y, w, h, size, source_x, source_y, delta_x, delta_y, block, apply, forcedDir, forcedDirStep)
	local prevX = source_x
	local prevY = source_y
	if not ((type(block) == "function" and block(_, prevX, prevY)) or (block and game.level.map:checkEntity(prevX, prevY, engine.Map.TERRAIN, "block_move"))) then 
		local curX = source_x
		local curY = source_y
		local dir = 0
		local dirStep = 1
		if forcedDir then
			dir = forcedDir
			dirStep = forcedDirStep
		else
			local angle = math.deg(math.atan2(delta_y, delta_x))
			if angle < 45 and angle >= -45 then 
				dir = 0
			elseif angle < 135 and angle >= 45 then 
				dir = 3
			elseif angle < -135 or angle >= 135 then 
				dir = 2
			elseif angle < -45 and angle >= -135 then 
				dir = 1
			end
			if (angle % 90 < 45) then -- Potentially remove if targeting is too complex
				dirStep = -1
			else 
				dirStep = 1
			end
		end
		local breakAll = false
		for i=1, size do 
			for i2=1, i do
				if dir == 0 then 
					curX = curX + 1
					if curX > w then 
						breakAll = true
						break 
					end
				elseif dir == 1 then 
					curY = curY - 1
					if curY < 0 then 
						breakAll = true
						break 
					end
				elseif dir == 2 then 
					curX = curX - 1
					if curX < 0 then 
						breakAll = true
						break 
					end
				elseif dir == 3 then 
					curY = curY + 1
					if curY > h then 
						breakAll = true
						break 
					end
				end
				if (type(block) == "function" and block(_, curX, curY)) or (block and game.level.map:checkEntity(curX, curY, engine.Map.TERRAIN, "block_move")) then 
					apply(prevX, prevY, curX, curY)
					breakAll = true
					break
				end
			end
			apply(prevX, prevY, curX, curY)
			prevX = curX
			prevY = curY
			if breakAll then 
				break
			end
			dir = dir + dirStep
			if dir > 3 then 
				dir = 0
			elseif dir < 0 then 
				dir = 3
			end
		end
	end
end
-- 0 = -x, 1 = +x, 2 = -y, 3 = +y, 4 = -x-y, 5 = +x-y, 6 = -y+x, 7 = +x+y
local function extendLine(x, y, w, h, dir, dist, block, apply, applyAtEndpoint)
	for i = 1, dist do 
		if dir == 0 then 
			x = x - 1
			if (x < 0) then break end
		elseif dir == 1 then 
			x = x + 1
			if (x >= w) then break end
		elseif dir == 2 then 
			y = y - 1
			if (y < 0) then break end
		elseif dir == 3 then
			y = y + 1
			if (y >= h) then break end
		elseif dir == 4 then 
			x = x - 1
			y = y - 1
			if (x < 0) or (y < 0) then break end
		elseif dir == 5 then 
			x = x - 1
			y = y + 1
			if (x < 0) or (y >= h) then break end
		elseif dir == 6 then 
			x = x + 1
			y = y - 1
			if (x >= w) or (y < 0) then break end
		else
			x = x + 1
			y = y + 1
			if (x >= w) or (y >= h) then break end
		end
		if (type(block) == "function" and block(_, x, y)) or (type(block) ~= "function" and game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move")) then 
			if applyAtEndpoint then
				apply(x, y)
			end
			break
		end
		if not applyAtEndpoint then
			apply(x, y)
		end
	end
end

-- As always, offset 1 or 0.
function _M:kam_calc_eightpoint(w, h, size, source_x, source_y, delta_x, delta_y, offset, block, apply, apply2)
	local angle = math.deg(math.atan2(delta_y, delta_x))
	if (angle % 180) < 90 then 
		offset = offset + 1
	end
	-- Conversions for extendLine
	doApply = function(x, y)
		if apply then
			apply(_, x, y)
		end
	end
	doApply2 = function(x, y)
		if apply2 then 
			apply2(_, x, y)
		end
	end
	for i = 0, 7 do
		if ((i > 3) == (offset % 2 ~= 0)) then
			extendLine(source_x, source_y, w, h, i, size, block, doApply2)
		else
			extendLine(source_x, source_y, w, h, i, size, block, doApply)
		end
	end
end
-- Applies only to endpoints (for particles)
function _M:kam_calc_eightpoint_endpoint(w, h, size, source_x, source_y, delta_x, delta_y, offset, block, apply, apply2)
	local angle = math.deg(math.atan2(delta_y, delta_x))
	if (angle % 180) < 90 then 
		offset = offset + 1
	end
	-- Conversions for extendLine
	doApply = function(x, y)
		if apply then
			apply(_, x, y)
		end
	end
	doApply2 = function(x, y)
		if apply2 then 
			apply2(_, x, y)
		end
	end
	for i = 0, 7 do
		if ((i > 3) == (offset % 2 ~= 0)) then
			extendLine(source_x, source_y, w, h, i, size, block, doApply2, true)
		else
			extendLine(source_x, source_y, w, h, i, size, block, doApply, true)
		end
	end
end


-- Offset is 1 or 0.
function _M:kam_calc_checkerboard(x, y, w, h, size, offset, block, apply, apply2)
	local startX = x 
	local startY = y
	doApply = function(x, y)
		if ((startX - x - y + startY) % 2 == offset) then 
			apply(_, x, y)
		elseif (apply2) then 
			apply2(_, x, y)
		end
	end
	doApply(x, y)
	for i = 0, 3 do 
		extendLine(x, y, w, h, i, size, block, doApply)
	end
	for i1 = 1, size do 
		x = startX + i1 
		y = startY + i1
		if (x >= w) or (y >= h) then 
			break 
		end
		if (type(block) == "function" and block(_, x, y)) or (block and game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move")) then
			doApply(x, y)
			break
		end
		doApply(x, y)
		if (i1 < size) then 
			extendLine(x, y, w, h, 1, size-i1, block, doApply)
			extendLine(x, y, w, h, 3, size-i1, block, doApply)
		end
	end
	for i1 = 1, size do 
		x = startX + i1 
		y = startY - i1
		if (x >= w) or (y < 0) then 
			break 
		end
		if (type(block) == "function" and block(_, x, y)) or (block and game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move")) then 
			doApply(x, y)
			break
		end
		doApply(x, y)
		if (i1 < size) then 
			extendLine(x, y, w, h, 1, size-i1, block, doApply)
			extendLine(x, y, w, h, 2, size-i1, block, doApply)
		end
	end
	for i1 = 1, size do 
		x = startX - i1 
		y = startY + i1
		if (x < 0) or (y >= h) then 
			break 
		end
		if (type(block) == "function" and block(_, x, y)) or (block and game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move")) then
			doApply(x, y)
			break
		end
		doApply(x, y)
		if (i1 < size) then 
			extendLine(x, y, w, h, 0, size-i1, block, doApply)
			extendLine(x, y, w, h, 3, size-i1, block, doApply)
		end
	end
	for i1 = 1, size do 
		x = startX - i1 
		y = startY - i1
		if (x < 0) or (y < 0) then 
			break 
		end
		if (type(block) == "function" and block(_, x, y)) or (block and game.level.map:checkEntity(x, y, engine.Map.TERRAIN, "block_move")) then 
			doApply(x, y)
			break
		end
		doApply(x, y)
		if (i1 < size) then 
			extendLine(x, y, w, h, 0, size-i1, block, doApply)
			extendLine(x, y, w, h, 2, size-i1, block, doApply)
		end
	end
end

-- Offset is 1 or 0 again.
function _M:kam_calc_wavepulse(x, y, w, h, size, offset, block, apply, apply2)
	local startX = x 
	local startY = y
	local doApply = function(x, y)
		if math.ceil(core.fov.distance(x, y, startX, startY)) % 2 ~= offset then 
			apply(_, x, y)
		elseif apply2 then
			apply2(_, x, y)
		end
	end
	core.fov.calc_circle( -- Originally I had a whole complicated calculation for this but now we use this instead because the logic on what was blocked didn't make sense that way.
		x,
		y,
		w,
		h,
		size,
		function(_, px, py)
			return block(_, px, py)
		end,
		function(_, px, py)
			doApply(px, py)
		end,
	nil)
end

function _M:kam_make_smiley(x, y, w, h, block, apply)
	local startX = x 
	local startY = y
	core.fov.calc_circle(
		x,
		y,
		w,
		h,
		2,
		function(_, px, py)
			return block(_, px, py)
		end,
		function(_, px, py)
			if ((math.abs(px - startX) == 2) and (startY - py == -1)) or ((math.abs(px - startX) == 1) and (math.abs(py - startY) == 2)) or (px - startX == 0 and startY - py == -2) then
				apply(_, px, py)
			end
		end,
	nil)
end

-- Prepare for the world's worst if/elseif block. SO MANY or...
-- But I can't figure out a good mathematical descriptor for this shape that applies nicely within a tile grid so...
function _M:kam_make_flower(x, y, w, h, offset, block, apply, apply2)
	local startX = x 
	local startY = y
	core.fov.calc_circle(
		x,
		y,
		w,
		h,
		6,
		function(_, px, py)
			return block(_, px, py)
		end,
		function(_, px, py) -- This hurt to make.
			local a1
			local a2
			if offset == 0 then
				a1 = apply
				a2 = apply2
			else 
				a1 = apply2
				a2 = apply
			end
			if a1 and ((math.abs(px - startX) == 5 and py - startY == 0) or (px - startX == -5 and py - startY == 1) or (px - startX == 5 and py - startY == -1) or 
					(math.abs(px - startX) == 4 and (math.abs(py - startY) == 2 or math.abs(py - startY) == 3)) or (px - startX == 4 and py - startY == 1) or (px - startX == -4 and py - startY == -1) or
					(math.abs(px - startX) == 3 and math.abs(py - startY) == 4) or (px - startX == 3 and (py - startY == -2 or py - startY == 1)) or (px - startX == -3 and (py - startY == -1 or py - startY == 2)) or
					(math.abs(px - startX) == 2 and (math.abs(py - startY) == 4 or math.abs(py - startY) == 1 or py - startY == 0)) or (px - startX == -2 and py - startY == -3) or (px - startX == 2 and py - startY == 3) or
					(math.abs(px - startX) == 1 and math.abs(py - startY) == 2) or (px - startX == -1 and (py - startY == 3 or py - startY == 4 or py - startY == -5)) or (px - startX == 1 and (py - startY == -3 or py - startY == -4 or py - startY == 5)) or
					(px - startX == 0 and (math.abs(py - startY) == 2 or math.abs(py - startY) == 5))) then 
				a1(_, px, py)
			elseif a2 and ((math.abs(px - startX) == 4 and py - startY == 0) or (px - startX == 4 and py - startY == -1) or (px - startX == -4 and py - startY == 1) or
					(math.abs(px - startX) == 3 and (math.abs(py - startY) == 3 or py - startY == 0)) or (px - startX == -3 and py - startY == -2) or (px - startX == 3 and py - startY == -1) or (px - startX == -3 and py - startY == 1) or (px - startX == 3 and py - startY == 2) or 
					(math.abs(px - startX) == 2 and math.abs(py - startY) == 2) or (px - startX == 2 and py - startY == -3) or (px - startX == -2 and py - startY == 3) or
					(math.abs(px - startX) == 1 and (py - startY == 0 or math.abs(py - startY) == 1)) or (px - startX == -1 and (py - startY == -3 or py - startY == -4)) or (px - startX == 1 and (py - startY == 3 or py - startY == 4)) or 
					(px - startX == 0 and (math.abs(py - startY) == 1 or math.abs(py - startY) == 3 or math.abs(py - startY) == 4 or py - startY == 0))) then
				a2(_, px, py)
			end
		end,
	nil)
end

-- All-draining version of burnArcaneResources. Drains all normal resources (not feedback) that don't go up with use (like equilibrium and paradox)
function _M:kam_burn_all_resources(target, damage)
	local mana = math.min(target:getMana(), damage)
	local vim = math.min(target:getVim(), damage/2)
	local stamina = math.min(target:getStamina(), damage/2)
	local pos = math.min(target:getPositive(), damage/4)
	local neg = math.min(target:getNegative(), damage/4)
	local psi = math.min(target:getPsi(), damage/4)
	local hate = math.min(target:getHate(), damage/10)
	
	local steam = 0
	if game:isAddonActive("orcs") then
		steam = math.min(target:getSteam(), damage/10)
		target:incSteam(-steam)
	end
	local insanity = 0
	if game:isAddonActive("cults") then
		insanity = math.min(target:getInsanity(), damage/10)
		target:incSteam(-insanity)
	end
	target:incMana(-mana)
	target:incVim(-vim)
	target:incPositive(-pos)
	target:incNegative(-neg)
	target:incPsi(-psi)
	target:incHate(-hate)
	target:incStamina(-stamina)

	return math.max(mana, vim * 2, pos * 4, neg * 4, psi * 4, hate * 10, stamina * 2, insanity * 10, steam * 10)
end

-- Does a Spellwoven attack spell have a given element.
function _M:talentContainsElement(self, t, element)
	element = element.kamUnderlyingElement or element
	if t.isKamDoubleShape then 
		if t.isKamDuo1 then 
			local element1 = t.getElement11(self, t)
			local element2 = t.getElement12(self, t)
			element1 = (DamageType:get(element1)).kamUnderlyingElement or element1
			element2 = (DamageType:get(element2)).kamUnderlyingElement or element2
			if (element1 == element) or (element2 == element) then 
				return true
			end
		else
			local element1 = t.getElement1(self, t)
			element1 = (DamageType:get(element1)).kamUnderlyingElement or element1
			if (element1 == element) then 
				return true
			end
		end
		if t.isKamDuo2 then
			local element1 = t.getElement21(self, t)
			local element2 = t.getElement22(self, t)
			element1 = (DamageType:get(element1)).kamUnderlyingElement or element1
			element2 = (DamageType:get(element2)).kamUnderlyingElement or element2
			if (element1 == element) or (element2 == element) then 
				return true
			end
		else
			local element1 = t.getElement2(self, t)
			element1 = (DamageType:get(element1)).kamUnderlyingElement or element1
			if (element1 == element) then 
				return true
			end
		end
	else 
		if t.isKamDuo then
			local element1 = t.getElement11(self, t)
			local element2 = t.getElement12(self, t)
			element1 = (DamageType:get(element1)).kamUnderlyingElement or element1
			element2 = (DamageType:get(element2)).kamUnderlyingElement or element2
			if (element1 == element) or (element2 == element) then 
				return true
			end
		else
			local element1 = t.getElement(self, t)
			element1 = (DamageType:get(element1)).kamUnderlyingElement or element1
			if (element1 == element) then 
				return true
			end
		end 
	end
	return false
end

-- Counts all elements the player knows, excluding Duo (since it isn't an "element" per say)
function _M:countSpellwovenElements(self)
	local elementCount = 0
	for _, talent in pairs(self.talents_def) do
		if self:knowTalent(talent) then
			local talentTable = self:getTalentFromId(talent)
			if talentTable.isKamElement and not (talentTable.isKamDuo) then
				elementCount = elementCount + 1
			end
		end
	end
	return elementCount
end

-- Used for changeup so I can use the same checking function in both files.
function _M:compareSlots(self, eff, t)
	for _, changeupSpellSlot in pairs(eff.changeupStorage) do
		if (t.kamSpellSlotNumber) == (changeupSpellSlot) then -- If they're the same spell, then they're the same spell, so they definitely share components.
			return false
		end
		for k1, component1 in pairs(self.kamSpellslotBuilder[t.kamSpellSlotNumber]) do
			for k2, component2 in pairs(self.kamSpellslotBuilder[changeupSpellSlot]) do
				if not (k1 == "isKamBarrage" or k1 == "spellType" or k2 == "spellType") then
					if not (component1 == "T_KAM_ELEMENT_DOUBLE" or component2 == "T_KAM_ELEMENT_DOUBLE") and (component1 == component2) then
						return false
					end
				elseif k2 == "isKamBarrage" and component1 == true and component2 == true then -- barrage works weirdly, so this is the barrage special case, since two not-barrage's shouldn't conflict.
					return false
				end
			end
		end
	end
	return true
end

-- TODO: Add any future elements to this 
-- Just a helper function so that I can iterate through talents, even though they aren't actually organized in a way conducive to that.
local function getElementTalentLevel(self, i)
	if i == 1 then
		if self:knowTalent(self.T_KAM_ELEMENTS_OTHERWORLDLY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_OTHERWORLDLY) / self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY).points
		else
			return 0
		end
	elseif i == 2 then
		if self:knowTalent(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY) / self:getTalentFromId(self.T_KAM_ELEMENTS_OTHERWORLDLY_MASTERY).points
		else
			return 0
		end
	elseif i == 3 then
		if self:knowTalent(self.T_KAM_ELEMENTS_MOLTEN) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_MOLTEN) / self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN).points
		else
			return 0
		end
	elseif i == 4 then
		if self:knowTalent(self.T_KAM_ELEMENTS_MOLTEN_MASTERY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_MOLTEN_MASTERY) / self:getTalentFromId(self.T_KAM_ELEMENTS_MOLTEN_MASTERY).points
		else
			return 0
		end
	elseif i == 5 then
		if self:knowTalent(self.T_KAM_ELEMENTS_WIND_AND_RAIN) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_WIND_AND_RAIN) / self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN).points
		else
			return 0
		end
	elseif i == 6 then
		if self:knowTalent(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY) / self:getTalentFromId(self.T_KAM_ELEMENTS_WIND_AND_RAIN_MASTERY).points
		else
			return 0
		end
	elseif i == 7 then
		if self:knowTalent(self.T_KAM_ELEMENTS_RUIN) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_RUIN) / self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN).points
		else
			return 0
		end
	elseif i == 8 then
		if self:knowTalent(self.T_KAM_ELEMENTS_RUIN_MASTERY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_RUIN_MASTERY) / self:getTalentFromId(self.T_KAM_ELEMENTS_RUIN_MASTERY).points
		else
			return 0
		end
	elseif i == 9 then
		if self:knowTalent(self.T_KAM_ELEMENTS_ECLIPSE) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_ECLIPSE) / self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE).points
		else
			return 0
		end
	elseif i == 10 then
		if self:knowTalent(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY) / self:getTalentFromId(self.T_KAM_ELEMENTS_ECLIPSE_MASTERY).points
		else
			return 0
		end
	elseif i == 11 then
		if self:knowTalent(self.T_KAM_ELEMENTS_GRAVECHILL) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_GRAVECHILL) / self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVECHILL).points
		else
			return 0
		end
	elseif i == 12 then
		if self:knowTalent(self.T_KAM_ELEMENTS_GRAVITY) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_GRAVITY) / self:getTalentFromId(self.T_KAM_ELEMENTS_GRAVITY).points
		else
			return 0
		end
	elseif i == 13 then
		if self:knowTalent(self.T_KAM_ELEMENTS_FEVER) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_FEVER) / self:getTalentFromId(self.T_KAM_ELEMENTS_FEVER).points
		else
			return 0
		end
	elseif i == 14 then
		if self:knowTalent(self.T_KAM_ELEMENTS_MANASTORM) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_MANASTORM) / self:getTalentFromId(self.T_KAM_ELEMENTS_MANASTORM).points
		else
			return 0
		end
	elseif i == 15 then
		if self:knowTalent(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE) then
			return self:getTalentLevel(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE) / self:getTalentFromId(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE).points
		else
			return 0
		end
	elseif i == 16 then
		if self:knowTalent(self.T_KAM_NATURAL_SPELLWEAVING_CORE) then
			return self:getTalentLevel(self.T_KAM_NATURAL_SPELLWEAVING_CORE) / self:getTalentFromId(self.T_KAM_NATURAL_SPELLWEAVING_CORE).points
		else
			return 0
		end
	end
end

local function replaceLowest(list, val)
	local lowest = list[1]
	local lowestIndex = 1
	for i = 1, #list do
		if list[i] < lowest then
			lowest = list[i]
			lowestIndex = i
		end
	end
	if val > lowest then
		list[lowestIndex] = val
	end
end

function _M:getAverageHighestElementTalentLevel(self, count)
	local highests = {}
	for i=1, count do
		table.insert(highests, getElementTalentLevel(self, i))
	end
	for i=count+1, 15 do
		replaceLowest(highests, getElementTalentLevel(self, i))
	end
	local total = 0
	for i=1, count do
		total = total + highests[i]
	end
	return total / count
end

-- Used for Runic stuff so I can use this same check between files. Currently always false.
function _M:isAllowInscriptions(self)
	return false
end

-- Used for Advanced Staff Combat so I can use this check anywhere. Allows weapons alongside staves.
function _M:isAllowWeapons(self)
	return false
end

-- Modified version of the one from kam_modes for use in shields across files
function _M:buildShieldArgsTableElement(self, t, allMod)
	local argsTable = {}
	if t.shieldUsesKamElement then
		argsTable.src = self
		argsTable.talent = t
		if not (t.isKamDuo) then
			argsTable.element = t.getElement(self, t)
			argsTable.second = t.getSecond(self, t)
			argsTable.elementInfo = t.getSpellElementInfo
			argsTable.status = t.getSecond(self, t)
			argsTable.dam = t.getElementDamage(self, t) * t.getPowerMod(self, t) * allMod
			argsTable.statusChance = t.getStatusChance(self, t) * t.getPowerMod(self, t) * allMod
		else 
			argsTable.element11 = t.getElement1(self, t)
			argsTable.element12 = t.getElement2(self, t)
			argsTable.second11 = t.getSecond1(self, t)
			argsTable.second12 = t.getSecond2(self, t)
			argsTable.elementInfo11 = t.getSpellElementInfo1
			argsTable.elementInfo12 = t.getSpellElementInfo2
			argsTable.status11 = t.getSecond1(self, t)
			argsTable.status12 = t.getSecond2(self, t)
			argsTable.dam11 = t.getElementDamage1(self, t) * t.getPowerMod(self, t) * allMod
			argsTable.statusChance11 = t.getStatusChance1(self, t) * t.getPowerMod(self, t) * allMod
			argsTable.dam12 = t.getElementDamage2(self, t) * t.getPowerMod(self, t) * allMod
			argsTable.statusChance12 = t.getStatusChance2(self, t) * t.getPowerMod(self, t) * allMod
		end
		return argsTable
	else
		return nil
	end
end

function _M:updateSpellSlotNumbers(self)
	local spellslotCount = 0
	if (self == game.party:findMember{main=true}) then -- Only the main character can ever have Spellslots (since they all actually hold copies of the one talent the player uses).
		if (self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_CORE) or self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_CORE) or self:knowTalent(self.T_KAM_SPELLWEAVER_CORE)) then
			spellslotCount = spellslotCount + 1
		end
		if self:knowTalent(self.T_KAM_SPELLWEAVER_CORE) then
			spellslotCount = spellslotCount + 3
		end
		if self:knowTalent(self.T_KAM_SPELLWEAVER_CORE) and self:getTalentLevelRaw(self.T_KAM_SPELLWEAVER_CORE) >= 3 then
			spellslotCount = spellslotCount + 1
		end
		if self:knowTalent(self.T_KAM_SPELLWEAVER_ADEPT) and self:getTalentLevelRaw(self.T_KAM_SPELLWEAVER_ADEPT) >= 3 then
			spellslotCount = spellslotCount + 1
		end
		if self:knowTalent(self.T_KAM_SPELLWEAVER_MASTER) and self:getTalentLevelRaw(self.T_KAM_SPELLWEAVER_MASTER) >= 3 then
			spellslotCount = spellslotCount + 1
		end
		if spellslotCount >= 1 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_ONE) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_ONE, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_ONE) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_ONE)
		end
		if spellslotCount >= 2 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_TWO) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_TWO, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_TWO) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_TWO)
		end
		if spellslotCount >= 3 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_THREE) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_THREE, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_THREE) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_THREE)
		end
		if spellslotCount >= 4 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_FOUR) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_FOUR, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_FOUR) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_FOUR)
		end
		if spellslotCount >= 5 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_FIVE) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_FIVE, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_FIVE) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_FIVE)
		end
		if spellslotCount >= 6 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_SIX) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_SIX, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_SIX) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_SIX)
		end
		if spellslotCount >= 7 then 
			if not self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_SEVEN) then
				self:learnTalent(ActorTalents.T_KAM_SPELL_SLOT_SEVEN, true)
			end
		elseif self:knowTalent(ActorTalents.T_KAM_SPELL_SLOT_SEVEN) then
			self:unlearnTalent(ActorTalents.T_KAM_SPELL_SLOT_SEVEN)
		end
	end
end

-- Checkerboard.
--543212345
--443212344
--333212333
--222212222
--1111M1111
--222212222
--333212333
--443212344
--543212345

-- Spiral
--...X..........
--...X..........
--...X.XXXXXX...
--...X.X....X...
--...X.X.XX.X...
--...X.X..X.X...
--...X.XXXX.X...
--...X......X...
--...XXXXXXXX...
--..............

-- Wavepulse
--.........
--..33333..
--.3322233.
--.3221223.
--.321M123.
--.3221223.
--.3322233.
--..33333..
--.........

-- Smiley
-- .....
-- .X.X.
-- .....
-- X...X
-- .XXX.