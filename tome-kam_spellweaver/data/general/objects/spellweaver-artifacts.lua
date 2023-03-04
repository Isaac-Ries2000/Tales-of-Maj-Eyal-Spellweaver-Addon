
local Stats = require "engine.interface.ActorStats"
local Talents = require "engine.interface.ActorTalents"

-- Teaching Loom: Increases Spellweave power for shields and teleports (7.5%) and can be used to make a random shield.
newEntity{ base = "BASE_TOOL_MISC",
	power_source = {arcane = true},
	unique=true,
	name = "Spellweaver's Teaching Loom",
	unided_name = _t"weathered frame loom",
	image = "object/shortbow_ash.png", -- ... I know, but it's all I have for this.
	special_desc = function(self) return _t"Your Spellweave multiplier for casting Spellwoven shields and teleportation spells is increased by 7.5%." end,
	desc = _t[[Weaving is a common method used to teach novice Spellweavers the art of weaving the threads of magic.
This tiny, weathered, handheld frame loom must have been used for teaching so many times that it absorbed a portion of Spellweaver magic.]],
	level_range = {7, 17},
	rarity = 210,
	cost = 70,
	material_level = 2,
	wielder = {
		inc_stats = { [Stats.STAT_WIL] = 3, [Stats.STAT_MAG] = 3 },
		talents_types_mastery = {
			["spellweaving/warpweaving"] = 0.2,
			["spellweaving/shieldweaving"] = 0.2,
		},
		kam_spellweaver_teaching_loom_bonus = 0.075
	},
	max_power = 40, power_regen = 1,
	use_talent = { id = Talents.T_KAM_SPELLWEAVER_TEACHING_LOOM_SKILL, level = 1, power = 35 },
}

-- Gloves of the Woven Elementalist. Gains power based on the elements you AREN'T using while weakening the ones you ARE. Kind of awful (but pretty cool hopefully?)
-- Note: Consider making the effect last for a bit once you take them off to prevent shenanigans.
newEntity{ base = "BASE_GLOVES",
	power_source = {arcane = true},
	unique=true,
	name = "Gloves of the Woven Elementalist",
	define_as = "KAM_SPELLWEAVER_ELEMENTALIST_GLOVES",
	unided_name = _t"elemental gloves",
	image = "object/artifact/gauntlets_crystalline.png", -- ... Sigh.
--	moddable_tile = "", 
	special_desc = function(self) return _t[[When you deal damage, adjust the glove's elemental balance away from that element (based on the amount of damage dealt). Out of combat, these changes will slowly return to normal.
Gloves melee damage is divided into the 10 Spellweaving elements, weighted based on your current elemental damage modifiers.]] end,
desc = _t[[Each finger on the gloves shines with a different element, making up all ten of the common Spellwoven elements.
Earth and light,
Flame and blight,
Empower us with your great might.
Lighting, time
Frigid rime,
Strength of elements sublime.]],
	color = colors.RED, 
	cost = 750,
	material_level = 5,
	rarity = 300,
	wielder = {
		combat_armor = 8,
		combat_def = 8,
		lite = 2,
		inc_stats = { [Stats.STAT_CUN] = 6, [Stats.STAT_WIL] = 6, [Stats.STAT_MAG] = 6 },
		talents_types_mastery = { -- Have some more masteries!
			["spellweaving/elementalist"] = 0.2,
			["spellweaving/eclipse"] = 0.1,
			["spellweaving/molten"] = 0.1,
			["spellweaving/wind-and-rain"] = 0.1,
			["spellweaving/otherworldly"] = 0.1,
			["spellweaving/ruin"] = 0.1,
		},
		kam_spellweaver_elemental_gloves_bonus = 1,
		combat = {
			dam = 35,
			apr = 10,
			physcrit = 10,
			physspeed = 0.2,
			dammod = {dex=0.4, mag=0.4, str=0.3, cun=0.2 },
			talent_on_hit = { T_KAM_SPELLWEAVER_NULLIFICATION_SLAM = {level=1, chance=10} },
			convert_damage = {[DamageType.KAM_ELEMENTALISTS_GLOVES_DAMAGE_TYPE] = 100},
		},
	},
	callbackOnAct = function(o, self)
		local DamageType = require "engine.DamageType" -- To prevent upvalue issues
		local damageIncTable = {
			[DamageType.ACID] = 4,
			[DamageType.ARCANE] = 4,
			[DamageType.BLIGHT] = 4,
			[DamageType.COLD] = 4,
			[DamageType.DARKNESS] = 4,
			[DamageType.FIRE] = 4,
			[DamageType.LIGHT] = 4,
			[DamageType.LIGHTNING] = 4,
			[DamageType.PHYSICAL] = 4,
			[DamageType.TEMPORAL] = 4,
		}
		if not self:hasEffect(self.EFF_KAM_ELEMENTALIST_GLOVES_EFFECT) then
			self:setEffect(self.EFF_KAM_ELEMENTALIST_GLOVES_EFFECT, 1, {damageIncTable = damageIncTable})
		end
	end,
	max_power = 50, power_regen = 1,
	use_talent = { id = Talents.T_KAM_SPELLWEAVER_NULLIFICATION_SLAM, level = 1, power = 30 },
}
