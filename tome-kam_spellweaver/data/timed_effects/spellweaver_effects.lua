local ActorTalents = require "engine.interface.ActorTalents"
local Stats = require "engine.interface.ActorStats"
local Particles = require "engine.Particles"
local KamCalc = require "mod.KamHelperFunctions"
require "engine.class"

newEffect{
	name = "KAM_SPELLWEAVE_DOT_EFFECT", 
	image = "talents/flame.png", -- It should be exceptionally rare to actually see this since it normally only targets hostile things.
	desc = _t"Harming Weave",	
	long_desc = function(self, eff)
		if not (eff.talent.isKamDoubleShape) or (eff.talent.isKamSpellSplitOne) then
			if (eff.element11) then
				return ([[Take %d %s and %d %s damage every turn. %s %s.]]):format(eff.dam11, (DamageType:get(eff.element11)).name:capitalize(), eff.dam12, (DamageType:get(eff.element12)), eff.talent.getSpellStatusInflict11(eff.src, eff.talent, eff.statusChance11, false, true), eff.talent.getSpellStatusInflict12(eff.src, eff.talent, eff.statusChance12, true))
			else
				return ([[Take %d %s damage every turn. %s.]]):format(eff.dam, (DamageType:get(eff.element)).name:capitalize(), eff.talent.getSpellStatusInflict1(eff.src, eff.talent, eff.statusChance, false, true))
			end
		else
			if (eff.element11) then
				return ([[Take %d %s and %d %s damage every turn. %s %s.]]):format(eff.dam11, (DamageType:get(eff.element11)).name:capitalize(), eff.dam12, (DamageType:get(eff.element12)), eff.talent.getSpellStatusInflict21(eff.src, eff.talent, eff.statusChance11, false, true), eff.talent.getSpellStatusInflict22(eff.src, eff.talent, eff.statusChance12, true))
			else
				return ([[Take %d %s damage every turn. %s.]]):format(eff.dam, (DamageType:get(eff.element)).name:capitalize(), eff.talent.getSpellStatusInflict2(eff.src, eff.talent, eff.statusChance, false, true))
			end		
		end
	end,
	type = "magical",
	subtype = { },
	status = "detrimental",
	parameters = { src = src, dam = 0, element = nil, status = nil, statusChance = 0, talent = nil},
	on_gain = function(self, err) return _t"#Target# is being hurt by the Spellweave!", _t"+Harming Weave" end,
	on_lose = function(self, err) return _t"The harming Spellweave on #Target# has ended.", _t"-Harming Weave" end,
	on_timeout = function(self, eff)
		if (eff.element11) then
			DamageType:get(eff.element11).projector(eff.src, self.x, self.y, eff.element11, eff.dam11 * 0.5)
			DamageType:get(eff.status11).projector(eff.src, self.x, self.y, eff.status11, eff.statusChance11 * 0.5)
			
			DamageType:get(eff.element12).projector(eff.src, self.x, self.y, eff.element12, eff.dam12 * 0.5)
			DamageType:get(eff.status12).projector(eff.src, self.x, self.y, eff.status12, eff.statusChance12 * 0.5)
		else
			DamageType:get(eff.element).projector(eff.src, self.x, self.y, eff.element, eff.dam)
			DamageType:get(eff.status).projector(eff.src, self.x, self.y, eff.status, eff.statusChance)		
		end
	end,
}

-- For eleshield and resistance breaking text.
local makeElementsList = function(self, prismatic, elements)
	if prismatic then 
		return "all"
	end
	local buildString = (DamageType:get(elements[1])).name:capitalize()
	for i = 2, table.getn(elements) do
		buildString = buildString.." and "..(DamageType:get(elements[i])).name:capitalize()
	end
	return buildString
end

newEffect{
	name = "KAM_SPELLWEAVE_ELESHIELD_EFFECT", 
	image = "talents/elemental_harmony.png", 
	desc = _t"Elemental Shielding",	
	long_desc = function(self, eff)
		local resistance = 0
		if eff.isPrismatic then 
			resistance = 15
		else 
			local count = table.getn(eff.elements)
			if count == 1 then 
				resistance = 30
			elseif count == 2 then 
				resistance = 25
			else 
				resistance = 20
			end
		end
		local eleList = makeElementsList(self, eff.isPrismatic, eff.elements)
		return ([[Gain a %d%% resistance to %s damage.]]):tformat(resistance, eleList)
	end,
	type = "magical",
	subtype = { },
	status = "beneficial", -- If isPrismatic is true, elements will be nil, otherwise elements will be the elements to resist.
	parameters = { src = src, elements = nil, isPrismatic = false },
	on_gain = function(self, err) return _t"#Target# gains elemental shielding!", _t"+Elemental Shielding" end,
	on_lose = function(self, err) return _t"#Target#'s elemental shielding has faded.", _t"-Elemental Shielding" end,
	getResistance = function(self, eff)
		if eff.isPrismatic then 
			return 15
		else 
			local count = table.getn(eff.elements)
			if count == 1 then 
				return 30
			elseif count == 2 then 
				return 25
			else 
				return 20
			end
		end
	end,
	activate = function(self, eff, ed)
		eff.resistances = {}
		if (eff.isPrismatic) then 
			self:effectTemporaryValue(eff, "resists", {all = 10})
		else 
			local resistanceAmount = ed.getResistance(self, eff)
			for i = 1, table.getn(eff.elements) do 
				self:effectTemporaryValue(eff, "resists", {[eff.elements[i]] = resistanceAmount})
			end
		end
	end,
}

newEffect{
	name = "KAM_SPELLWEAVE_RESISTANCE_REDUCE_EFFECT", 
	image = "talents/flame.png",
	desc = _t"Elemental Breaking",	
	long_desc = function(self, eff, ed)
		local resistance = 0
		if eff.isPrismatic then 
			resistance = 15
		else 
			local count = table.getn(eff.elements)
			if count == 1 then 
				resistance = 30
			elseif count == 2 then 
				resistance = 25
			else 
				resistance = 20
			end
		end
		local eleList = makeElementsList(self, eff.isPrismatic, eff.elements)
		return ([[Resistance to %s damage is reduced by %d%%.]]):tformat(eleList, resistance)
	end,
	type = "magical",
	subtype = { },
	status = "detrimental",
	parameters = { src = src, elements = {}, isPrismatic = false, resistances = {} },
	on_gain = function(self, err) return _t"#Target#'s resistances falter!", _t"+Elemental Breaking" end,
	on_lose = function(self, err) return _t"#Target#'s resistances have recovered.", _t"-Elemental Breaking" end,
	getResistance = function(self, eff)
		if eff.isPrismatic then 
			return 15
		else 
			local count = table.getn(eff.elements)
			if count == 1 then 
				return 30
			elseif count == 2 then 
				return 25
			else 
				return 20
			end
		end
	end,
	activate = function(self, eff, ed)
		eff.resistances = {}
		if (eff.isPrismatic) then 
			self:effectTemporaryValue(eff, "resists", {all = -15})
		else 
			local resistanceAmount = ed.getResistance(self, eff)
			for i = 1, table.getn(eff.elements) do 
				self:effectTemporaryValue(eff, "resists", {[eff.elements[i]] = -1*resistanceAmount})
			end
		end
	end,
}

newEffect{
	name = "KAM_PHYSICAL_WOUNDS", 
	image = "talents/brutality.png",
	desc = _t"Earthen Wounds",	
	long_desc = function(self, eff)
		return ([[Because of deep wounds from earthen magic, all healing recieved is reduced by %d%%.]]):tformat(eff.healingReduction)
	end,
	type = "magical",
	subtype = {}, 
	parameters = { healingReduction = 0 },
	on_gain = function(self, err) return _t"#Target# has been wounded by Spellwoven earth!", _t"+Wounded" end,
	on_lose = function(self, err) return _t"#Target#'s wounds have recovered.", _t"-Wounded" end,
	status = "detrimental",
	activate = function(self, eff)
		eff.healid = self:addTemporaryValue("healing_factor", eff.healingReduction / 100)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("healing_factor", eff.healid)
	end,
}

