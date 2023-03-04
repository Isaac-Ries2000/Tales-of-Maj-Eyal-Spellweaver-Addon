local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ generic = true, type = "spellweaving/metaweaving", no_silence = true, is_spell = true, name = _t("metaweaving", "talent type"), description = _t"Spellweaving is complicated enough, but a truly artful Spellweaver can perform much more complicated technqiues." }

spells_req_high1 = {
	stat = { mag=function(level) return 22 + (level-1) * 2 end },
	level = function(level) return 10 + (level-1)  end,
}
spells_req_high2 = {
	stat = { mag=function(level) return 30 + (level-1) * 2 end },
	level = function(level) return 14 + (level-1)  end,
}
spells_req_high3 = {
	stat = { mag=function(level) return 38 + (level-1) * 2 end },
	level = function(level) return 18 + (level-1)  end,
}
spells_req_high4 = {
	stat = { mag=function(level) return 46 + (level-1) * 2 end },
	level = function(level) return 22 + (level-1)  end,
}

-- Metaweaving: All of the weird types of Spellweave trickery that you normally don't get.
-- Spellweave components to implement: (The Questionable Ones)
--	Random Shape: On cast, choose random shape. Increases Spellweave power.
--	Random Element: On cast, choose random element. Increases Spellweave power. (Remember, this means you can't benefit from plus attack nearly as much)
--	Random Shield: On cast, choose a random (non-Sustain) shield.
--	Random Teleport: On cast, choose a random teleport skill.

-- One of the original skills inspiring metaweaving. A literal one pointer, given that I really just don't want to add an unnecessary bonus scaling effect to it? Maybe later.
newTalent{ -- abstract-112
	name = "Power Loom",
	short_name = "KAM_METAWEAVING_CRAFT",
	type = {"spellweaving/metaweaving", 1},
	require = spells_req_high1,
	image = "talents/kam_spellweaver_power_loom.png",
--	image = "talents/thread_the_needle.png", 
	points = 1,
	cooldown = 40,
	no_energy = true,
	info = function(self, t)
		return ([[Through an advanced spellweaver technique, you can craft spells far more quickly than normal.
		Instantly craft one spell of any type you can normally craft, even in combat.]]):
		tformat()
	end,
	action = function(self, t)
		self.kam_is_combat_crafting = true
		local craftingMethodId = self:talentDialog(require("mod.dialogs.talents.KamSpellCraftingMethodSelect").new(self))
		if not craftingMethodId then 
			self.kam_is_combat_crafting = false
			return false 
		end
		local craftingMethod = self.talents_def[craftingMethodId]
		local slotTid = craftingMethod.action(self, craftingMethod)
		self.kam_is_combat_crafting = false
		if slotTid then
			if self:attr("kam_beacon_of_spellweavers_attr") then
				if self.talents_types["spellweaving/spellweaving-mastery"] then
					self.talents_cd[slotTid] = (self:getTalentFromId(slotTid).cooldown) / 4
				end
			end
			return true
		end
		return false
	end,
}

-- Swippy Swappy. This talent might be annoying to use, but bright side, it's very fancy.
newTalent{ -- abstract-097
	name = "Threadswitch",
	short_name = "KAM_METAWEAVING_THREADSWITCH",
	type = {"spellweaving/metaweaving", 2},
	require = spells_req_high2,
	image = "talents/kam_spellweaver_threadswitch.png",
--	image = "talents/skirmisher_the_eternal_warrior.png", -- I mean that's what it does.
	points = 5,
	cooldown = function(self, t) return (math.max(5, 35 - self:getTalentLevel(t) * 3)) end,
	getCooldownReduction = function(self, t) return self:combatTalentScale(t, 3, 7) end,
	getDoubleCooldownReduction = function(self, t) return math.ceil(t.getCooldownReduction(self, t) / 2) end,
	no_energy = true,
	action = function(self, t)
		local slot_tidOne = self:talentDialog(require("mod.dialogs.talents.KamSpellSlotsSelectionThreadswitch").new(self))
		if not slot_tidOne then return false end 
		local slotOne = self.talents_def[slot_tidOne]
		slotOne.kamExcludeFromThreadswitch = true
		local slot_tidTwo = self:talentDialog(require("mod.dialogs.talents.KamSpellSlotsSelectionThreadswitch").new(self))
		slotOne.kamExcludeFromThreadswitch = nil
		if not slot_tidTwo then return false end 
		local cooldownOne = self.talents_cd[slot_tidOne] or 0
		local cooldownTwo = self.talents_cd[slot_tidTwo] or 0
		if (cooldownOne == 0 and cooldownTwo == 0) then
			game.log("Neither spell is on cooldown.")
			return false
		end
		if (math.floor(cooldownOne) == math.floor(cooldownTwo)) then
			cooldownOne = cooldownOne - t.getDoubleCooldownReduction(self, t)
			cooldownTwo = cooldownTwo - t.getDoubleCooldownReduction(self, t)		
		elseif (cooldownOne > cooldownTwo) then
			cooldownOne = cooldownOne - t.getCooldownReduction(self, t)
		else
			cooldownTwo = cooldownTwo - t.getCooldownReduction(self, t)
		end
		if cooldownTwo > 0 and (self:getTalentFromId(slot_tidOne).mode == "sustained") and self:isTalentActive(slot_tidOne) then
			self:forceUseTalent(slot_tidOne, {ignore_energy = true, silent = true})
		end
		if cooldownOne > 0 and (self:getTalentFromId(slot_tidTwo).mode == "sustained") and self:isTalentActive(slot_tidTwo) then
			self:forceUseTalent(slot_tidTwo, {ignore_energy = true, silent = true})
		end
		if (cooldownOne <= 0) then cooldownOne = nil end
		if (cooldownTwo <= 0) then cooldownTwo = nil end
		self.talents_cd[slot_tidOne] = cooldownTwo
		self.talents_cd[slot_tidTwo] = cooldownOne
		return true
	end,
	info = function(self, t)
		return ([[In the end, all of your magic comes from the same source. With a bit of finesse, you can always have an edge.
		Choose two Spellwoven spells and swap their current cooldowns, then reduce the current cooldown of the one with the longer cooldown by %d (if both are equal, instead reduce both by %d). Spells swapped this way must be either Sustains or Activated spells and any Sustain that was active will be disabled if it's cooldown becomes non-zero. Cooldown and cooldown reduction scales with talent level.]]):
		tformat(t.getCooldownReduction(self, t), t.getDoubleCooldownReduction(self, t))
	end,
}

newTalent{ -- abstract-119
	name = "Meta Empowerment",
	short_name = "KAM_METAWEAVING_EMPOWERMENT",
	type = {"spellweaving/metaweaving", 3},
	require = spells_req_high3,
	no_sustain_autoreset = true,
	image = "talents/kam_spellweaver_meta_empowerment.png",
--	image = "talents/redirect.png",
	points = 5,
	cooldown = function(self, t) return (math.max(5, 25 - self:getTalentLevel(t) * 2)) end,
	mode = "sustained",
	sustain_mana = 35,
	speed = "spell",
	tactical = { BUFF = 2 },
	
	getSpellweaveMod = function(self, t) return self:combatTalentScale(t, 1.05, 1.25) end, -- This is a flat multiplier on all effects of a spell, so a little can do a lot on a pretty cheap talent.
	activate = function(self, t)
		if self ~= game.player then -- If not the player, just force it to be on the first one.
			local retVal = {}
			retVal.boostedTalentId = (self.talents_def[self.T_KAM_SPELL_SLOT_ONE]).kamSpellSlotNumber
			retVal.boostedTalentTId = "T_KAM_SPELL_SLOT_ONE"
			return retVal
		end
		game:playSoundNear(self, "talents/spell_generic2")
		local slot_tid = self:talentDialog(require("mod.dialogs.talents.KamSpellSlotsSelection").new(self))
		if not slot_tid then return false end
		local retVal = {}
		retVal.boostedTalentId = (self.talents_def[slot_tid]).kamSpellSlotNumber
		retVal.boostedTalentTId = slot_tid
		return retVal
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		local talentText = "Currently inactive."
		local talent = self:isTalentActive(t.id)
		if (talent) then
			talentText = "Currently improved spell: "..(self.talents_def[talent.boostedTalentTId]).name.." in Spell Slot "..(talent.boostedTalentId + 1).."."
		end
		return ([[By focusing on a single spell, you can enhance its effects to impressive levels.
		Choose one Spellwoven spell. As long as this spell is sustained, that spell gains an additional %0.2f Spellweave Multiplier modifer.
		
		%s]]):
		tformat(t.getSpellweaveMod(self, t), talentText)
	end,
}

-- I was thinking about weird talents for the last thing I needed, and I came up with this.
newTalent{ -- abstract-111
	name = "Harmonic Paradise",
	short_name = "KAM_METAWEAVING_SANCTUARY",
	type = {"spellweaving/metaweaving", 4},
	require = spells_req_high4,
	image = "talents/kam_spellweaver_harmonic_paradise.png",
	no_unlearn_last = true,
--	image = "talents/shertul_fortress_orbit.png",
	points = 5,
	cooldown = 50,
	mana = 50,
	no_energy = true,
	tactical = { BUFF = 1 }, -- This would be funny if an enemy has it.
	
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 3 then
			if not self:knowTalent(self.T_KAM_ELEMENT_ELEMENTAL_RANDOM) then
				self:learnTalent(Talents.T_KAM_ELEMENT_ELEMENTAL_RANDOM, true)
			end
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_ELEMENT_ELEMENTAL_RANDOM)
		end
	end,
	
	getParadiseTurns = function(self, t) -- Hardcoded wierdly because it was given nothing at 1.0 mastery for Talent Levels 4 AND 5.
		local level = self:getTalentLevel(t)
		if level < 2 then return 2 end
		if level < 3 then return 3 end
		if level < 5 then return 4 end
		if level < 6 then return 5 end
		if level < 7 then return 6 end
		return 7
	end,
	action = function(self, t)
		self:setEffect(self.EFF_KAM_SPELLWEAVER_METAPARADISE, t.getParadiseTurns(self, t), {})
		return true
	end,
	info = function(self, t)
		return ([[Through a perfect understanding of the Spellweave, weave all of the elements, all of magic, everything, into a perfect alignment for a short moment.
		For %d turns, you cannot take damage and the durations of beneficial effects decrement half as quickly. However, maintaining such a perfect weave prevents you from dealing any damage. Effects that disrupt beneficial effects will not disrupt this effect.
		At raw talent level three, also gain Element: Random (when the spell is cast, or on each trigger for a sustain, the element of the spell is selected randomly (although its talent level is treated as the average of your highest three talent levels) with an increased 10%% effective Spellweave Multiplier for damage and effect chance and power.]]):
		tformat(t.getParadiseTurns(self, t))
	end,
}