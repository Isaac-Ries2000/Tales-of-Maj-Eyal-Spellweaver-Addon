local Map = require "engine.Map"
local Chat = require "engine.Chat"
local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/crafting", no_silence = true, is_spell = true, name = _t("crafting spells", "talent type"), descriptions = _t"Weave spells from components." }

-- Spellweave command talents. 
-- They're all free to use and have no mana costs or anything or cooldowns, but you can't use them in combat so it doesn't matter. 

newTalent{
	name = "Attack Spell Crafting",
	short_name = "KAM_SPELL_CRAFTING",
	image = "talents/kam_spellweaver_attack_spell_crafting.png",
	type = {"spellweaving/crafting", 1},
	points = 1,
	no_npc_use = true,
	isKamSpellCraftingMethod = true,
	info = function(self, t)
		local combatText = "\nYou cannot craft spells in combat unless you have none."
		if (self.kam_is_combat_crafting) then
			local combatText = ""
		end
		return ([[Craft an attack spell from spellweaving components into one of your spellweaving slots. Your perfect control means that no spell created this way will ever hurt friendly targets.%s
		Attack spells cost 15 mana and have a cooldown of 5.]]):
		tformat(combatText)
	end,
	on_pre_use = function(self, t, silent) 
		if self.kam_spell_crafted and self.in_combat and not self.kam_is_combat_crafting then 
			if not silent then 
				game.logPlayer(self, "You cannot craft spells in combat!") 
			end 
			return false 
		end 
		return true 
	end,
	action = function(self, t)
		local slot_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellSlots").new(self))
		if not slot_tid then return false end 
		local shape_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellShapes").new(self))
		if not shape_tid then return false end 
		
		local checkShape = self.talents_def[shape_tid]
		local isBarrage = false
		if checkShape.isKamBarrage then 
			isBarrage = true
			checkShape.isKamShape = false
			shape_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellShapes").new(self))
			checkShape.isKamShape = true
			if not shape_tid then return false end 
			checkShape = self.talents_def[shape_tid]
		end
		local spellTable = {}
		-- Here we go...
		if checkShape.isKamDoubleShape then
			local bannedMode = nil -- I'm aware this isn't a great solution but I don't care to figure it out right now.
			if self:knowTalent(self.T_KAM_MODE_DIGGING) then 
				bannedMode = self:getTalentFromId(self.T_KAM_MODE_DIGGING)
			end
			-- Spellset 1, the "on" tiles
			local element_tid1 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
			if not element_tid1 then return false end 
			local checkElement1 = self.talents_def[element_tid1]
			local element_tid11 = nil
			local element_tid12 = nil
			if (checkElement1.isKamDuo) then 
				checkElement1.isKamElement = false
				element_tid11 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				if not element_tid11 then 
					checkElement1.isKamElement = true
					return false 
				end
				local markElement = self.talents_def[element_tid11]
				markElement.isKamElement = false
				element_tid12 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				markElement.isKamElement = true
				checkElement1.isKamElement = true
				if not element_tid12 then 
					return false 
				end
			end
			if bannedMode then 
				bannedMode.isKamMode = false
			end
			local mode_tid1 = self:talentDialog(require("mod.dialogs.talents.KamSpellModes").new(self))
			if bannedMode then 
				bannedMode.isKamMode = true
			end
			if not mode_tid1 then return false end 
			local checkMode1 = self.talents_def[mode_tid1]
			if checkMode1.isKamNoDoubleMode then 
				checkMode1.isKamMode = false
			end
			
			-- Spell set 2, the "off" tiles
			local element_tid2 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
			if not element_tid2 then 
				checkMode1.isKamMode = true
				return false 
			end 
			local checkElement2 = self.talents_def[element_tid2]
			local element_tid21 = nil
			local element_tid22 = nil
			if (checkElement2.isKamDuo) then 
				checkElement2.isKamElement = false
				element_tid21 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				if not element_tid21 then 
					checkElement2.isKamElement = true
					checkMode1.isKamMode = true
					return false 
				end
				local markElement = self.talents_def[element_tid21]
				markElement.isKamElement = false
				element_tid22 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				markElement.isKamElement = true
				checkElement2.isKamElement = true
				if not element_tid22 then 
					checkMode1.isKamMode = true
					return false 
				end
			end
			if bannedMode then 
				bannedMode.isKamMode = false
			end
			local mode_tid2 = self:talentDialog(require("mod.dialogs.talents.KamSpellModes").new(self))
			if bannedMode then 
				bannedMode.isKamMode = true
			end
			checkMode1.isKamMode = true
			if not mode_tid2 then return false end 
			
			if not (checkElement1.isKamDuo) and not (checkElement2.isKamDuo) then 
				spellTable = {slot = slot_tid, shape = shape_tid, mode1 = mode_tid1, element1 = element_tid1, mode2 = mode_tid2, element2 = element_tid2}
			elseif (checkElement1.isKamDuo) and not (checkElement2.isKamDuo) then 
				spellTable = {slot = slot_tid, shape = shape_tid, mode1 = mode_tid1, element1 = element_tid1, element11 = element_tid11, element12 = element_tid12, mode2 = mode_tid2, element2 = element_tid2}
			elseif not (checkElement1.isKamDuo) then 
				spellTable = {slot = slot_tid, shape = shape_tid, mode1 = mode_tid1, element1 = element_tid1, mode2 = mode_tid2, element2 = element_tid2, element21 = element_tid21, element22 = element_tid22}
			else
				spellTable = {slot = slot_tid, shape = shape_tid, mode1 = mode_tid1, element1 = element_tid1, element11 = element_tid11, element12 = element_tid12, mode2 = mode_tid2, element2 = element_tid2, element21 = element_tid21, element22 = element_tid22}
			end
		else
			if checkShape.isKamNoDigging then
				local bannedMode = nil -- I'm aware this isn't a great solution but I don't care to figure it out right now.
				if self:knowTalent(self.T_KAM_MODE_DIGGING) then 
					bannedMode = self:getTalentFromId(self.T_KAM_MODE_DIGGING)
				end
			end
			local element_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
			if not element_tid then return false end 
			local checkElement = self.talents_def[element_tid]
			local element_tid11 = nil
			local element_tid12 = nil
			if (checkElement.isKamDuo) then 
				checkElement.isKamElement = false
				element_tid11 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				if not element_tid11 then 
					checkElement.isKamElement = true
					return false 
				end
				local markElement = self.talents_def[element_tid11]
				markElement.isKamElement = false
				element_tid12 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				markElement.isKamElement = true
				checkElement.isKamElement = true
				if not element_tid12 then 
					return false 
				end
			end
			
			if bannedMode then 
				bannedMode.isKamMode = false
			end
			local mode_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellModes").new(self))
			if bannedMode then 
				bannedMode.isKamMode = true 
			end
			if not mode_tid then 
				return false 
			end 

			if not (checkElement.isKamDuo) then 
				spellTable = {slot = slot_tid, shape = shape_tid, mode1 = mode_tid, element1 = element_tid}
			else 
				spellTable = {slot = slot_tid, shape = shape_tid, mode1 = mode_tid, element1 = element_tid, element11 = element_tid11, element12 = element_tid12}
			end
		end
		-- Note: isBarrage is from earlier, determined by if someone chose the barrage shape first.
		spellTable.isKamBarrage = isBarrage
		spellTable.spellType = 1 -- 1 marks attack spell
		
		KamCalc.kam_build_spell_from_ids(self, spellTable)
		
		self.kam_spell_crafted = true
		if not (self.kamSpellslotBuilder) then 
			self.kamSpellslotBuilder = {}
			for i=0, 14 do
				table.insert(self.kamSpellslotBuilder, -1)
			end
		end
		self.kamSpellslotBuilder[self.talents_def[slot_tid].kamSpellSlotNumber] = spellTable
		return slot_tid
	end,
}

