local KamCalc = require "mod.KamHelperFunctions"

newTalentType{ type = "spellweaving/elementalist", no_silence = true, is_spell = true, name = _t("elementalist", "talent type"), description = _t"Weave spells with the elements in unity. Like Armor Training, talents in this category can be taken in any order." }
spells_req_high = {
	stat = { mag=function(level) return 22 + (level-1) * 2 end },
	level = function(level) return 10 + (level-1)  end,
}
-- Special Elementalist Tree rules: Elements have 3 points max, talent scaling is 5/3rds better.  
-- Elementalist tree. Talents:
-- Elementalist: Not actually takeable, just logs number of points you've put in. Provides bonuses at certain levels.

-- Gravechill: Cold + Darkness element. Gives armor and can make skeletons from defeated targets. Armor gain is minor (max 10)
-- Gravity: Physical + Temporal element. Knocks back targets, dealing extra damage on slam (possibly making this the highest damage element). Might need to rebalance knockback.
-- Fever: Blight + Fire. Creates diseases that spread, deal damage, and heal you back for what they drain.
-- Manastorm: Arcane + Lightning. Creates area effects that drain resources.
-- Corroding Brilliance: Acid + Light (... so I'm kind of just throwing together what's left). Adds splashy damage.


newTalent{ -- Core skill. Cannot be taken directly. Bonuses may be altered (beyond the first).
	name = "True Elementalist",
	short_name = "KAM_ELEMENTALIST_MASTERY",
	type = {"spellweaving/elementalist", 1},
	require = { special={desc="Cannot be taken directly.", fct=function(self)
		return false
	end} },
	image = "talents/kam_spellweaver_true_elementalist.png",
--	image = "talents/staff_mastery.png", 
	points = 15,
	mode = "passive",
	no_unlearn_last = true,
	no_energy = true,
	info = function(self, t)
		return ([[You are a master of the elements. You cannot put points in this talent directly, instead one point is gained for each raw level in Elementalist tree talents.
		At different raw talent levels, gain special bonus effects:
		Talent level 5: Gain 10%% all resistance penetration. 
		Talent level 10: Gain 10%% all resistance.
		Talent level 15: Increase your all damage by 15%%.
		Talent level 20 (obtained by taking the Grand Elementalist prodigy): Gain the Elemental Purification element, which deals piercing elementless damage based on your highest element talent, piercing 50%% of the targets all resistance and ignoring both the target's and your elemental resistances and damage increases, and can inflict Elemental Nullification on enemies, causing them to deal 30%% reduced damage and have their damage converted to non-piercing elementless damage.]]):
		tformat()
		--		Talent level 1: Spellwoven attack spells gain a small amount of bonus damage (1%% of normal power per raw talent level) of a random element you have unlocked (but using the average talent level of your highest five element talents), including any status chances associated with that element. This is modified by the Spellweave Multiplier of the shape instead of the normal multiplier.
	end,
	trueElementalistBonusPower = function(self, t)
		return self:getTalentLevelRaw(t) * 0.01
	end,
	passives = function(self, t, p)
		if self:getTalentLevelRaw(t) >= 5 then
			self:talentTemporaryValue(p, "resists_pen", {all = 10})
		end
		if self:getTalentLevelRaw(t) >= 10 then
			self:talentTemporaryValue(p, "resists", {all = 10})
		end
		if self:getTalentLevelRaw(t) >= 15 then
			self:talentTemporaryValue(p, "inc_damage", {all = 15})
		end
	end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 20 then
			if not self:knowTalent(self.T_KAM_ELEMENT_ELEMENTAL_PURIFICATION) then
				self:learnTalent(Talents.T_KAM_ELEMENT_ELEMENTAL_PURIFICATION, true)
			end
		end
	end,
	on_unlearn = function(self, t)
		if self:getTalentLevelRaw(t) < 20 then
			if self:knowTalent(self.T_KAM_ELEMENT_ELEMENTAL_PURIFICATION) then
				self:unlearnTalent(Talents.T_KAM_ELEMENT_ELEMENTAL_PURIFICATION)
			end
		end
	end,
}

newTalent{ -- Gravechill element: Targets have chance to rise as skeletons. Gain armor on cast.
	name = "Gravechill", -- morbid-humor (Note: I don't like how this one turned out, but I'm failing to get anything better so...)
	short_name = "KAM_ELEMENTS_GRAVECHILL",
	image = "talents/kam_spellweaver_gravechill.png",
--	image = "talents/grave_mistake.png",
	type = {"spellweaving/elementalist", 1},
	points = 3,
	mode = "passive",
	no_unlearn_last = true,
	is_necromancy = true, -- If you are in Orcs or whatever, free lich-ing.
	require = spells_req_high,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_GRAVECHILL)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_GRAVECHILL, true)
		end
		self:learnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY, true)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_GRAVECHILL)
		end
		self:unlearnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY)
	end,
	getDamage = function(self, t, level) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, level or t, 3)
	end,
	getSkeletonChance = function(self, t)
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level * 5/3, 50, 10, 20)
	end,
	getArmor = function(self, t) -- This is NOT actually used anywhere else, so if you change this, update the damage type too.
		return t.getSkeletonChance(self, t) / 10
	end,
	getSkeletonDuration = function(self, t)
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return math.floor(KamCalc:combatTalentSpellDamageLevelVariable(self, t, 5, 30, nil, 3))
	end,
	makeSkeleton = function(self, target, t) -- Skeleton may need rebalancing. This talent is kind of wild.
		local x, y = util.findFreeGrid(target.x, target.y, 10, true, {[Map.ACTOR]=true})
		if not x then return nil end
		local str = 15 + self:combatTalentScale(self:getTalentLevel(t) * 5/3, 2, 10, 0.75)
		local dex = 15 + self:combatTalentScale(self:getTalentLevel(t) * 5/3, 2, 10, 0.75)
		local con = 15
		local NPC = require "mod.class.NPC"
		local skeleton = NPC.new{ type = "undead", subtype = "skeleton",
			desc = _t"A skeleton, frigid with the cold of the grave.",
			name = "gravechilled skeleton", color=colors.STEEL_BLUE, image="npc/armored_skeleton_warrior.png",
			blood_color = colors.STEEL_BLUE,
			display = "s", color=colors.STEEL_BLUE,
			combat = { dam=self:getTalentLevel(t) * 5/3 * 7 + rng.avg(12,25), atk=10, apr=10, dammod={str=0.8} },
			faction = self.faction,
			level_range = {1, nil}, exp_worth = 0,
			life_rating = 10,
			max_life = 100,
			combat_armor_hardiness = 40,
			combat_armor=resolvers.levelup(3, 1, 1), combat_def = 7,
			body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1, QUIVER=1 },
			infravision = 10,
			rank = 2,
			size_category = 3,
			autolevel = "warrior",
			silent_levelup = true,
			no_inventory_access = true,
			no_drops = true,
			summoner = self, summoner_gain_exp = true,
			summon_time = t.getSkeletonDuration(self, t),
			ai = "summoned", ai_state = { talent_in=1, ai_move="move_ghoul", },
			ai_real = "tactical",
			ai_tactic = resolvers.tactic"melee",
			stats = { str=str, dex=dex, con=con, damtype=DamageType.KAM_GRAVECHILL_DAMAGE_TYPE },
			resolvers.racial(),
			resolvers.tmasteries{ ["technique/other"]=0.3, ["technique/2hweapon-offense"]=0.3, ["technique/2hweapon-cripple"]=0.3 },
			open_door = true,
			cut_immune = 1,
			blind_immune = 1,
			fear_immune = 1,
			poison_immune = 1,
			see_invisible = 2,
			undead = 1,
			rarity = 1,
			not_power_source = {nature=true},
			
			resolvers.inscriptions(1, {"blink rune"}),
			resolvers.equip{ 
				{type="weapon", subtype="longsword", forbid_power_source={antimagic=true}, autoreq=true}, 
				{type="armor", subtype="shield", forbid_power_source={antimagic=true}, autoreq=true}, 
				{type="armor", subtype="heavy", forbid_power_source={antimagic=true}, autoreq=true} 
			},
			resolvers.talents{
				T_WEAPON_COMBAT={base=1, every=7, max=10},
				T_WEAPONS_MASTERY={base=1, every=7, max=10},
				T_ARMOUR_TRAINING={base=2, every=14, max=4},
				T_OVERPOWER={base=1, every=7, max=5},
				T_SHIELD_PUMMEL={base=1, every=7, max=5},
			},
			ai_state = { talent_in=1, },
			ai_target = {actor=target},
		}
		skeleton:resolve() 
		skeleton:resolve(nil, true)
		skeleton:forceLevelup(self.level)
		skeleton.unused_talents = 0
		skeleton.unused_generics = 0
		skeleton.unused_talents_types = 0

		game.zone:addEntity(game.level, skeleton, "actor", x, y)
		game.level.map:particleEmitter(target.x, target.y, 1, "slime")
		game:playSoundNear(target, "talents/slime")
		skeleton:logCombat(target, "A #GREY##Source##LAST# rises from the corpse of #Target#.")

		if game.party:hasMember(self) then
			skeleton.remove_from_party_on_death = true
			game.party:addMember(skeleton, {
				control="no",
				type="minion",
				title=_t"Gravechilled Skeleton",
				orders = {target=true},
			})
		end
	end,
	info = function(self, t)
		return ([[Although few Spellweavers dabble in the necromantic arts, nothing actually stops one from doing so, and most Spellweavers don't even find it particularly unethical. Cold and Darkness are already far nearer to the grave than most magics, after all.
		Gain the Frostdusk element, which deals %d damage, divided equally among Cold and Darkness and multiplied by Spellweave Multiplier. This damage also spreads the chill of the grave, stackingly granting you %d Armor per target hit for 5 turns (stacking up to 10 Armor) and inflicting targets with Gravechill for 10 turns. Gravechilled targets have a %d%% chance to rise from the dead as a skeleton when they die. Skeletons last for %d turns and their various stats scale with your Talent Level. Armor gain and skeleton chance on death are modified by Spellweave Multiplier.
		Damage and Skeleton duration increase with Spellpower.]]):
		tformat(t.getDamage(self, t), t.getArmor(self, t), t.getSkeletonChance(self, t), t.getSkeletonDuration(self, t))
	end, 
}

