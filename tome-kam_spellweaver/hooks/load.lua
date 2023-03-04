local class = require "engine.class"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"
local DamageType = require "engine.DamageType"
local Target = require "engine.Target"
local KamCalc = require "mod.KamHelperFunctions"
local Store = require "mod.class.Store"
local Chat = require "engine.Chat"
local PartyLore = require "mod.class.interface.PartyLore"

local function makeSpellslots() -- I have changed these talents extensively, now any change I make will apply to all of them.
	KamCalc:setupSpellwovenTalentEntities()
	local slotOne = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	local slotTwo = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	local slotThree = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	local slotFour = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	local slotFive = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	local slotSix = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	local slotSeven = table.clone(ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_ATTACK])
	
	slotOne.name = "Spell Slot One"
	slotOne.short_name = "KAM_SPELL_SLOT_ONE"
	slotOne.kamSpellSlotNumber = 0
	slotOne.image = "talents/kam_spellweaver_spellslot_empty_0.png"
	ActorTalents:newTalent(slotOne)
	
	slotTwo.name = "Spell Slot Two"
	slotTwo.short_name = "KAM_SPELL_SLOT_TWO"
	slotTwo.kamSpellSlotNumber = 1
	slotTwo.image = "talents/kam_spellweaver_spellslot_empty_1.png"
	ActorTalents:newTalent(slotTwo)
	
	slotThree.name = "Spell Slot Three"
	slotThree.short_name = "KAM_SPELL_SLOT_THREE"
	slotThree.kamSpellSlotNumber = 2
	slotThree.image = "talents/kam_spellweaver_spellslot_empty_2.png"
	ActorTalents:newTalent(slotThree)
	
	slotFour.name = "Spell Slot Four"
	slotFour.short_name = "KAM_SPELL_SLOT_FOUR"
	slotFour.kamSpellSlotNumber = 3
	slotFour.image = "talents/kam_spellweaver_spellslot_empty_3.png"
	ActorTalents:newTalent(slotFour)
	
	slotFive.name = "Spell Slot Five"
	slotFive.short_name = "KAM_SPELL_SLOT_FIVE"
	slotFive.kamSpellSlotNumber = 4
	slotFive.image = "talents/kam_spellweaver_spellslot_empty_4.png"
	ActorTalents:newTalent(slotFive)
	
	slotSix.name = "Spell Slot Six"
	slotSix.short_name = "KAM_SPELL_SLOT_SIX"
	slotSix.kamSpellSlotNumber = 5
	slotSix.image = "talents/kam_spellweaver_spellslot_empty_5.png"
	ActorTalents:newTalent(slotSix)
	
	slotSeven.name = "Spell Slot Seven"
	slotSeven.short_name = "KAM_SPELL_SLOT_SEVEN"
	slotSeven.kamSpellSlotNumber = 6
	slotSeven.image = "talents/kam_spellweaver_spellslot_empty_6.png"
	ActorTalents:newTalent(slotSeven)

	local baseShield = ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_SHIELD]
	
	local sustainShield = ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_SHIELD_SUSTAIN] -- Make sure any changes to getPowerModSpecial are transfered.
	sustainShield.getPowerModSpecial = baseShield.getPowerModSpecial
	local contingencyShield = ActorTalents.talents_def[ActorTalents.T_KAM_SPELL_SLOT_SHIELD_CONTINGENCY] -- Same.
	contingencyShield.getPowerModSpecial = baseShield.getPowerModSpecial
end

