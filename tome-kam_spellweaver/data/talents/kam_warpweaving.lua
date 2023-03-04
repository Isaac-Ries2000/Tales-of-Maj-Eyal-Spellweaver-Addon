local Map = require "engine.Map"
local Chat = require "engine.Chat"
local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ generic = true, type = "spellweaving/warpweaving", no_silence = true, is_spell = true, name = _t("warpweaving", "talent type"), description = _t"The art of weaving teleportation and mobility spells." }
spells_req1 = {
	stat = { mag=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
spells_req2 = {
	stat = { mag=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
spells_req3 = {
	stat = { mag=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
spells_req4 = {
	stat = { mag=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}

-- The basic teleportation tree. Has:
-- Range/core.
-- %chance to fail out of LOS.
-- Precision modifier.
-- Mastery.

-- The warp core.
newTalent{ -- back-forth
	name = "The Art of Warpweaving",
	short_name = "KAM_SPELLWEAVER_WARP_CORE",
	image = "talents/kam_spellweaver_the_art_of_warpweaving.png",
--	image = "talents/banish.png",
	type = {"spellweaving/warpweaving", 1},
	points = 5,
	require = spells_req1,
	mode = "passive",
	no_unlearn_last = true,
	getRange = function(self, t) -- Originally based on Phase Door from the Conveyance tree.
		return self:combatLimit(self:combatTalentSpellDamage(t, 10, 15), 40, 4, 0, 13.4, 9.4) 
	end,
	getTeleportFizzleRate = function(self, t)
		if self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_FIZZLE) then 
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_WARP_FIZZLE)
			return tal.getTeleportFizzleRate(self, tal)
		end
		return 0.5
	end,
	getPrecisionMod = function(self, t) 
		if self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_PRECISION) then 
			local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_WARP_PRECISION)
			return tal.getPrecisionMod(self, tal)
		end
		return 1
	end,
	info = function(self, t)
		return ([[Teleportation is a simple process once you understand the nature of the magical threads that make up the world.
You gain the Teleport Spell Crafting spell. Teleportation spells you create have a base %d range, multiplied by Spellweave Multiplier. Unlike the uncontrolled teleportation practiced by Archmages, you will always be able to control where you are targeting, but you still have a %d%% chance to fail when attempting to teleport to places you cannot see (chance affected by the Threaded Understanding talent). Spells that have precision will be divided by Spellweave Multipler and modified by your precision modifier, %d%%, which is improved by the Threaddance talent.
Range scales with spellpower and talent level. Bonuses that grant a buff will not stack.
Additionally, gain the basic Teleport Components - Mode: Blink and Bonus: None. If you do not have the first Spell Slot from the Spellweaver tree, also gain that Spell Slot. 
At raw talent level 3, also gain Teleport Bonus: Phasing (After teleport, increase defense and all resist and reduce the duration of new effects for 3 turns).
At raw talent level 5, also gain Teleport Mode: Blink Any (Teleport any target, but has reduced Spellweave Multiplier).]]):tformat(t.getRange(self, t), t.getTeleportFizzleRate(self, t) * 100, t.getPrecisionMod(self, t) * 100)
	end, --  and one Teleport Spell Slot, which can only contain Teleport spells and comes by default with a basic Blink spell
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_WARPMODE_BLINK)) then
			self:learnTalent(Talents.T_KAM_WARPMODE_BLINK, true)
		end
		if not (self:knowTalent(self.T_KAM_WARPBONUS_NONE)) then
			self:learnTalent(Talents.T_KAM_WARPBONUS_NONE, true)
		end
		if not (self:knowTalent(self.T_KAM_SPELL_CRAFTING_TELEPORT)) then
			self:learnTalent(Talents.T_KAM_SPELL_CRAFTING_TELEPORT, true)
		end
		if self:getTalentLevelRaw(t) >= 3 then
			if not (self:knowTalent(self.T_KAM_WARPBONUS_PHASE)) then
				self:learnTalent(Talents.T_KAM_WARPBONUS_PHASE, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_BLINKANY)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_BLINKANY, true)
			end
		end
--[[
		if not self:knowTalent(self.T_KAM_SPELL_SLOT_TELEPORT_UNIQUE) and (self == game.party:findMember{main=true}) then
			self:learnTalent(Talents.T_KAM_SPELL_SLOT_TELEPORT_UNIQUE, true)
			
			if not (self.kamSpellslotBuilder) then 
				self.kamSpellslotBuilder = {}
			end
			local spellTable

			spellTable = {slot = "T_KAM_SPELL_SLOT_TELEPORT_UNIQUE", mode = "T_KAM_WARPMODE_BLINK", bonus = "T_KAM_WARPBONUS_NONE", spellType = 3}
			KamCalc.kam_build_teleport_spell_from_ids(self, spellTable)
			self.kamSpellslotBuilder[14] = spellTable
		end
--]]
		KamCalc:updateSpellSlotNumbers(self)
	end, 
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_BLINK)
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_NONE)
			self:unlearnTalent(Talents.T_KAM_SPELL_CRAFTING_TELEPORT)
			self:unlearnTalent(Talents.T_KAM_SPELL_SLOT_TELEPORT_UNIQUE)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_PHASE)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_BLINKANY)
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
}