newTalent{
	name = "Shielding Spell Crafting",
	short_name = "KAM_SPELL_CRAFTING_SHIELD",
	image = "talents/kam_spellweaver_defense_spell_crafting.png",
	type = {"spellweaving/crafting", 1},
	points = 1,
	no_npc_use = true,
	isKamSpellCraftingMethod = true,
	info = function(self, t)
		local combatText = "\nYou cannot craft spells in combat unless you have none."
		if (self.kam_is_combat_crafting) then
			local combatText = ""
		end
		return ([[Craft a shielding spell from spellweaving components into one of your spellweaving slots.
		Shields created by the same shield mode will not stack, others will.%s
		Normal Shield spells cost 20 mana and have a 15 turn cooldown.]]):
		tformat(combatText)
	end,
	on_pre_use = function(self, t, silent) 
		if self.kam_spell_crafted and self.in_combat and not self.kam_is_combat_crafting then 
			if not silent then 
				game.logPlayer(self, "You cannot craft spells in combat!") 
			end 
			return false 
		end 
		return true 
	end,
	action = function(self, t)
		local slot_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellSlots").new(self))
		if not slot_tid then return false end 
		local mode_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellShieldModes").new(self))
		if not mode_tid then return false end 
		local bonus_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellShieldBonuses").new(self))
		if not bonus_tid then return false end 
		
		local checkForElement = self.talents_def[bonus_tid] -- Get element(s)
		local element_tid = nil
		local element_tid1 = nil
		local element_tid2 = nil
		if checkForElement.kamRequiresElement then
			element_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
			if not element_tid then return false end 
			local checkDuo = self.talents_def[element_tid]
			if (checkDuo.isKamDuo) then 
				checkDuo.isKamElement = false
				element_tid1 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				if not element_tid1 then 
					checkDuo.isKamElement = true
					return false 
				end
				local markElement = self.talents_def[element_tid1]
				markElement.isKamElement = false
				element_tid2 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				markElement.isKamElement = true
				checkDuo.isKamElement = true
				if not element_tid2 then 
					return false 
				end
			end
		end
		
		spellTable = {slot = slot_tid, mode = mode_tid, bonus = bonus_tid, element = element_tid, element1 = element_tid1, element2 = element_tid2}

		spellTable.spellType = 2 -- 2 marks shield spell
		
		KamCalc.kam_build_shield_spell_from_ids(self, spellTable)
		
		self.kam_spell_crafted = true
		if not (self.kamSpellslotBuilder) then 
			self.kamSpellslotBuilder = {}
			for i=0, 14 do
				table.insert(self.kamSpellslotBuilder, -1)
			end
		end
		self.kamSpellslotBuilder[self.talents_def[slot_tid].kamSpellSlotNumber] = spellTable
		return slot_tid
	end,
}