local function makeShield() -- This is as much because I wanted to see if I could as to make sure changes are held across different multi and basic.
	local multiShield = table.clone(ActorTemporaryEffects.tempeffect_def[ActorTemporaryEffects.EFF_KAM_SPELLWEAVER_SHIELD_BASIC])
	multiShield.name = "KAM_SPELLWEAVER_SHIELD_MULTI"
	multiShield.desc = "Spellwoven Shieldwave"
	multiShield.long_desc = function(self, eff)
		return ([[You and nearby allies are surrounded by a Spellwoven shield that can absorb %d/%d damage. %s]]):format(eff.absorbLeft, eff.absorbPower, eff.bonusDescriptor)
	end
	
	local contingencyShield = table.clone(ActorTemporaryEffects.tempeffect_def[ActorTemporaryEffects.EFF_KAM_SPELLWEAVER_SHIELD_BASIC])
	contingencyShield.name = "KAM_SPELLWEAVER_SHIELD_CONTINGENT"
	contingencyShield.desc = "Spellwoven Contingency Shield"
	contingencyShield.long_desc = function(self, eff)
		return ([[Your contingency shield has triggered, surrounding you with a Spellwoven shield that can absorb %d/%d damage. %s]]):format(eff.absorbLeft, eff.absorbPower, eff.bonusDescriptor)
	end
	
	local perfectBlock = table.clone(ActorTemporaryEffects.tempeffect_def[ActorTemporaryEffects.EFF_KAM_SPELLWEAVER_SHIELD_BASIC])
	perfectBlock.name = "KAM_SPELLWEAVER_SHIELD_ONETURN"
	perfectBlock.desc = "Spellwoven Perfect Guard"
	perfectBlock.long_desc = function(self, eff)
		return ([[You have a perfect magical barrier, surrounding you with a Spellwoven shield that can absorb %d/%d damage. %s]]):format(eff.absorbLeft, eff.absorbPower, eff.bonusDescriptor)
	end
	
	ActorTemporaryEffects:newEffect(multiShield)
	ActorTemporaryEffects:newEffect(contingencyShield)
	ActorTemporaryEffects:newEffect(perfectBlock)
end

local function rebuildSpellslots(player)
	if player.kamSpellslotBuilder then
		for i=0, table.getn(player.kamSpellslotBuilder) do 
			if not (player.kamSpellslotBuilder[i] == -1) then
				if (player.kamSpellslotBuilder[i].spellType == 1) then -- spellType 1 = attack 
					KamCalc.kam_build_spell_from_ids(player, player.kamSpellslotBuilder[i])
				elseif (player.kamSpellslotBuilder[i].spellType == 2) then -- spellType 2 = shield
					KamCalc.kam_build_shield_spell_from_ids(player, player.kamSpellslotBuilder[i])
				elseif (player.kamSpellslotBuilder[i].spellType == 3) then -- spellType 3 = teleport
					KamCalc.kam_build_teleport_spell_from_ids(player, player.kamSpellslotBuilder[i])
				end
			end
		end
	end
end

local function addTypesDef(self) -- Modifies _M.types_def in Target.lua in the engine.
	local mergeTable = {cross = function(dest, src) dest.cross = src.size end, 
		spiral = function(dest, src) dest.spiral = src.size end,
		checkerboard = function(dest, src) 
			dest.checkerboard = src.size 
			dest.offset = src.offset
		end,
		wavepulse = function(dest, src) 
			dest.wavepulse = src.size 
			dest.offset = src.offset
		end,
		kamDoubleCircle = function(dest, src)
			dest.kamDoubleCircle = src.size
			dest.sizeTwo = src.sizeTwo
		end,
		kam_smiley = function(dest, src)
			dest.isKamSmiley = src.isKamSmiley -- Just so that I can normally determine the type. Not used for anything since it's static. 
		end,
		kam_flower = function(dest, src)
			dest.isKamFlower = src.isKamFlower -- Same reasoning.
		end,
		kam_eightpoint = function(dest, src)
			dest.kam_eightpoint = src.size
		end,
		kam_doublespiral = function(dest, src)
			dest.kam_doublespiral = src.size
		end
		}
	table.mergeAdd(Target.types_def, mergeTable)
end

