local Map = require "engine.Map"
local Target = require "engine.Target"
local KamCalc = require "mod.KamHelperFunctions"
newTalentType{ type = "spellweaving/shapes", is_spell = true, name = _t("shapes", "talent type"), descriptions = _t"Weave spells with shapes." }

-- This is simply all of the shapes useable in Spellweaving.

-- Current bugs: The weird way I implemented everything critting together for special shapes messes up crit bolding. Works for shapes not using special handlers.

local function getSpellweaveRange(self, t)
	if (self.kamSpellweaveForcedRange) then
		return math.max(self.getTalentRange(t), self.kamSpellweaveForcedRange) -- In the event that we want to force a minimum range. Mostly for future Spellweaving Combat shenanigans.
	else
		local retval = self:getTalentRange(t)
		if self:isTalentActive(self.T_RANGE_AMPLIFICATION_DEVICE) and retval == 1 then
			retval = 2
		end
		return retval
	end
end

local base_newTalent = newTalent -- Modify all of these talents to make them hidden in the talents menu. Done this way so I can turn it off easily if I want. They were just causing a LOT of talent screen bloat.
newTalent = function(t) 
	t.hide = "always"
	base_newTalent(t)
end

newTalent{
	name = "Beam",
	short_name = "KAM_SHAPE_BEAM",
	image = "talents/manathrust.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCBeam = true,
	no_npc_use = true,
	range = 7,
	getSpellNameShape = "Beam of ",
	target = function(self, t) 
		return {type="beam", range = getSpellweaveRange(self, t), friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Shape your spell into a beam with range %d. Spellweave Multiplier: 1.]]):tformat(getSpellweaveRange(self, t))
	end,
	getElementColors = function(self, argsList, t) end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a beam with range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x-self.x, ty=y-self.y}
		
		if (t.isKamDuo) then
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
			
			argsList = {tx=x-self.x, ty=y-self.y, density = 0.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
		end
	end,
}

