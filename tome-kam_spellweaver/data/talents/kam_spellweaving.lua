local Map = require "engine.Map"
local Chat = require "engine.Chat"
local KamCalc = require "mod.KamHelperFunctions"
local ActorTalents = require "engine.interface.ActorTalents"

newTalentType{ type = "spellweaving/spellweaver", no_silence = true, is_spell = true, name = _t("spellweaver", "talent type"), description = _t"The arts of weaving spells." }
spells_req1 = {
	stat = { mag=function(level) return 12 + (level-1) * 3 end },
	level = function(level) return 0 + 2 * (level-1)  end,
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
-- The basic spellweaving tree. 
-- All talents were compressed into 3 pointers since they have fairly minor benefits and I felt like this way means you can actually afford to take Spellweaver's Cool Stuff more easily.

-- This thing literally is just learn/unlearn 4 passives, 1 control, and 4 active spells.
-- Note: Talent compressed down into a 3 pointer since frankly having three from the start really helps and the investment felt weird for how it worked.
newTalent{ -- juggler
	name = "Spellweaver",
	short_name = "KAM_SPELLWEAVER_CORE",
	image = "talents/kam_spellweaver_core_spellweaver.png", -- It's a little over the top. Maybe too much?
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaver", 1},
	points = 3,
	require = spells_req1,
	mode = "passive",
	no_unlearn_last = true,
	info = function(self, t)
		return ([[Rather than pluck and pull on the elemental threads of the world, you understand how to weave them to produce perfectly controlled effects.
You gain the Attack Spell Crafting spell and %d Spell Slots that you can craft spells into, gaining another at raw talent level 3. If you have no crafted spells, you also start out with basic spells Beam of Fiery Harm, Beam of Shadowed Harm, and (if you know the Shielding and Teleport based Spellweaving trees) Shield and Blink.
Additionally, gain the basic Spell Components - Shape: Beam and Mode: Basic Damage.
At raw talent level 2, gain Shape: Bolt and Shape: Burst.]]):tformat(t.listSpellslotCount(self, t))
	end,
	on_levelup_close = function(self, t, lvl, old_lvl, lvl_raw, old_lvl_raw)
		if not self.kam_spell_crafted then
			if not (self.kamSpellslotBuilder) then 
				self.kamSpellslotBuilder = {}
				for i=0, 14 do -- Number increased, just in case.
					table.insert(self.kamSpellslotBuilder, -1)
				end
			end
			local spellTable

			spellTable = {slot = "T_KAM_SPELL_SLOT_ONE", shape = "T_KAM_SHAPE_BEAM", mode1 = "T_KAM_MODE_DAMAGE", element1 = "T_KAM_ELEMENT_FLAME", spellType = 1}
			KamCalc.kam_build_spell_from_ids(self, spellTable)			
			self.kamSpellslotBuilder[0] = spellTable

			spellTable = {slot = "T_KAM_SPELL_SLOT_TWO", shape = "T_KAM_SHAPE_BEAM", mode1 = "T_KAM_MODE_DAMAGE", element1 = "T_KAM_ELEMENT_LIGHT", spellType = 1}
			KamCalc.kam_build_spell_from_ids(self, spellTable)
			self.kamSpellslotBuilder[1] = spellTable

			if self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_CORE) or game.turn == 0 then -- Can't assume when exactly we know talents at turn 0 so this is for safety and reliability on Spellweaver start.
				spellTable = {slot = "T_KAM_SPELL_SLOT_THREE", mode = "T_KAM_SHIELDMODE_BASIC", bonus = "T_KAM_SHIELDBONUS_NONE", spellType = 2}
				KamCalc.kam_build_shield_spell_from_ids(self, spellTable)
				self.kamSpellslotBuilder[2] = spellTable
			end

			if self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_CORE) or game.turn == 0 then
				spellTable = {slot = "T_KAM_SPELL_SLOT_FOUR", mode = "T_KAM_WARPMODE_BLINK", bonus = "T_KAM_WARPBONUS_NONE", spellType = 3}
				KamCalc.kam_build_teleport_spell_from_ids(self, spellTable)
				self.kamSpellslotBuilder[3] = spellTable
			end
			
			self.kam_spell_crafted = true
		end
	end,
	listSpellslotCount = function (self, t)
		if self:getTalentLevelRaw(t) < 3 then
			return 4
		else
			return 5
		end
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHAPE_BEAM)) then
			self:learnTalent(Talents.T_KAM_SHAPE_BEAM, true)
		end
		if not (self:knowTalent(self.T_KAM_MODE_DAMAGE)) then
			self:learnTalent(Talents.T_KAM_MODE_DAMAGE, true)
		end
		KamCalc:updateSpellSlotNumbers(self)
		if not (self:knowTalent(self.T_KAM_SPELL_CRAFTING)) then
			self:learnTalent(Talents.T_KAM_SPELL_CRAFTING, true)
		end
		if self:getTalentLevelRaw(t) == 2 then
			if not (self:knowTalent(self.T_KAM_SHAPE_BOLT)) then
				self:learnTalent(Talents.T_KAM_SHAPE_BOLT, true)
			end			
			if not (self:knowTalent(self.T_KAM_SHAPE_BURST)) then
				self:learnTalent(Talents.T_KAM_SHAPE_BURST, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 3 then
			if (self == game.party:findMember{main=true}) and not (self:knowTalent(self.T_KAM_SPELL_SLOT_FOUR)) then
				self:learnTalent(Talents.T_KAM_SPELL_SLOT_FOUR, true)
			end			
		end
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_SHAPE_BEAM)
			self:unlearnTalent(Talents.T_KAM_MODE_DAMAGE)
			self:unlearnTalent(Talents.T_KAM_SPELL_CRAFTING)
			if not self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_CORE) and not self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_CORE) then 
				self:unlearnTalent(Talents.T_KAM_SPELL_SLOT_ONE)
			end
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_SHAPE_BOLT)
			self:unlearnTalent(Talents.T_KAM_SHAPE_BURST)
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
}

