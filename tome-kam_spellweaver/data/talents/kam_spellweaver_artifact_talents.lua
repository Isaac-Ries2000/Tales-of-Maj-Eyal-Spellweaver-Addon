
newTalent{
	name = "Weave Shield",
	short_name = "KAM_SPELLWEAVER_TEACHING_LOOM_SKILL",
	type = {"spell/objects",1},
	image = "talents/kam_spellweaver_practiced_motions.png",
	points = 1,
	mana = 0,
	cooldown = 20,
	tactical = { DEFEND = 2 },
	range = 10,
	getShield = function(self, t)
		return 150 + 2 * self:getMag(100) -- Based on mirror shards
	end,
	getShieldDuration = function(self, t)
		return 6
	end,
	action = function(self, t)
		local shieldmode = rng.range(1, 4)
		local absorbPower = t.getShield(self, t)
		local duration = t.getShieldDuration(self, t)
		if shieldmode == 1 then
			absorbPower = absorbPower * 7
			self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_ONETURN, 1, {absorbPower=absorbPower, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end})
		elseif shieldmode == 2 then
			self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_BASIC, self:getShieldDuration(duration), {absorbPower=absorbPower, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end})		
		elseif shieldmode == 3 then
			absorbPower = absorbPower * 1.4
			duration = duration * 1.4
			self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_PHANTASMAL, self:getShieldDuration(duration), {absorbPower=absorbPower, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end})		
		else
			absorbPower = absorbPower * 1.25
			duration = duration * 1.25
			self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_DISPERSING, self:getShieldDuration(duration), {absorbPower=absorbPower, bonusType = 0, bonusDescriptor = "", spellweavePower = 1, doBonus = function() end})		
		end
		return true
	end,
	info = function(self, t)
		return ([[By focusing through the frame loom, create a basic shield.
Generate a damage shield of one of four Spellwoven shield types, with %d base power and %d duration modified by the shield type:
Basic: Normal damage shield with no effects. 100%% power.
Phantasmal: Only absorbs damage 50%% of the time. 140%% power.
Dispersing: Only absorbs 100 damage from each damage instance. 125%% power.
Perfect Block: Only lasts 1 turn. 700%% power.
Shield power scales with Magic.]]):
		tformat(t.getShield(self, t), t.getShieldDuration(self, t))
	end,
}

newTalent{
	name = "Nullification Fist",
	short_name = "KAM_SPELLWEAVER_NULLIFICATION_SLAM",
	type = {"spell/objects",1},
	image = "talents/kam_spellweaver_nullfication_fist.png",
	points = 1,
	mana = 0,
	cooldown = 20,
	tactical = { ATTACK = { weapon = 1}, DISABLE = 2},
	target = function(self, t) return {type="hit", range=self:getTalentRange(t)} end,
	range = 1,
	requires_target = true,
	is_melee = true,
	getDamage = function(self, t) return 1.3 end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not target or not self:canProject(tg, x, y) then return nil end

		local hit = self:attackTarget(target, nil, t.getDamage(self, t), true)
		
		if hit then target:setEffect(target.EFF_KAM_ELEMENTAL_NULLIFICATION, 4, {}) end
		
		return true
	end,
	info = function(self, t)
		return ([[Punch an enemy with the Gloves of the Woven Elementalist, attempting to sever their connection to the elements.
Hit the target for %d%% unarmed damage. On a successful hit, sever the target's connection to the elements for 4 turns, reducing their damage by 30%% and converting it into elementless damage that ignores elemental damage increases and resistances. Note that some enemies already convert their damage types for melee and will not have their damage converted, but will still lose 30%% of their damage.]]):
		tformat(t.getDamage(self, t))
	end,
}
