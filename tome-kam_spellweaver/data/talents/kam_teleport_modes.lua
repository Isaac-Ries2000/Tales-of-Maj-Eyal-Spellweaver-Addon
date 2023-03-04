local Map = require "engine.Map"
local Object = require "mod.class.Object"
newTalentType{ type = "spellweaving/teleportation-modes", is_spell = true, name = _t("teleportation-modes", "talent type"), description = _t"Methods of magical traversal." }

-- Unused ideas: Hurricane teleport: Teleports all nearby targets (including or not including you?)
--				 Phantasmal: Gain wall walking.

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

-- Calculates teleport range, using any necessary modifiers.
local function getTeleportRange(self, t, modifier, givenPowerMod)
	local range = 0
	if self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_CORE) then
		local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_WARP_CORE)
		range = tal.getRange(self, tal)
	end
	local powerMod = 1
	if givenPowerMod then 
		powerMod = givenPowerMod
	elseif t and t.getPowerMod then 
		powerMod = t.getPowerMod(self, t)
	end
	range = range * modifier * powerMod
	-- If any kind of shield multiplier values are added, they go here.
	return math.max(range, 1) -- Min range = 1
end

-- Calculates teleport precision, using any necessary modifiers.
local function getTeleportPrecision(self, t, basePrecision, givenPowerMod)
	local precision = basePrecision
	local precisionMod = 1
	if self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_CORE) then
		local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_WARP_CORE)
		precisionMod = tal.getPrecisionMod(self, tal)
	end
	local powerMod = 1
	if givenPowerMod then 
		powerMod = givenPowerMod
	elseif t and t.getPowerMod then 
		powerMod = t.getPowerMod(self, t)
	end
	precision = basePrecision * precisionMod / powerMod
	-- If any kind of shield multiplier values are added, they go here.d
	return precision
end

-- Calculates teleport fizzle rate.
local function getTeleportFizzleRate(self, t)
	local fizzleRate = 1 -- If you've cheated this somehow, you get to fail.
	if self:knowTalent(self.T_KAM_SPELLWEAVER_WARP_CORE) then
		local tal = self:getTalentFromId(self.T_KAM_SPELLWEAVER_WARP_CORE)
		fizzleRate = tal.getTeleportFizzleRate(self, tal)
	end
	return fizzleRate
end

local function doParticles(self, t)
	if not t.replaceParticles then
		game.level.map:particleEmitter(self.x, self.y, 1, "teleport")
	end
end

local function teleportSetupStuff(self, t)
	if t.isKamElementRandom then -- Pick a random element the player knows.
		local elements = {}
		for _, talent in pairs(self.talents_def) do
			if self:knowTalent(talent) then
				local talentTable = self:getTalentFromId(talent)
				if talentTable.isKamElement and not (talentTable.isKamDuo or talentTable.isKamPrismatic) then
					elements[#elements+1] = talentTable
				end
			end
		end
		game.state.kam_spellweaver_random_element = rng.table(elements)
	end
end

newTalent{
	name = "Blink",
	short_name = "KAM_WARPMODE_BLINK",
	image = "talents/heightened_reflexes.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Blink",
	no_npc_use = true,
	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		local _, tx, ty

		-- A LOT of this is directly from the Blink spell in the Conveyence tree.
		local x, y = self.x, self.y
		local range = getTeleportRange(self, t, 1)
		local radius = getTeleportPrecision(self, t, 3)
		game.logPlayer(self, "Select a teleport location...")
		--copy the block_path function from the engine so that we can call it for normal block_path checks
		local old_block_path = engine.Target.defaults.block_path
		--use an adjusted block_path to check if we have a tile in LOS; display targeting in yellow if we don't so we can warn the player their spell may fizzle
		--note: we only use this if the original block_path would permit targeting 
		local tg = {type="ball", nolock=true, pass_terrain=true, nowarning=true, range=range, radius=radius, requires_knowledge=false, block_path=function(typ, lx, ly, for_highlights) if not self:hasLOS(lx, ly) and not old_block_path(typ, lx, ly, for_highlights) then return false, "unknown", true else return old_block_path(typ, lx, ly, for_highlights) end end}
		x, y = self:getTarget(tg)
		if not x then return nil end
		_, _, _, x, y = self:canProject(tg, x, y)
		if t.bonusType == 2 or t.bonusType == 3 then 
			t.doBonus(self, t, 0)
		end
		range = radius
		-- Check LOS
		local failed = false
		local failed2 = false
		if not self:hasLOS(x, y) and rng.percent((getTeleportFizzleRate(self, t)) * 100) then
			failed = true
			x, y = self.x, self.y
			range = getTeleportRange(self, t, 1)
		end

		doParticles(self, t)
		local ox, oy = self.x, self.y
		self:teleportRandom(x, y, range)
		if ox == self.x and oy == self.y then
			if not failed and range < 2 then
				range = range + 2 -- Since at high levels of precision you can get to perfect precision, expand before random teleportation in the event of a failure.
				self:teleportRandom(x, y, range)
				if ox == self.x and oy == self.y then -- Check if we failed again.
					failed2 = true
					x, y = self.x, self.y
					range = getTeleportRange(self, t, 1)
					self:teleportRandom(x, y, range)
				else
					game.logPlayer(self, "With nowhere to teleport to, the blink lands slightly outside of the expected range.")
				end
			end
		end
		if ox == self.x and oy == self.y then -- Namely for if you use it somewhere like Sher'tul fortress where everything's No Teleport.
			game.logPlayer(self, "... but there was nowhere to teleport to.")
		elseif failed then
			game.logPlayer(self, "The blink fizzles and works randomly!")
		elseif failed2 then
			game.logPlayer(self, "With nowhere nearby to land, the blink fizzles and works randomly!")
		end
		doParticles(self, t)

		game:playSoundNear(self, "talents/teleport")
		if t.bonusType == 1 or t.bonusType == 3 then 
			t.doBonus(self, t, 1)
		end
		return true
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Teleport to a location with base range %d and precision %d. This does not require line of sight%s. Spellweave Multiplier: 1.]]):tformat(getTeleportRange(self, nil, 1, t.getPowerModMode(self, t)), getTeleportPrecision(self, nil, 3, t.getPowerModMode(self, t)), fizzleText)
	end,
	getModeDescriptor = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Teleport to a location within range %d with an area of %d. This does not require line of sight%s.]]):tformat(getTeleportRange(self, t, 1), getTeleportPrecision(self, t, 3), fizzleText)
	end,
}

