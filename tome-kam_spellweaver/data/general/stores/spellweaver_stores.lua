-- Enchanted gear from Dymion. Sells just about anything. 

newEntity{
	define_as = "KAM_WOVENHOME_STORE",
	name = "Spellwoven Gear",
	display = '3', color = colors.UMBER,
	store = {
		purse = 25,
		empty_before_restock = false,
		nb_fill = 8, -- Can sell literally anything and always has egos, however also very unreliable because of that.
		player_material_level = true,
		filters = {
			{type="weapon", id=true, ego_chance=100},
			{type="jewelry", id=true, ego_chance=100},
			{type="charm", id=true, ego_chance=100},
			{type="lite", id=true, ego_chance=100},
			{type="tool", id=true, ego_chance=100},
			{type="ammo", id=true, ego_chance=100},
			{type="armor", id=true, ego_chance=100},
			{type="scroll", subtype="rune", id=true, ego_chance = 100},
			{type="scroll", subtype="infusion", id=true, ego_chance = 100},
		},
		post_filter = function(e)
			if e.power_source and e.power_source.antimagic then return false end -- No antimagic.
			if e.unique and not e.randart then return false end -- No fixed arts (Dymion couldn't be making items that already exist).
			return true
		end,
	},
}

-- Lore from Professor Ifnai. Sells lore exclusively

newEntity{
	define_as = "KAM_WOVENHOME_IFNAI_LORE",
	name = "Transcribed Lectures",
	display = '3', color = colors.UMBER,
	store = {
		purse = 25,
		empty_before_restock = false,
		fixed = {
			{id=true, defined="KAM_SPELLWEAVER_HISTORY_LECTURE"},
			{id=true, defined="KAM_SPELLWEAVER_TECHNIQUE_LECTURE"},
			{id=true, defined="KAM_SPELLWEAVER_CALENDAR_LECTURE"},
			{id=true, defined="KAM_SPELLWEAVER_ORCS_LECTURE"},
		},
	},
}