newTalent{
	name = "Bolt",
	short_name = "KAM_SHAPE_BOLT",
	image = "talents/water_bolt.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCBeam = true,
	no_npc_use = true,
	isKamDoubleWallChance = true,
	range = 7,
	getSpellNameShape = "Bolt of ",
	target = function(self, t) 
		return {type="bolt", range = getSpellweaveRange(self, t), friendlyfire=false, selffire=false, friendlyblock=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 1.2
	end,
	info = function(self, t)
		return ([[Shape your spell into an instantaneous bolt with range %d. It hits the first target in its path, but is not blocked by allies. Spellweave Multiplier: 1.2.]]):tformat(getSpellweaveRange(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a bolt with range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x-self.x, ty=y-self.y, radius=0.8}
		if (t.isKamDuo) then
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(x, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x-self.x, ty=y-self.y, radius=0.8, density = 0.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(x, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(x, y, 0.8, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Burst",
	short_name = "KAM_SHAPE_BURST",
	image = "talents/throw_bomb.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCExact = true,
	no_npc_use = true,
	range = 6,
	getSpellNameShape = "Burst of ",
	target = function(self, t) 
		return {type="ball", range = getSpellweaveRange(self, t), radius = 3, friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 0.9
	end,
	info = function(self, t)
		return ([[Shape your spell into a burst of magic with range %d and radius 3. Spellweave Multiplier: 0.9.]]):tformat(getSpellweaveRange(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a burst with radius 3 and range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x, ty=y, radius = 3}
		if (t.isKamDuo) then 
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(x, y, 3, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x, ty=y, radius = 3, density = 0.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(x, y, 3, "kam_spellweaver_ball_physical", argsList)
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(x, y, 3, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Huge",
	short_name = "KAM_SHAPE_HUGE",
	image = "talents/repulsion_blast.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	no_npc_use = true,
	isKamASCSelf = true,
	isKamNoNeedTarget = true,
	range = 0,
	getSpellNameShape = "Massive Burst of ",
	target = function(self, t) 
		return {type="ball", range = getSpellweaveRange(self, t), radius = 10, friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 0.45
	end,
	info = function(self, t)
		return ([[Shape your spell into a huge explosion centered on top of you with radius 10. Spellweave Multiplier: 0.45.]])
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a massive explosion with radius 10,]]):tformat()
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x, ty=y, radius = 10}
		if (t.isKamDuo) then 
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x, ty=y, radius = 10, density = 0.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Cone",
	short_name = "KAM_SHAPE_CONE",
	image = "talents/command_breathe.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCBeam = true,
	isKamNoCheckCanProject = true,
	no_npc_use = true,
	getSpellNameShape = "Cone of ",
	range = 0,
	radius = 5,
	target = function(self, t)
		return {type="cone", range=getSpellweaveRange(self, t), radius=self:getTalentRadius(t), friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 0.85
	end,
	info = function(self, t)
		return ([[Shape your spell into an cone with radius 5. Spellweave Multiplier: %0.2f.]]):tformat(t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a cone with radius 5,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x-self.x, ty=y-self.y, radius = 5}
		if (t.isKamDuo) then 
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, 5, "kam_spellweaver_cone", argsList)	
			argsList = {tx=x-self.x, ty=y-self.y, radius = 5, density = 0.5}			
			t.getElementColors12(self, argsList, t)	
			game.level.map:particleEmitter(self.x, self.y, 5, "kam_spellweaver_cone", argsList)		

		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, 5, "kam_spellweaver_cone", argsList)
		end
	end,
}

newTalent{
	name = "Wall",
	short_name = "KAM_SHAPE_WALL",
	image = "talents/hold_the_ground.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCExact = true,
	no_npc_use = true,
	range = 4,
	getSpellNameShape = "Wall of ",
	target = function(self, t)
		return {type="wall", range = getSpellweaveRange(self, t), halflength=4, talent=t, friendlyfire=false, selffire=false, halfmax_spots=5} 
	end,
	getPowerModShape = function(self, t)
		return 1.0
	end,
	info = function(self, t)
		return ([[Shape your spell into an wall of length 8 with range %d. Spellweave Multiplier: %d.]]):tformat(getSpellweaveRange(self, t), t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a wall of length 8 with a range of %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local x1 = 0
		local y1 = 0
		local x2 = 0
		local y2 = 0
		local set = 0
		local function setXY(x, y)
			if set == 0 then 
				x1 = x 
				y1 = y
			elseif set == 1 then 
				x2 = x 
				y2 = y 
			end
			set = set + 1
		end
		KamCalc.kam_calc_wall_endpoints(
			self,
			x,
			y,
			game.level.map.w,
			game.level.map.h,
			4,
			5,
			self.x,
			self.y,
			x - self.x,
			y - self.y,
			function(_, px, py)
				if Target.defaults:block_radius(px, py, false) then return true end
			end,
			function(_, px, py)
				setXY(px, py)
			end,
		nil)
		local argsList = {tx=x1-x, ty=y1-y}
		if (t.isKamDuo) then
			t.getElementColors11(self, argsList, t)
			argsList.density = 0.5
			game.level.map:particleEmitter(x, y, math.max(math.abs(x1-x), math.abs(y1-y)), "kam_spellweaver_beam", argsList)
			argsList.tx=x2-x 
			argsList.ty=y2-y
			game.level.map:particleEmitter(x, y, math.max(math.abs(x2-x), math.abs(y2-y)), "kam_spellweaver_beam", argsList)
			argsList.tx = x1
			argsList.ty = y1
			argsList.radius = 0.5
			game.level.map:particleEmitter(x1, y1, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.tx = x2
			argsList.ty = y2
			game.level.map:particleEmitter(x2, y2, 0.8, "kam_spellweaver_ball_physical", argsList)

			argsList = {tx=x1-x, ty=y1-y, density = 0.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(x, y, math.max(math.abs(x1-x), math.abs(y1-y)), "kam_spellweaver_beam", argsList)
			argsList.tx=x2-x 
			argsList.ty=y2-y
			game.level.map:particleEmitter(x, y, math.max(math.abs(x2-x), math.abs(y2-y)), "kam_spellweaver_beam", argsList)
			argsList.tx = x1
			argsList.ty = y1
			argsList.radius = 0.5
			game.level.map:particleEmitter(x1, y1, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.tx = x2
			argsList.ty = y2
			game.level.map:particleEmitter(x2, y2, 0.8, "kam_spellweaver_ball_physical", argsList)
			
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(x, y, math.max(math.abs(x1-x), math.abs(y1-y)), "kam_spellweaver_beam", argsList)
			argsList.tx=x2-x 
			argsList.ty=y2-y
			game.level.map:particleEmitter(x, y, math.max(math.abs(x2-x), math.abs(y2-y)), "kam_spellweaver_beam", argsList)
			argsList.tx = x1
			argsList.ty = y1
			argsList.radius = 0.5
			game.level.map:particleEmitter(x1, y1, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.tx = x2
			argsList.ty = y2
			game.level.map:particleEmitter(x2, y2, 0.8, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Wide Beam",
	short_name = "KAM_SHAPE_WIDEBEAM",
	image = "talents/path_of_the_sun.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCBeam = true,
	no_npc_use = true,
	range = 7,
	getSpellNameShape = "Wide Beam of ",
	target = function(self, t)
		return {type="widebeam", radius=1, range = getSpellweaveRange(self, t), friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 0.85
	end,
	info = function(self, t)
		return ([[Shape your spell into a wide beam with range %d. Spellweave Multiplier: %0.2f.]]):tformat(getSpellweaveRange(self, t), t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a wide beam with range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x-self.x, ty=y-self.y}
		if (t.isKamDuo) then
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_wide_beam", argsList)
			
			argsList = {tx=x-self.x, ty=y-self.y,density=0.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_wide_beam", argsList)
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_wide_beam", argsList)
		end
	end,
}

local function addGrid(typ, x, y, grids)
	if typ.filter and not typ.filter(x, y) then 
		return 
	end
	if not grids[x] then 
		grids[x] = {} 
	end
	grids[x][y] = true
end

newTalent{ 
	name = "Cross",
	short_name = "KAM_SHAPE_CROSS",
	image = "talents/boneyard.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCExact = true,
	no_npc_use = true,
	getSpellNameShape = "Cross of ",
	range = 4,
	target = function(self, t)
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_cross(
				x,
				y,
				game.level.map.w,
				game.level.map.h,
				3,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="cross", range = getSpellweaveRange(self, t), size = 3, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.9
	end,
	info = function(self, t)
		return ([[Shape your spell into a cross with size 3 and range %d. Spellweave Multiplier: %0.1f.]]):tformat(getSpellweaveRange(self, t), t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a cross of size 3 with range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		lowX = x 
		topX = x
		lowY = y
		topY = y
		local function setXY(px, py)
			if (px < lowX) then 
				lowX = px
			elseif (px > topX) then 
				topX = px
			end 
			if (py < lowY) then 
				lowY = py
			elseif (py > topY) then 
				topY = py
			end
		end
		local specialTargetTable = Target:getType(tg)
		KamCalc.kam_calc_cross(
			self,
			x,
			y,
			game.level.map.w,
			game.level.map.h,
			3,
			function(_, px, py)
				if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
			end,
			function(_, px, py)
				setXY(px, py)
			end,
		nil)
		local argsList = {tx=topX-x, ty=0}
		if (t.isKamDuo) then 
			t.getElementColors11(self, argsList, t)
			argsList.density = 0.5
			
			game.level.map:particleEmitter(x, y, math.abs(topX-x), "kam_spellweaver_beam", argsList)
			argsList.tx=lowX-x 
			game.level.map:particleEmitter(x, y, math.abs(lowX-x), "kam_spellweaver_beam", argsList)
			
			argsList.tx=0
			argsList.ty=topY-y
			game.level.map:particleEmitter(x, y, math.abs(topY-y), "kam_spellweaver_beam", argsList)
			argsList.ty=lowY-y
			game.level.map:particleEmitter(x, y, math.abs(lowY-y), "kam_spellweaver_beam", argsList)
			
			argsList.tx = topX
			argsList.ty = y
			argsList.radius = 0.5
			game.level.map:particleEmitter(topX, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.tx = lowX
			game.level.map:particleEmitter(lowX, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			
			argsList.tx = x
			argsList.ty = topY
			game.level.map:particleEmitter(x, topY, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.ty = lowY
			game.level.map:particleEmitter(x, lowY, 0.8, "kam_spellweaver_ball_physical", argsList)
		
			argsList = {tx=topX-x, ty=0, density=0.5}
			t.getElementColors12(self, argsList, t)
			
			game.level.map:particleEmitter(x, y, math.abs(topX-x), "kam_spellweaver_beam", argsList)
			argsList.tx=lowX-x 
			game.level.map:particleEmitter(x, y, math.abs(lowX-x), "kam_spellweaver_beam", argsList)
			
			argsList.tx=0
			argsList.ty=topY-y
			game.level.map:particleEmitter(x, y, math.abs(topY-y), "kam_spellweaver_beam", argsList)
			argsList.ty=lowY-y
			game.level.map:particleEmitter(x, y, math.abs(lowY-y), "kam_spellweaver_beam", argsList)
			
			argsList.tx = topX
			argsList.ty = y
			argsList.radius = 0.5
			game.level.map:particleEmitter(topX, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.tx = lowX
			game.level.map:particleEmitter(lowX, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			
			argsList.tx = x
			argsList.ty = topY
			game.level.map:particleEmitter(x, topY, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.ty = lowY
			game.level.map:particleEmitter(x, lowY, 0.8, "kam_spellweaver_ball_physical", argsList)
		else 
			t.getElementColors(self, argsList, t)
			
			game.level.map:particleEmitter(x, y, math.abs(topX-x), "kam_spellweaver_beam", argsList)
			argsList.tx=lowX-x 
			game.level.map:particleEmitter(x, y, math.abs(lowX-x), "kam_spellweaver_beam", argsList)
			
			argsList.tx=0
			argsList.ty=topY-y
			game.level.map:particleEmitter(x, y, math.abs(topY-y), "kam_spellweaver_beam", argsList)
			argsList.ty=lowY-y
			game.level.map:particleEmitter(x, y, math.abs(lowY-y), "kam_spellweaver_beam", argsList)
			
			argsList.tx = topX
			argsList.ty = y
			argsList.radius = 0.5
			game.level.map:particleEmitter(topX, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.tx = lowX
			game.level.map:particleEmitter(lowX, y, 0.8, "kam_spellweaver_ball_physical", argsList)
			
			argsList.tx = x
			argsList.ty = topY
			game.level.map:particleEmitter(x, topY, 0.8, "kam_spellweaver_ball_physical", argsList)
			argsList.ty = lowY
			game.level.map:particleEmitter(x, lowY, 0.8, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{ 
	name = "Spiral",
	short_name = "KAM_SHAPE_SPIRAL",
	image = "talents/twist_fate.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCRand = true,
	no_npc_use = true,
	isKamNoCheckCanProject = true,
	range = 0,
	getSpellNameShape = "Spiral of ",
	target = function(self, t)
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_spiral(
				self.x,
				self.y,
				game.level.map.w,
				game.level.map.h,
				6,
				self.x,
				self.y,
				x - self.x,
				y - self.y,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="spiral", range = getSpellweaveRange(self, t), size = 6, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.9
	end,
	info = function(self, t)
		return ([[Shape your spell into a spiral with size 6. Spellweave Multiplier: %0.1f.]]):tformat(t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Conjure a spiral with size 6,]]):tformat()
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=0, ty=0, radius = 0.6, density = 0.5}
		local function toApply(prevX, prevY, curX, curY) return nil end
		if (t.isKamDuo) then 
			local argsList2 = table.clone(argsList)
			t.getElementColors11(self, argsList, t)
			t.getElementColors12(self, argsList2)
			toApply = function(prevX, prevY, curX, curY)
				argsList.tx = curX - prevX 
				argsList.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList)
				argsList.tx = prevX - curX 
				argsList.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList)
				argsList.tx = curX
				argsList.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList)
				
				argsList2.tx = curX - prevX 
				argsList2.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList2)
				argsList2.tx = prevX - curX 
				argsList2.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList2)
				argsList2.tx = curX
				argsList2.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList2)
			end
		else
			t.getElementColors(self, argsList, t)
			toApply = function(prevX, prevY, curX, curY)
				argsList.tx = curX - prevX 
				argsList.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList)
				argsList.tx = prevX - curX 
				argsList.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList)
				argsList.tx = curX
				argsList.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList)
			end
		end
		
		KamCalc.kam_calc_spiral_endpoints(
			self,
			x, 
			y, 
			game.level.map.w,
			game.level.map.h,
			6, 
			self.x, 
			self.y, 
			x - self.x,
			y - self.y,
			function(_, px, py)
				if Target.defaults:block_radius(px, py, false) then return true end
			end,
			toApply,
		nil)
	end,
}

newTalent{ 
	name = "Checkerboard",
	short_name = "KAM_SHAPE_CHECKERBOARD",
	image = "talents/heal_nature.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCExact = true,
	isKamDoubleWallChance = true,
	isKamDoubleShape = true,
	no_npc_use = true,
	range = 4,
	getSpellNameShape = "Checkerboard of ",
	target = function(self, t)
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_checkerboard(
				x,
				y,
				game.level.map.w,
				game.level.map.h,
				3,
				tg.offset,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="checkerboard", range = getSpellweaveRange(self, t), size = 3, offset = 0, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.85
	end,
	info = function(self, t)
		return ([[Shape your spell into a checkerboard with two alternating effects with size 7 and range %d. Spellweave Multiplier: %0.2f.]]):tformat(getSpellweaveRange(self, t), t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Conjure a checkerboard with size 7 and range %d]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y)
		local makeParticles1 = function(x, y) end
		if (t.isKamDuo1) then 
			makeParticles1 = function(x, y)
				local argsList = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors01(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList)
				argsList = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors02(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList)
			end
		else
			local argsList = {tx = x, ty = y, radius = 0.3, density = 0.5}
			t.getElementColors1(self, argsList, t)
			makeParticles1 = function(x, y)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList)
			end
		end
		
		local makeParticles2 = function(x, y) end
		if (t.isKamDuo2) then 
			makeParticles2 = function(x, y)
				local argsList2 = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors21(self, argsList2, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList2)
				argsList2 = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors22(self, argsList2, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList2)
			end
		else
			local argsList2 = {tx = x, ty = y, radius = 0.3, density = 0.5}
			t.getElementColors2(self, argsList2, t)
			makeParticles2 = function(x, y)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList2)
			end
		end
		KamCalc.kam_calc_checkerboard(
			self,
			x,
			y,
			game.level.map.w,
			game.level.map.h,
			3,
			0,
			function(_, px, py)
				if Target.defaults:block_radius(px, py, false) then return true end
			end,
			function(_, px, py)
				makeParticles1(px, py)
			end,
			function(_, px, py)
				makeParticles2(px, py)
			end,
		nil)
	end,
}

newTalent{ -- Look, so this is bad. But it's dramatic and cool as heck, so it stays.
	name = "Grand Checkerboard",
	short_name = "KAM_SHAPE_HUGE_CHECKERBOARD",
	image = "talents/shield_expertise.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCSelf = true,
	isKamDoubleWallChance = true,
	isKamDoubleShape = true,
	no_npc_use = true,
	range = 0,
	getSpellNameShape = "Grand Checkerboard of ",
	target = function(self, t)
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_checkerboard(
				x,
				y,
				game.level.map.w,
				game.level.map.h,
				9,
				tg.offset,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="checkerboard", range = getSpellweaveRange(self, t), size = 9, offset = 0, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.4
	end,
	info = function(self, t)
		return ([[Shape your spell into a huge checkerboard with size 19, centered on your position. Spellweave Multiplier: %0.1f.]]):tformat(t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a huge checkerboard with size 19, centered on you,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x, ty=y, radius = 10}
		if (t.isKamDuo1) then 
			argsList.density = 0.25
			t.getElementColors01(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x, ty=y, radius = 10, density = 0.25}
			t.getElementColors02(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
		else
			argsList = {tx=x, ty=y, radius = 10, density = 0.5}
			t.getElementColors1(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
		end
		if (t.isKamDuo2) then 
			argsList = {tx=x, ty=y, radius = 10, density = 0.25}
			argsList.density = 0.25
			t.getElementColors21(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x, ty=y, radius = 10, density = 0.25}
			t.getElementColors22(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
		else 
			t.getElementColors2(self, argsList, t)
			game.level.map:particleEmitter(x, y, 10, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Smiley",
	short_name = "KAM_SHAPE_SMILEY",
	image = "talents/sandman.png", -- ... it's a kind of unnerving smile, but a smile it is (and it has no blood or anything so)
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCExact = true,
	isKamNoDigging = true,
	no_npc_use = true,
	range = 6,
	getSpellNameShape = "Smiley Face of ", -- Chaos Chaos.
	target = function(self, t) 
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_make_smiley(
				x,
				y,
				game.level.map.w,
				game.level.map.h,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="kam_smiley", range = getSpellweaveRange(self, t), radius = 3, friendlyfire=false, selffire=false, talent=t, projectHandlerFunction = handlerFunction, isKamSmiley = 1}
	end,
	getPowerModShape = function(self, t)
		return 1.05
	end,
	info = function(self, t)
		return ([[Shape your spell into a smiling face shape with range %d. Spellweave Multiplier: 1.05.
		Due to the complex shape of this spell, you cannot use the Digging mode with it.]]):tformat(getSpellweaveRange(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a spell with a smiley face shape with range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y)
		local startX = x
		local startY = y
		local pointsList = {}
		local specialTargetTable = Target:getType(tg)
		KamCalc:kam_make_smiley(
			x,
			y,
			game.level.map.w,
			game.level.map.h,
			function(_, px, py)
				if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
			end,
			function(_, px, py)
				if py < y then
					local argsList = {tx=px, ty=py, radius = 0.7}
					if (t.isKamDuo) then 
						argsList.density = 0.5
						t.getElementColors11(self, argsList, t)
						game.level.map:particleEmitter(px, py, 0.7, "kam_spellweaver_ball_physical", argsList)
						argsList = {tx=px, ty=py, radius = 0.7, density = 0.5}
						t.getElementColors12(self, argsList, t)
						game.level.map:particleEmitter(px, py, 0.7, "kam_spellweaver_ball_physical", argsList)
					else
						t.getElementColors(self, argsList, t)
						game.level.map:particleEmitter(px, py, 0.7, "kam_spellweaver_ball_physical", argsList)
					end
				else
					table.insert(pointsList, {px, py})
				end
			end,
		nil)
		table.sort(pointsList, function(p1, p2)
			if p1[1] < p2[1] then return true end
		end)
		if (#pointsList == 1) then
			local x, y = pointsList[1], pointsList[2]
			local argsList = {tx=x, ty=y, radius = 0.7}
			if (t.isKamDuo) then 
				argsList.density = 0.5
				t.getElementColors11(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.7, "kam_spellweaver_ball_physical", argsList)
				argsList = {tx=x, ty=y, radius = 0.7, density = 0.5}
				t.getElementColors12(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.7, "kam_spellweaver_ball_physical", argsList)
			else
				t.getElementColors(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.7, "kam_spellweaver_ball_physical", argsList)
			end
		else
			for i = 2, #pointsList do
				local xOne, yOne, xTwo, yTwo = pointsList[i-1][1], pointsList[i-1][2], pointsList[i][1], pointsList[i][2]
				local argsList = {tx=xTwo-xOne, ty=yTwo-yOne}
				if (t.isKamDuo) then
					argsList.density = 0.5
					t.getElementColors11(self, argsList, t)
					game.level.map:particleEmitter(xOne, yOne, math.max(math.abs(xTwo-xOne), math.abs(yTwo-yOne)), "kam_spellweaver_beam", argsList)
					
					argsList = {tx=xTwo-xOne, ty=yTwo-yOne, density = 0.5}
					t.getElementColors12(self, argsList, t)
					game.level.map:particleEmitter(xOne, yOne, math.max(math.abs(xTwo-xOne), math.abs(yTwo-yOne)), "kam_spellweaver_beam", argsList)
				else
					t.getElementColors(self, argsList, t)
					game.level.map:particleEmitter(xOne, yOne, math.max(math.abs(xTwo-xOne), math.abs(yTwo-yOne)), "kam_spellweaver_beam", argsList)
				end
			end
		end
	end,
}

newTalent{ -- flower-twirl
	name = "Abstract Flower",
	short_name = "KAM_SHAPE_FLOWER",
	image = "talents/kam_spellweaver_abstract_flower.png",
--	image = "talents/aura_mastery.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCRand = true,
	isKamDoubleShape = true,
	no_npc_use = true,
	range = 0,
	getSpellNameShape = "Flower of ",
	target = function(self, t) 
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_make_flower(
				x,
				y,
				game.level.map.w,
				game.level.map.h,
				tg.offset,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="kam_flower", range = getSpellweaveRange(self, t), offset = 0, talent=t, friendlyfire=false, selffire=false, isKamFlower = 1, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.7
	end,
	info = function(self, t)
		return ([[Shape your spell into a large abstract flower pattern with approximate radius 5 and two kinds of spells. Spellweave Multiplier: 0.7.]]):tformat()
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a spell into a large abstract flower pattern,]]):tformat()
	end,
	makeParticles = function(self, t, tg, x, y)
		local argsList
		if (t.isKamDuo1) then 
			argsList.density = 0.4
			t.getElementColors01(self, argsList, t)
			game.level.map:particleEmitter(x, y, 6, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x, ty=y, radius = 6, density = 0.4}
			t.getElementColors02(self, argsList, t)
			game.level.map:particleEmitter(x, y, 6, "kam_spellweaver_ball_physical", argsList)
		else
			argsList = {tx=x, ty=y, radius = 6, density = 0.8}
			t.getElementColors1(self, argsList, t)
			game.level.map:particleEmitter(x, y, 6, "kam_spellweaver_ball_physical", argsList)
		end
		if (t.isKamDuo2) then 
			argsList = {tx=x, ty=y, radius = 6, density = 0.4}
			argsList.density = 0.4
			t.getElementColors21(self, argsList, t)
			game.level.map:particleEmitter(x, y, 6, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x, ty=y, radius = 6, density = 0.4}
			t.getElementColors22(self, argsList, t)
			game.level.map:particleEmitter(x, y, 6, "kam_spellweaver_ball_physical", argsList)
		else 
			argsList = {tx=x, ty=y, radius = 6, density = 0.8}
			t.getElementColors2(self, argsList, t)
			game.level.map:particleEmitter(x, y, 6, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Eight Pointed",
	short_name = "KAM_SHAPE_EIGHTPOINT",
	image = "talents/masterful_telekinetic_archery.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCRand = true,
	isKamDoubleShape = true,
	isKamNoCheckCanProject = true,
	no_npc_use = true,
	range = 0,
	getSpellNameShape = "Eightpointed ",
	target = function(self, t) 
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_eightpoint(
				game.level.map.w,
				game.level.map.h,
				5,
				self.x,
				self.y,
				x - self.x,
				y - self.y,
				tg.offset,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="kam_eightpoint", range = getSpellweaveRange(self, t), size = 5, offset = 0, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.8
	end,
	info = function(self, t)
		return ([[Shape your spell into eight lines pointing 5 tiles in all directions from you with two alternating spells. Spellweave Multiplier: 0.8.]]):tformat()
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a spell into eight points of alternating spells pointing 5 tiles from you in all directions,]]):tformat()
	end,
	makeParticles = function(self, t, tg, x, y)
		local particle1func
		if (t.isKamDuo1) then 
			particle1func = function(x, y)
				local argsList = {tx=x-self.x, ty=y-self.y, density = 0.5}
				t.getElementColors01(self, argsList, t)
				game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
				argsList = {tx=x-self.x, ty=y-self.y, density = 0.5}
				t.getElementColors02(self, argsList, t)
				game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
			end
		else
			particle1func = function(x, y)
				local argsList = {tx=x-self.x, ty=y-self.y, density = 1}
				t.getElementColors1(self, argsList, t)
				game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
			end
		end
		if (t.isKamDuo2) then 
			particle2func = function(x, y)
				local argsList = {tx=x-self.x, ty=y-self.y, density = 0.5}
				t.getElementColors21(self, argsList, t)
				game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
				argsList = {tx=x-self.x, ty=y-self.y, density = 0.5}
				t.getElementColors22(self, argsList, t)
				game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
			end
		else 
			particle2func = function(x, y)
				local argsList = {tx=x-self.x, ty=y-self.y, density = 1}
				t.getElementColors2(self, argsList, t)
				game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "kam_spellweaver_beam", argsList)
			end
		end
		local specialTargetTable = Target:getType(tg)
		KamCalc:kam_calc_eightpoint(
			game.level.map.w,
			game.level.map.h,
			5,
			self.x,
			self.y,
			x - self.x,
			y - self.y,
			0,
			function(_, px, py)
				if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
			end,
			function(_, px, py)
				particle1func(px, py)
			end,
			function(_, px, py)
				particle2func(px, py)
			end,
		nil)
	end,
}

newTalent{
	name = "Double Spiral",
	short_name = "KAM_SHAPE_DOUBLE_SPIRAL",
	image = "talents/anomaly_sphere_of_destruction.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCRand = true,
	isKamDoubleShape = true,
	isKamNoCheckCanProject = true,
	no_npc_use = true,
	range = 0,
	getSpellNameShape = "Doublespiraling ",
	target = function(self, t) 
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_doublespiral(
				self.x,
				self.y,
				game.level.map.w,
				game.level.map.h,
				tg.offset,
				6,
				self.x,
				self.y,
				x - self.x,
				y - self.y,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="kam_doublespiral", range = getSpellweaveRange(self, t), size = 6, offset = 0, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.7
	end,
	info = function(self, t)
		return ([[Shape your spell into two spirals of alternating spells with size 6. Spellweave Multiplier: 0.7.]]):tformat()
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast a spell into two spirals of alternating spells with size 6,]]):tformat()
	end,
	makeParticles = function(self, t, tg, x, y)
		local particle1func
		local toApply1
		local toApply2
		if (t.isKamDuo1) then 
			local argsList = {tx=0, ty=0, radius = 0.6, density = 0.5}
			local argsList2 = {tx=0, ty=0, radius = 0.6, density = 0.5}
			t.getElementColors01(self, argsList, t)
			t.getElementColors02(self, argsList2, t)
			toApply1 = function(prevX, prevY, curX, curY)
				argsList.tx = curX - prevX 
				argsList.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList)
				argsList.tx = prevX - curX 
				argsList.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList)
				argsList.tx = curX
				argsList.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList)
				
				argsList2.tx = curX - prevX 
				argsList2.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList2)
				argsList2.tx = prevX - curX 
				argsList2.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList2)
				argsList2.tx = curX
				argsList2.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList2)
			end
		else
			local argsList = {tx=0, ty=0, radius = 0.6, density = 0.5}
			t.getElementColors1(self, argsList, t)
			toApply1 = function(prevX, prevY, curX, curY)
				argsList.tx = curX - prevX 
				argsList.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList)
				argsList.tx = prevX - curX 
				argsList.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList)
				argsList.tx = curX
				argsList.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList)
			end
		end
		if (t.isKamDuo2) then 
			local argsList = {tx=0, ty=0, radius = 0.6, density = 0.5}
			local argsList2 = {tx=0, ty=0, radius = 0.6, density = 0.5}
			t.getElementColors21(self, argsList, t)
			t.getElementColors22(self, argsList2, t)
			toApply2 = function(prevX, prevY, curX, curY)
				argsList.tx = curX - prevX 
				argsList.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList)
				argsList.tx = prevX - curX 
				argsList.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList)
				argsList.tx = curX
				argsList.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList)
				
				argsList2.tx = curX - prevX 
				argsList2.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList2)
				argsList2.tx = prevX - curX 
				argsList2.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList2)
				argsList2.tx = curX
				argsList2.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList2)
			end
		else 
			local argsList = {tx=0, ty=0, radius = 0.6, density = 0.5}
			t.getElementColors2(self, argsList, t)
			toApply2 = function(prevX, prevY, curX, curY)
				argsList.tx = curX - prevX 
				argsList.ty = curY - prevY
				game.level.map:particleEmitter(prevX, prevY, math.max(math.abs(curX - prevX), math.abs(curY - prevY)), "kam_spellweaver_beam", argsList)
				argsList.tx = prevX - curX 
				argsList.ty = prevY - curY
				game.level.map:particleEmitter(curX, curY, math.max(math.abs(prevX - curX), math.abs(prevY - curY)), "kam_spellweaver_beam", argsList)
				argsList.tx = curX
				argsList.ty = curY
				game.level.map:particleEmitter(curX, curY, 0.6, "kam_spellweaver_ball_physical", argsList)
			end
		end
		local specialTargetTable = Target:getType(tg)
		KamCalc:kam_calc_doublespiral_endpoints(
			self.x,
			self.y,
			game.level.map.w,
			game.level.map.h,
			0,
			6,
			self.x,
			self.y,
			x - self.x,
			y - self.y,
			function(_, px, py)
				if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
			end,
			toApply1,
			toApply2,
		nil)
	end,
}