newTalent{ -- Similar to Archmage's teleport, but it displays the minimum range (using a method based on Nekarcos's skill Buzz Off from Odyssey of the Summoner).
	name = "Teleport",
	short_name = "KAM_WARPMODE_TELEPORT",
	image = "talents/banish.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Teleport",
	no_npc_use = true,
	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		local _, tx, ty

		local x, y = self.x, self.y
		local range = getTeleportRange(self, t, 6)
		-- This teleport checking method is based on Nekarcos's skill Buzz Off from Odyssey of the Summoner. Somewhat amusingly, I forgot that regular teleport already works that way.
		-- Although since the normal version of Teleport doesn't show the filter, this was still really good to get help from.
		local filter = function(tx, ty)
			if core.fov.distance(self.x, self.y, tx, ty) < 12 then
				return false
			end
			return true
		end
		local radius = getTeleportPrecision(self, t, 20)
		game.logPlayer(self, "Select a teleport location...")
		--copy the block_path function from the engine so that we can call it for normal block_path checks
		local old_block_path = engine.Target.defaults.block_path
		--use an adjusted block_path to check if we have a tile in LOS; display targeting in yellow if we don't so we can warn the player their spell may fizzle
		--note: we only use this if the original block_path would permit targeting 
		local tg = {type="ball", nolock=true, pass_terrain=true, nowarning=true, range=range, radius=radius, requires_knowledge=false, block_path=function(typ, lx, ly, for_highlights) if not self:hasLOS(lx, ly) and not old_block_path(typ, lx, ly, for_highlights) then return false, "unknown", true else return old_block_path(typ, lx, ly, for_highlights) end end, filter = filter}
		x, y = self:getTarget(tg)
		if not x then return nil end
		_, _, _, x, y = self:canProject(tg, x, y)
		range = radius
		-- Check LOS.
		local didFizzle = false
		if not self:hasLOS(x, y) and rng.percent((getTeleportFizzleRate(self, t)) * 100) then
			game.logPlayer(self, "The targeted teleportation fizzles and works randomly!")
			didFizzle = true
			x, y = self.x, self.y
			range = getTeleportRange(self, t, 6)
			tg.radius = range
		end

		local didRandom = false
		local try = 0 -- Try three times to see if placement is possible. This shouldn't NORMALLY be necessary but.
		while(try < 3) do
			try = try + 1
			local grids = {}
			self:project(tg, x, y, function(px, py)
				if not game.level.map:checkAllEntities(px, py, "block_move") then
					if core.fov.distance(self.x, self.y, px, py) >= 12 then
						grids[#grids+1] = {x=px, y=py}
					end
				end
			end)
			--
			if #grids > 0 then
				local grd = rng.table(grids)
				if didRandom then 
					game.log("With nowhere to teleport to, the teleportation fizzled and works randomly.")
				end
				--
				if t.bonusType == 2 or t.bonusType == 3 then 
					t.doBonus(self, t, 0)
				end
				doParticles(self, t)
				self:teleportRandom(grd.x, grd.y, 0)
				doParticles(self, t)

				game:playSoundNear(self, "talents/teleport")
				break
			else
				if not didFizzle then 
					didRandom = true
				end
				if try < 2 then 
					x, y = self.x, self.y
					range = getTeleportRange(self, t, 1)
					tg.radius = range
				else 
					game.log("There was nowhere to teleport to, so teleportation failed.")
					return false
				end
			end
		end
		
		if t.bonusType == 1 or t.bonusType == 3 then 
			t.doBonus(self, t, 1)
		end
		return true
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Teleport to a distant location with base range %d (6 times the base range) and precision %d. You cannot teleport anywhere within range 12. This does not require line of sight%s. Spellweave Multiplier: 1.]]):tformat(getTeleportRange(self, nil, 6, t.getPowerModMode(self, t)), getTeleportPrecision(self, nil, 20, t.getPowerModMode(self, t)), fizzleText)
	end,
	getModeDescriptor = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Teleport to a distant location within range %d with an area of %d. You cannot teleport anywhere within range 12. This does not require line of sight%s.]]):tformat(getTeleportRange(self, t, 6), getTeleportPrecision(self, t, 20), fizzleText)
	end,
}