newTalent{ -- Gravity: Push enemies away from you, dealing extra damage on slams.
	name = "Gravitic", -- expand + contract
	short_name = "KAM_ELEMENTS_GRAVITY",
	image = "talents/kam_spellweaver_gravity.png",
--	image = "talents/gravity_locus.png",
	type = {"spellweaving/elementalist", 1},
	levelup_screen_break_line = true,
	points = 3,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req_high,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_GRAVITY)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_GRAVITY, true)
		end
		if not (self:knowTalent(self.T_KAM_ELEMENT_GRAVITY_PULL)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_GRAVITY_PULL, true)
		end
		self:learnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY, true)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_GRAVITY)
		end
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_GRAVITY_PULL)
		end
		self:unlearnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY)
	end,
	getDamage = function(self, t, level)
		return KamCalc:coreSpellweaveElementDamageFunction(self, level or t, 3)
	end,
	getDamagePulling = function(self, t, level)
		return KamCalc:coreSpellweaveElementDamageFunction(self, level or t) * 1.1 
	end,
	getPushDist = function(self, t) -- Always pushes unless resisted.
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level * 5/3, 10, 2, 4.5)
	end,
	getGraviticExhaustion = function(self, t)
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level * 5/3, 100, 10, 50)
	end,
	getGraviticExhaustionDuration = function(self, t)
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return self:combatTalentScale(level * 5/3, 3, 7)
	end,
	getSlamDamage = function(self, t) return KamCalc:coreSpellweaveElementDamageFunction(self, self:getTalentLevel(t) * 5/3) * 0.2 end,
	info = function(self, t)
		return ([[Although gravity is a force constantly affecting all of us, most don't realize its sheer power. However, the perfect combination of physical and temporal magics can result in some incredible force.
		Gain the Gravitic element, which deals %d damage, divided equally among Physical and Temporal and multiplied by Spellweave Multiplier. This damage also pushes targets %d tiles away from the center of the spell (or you if the spell uses lingering damage or is a beam or otherwise is moving away from you) and inflicts Gravitic Exhaustion for %d turns, reducing the target's knockback resistance by %d%%. If a target is slammed into a wall by Gravitic damage, they take an additional 20%% of base damage as Gravitic damage. Knockback distance and gravitic exhaustion power are modified by Spellweave Multiplier (but knockback distance is minimum 1).
		Additionally, gain the Gravitic (Pull) element, which deals an increased %d Gravitic damage, multiplied by Spellweave Multiplier, pulls targets %d tiles, and inflicts the same Gravitic Exhaustion effect, but does not deal additional slam damage.
		Targets can only be pushed and/or pulled by Gravity damages one per turn.
		Element damage increases with Spellpower.]]):
		tformat(t.getDamage(self, t), t.getPushDist(self, t), t.getGraviticExhaustionDuration(self, t), t.getGraviticExhaustion(self, t), t.getDamagePulling(self, t), t.getPushDist(self, t))
	end, 
}