newTalent{
	name = "Wavepulse",
	short_name = "KAM_SHAPE_WAVEPULSE",
	image = "talents/lay_web.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCSelf = true,
	isKamDoubleShape = true,
	no_npc_use = true,
	range = 0,
	getSpellNameShape = "Wavepulse of ",
	target = function(self, t)
		local handlerFunction = function(self, apply, tg, x, y, args)
			local specialTargetTable = Target:getType(tg)
			local grids = {}
			KamCalc:kam_calc_wavepulse(
				x,
				y,
				game.level.map.w,
				game.level.map.h,
				4,
				tg.offset,
				function(_, px, py)
					if specialTargetTable.block_radius and specialTargetTable:block_radius(px, py) then return true end
				end,
				function(_, px, py)
					addGrid(tg, px, py, grids)
					apply(self, tg, px, py, unpack(args))
				end,
			nil)
			return grids
		end
		return {type="wavepulse", range = getSpellweaveRange(self, t), size = 4, offset = 0, talent=t, friendlyfire=false, selffire=false, projectHandlerFunction = handlerFunction}
	end,
	getPowerModShape = function(self, t)
		return 0.7
	end,
	info = function(self, t)
		return ([[Shape your spell into a pulse of two alternating spells. Spellweave Multiplier: %0.1f.]]):tformat(t.getPowerModShape(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Cast alternating rings in a radius 4 ball,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local makeParticles1 = function(x, y) end
		if (t.isKamDuo1) then 
			makeParticles1 = function(x, y) 
				local argsList = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors01(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList)
				argsList = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors02(self, argsList, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList)
			end
		else
			local argsList = {tx = x, ty = y, radius = 0.3, density = 0.5}
			t.getElementColors1(self, argsList, t)
			makeParticles1 = function(x, y)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList)
			end
		end
		
		local makeParticles2 = function(x, y) end
		if (t.isKamDuo2) then 
			makeParticles2 = function(x, y)
				local argsList2 = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors21(self, argsList2, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList2)
				argsList2 = {tx = x, ty = y, radius = 0.3, density = 0.25}
				t.getElementColors22(self, argsList2, t)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList2)
			end
		else
			local argsList2 = {tx = x, ty = y, radius = 0.3, density = 0.5}
			t.getElementColors2(self, argsList2, t)
			makeParticles2 = function(x, y)
				game.level.map:particleEmitter(x, y, 0.3, "kam_spellweaver_ball_physical", argsList2)
			end
		end
		KamCalc:kam_calc_wavepulse(
			x,
			y,
			game.level.map.w,
			game.level.map.h,
			4,
			0,
			function(_, px, py)
				if Target.defaults:block_radius(px, py, false) then return true end
			end,
			function(_, px, py)
				makeParticles1(px, py)
			end,
			function(_, px, py)
				makeParticles2(px, py)
			end,
		nil)
	end,
}