-- Talent maxes reduced to 3 since direct benefits are fairly minor and I really want players to be able to get shapes and modes more easily.
-- To do this, it now uses talentLevel * 5/3 and gives Mode: DoT and Mode: Exploit Weakness at RTLs 2 and 3 instead of 3 and 5
newTalent{ -- abstract-011
	name = "Spellweaver's Power",
	short_name = "KAM_SPELLWEAVER_POWER",
	image = "talents/kam_spellweaver_spellweavers_power.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaver", 2},
	points = 3,
	mode = "passive",
	require = spells_req2,
	no_unlearn_last = true,
	getSpellpowerIncrease = function(self, t) 
		return self:combatTalentScale(self:getTalentLevel(t) * 5 / 3, 3, 15, 0.75)
	end,
	info = function(self, t)
		return ([[You understand the power of subtlety, but also the power of power.
You gain %d Spellpower and you gain Shape: Cone.
At raw talent level 2, gain Mode: Damage Over Time (Damage is dealt over several turns).
At raw talent level 3, also gain Mode: Exploit Weakness (Damage and status chance modified by half of the power of resistances befores resistances are normally applied) and Mode: Lingering (Create tiles that damage enemies and last for several turns).]]):tformat(t.getSpellpowerIncrease(self, t))
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_spellpower", t.getSpellpowerIncrease(self, t))
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHAPE_CONE)) then
			self:learnTalent(Talents.T_KAM_SHAPE_CONE, true)
		end
		if self:getTalentLevelRaw(t) == 2 then
			if not (self:knowTalent(self.T_KAM_MODE_DOT)) then
				self:learnTalent(Talents.T_KAM_MODE_DOT, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_MODE_EXPLOIT)) then
				self:learnTalent(Talents.T_KAM_MODE_EXPLOIT, true)
			end
			if not (self:knowTalent(self.T_KAM_MODE_LINGERING)) then
				self:learnTalent(Talents.T_KAM_MODE_LINGERING, true)
			end
		end
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_SHAPE_CONE)
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_MODE_DOT)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_MODE_EXPLOIT)
			self:unlearnTalent(Talents.T_KAM_MODE_LINGERING)
		end
	end,
}

-- Made a 3 pointer since everything else in the tree was.
-- Now uses Talent Level * 5 / 3, gives Wall up front instead of at 2, gives Large Beam at 2 instead of 4, gives Resisting at 2 instead of 3, gives Cross at 3 instead of 4, and gives applying at 3 instead of 5.
newTalent{ -- abstract-034
	name = "Spellweaver's Finesse",
	short_name = "KAM_SPELLWEAVER_FINESSE",
	image = "talents/kam_spellweaver_spellweavers_finesse.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaver", 3},
	require = spells_req3,
	points = 3,
	mode = "passive",
	getCrit = function(self, t) 
		return self:combatTalentScale(self:getTalentLevel(t) * 5 / 3, 2, 9, 0.75) 
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "combat_spellcrit", t.getCrit(self, t))
	end,
	no_unlearn_last = true,
	info = function(self, t)
		return ([[You have learned how to shape your spells to make them perfectly precise. Increase your spell critical chance by %d%%.
Additionally, you've discovered some of the stranger ways to shape your spells.
Gain access to Shape: Wall.
At raw talent level 2, gain access to Shape: Large Beam and Mode: Resisting (Reduce Spellweave Multiplier, but gain temporary resistance to the Spell's Element).
At raw talent level 3, gain access to Shape: Cross and Mode: Applying (Damage is reduced by 40%%, but effective Spellweave Multiplier for element status effects is increased by 50%%.]]):tformat(t.getCrit(self, t))
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_SHAPE_WALL)) then
			self:learnTalent(Talents.T_KAM_SHAPE_WALL, true)
		end
		if self:getTalentLevelRaw(t) == 2 then
			if not (self:knowTalent(self.T_KAM_SHAPE_WIDEBEAM)) then
				self:learnTalent(Talents.T_KAM_SHAPE_WIDEBEAM, true)
			end	
			if not (self:knowTalent(self.T_KAM_MODE_ELEMENTAL_SHIELD)) then
				self:learnTalent(Talents.T_KAM_MODE_ELEMENTAL_SHIELD, true)
			end			
		end
		if self:getTalentLevelRaw(t) == 3 then
			if not (self:knowTalent(self.T_KAM_SHAPE_CROSS)) then
				self:learnTalent(Talents.T_KAM_SHAPE_CROSS, true)
			end	
			if not (self:knowTalent(self.T_KAM_MODE_APPLY)) then
				self:learnTalent(Talents.T_KAM_MODE_APPLY, true)
			end	
		end
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_SHAPE_WALL)
		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_SHAPE_WIDEBEAM)
			self:unlearnTalent(Talents.T_KAM_MODE_ELEMENTAL_SHIELD)
		end
		if self:getTalentLevelRaw(t) < 3 then
			self:unlearnTalent(Talents.T_KAM_SHAPE_CROSS)
			self:unlearnTalent(Talents.T_KAM_MODE_APPLY)
		end
	end,
}