-- Fizzle rate.
newTalent{ -- psychic-waves
	name = "Threaded Understanding",
	short_name = "KAM_SPELLWEAVER_WARP_FIZZLE",
	image = "talents/kam_spellweaver_threaded_understanding.png",
--	image = "talents/disruption_shield.png",
	type = {"spellweaving/warpweaving", 2},
	points = 5,
	require = spells_req2,
	mode = "passive",
	no_unlearn_last = true,
	getTeleportFizzleRate = function(self, t)
		if self:getTalentLevel(t) >= 5 then 
			return 0
		end
		return (0.5 - self:combatTalentLimit(self:getTalentLevel(t), 0.5, 0.08, 0.45))
	end,
	info = function(self, t)
		return ([[Where normal mages find teleporting to places they cannot see difficult, your grasp of teleportation theory and your practiced spacial sense give you an advantage.
Your chance of teleports fizzling when you teleport out of line of sight is reduced to %d%%. At level 5, teleports will always work as long as there is space to teleport to.
At raw talent level 3, also gain Teleport Bonus: Pulse (Deal one third of element damage, modified by Spellweave Multiplier to enemies before and after the teleport).
At raw talent level 5, also gain Teleport Mode: Teleport (High range, low accuracy, low Spellweave Multiplier).]]):tformat(t.getTeleportFizzleRate(self, t) * 100)
	end,
	on_learn = function(self, t) 
		if self:getTalentLevelRaw(t) >= 3 then
			if not (self:knowTalent(self.T_KAM_WARPBONUS_PULSE)) then
				self:learnTalent(Talents.T_KAM_WARPBONUS_PULSE, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_TELEPORT)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_TELEPORT, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_PULSE)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_TELEPORT)
		end
	end,
}

-- Teleport Precision.
newTalent{ -- relationship-bounds
	name = "Threaddance",
	short_name = "KAM_SPELLWEAVER_WARP_PRECISION",
	image = "talents/kam_spellweaver_threaddance.png",
--	image = "talents/dimensional_step.png",
	type = {"spellweaving/warpweaving", 3},
	points = 5,
	require = spells_req3,
	mode = "passive",
	no_unlearn_last = true,
	getPrecisionMod = function(self, t)
		return (1 - self:combatTalentLimit(self:getTalentLevel(t), 0.6, 0.08, 0.5))
	end,
	info = function(self, t)
		return ([[As a Spellweaver, your magic is precise and perfect, and teleportation is no exception.
Your Precision Modifier becomes %d%%.
At raw talent level 3, also gain Teleport Bonus: Restoration (Gain regeneration at the end of the teleport).
At raw talent level 5, also gain Teleport Mode: Threadleap (Lower range and requires Line of Sight, but is perfectly accurate and cannot be silenced).]]):tformat(t.getPrecisionMod(self, t) * 100)
	end,
	on_learn = function(self, t) 
		if self:getTalentLevelRaw(t) >= 3 then
			if not (self:knowTalent(self.T_KAM_WARPBONUS_RESTORATION)) then
				self:learnTalent(Talents.T_KAM_WARPBONUS_RESTORATION, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_THREADLEAP)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_THREADLEAP, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_RESTORATION)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_THREADLEAP)
		end
	end,
}

newTalent{ -- abstract-053
	name = "Spellweaver's Direction",
	short_name = "KAM_SPELLWEAVER_TELEPORT_MASTERY",
	image = "talents/kam_spellweaver_spellweavers_direction.png",
--	image = "talents/displace_damage.png",
	type = {"spellweaving/warpweaving", 4},
	points = 5,
	require = spells_req4,
	mode = "passive",
	no_unlearn_last = true,
	getSpellweaverPowerBoost = function(self, t) 
		return self:combatTalentLimit(self:getTalentLevel(t), .25, .05, .15)
	end,
	info = function(self, t)
		return ([[You always know where you are going, and you will always get there.
		Your Teleport spells gain an additional %d%% Spellweave Multiplier.
		At raw talent level 3, also gain the Teleport Bonus: Trick (Temporarily reduce the damage and resistances of enemies within radius 2 of you when you teleport)
		At raw talent level 5, also gain the Teleport Mode: Wormholes (Create two wormholes that can be used by anything repeatedly, applying bonuses each time with diminishing power).]]):tformat(t.getSpellweaverPowerBoost(self, t) * 100)
	end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_WARPBONUS_TRICK)) then
				self:learnTalent(Talents.T_KAM_WARPBONUS_TRICK, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 5 then
			if not (self:knowTalent(self.T_KAM_WARPMODE_WORMHOLE)) then
				self:learnTalent(Talents.T_KAM_WARPMODE_WORMHOLE, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_WARPBONUS_TRICK)
		end
		if self:getTalentLevelRaw(t) < 5 then
			self:unlearnTalent(Talents.T_KAM_WARPMODE_WORMHOLE)
		end
	end,
}