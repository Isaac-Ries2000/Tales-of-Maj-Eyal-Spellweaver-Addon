local Map = require "engine.Map"
local Object = require "mod.class.Object"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "spellweaving/shield-modes", is_spell = true, name = _t("shield-modes", "talent type"), description = _t"Methods of creating defensive shields." }

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

-- Calculates shield power, using any necessary modifiers.
local function getShieldPower(self, t, modifier, givenPowerMod)
	local absorb = 0
	if self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_CORE) then
		local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_SHIELDS_CORE)
		absorb = tal.getMaxAbsorb(self, tal)
		local powerMod = 1
		if t and t.getPowerMod then 
			powerMod = t.getPowerMod(self, t)
		elseif givenPowerMod then 
			powerMod = givenPowerMod
		end
		absorb = absorb * modifier * powerMod
		-- If any kind of shield multiplier values are added, they go here.
	end
	return self:getShieldAmount(math.max(absorb, 1)) -- Min power is one.
end

-- Calculates shield duration, using any necessary modifiers.
local function getShieldDuration(self, t, modifier, givenPowerMod)
	local duration = 0
	if self:knowTalent(self.T_KAM_SPELLWEAVER_SHIELDS_CORE) then 
		local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_SHIELDS_CORE)
		duration = tal.getDuration(self, tal)
		local powerMod = 1
		if t and t.getPowerMod then 
			powerMod = t.getPowerMod(self, t)
		elseif givenPowerMod then 
			powerMod = givenPowerMod
		end
		duration = duration * modifier * ((1 - powerMod)/2 + powerMod)
		-- If any kind of shield multiplier values are added, they go here.
	end
	return self:getShieldDuration(math.max(duration, 1)) -- Shields must have a duration, then apply Ethereal Embrace.
end

local function beforeShieldTrigger(self, t)
	if t.isKamElementRandom then -- Pick a random element the player knows.
		local elements = {}
		for _, talent in pairs(self.talents_def) do
			if self:knowTalent(talent) then
				local talentTable = self:getTalentFromId(talent)
				if talentTable.isKamElement and not (talentTable.isKamDuo or talentTable.isKamPrismatic or talentTable.isKamElementRandom) then
					elements[#elements+1] = talentTable
				end
			end
		end
		game.state.kam_spellweaver_random_element = rng.table(elements)
	end
end

newTalent{
	name = "Basic Shield",
	short_name = "KAM_SHIELDMODE_BASIC",
	image = "talents/rune__shielding.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	mode = "passive",
	getModeName = "Shield",
	no_npc_use = true,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 1)
		local duration = getShieldDuration(self, t, 1)
		beforeShieldTrigger(self, t)
		self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_BASIC, duration, {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
		game:playSoundNear(self, "talents/spell_generic")
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Create a basic damage shield with the base %d shield power and base %d turn duration unmodified. Spellweave Multiplier: 1.]]):tformat(getShieldPower(self, nil, 1, t.getPowerModMode(self, t)), getShieldDuration(self, nil, 1, t.getPowerModMode(self, t)))
	end,
	getModeDescriptor = function(self, t)
		return ([[Create a basic damage shield that absorbs %d damage and lasts for %d turns.]]):tformat(getShieldPower(self, t, 1), getShieldDuration(self, t, 1))
	end,
}