newTalent{ -- Fever: Create diseases that reduce the opposite set from normal blight (Willpower, Dexterity, Magic) and drain life.
	name = "Plaguefire", -- back-pain
	short_name = "KAM_ELEMENTS_FEVER",
	image = "talents/kam_spellweaver_fever.png",
--	image = "talents/energy_absorption.png",
	type = {"spellweaving/elementalist", 1},
	points = 3,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req_high,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_FEVER)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_FEVER, true)
		end
		self:learnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY, true)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_FEVER)
		end
		self:unlearnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY)
	end,
	getDamage = function(self, t, level) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, level or t, 3)
	end,
	getFeverPower = function(self, t) -- Improved because its not THAT good of draining.
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return KamCalc:combatTalentSpellDamageLevelVariable(self, level, 5, 22, nil, 3)
	end,
	getFeverDamage = function(self, t)
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return t.getDamage(self, t) * self:combatTalentLimit(level * 5/3, 1, 0.05, 0.20)
	end,
	getFeverDuration = function(self, t) -- For ease of adjustment (and because I already had it set up when I realized it didn't work well with the damage.
		return 5
	end,
	info = function(self, t)
		return ([[It turns out that combining a little heat with your blight can produce unexpected and powerful combinations that sap your foes abilities while increasing yours.
		Gain the Plaguefire element, which deals %d damage, divided equally among Blight and Fire and multiplied by Spellweave Multiplier. Fever also afflicts targets with a draining fever, reducing their magic, willpower, or cunning by %d for %d turns. These diseases stack, and diseases that are not currently in use will be prioritized. Additionally, diseased targets will take %d draining Plaguefire damage over the fever's duration, healing you for amount of damage dealt. Draining damage and stat reduction are multiplied by Spellweave Multiplier.
		Fevers created by this effect are treated as diseases for the effect of the Acidic Pestilence sustain in the Ruin tree.
		Element damage and Fever damage and stat reduction increase with Spellpower.]]):
		tformat(t.getDamage(self, t), t.getFeverPower(self, t), t.getFeverDuration(self, t), t.getFeverDamage(self, t))
	end, 
}