newTalent{
	name = "Touch",
	short_name = "KAM_SHAPE_TOUCH",
	image = "talents/grappling_stance.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCBeam = true,
	isKamDoubleWallChance = true,
	no_npc_use = true,
	getSpellNameShape = "Touch of ",
	range = 1,
	target = function(self, t) 
		return {type="bolt", range = getSpellweaveRange(self, t), friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 1.4 -- big numbers, the worst range and targeting.
	end,
	info = function(self, t)
		local rangeText = "adjacent to you"
		local radText = ""
		if game:isAddonActive("orcs") then
			if self:isTalentActive(self.T_RANGE_AMPLIFICATION_DEVICE) then
				rangeText = "within range two"
			end
			radText = [[ If you are sustaining Range Amplification Device, this talent's range becomes 2 as you use the device with your teleportation magic to project the touch a short distance.]]
		end
		return ([[Shape your spell into an touch that hits one enemy %s. Spellweave Multiplier: 1.4.%s]]):tformat(rangeText, radText)
	end,
	getSpellShapeInfo = function(self, t) 
		local rangeText = "adjacent enemy"
		if self:isTalentActive(self.T_RANGE_AMPLIFICATION_DEVICE) then
			rangeText = "enemy within range two"
		end
		return ([[Tap an %s with a powerful burst of magic,]]):tformat(rangeText)
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=x-self.x, ty=y-self.y, radius=0.5, density = 2}
		if (t.isKamDuo) then
			argsList.density = 0.5
			t.getElementColors11(self, argsList, t)
			game.level.map:particleEmitter(x, y, 0.5, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=x-self.x, ty=y-self.y, radius=0.5, density = 1}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(x, y, 0.5, "kam_spellweaver_ball_physical", argsList)
			
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(x, y, 0.5, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{ -- Designed to fill the same shape as entomb.
	name = "Square",
	short_name = "KAM_SHAPE_SQUARE",
	image = "talents/anomaly_entomb.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamASCExact = true,
	no_npc_use = true,
	range = 6,
	getSpellNameShape = "Square of ",
	target = function(self, t) 
		return {type="ball", range = getSpellweaveRange(self, t), radius = 1, friendlyfire=false, selffire=false, talent=t}
	end,
	getPowerModShape = function(self, t)
		return 1
	end,
	info = function(self, t)
		return ([[Shape your spell into a three by three sequare with range %d. Spellweave Multiplier: 1.]]):tformat(getSpellweaveRange(self, t))
	end,
	getSpellShapeInfo = function(self, t) 
		return ([[Conjure a 3 by 3 square within range %d,]]):tformat(getSpellweaveRange(self, t))
	end,
	makeParticles = function(self, t, tg, x, y) 
		local argsList = {tx=2, ty=0, density = 0.5, radius = 1.5}
		if (t.isKamDuo) then
			argsList.density = 0.25
			t.getElementColors11(self, argsList, t)
			
			game.level.map:particleEmitter(x-1, y, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = 0
			argsList.ty = 2
			game.level.map:particleEmitter(x, y-1, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = -2
			argsList.ty = 0
			game.level.map:particleEmitter(x+1, y, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = 0
			argsList.ty = -2
			game.level.map:particleEmitter(x, y+1, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = x 
			argsList.ty = y
			game.level.map:particleEmitter(x, y, 1.5, "kam_spellweaver_ball_physical", argsList)
			argsList = {tx=2, ty=0, density = 0.25, radius = 1.5}
			t.getElementColors12(self, argsList, t)
			game.level.map:particleEmitter(x-1, y, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = 0
			argsList.ty = 2
			game.level.map:particleEmitter(x, y-1, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = -2
			argsList.ty = 0
			game.level.map:particleEmitter(x+1, y, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = 0
			argsList.ty = -2
			game.level.map:particleEmitter(x, y+1, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = x 
			argsList.ty = y
			game.level.map:particleEmitter(x, y, 1.5, "kam_spellweaver_ball_physical", argsList)
		else
			t.getElementColors(self, argsList, t)
			game.level.map:particleEmitter(x-1, y, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = 0
			argsList.ty = 2
			game.level.map:particleEmitter(x, y-1, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = -2
			argsList.ty = 0
			game.level.map:particleEmitter(x+1, y, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = 0
			argsList.ty = -2
			game.level.map:particleEmitter(x, y+1, 2, "kam_spellweaver_wide_beam", argsList)
			argsList.tx = x 
			argsList.ty = y
			game.level.map:particleEmitter(x, y, 1.5, "kam_spellweaver_ball_physical", argsList)
		end
	end,
}

newTalent{
	name = "Barrage",
	short_name = "KAM_SHAPE_BARRAGE",
	image = "talents/spatial_fragments.png",
	type = {"spellweaving/shapes", 1},
	points = 1,
	mode = "passive",
	isKamShape = true,
	isKamDoubleWallChance = true,
	isKamBarrage = true, -- 
	no_npc_use = true,
	getSpellNameShape = "Triple ",
	target = function(self, t) 
		return nil
	end,
	getPowerModShape = function(self, t)
		return 0.3
	end,
	info = function(self, t)
		return ([[Instead of just applying a spell once, choose another shape and apply it three times, such that enemies can be hit by any number of the applications. Spellweave Multiplier: 0.3.]])
	end,
	getSpellShapeInfo = "three",
	makeParticles = function(self, t, tg, x, y) 
		return nil
	end,
}