newTalent{ -- Threadleap, based on my beloved Ghoulish Leap. Actually doesn't use fizzle rate or precision, although currently you have to have maxed Precision to get it.
	name = "Threadleap",
	short_name = "KAM_WARPMODE_THREADLEAP",
	image = "talents/telekinetic_leap.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	kamNoSilence = true, -- It can't go through walls and it is short range, this is the big advantage. Precision is nice but you should be fine by 5 points in this talent.
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Threadleap",
	no_npc_use = true,
	getTeleportFunction = function(self, t) -- From Ghoulish Leap
		teleportSetupStuff(self, t)
		local range = getTeleportRange(self, t, 2/3)
		local tg = {type="hit", range=range, nolock=true}
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		if core.fov.distance(self.x, self.y, x, y) > range then return nil end

		local ox, oy = self.x, self.y

		local block_actor = function(_, bx, by) return game.level.map:checkEntity(bx, by, Map.TERRAIN, "block_move", self) end
		local l = self:lineFOV(x, y, block_actor)
		local lx, ly, is_corner_blocked = l:step()
		local tx, ty, _ = lx, ly
		while lx and ly do
			if is_corner_blocked or block_actor(_, lx, ly) then break end
			tx, ty = lx, ly
			lx, ly, is_corner_blocked = l:step()
		end

		-- Find space
		if block_actor(_, tx, ty) then return nil end
		local fx, fy = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
		if not fx then
			return
		end
		if t.bonusType == 2 or t.bonusType == 3 then 
			t.doBonus(self, t, 0)
		end
		self:move(fx, fy, true)
		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(ox, oy, 9, 5)
		end

		if t.bonusType == 1 or t.bonusType == 3 then 
			t.doBonus(self, t, 1)
		end
		return true
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[By preparing a magical spell on your boots, leap with perfect precision to a location you can see with %d range (two thirds of normal range). This cannot be silenced, and as it is not truly a teleport, it will work in locations where teleport effects will not. Spellweave Multiplier: 1.]]):tformat(getTeleportRange(self, nil, 2/3, t.getPowerModMode(self, t)))
	end,
	getModeDescriptor = function(self, t)
		return ([[With the magical spell on your boots, leap with perfect precision to a location you can see with %d range. This cannot be silenced, and as it is not truly a teleport, it will work in locations where teleport effects will not.]]):tformat(getTeleportRange(self, t, 2/3))
	end,
}

-- Exists so that I can modify this function more easily without messing with talent creation.
local function getWormholeDuration(self, t, inputSpellweavePower)
	local spellweavePower = inputSpellweavePower or t.getPowerMod(self, t)
	return 8 * spellweavePower
end

