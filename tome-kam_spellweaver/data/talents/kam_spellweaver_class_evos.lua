local KamCalc = require "mod.KamHelperFunctions"

uberTalent = function(t)
	t.type = {"uber/magic", 1}
	t.uber = true
	t.require = t.require or {}
	t.require.stat = t.require.stat or {}
	t.require.level = 25
	t.require.stat.mag = 50
	t.no_npc_use = true
	newTalent(t)
end

-- TODO: Check if this causes issues with Writhing Ring of the Hunter on either of its prodigies. That would be weird for someone to try but it could theoretically happen.
uberTalent{
	name = "Grand Elementalist",
	image = "talents/kam_spellweaver_true_elementalist.png", -- Reused from true elementalist, since they're both passives.
	require = { -- Note: You always have 10 elements as a Spellweaver, so this is funcitonally free.
		birth_descriptors={{"subclass", "Spellweaver"}},
		special={desc=_t"Know at least 10 elements (not including Duo)", fct=function(self)
			return KamCalc:countSpellwovenElements(self) >= 10
		end},
		stat = {cun=25}, -- Willpower would make more sense but the prodigies scale with cun so...
	},
	is_class_evolution = "Spellweaver",
	cant_steal = true,
	is_spell = true,
	mode = "passive",
	on_learn = function(self, t)
		if not self:knowTalent(self.T_ELEMENTAL_SURGE) then
			self:learnTalent(self.T_ELEMENTAL_SURGE, true)
		end
		if not self:knowTalent(self.T_ENDLESS_WOES) then
			self:learnTalent(self.T_ENDLESS_WOES, true)
		end

		if self:knowTalentType("spellweaving/elementalist") then
			self:learnTalent(self.T_KAM_ELEMENTS_GRAVECHILL, true)
			self:learnTalent(self.T_KAM_ELEMENTS_GRAVITY, true)
			self:learnTalent(self.T_KAM_ELEMENTS_FEVER, true)
			self:learnTalent(self.T_KAM_ELEMENTS_MANASTORM, true)
			self:learnTalent(self.T_KAM_ELEMENTS_CORRODING_BRILLIANCE, true)
		else
			self:learnTalentType("spellweaving/elementalist", true)
		end
		if not game.party:hasMember(self) then return end
		self.descriptor.class_evolution = _t"Grand Elementalist"
	end,
	passives = function(self, t, p)
		self.talents_inc_cap = self.talents_inc_cap or {}
		table.mergeAdd(self.talents_inc_cap, {T_KAM_ELEMENTS_GRAVECHILL = 1, T_KAM_ELEMENTS_GRAVITY = 1, 
			T_KAM_ELEMENTS_FEVER = 1, T_KAM_ELEMENTS_MANASTORM = 1, T_KAM_ELEMENTS_CORRODING_BRILLIANCE = 1,
			T_KAM_ELEMENTALIST_MASTERY = 5})
	end,
	on_unlearn = function(self, t)
	end,
	info = function(self, t)
		return ([[You have studied the elements intensely, learning them more deeply than nearly anyone. Now, as one of the most skilled Elemental Spellweavers, you can call yourself a Grand Elementalist.
		Gain the prodigies Elemental Surge and Endless Woes (this will have no effect on either of these prodigies if you already know them) and unlock the tree Spellweaving/Elementalist or, if it is already known, gain 1 point in each Elementalist talent.
		Additionally, your talent levels for Spellweaving/Elementalist talents can now be increased to 4 (making it possible to get True Elementalist to 20).]])
		:tformat()
	end,
}