newTalent{
	name = "Shielding Wave",
	short_name = "KAM_SHIELDMODE_AREA",
	image = "talents/shielding.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	mode = "passive",
	getModeName = "Shielding Wave",
	no_npc_use = true,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 1)
		local duration = getShieldDuration(self, t, 1)
		
		local tg = {type="ball", range = 0, radius = 3, friendlyfire=true, selffire=true, talent=t}
		beforeShieldTrigger(self, t)
		
		self:project(tg, self.x, self.y, function(px, py, tg, self)
			local target = game.level.map(px, py, Map.ACTOR)
			if target and self:reactionToward(target) > 0 then 
				target:setEffect(target.EFF_KAM_SPELLWEAVER_SHIELD_MULTI, duration, {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
			end
		end)
		game:playSoundNear(self, "talents/spell_generic")
	end,
	getPowerModMode = function(self, t)
		return 0.85 -- This comes up rarely, but it is really handy for like escort quests.
	end,
	info = function(self, t)
		return ([[You and all allies in range 3 gain a damage shield with the base %d shield power and base %d turn duration unmodified. Spellweave Multiplier: %0.2f.]]):tformat(getShieldPower(self, nil, 1, t.getPowerModMode(self, t)), getShieldDuration(self, nil, 1, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		return ([[You and all allies in range 3 gain a damage shield that absorbs %d damage and lasts for %d turns.]]):tformat(getShieldPower(self, t, 1), getShieldDuration(self, t, 1))
	end,
}

newTalent{
	name = "Slag Shield",
	short_name = "KAM_SHIELDMODE_SUSTAINED",
	image = "talents/pyrokinesis.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	mode = "passive",
	getModeName = "Slag Shield",
	no_npc_use = true,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 1)
		return absorbPower
	end,
	getPowerModMode = function(self, t)
		return 0.6 -- It restores itself and is always active. 
	end,
	info = function(self, t)
		return ([[The shield becomes a sustain with sustained mana cost 25 and a 30 turn cooldown. The shield has a low spellweave power, but is constantly active (with %d absorption power) and regains 4%% of shield power each turn in combat (and 10%% out of combat). Additionally, unlike normal Spellwoven shields, these can stack with other Slag Shields.
If the shield reaches 0 absorption power, it will not be removed and bonus effects that trigger from a shield breaking will be applied, but they will not apply again until the shield is fully repaired, and any bonus effects that trigger on being hit or as long as the shield is active will have their power reduced by 50%%.
Spellweave Multiplier: %0.1f.]]):tformat(getShieldPower(self, nil, 1, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		local text = [[]]
		if t.bonusType == 1 then 
			text = ([[
The bonus effect will trigger when the shield hits 0 absorption power, but will not trigger again until the shield has fully repaired.]]):tformat()
		elseif t.bonusType == 2 then
			text = ([[
The bonus effect will trigger each time the shield is hit, but its effective Spellweave Multiplier will be halved if the shield has broken and not yet fully repaired.]]):tformat()
		elseif t.bonusType == 3 then 
			text = ([[
The bonus effect will remain constantly active, but if the shield's absorption power hits 0, its effective Spellweave Multiplier will be halved until the shield fully regains all absorption power.]]):tformat()
		end
		local text2
		local absorb
		local p = self:isTalentActive(t.id)
		if p then
			local currentAbsorb = p.absorb or 0
			absorb = p.maxAbsorb or 0
			text2 = ([[%d/%d]]):tformat(currentAbsorb, absorb)
		else 
			absorb = getShieldPower(self, t, 1)
			text2 = ([[%d]]):tformat(absorb)
		end
		return ([[Gain a damage shield that absorbs %s damage and regains 4%% each turn in combat (%d restored) and 10%% outside of combat (%d restored).%s]]):tformat(text2, absorb*0.04, absorb*0.1, text)
	end,
}

newTalent{
	name = "Contingency Shield",
	short_name = "KAM_SHIELDMODE_CONTINGENCY",
	image = "talents/quicken_spells.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	isKamSustainShield = true,
	mode = "passive",
	getModeName = "Contingency Shield",
	no_npc_use = true,
	health_threshold = 30,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 1)
		local duration = getShieldDuration(self, t, 1)
		beforeShieldTrigger(self, t)
		self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_CONTINGENT, duration, {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
		game:playSoundNear(self, "talents/spell_generic")
	end,
	getPowerModMode = function(self, t)
		return 0.8 -- It takes no time to activate and triggers when something happens unexpectedly, but you also can't use it when you want to.
	end,
	info = function(self, t)
		return ([[The shield becomes a sustain with sustained mana cost 25 that triggers when you recieve damage that would reduce your health to below %d%% of your max life, instantly granting you a shield with base %d shield power and base %d turn duration. This can only apply at most every 20 turns. Spellweave Multiplier: %0.1f.]]):tformat(t.health_threshold, getShieldPower(self, nil, 1, t.getPowerModMode(self, t)), getShieldDuration(self, nil, 1, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		local tal = self:getTalentFromId(self.T_KAM_SHIELDMODE_CONTINGENCY)
		local threshold = tal.health_threshold
		local cooldown = 0
		local p = self:isTalentActive(t.id)
		if p then
			cooldown = p.cooldown
		end
		return ([[When you recieve damage that would reduce your health to below %d%% of your max life, instantly gain a shield with base %d absorption power and %d duration. This can only trigger at most every 20 turns. Current cooldown: %d).]]):tformat(threshold, getShieldPower(self, t, 1), getShieldDuration(self, t, 1), cooldown)
	end,
}

newTalent{
	name = "Perfect Block",
	short_name = "KAM_SHIELDMODE_ONETURN",
	image = "talents/final_sunbeam.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	speedMod = 0.5, -- This gives a TON of shields, so no doing it too speedily.
	mode = "passive",
	getModeName = "Perfect Block",
	no_npc_use = true,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 7)
		beforeShieldTrigger(self, t) 
		-- NOTE: This checks getShieldDuration so that Ethereal Embrace adds 1 turn. If stuff that generically extends shields is added, this may need to be removed, as I want that to be a fun bonus interaction, not a weird extending strategy.
		self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_ONETURN, self:getShieldDuration(1), {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
		game:playSoundNear(self, "talents/spell_generic")
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Create an incredibly powerful damage shield with the %d shield power, but that only lasts for a single turn. The power of this shield also takes more energy to form, so the time to use it is increased by half a turn. Spellweave Multiplier: 1.]]):tformat(getShieldPower(self, nil, 7, t.getPowerModMode(self, t)))
	end,
	getModeDescriptor = function(self, t)
		return ([[Create an incredibly powerful shield that blocks %d damage but only lasts for one turn. The time it takes to use is half a turn longer than normal shields.]]):tformat(getShieldPower(self, t, 7))
	end,
}

newTalent{
	name = "Dispersing Shield",
	short_name = "KAM_SHIELDMODE_DISPERSE",
	image = "talents/shield_discipline.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	mode = "passive",
	getModeName = "Dispersing Shield",
	no_npc_use = true,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 1)
		local duration = getShieldDuration(self, t, 1)
		beforeShieldTrigger(self, t)
		self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_DISPERSING, duration, {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
		game:playSoundNear(self, "talents/spell_generic")
	end,
	getPowerModMode = function(self, t)
		return 1.25
	end,
	info = function(self, t)
		return ([[Create a damage shield that disperses damage, absorbing up to 100 damage per attack, with a %d shield power and %d turn duration. Spellweave Multiplier: %0.2f.]]):tformat(getShieldPower(self, nil, 1, t.getPowerModMode(self, t)), getShieldDuration(self, nil, 1, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		return ([[Create a damage shield that disperses damage, absorbing up to 100 damage per attack, with a %d shield power and %d turn duration.]]):tformat(getShieldPower(self, t, 1), getShieldDuration(self, t, 1))
	end,
}

newTalent{
	name = "Phantasmal Shield",
	short_name = "KAM_SHIELDMODE_CHANCEY",
	image = "talents/phantasmal_shield.png",
	type = {"spellweaving/shield-modes", 1},
	points = 1,
	isKamShieldMode = true,
	mode = "passive",
	getModeName = "Phantasmal Shield",
	no_npc_use = true,
	getShieldFunction = function(self, t)
		local absorbPower = getShieldPower(self, t, 1)
		local duration = getShieldDuration(self, t, 1)
		beforeShieldTrigger(self, t)
		self:setEffect(self.EFF_KAM_SPELLWEAVER_SHIELD_PHANTASMAL, duration, {absorbPower=absorbPower, bonusType = t.bonusType, bonusDescriptor = t.getBonusDescriptor(self, t), spellweavePower = t.getPowerMod(self, t), doBonus = t.doBonus, argsTable = KamCalc:buildShieldArgsTableElement(self, t, 1)})
		game:playSoundNear(self, "talents/spell_generic")
	end,
	getPowerModMode = function(self, t) -- This is unreliable, but powerful.
		return 1.4
	end,
	info = function(self, t)
		return ([[Create a phantasmal damage shield that only blocks attacks half the time, with base %d shield power and base %d turn duration. On hit bonus effects will trigger regardless of whether damage is blocked or not. Spellweave Multiplier: %0.1f.]]):tformat(getShieldPower(self, nil, 1, t.getPowerModMode(self, t)), getShieldDuration(self, nil, 1, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		return ([[Create a phantasmal damage shield that only blocks attacks half the time, with base %d shield power and base %d turn duration. On hit bonus effects will trigger regardless of whether damage is blocked or not.]]):tformat(getShieldPower(self, t, 1), getShieldDuration(self, t, 1))
	end,
}