local function modifyCooldownMerge(self) -- Adjust infusion cooldown effect on_merge to 
	local infusionCooldown = ActorTemporaryEffects.tempeffect_def[ActorTemporaryEffects.EFF_INFUSION_COOLDOWN]
	local runeCooldown = ActorTemporaryEffects.tempeffect_def[ActorTemporaryEffects.EFF_RUNE_COOLDOWN]
	local taintCooldown = ActorTemporaryEffects.tempeffect_def[ActorTemporaryEffects.EFF_TAINT_COOLDOWN]
	infusionCooldown.kam_old_on_merge = infusionCooldown.on_merge
	runeCooldown.kam_old_on_merge = runeCooldown.on_merge
	taintCooldown.kam_old_on_merge = taintCooldown.on_merge
	infusionCooldown.on_merge = function(self, old_eff, new_eff)
		local retval = infusionCooldown.kam_old_on_merge(self, old_eff, new_eff)
		local KamCalc = require "mod.KamHelperFunctions"
		if (self:knowTalent(self.T_KAM_RUNIC_MASTERY) and KamCalc:isAllowInscriptions(self)) then
			if not retval.kamInscriptionCooldownEff then
				retval.power = retval.power - 1
				retval.kamInscriptionCooldownEff = true
			else 
				retval.kamInscriptionCooldownEff = false
			end
		end
		return retval
	end
	runeCooldown.on_merge = function(self, old_eff, new_eff)
		local retval = runeCooldown.kam_old_on_merge(self, old_eff, new_eff)
		if (self:knowTalent(self.T_KAM_RUNIC_MASTERY)) then
			if not retval.kamInscriptionCooldownEff then
				retval.power = retval.power - 1
				retval.kamInscriptionCooldownEff = true
			else 
				retval.kamInscriptionCooldownEff = false
			end
		end
		return retval
	end
	taintCooldown.on_merge = function(self, old_eff, new_eff)
		local retval = taintCooldown.kam_old_on_merge(self, old_eff, new_eff)
		if (self:knowTalent(self.T_KAM_RUNIC_MASTERY)) then
			if not retval.kamInscriptionCooldownEff then
				retval.power = retval.power - 1
				retval.kamInscriptionCooldownEff = true
			else 
				retval.kamInscriptionCooldownEff = false
			end
		end
		return retval
	end
	infusionCooldown.kam_old_long_desc = infusionCooldown.long_desc
	runeCooldown.kam_old_long_desc = runeCooldown.long_desc
	taintCooldown.kam_old_long_desc = taintCooldown.long_desc
	infusionCooldown.long_desc = function(self, eff)
		local addText = ""
		local KamCalc = require "mod.KamHelperFunctions"
		if (self:knowTalent(self.T_KAM_RUNIC_MASTERY)) and not (eff.kamInscriptionCooldownEff) and KamCalc:isAllowInscriptions(self) then
			addText = [[ The next infusion you use will not increase this effect (although the duration will still be reset).]]
		end
		return ([[%s%s]]):tformat(infusionCooldown.kam_old_long_desc(self, eff), addText)
	end
	runeCooldown.long_desc = function(self, eff)
		local addText = ""
		if (self:knowTalent(self.T_KAM_RUNIC_MASTERY)) and not (eff.kamInscriptionCooldownEff) then
			addText = [[ The next rune you use will not increase this effect (although the duration will still be reset).]]
		end
		return ([[%s%s]]):tformat(runeCooldown.kam_old_long_desc(self, eff), addText)
	end
	taintCooldown.long_desc = function(self, eff) -- I wonder how many people will ever actually benefit from this effect for taints.
		local addText = ""
		if (self:knowTalent(self.T_KAM_RUNIC_MASTERY)) and not (eff.kamInscriptionCooldownEff) then
			addText = [[ The next taint you use will not increase this effect (although the duration will still be reset).]]
		end
		return ([[%s%s]]):tformat(taintCooldown.kam_old_long_desc(self, eff), addText)
	end
end

