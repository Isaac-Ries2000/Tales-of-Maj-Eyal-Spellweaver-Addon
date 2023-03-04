-- local Map = require "engine.Map" -- This needs to be placed in functions as needed to prevent Wormhole upvalues.
local Object = require "mod.class.Object"
newTalentType{ type = "spellweaving/teleport-bonuses", is_spell = true, name = _t("teleport-bonuses", "talent type"), description = _t"Additional effects you can grant your teleportation spells." }

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

local function getDamTypeManager(self, t)
	if (t.isKamDuo) then 
		return DamageType.KAM_SPELLWEAVE_DUO_MANAGER
	else 
		return DamageType.KAM_SPELLWEAVE_MANAGER
	end
end

-- Modified version of the one from kam_modes
local function buildArgsTableElement(self, t, argsTable, allMod)
	argsTable.src = self
	argsTable.talent = t
	local critStatus = self:spellCrit(1) -- It all crits together or nothing crits. Otherwise you end up with critting so many times.
	if not (t.isKamDuo) then
		argsTable.element = t.getElement(self, t)
		argsTable.second = t.getSecond(self, t)
		argsTable.elementInfo = t.getSpellElementInfo
		argsTable.status = t.getSecond(self, t)
		argsTable.dam = critStatus * t.getElementDamage(self, t) * t.getPowerMod(self, t) * allMod
		argsTable.statusChance = t.getStatusChance(self, t) * t.getPowerMod(self, t) * allMod
	else 
		argsTable.element11 = t.getElement1(self, t)
		argsTable.element12 = t.getElement2(self, t)
		argsTable.second11 = t.getSecond1(self, t)
		argsTable.second12 = t.getSecond2(self, t)
		argsTable.elementInfo11 = t.getSpellElementInfo1
		argsTable.elementInfo12 = t.getSpellElementInfo2
		argsTable.status11 = t.getSecond1(self, t)
		argsTable.status12 = t.getSecond2(self, t)
		argsTable.dam11 = critStatus * t.getElementDamage1(self, t) * t.getPowerMod(self, t) * allMod
		argsTable.statusChance11 = t.getStatusChance1(self, t) * t.getPowerMod(self, t) * allMod
		argsTable.dam12 = critStatus * t.getElementDamage2(self, t) * t.getPowerMod(self, t) * allMod
		argsTable.statusChance12 = t.getStatusChance2(self, t) * t.getPowerMod(self, t) * allMod
	end
end

newTalent{
	name = "None",
	short_name = "KAM_WARPBONUS_NONE",
	image = "talents/arcane_power.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	mode = "passive",
	getBonusName = "",
	no_npc_use = true,
	bonusType = 0,
	doBonus = function() end,
	getPowerModBonus = function(self, t)
		return 1.2
	end,
	info = function(self, t)
		return ([[The teleport will gain no additional effects. Spellweave Multiplier: 1.2.]])
	end,
	getBonusDescriptor = function(self, t) -- No description needed.
		return ([[]]):tformat()
	end,
}