newTalent{
	name = "Wormhole", -- It is like the fanciest teleport method in game.
	short_name = "KAM_WARPMODE_WORMHOLE", 
	image = "talents/wormhole.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Wormhole",
	no_npc_use = true,

	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		-- This is largely from the spacetime-weaving tree's Wormhole. It's weird how much you can get done by copying stuff together in new configurations.
		local tg = {type="bolt", nowarning=true, range=1, nolock=true, simple_dir_request=true, talent=t}
		local entrance_x, entrance_y = self:getTarget(tg)
		if not entrance_x or not entrance_y then return nil end
		local _ _, entrance_x, entrance_y = self:canProject(tg, entrance_x, entrance_y)
		local trap = game.level.map(entrance_x, entrance_y, engine.Map.TRAP)
		if trap or game.level.map:checkEntity(entrance_x, entrance_y, Map.TERRAIN, "block_move") then game.logPlayer(self, "You can't place a wormhole entrance here.") return end

		-- Target the exit location
		local tg = {type="hit", nolock=true, pass_terrain=true, nowarning=true, range=getTeleportRange(self, t, 1)}
		local exit_x, exit_y = self:getTarget(tg)
		if not exit_x or not exit_y then return nil end
		local _ _, exit_x, exit_y = self:canProject(tg, exit_x, exit_y)
		local trap = game.level.map(exit_x, exit_y, engine.Map.TRAP)
		if trap or game.level.map:checkEntity(exit_x, exit_y, Map.TERRAIN, "block_move") or core.fov.distance(entrance_x, entrance_y, exit_x, exit_y) < 2 then game.logPlayer(self, "You can't place a wormhole exit here.") return end

		-- Wormhole values
		local power = self:combatSpellpower()
		local dest_power = self:combatSpellpower(0.3)
		
		-- Our base wormhole
		local function makeWormhole(x, y, dest_x, dest_y)
			local wormhole = mod.class.Trap.new{
				name = _t"wormhole",
				type = "annoy", subtype="teleport", id_by_type=true, unided_name = _t"trap",
				image = "terrain/wormhole.png",
				display = '&', color_r=255, color_g=100, color_b=255, back_color=colors.STEEL_BLUE,
				message = _t"@Target@ moves onto the wormhole.",
				temporary = getWormholeDuration(self, t),
				x = x, y = y, dest_x = dest_x, dest_y = dest_y,
				radius = getTeleportPrecision(self, t, 5),
				canAct = false,
				energy = {value=0},
				disarm = function(self, x, y, who) return false end,
				power = power, dest_power = dest_power,
				summoner = self, beneficial_trap = true, faction=self.faction,
				bonusType = t.bonusType,
				talent = t,
				t_id = t.id,
				bonusPowerMod = 1,
				doParticles = doParticles,
				triggered = function(self, x, y, who)
					local hit = who:checkHit(self.power, who:combatSpellResist()+(who:attr("continuum_destabilization") or 0), 0, 95) and who:canBe("teleport") -- Bug fix, Deprecrated checkhit call
					if hit or (who.reactionToward and who:reactionToward(self) >= 0) then
						local talent = self.summoner:getTalentFromId(self.summoner[self.t_id])
						self.doParticles(who, talent)
						if self.bonusPowerMod > 0 and (talent.bonusType == 2 or talent.bonusType == 3) then 
							talent.doBonus(self.summoner, talent, 0, who.x, who.y, who, self.bonusPowerMod)
						end
						if not who:teleportRandom(self.dest_x, self.dest_y, self.radius, 1) then
							game.logSeen(who, "%s tries to enter the wormhole but a violent force pushes it back.", who:getName():capitalize())
						else
							if who ~= self.summoner then who:setEffect(who.EFF_CONTINUUM_DESTABILIZATION, 100, {power=self.dest_power}) end
							self.doParticles(who, talent)
							game:playSoundNear(self, "talents/teleport")
							if self.bonusPowerMod > 0 and (talent.bonusType == 1 or talent.bonusType == 3) then 
								talent.doBonus(self.summoner, talent, 1, who.x, who.y, who, self.bonusPowerMod)
							end
							self.bonusPowerMod = self.bonusPowerMod - 0.1
							self.dest.bonusPowerMod = self.dest.bonusPowerMod - 0.1
						end
					else
						game.logSeen(who, "%s ignores the wormhole.", who:getName():capitalize())
					end
					return true
				end,
				act = function(self)
					self:useEnergy()
					self.temporary = self.temporary - 1
					if self.temporary <= 0 then
						game.logSeen(self, "Reality asserts itself and forces the wormhole shut.")
						if game.level.map(self.x, self.y, engine.Map.TRAP) == self then game.level.map:remove(self.x, self.y, engine.Map.TRAP) end
						game.level:removeEntity(self, true)
					end
				end,
			}
			
			return wormhole
		end
		
		-- Adding the entrance wormhole
		local entrance = makeWormhole(entrance_x, entrance_y, exit_x, exit_y)
		game.level:addEntity(entrance)
		entrance:identify(true)
		entrance:setKnown(self, true)
		game.zone:addEntity(game.level, entrance, "trap", entrance_x, entrance_y)
		game:playSoundNear(self, "talents/heal")

		-- Adding the exit wormhole
		local exit = makeWormhole(exit_x, exit_y, entrance_x, entrance_y)
		exit.x = exit_x
		exit.y = exit_y
		game.level:addEntity(exit)
		exit:identify(true)
		exit:setKnown(self, true)
		game.zone:addEntity(game.level, exit, "trap", exit_x, exit_y)

		-- Linking the wormholes
		entrance.dest = exit
		exit.dest = entrance

		game.logSeen(self, "%s folds the space between two points.", self:getName())
		return true
	end,
	getPowerModMode = function(self, t)
		return 0.8
	end,
	info = function(self, t)
		return ([[Through advanced Spellweaving techniques, fold space between an adjacent tile and a second point within range %d, creating a wormhole. Wormholes last %d turns (multiplied by Spellweave Multiplier), and whenever a creature enters one, it will be teleported near the other with an area of %d. Wormholes must be placed at least two tiles apart. These wormholes trigger their bonus effect each time, reducing in power by 10%% additively each time. If an enemy enters them, they will have a chance of being teleported, scaling with Spellpower, and they will be the target of the bonus, granting them any effects it would give if the bonus gave effects, or triggering at the location each time if the bonus used location. Spellweave Multiplier: %0.1f.]]):tformat(getTeleportRange(self, nil, 1, t.getPowerModMode(self, t)), getWormholeDuration(self, nil, t.getPowerModMode(self, t)), getTeleportPrecision(self, nil, 5, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		return ([[Create two wormholes, one adjacent to you and one within range %d, but must be at least two tiles apart. Wormholes last %d turns, and whenever a creature enters one, it will teleport near the other with an area of %d precision triggering the bonus with it as the target and location. The effect of this bonus will be reduced by 10%% additively each time. Chance of teleporting enemies scales with spellpower.]]):tformat(getTeleportRange(self, t, 1), getWormholeDuration(self, t), getTeleportPrecision(self, t, 5))
	end,
}

newTalent{
	name = "Blink Any",
	short_name = "KAM_WARPMODE_BLINKANY",
	image = "talents/vault.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Force-Blink",
	no_npc_use = true,
	getTeleportFunction = function(self, t) -- Again, largely from Phase Door
		teleportSetupStuff(self, t)
		local target = self
		local aitarget = self.ai_target.actor
		local range = getTeleportRange(self, t, 1)
		local radius = getTeleportPrecision(self, t, 3)
		local _, tx, ty
		game.logPlayer(self, "Select a target to teleport...")
		local tg = {default_target=self, type="hit", friendlyblock = false, nowarning=true, range=6 * t.getPowerMod(self, t)}
		if rng.percent(50 + (aitarget and aitarget:attr("teleport_immune") or 0) + (aitarget and aitarget:attr("continuum_destabilization") or 0)/2) then tg.first_target = "friend" end -- npc's select self or aitarget based on target's resistance to teleportation
		tx, ty = self:getTarget(tg)
		if tx then
			 _, _, _, tx, ty = self:canProject(tg, tx, ty)
			if tx then
				target = game.level.map(tx, ty, Map.ACTOR)
				if ai_target and target ~= aitarget then target = self end
			end
		end
		target = target or self
		if target ~= self then
			local hit = self:checkHit(self:combatSpellpower() * t.getPowerMod(self, t) * 1.4, target:combatSpellResist() + (target:attr("continuum_destabilization") or 0))
			if not target:canBe("teleport") or not hit then -- The 1.4 is to cancel the low power mod so this isn't way worse than normal Phase Door.
				game.log("The target resisted your teleportation!")
				return true
			end
		end

		-- get target location, if needed
		local x, y = self.x, self.y
		game.logPlayer(self, "Select a teleport location...")
		--copy the block_path function from the engine so that we can call it for normal block_path checks
		local old_block_path = engine.Target.defaults.block_path
		--use an adjusted block_path to check if we have a tile in LOS; display targeting in yellow if we don't so we can warn the player their spell may fizzle
		--note: we only use this if the original block_path would permit targeting 
		local tg = {type="ball", nolock=true, pass_terrain=true, nowarning=true, range=range, radius=radius, requires_knowledge=false, block_path=function(typ, lx, ly, for_highlights) if not self:hasLOS(lx, ly) and not old_block_path(typ, lx, ly, for_highlights) then return false, "unknown", true else return old_block_path(typ, lx, ly, for_highlights) end end}
		x, y = self:getTarget(tg)
		if not x then return nil end
		_, _, _, x, y = self:canProject(tg, x, y)
		range = radius
		-- Check LOS
		if not self:hasLOS(x, y) and rng.percent((getTeleportFizzleRate(self, t)) * 100) then
			game.logPlayer(self, "The targeted phase door fizzles and works randomly!")
			x, y = self.x, self.y
			range = getTeleportRange(self, t, 1)
		end

		if t.bonusType == 2 or t.bonusType == 3 then 
			t.doBonus(self, t, 0, target.x, target.y, target)
		end
		doParticles(self, t)
		target:teleportRandom(x, y, range)
		doParticles(self, t)
		
		if target ~= self then
			if target:reactionToward(self) < 0 then target:setTarget(self) end -- Annoy them!
			target:setEffect(target.EFF_CONTINUUM_DESTABILIZATION, 100, {power=self:combatSpellpower(0.3)})
		end
		if t.bonusType == 1 or t.bonusType == 3 then 
			t.doBonus(self, t, 1, target.x, target.y, target)
		end
		game:playSoundNear(target, "talents/teleport")
		return true
	end,
	getPowerModMode = function(self, t)
		return 0.8
	end,
	info = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Teleport any target within range 6 (multiplied by Spellweave Multiplier) to a location with base range %d and precision %d. This does not require line of sight%s. Chance of teleporting enemies scales with spellpower and Spellweave Multiplier, and teleport bonuses will be applied to the target, giving them any effects it would activate or trigger any location based effects at their location. Spellweave Multiplier: %0.1f.]]):tformat(getTeleportRange(self, nil, 1, t.getPowerModMode(self, t)), getTeleportPrecision(self, nil, 3, t.getPowerModMode(self, t)), fizzleText, t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Teleport any target in range %d to a location within range %d with an area of %d. This does not require line of sight%s. Chance of teleporting enemies scales with spellpower and Spellweave Multiplier, and teleport bonuses will be applied to the target, giving them any effects it would activate or trigger any location based effects at their location.]]):tformat(6 * t.getPowerMod(self, t), getTeleportRange(self, t, 1), getTeleportPrecision(self, t, 3), fizzleText)
	end,
}