class:bindHook("ToME:load", function(self, data)
	addTypesDef(self)
	dofile("/data-kam_spellweaver/kam_spellweavers_faction.lua")
	
	-- Attack spells
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_elements.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_modes.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_shapes.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spell_crafting.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spellslots.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_eclipse.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_molten.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_wind_and_rain.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_otherworldly.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_ruin.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spellweaving.lua")
	-- Shield Spells
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_shieldweaving.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_shield_modes.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_shield_bonuses.lua")
	-- Warp Spells
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_warpweaving.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_teleport_modes.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_teleport_bonuses.lua")
	-- The Weird Stuff (Locked Trees)
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_runic_mastery.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_metaweaving.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spellweaving_mastery.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_elementalist.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_advanced_staff_combat.lua")
	-- Class evos
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spellweaver_class_evos.lua")
	-- Effects
	ActorTemporaryEffects:loadDefinition("/data-kam_spellweaver/timed_effects/spellweaver_effects.lua")
	ActorTemporaryEffects:loadDefinition("/data-kam_spellweaver/timed_effects/spellweaver_shield_effects.lua")
	DamageType:loadDefinition("/data-kam_spellweaver/kam_spellweaver_damage_types.lua")
	Birther:loadDefinition("/data-kam_spellweaver/birth/classes/spellweaver.lua")
	-- Enemy talents
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_woven_animal_spells.lua")
	-- Stuff for Woven Home
	-- Stores
	Store:loadStores("/data-kam_spellweaver/general/stores/spellweaver_stores.lua")
	-- Lores
	PartyLore:loadDefinition("/data-kam_spellweaver/lore/kam-spellweavers.lua")
	PartyLore:loadDefinition("/data-kam_spellweaver/lore/kam-spellweavers_beacon.lua")
	PartyLore:loadDefinition("/data-kam_spellweaver/lore/kam-spellweavers_elemental_ruins.lua")
	-- Fake talents for professors
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_natural_spellweaving.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_fake_talents.lua")
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spellwoven_enhancements.lua")
	-- Artifact Talents
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/kam_spellweaver_artifact_talents.lua")
	-- Wovenhome Orc talents. Loaded even if no EoR since the talents are used for the fixedart from Grath's quest.
	ActorTalents:loadDefinition("/data-kam_spellweaver/talents/racials/kam_wovenhome_orcs.lua")
	-- Wovenhome Orcs (only if you have EoR). Disabled because I needed to do an unexpected bugfix update.
--	if ActorTalents.talents_types_def["steamtech/chemistry"] then -- game:isAddonActive does not work here, even if you require engine.Game
--		Birther:loadDefinition("/data-kam_spellweaver/birth/races/kam_wovenhome_orc.lua")
--	end
	
	makeSpellslots()
	makeShield()
	modifyCooldownMerge()
end)

class:bindHook("Entity:loadList", function(self, data) 
	if data.file == "/data/zones/wilderness/grids.lua" then
		self:loadList("/data-kam_spellweaver/kam_wilderness_spellweaver.lua", data.no_default, data.res, data.mod, data.loaded)
	elseif data.file == "/data/general/objects/world-artifacts.lua" then
		self:loadList("/data-kam_spellweaver/general/objects/spellweaver-artifacts.lua", data.no_default, data.res, data.mod, data.loaded)
	elseif data.file == "/data/general/objects/world-artifacts-far-east.lua" then
		self:loadList("/data-kam_spellweaver/general/objects/spellweaver-artifacts-east.lua", data.no_default, data.res, data.mod, data.loaded)
	end
end)

-- This method of loading into the wilderness map is based on House Pet's More Tales. Thank you to House Pet.
class:bindHook("MapGeneratorStatic:subgenRegister", function(self, data)
	if data.mapfile ~= "wilderness/eyal" then return end
	if game.player.descriptor.world ~= "Maj'Eyal" then return end
	
	data.list[#data.list+1] = {
		x = 163, y = 24, w = 1, h = 1, overlay = true,
		generator = "engine.generator.map.Static",
		data = {
			map = "kam_spellweaver+kam-spellweaver-woven-home-overlay",
		},
	}
end)

-- Rebuilds all the spell slots at the beginning of each game, since the way they are changed is not stored.
class:bindHook("ToME:runDone", function(self, data)
	if (game.player) then 
		rebuildSpellslots(game.player)
	end
end)