newTalent{
	name = "Teleportation Spell Crafting",
	short_name = "KAM_SPELL_CRAFTING_TELEPORT",
	image = "talents/kam_spellweaver_teleport_spell_crafting.png",
	type = {"spellweaving/crafting", 1},
	points = 1,
	no_npc_use = true,
	isKamSpellCraftingMethod = true,
	info = function(self, t)
		local combatText = "\nYou cannot craft spells in combat unless you have none."
		if (self.kam_is_combat_crafting) then
			local combatText = ""
		end
		return ([[Craft a mobility spell from spellweaving components into one of your spellweaving slots.
		Components that grant a buff will not stack (unless stated otherwise).%s
		Normal Teleportation spells cost 15 mana and have a 15 turn cooldown.]]):
		tformat(combatText)
	end,
	on_pre_use = function(self, t, silent) 
		if self.kam_spell_crafted and self.in_combat and not self.kam_is_combat_crafting then 
			if not silent then 
				game.logPlayer(self, "You cannot craft spells in combat!") 
			end 
			return false 
		end 
		return true 
	end,
	action = function(self, t)
		local slot_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellSlotsAllowTeleport").new(self))
		if not slot_tid then return false end 
		local mode_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellTeleportModes").new(self))
		if not mode_tid then return false end 
		local bonus_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellTeleportBonuses").new(self))
		if not bonus_tid then return false end 
		
		local checkForElement = self.talents_def[bonus_tid] -- Get element(s)
		local element_tid = nil
		local element_tid1 = nil
		local element_tid2 = nil
		if checkForElement.kamRequiresElement then
			element_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
			if not element_tid then return false end 
			local checkDuo = self.talents_def[element_tid]
			if (checkDuo.isKamDuo) then 
				checkDuo.isKamElement = false
				element_tid1 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				if not element_tid1 then 
					checkDuo.isKamElement = true
					return false 
				end
				local markElement = self.talents_def[element_tid1]
				markElement.isKamElement = false
				element_tid2 = self:talentDialog(require("mod.dialogs.talents.KamSpellElements").new(self))
				markElement.isKamElement = true
				checkDuo.isKamElement = true
				if not element_tid2 then 
					return false 
				end
			end
		end
		
		spellTable = {slot = slot_tid, mode = mode_tid, bonus = bonus_tid, element = element_tid, element1 = element_tid1, element2 = element_tid2}

		spellTable.spellType = 3 -- 3 marks teleport spell
		
		KamCalc.kam_build_teleport_spell_from_ids(self, spellTable)
		
		self.kam_spell_crafted = true
		if not (self.kamSpellslotBuilder) then 
			self.kamSpellslotBuilder = {}
			for i=0, 14 do
				table.insert(self.kamSpellslotBuilder, -1)
			end
		end
		self.kamSpellslotBuilder[self.talents_def[slot_tid].kamSpellSlotNumber] = spellTable
		return slot_tid
	end,
}