newTalent{ -- abstract-061
	name = "Spellweaver Adept",
	short_name = "KAM_SPELLWEAVER_ADEPT",
	image = "talents/kam_spellweaver_spellweaver_adept.png",
--	image = "talents/imbue_item.png",
	type = {"spellweaving/spellweaver", 4},
	points = 3,
	mode = "passive",
	require = spells_req4,
	no_unlearn_last = true,
	info = function(self, t)
		return ([[As an Adept in the art of Spellweaving, you've learned many ways to shape your spells and to use tools to enhance them further.
		Gain access to Element: Duo (Choose any other two elements you know and use them, both at half strength). Additionally, staves now give you the all modifier increase instead of a boost to their respective element (staves with the Greater ego, including most artifact staves that give multiple element damage increases, as well as staves that do not give damage increases or do not grant Command Staff will not be affected).
		At raw talent level 2, gain access to Shape: Square (A basic square) and Mode: Forceful (Spell damage increased by 50%%, but the spell no longer inflicts status effects at all).
		At raw talent level 3, gain an additional Spell Slot.]]):tformat()
	end,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_DOUBLE)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_DOUBLE, true)
		end
		if self:getTalentLevelRaw(t) == 1 then
			for i, o in ipairs(self:getInven("MAINHAND") or {}) do 
				self:onTakeoff(o, self.INVEN_MAINHAND, true) 
				self:onWear(o, self.INVEN_MAINHAND, true) 
			end
			for i, o in ipairs(self:getInven("OFFHAND") or {}) do 
				self:onTakeoff(o, self.INVEN_OFFHAND, true) 
				self:onWear(o, self.INVEN_OFFHAND, true) 
			end
			for i, o in ipairs(self:getInven("PSIONIC_FOCUS") or {}) do -- To my knowledge I don't think you can learn to do this on a non-psionic character, but it might be added?
				self:onTakeoff(o, self.INVEN_PSIONIC_FOCUS, true) 
				self:onWear(o, self.INVEN_PSIONIC_FOCUS, true) 
			end
		end
		if self:getTalentLevelRaw(t) == 2 then
			if not (self:knowTalent(self.T_KAM_SHAPE_SQUARE)) then
				self:learnTalent(Talents.T_KAM_SHAPE_SQUARE, true)
			end
			if not (self:knowTalent(self.T_KAM_MODE_FORCEFUL)) then
				self:learnTalent(Talents.T_KAM_MODE_FORCEFUL, true)
			end
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then
			self:unlearnTalent(Talents.T_KAM_ELEMENT_DOUBLE)
			for i, o in ipairs(self:getInven("MAINHAND") or {}) do 
				self:onTakeoff(o, self.INVEN_MAINHAND, true) 
				self:onWear(o, self.INVEN_MAINHAND, true) 
			end
			for i, o in ipairs(self:getInven("OFFHAND") or {}) do 
				self:onTakeoff(o, self.INVEN_OFFHAND, true) 
				self:onWear(o, self.INVEN_OFFHAND, true) 
			end
			for i, o in ipairs(self:getInven("PSIONIC_FOCUS") or {}) do
				self:onTakeoff(o, self.INVEN_PSIONIC_FOCUS, true) 
				self:onWear(o, self.INVEN_PSIONIC_FOCUS, true) 
			end

		end
		if self:getTalentLevelRaw(t) < 2 then
			self:unlearnTalent(Talents.T_KAM_SHAPE_SQUARE)
			self:unlearnTalent(Talents.T_KAM_MODE_FORCEFUL)
		end
		KamCalc:updateSpellSlotNumbers(self)
	end,
	callbackOnTakeoff = function(self, t, obj) -- The corresponding callback was implemented as a hook because of weird design.
		if (obj.__kam_staff_all_data) then
			obj:tableTemporaryValuesRemove(obj.__kam_staff_all_data)
		end
	end,
}