-- The changes to realDisplay to allow new exciting shapes.
class:bindHook("Target:realDisplay", function(self, data)
	if self.target_type.cross and self.target_type.cross > 0 then 
		KamCalc:kam_calc_cross(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.size,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
		nil)
	end
	if self.target_type.spiral and self.target_type.spiral > 0 then 
		KamCalc:kam_calc_spiral(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.size,
			self.target_type.start_x,
			self.target_type.start_y,
			self.target.x - self.target_type.start_x,
			self.target.y - self.target_type.start_y,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
		nil)
	end
	if self.target_type.checkerboard and self.target_type.checkerboard > 0 then 
		KamCalc:kam_calc_checkerboard(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.size,
			0,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.sr, px, py)
					data.display_highlight(self.kamPurple, px, py)
				else
					data.display_highlight(self.kamPurple, px, py)
				end
			end,
		nil)
	end
	if self.target_type.wavepulse and self.target_type.wavepulse > 0 then 
		KamCalc:kam_calc_wavepulse(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.size,
			0,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.sr, px, py)
					data.display_highlight(self.kamPurple, px, py)
				else
					data.display_highlight(self.kamPurple, px, py)
				end
			end,
		nil)
	end
	if self.target_type.kamDoubleCircle and self.target_type.kamDoubleCircle > 0 then 
		core.fov.calc_circle( -- Double circle to make sure that part of the doubles can be yellow. Only used here for targetting, do that actual work yourself.
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.size,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
		nil)
		core.fov.calc_circle(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			self.target_type.sizeTwo,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.sr, px, py)
					data.display_highlight(self.kamPurple, px, py)
				else
					data.display_highlight(self.kamPurple, px, py)
				end
			end,
		nil)
	end
	if self.target_type.isKamSmiley and self.target_type.isKamSmiley > 0 then 
		KamCalc:kam_make_smiley(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
		nil)
	end
	if self.target_type.isKamFlower and self.target_type.isKamFlower > 0 then 
		KamCalc:kam_make_flower(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			0,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.sr, px, py)
					data.display_highlight(self.kamPurple, px, py)
				else
					data.display_highlight(self.kamPurple, px, py)
				end
			end,
		nil)
	end
	if self.target_type.kam_eightpoint and self.target_type.kam_eightpoint > 0 then 
		KamCalc:kam_calc_eightpoint(
			game.level.map.w,
			game.level.map.h,
			self.target_type.size,
			self.target_type.start_x,
			self.target_type.start_y,
			self.target.x - self.target_type.start_x,
			self.target.y - self.target_type.start_y,
			0,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.sr, px, py)
					data.display_highlight(self.kamPurple, px, py)
				else
					data.display_highlight(self.kamPurple, px, py)
				end
			end,
		nil)
	end
	if self.target_type.kam_doublespiral and self.target_type.kam_doublespiral > 0 then 
		KamCalc:kam_calc_doublespiral(
			data.stop_radius_x,
			data.stop_radius_y,
			game.level.map.w,
			game.level.map.h,
			0,
			self.target_type.size,
			self.target_type.start_x,
			self.target_type.start_y,
			self.target.x - self.target_type.start_x,
			self.target.y - self.target_type.start_y,
			function(_, px, py)
				if self.target_type.block_radius and self.target_type:block_radius(px, py, true) then return true end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.syg, px, py)
				else
					data.display_highlight(self.sg, px, py)
				end
			end,
			function(_, px, py)
				if not self.target_type.no_restrict and not game.level.map.remembers(px, py) and not game.level.map.seens(px, py) then
					data.display_highlight(self.sr, px, py)
					data.display_highlight(self.kamPurple, px, py)
				else
					data.display_highlight(self.kamPurple, px, py)
				end
			end,
		nil)
	end
end)

-- Used for Elementalist's Gloves since we want to alter elemental damage increases AFTER they are already applied
class:bindHook("DamageProjector:beforeResists", function(self, data)
	if self and self.hasEffect then 
		local eff = self:hasEffect(self.EFF_KAM_ELEMENTALIST_GLOVES_EFFECT)
		if eff then
			local ed = self:getEffectFromId(self.EFF_KAM_ELEMENTALIST_GLOVES_EFFECT)
			ed.kamSpellweaverElementalGlovesShiftElements(self, eff, data.type, data.dam)
		end
	end
end)