newTalent{ -- Again, no fizzle rate or precision, but it only works through walls as a probability travel. I really hope fizzle rate and precision don't end up meaningless.
	name = "Molten Path",
	short_name = "KAM_WARPMODE_WALLS",
	image = "talents/cleansing_flames.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Molten Path",
	no_npc_use = true,
	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		local tg = {type="bolt", range=1, nolock=true}
		local x, y
		if self == game.player then
			x, y = game:targetGetForPlayer(tg) -- Ignore Freezes, this specially removes and ignores them, but you only get the remove if you USE it so.
		else
			x, y = game:getTarget(tg)
		end
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		
		local currentX, currentY = self.x, self.y
		self:probabilityTravel(x, y, getTeleportRange(self, t, 1.5)) -- Very handy.
		
		if self.x == currentX and self.y == currentY then
			game.log("You could not melt through that wall.")
			return false
		end
		if t.bonusType == 2 or t.bonusType == 3 then 
			t.doBonus(self, t, 0, currentX, currentY)
		end
		if t.bonusType == 1 or t.bonusType == 3 then 
			t.doBonus(self, t, 1)
		end
		
		
		local didRemove = false
		for eff_id, p in pairs(self.tmp) do
			local e = self.tempeffect_def[eff_id]
			if e and (e.subtype.stun or e.subtype.cold) and (e.status == "detrimental") then
				self:removeEffect(eff_id)
				didRemove = true
			end
		end
		if didRemove then
			game.log("%s melts through freezes and stuns!", self:getName():capitalize())
		end
		game:playSoundNear(game.player, "talents/fireflash")
		return true
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Melt through everything surrounding you. Choose an adjacent wall or enemy and teleport to the other side of it, moving up to %d tiles (multiplied by Spellweave Multiplier). Additionally, the incredible heat of molten stone removes any Stun or Freeze effects on you, and Freeze effects do not impact your ability to use this Spell. Spellweave Multiplier: %d.]]):tformat(getTeleportRange(self, nil, 1.5, t.getPowerModMode(self, t)), t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		return ([[Melt through everything surrounding you. Choose an adjacent wall or enemy and teleport to the other side of it, moving up to %d tiles. Additionally, the incredible heat of molten stone removes any Stun or Freeze effects on you, and Freeze effects do not impact your ability to use this Spell.]]):tformat(getTeleportRange(self, t, 1.5))
	end,
}