newTalent{ -- Manastorm: Create manastorms that drain target's resources.
	name = "Manastorm", -- lightning-storm
	short_name = "KAM_ELEMENTS_MANASTORM",
	image = "talents/kam_spellweaver_manastorm.png",
--	image = "talents/anomaly_invigorate.png",
	type = {"spellweaving/elementalist", 1},
	points = 3,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req_high,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_MANASTORM)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_MANASTORM, true)
		end
		self:learnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY, true)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_MANASTORM)
		end
		self:unlearnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY)
	end,
	getDamage = function(self, t, level) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, level or t, 3)
	end,
	getChance = function(self, t, level)
		if not level then
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level, 60, 8, 40) -- Again, fancy draining power.
	end,
	getResourceDrain = function(self, t) -- ... I have NO idea how to balance this. Very contextual but also potentially very strong.
		return math.floor(self:combatTalentSpellDamage(t, 10, 35))
	end,
	getRadius = function(self, t) -- Radius of manastorms, for ease of adjustment.
		return 3
	end,
	getDuration = function(self, t) -- For ease of adjustment.
		return 4
	end,
	getChanceMod = function(self, t) -- Multiply manastorm chance by this amount.
		local manastorms = t.doUpdateCount(self, t)
		return math.max(0, 1 - manastorms * 0.15)
	end,
	doUpdateCount = function(self, t) -- Update manastorms count
		local count = 0
		for _, e in pairs(game.level.entities) do
			if e.rank and e.subtype and e.hasEffect and e:hasEffect(e.EFF_KAM_MANASTORM_EFFECT) then
				count = count + 1
			end
		end
		return count
	end,
	info = function(self, t) -- I was hoping to avoid giving any Elementalist tree chance effects, but this one needs it to balance the applying it to many things slowdowns...
		local extraText = [[]]
		if game:isAddonActive("orcs") and game:isAddonActive("cults") then
			extraText = (([[Steam, Insanity, and ]]):tformat())
		elseif game:isAddonActive("orcs") then
			extraText = (([[Steam and ]]):tformat())
		elseif game:isAddonActive("cults") then
			extraText = (([[Insanity and ]]):tformat())
		end
		return ([[Although Arcane and Lightning magic is a somewhat unconventional combo, it turns out that storms of mana can have some truly fascinating effects regarding the manipulation of energies.
		Gain the Manastorm element, which deals %d damage, divided equally among Arcane and Lightning and multiplied by Spellweave Multiplier. Manastorm damage also has a %d%% chance to surround targets with an intense storm of mana, draining %d resources from the target (scaling based on resources, listed below) and every enemy around them in radius %d for %d turns, and restoring mana based on the highest of the resources drained (see the scaling below). The chance of inflicting manastorms reduces by 15%% for each manastorm present on the level.
		Resource scaling: 
		Mana: Draining 100%% of the value, restoring 100%% of amount drained.
		Vim and Stamina: Draining 50%% of the value, restoring 200%% of the amount drained.
		Psi, Positive and Negative Energies: Draining 25%% of the value, restoring 400%% of the amount drained.
		%sHate: Draining 10%% of the value, restoring 1000%% of the amount drained.
		Element damage and resource drain increase with Spellpower.]]):
		tformat(t.getDamage(self, t), t.getChance(self, t) * t.getChanceMod(self, t), t.getResourceDrain(self, t), t.getRadius(self, t), t.getDuration(self, t), extraText)
	end, 
}