newEffect{ -- Largely this is normal burning but it's magical instead of physical.
	name = "KAM_FIRE_BURNING", 
	image = "talents/flame.png",
	desc = _t"Burning Flames",
	long_desc = function(self, eff) return ("The target is burning with Spellwoven flames, taking %0.2f Fire damage per turn."):tformat(eff.power) end,
	charges = function(self, eff) return (math.floor(eff.power)) end,
	type = "magical",
	subtype = { fire=true },
	status = "detrimental",
	parameters = { power=0 },
	on_gain = function(self, err) return _t"#Target# is on fire!", _t"+Burn" end,
	on_lose = function(self, err) return _t"#Target# stops burning.", _t"-Burn" end,
	on_merge = function(self, old_eff, new_eff)
		-- Merges like normal burning
		local olddam = old_eff.power * old_eff.dur
		local newdam = new_eff.power * new_eff.dur
		local dur = math.ceil((old_eff.dur + new_eff.dur) / 2)
		old_eff.dur = dur
		old_eff.power = (olddam + newdam) / dur
		return old_eff
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.FIRE).projector(eff.src, self.x, self.y, DamageType.FIRE, eff.power)
	end,
}

newEffect{
	name = "KAM_SPELLWEAVE_CHANGEUP",
	image = "talents/flurry_of_fists.png", 
	desc = _t"Changeup",
	long_desc = function(self, eff)
		local talentString = " "
		if #(eff.talentNames) > 1 then
			talentString = "s "
		end
		talentString = talentString..eff.talentNames[1]
		if #(eff.talentNames) > 1 then
			for i = 2, #(eff.talentNames) - 1 do
				talentString = talentString..", "..eff.talentNames[i]
			end
			if #(eff.talentNames) > 2 then
				talentString = talentString..", and "..eff.talentNames[#(eff.talentNames)]
			else 
				talentString = talentString.." and "..eff.talentNames[#(eff.talentNames)]
			end
		end
		return ([[By changing up tactics, you've made the perfect opportunity to strike. Spellweave Multiplier for spells not including the same spellweave components as the talent%s is multiplied by 1.4.]]):
		tformat(talentString)
	end,
	type = "magical",
	subtype = { },
	status = "beneficial",
	parameters = { src = src, talentNames = {""}, changeupStorage = {} },
}

newEffect{ -- Variant of weakness disease
	name = "KAM_EXHAUSTING_DISEASE", image = "talents/weakness_disease.png",
	desc = _t"Exhausting Disease",
	long_desc = function(self, eff) return ("The target is infected by a disease, reducing its strength by %d."):tformat(eff.str) end,
	type = "magical",
	subtype = {disease=true, blight=true},
	status = "detrimental",
	parameters = {str = 1, dam = 0},
	on_gain = function(self, err) return _t"#Target# is afflicted by an exhausting disease!" end,
	on_lose = function(self, err) return _t"#Target# is free from the exhausting disease." end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_disease_count", 1)
		eff.tmpid2 = self:addTemporaryValue("inc_stats", {[Stats.STAT_STR] = -eff.str})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_disease_count", eff.tmpid1)
		self:removeTemporaryValue("inc_stats", eff.tmpid2)
		eff.tmpid1 = nil
		eff.tmpid2 = nil
	end,
}

newEffect{ -- Variant of rotting disease
	name = "KAM_ENERVATING_DISEASE", image = "talents/rotting_disease.png",
	desc = _t"Enervating Disease",
	long_desc = function(self, eff) return ("The target is infected by a disease, reducing its constitution by %d."):tformat(eff.con) end,
	type = "magical",
	subtype = {disease=true, blight=true},
	status = "detrimental",
	parameters = {con = 1, dam = 0},
	on_gain = function(self, err) return _t"#Target# is afflicted by an enervating disease!" end,
	on_lose = function(self, err) return _t"#Target# is free from the enervating disease." end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_disease_count", 1)
		eff.tmpid2 = self:addTemporaryValue("inc_stats", {[Stats.STAT_CON] = -eff.con})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_disease_count", eff.tmpid1)
		self:removeTemporaryValue("inc_stats", eff.tmpid2)
		eff.tmpid1 = nil
		eff.tmpid2 = nil
	end,
}

newEffect{ -- Variant of decrepitude disease
	name = "KAM_WEARYING_DISEASE", image = "talents/decrepitude_disease.png",
	desc = _t"Wearying Disease",
	long_desc = function(self, eff) return ("The target is infected by a disease, reducing its dexterity by %d."):tformat(eff.dex) end,
	type = "magical",
	subtype = {disease=true, blight=true},
	status = "detrimental",
	parameters = {dex = 1, dam = 0},
	on_gain = function(self, err) return _t"#Target# is afflicted by a wearying disease!" end,
	on_lose = function(self, err) return _t"#Target# is free from the wearying disease." end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_disease_count", 1)
		eff.tmpid2 = self:addTemporaryValue("inc_stats", {[Stats.STAT_DEX] = -eff.dex})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_disease_count", eff.tmpid1)
		self:removeTemporaryValue("inc_stats", eff.tmpid2)
		eff.tmpid1 = nil
		eff.tmpid2 = nil
	end,
}

newEffect{ -- Variant of Out of Phase.
	name = "KAM_SPELLWOVEN_PHASING", image = "talents/phase_door.png",
	desc = _t"Spellwoven Phasing",
	long_desc = function(self, eff) return ("You have used your Spellwoven teleportation to phase yourself out of reality, increasing your defense by %d and your resist all by %d%%, and reducing the duration of detrimental timed effects by %d%%."):tformat(eff.power, eff.power, eff.power) end,
	type = "magical",
	subtype = { teleport=true },
	status = "beneficial",
	parameters = { power = 0 },
	on_gain = function(self, err) return _t"#Target# has woven themself out of phase with reality.", _t"+Spellwoven Phasing" end,
	on_lose = function(self, err) return _t"#Target# has phased back into reality.", _t"-Spellwoven Phasing" end,
	activate = function(self, eff)
		eff.defid = self:addTemporaryValue("combat_def", eff.power)
		eff.resid= self:addTemporaryValue("resists", {all=eff.power})
		eff.durid = self:addTemporaryValue("reduce_detrimental_status_effects_time", eff.power)
		eff.particle = self:addParticles(Particles.new("phantasm_shield", 1))
	end,
	on_merge = function(self, old_eff, new_eff)
		return new_eff -- new effects always overwrite old for this.
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_def", eff.defid)
		self:removeTemporaryValue("resists", eff.resid)
		self:removeTemporaryValue("reduce_detrimental_status_effects_time", eff.durid)
		self:removeParticles(eff.particle)
	end,
}

newEffect{
	name = "KAM_SPELLWOVEN_REGENERATION", image = "talents/disruption_shield.png", -- Knockoff Regeneration because it should be a spell for Spellweavers.
	desc = _t"Spellwoven Regeneration",
	long_desc = function(self, eff) return ("Arcane energies are restoring your body, regenerating %0.2f life per turn."):tformat(eff.power) end,
	type = "magical",
	subtype = { arcane = true, healing = true, regeneration = true },
	status = "beneficial",
	parameters = { power=0 },
	on_gain = function(self, err) return _t"#Target# is regenerating from the Spellwoven teleportation.", _t"+Spellwoven Regen" end,
	on_lose = function(self, err) return _t"#Target#'s Spellwoven regeneration has ended.", _t"-Spellwoven Regen" end,
	activate = function(self, eff)
		eff.tmpid = self:addTemporaryValue("life_regen", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("life_regen", eff.tmpid)
	end,
	on_merge = function(self, old_eff, new_eff)
		if (old_eff.dur * old_eff.power) < (new_eff.dur * new_eff.power) then 
			return new_eff
		else
			return old_eff 
		end
	end,
}

newEffect{
	name = "KAM_SPELLWOVEN_TRICK", 
	image = "talents/disruption_shield.png", -- I don't think this is possible to see as stands but.
	desc = _t"Tricked",
	long_desc = function(self, eff) return ("The target has been tricked by teleportation, reducing its damage dealt by %d%% and increasing its damage taken by %d%%."):tformat(eff.damReduce, eff.damIncrease) end,
	type = "mental", -- Pretty much the only new mental Spellwoven effect, since it doesn't reflect the actual "magic"
	subtype = { }, -- This isn't like mental-magical confusion stuff, it's just like "Oh shoot, they teleported all weird, where are they"
	status = "detrimental",
	parameters = { damReduce = 0, damIncrease = 0 },
	on_gain = function(self, err) return _t"#Target# has been tricked by confusing teleportation!", _t"+Tricked" end,
	on_lose = function(self, err) return _t"#Target# realizes what happened.", _t"-Tricked" end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_tricked_reduceDamage", eff.damReduce)
		eff.tmpid2 = self:addTemporaryValue("kam_tricked_increasedDamage", eff.damIncrease)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_tricked_reduceDamage", eff.tmpid1)
		self:removeTemporaryValue("kam_tricked_increasedDamage", eff.tmpid2)
	end,
	on_merge = function(self, old_eff, new_eff)
		return new_eff -- new effects always overwrite old for this.
	end,
}

newEffect{
	name = "KAM_SPELLWEAVER_OTHERWORLDLY_FLOW", 
	image = "talents/slipstream.png",
	desc = _t"Otherworldly Flow",
	long_desc = function(self, eff) return ("Through motion, your magic is enhanced. Your next Spellwoven spell gains a %0.2f Spellweave Multiplier."):tformat(eff.powerMod) end,
	type = "magical",
	subtype = { },
	status = "beneficial",
	parameters = { powerMod = 1 }, -- No on gain or lose messages since you'll get this like every turn of exploring...
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{ -- Pretty much functions like worse Movement Infusion. Always 1 turn duration, no pin/stun/daze immunity. Also magic if it would come up for a 1 turn buff, but it usually won't.
	name = "KAM_SPELLWOVEN_SPEED", image = "talents/rune__speed.png",
	desc = _t"Spellwoven Speed",
	long_desc = function(self, eff) return ("Through the Spellweave, you are moving very quickly, gaining %d%% movespeed.")
		:tformat(eff.power) end,
	type = "magical",
	subtype = { speed=true },
	status = "beneficial",
	parameters = {power=0},
	on_gain = function(self, err) return _t"#Target# is moving at otherworldly speeds!", _t"+Spellwoven Speed" end,
	on_lose = function(self, err) return _t"#Target#'s otherworldly speed has disappeared.", _t"-Spellwoven Speed" end,
	activate = function(self, eff)
		eff.moveid = self:addTemporaryValue("movement_speed", eff.power/100)
		self:effectTemporaryValue(eff, "ai_spread_add", 5)  -- Based on the movement infusion, this helps prevent AI tracking us out of LOS in weird ways.
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("movement_speed", eff.moveid)
	end,
	callbackOnMove = function(self, eff, moved, force, ox, oy)
		if not moved or force or (ox == self.x and oy == self.y) then return end
		local p = self:isTalentActive(self.T_KAM_ELEMENTS_OTHERWORLDLY_SUSTAIN)
		if not p then return end 
		p.waitTurns = 5
	end,
}

newEffect{
	name = "KAM_ECLIPSING_CORONA", 
	image = "talents/bind.png",
	desc = _t"Eclipsing Corona",	
	long_desc = function(self, eff)
		return ([[The target is illuminated by the light and darkness of a powerful eclipse, reducing all of their resistances by %d%% and losing defense and stealth power by %d and their armor and invisibility power by %d.]]):
		tformat(eff.resistanceReduction, eff.defenseReduction, eff.armorReduction)
	end,
	type = "magical",
	parameters = { resistanceReduction = 0, defenseReduction = 0, armorReduction = 0 },
	subtype = { },
	on_gain = function(self, err) return _t"#Target# is illuminated by an eclipsing corona!", _t"+Eclipsing Corona" end,
	on_lose = function(self, err) return _t"The eclipsing corona around #Target# has faded.", _t"-Eclipsing Corona" end,
	status = "detrimental",
	activate = function(self, eff)
		eff.resistPenalty = self:addTemporaryValue("resists", {all=-eff.resistanceReduction})
		eff.stealthPenalty = self:addTemporaryValue("inc_stealth", -eff.defenseReduction)
		eff.defensePenalty = self:addTemporaryValue("combat_def", -eff.defenseReduction)
		eff.armorPenalty = self:addTemporaryValue("combat_armor", -eff.armorReduction)
		if self:attr("invisible") then -- Invisibility and stealth work weirdly
			eff.invisiblePenalty = self:addTemporaryValue("invisible", -eff.armorReduction) 
		end
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists", eff.resistPenalty)
		self:removeTemporaryValue("inc_stealth", eff.stealthPenalty)
		self:removeTemporaryValue("combat_def", eff.defensePenalty)
		self:removeTemporaryValue("combat_armor", eff.armorPenalty)
		if eff.invisiblePenalty then
			self:removeTemporaryValue("invisible", eff.invisiblePenalty)
		end
	end,
}

newEffect{ -- Mostly modified from HEALING_NEXUS
	name = "KAM_MOLTEN_DRAIN_EFF", image = "talents/elemental_retribution.png",
	desc = _t"Molten Drain",
	long_desc = function(self, eff)
		return ("%d%% of direct healing done to the target is redirected to %s."):tformat(eff.reduction, eff.src:getName())
	end,
	type = "magical",
	subtype = { fire=true, physical=true, heal=true },
	status = "detrimental",
	parameters = { reduction = 0},
	callbackPriorities={callbackOnHeal = -5},
	callbackOnHeal = function(self, eff, value, src, raw_value)
		if raw_value > 0 and eff.src and not eff.src.__kam_healing_drain_active then
			local reduction = value * (eff.reduction / 100)
			game:delayedLogDamage(eff.src, self, 0, ("#SLATE#(%d drained)#LAST#"):tformat(reduction), false)
			eff.src.__kam_healing_drain_active = true
			eff.src:heal(raw_value * eff.reduction / 100, src)
			eff.src.__kam_healing_drain_active = nil
			return {value = value - reduction}
		end
	end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{ -- Nyooooommmmmm...
	name = "KAM_SPELLWOVEN_HASTE", image = "talents/timeless.png",
	desc = _t"Spellwoven Haste",
	long_desc = function(self, eff) return ("Absorbing excess energy from your shield, you have gained %d%% movespeed and %d%% combat, spell, and mind speeds.")
		:tformat(eff.movespeed, eff.combatspeed) end,
	type = "magical",
	subtype = { speed=true },
	status = "beneficial",
	parameters = {movespeed = 0, combatspeed = 0},
	on_gain = function(self, err) return _t"#Target# absorbs energy from their broken shield!", _t"+Haste" end,
	on_lose = function(self, err) return _t"#Target#'s excess energy dissapates.", _t"-Haste" end,
	activate = function(self, eff)
		eff.movespeedId = self:addTemporaryValue("movement_speed", eff.movespeed/100)
		eff.physspeedId = self:addTemporaryValue("combat_physspeed", eff.combatspeed/100)
		eff.mindspeedId = self:addTemporaryValue("combat_mindspeed", eff.combatspeed/100)
		eff.spelspeedId = self:addTemporaryValue("combat_spellspeed", eff.combatspeed/100)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("movement_speed", eff.movespeedId)
		self:removeTemporaryValue("combat_physspeed", eff.physspeedId)
		self:removeTemporaryValue("combat_mindspeed", eff.mindspeedId)
		self:removeTemporaryValue("combat_spellspeed", eff.spelspeedId)
		self:setEffect(self.EFF_KAM_SPELLWOVEN_HASTE_EXHAUSTION, 5, {})
	end,
}

newEffect{ -- Bwoop.
	name = "KAM_SPELLWOVEN_HASTE_EXHAUSTION", image = "talents/time_dilation.png",
	desc = _t"Haste Exhaustion",
	long_desc = function(self, eff) return ("You cannot absorb any more shields. You cannot gain the effects of the Haste Shield Bonus.")
		:tformat(eff.power) end,
	type = "other",
	subtype = { },
	status = "detrimental",
	parameters = {},
	activate = function(self, eff) end,
	deactivate = function(self, eff) end,
}

newEffect{
	name = "KAM_SPELLWOVEN_VOIDSTEPPING", image = "talents/slipstream.png",
	desc = _t"Voidstepping",
	long_desc = function(self, eff) return ("You aren't fully in reality after your teleport, increasing your movespeed by %d%% and allowing you to run through walls of thickness 3 or less, instantly teleporting to the other side. This has a cooldown equal to the number of tiles moved through.")
		:tformat(eff.movespeed) end,
	type = "magical",
	subtype = { speed=true },
	status = "beneficial",
	parameters = {movespeed = 0},
	on_gain = function(self, err) return _t"#Target# is voidstepping!", _t"+Voidstepping" end,
	on_lose = function(self, err) return _t"#Target# is no longer voidstepping.", _t"-Voidstepping" end,
	activate = function(self, eff)
		eff.movespeedId = self:addTemporaryValue("movement_speed", eff.movespeed/100)
		eff.throughWalls = self:addTemporaryValue("prob_travel", 3)
		eff.throughWallsCooldown = self:addTemporaryValue("prob_travel_penalty", 1)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("movement_speed", eff.movespeedId)
		self:removeTemporaryValue("prob_travel", eff.throughWalls)
		self:removeTemporaryValue("prob_travel_penalty", eff.throughWallsCooldown)
	end,
}

newEffect{
	name = "KAM_WIND_AND_RAIN_EFFECT", 
	image = "talents/thunderclap.png",
	desc = _t"Icestorm",	
	long_desc = function(self, eff)
		return ([[The target is surrounded by a raging ice storm, halving their Stun and Pinning resistance and dealing %d Cold and %d Lightning damage each turn to all enemies within radius %d.]]):
		tformat(eff.src:damDesc(DamageType.COLD, eff.damage/2), eff.src:damDesc(DamageType.LIGHTNING, eff.damage/2), eff.radius)
	end,
	type = "magical",
	parameters = { src = src, damage = 0, radius = 0 },
	subtype = {},
	on_gain = function(self, err) return _t"#Target# is surrounded by a raging icestorm!", _t"+Icestorm" end,
	on_lose = function(self, err) return _t"The icestorm around #Target# dies out.", _t"-Icestorm" end,
	status = "detrimental",
	activate = function(self, eff)
		if self:attr("pin_immune") then
			eff.pinResist = self:addTemporaryValue("pin_immune", -self:attr("pin_immune") / 2)
		end
		if self:attr("stun_immune") then
			eff.stunResist = self:addTemporaryValue("stun_immune", -self:attr("stun_immune") / 2)
		end
		eff.src:attr("kam_icestorm_count", 1)
	end,
	deactivate = function(self, eff)
		if eff.pinResist ~= nil then
			self:removeTemporaryValue("pin_immune", eff.pinResist)
		end
		if eff.stunResist ~= nil then
			self:removeTemporaryValue("stun_immune", eff.stunResist)
		end
		eff.src:attr("kam_icestorm_count", -1)
	end,
	on_timeout = function(self, eff)
		local tg = {type="ball", x=self.x, y=self.y, radius=eff.radius, friendlyfire=false, selffire=false}
		
		eff.src:project(tg, self.x, self.y, DamageType.KAM_WIND_AND_RAIN_DAMAGE_TYPE, eff.damage)

		local tal = eff.src:getTalentFromId(eff.src.T_KAM_ELEMENT_WIND_AND_RAIN)
		local argsList = {tx=self.x, ty=self.y, radius=eff.radius, density = 0.1}
		tal.getElementColors(eff.src, argsList, tal)
		game.level.map:particleEmitter(self.x, self.y, 0.8, "kam_spellweaver_ball_physical", argsList)
	end,
}

newEffect{ -- Based on WILD_SPEED since it already does what I needed.
	name = "KAM_SPELLWOVEN_LIGHTNING_SPEED", image = "talents/thunderclap.png",
	desc = _t"Spellwoven Speed",
	long_desc = function(self, eff) return ("You are moving at incredibly speeds, gaining %d%% movespeed and 100%% stun, daze and pinning immunity.")
		:tformat(100 * eff.power) end,
	type = "magical",
	subtype = { speed=true },
	status = "beneficial",
	parameters = {power = 0, t_id = nil, doBonus = false},
	on_gain = function(self, err) return _t"#Target# is moving at lightning speeds!", _t"+Spellwoven Speed" end,
	on_lose = function(self, err) return _t"#Target#'s lightning speed ends.", _t"-Spellwoven Speed" end,
	get_fractional_percent = function(self, eff)
		local d = game.turn - eff.start_turn
		return util.bound(360 - d / eff.possible_end_turns * 360, 0, 360)
	end,
	activate = function(self, eff) -- Brief note: Pretty sure nothing in game uses daze_immunity except like this and 2 other effects. Including the actual effect of daze.
		eff.start_turn = game.turn
		eff.possible_end_turns = 10 * (eff.dur+1)
		eff.moveid = self:addTemporaryValue("movement_speed", eff.power)

		self:effectTemporaryValue(eff, "ai_spread_add", 5)  -- Reduce accuracy of AI position guesses so we don't track straight to players that moved out of LOS
		
		eff.stun = self:addTemporaryValue("stun_immune", 1)
		eff.pin = self:addTemporaryValue("pin_immune", 1)
		
		self:getTalentFromId(self[eff.t_id]).kamLightningEffActive = true
	end,
	deactivate = function(self, eff)
		local t = self:getTalentFromId(self[eff.t_id])
		self:removeTemporaryValue("movement_speed", eff.moveid)
		self:removeTemporaryValue("stun_immune", eff.stun)
		self:removeTemporaryValue("pin_immune", eff.pin)
		if eff.doBonus then
			t.doBonus(self, t, 1)
		end
		t.kamLightningEffActive = false
	end,
}

newEffect{
	name = "KAM_RUINOUS_EXHAUSTION", 
	image = "talents/corpse_explosion.png",
	desc = _t"Ruinous Exhaustion",	
	long_desc = function(self, eff)
		return ([[The target is exhausted from the horrible ruin, reducing all of their damage by %d%%, all damage penetration by %d%%, their Attack, Mental, and Spell powers by %d, and their accuracy by %d for 4 turns.]]):
		tformat(eff.damageReduction, eff.accuracyPenReduction, eff.powerReduction, eff.accuracyPenReduction)
	end,
	type = "magical",
	subtype = { damageReduction = 0, powerReduction = 0, accuracyPenReduction = 0 },
	on_gain = function(self, err) return _t"#Target# is afflicted with ruinous exhaustion!", _t"+Ruinous Exhaustion" end,
	on_lose = function(self, err) return _t"#Target# has recovered from the ruinous exhaustion.", _t"-Ruinous Exhaustion" end,
	status = "detrimental",
	activate = function(self, eff)
		eff.resistPenPenalty = self:addTemporaryValue("resists_pen", {all=-eff.accuracyPenReduction})
		eff.allDamageReduction = self:addTemporaryValue("inc_damage", {all=-eff.damageReduction})
		eff.physReduction = self:addTemporaryValue("combat_dam", -eff.powerReduction)
		eff.spellReduction = self:addTemporaryValue("combat_spellpower", -eff.powerReduction)
		eff.mindReduction = self:addTemporaryValue("combat_mindpower", -eff.powerReduction)
		eff.accuracyReduction = self:addTemporaryValue("combat_atk", -eff.accuracyPenReduction)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists_pen", eff.resistPenPenalty)
		self:removeTemporaryValue("combat_dam", eff.physReduction)
		self:removeTemporaryValue("combat_spellpower", eff.spellReduction)
		self:removeTemporaryValue("combat_mindpower", eff.mindReduction)
		self:removeTemporaryValue("inc_damage", eff.allDamageReduction)
		self:removeTemporaryValue("combat_atk", eff.accuracyReduction)
	end,
}

newEffect{
	name = "KAM_SHIELDBONUS_CORROSION", 
	image = "talents/acidfire.png",
	desc = _t"Reflected Corrosion",	
	long_desc = function(self, eff)
		return ([[The target is corroded from attacking a corrosive Spellwoven shield, reducing their damage by %d%%.]]):
		tformat(eff.power)
	end,
	type = "magical",
	on_gain = function(self, err) return _t"#Target# is becoming corroded!", _t"+Corrosion" end,
	on_lose = function(self, err) return _t"The corrosion on #Target# fades away.", _t"-Corrosion" end,
	subtype = { power = 0, lastApplyTurn = 0 },
	status = "detrimental",
	on_merge = function(self, old_eff, new_eff)
		if not (old_eff.lastApplyTurn + 10 > game.turn) then -- Once per turn stacking.
			self:removeTemporaryValue("inc_damage", old_eff.reductionId)
			old_eff.power = math.min(50, old_eff.power + new_eff.power)
			old_eff.reductionId = self:addTemporaryValue("inc_damage", {all=-old_eff.power})
			old_eff.dur = new_eff.dur
			old_eff.lastApplyTurn = game.turn
		end
		
		return old_eff
	end,
	activate = function(self, eff)
		eff.reductionId = self:addTemporaryValue("inc_damage", {all=-eff.power})
		eff.lastApplyTurn = game.turn
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("inc_damage", eff.reductionId)
	end,
}

-- The next many effects are all runic modification effects. There are many of them.
newEffect{ -- Prevents all damage dealt by or to you (see hooks). May be badly balanced.
	name = "KAM_RUNIC_MODIFICATION_TELEPORT", 
	image = "talents/rune__teleportation.png",
	desc = _t"Rune Modification: Teleportation",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you cannot take or deal damage.]]):
		tformat()
	end,
	type = "magical",
	status = "beneficial",
	parameters = { },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_SHIELD", 
	image = "talents/rune__shielding.png",
	desc = _t"Rune Modification: Shielding",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you are reducing all damage dealt to you by %d%%.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+Resilience" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-Resilience" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.resistId = self:addTemporaryValue("resists", {all=eff.power})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists", eff.resistId)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_BLINK", 
	image = "effects/rune__controlled_phase_door.png",
	desc = _t"Rune Modification: Blink",
	long_desc = function(self, eff)
		return ([[Through runic modification, you are invisible, gaining %d invisibility power.]]):
		tformat(eff.power)
	end,
	type = "magical",
	status = "beneficial",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "invisible", eff.power)
	end,
	deactivate = function(self, eff)
		self:resetCanSeeCacheOf()
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_BITING_GALE", 
	image = "talents/rune__biting_gale.png",
	desc = _t"Rune Modification: Biting Gale",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you have gained %d%% iceblock penetration.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.pierceId = self:addTemporaryValue("iceblock_pierce", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("iceblock_pierce", eff.pierceId)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_ACID_WAVE", 
	image = "talents/rune__acid_wave.png",
	desc = _t"Rune Modification: Acid Wave",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you have gained %d%% all resist penetration.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.resistPenPenalty = self:addTemporaryValue("resists_pen", {all=-eff.power})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists_pen", eff.resistPenPenalty)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_ETHEREAL", 
	image = "talents/rune__invisibility.png",
	desc = _t"Rune Modification: Ethereal",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you have gained %d%% movespeed.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.movespeedId = self:addTemporaryValue("movement_speed", eff.power / 100)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("movement_speed", eff.movespeedId)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_STORMSHIELD", 
	image = "talents/rune__lightning.png",
	desc = _t"Rune Modification: Stormshield",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you have gained %d%% Lightning melee retaliation.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.meleeRetalId = self:addTemporaryValue("on_melee_hit", {[DamageType.LIGHTNING] = eff.power})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("on_melee_hit", eff.meleeRetalId)
	end,
}

newEffect{ -- Yeah, it's bad. I might buff this into something useable later, but Shatter Afflictions seems like such a must-pick already.
	name = "KAM_RUNIC_MODIFICATION_SHATTER_AFFLICTIONS", 
	image = "talents/warp_mine_away.png",
	desc = _t"Rune Modification: Shatter Afflictions",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you have gained %d Constitution.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.constitutionId = self:addTemporaryValue("inc_stats", {[Stats.STAT_CON] = eff.power})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("inc_stats", eff.constitutionId)
	end,
}

newEffect{ -- The one for artifact runes (other than Rune of Reflection). I considered doing one for each, but the talent discription is already long enough. Also should give a level of addon/update resistance.
	name = "KAM_RUNIC_MODIFICATION_OTHER", 
	image = "talents/rune_of_the_rift.png",
	desc = _t"Rune Modification: Advanced",	
	long_desc = function(self, eff)
		return ([[Through runic modification, your damage is increased by %d%%.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.damageId = self:addTemporaryValue("inc_damage", {all = eff.power})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("inc_damage", eff.damageId)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_REGENERATION", 
	image = "talents/infusion__regeneration.png",
	desc = _t"Rune Modification: Regeneration",	
	long_desc = function(self, eff)
		return ([[Through runic modification, your heal mod is increased by %d%%.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.healmodId = self:addTemporaryValue("healing_factor", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("inc_stats", eff.healmodId)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_HEALING", 
	image = "talents/infusion__healing.png",
	desc = _t"Rune Modification: Healing",	
	long_desc = function(self, eff)
		return ([[Through runic modification, block the next %d instances of damage over 50 that would be dealt to you.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
	callbackOnTakeDamage = function(self, eff, src, _, _, type, dam, state)
		if dam > 50 then
			local d_color = DamageType:get(type).text_color or "#ORCHID#"
			game:delayedLogDamage(src, self, 0, ("%s(%d negated#LAST#%s)#LAST#"):tformat(d_color, dam, d_color), false)
			eff.power = eff.power - 1
			if eff.power <= 0 then
				self:removeEffect(self.EFF_KAM_RUNIC_MODIFICATION_HEALING)
			end
			return {dam = 0}
		end
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_HEROISM", 
	image = "talents/infusion__heroism.png",
	desc = _t"Rune Modification: Heroism",	
	long_desc = function(self, eff)
		return ([[Through runic modification, if you take damage that would reduce your life to less than 1, prevent it and heal for %d. If this occurs, this effect cannot trigger again for 50 turns.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_HEROISM_COOLDOWN", 
	image = "talents/sleep.png",
	desc = _t"Runic Modification Exhaustion",	
	long_desc = function(self, eff)
		return ([[You are exhausted from avoiding death. You cannot benefit from Runic Modification: Heroism.]]):
		tformat()
	end,
	type = "other", -- No, you will not.
	parameters = { },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "detrimental",
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "KAM_RUNIC_MODIFICATION_OTHER_INFUSION", 
	image = "talents/infusion__wild_growth.png",
	desc = _t"Rune Modification: Advanced Infusion",	
	long_desc = function(self, eff)
		return ([[Through runic modification, you are reducing all damage dealt to you by %d%%.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Removed because this is a guarenteed apply whenever you use a rune of the right type.
--	on_lose = function(self, err) return _t"#Target#.", _t"-" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.resistId = self:addTemporaryValue("resists", {all=eff.power})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists", eff.resistId)
	end,
}

newEffect{
	name = "KAM_SPELLWEAVER_RUNIC_EMPOWERMENT", 
	image = "talents/rune__vision.png",
	desc = _t"Runic Rechanneling",
	long_desc = function(self, eff) return ("You have channeled excess runic power into your magic. Your next Spellwoven spell gains a %0.2f Spellweave Multiplier."):tformat(eff.powerMod) end,
	type = "magical",
	subtype = { },
	status = "beneficial",
	parameters = { powerMod = 1 }, -- For the same reason as all the other rune stuff, no messages here. Might add one here since it's the big one.
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
	on_merge = function(self, old_eff, new_eff) -- Bonus stacks.
		new_eff.powerMod = new_eff.powerMod + old_eff.powerMod - 1
		return new_eff
	end,
}

newEffect{
	name = "ZONE_AURA_KAM_WOVEN_HOME",
	desc = _t"Harmonic Paradise",
	image = "talents/kam_spellweaver_harmonic_paradise.png",
	no_stop_enter_worlmap = true,
	long_desc = function(self, eff) return (_t"Zone-wide effect: The elements here are in perfect harmony, preventing all damage.") end,
	decrease = 0, no_remove = true,
	type = "other",
	subtype = { aura=true },
	status = "detrimental",
	zone_wide_effect = true,
	parameters = {},
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{ -- Prevents all damage dealt by or to you and makes beneficial effects last longer. May be badly balanced.
	name = "KAM_SPELLWEAVER_METAPARADISE", 
	image = "talents/kam_spellweaver_harmonic_paradise.png",
	desc = _t"Harmonic Paradise",	
	long_desc = function(self, eff)
		return ([[For a short moment, everything is in perfect harmony. You cannot take or deal damage, also the durations of beneficial effects reduce half as quickly. This effect cannot be removed by most sources of effect removal.]]):
		tformat()
	end,
	type = "magical",
	status = "other",
	parameters = { },
	subtype = { },
	on_gain = function(self, err) return _t"#Target# creates a perfect elemental harmony!", _t"+Harmonic Paradise" end,
	on_lose = function(self, err) return _t"#Target# can no longer sustain the perfect moment.", _t"-Harmonic Paradise" end,
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
}

newEffect{
	name = "KAM_CHILL_OF_THE_GRAVE_ARMORBONUS", 
	image = "talents/grave_mistake.png",
	desc = _t"Gravechill Armor",	
	long_desc = function(self, eff)
		return ([[You are covered with the ice of death itself, granting you %d armor. This caps at 20 armor.]]):
		tformat(eff.armor)
	end,
	type = "magical",
	subtype = { },
	parameters = { armor = 0 },
	on_gain = function(self, err) return _t"#Target# is coated in the ice of the dead!", _t"+Gravechill Armor" end,
	on_lose = function(self, err) return _t"The grave ice coating #Target# melts.", _t"-Gravechill Armor" end,
	status = "beneficial",
	activate = function(self, eff)
		eff.armorBonus = self:addTemporaryValue("combat_armor", eff.armor)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_armor", eff.armorBonus)
	end,
	on_merge = function(self, old_eff, new_eff) -- Stacks up to 10 armor.
		self:removeTemporaryValue("combat_armor", old_eff.armorBonus)
		old_eff.armor = math.min(20, old_eff.armor + new_eff.armor)
		old_eff.armorBonus = self:addTemporaryValue("combat_armor", old_eff.armor)
		old_eff.dur = new_eff.dur
		return old_eff
	end,
}

newEffect{
	name = "KAM_CHILL_OF_THE_GRAVE", 
	image = "talents/grave_mistake.png",
	desc = _t"Chill of the Grave",	
	long_desc = function(self, eff)
		local gravechill = eff.src:getTalentFromId(eff.src.T_KAM_ELEMENTS_GRAVECHILL)
		local skeletonDuration = 0
		if gravechill then
			skeletonDuration = gravechill.getSkeletonDuration(eff.src, gravechill)
		end
		return ([[The target is frigid with the chill of the grave. On death, the target has a %d%% chance to rise as a skeleton for %d turns.]]):
		tformat(eff.chance, skeletonDuration)
	end,
	type = "magical", -- Almost tempted to make this other since it really doesn't effect the target per say, but...
	parameters = { src = src, chance = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+Gravechill" end, -- Guarenteed to apply to everything whenever you use, say, huge. No need to spam the chatlog that much.
--	on_lose = function(self, err) return _t"#Target#.", _t"-Gravechill" end,
	status = "detrimental",
	activate = function(self, eff)
	end,
	deactivate = function(self, eff)
	end,
	on_die = function(self, eff)
		if (rng.range(1,100) <= eff.chance) then
			local gravechill = eff.src:getTalentFromId(eff.src.T_KAM_ELEMENTS_GRAVECHILL)
			gravechill.makeSkeleton(eff.src, self, gravechill)
		end
	end,
}

newEffect{
	name = "KAM_GRAVITIC_EXHAUSTION", 
	image = "talents/gravity_locus.png",
	desc = _t"Gravitic Exhaustion",	
	long_desc = function(self, eff)
		return ([[The target is exhausted and destabilized by the bizarre gravity shifts, lowering their Knockback Resistance by %d%%.]]):tformat(eff.power)
	end,
	type = "magical",
	subtype = { },
	parameters = { power = 0 },
	on_gain = function(self, err) return _t"#Target# is exhausted by shifts in gravity!", _t"+Gravitic Exhaustion" end,
	on_lose = function(self, err) return _t"#Target# has recovered their stability.", _t"-Gravitic Exhaustion" end,
	status = "detrimental",
	activate = function(self, eff)
		eff.knockbackId = self:addTemporaryValue("knockback_immune", -1 * eff.power / 100)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("knockback_immune", eff.knockbackId)
	end,
}

-- Second set of diseases: Confusing Disease - Cunning, Mystical Disease - Magic, Nauseating Disease - Willpower
newEffect{ -- Cunning disease
	name = "KAM_CONFUSING_DISEASE", image = "talents/weakness_disease.png",
	desc = _t"Confusing Fever",
	long_desc = function(self, eff) return ("The target is infected by a confusing fever, reducing their cunning by %d."):tformat(eff.cun) end,
	type = "magical",
	subtype = {disease=true, blight=true},
	status = "detrimental",
	parameters = {cun = 0, feverDamage = 0},
	on_gain = function(self, err) return _t"#Target# is afflicted by a confusing fever!" end,
	on_lose = function(self, err) return _t"#Target# recovers from the confusing fever." end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_disease_count", 1)
		eff.tmpid2 = self:addTemporaryValue("inc_stats", {[Stats.STAT_CUN] = -eff.cun})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_disease_count", eff.tmpid1)
		self:removeTemporaryValue("inc_stats", eff.tmpid2)
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.KAM_DRAINING_FEVER_DAMAGE_TYPE).projector(eff.src, self.x, self.y, DamageType.KAM_DRAINING_FEVER_DAMAGE_TYPE, eff.feverDamage)
	end,
}

newEffect{ 
	name = "KAM_MYSTICAL_DISEASE", image = "talents/rotting_disease.png",
	desc = _t"Mystical Fever",
	long_desc = function(self, eff) return ("The target is infected by a mystical fever, reducing their magic by %d."):tformat(eff.mag) end,
	type = "magical",
	subtype = {disease=true, blight=true},
	status = "detrimental",
	parameters = {mag = 0, feverDamage = 0},
	on_gain = function(self, err) return _t"#Target# is afflicted by a mystical fever!" end,
	on_lose = function(self, err) return _t"#Target# recovers from the mystical fever." end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_disease_count", 1)
		eff.tmpid2 = self:addTemporaryValue("inc_stats", {[Stats.STAT_MAG] = -eff.mag})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_disease_count", eff.tmpid1)
		self:removeTemporaryValue("inc_stats", eff.tmpid2)
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.KAM_DRAINING_FEVER_DAMAGE_TYPE).projector(eff.src, self.x, self.y, DamageType.KAM_DRAINING_FEVER_DAMAGE_TYPE, eff.feverDamage)
	end,
}

newEffect{
	name = "KAM_NAUSEATING_DISEASE", image = "talents/decrepitude_disease.png",
	desc = _t"Nauseating Fever",
	long_desc = function(self, eff) return ("The target is infected by a nauseating fever, reducing their willpower by %d."):tformat(eff.wil) end,
	type = "magical",
	subtype = {disease=true, blight=true},
	status = "detrimental",
	parameters = {wil = 0, feverDamage = 0},
	on_gain = function(self, err) return _t"#Target# is afflicted by a nauseating fever!" end,
	on_lose = function(self, err) return _t"#Target# recovers from the nauseating fever." end,
	activate = function(self, eff)
		eff.tmpid1 = self:addTemporaryValue("kam_disease_count", 1)
		eff.tmpid2 = self:addTemporaryValue("inc_stats", {[Stats.STAT_WIL] = -eff.wil})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("kam_disease_count", eff.tmpid1)
		self:removeTemporaryValue("inc_stats", eff.tmpid2)
	end,
	on_timeout = function(self, eff)
		DamageType:get(DamageType.KAM_DRAINING_FEVER_DAMAGE_TYPE).projector(eff.src, self.x, self.y, DamageType.KAM_DRAINING_FEVER_DAMAGE_TYPE, eff.feverDamage)
	end,
}

newEffect{
	name = "KAM_MANASTORM_EFFECT", 
	image = "talents/anomaly_invigorate.png",
	desc = _t"Manastorm",
	long_desc = function(self, eff)
		return ([[The target is surrounded by an arcane storm, draining %d resources (resource scaling listed in the Manastorm talent in the Elementalist tree) each turn from all enemies within radius %d.]]):
		tformat(eff.draining, eff.radius)
	end,
	type = "magical",
	parameters = { src = src, draining = 0, radius = 0 },
	subtype = {},
	on_gain = function(self, err) return _t"#Target# is surrounded by a mystical manastorm!", _t"+Manastorm" end,
	on_lose = function(self, err) return _t"The manastorm around #Target# burns out.", _t"-Manastorm" end,
	status = "detrimental",
	on_timeout = function(self, eff)
		local tg = {type="ball", x=self.x, y=self.y, radius=eff.radius, friendlyfire=false, selffire=false}
		
		eff.src:project(tg, self.x, self.y, DamageType.KAM_DRAINING_MANASTORM_DAMTYPE, eff.draining)
		
		local tal = eff.src:getTalentFromId(eff.src.T_KAM_ELEMENT_MANASTORM)
		local argsList = {tx=self.x, ty=self.y, radius=eff.radius, density = 0.1}
		tal.getElementColors(eff.src, argsList, tal)
		game.level.map:particleEmitter(self.x, self.y, 0.8, "kam_spellweaver_ball_physical", argsList)
	end,
}

newEffect{
	name = "KAM_RADIAMARK_EFFECT", 
	image = "talents/charge_leech.png",
	desc = _t"Radiamark",
	long_desc = function(self, eff)
		return ([[The target is illuminated with a corrosive glow, giving %s's attacks against them a %d%% chance to repeat (repeated attacks cannot trigger this) and causing those attacks to heal %s for %d%% of the damage dealt.]]):
		tformat(eff.src.name, eff.repeatChance, eff.src.name, eff.drainPower)
	end,
	type = "magical",
	parameters = { src = src, repeatChance = 0, drainPower = 0 },
	subtype = {},
	on_gain = function(self, err) return _t"#Target# is glowing with a corrosive radiance!", _t"+Radiamark" end,
	on_lose = function(self, err) return _t"The corrosive glow around #Target# dims.", _t"-Radiamark" end,
	status = "detrimental",
	activate = function(self, eff)
		eff.blightfightedId = self:addTemporaryValue("blind_fighted", 1)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("blind_fighted", eff.blightfightedId)
	end,
	callbackOnMeleeHit = function(self, eff, src, dam)
		if eff.src == src then
			src:heal(dam * eff.drainPower / 100, self)
		end
		if not self.dead and not (game.state.kam_is_radiamark_bonus_attacking) and not (src.turn_procs.kam_radiamark_attacked and not src.turn_procs.kam_radiamark_attacked[self]) and (rng.range(1,100) <= eff.repeatChance) then 
			game.state.kam_is_radiamark_bonus_attacking = true -- Should never trigger off of itself.
			src.turn_procs.kam_radiamark_attacked = src.turn_procs.kam_radiamark_attacked or {}
			src.turn_procs.kam_radiamark_attacked[self] = true
			local old = src.energy.value
			game.logSeen(self, "%s's Radiamark glows and %s strikes again!", self:getName():capitalize(), src:getName():capitalize())
			src:attackTarget(self, nil, 1, true, false)
			game.state.kam_is_radiamark_bonus_attacking = false
			src.energy.value = old
		end
	end,
}

newEffect{
	name = "KAM_CONSTRUCT_CONTROLLER_RECONFIGURE", image = "talents/anomaly_stop.png",
	desc = _t"Reconfigured Elements",
	long_desc = function(self, eff) 
		if eff.isPrismatic then
			return ("The Controller Construct has altered its elements. It now resists all damage and uses Prismatic damage."):tformat() 
		else
			return ("The Controller Construct has altered its elements. It now resists and utilizes %s and %s damage and is weak to %s and %s damage."):tformat(DamageType:get(eff.resist1).name:capitalize(), DamageType:get(eff.resist2).name:capitalize(), DamageType:get(eff.weakness1).name:capitalize(), DamageType:get(eff.weakness2).name:capitalize()) 
		end
	end,
	type = "other",
	subtype = { },
	status = "beneficial",
	parameters = {resist1 = nil, resist2 = nil, weakness1 = nil, weakness2 = nil, resistPower = 0, weaknessPower = 0},
	on_gain = function(self, err) return _t"#Target# reconfigures its elements!" end,
--	on_lose = function(self, err) return _t"#Target#." end,
	activate = function(self, eff)
		eff.resid1 = self:addTemporaryValue("resists", {[eff.resist1] = eff.resistPower})
		eff.resid2 = self:addTemporaryValue("resists", {[eff.resist2] = eff.resistPower})
		eff.weakid1 = self:addTemporaryValue("resists", {[eff.weakness1] = -1 * eff.resistPower})
		eff.weakid2 = self:addTemporaryValue("resists", {[eff.weakness2] = -1 * eff.resistPower})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists", eff.resid1)
		self:removeTemporaryValue("resists", eff.resid2)
		self:removeTemporaryValue("resists", eff.weakid1)
		self:removeTemporaryValue("resists", eff.weakid2)
		
		local tal = self:getTalentFromId(self.T_KAM_KIA_CONSTRUCT_SHUFFLE)
		if tal then
			tal.setElements(self, tal)
		end
	end,
}

-- Note: Buffed gloves by making them refrain from forcing to center while increasing element power gains, thus making a net increase instead of no net change.
newEffect{
	name = "KAM_ELEMENTALIST_GLOVES_EFFECT",
	desc = _t"Elemental Balance",
	image = "talents/psi_tap.png",
	long_desc = function(self, eff)
		local eleString = ""
		for k, ele in pairs(eff.damageIncTable) do 
			local appendString = ([[%s: %0.1f%%]]):tformat((DamageType:get(k)).name:capitalize(), ele)
			eleString = eleString.."\n"..appendString
		end
		return ([[As you use the gloves, their elements change. Current status: %s]]):tformat(eleString)
	end,
	type = "other",
	subtype = { },
	no_stop_enter_worlmap = true,
	status = "detrimental",
	decrease = 0, no_remove = true,
	parameters = {damageIncTable = {}, damageTempValTable = {}},
	on_gain = function(self, err) return _t"#Target#'s gloves glow with the elements..." end,
--	on_lose = function(self, err) return _t"#Target#." end,
	activate = function(self, eff)
		local ed = self:getEffectFromId(eff.effect_id)
		ed.applyDamageInc(self, eff)
	end,
	deactivate = function(self, eff)
		local ed = self:getEffectFromId(eff.effect_id)
		ed.clearDamageInc(self, eff)
	end,
	getElementalGlovesModifier = function(self) -- Prevents things that divide damage types among things (like prismatic) from having somewhat wild effects.
		return 15 * self.level 
	end,
	getCenter = function()
		return 40
	end,
	applyDamageInc = function(self, eff)
		for k, ele in pairs(eff.damageIncTable) do
			eff.damageTempValTable[k] = self:addTemporaryValue("inc_damage", {[k] = ele})
		end
	end,
	clearDamageInc = function(self, eff)
		for _, tempVal in pairs(eff.damageTempValTable) do 
			self:removeTemporaryValue("inc_damage", tempVal)
		end
	end,
	kamSpellweaverElementalGlovesShiftElements = function(self, eff, damtype, dam)
		local ed = self:getEffectFromId(eff.effect_id)
		local maxDistanceFromZero = 70 -- The greatest allowed damage increase/reduction as a distance from 0.
		local baseStep = 2 -- Step for random corrections.
		local center = ed.getCenter()
		local cur = eff.damageIncTable[damtype]
		if cur then
			ed.clearDamageInc(self, eff)
			local shiftVal = dam / ed.getElementalGlovesModifier(self) * 20 -- Dealing 15*level damage will shift damage mod for this ele by -20% and all others by +2%.
			shiftVal = math.min(shiftVal, maxDistanceFromZero + cur)
			eff.damageIncTable[damtype] = cur - shiftVal
			local elementsCount = 0
			for _, _ in pairs(eff.damageIncTable) do
				elementsCount = elementsCount + 1
			end
			shiftVal = shiftVal / ((elementsCount - 1) * 0.9)
			for k, ele in pairs(eff.damageIncTable) do
				if k ~= damtype then
					cur = ele
					local eleShift = math.min(shiftVal, maxDistanceFromZero - cur)
					eff.damageIncTable[k] = cur + eleShift
				end
			end
			--[[ Cut to improve gloves's power
			-- Correct to make sure that the overall change is always 0. (can happen if an element is at 70 and is increased again). Set up to go both ways in case I missed something.
			local count = 0
			local eleTable = {}
			for k, ele in pairs(eff.damageIncTable) do
				count = count + ele
				if math.abs(eff.damageIncTable[k]) < maxDistanceFromZero then
					table.insert(eleTable, k)
				end
			end
			if count ~= center then
				local dir
				while math.abs(math.abs(count) - math.abs(center)) > 0.5 do
					if count < center then
						dir = 1
					else
						dir = -1
					end
					local k = rng.table(eleTable)
					cur = eff.damageIncTable[k]
					local eleShift = math.min(baseStep, maxDistanceFromZero - cur)
					eleShift = math.min(eleShift, center - count)
					count = count + eleShift * dir
					eff.damageIncTable[k] = eff.damageIncTable[k] + eleShift * dir
					if math.abs(count) < 0.5 then
						break
					end
				end
			end
			--]]
			ed.applyDamageInc(self, eff)
		end
	end,
	on_timeout = function(self, eff, ed)
		if not (self.attr and self:attr("kam_spellweaver_elemental_gloves_bonus")) then
			self:removeEffect(self.EFF_KAM_ELEMENTALIST_GLOVES_EFFECT, true, true)
		elseif not self.in_combat then
			ed.clearDamageInc(self, eff)
			local center = ed.getCenter()
			local elementsCount = 0
			for _, _ in pairs(eff.damageIncTable) do
				elementsCount = elementsCount + 1
			end
			center = center / elementsCount
			for k, ele in pairs(eff.damageIncTable) do
				if ele ~= center then
					local eleShift = (center - ele) * 0.15
					if math.abs(eleShift) < 2 then
						if center > ele then
							eleShift = 2
						else
							eleShift = -2
						end
					end
					if math.abs(ele + eleShift - center) <= 2 then
						eff.damageIncTable[k] = center
					else
						eff.damageIncTable[k] = eff.damageIncTable[k] + eleShift
					end
				end
			end
			ed.applyDamageInc(self, eff)
		end
	end,
}

newEffect{
	name = "KAM_ELEMENTAL_NULLIFICATION", image = "status/kam_spellweaver_elemental_nullfication.png", -- Made very easily and lazily with the empty set symbol.
	desc = _t"Elemental Nullification",
	long_desc = function(self, eff)
		return ("The target has no connection to the elements, lowering its damage by 20%% and converting its damage into elementless damage that ignores elemental damage increases and resistances."):tformat() 
	end,
	type = "other",
	subtype = { },
	status = "detrimental",
	parameters = {},
	on_gain = function(self, err) return _t"#Target# is severed from the elements!" end,
	on_lose = function(self, err) return _t"#Target#'s connection to the elements is restored." end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, "all_damage_convert", DamageType.KAM_ELEMENTLESS_DAMAGE)
		self:effectTemporaryValue(eff, "all_damage_convert_percent", 100)
	end,
}

newEffect{
	name = "KAM_WOVENHOME_ORC_PEACE_FURY_USER", image = "talents/kam_spellweaver_peace_rage.png",
	desc = _t"Peaceful Rage",
	long_desc = function(self, eff) 
		local wasSummonedText = ""
		if self.summoner then
			wasSummonedText = ("%s's "):tformat(self.summoner:getName():capitalize())
		end
		return ([[You are driven by %speace and rage, increasing all damage done to %s by %d%%.]]):tformat(wasSummonedText, eff.target.name, eff.power) 
	end,
	type = "mental",
	subtype = { frenzy=true },
	status = "detrimental",
	cancel_on_level_change = true,
	parameters = { power=10, target = nil },
	on_gain = function(self, err) return nil, _t"+Rage" end, -- Added in the text because otherwise if you have text it displays a long text.
	on_lose = function(self, err) return nil, _t"-Rage" end,
	callbackOnAct = function(self, eff) -- If you don't have a target, or the target dies, clear the effect.
		if not eff.target or eff.target.dead then 
			self:removeEffect(self.EFF_KAM_WOVENHOME_ORC_PEACE_FURY_USER, true, true)
		end
		if self.summoner then -- Force summons to target, obviously no need to do this to the actual user.
			self:setTarget(eff.target)
		end
	end,
}

newEffect{
	name = "KAM_WOVENHOME_ORC_HOLD_GROUND", 
	image = "talents/kam_spellweaver_new_home_ground.png",
	desc = _t"Stand Strong",	
	long_desc = function(self, eff)
		return ([[Through your focus and knowledge of Spellweaving techniques, all of your saves are increased by %d.]]):
		tformat(eff.power)
	end,
	type = "magical",
	parameters = { power = 0 },
	subtype = { },
--	on_gain = function(self, err) return _t"#Target#!", _t"+" end, -- Already has an application message.
	status = "beneficial",
	activate = function(self, eff)
		eff.mental = self:addTemporaryValue("combat_mentalresist", eff.power)
		eff.spell = self:addTemporaryValue("combat_spellresist", eff.power)
		eff.physical = self:addTemporaryValue("combat_physresist", eff.power)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("combat_mentalresist", eff.mental)
		self:removeTemporaryValue("combat_spellresist", eff.spell)
		self:removeTemporaryValue("combat_physresist", eff.physical)
	end,
}

newEffect{
	name = "KAM_WOVENHOME_ORC_NEW_PRIDE", 
	image = "talents/kam_spellweaver_new_pride.png",
	desc = _t"New Pride",
	long_desc = function(self, eff)
		return ([[The Wovenhome Orcs would not want you to fail here, and so you will not. Reduce all damage you take by a flat %d%%.]]):
		tformat(100 - eff.power)
	end,
	type = "other", -- Nothing would really "remove" this so...
	parameters = { power = 0 },
	subtype = { },
	on_gain = function(self, err) return _t"#Target# stands strong!" end,
	on_lose = function(self, err) return _t"#Target# is no longer standing strong." end,
	status = "beneficial",
	on_merge = function(self, old_eff, new_eff) -- Stacks multiplicatively.
		new_eff.power = ((new_eff.power) * (old_eff.power) / 100)
		return new_eff
	end,
}

newEffect{
	name = "KAM_META_EMPOWERMENT_BOOST", 
	image = "status/kam_spellweaver_boost_meta_empowerment.png",
	desc = _t"Metafocus",
	long_desc = function(self, eff)
		return ([[The Beacon is charged with energy, enhancing your focused spell. The damage boost of your next cast of your Meta Empowerment boosted spell is increased by %d%%.]]):tformat(eff.power)
	end,
	type = "other",
	parameters = { power = 0 },
	subtype = { },
	on_gain = function(self, err) return _t"#Target#'s focused spell is enhanced." end,
--	on_lose = function(self, err) return _t"#Target# is no longer standing strong." end,
	status = "beneficial",
}

newEffect{
	name = "KAM_RUNIC_ADAPTION_SCALE_BOOST", 
	image = "status/kam_spellweaver_boost_runic_adaption.png",
	desc = _t"Adapted Adaption",
	long_desc = function(self, eff)
		return ([[Your runes glow with the Beacon's power. The scaling boost of Runic Adaption is increased doubled for your next Rune cast.]]):tformat()
	end,
	type = "other",
	parameters = { power = 0 },
	subtype = { },
	on_gain = function(self, err) return _t"#Target#'s runes glow." end,
--	on_lose = function(self, err) return _t"#Target# is no longer standing strong." end,
	status = "beneficial",
	activate = function(self, eff)
		if self:knowTalent(self.T_KAM_RUNIC_ADAPTION) then
			local runicAdaption = self:getTalentFromId(self.T_KAM_RUNIC_ADAPTION)
			runicAdaption.updateRunes(self, runicAdaption)
		end
	end,
	deactivate = function(self, eff)
		local runicAdaption = self:getTalentFromId(self.T_KAM_RUNIC_ADAPTION)
		runicAdaption.updateRunes(self, runicAdaption)
	end,
	callbackOnTalentPost = function(self, t,  ab)
		if ab.type[1] == "inscriptions/runes" or ab.type[1] == "inscriptions/taints" or (ab.type[1] == "inscriptions/infusions" and KamCalc:isAllowInscriptions(self)) then
			self:removeEffect(self.EFF_KAM_RUNIC_ADAPTION_SCALE_BOOST)
		end
	end,
}

newEffect{
	name = "KAM_FRONTLINE_COUNTERATTACK_BOOST", 
	image = "status/kam_spellweaver_boost_frontline_spellweaver.png",
	desc = _t"Frontline Guard",
	long_desc = function(self, eff)
		return ([[The Beacon suddenly feels far more light, almost seeming to move on its own. The counterattack rate of Frontline Spellweaver is increased (multiplicatively) by %d%%.]]):tformat(eff.power)
	end,
	type = "other",
	parameters = { power = 0 },
	subtype = { },
	on_gain = function(self, err) return _t"The Beacon of the Spellweavers seems weightless." end,
--	on_lose = function(self, err) return _t"#Target# is no longer standing strong." end,
	status = "beneficial",
}

newEffect{
	name = "KAM_MELEE_META_BOOST", 
	image = "status/kam_spellweaver_boost_meta_melee.png",
	desc = _t"Metamelee",
	long_desc = function(self, eff)
		return ([[The Beacon thrums with pure power. Every attack deals an additional %d piercing elementless damage (which ignores all elemental resists and half of the targets all resistance but only benefits from your all damage increase).]]):tformat(eff.damage)
	end,
	type = "other",
	parameters = { damage = 0 },
	subtype = { },
	on_gain = function(self, err) return _t"The Beacon of the Spellweavers thrums with power." end,
--	on_lose = function(self, err) return _t"#Target# is no longer standing strong." end,
	status = "beneficial",
	callbackOnMeleeAttack = function(self, eff, target, hitted, crit, weapon, damtype)
		if self:reactionToward(target) >= 0 then return end
		if hitted and target and (not target.dead) and not (self.x == target.x and self.y == target.y) then
			DamageType:get(DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE).projector(self, target.x, target.y, DamageType.KAM_PIERCING_ELEMENTLESS_DAMAGE, eff.damage)
		end
	end,
}

newEffect{
	name = "ZONE_AURA_KAM_ELEMENTAL_RUINS",
	desc = _t"Harmonic Annihilation",
	image = "status/kam_spellweaver_harmonic_annihilation.png",
	no_stop_enter_worlmap = true,
	long_desc = function(self, eff) 
		return (_t"Zone-wide effect: The elements here are in ruinous harmony, nullifying the effects of resistance piercing and reducing all of your resistance piercing by 1000%.")
	end,
	decrease = 0, no_remove = true,
	type = "other",
	subtype = { aura=true },
	status = "detrimental",
	zone_wide_effect = true,
	parameters = {},
	activate = function(self, eff)
		eff.resistPenPenalty = self:addTemporaryValue("resists_pen", {all = -1000})
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue("resists_pen", eff.resistPenPenalty)
	end,
}