newTalent{ -- Again again, no fizzle rate or precision. Also a movement infusion though, so.
	name = "Lightning Dash",
	short_name = "KAM_WARPMODE_SPEED",
	image = "talents/living_lightning.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Lightning Dash",
	no_npc_use = true,
	kamIsInstant = true,
	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		local speed = getTeleportRange(self, t, 0.5)
		if t.bonusType == 2 or t.bonusType == 3 then 
			t.doBonus(self, t, 0)
		end
		local doBonus = false
		if (t.bonusType == 1 or t.bonusType == 3) then
			doBonus = true
		end
		self:setEffect(self.EFF_KAM_SPELLWOVEN_LIGHTNING_SPEED, 2, {power = speed, t_id = t.id, doBonus = doBonus})
		return true
	end,
	onBuildover = function(self, t)
		if t.kamLightningEffActive then 
			self:removeEffect(self.EFF_KAM_SPELLWOVEN_LIGHTNING_SPEED) 
		end
	end,
	getPowerModMode = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Rather than teleport, run at impossible speed. Gain %d%% movement speed (scaling with teleport distance and multiplied by Spellweave Multiplier) for two turns. Bonus effects that trigger after a teleport trigger when the burst of speed ends. While the speed lasts, you are immune to stuns, dazes, and pins. If you replace this spell while its active, then the speed will be canceled. Spellweave Multiplier: %d.]]):tformat(getTeleportRange(self, nil, 0.5, t.getPowerModMode(self, t)) * 100, t.getPowerModMode(self, t))
	end,
	getModeDescriptor = function(self, t)
		return ([[Rather than teleport, run at impossible speed. Gain %d%% movement speed (scaling with teleport distance) for two turns. While the speed lasts, you are immune to stuns, dazes, and pins. If you replace this spell while its active, then the speed will be canceled.]]):tformat(getTeleportRange(self, t, 0.5) * 100)
	end,
}

