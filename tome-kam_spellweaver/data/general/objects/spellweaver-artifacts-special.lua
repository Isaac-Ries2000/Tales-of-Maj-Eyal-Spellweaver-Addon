local Stats = require "engine.interface.ActorStats"
local Talents = require("engine.interface.ActorTalents")

load("/data/general/objects/objects-far-east.lua")

-- The artifact representing fancy Spellweaving.
newEntity{ base = "BASE_STAFF", define_as = "KAM_BEACON_OF_THE_SPELLWEAVERS",
	power_source = {arcane=true, technique=true},
	image = "object/artifact/kam_staff_beacon_of_the_spellweavers.png",
	moddable_tile = "special/kam_spellweaver/%s_kam_staff_beacon_of_the_spellweavers",
	unided_name = _t"walking stick",
	color = colors.VIOLET,
	unique = true,
	rarity = false,
	plot = true,
	material_level = 5,
	name = "The Beacon of the Spellweavers", unique=true,
	desc = _t[[This staff has been passed down through generations of Spellweavers. Seemingly a plain walking stick, it bears centuries of Spellwoven enchantments. Now you hold it, helping to define the future for Spellweavers.]],
	special_desc = function(self) return _t"You gain a variety of special effects based on which locked trees you know (see the Spellweaver's Reflection talent). Additionally, Spellwoven spells gain a small amount of bonus damage (20% of normal power) of a random element you have unlocked, including any status chances associated with that element." end,
	-- require = { }, -- No requirements needed, beyond having the prodigy.	
	combat = {
		dam = 70,
		apr = 15,
		dammod = {mag=1.5},
		damtype = DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE, -- This is kind of becoming the signature "fancy" element so.
		element = DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE,
		melee_element = true,
	},
	wielder = {
		inc_stats = { [Stats.STAT_WIL] = 5, [Stats.STAT_MAG] = 5 },
		max_mana = 200, -- Even more mana for your sustains.
		combat_spellpower = 30, -- Mirroring Telos Spire
		combat_spellcrit = 30,
		combat_critical_power = 30,
		combat_mentalresist = 20,
		combat_spellresist = 20,
		damage_resonance = 50, -- It's very fitting for Spellweavers to have an adaptive power effect.
		confusion_immune = 1, -- The biggest perk of this staff: All your best immunities at once.
		silence_immune = 1, 
		stun_immune = 1,
		combat_critical_power = 30, -- Thank Moasseman.
		spell_cooldown_reduction = 0.1, -- Nonstandard and powerful bonus.
		inc_damage={all = 37}, -- You should be getting this anyways sooo.
		kam_commanding_staff_attr = 0.2, -- Honestly, I didn't even plan this, but it makes a nice circularness to it all.
		kam_beacon_of_spellweavers_attr = 1, -- The Special Thing.
		combat_atk = 15,
		learn_talent = {[Talents.T_COMMAND_STAFF] = 1},
	},
	on_drop = function(self, who)
		if who == game.player then
			game.logPlayer(who, "You can't leave the %s on the ground!", self:getName())
			return true
		end
	end,
	flavors = {
		magestaff = true,
		vilestaff = true,
		starstaff = true,
		spellweaver = {DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE, DamageType.MIND, DamageType.NATURE, DamageType.KAM_ELEMENTALISTS_GLOVES_DAMAGE_TYPE},
		
	},
	command_staff = {
		inc_damage = false, -- Just changes damage types
	}
}