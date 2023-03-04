local ActorTalents = require "engine.interface.ActorTalents"
local Stats = require("engine.interface.ActorStats")
local Particles = require "engine.Particles"
local Entity = require "engine.Entity"
local Map = require "engine.Map"
require "engine.class"

-- File for shield effects since they're kinda their own thing.

newEffect{
	name = "KAM_SPELLWEAVER_SHIELD_BASIC", 
	image = "talents/rune__shielding.png",
	desc = _t"Spellwoven Shield",
	long_desc = function(self, eff)
		return ([[You are surrounded by a Spellwoven shield that can absorb %d/%d damage. %s]]):format(eff.absorbLeft, eff.absorbPower, eff.bonusDescriptor)
	end,
	charges = function(self, eff) return math.ceil(eff.absorbLeft) end,
	type = "magical", 
	subtype = { shield = true },
	status = "beneficial",
	parameters = { src = src, absorbPower = 1, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end },
	on_gain = function(self, err) return _t"A Spellwoven shield forms around #Target#.", _t"+Spellwoven Shield" end,
	on_lose = function(self, err) return _t"#Target#'s Spellwoven shield fades away.", _t"-Spellwoven Shield" end,
	damage_feedback = function(self, eff, src, value)
		if eff.particle and eff.particle._shader and eff.particle._shader.shad and src and src.x and src.y then
			local r = -rng.float(0.2, 0.4)
			local a = math.atan2(src.y - self.y, src.x - self.x)
			eff.particle._shader:setUniform("impact", {math.cos(a) * r, math.sin(a) * r})
			eff.particle._shader:setUniform("impact_tick", core.game.getTime())
		end
	end,
	activate = function(self, eff)
		eff.absorbPower = eff.absorbPower
		eff.absorbLeft = eff.absorbPower
		eff.dur = eff.dur
		if core.shader.active(4) then
			eff.particle = self:addParticles(Particles.new("shader_shield", 1, {img=eff.image or "shield7"}, {type="shield", shieldIntensity=eff.shield_intensity or 0.2, color=eff.color or {0.4, 0.7, 1.0}}))
		else
			eff.particle = self:addParticles(Particles.new("damage_shield", 1))
		end
		if (eff.bonusType == 5) then 
			eff.doBonus(self, eff.spellweavePower, eff, false)
		end
	end,
	callbackPriorities={callbackOnHit = -1}, -- Should activate early to make it less bad.
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		if (eff.bonusType == 1) or (eff.bonusType == 5) then 
			eff.doBonus(self, eff.spellweavePower, eff, true)
		end
	end,
	callbackOnHit = function(self, eff, cb, src)		
		if cb.value > 0 then 
			local damageToShield = cb.value
			if src and src.attr and src:attr("damage_shield_penetrate") then
				damageToShield = cb.value * (1 - (util.bound(src.damage_shield_penetrate, 0, 100) / 100))
			end
			local damageToShield = math.min(eff.absorbLeft, damageToShield)
			eff.absorbLeft = eff.absorbLeft - damageToShield
			cb.value = cb.value - damageToShield
			game:delayedLogDamage(src, self, 0, ("#SLATE#(%d absorbed)#LAST#"):tformat(damageToShield), false)
			
			if (eff.bonusType == 2) then 
				local a = game.level.map(src.x, src.y, Map.ACTOR)
				if a and self:reactionToward(a) < 0 then 
					eff.doBonus(self, eff.spellweavePower, a, damageToShield, eff.argsTable)
				end
			end
			if (eff.bonusType == 4) then 
				eff.doBonus(self, eff.spellweavePower, damageToShield)
			end
			
			if eff.absorbLeft <= 0 then 
				self:removeEffect(eff.effect_id)
			end
			return true
		end
	end,
	on_timeout = function(self, eff)
		if (eff.bonusType == 3) then 
			eff.doBonus(self, eff.spellweavePower)
		end
	end,
}