newTalent{
	name = "Blightgate",
	short_name = "KAM_WARPMODE_SWAPPY", -- Swippy swappy. : )
	image = "talents/dark_portal.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Blightgate",
	no_npc_use = true,
	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		local _, tx, ty

		local x, y = self.x, self.y
		local ox, oy = x, y
		local range = getTeleportRange(self, t, 0.9)
		local precision = getTeleportPrecision(self, t, 4)
		local radius = 3
		game.logPlayer(self, "Select a teleport location...")
		local tg = {type="kamDoubleCircle", nolock=true, pass_terrain=true, nowarning=true, range=range, size=precision, sizeTwo = radius, requires_knowledge=false}
		x, y = self:getTarget(tg)
		if not x then return nil end
		_, _, _, x, y = self:canProject(tg, x, y)
		-- Make sure there is at least one legal tile to prevent more annoying shenanigans.
		local legal = false
		local teleportFailure = false
		local fizzled = false
		local expanded = false
		precision = math.floor(precision + 0.5)
		range = math.floor(range + 0.5)
		for i = x - precision, x + precision do -- Unlike normally, we cannot rely on teleporting in a big area since we need a specific target. So here we'll generate all possible targets and pick one. Based on _M:teleportRandom code.
			for j = y - precision, y + precision do
				if game.level.map:isBound(i, j) and	core.fov.distance(x, y, i, j) <= precision and self:canMove(i, j) then
					-- Check for no_teleport and vaults
					if game.level.map.attrs(i, j, "no_teleport") then
						local vault = game.level.map.attrs(self.x, self.y, "vault_id")
						if vault and game.level.map.attrs(i, j, "vault_id") == vault then
							legal = true
							break
						end
					else
						legal = true
						break
					end
				end
			end
			if legal then 
				break
			end
		end
		if not legal and precision < 4 then
			precision = 4
			for i = x - precision, x + precision do -- Unlike normally, we cannot rely on teleporting in a big area since we need a specific target. So here we'll generate all possible targets and pick one. Based on _M:teleportRandom code.
				for j = y - precision, y + precision do
					if game.level.map:isBound(i, j) and	core.fov.distance(x, y, i, j) <= precision and self:canMove(i, j) then
						-- Check for no_teleport and vaults
						if game.level.map.attrs(i, j, "no_teleport") then
							local vault = game.level.map.attrs(self.x, self.y, "vault_id")
							if vault and game.level.map.attrs(i, j, "vault_id") == vault then
								legal = true
								break
							end
						else
							legal = true
							break
						end
					end
				end
				if legal then 
					break
				end
			end
			expanded = true
		end
		-- If there is no legal target within the intended range or a fizzle occurs, decide on a random new legal target within range.
		if not legal or (not self:hasLOS(x, y) and rng.percent((getTeleportFizzleRate(self, t)) * 100)) then
			local fizzled = true
			local poss = {}
			for i = self.x - range, self.x + range do -- Unlike normally, we cannot rely on teleporting in a big area since we need a specific target. So here we'll generate all possible targets and pick one. Based on _M:teleportRandom code.
				for j = self.y - range, self.y + range do
					if game.level.map:isBound(i, j) and	core.fov.distance(self.x, self.y, i, j) <= range and self:canMove(i, j) then
						-- Check for no_teleport and vaults
						if game.level.map.attrs(i, j, "no_teleport") then
							local vault = game.level.map.attrs(self.x, self.y, "vault_id")
							if vault and game.level.map.attrs(i, j, "vault_id") == vault then
								poss[#poss+1] = {i,j}
							end
						else
							poss[#poss+1] = {i,j}
						end
					end
				end
			end
			if #poss > 0 then
				local pos = poss[rng.range(1, #poss)]
				x, y = pos[1], pos[2]
			else
				teleportFailure = true
			end
		end

		if teleportFailure then -- Originally set up because you could cheat and teleport enemies out of a vault from outside of it and you wouldn't get moved but they would.
			game.log("... but there was nowhere to teleport to.")
			return false
		else
			if expanded then
				game.logPlayer(self, "With nowhere to teleport to in the range, the blightgate sends you slightly out of the intended range.")
			elseif not legal then
				game.logPlayer(self, "With nowhere to teleport to in the range, the blightgate fizzles and works randomly!")
			elseif fizzled then
				game.logPlayer(self, "The blightgate fizzles and works randomly!")
			end
			if t.bonusType == 2 or t.bonusType == 3 then 
				t.doBonus(self, t, 0)
			end

			-- Teleport your enemies
			local actors = {}
			self:project({type="ball", range=range, radius=radius, x = x, y = y, selffire = false, friendlyfire = false}, x, y, function(px, py)
				local target = game.level.map(px, py, Map.ACTOR)
				if target then
					if not target:canBe("teleport") then 
						game.logSeen("%s resists the blightgate!") 
						return 
					end
					if game.level.map.attrs(target.x, target.y, "no_teleport") then -- If an enemy is on a no-teleport tile, they should resist this (unless it's a vault you're both in).
						local vault = game.level.map.attrs(target.x, target.y, "vault_id")
						if not (vault and game.level.map.attrs(self.x, self.y, "vault_id") == vault) then
							return
						end
					end
					actors[#actors+1] = target
				end
			end)
			for i, a in ipairs(actors) do
				local tx, ty = util.findFreeGrid(self.x, self.y, 20, true, {[Map.ACTOR]=true})
				if tx and ty then a:move(tx, ty, true) end
			end

			doParticles(self, t)
			self:teleportRandom(x, y, precision) -- Sometimes teleports you into walls?
			doParticles(self, t)
			
			game:playSoundNear(self, "talents/teleport")
			return true
		end
	end,
	getPowerModMode = function(self, t)
		return 0.9
	end,
	info = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Open a blightgate to a location with base range %d and precision %d, teleporting any enemy within range %d of the targeted location to you (this region is marked in purple when targeting). This does not require line of sight%s. Spellweave Multiplier: 0.9.]]):tformat(getTeleportRange(self, nil, 0.9, t.getPowerModMode(self, t)), getTeleportPrecision(self, nil, 4, t.getPowerModMode(self, t)), 3, fizzleText)
	end,
	getModeDescriptor = function(self, t)
		local fizzleText = [[]]
		if getTeleportFizzleRate(self, t) > 0 then
			fizzleText = ([[, although if you blink to a location you cannot see, you have a %d%% chance to fail and teleport randomly]]):tformat(getTeleportFizzleRate(self, t) * 100)
		end
		return ([[Open a blightgate to a location with base range %d and precision %d (with your precision marked in green for targeting), teleporting any enemy within range 3 of the targeted location to you (this region is marked in purple when targeting). This does not require line of sight%s.]]):tformat(getTeleportRange(self, t, 0.9), getTeleportPrecision(self, t, 4), fizzleText)
	end,
}

newTalent{ 
	name = "Strikethrough",
	short_name = "KAM_WARPMODE_SLASH_DASH",
	image = "talents/blade_ward.png",
	type = {"spellweaving/teleportation-modes", 1},
	points = 1,
	isKamTeleportMode = true,
	mode = "passive",
	getModeName = "Strikethrough",
	no_npc_use = true,
	getTeleportFunction = function(self, t)
		teleportSetupStuff(self, t)
		local tg = {type="bolt", range=1, nolock=true}
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		
		local currentX, currentY = self.x, self.y
		
		if self:attr("encased_in_ice") then return end

		local dirx, diry = x - self.x, y - self.y
		local tx, ty = x, y
		local targList = {}
		
		local dist = getTeleportRange(self, t, 0.4)
		
		while game.level.map:isBound(tx, ty) and game.level.map:checkAllEntities(tx, ty, "block_move", self) and dist > 0 do
			if not ignore_no_teleport and game.level.map.attrs(tx, ty, "no_teleport") then break end
			if game.level.map:checkAllEntities(tx, ty, "no_prob_travel", self) then break end
			if checker and checker(tx, ty) then break end
			local targ = game.level.map(tx, ty, Map.ACTOR)
			if targ and self:reactionToward(targ) < 0 then
				table.insert(targList, targ)
			else 
				break
			end
			tx = tx + dirx
			ty = ty + diry
			dist = dist - 1
		end
		if #targList > 0 then
			if game.level.map:isBound(tx, ty) and not game.level.map:checkAllEntities(tx, ty, "block_move", self) and (ignore_no_teleport or not game.level.map.attrs(tx, ty, "no_teleport")) then
				if t.bonusType == 2 or t.bonusType == 3 then 
					t.doBonus(self, t, 0)
				end
				self:dropNoTeleportObjects()
				if not engine.Actor.move(self, tx, ty, false) then
					game.log("Your attempt to dash through enemies failed.")
					return false			
				end
			else
				game.log("Your attempt to dash through enemies failed.")
				return false
			end
			if t.bonusType == 1 or t.bonusType == 3 then 
				t.doBonus(self, t, 1)
			end
			
			local oldModifyASCChance = self.kam_modify_asc_chance
			self.kam_modify_asc_chance = 0
			for i = 1, #targList - 1 do
				self:attackTarget(targList[i], nil, 0.25, true)
			end
			self.kam_modify_asc_chance = -1
			self:attackTarget(targList[#targList], nil, 0.25, true)
			self.kam_modify_asc_chance = oldModifyASCChance
			return true
		else
			game.log("There was nothing to dash through.")
			return false	
		end
	end,
	getPowerModMode = function(self, t)
		return 0.8
	end,
	info = function(self, t)
		return ([[Phase part way out of reality, dashing through a line of enemies (up to %d in a row). On a successful dash, make a melee attack on each target passed through with 25%% power. These attacks will not trigger Advanced Staff Combat casts, except for the last target, which has a 100%% chance to trigger an Advanced Staff Combat cast (modified before any dual wielding penalities). Spellweave Multiplier: 0.8.]]):tformat(getTeleportRange(self, nil, 0.4, t.getPowerModMode(self, t)))
	end,
	getModeDescriptor = function(self, t)
		return ([[Phase part way out of reality, dashing through a line of enemies (up to %d in a row). On a successful dash, make a melee attack on each target passed through with 25%% power. These attacks will not trigger Advanced Staff Combat casts, except for the last target, which has a 100%% chance to trigger an Advanced Staff Combat cast (modified before any dual wielding penalities).]]):tformat(getTeleportRange(self, t, 0.4))
	end,
}