class:bindHook("DamageProjector:base", function(self, data) -- Special flat damage modifiers because I like them.	
	if data.target and data.src then
		if data.src.attr and data.src:attr("kam_spellweaver_hundredeyes_glasses_bonus") then
			if data.target.hasEffect and data.target:hasEffect(data.target.EFF_ARCANE_EYE_SEEN) then
				if data.src.hasEffect and data.src:hasEffect(data.src.EFF_ARCANE_EYE) then
					data.dam = data.dam * (data.src:attr("kam_spellweaver_hundredeyes_glasses_bonus") + 1)
				end
			end
		end
		
		if data.src.hasEffect then
			local peaceRage = data.src:hasEffect(data.src.EFF_KAM_WOVENHOME_ORC_PEACE_FURY_USER)
			if peaceRage then
				if peaceRage.target == data.target then
					data.dam = data.dam * ((peaceRage.power / 100) + 1)
				else
					data.dam = 0
				end
			end
		end
		
		if data.src.attr and data.src:attr("kam_darklight_illuminate_damage") then 
			if data.target.hasEffect and (data.target:hasEffect(data.target.EFF_LUMINESCENCE) or data.target:hasEffect(data.target.EFF_BLINDED) or data.target:hasEffect(data.target.EFF_KAM_ECLIPSING_CORONA)) then
				data.dam = data.dam * ((data.src:attr("kam_darklight_illuminate_damage") / 100) + 1)
				if data.type ~= DamageType.DARKNESS and data.type ~= DamageType.LIGHT then 
					data.dam = data.dam * 1.1
				end
			end
		end
		
		if data.src.attr and data.src:attr("kam_apestilence_diseaseDamage") and data.target.attr and data.target:attr("kam_disease_count") then 
			local unblightBonus = 1
			if data.type ~= DamageType.BLIGHT and data.type ~= DamageType.ACID then
				unblightBonus = 1.3
			end
			data.dam = data.dam * (unblightBonus * (data.src:attr("kam_apestilence_diseaseDamage") / 100 * (math.min(3, data.target:attr("kam_disease_count")))) + 1)
		end	
		
		local wovenhomeOrcReduce = (data.src.attr and data.src:attr("wovenhome_orc_damage_reduce")) or (data.src.summoner and data.src.summoner.attr and data.src.summoner:attr("wovenhome_orc_damage_reduce"))
		if wovenhomeOrcReduce and data.src:reactionToward(data.target) > 0 then
			data.dam = data.dam * (1 - wovenhomeOrcReduce)
		end
	end

	if data.target then
		if data.target.attr and data.target:attr("kam_tricked_increasedDamage") then
			data.dam = data.dam * (100 + data.target:attr("kam_tricked_increasedDamage")) / 100
		end
		
		if data.target.hasEffect then
			local newPride = data.target:hasEffect(data.target.EFF_KAM_WOVENHOME_ORC_NEW_PRIDE)
			if newPride then
				data.dam = data.dam * (newPride.power / 100)
			end
		end
	end

	if data.src then
		if data.src.attr and data.src:attr("kam_tricked_reduceDamage") then
			data.dam = data.dam * (100 - data.src:attr("kam_tricked_reduceDamage")) / 100
		end

		if data.src.hasEffect and data.src:hasEffect(data.src.EFF_KAM_ELEMENTAL_NULLIFICATION) then
			data.dam = data.dam * 0.7
		end
	end
	
	return data
end)

-- These two are for the various null damage effects.
class:bindHook("Actor:takeHit", function(self, data)
	if self.hasEffect and (self:hasEffect(self.EFF_KAM_RUNIC_MODIFICATION_TELEPORT) or self:hasEffect(self.EFF_KAM_SPELLWEAVER_METAPARADISE) or self:hasEffect(self.EFF_ZONE_AURA_KAM_WOVEN_HOME)) then 
		data.value = 0 
		return true 
	end
end)
class:bindHook("DamageProjector:base", function(self, data)
	if self.hasEffect and (self:hasEffect(self.EFF_KAM_RUNIC_MODIFICATION_TELEPORT) or self:hasEffect(self.EFF_KAM_SPELLWEAVER_METAPARADISE) or self:hasEffect(self.EFF_ZONE_AURA_KAM_WOVEN_HOME)) then 
		data.dam = 0 
		return true 
	end
end)