newEffect{
	name = "KAM_SPELLWEAVER_SHIELD_DISPERSING", 
	image = "talents/rune__shielding.png",
	desc = _t"Dispersing Shield",
	long_desc = function(self, eff)
		return ([[You are surrounded by a Dispersing Shield that can absorb up to 100 damage from each attack. It can still absorb %d/%d damage. %s]]):format(eff.absorbLeft, eff.absorbPower, eff.bonusDescriptor)
	end,
	charges = function(self, eff) return math.ceil(eff.absorbLeft) end,
	type = "magical", 
	subtype = { shield = true },
	status = "beneficial",
	parameters = { src = src, absorbPower = 1, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end },
	on_gain = function(self, err) return _t"A Dispersing shield forms around #Target#.", _t"+Dispersing Shield" end,
	on_lose = function(self, err) return _t"#Target#'s Dispersing shield fades away.", _t"-Dispersing Shield" end,
	damage_feedback = function(self, eff, src, value)
		if eff.particle and eff.particle._shader and eff.particle._shader.shad and src and src.x and src.y then
			local r = -rng.float(0.2, 0.4)
			local a = math.atan2(src.y - self.y, src.x - self.x)
			eff.particle._shader:setUniform("impact", {math.cos(a) * r, math.sin(a) * r})
			eff.particle._shader:setUniform("impact_tick", core.game.getTime())
		end
	end,
	activate = function(self, eff)
		eff.absorbPower = eff.absorbPower
		eff.absorbLeft = eff.absorbPower
		eff.dur = eff.dur
		if core.shader.active(4) then
			eff.particle = self:addParticles(Particles.new("shader_shield", 1, {img=eff.image or "shield7"}, {type="shield", shieldIntensity=eff.shield_intensity or 0.2, color=eff.color or {0.4, 0.7, 1.0}}))
		else
			eff.particle = self:addParticles(Particles.new("damage_shield", 1))
		end
		if (eff.bonusType == 5) then 
			eff.doBonus(self, eff.spellweavePower, eff, false)
		end
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		if (eff.bonusType == 1) or (eff.bonusType == 5) then 
			eff.doBonus(self, eff.spellweavePower, eff, true)
		end
	end,
	callbackOnHit = function(self, eff, cb, src)		
		if cb.value > 0 then 
			local damageToShield = cb.value
			if src and src.attr and src:attr("damage_shield_penetrate") then
				damageToShield = cb.value * (1 - (util.bound(src.damage_shield_penetrate, 0, 100) / 100))
			end
			damageToShield = math.min(eff.absorbLeft, damageToShield)
			damageToShield = math.min(100, damageToShield)
			eff.absorbLeft = eff.absorbLeft - damageToShield
			cb.value = cb.value - damageToShield
			game:delayedLogDamage(src, self, 0, ("#SLATE#(%d dispersed)#LAST#"):tformat(damageToShield), false)
			
			if (eff.bonusType == 2) then 
				local a = game.level.map(src.x, src.y, Map.ACTOR)
				if a and self:reactionToward(a) < 0 then 
					eff.doBonus(self, eff.spellweavePower, a, damageToShield, eff.argsTable)
				end
			end
			if (eff.bonusType == 4) then 
				eff.doBonus(self, eff.spellweavePower, damageToShield)
			end
			
			if eff.absorbLeft <= 0 then 
				self:removeEffect(eff.effect_id)
			end
			return true
		end
	end,
	on_timeout = function(self, eff)
		if (eff.bonusType == 3) then 
			eff.doBonus(self, eff.spellweavePower)
		end
	end,
}

newEffect{
	name = "KAM_SPELLWEAVER_SHIELD_PHANTASMAL", 
	image = "talents/rune__shielding.png",
	desc = _t"Spellwoven Phantasmal Shield",
	long_desc = function(self, eff)
		return ([[You are surrounded by a Phantasmal shield that absorbs damage 50%% of the time. It can still absorb %d/%d damage. %s]]):format(eff.absorbLeft, eff.absorbPower, eff.bonusDescriptor)
	end,
	charges = function(self, eff) return math.ceil(eff.absorbLeft) end,
	type = "magical", 
	subtype = { shield = true },
	status = "beneficial",
	parameters = { src = src, absorbPower = 1, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end },
	on_gain = function(self, err) return _t"A Phantasmal Spellwoven shield forms around #Target#.", _t"+Phantasmal Shield" end,
	on_lose = function(self, err) return _t"#Target#'s Phantasmal Spellwoven shield fades away.", _t"-Phantasmal Shield" end,
	damage_feedback = function(self, eff, src, value)
		if eff.particle and eff.particle._shader and eff.particle._shader.shad and src and src.x and src.y then
			local r = -rng.float(0.2, 0.4)
			local a = math.atan2(src.y - self.y, src.x - self.x)
			eff.particle._shader:setUniform("impact", {math.cos(a) * r, math.sin(a) * r})
			eff.particle._shader:setUniform("impact_tick", core.game.getTime())
		end
	end,
	activate = function(self, eff)
		eff.absorbPower = eff.absorbPower
		eff.absorbLeft = eff.absorbPower
		eff.dur = eff.dur
		if core.shader.active(4) then
			eff.particle = self:addParticles(Particles.new("shader_shield", 1, {img=eff.image or "shield7"}, {type="shield", shieldIntensity=eff.shield_intensity or 0.2, color=eff.color or {0.4, 0.7, 1.0}}))
		else
			eff.particle = self:addParticles(Particles.new("damage_shield", 1))
		end
		if (eff.bonusType == 5) then 
			eff.doBonus(self, eff.spellweavePower, eff, false)
		end
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
		if (eff.bonusType == 1) or (eff.bonusType == 5) then 
			eff.doBonus(self, eff.spellweavePower, eff, true)
		end
	end,
	callbackOnHit = function(self, eff, cb, src)		
		if cb.value > 0 then 
			if rng.percent(50) then
				local damageToShield = cb.value
				if src and src.attr and src:attr("damage_shield_penetrate") then
					damageToShield = cb.value * (1 - (util.bound(src.damage_shield_penetrate, 0, 100) / 100))
				end
				local damageToShield = math.min(eff.absorbLeft, damageToShield)
				eff.absorbLeft = eff.absorbLeft - damageToShield
				cb.value = cb.value - damageToShield
				game:delayedLogDamage(src, self, 0, ("#SLATE#(%d absorbed)#LAST#"):tformat(damageToShield), false)
			end
			
			if (eff.bonusType == 2) then 
				local a = game.level.map(src.x, src.y, Map.ACTOR)
				if a and self:reactionToward(a) < 0 then 
					eff.doBonus(self, eff.spellweavePower, a, damageToShield, eff.argsTable)
				end
			end
			if (eff.bonusType == 4) then
				eff.doBonus(self, eff.spellweavePower, damageToShield)
			end
			
			if eff.absorbLeft <= 0 then 
				self:removeEffect(eff.effect_id)
			end
			return true
		end
	end,
	on_timeout = function(self, eff)
		if (eff.bonusType == 3) then 
			eff.doBonus(self, eff.spellweavePower)
		end
	end,
}