newTalent{ -- Corroding Brilliance: For Melee Spellweavers. Makes attacks drain and makes them repeat.
	name = "Corroding Brilliance", -- wrapping-star
	short_name = "KAM_ELEMENTS_CORRODING_BRILLIANCE",
	image = "talents/kam_spellweaver_corrosive_brilliance.png",
--	image = "talents/charge_leech.png",
	type = {"spellweaving/elementalist", 1},
	points = 3,
	mode = "passive",
	no_unlearn_last = true,
	require = spells_req_high,
	on_learn = function(self, t)
		if not (self:knowTalent(self.T_KAM_ELEMENT_CORRODING_BRILLIANCE)) then
			self:learnTalent(Talents.T_KAM_ELEMENT_CORRODING_BRILLIANCE, true)
		end
		self:learnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY, true)
	end,
	on_unlearn = function(self, t)
		if not self:knowTalent(t) then 
			self:unlearnTalent(Talents.T_KAM_ELEMENT_CORRODING_BRILLIANCE)
		end
		self:unlearnTalent(Talents.T_KAM_ELEMENTALIST_MASTERY)
	end,
	getDamage = function(self, t, level) 
		return KamCalc:coreSpellweaveElementDamageFunction(self, level or t, 3)
	end,
	getDuration = function(self, t)
		return 5
	end,
	getRepeatChance = function(self, t) -- Repetion chance.
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level * 5/3, 75, 8, 35) -- Nerfed slightly (was 75, 8, 35)
	end,
	getDrain = function(self, t)
		local level
		if game.state.kam_spellweaver_random_element_level then
			level = game.state.kam_spellweaver_random_element_level
		else
			level = self:getTalentLevel(t)
		end
		return self:combatTalentLimit(level * 5/3, 30, 2, 15) -- Again, fancy draining power. Massively nerfed from (100, 8, 50).
	end,
	info = function(self, t)
		return ([[Acidic and Light magic are a very rare combo to see used by Spellweavers, but some melee-focused Spellweavers who studied at the Gates of Morning developed techniques with it to enhance their melee abilities.
		Gain the Corroding Brilliance element, which deals %d damage, divided equally among Acid and Light and multiplied by Spellweave Multiplier. Corroding Brilliance damage also inflicts targets with a Radiamark for %d turns, causing your melee attacks made against them to heal you for %d%% of the damage dealt and have a %d%% chance to instantly make a bonus attack (each target can only have one bonus attack made against them per turn), and preventing them from gaining evasion benefits for being unseen. Melee attack repetition chance and life restoring is modified by Spellweave Multiplier.
		Element damage increases with Spellpower.]]):
		tformat(t.getDamage(self, t), t.getDuration(self, t), t.getDrain(self, t), t.getRepeatChance(self, t))
	end, 
}