class:bindHook("Actor:onWear", function(self, data) -- Interesting (and annoying) fact: callbackOnWear applies AFTER stats are added and thus changing stats with it is Very Bad
	local obj = data.o
	if self:knowTalent(self.T_KAM_SPELLWEAVER_ADEPT) then
		if (obj.subtype == "staff") and obj.command_staff and obj.command_staff.inc_damage and not (obj.combat and obj.combat.is_greater) then
			if obj.__kam_staff_all_data then
				obj:tableTemporaryValuesRemove(obj.__kam_staff_all_data)
				obj.__kam_staff_all_data = nil
			end
			obj.__kam_staff_all_data = {}
			local staffPower = obj.combat.staff_power or obj.combat.dam
			local element = obj.combat.element
			if staffPower and element then -- Staff must have both a staff power and a proper element, otherwise things like Bolbum's Big Knocker will fail.
				obj:tableTemporaryValue(obj.__kam_staff_all_data, {"wielder","inc_damage"}, {[element] = -1 * staffPower})
				obj:tableTemporaryValue(obj.__kam_staff_all_data, {"wielder","inc_damage"}, {["all"] = staffPower})
			end
		end
	elseif obj.__kam_staff_all_data then
		obj:tableTemporaryValuesRemove(obj.__kam_staff_all_data)
		obj.__kam_staff_all_data = nil
	end
	if (self:knowTalent(self.T_KAM_ASC_EMPOWERMENT)) then
		if obj.__kam_staff_empowerment_data then
			obj:tableTemporaryValuesRemove(obj.__kam_staff_empowerment_data)
			obj.__kam_staff_empowerment_data = nil
		end
		local tal = self:getTalentFromId(self.T_KAM_ASC_EMPOWERMENT)
		obj.__kam_staff_empowerment_data = {}
		if (obj.subtype == "staff") and obj.combat and obj.combat.dammod and obj.combat.dammod["mag"] then
			obj:tableTemporaryValue(obj.__kam_staff_empowerment_data, {"combat", "dammod"}, {["mag"] = obj.combat.dammod["mag"] * (tal.getStatmult(self, tal)-1) })
		end
	elseif obj.__kam_staff_empowerment_data then
		obj:tableTemporaryValuesRemove(obj.__kam_staff_empowerment_data)
		obj.__kam_staff_empowerment_data = nil
	end
	if self:knowTalent(self.T_KAM_WOVENHOME_ORC_SURVIVALIST) and obj.wielder then 
		if obj.__kam_wovenhome_survivalist_adds then
			obj:tableTemporaryValuesRemove(obj.__kam_wovenhome_survivalist_adds)
			obj.__kam_wovenhome_survivalist_adds = nil
		end
		
		local factor = self:callTalent(self.T_KAM_WOVENHOME_ORC_SURVIVALIST, "gearBoost") / 100 -- Wait, this function exists??? That probably would have made everything easier...

		obj.__kam_wovenhome_survivalist_adds = {}
		if obj.wielder.combat_spellresist then obj:tableTemporaryValue(obj.__kam_wovenhome_survivalist_adds, {"wielder", "combat_spellresist"}, math.ceil(obj.wielder.combat_spellresist * factor)) end
		if obj.wielder.combat_physresist then obj:tableTemporaryValue(obj.__kam_wovenhome_survivalist_adds, {"wielder", "combat_physresist"}, math.ceil(obj.wielder.combat_physresist * factor)) end
		if obj.wielder.combat_mentalresist then obj:tableTemporaryValue(obj.__kam_wovenhome_survivalist_adds, {"wielder", "combat_mentalresist"}, math.ceil(obj.wielder.combat_mentalresist * factor)) end
		if obj.wielder.combat_armor then obj:tableTemporaryValue(obj.__kam_wovenhome_survivalist_adds, {"wielder", "combat_armor"}, math.ceil(obj.wielder.combat_armor * factor)) end
		if obj.wielder.combat_def then obj:tableTemporaryValue(obj.__kam_wovenhome_survivalist_adds, {"wielder", "combat_def"}, math.ceil(obj.wielder.combat_def * factor)) end
		if obj.wielder.inc_stats then 
			local adds = {}
			for k, v in pairs(obj.wielder.inc_stats) do adds[k] = math.ceil(v * factor) end
			obj:tableTemporaryValue(obj.__kam_wovenhome_survivalist_adds, {"wielder", "inc_stats"}, adds)
		end
	elseif obj.__kam_wovenhome_survivalist_adds then
		obj:tableTemporaryValuesRemove(obj.__kam_wovenhome_survivalist_adds)
		obj.__kam_wovenhome_survivalist_adds = nil
	end
end)