newTalent{
	name = "Phasing",
	short_name = "KAM_WARPBONUS_PHASE",
	image = "talents/phase_shift.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	mode = "passive",
	getBonusName = "Phasing ",
	no_npc_use = true,
	bonusType = 1,
	doBonus = function(self, t, _, _, _, target, spellweavePowerMod)
		local powerMod = spellweavePowerMod or 1
		local target = target or self
		target:setEffect(self.EFF_KAM_SPELLWOVEN_PHASING, 3, {src=self, power = t.bonusAssociatedFunction(self, t) * powerMod})
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	bonusAssociatedFunction = function(self, t)
		local spellweavePower = 1
		if t then 
			spellweavePower = t.getPowerMod(self, t)
		end
		return 15 * spellweavePower
	end,
	info = function(self, t)
		return ([[At the end of the teleport, gain Spellwoven Phasing, which increases defense by %d, all resist by %d%%, and reduces the duration of new effects by %d%% for 3 turns. The power of the effect is multiplied by Spellweave Multiplier. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self), t.bonusAssociatedFunction(self), t.bonusAssociatedFunction(self))
	end,
	getBonusDescriptor = function(self, t)
		return ([[At the end of the teleport, also gain Spellwoven Phasing, which increases defense by %d, all resist by %d%%, and reduces the duration of new effects by %d%% for 3 turns.]]):tformat(t.bonusAssociatedFunction(self, t), t.bonusAssociatedFunction(self, t), t.bonusAssociatedFunction(self, t))
	end,
}

newTalent{
	name = "Pulse",
	short_name = "KAM_WARPBONUS_PULSE",
	image = "talents/phase_pulse.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	kamRequiresElement = true,
	replaceParticles = true,
	mode = "passive",
	getBonusName = "Pulsing ",
	no_npc_use = true,
	bonusType = 3, -- Before and after.
	getElementDamageMod = 1/3,
	doBonus = function(self, t, atEnd, inputX, inputY, target, spellweavePowerMod)
		local powerMod = spellweavePowerMod or 1
		local target = target or self
		local x = inputX or target.x
		local y = inputY or target.y
		local tg = {type="ball", range=0, radius=1 + atEnd, talent=t, friendlyfire = false, pass_terrain = false}
		local argsTable = {}
		buildArgsTableElement(self, t, argsTable, 1/3 * powerMod)
		self:project(tg, x, y, getDamTypeManager(self, t), argsTable, nil)
		local particleList = {tx=x, ty=y, radius=1 + atEnd}
		if (t.isKamDuo) then
			particleList.density = 0.5
			t.getElementColors1(self, particleList, t)
			game.level.map:particleEmitter(x, y, 1 + atEnd, "kam_spellweaver_ball_physical", particleList)
			particleList = {tx=x, ty=y, radius=1 + atEnd, density = 0.5}
			t.getElementColors2(self, particleList, t)
			game.level.map:particleEmitter(x, y, 1 + atEnd, "kam_spellweaver_ball_physical", particleList)
			
		else
			t.getElementColors(self, particleList, t)
			game.level.map:particleEmitter(x, y, 1 + atEnd, "kam_spellweaver_ball_physical", particleList)
		end
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	bonusAssociatedFunction = function(self, t)
		local spellweavePower = 1
		if t then 
			spellweavePower = t.getPowerMod(self, t)
		end
		if t.isKamDuo then 
			return t.getElementDamage1(self, t) * spellweavePower / 6, t.getElementDamage2(self, t) * spellweavePower / 6
		else 
			return t.getElementDamage(self, t) * spellweavePower / 3
		end
	end,
	info = function(self, t)
		return ([[Before the teleport, deal low damage to any enemies in radius one (normal element damage divided by three). At the end of the teleport, deal that damage again in radius two. The power of the effect is multiplied by Spellweave Multiplier, and you can choose the element of the damage from your unlocked elements (inflicting status effects as the element would normally). Spellweave Multiplier: 1.]]):tformat()
	end,
	getBonusDescriptor = function(self, t)
		local elementDescriptor
		if t.isKamDuo then 
			local damage1, damage2 = t.bonusAssociatedFunction(self, t)
			elementDescriptor = ([[%d %s and %d %s]]):tformat(self:damDesc(t.getElement1(self, t), damage1), DamageType:get(t.getElement1(self, t)).name:capitalize(), self:damDesc(t.getElement2(self, t), damage2), DamageType:get(t.getElement2(self, t)).name:capitalize())
		else 
			local damage = t.bonusAssociatedFunction(self, t)
			elementDescriptor = ([[%d %s]]):tformat(self:damDesc(t.getElement(self, t), damage), DamageType:get(t.getElement(self, t)).name:capitalize())
		end
		return ([[Before the teleport, deal %s damage to any enemies in radius one. At the end of the teleport, deal %s damage again in radius two. %s.]]):tformat(elementDescriptor, elementDescriptor, t.getSpellStatusInflict(self, t))
	end,
}

newTalent{
	name = "Restoration",
	short_name = "KAM_WARPBONUS_RESTORATION",
	image = "talents/regeneration.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	mode = "passive",
	getBonusName = "Restoring ",
	no_npc_use = true,
	bonusType = 1,
	doBonus = function(self, t, _, _, _, target, spellweavePowerMod)
		local powerMod = spellweavePowerMod or 1
		local target = target or self -- Heal your enemies, I don't care.
		target:setEffect(self.EFF_KAM_SPELLWOVEN_REGENERATION, 5, {src = self, power = t.bonusAssociatedFunction(self, t)/5 * powerMod})
		if core.shader.active(4) then
			target:addParticles(Particles.new("shader_shield_temp", 1, {toback=true , size_factor=1.5, y=-0.3, img="healarcane", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=2.0, beamColor1={0x8e/255, 0x2f/255, 0xbb/255, 1}, beamColor2={0xe7/255, 0x39/255, 0xde/255, 1}, circleDescendSpeed=4}))
			target:addParticles(Particles.new("shader_shield_temp", 1, {toback=false, size_factor=1.5, y=-0.3, img="healarcane", life=25}, {type="healing", time_factor=2000, beamsCount=20, noup=1.0, beamColor1={0x8e/255, 0x2f/255, 0xbb/255, 1}, beamColor2={0xe7/255, 0x39/255, 0xde/255, 1}, circleDescendSpeed=4}))
		end
		game:playSoundNear(target, "talents/heal")
		return true
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	bonusAssociatedFunction = function(self, t) -- Pretty weak healing, but it's a bonus effect and can be multiplied so.
		local spellweavePower = 1
		if t then 
			spellweavePower = t.getPowerMod(self, t)
		end
		return 20 + self:combatStatLimit("mag", 400, 10, 300) * spellweavePower
	end,
	info = function(self, t)
		return ([[Gain the Spellwoven Regeneration effect that heals %d life over for 5 turns at the end of the teleport. This effect will not stack, and if a new effect is applied, the one with the greatest amount of healing left will be kept. Healing per turn is multiplied by Spellweave Multiplier. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	getBonusDescriptor = function(self, t)
		return ([[After the teleport, gain the Spellwoven Regeneration effect that heals %d life over 5 turns. This effect does not stack, and if another is applied, the one with the greatest amount of healing remaining will be kept.]]):tformat(t.bonusAssociatedFunction(self, t))
	end,
}

newTalent{
	name = "Trick",
	short_name = "KAM_WARPBONUS_TRICK",
	image = "talents/gloom.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	mode = "passive",
	getBonusName = "Tricky ",
	no_npc_use = true,
	bonusType = 2,
	doBonus = function(self, t, _, inputX, inputY, target, spellweavePowerMod)
		local powerMod = spellweavePowerMod or 1
		local target = target or self
		local x = inputX or target.x
		local y = inputY or target.y
		local tg = {type = "ball", range = 0, radius = 2, talent = t, friendlyfire = false, kam_powerMod = powerMod}
		self:project(tg, x, y, function(px, py, tg, self)
			local Map = require "engine.Map"
			local target = game.level.map(px, py, Map.ACTOR)
			if target then 
				local effectPower = tg.talent.bonusAssociatedFunction(self, tg.talent) * tg.kam_powerMod
				target:setEffect(target.EFF_KAM_SPELLWOVEN_TRICK, 3, {src=src, damReduce = effectPower, damIncrease = effectPower / 1.5})
			end
		end)
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	bonusAssociatedFunction = function(self, t)
		local spellweavePower = 1
		if t then 
			spellweavePower = t.getPowerMod(self, t)
		end
		return (15 + self:combatStatLimit("mag", 15, 0, 10)) * spellweavePower
	end,
	info = function(self, t)
		return ([[Through confusing movement, Trick all enemies in radius 2 before the teleport, reducing their damage dealt by %d%% and increasing their damage recieved by %d%% for 3 turns. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self), t.bonusAssociatedFunction(self)/1.5)
	end,
	getBonusDescriptor = function(self, t)
		return ([[Through confusing movement, Trick all enemies in radius 2 before the teleport, reducing their damage dealt by %d%% and increasing their damage recieved by %d%% for 3 turns.]]):tformat(t.bonusAssociatedFunction(self, t), t.bonusAssociatedFunction(self, t) / 1.5)
	end,
}

newTalent{
	name = "Illusions",
	short_name = "KAM_WARPBONUS_MIRRORIMAGE",
	image = "talents/forgery_of_haze.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	mode = "passive",
	getBonusName = "Illusory ",
	no_npc_use = true,
	bonusType = 3,
	getInheritedResist = function(self, t)
		local res = {}
		for k,v in pairs(self.resists) do
			res[k] = ((self.resists[k]) or 0)
		end
		return res
	end,
	doBonus = function(self, t, atEnd, inputX, inputY, _, spellweavePowerMod)
		if atEnd == 0 then -- Store x and y positions so that they are free.
			self.kamMirrorImagePositionStoreLevel = game.level
			self.kamMirrorImagePositionStoreX = self.x
			self.kamMirrorImagePositionStoreY = self.y
		else 
			-- Substantial portion of talent directly from Rune: Mirror Image.
			local Map = require "engine.Map"
			if self.kamMirrorImagePositionStoreLevel == game.level and self.kamMirrorImagePositionStoreX and self.kamMirrorImagePositionStoreY then
				local tx, ty = util.findFreeGrid(self.kamMirrorImagePositionStoreX, self.kamMirrorImagePositionStoreY, 3, true, {[Map.ACTOR]=true})
				if tx then
					local Talents = require "engine.interface.ActorTalents"
					local NPC = require "mod.class.NPC"
					local caster = self
					local tal = self:getTalentFromId(self.T_KAM_WARPBONUS_MIRRORIMAGE)
					local image = NPC.new{
						name = _t"Spellwoven Simulacrum",
						type = "spellwoven", subtype = "image",
						ai = "summoned", ai_real = nil, ai_state = { talent_in=1, }, ai_target = {actor=nil},
						desc = _t"An arcane image.",
						image = caster.image,
						add_mos = table.clone(caster.add_mos, true),
						shader = "shadow_simulacrum", shader_args = { color = {0.8, 0.2, 0.8}, base = 0.6, time_factor = 1500 },
						exp_worth=0,
						max_life = caster.max_life * 0.5 * t.getPowerMod(self, t),
						life = caster.max_life * 0.5 * t.getPowerMod(self, t), -- A fair bit weaker than the normal, but it comes with a teleport so.
						combat_armor_hardiness = caster:combatArmorHardiness(),
						combat_def = caster:combatDefense(),
						combat_armor = caster:combatArmor(),
						size_category = caster.size_category,
						resists = tal.getInheritedResist(self, tal),
						rank = 1,
						life_rating = 0,
						cant_be_moved = 1,
						never_move = 1,
						never_anger = true,
						resolvers.talents{
							[Talents.T_TAUNT]=1, -- Add the talent so the player can see it even though we cast it manually
						},
						on_act = function(self) -- avoid any interaction with .. uh, anything
							self:forceUseTalent(self.T_TAUNT, {ignore_cd=true, no_talent_fail = true})
						end,
						faction = caster.faction,
						summoner = caster,
						summon_time=t.bonusAssociatedFunction(self, t),
						no_breath = 1,
						remove_from_party_on_death = true,
					}

					image:resolve()
					game.zone:addEntity(game.level, image, "actor", tx, ty)
					if game.party:hasMember(self) then
						game.party:addMember(image, {
							control=false,
							type="summon",
							title=_t"Summon",
							temporary_level = true,
							orders = {},
						})
					end

					image:forceUseTalent(image.T_TAUNT, {ignore_cd=true, no_talent_fail = true})
				end
			end
			self.kamMirrorImagePositionStoreX = nil
			self.kamMirrorImagePositionStoreY = nil
			self.kamMirrorImagePositionStoreLevel = nil
		end
		return true
	end,
	getPowerModBonus = function(self, t)
		return 0.8
	end,
	bonusAssociatedFunction = function(self, t)
		local spellweavePower = 1
		if t then 
			spellweavePower = t.getPowerMod(self, t)
		end
		return math.floor(7 * spellweavePower + 0.5)
	end,
	info = function(self, t)
		return ([[Through illusions of light and dark, leave a Spellwoven Simulacrum behind when you teleport. It has life equal to half your max life times Spellweave Multiplier and inherits all of your resistance, armor, defense, and armor hardiness, and lasts for a base %d turns (multiplied by Spellweave Multiplier, rounding to the nearest turn). Additionally, it taunts targets to distract them. Spellweave Multiplier: %d.]]):tformat(t.bonusAssociatedFunction(self), t.getPowerModBonus())
	end,
	getBonusDescriptor = function(self, t) 
		return ([[Through illusions of light and dark, leave a Spellwoven Simulacrum behind when you teleport. It has life equal to %d%% of your max life and inherits all of your resistance, armor, defense, and armor hardiness and lasts for %d turns. Additionally, it taunts targets to distract them.]]):tformat(t.getPowerMod(self, t) * 50, t.bonusAssociatedFunction(self, t))
	end,
}

newTalent{ -- For a funny combo, combine with lightning speed or molten path.
	name = "Voidstepping",
	short_name = "KAM_WARPBONUS_VOIDSTEPPING",
	image = "talents/rune__speed.png",
	type = {"spellweaving/teleport-bonuses", 1},
	points = 1,
	isKamTeleportBonus = true,
	mode = "passive",
	getBonusName = "Voidstepping ",
	no_npc_use = true,
	bonusType = 1,
	doBonus = function(self, t, _, _, _, target, spellweavePowerMod)
		local powerMod = spellweavePowerMod or 1
		local target = target or self
		target:setEffect(self.EFF_KAM_SPELLWOVEN_VOIDSTEPPING, 2, {src=self, movespeed = t.bonusAssociatedFunction(self, t) * powerMod})
	end,
	getPowerModBonus = function(self, t)
		return 1
	end,
	bonusAssociatedFunction = function(self, t)
		local spellweavePower = 1
		if t then 
			spellweavePower = t.getPowerMod(self, t)
		end
		return 100 * spellweavePower
	end,
	info = function(self, t)
		return ([[At the end of the teleport, gain Voidstepping, increasing movement speed by %d%% (multiplied by Spellweave Multiplier) for 2 turns and allowing you to run through walls of thickness up to 3, instantly teleporting you to the other side. Moving through walls with this effect has a cooldown equal to the number of tiles moved through. Spellweave Multiplier: 1.]]):tformat(t.bonusAssociatedFunction(self))
	end,
	getBonusDescriptor = function(self, t)
		return ([[At the end of the teleport, gain Voidstepping, increasing movement speed by %d%% for 2 turns and allowing you to run through walls of thickness up to 3, instantly teleporting you to the other side. Moving through walls with this effect has a cooldown equal to the number of tiles moved through.]]):tformat(t.bonusAssociatedFunction(self, t))
	end,
}