uberTalent{
	name = "Spellweaver's Reflection",
	image = "talents/kam_spellweaver_spellweaver_reflection.png",
	require = {
		birth_descriptors={{"subclass", "Spellweaver"}},
		special={desc=_t"Know one of the Spellweaver's locked trees", fct=function(self) -- I think having at least one locked tree by the time you get to 25 is pretty normal.
			return (self:knowTalentType("spellweaving/elementalist") or self:knowTalentType("spellweaving/spellweaving-mastery") or self:knowTalentType("spellweaving/runic-mastery") or self:knowTalentType("spellweaving/advanced-staff-combat") or self:knowTalentType("spellweaving/metaweaving"))
		end},
		stat = {wil=25}, -- Kind of a given since Willpower is the "canonical" Spellweaver stat.
	},
	is_class_evolution = "Spellweaver",
	cant_steal = true,
	is_spell = true,
	mode = "passive",
	on_learn = function(self, t)
		self.descriptor.class_evolution = _t"Beacon of the Spellweavers"
		if not self.talents_add_levels_custom then
			self.talents_add_levels_custom = {}
		end
		self.talents_add_levels_custom.kam_spellweaver_beacon_level_increase = function(self, t, level)
			if t.type[1]:find("^spellweaving/") then
				return level + 1
			end
		end
		self.unused_talents_types = self.unused_talents_types + 1
		if not game.party:hasMember(self) then return end
		if self.faction == "spellweavers" then
			local q = game.player:hasQuest("start-spellweaver")
			if q:isCompleted("return") then
				game.party:learnLore("kam-spellweaver-beacon-get-returned")
				require("engine.ui.Dialog"):simpleLongPopup(_t"The Beacon of the Spellweavers.", _t"As you consider your powers and abilities, you see the Beacon of the Spellweavers appear out of nowhere, with a note attached to it.", 400)
			else
				game.party:learnLore("kam-spellweaver-beacon-get-lost")
				require("engine.ui.Dialog"):simpleLongPopup(_t"The Beacon of the Spellweavers.", _t"As you consider your powers and abilities, you see the Beacon of the Spellweavers appear out of a burst of magic, with a note attached to it.", 400)
			end
		else
			require("engine.ui.Dialog"):simpleLongPopup(_t"A Mysterious Staff???", _t"As you consider your powers and abilities, you suddenly see a staff appear out of nowhere. It looks fairly regular, but it feels extremely magical. It probably wasn't intended for you, but hey, if it's here now, it's yours.", 400)
		end
		local list = mod.class.Object:loadList("/data-kam_spellweaver/general/objects/spellweaver-artifacts-special.lua")
		local o = game.zone:makeEntityByName(game.level, list, "KAM_BEACON_OF_THE_SPELLWEAVERS", true)
		o:identify(true)
		self:addObject(self.INVEN_INVEN, o)
		self:sortInven()
	end,
	callbackOnActBase = function(self, t) 
		self:updateTalentPassives(t) -- I didn't want weird function superloads for this, and this works.
	end,
	passives = function(self, t, p)
		if self:attr("kam_beacon_of_spellweavers_attr") then
			if self.talents_types["spellweaving/elementalist"] then
				local total = 6
				if self.talents_types["spellweaving/spellweaving-mastery"] then
					total = total + 6
				end
				if self.talents_types["spellweaving/runic-mastery"] then
					total = total + 6
				end
				if self.talents_types["spellweaving/advanced-staff-combat"] then
					total = total + 6
				end
				if self.talents_types["spellweaving/metaweaving"] then
					total = total + 6
				end
				self:talentTemporaryValue(p, "resists_pen", {all = total})
			end
		else
			self:talentTemporaryValue(p, "resists_pen", {all = 0})
		end
	end,
	on_unlearn = function(self, t)
		if self.talents_add_levels_custom.kam_spellweaver_beacon_level_increase then
			self.talents_add_levels_custom.kam_spellweaver_beacon_level_increase = nil
		end
	end,
	reduceCooldownOfSpellwoven = function(self, reduction)
		local talentsTable = {}
		for _, talent in pairs(self.talents_def) do
			local tid = talent.id
			if self:knowTalent(tid) and talent.isKamSpellSlot and self.talents_cd[tid] and (self.talents_cd[tid] > 0) then
				talentsTable[#talentsTable+1] = tid
			end
		end
		if (#talentsTable > 0) then
			local tid = rng.table(talentsTable)
			self.talents_cd[tid] = self.talents_cd[tid] - reduction
		end
	end,
	reduceCooldownOfMetaweaving = function(self, reduction)
		local talentsTable = {}
		for _, talent in pairs(self.talents_def) do
			local tid = talent.id
			if talent.type[1] == "spellweaving/metaweaving" and self.talents_cd[tid] and (self.talents_cd[tid] > 0) then
				talentsTable[#talentsTable+1] = tid
			end
		end
		if (#talentsTable > 0) then
			local tid = rng.table(talentsTable)
			self.talents_cd[tid] = self.talents_cd[tid] - reduction
		end
	end,
	getRunicAdaptionScaleBoostChance = function(self, t)
		return 20
	end,
	getSpellweavingMasteryFrontlineBoostChance = function(self, t)
		return 25
	end,
	getRunicFrontlineBoostChance = function(self, t)
		return 50
	end,
	getFrontlineBoostPower = function(self, t)
		return 50
	end,
	getMetaEmpowermentBoostChance = function(self, t)
		return 20
	end,
	getMetaEmpowermentBoost = function(self, t)
		return 25
	end,
	callbackOnMeleeAttack = function(self, t, target, hitted, crit, weapon, damtype)
		if self:attr("kam_beacon_of_spellweavers_attr") then
			if self.talents_types["spellweaving/advanced-staff-combat"] then
				if self.talents_types["spellweaving/spellweaving-mastery"] then
					t.reduceCooldownOfSpellwoven(self, 1)
				end
				if self.talents_types["spellweaving/runic-mastery"] then
					if rng.percent(t.getRunicAdaptionScaleBoostChance(self, t)) then
						self:setEffect(self.EFF_KAM_RUNIC_ADAPTION_SCALE_BOOST, 3, {src=self, power = 2})
					end
				end
				if self.talents_types["spellweaving/metaweaving"] then
					if rng.percent(t.getMetaEmpowermentBoostChance(self, t)) then
						self:setEffect(self.EFF_KAM_META_EMPOWERMENT_BOOST, 3, {src=self, power = t.getMetaEmpowermentBoost(self, t)})
					end
				end
			end
		end
	end,
	callbackOnTalentPost = function(self, t, ab)
		if self:attr("kam_beacon_of_spellweavers_attr") then
			if self.talents_types["spellweaving/runic-mastery"] then
				if ab.type[1] == "inscriptions/runes" or ab.type[1] == "inscriptions/taints" or (ab.type[1] == "inscriptions/infusions" and KamCalc:isAllowInscriptions(self)) then
					if self.talents_types["spellweaving/spellweaving-mastery"] then
						t.reduceCooldownOfSpellwoven(self, 2)
					end
					if self.talents_types["spellweaving/advanced-staff-combat"] then
						if rng.percent(t.getRunicFrontlineBoostChance(self, t)) then
							self:setEffect(self.EFF_KAM_FRONTLINE_COUNTERATTACK_BOOST, 2, {src=self, power = t.getFrontlineBoostPower(self, t)})
						end
					end
					if self.talents_types["spellweaving/metaweaving"] then
						t.reduceCooldownOfMetaweaving(self, 3)
					end
				end
			end
			if self.talents_types["spellweaving/spellweaving-mastery"] then
				if (not self.__kam_asc_casting) and ab.isKamSpellSlot then
					if self.talents_types["spellweaving/advanced-staff-combat"] then
						if rng.percent(t.getSpellweavingMasteryFrontlineBoostChance(self, t)) then
							self:setEffect(self.EFF_KAM_FRONTLINE_COUNTERATTACK_BOOST, 2, {src=self, power = t.getFrontlineBoostPower(self, t)})
						end
					end
					if self.talents_types["spellweaving/runic-mastery"] then
						if rng.percent(t.getRunicAdaptionScaleBoostChance(self, t)) then
							self:setEffect(self.EFF_KAM_RUNIC_ADAPTION_SCALE_BOOST, 3, {src=self, power = 2})
						end
					end
				end
			end
			if self.talents_types["spellweaving/metaweaving"] then
				if ab.type[1] == "spellweaving/metaweaving" then
					if self.talents_types["spellweaving/spellweaving-mastery"] then
						t.reduceCooldownOfSpellwoven(self, 3)
					end
					if self.talents_types["spellweaving/advanced-staff-combat"] then
						self:setEffect(self.EFF_KAM_MELEE_META_BOOST, 5, {src=self, damage = t.getMetaDamage(self, t)})
					end
				end
			end
		end
	end,
	getMetaDamage = function(self, t)
		return 0.5 * KamCalc:coreSpellweaveElementDamageFunction(self, (self.level / 10) * 1.5);
	end,
	info = function(self, t)
		return ([[Your commitment to Spellweaving has impressed all of Wovenhome, and you have been chosen to carry the Beacon of the Spellweavers, the legendary staff passed down since the time of the earliest Spellweavers.
		You to gain a Category Point and your talent level for all known Spellweaving spells is permanently increased by 1. 
		While wielding the Beacon, you gain bonuses for each pair of advanced Spellweaving categories you know:
		- Spellweaving Mastery + Advanced Staff Combat: Reduce the cooldown of a Spellwoven spell by 1 whenever you make a melee attack. Spellwoven spells have a %d%% chance to increase the Frontline Spellweaver counteratack by %d%% for 2 turns.
        
		- Spellweaving Mastery + Runic Mastery: Reduce the cooldown of a Spellwoven spell by 2 whenever you use a Rune. Spellwoven spells have a 20%% chance to double Runic Adaptation for your next rune.
        
		- Spellweaving Mastery + Metaweaving: Reduce the cooldown of a Spellwoven spell by 3 whenever you cast a Metaweaving spell.  When you craft a spell with Power Loom, reduce that spell's current cooldown by 75%%.
        
		- Advanced Staff Combat + Runic Mastery: Runes have a %d%% chance to increase the Frontline Spellweaver counterattack rate by %d%% for 2 turns. Melee attacks have a 20%% chance to double Runic Adaptation for your next rune.
        
		- Metaweaving + Advanced Staff Combat: Melee attacks have a 20%% chance to increase the effect of Meta Empowerment by 25%% until the selected spell is cast, or for 3 turns. Whenever you cast a Metaweaving Spell, add %d piercing elementless damage to your melee attacks for 5 turns.
        
		- Metaweaving + Runic Mastery: Whenever you use a Rune, reduce the cooldown of a random Metaweaving talent by 3. You can now choose Runes as a target for Threadswitch.
 
		- Elementalist: Increase your all resistance penetration by 5%% per advanced Spellweaving category known.

		(Spell procs from the Advanced Staff Combat tree do not count as casting a Spellwoven spell)]])
		:tformat(t.getSpellweavingMasteryFrontlineBoostChance(self, t), t.getFrontlineBoostPower(self, t), t.getRunicFrontlineBoostChance(self, t), t.getFrontlineBoostPower(self, t), self:damDesc(DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE, t.getMetaDamage(self, t)))
	end,
}