class:bindHook("Combat:attackTarget", function(self, data)
	local target = data.target
	if target then
		local frontline = target:getTalentFromId(target.T_KAM_ASC_MASTERY)
		if frontline then
			if not (game.state.kam_is_doing_frontline_counterattack) then
				if (math.abs(self.x - target.x) < 2 and math.abs(self.y - target.y) < 2) then
					if (not target.turn_procs.kam_frontline_counterattack) and (rng.percent(frontline.getAttackChance(target, frontline))) then
						data.mult = data.mult or 1
						data.mult = data.mult * (1 - (frontline.getDamageReduce(target, frontline) / 100))
						game.state.kam_is_doing_frontline_counterattack = true -- Should never trigger off of itself.
						local old = target.energy.value
						local oldModifyASC = target.kam_modify_asc_chance
						target.kam_modify_asc_chance = 1/3
						target:attackTarget(self, nil, 1, true, false)
						game.state.kam_is_doing_frontline_counterattack = false
						target.energy.value = old
						target.kam_modify_asc_chance = oldModifyASC
						target.turn_procs.kam_frontline_counterattack = true
	--					game.logPlayer(target, "%s counterattacks!") -- I guess Intuitive Shots doesn't, so maybe I shouldn't
						return {mult = data.mult, damtype = data.damtype, }
					end
				end
			end
		end
	end
end)

class:bindHook("Chat:load", function(self, data) -- Chat modifications, since they know about Spellweavers in the East.
	local q = game.player:hasQuest("start-spellweaver")
	if q then 
		if self.name == "unremarkable-cave-fillarel" then
			local newAns = {_t"Happy to help. We're near the Gates of Morning, right?", jump = "kam_spellweaver"}
			self.chats.welcome.answers = { newAns }
			
			self:addChat({
				id = "kam_spellweaver",
				action = function(npc, player) end,
				text = [[Wait... @playername@! You were the missing Spellweaver that Hundredeyes reported to us. They thought you might have teleported somewhere unexpected, although after this long we had mostly given up hope.
You should return to Hundredeyes with the good news.]],
				answers = {
					{_t"Additionally, some orcs tried to steal a powerful artifact in the distant land of Maj'Eyal, and I fear that they plan worse.", jump = "kam_badnews"},
				}
			})
			
			self:addChat({
				id = "kam_badnews",
				action = function(npc, player) end,
				text = [[Oh no. I'm too worn down from that fight to travel yet. Could you take the news to Aeryn? I know you Spellweavers normally avoid the good fight against the orcs, but surely if you're that worried you can see that this must be done.]],
				answers = {
					{_t"Don't worry, I will get the news to Aeryn.", action=function(npc, player) game.player:setQuestStatus("strange-new-world", engine.Quest.COMPLETED, "helped-fillarel") end},
				}
			})
		end
		if self.name == "gates-of-morning-welcome" then
			local welcome = self.chats["welcome"]
			welcome.text = _t[[#LIGHT_GREEN#*Aeryn stands before the Gates of Morning, protecting it from interlopers. Must be her turn to handle guard duty.*#WHITE#
Stop! You are clearly a strange - wait... Aren't you @playername@, the missing Spellweaver that disappeared recently? We thought you were dead.
You should report to Hundredeyes that you're alive. Although since it took me a minute to recognize you, just as a reminder, you can get to Wovenhome by heading around the mountains and down the coast to the North and then East of here.]]
			welcome.answers = {
				{_t"I will, but Fillarel asked me to report something first.", jump = "kam_report"},
			}

			self:addChat({
				id = "kam_report",
				action = function(npc, player) end,
				text = [[Fillarel is alive? Good. Hopefully she will recover soon and join us here. As an Anorithil, healing in a relatively secluded cave shouldn't take that long...
Anyways, what do you need to report?]],
				answers = {
					{_t"Orcs attempted to steal a powerful artifact in the distant land of Maj'Eyal, to the west. I fear they plan to use it for something awful.", jump = "kam_go_check_back_in_eyal"},
				}
			})
			
			local orcsAnswer = self.chats.orcs.answers[1]
			orcsAnswer[1] = _t"Thank you, I'll do so soon."
			
			self:addChat({
				id = "kam_go_check_back_in_eyal",
				action = function(npc, player) end,
				text = [[Hmm. If needed, I can tell you where the Orcish Prides are if you want to investigate further. We don't have the resources to make a full on attack, so we will not be able to assist you if you actually find out that something is that badly wrong.
Additionally, if you want to get back to this Maj'Eyal to look for more information, you may wish to talk to Zemekkys. He has some knowledge of portals and similar and may be able to make a way back.]],
				answers = {
					orcsAnswer,
				}
			})
		end
		if self.name == "gates-of-morning-main" then
			self.chats.relentless.answers[1][1] = _t"I will retrieve the staff and stop whatever trouble is happening."
		end
	end
end)