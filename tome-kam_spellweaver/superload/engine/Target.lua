local _M = loadPrevious(...)

require "engine.class"
local Map = require "engine.Map"
local Target = require "engine.Target"
local DamageType = require "engine.DamageType"
local KamCalc = require "mod.KamHelperFunctions"

--- Handles actors projecting damage to zones/targets
-- @classmod engine.generator.interface.ActorProject
module(..., package.seeall, class.make)

local base_createTextures = _M.createTextures -- Create purple targeting color for double shapes.
function _M:createTextures()
	base_createTextures(self)
	local pot_width = math.pow(2, math.ceil(math.log(self.tile_w-0.1) / math.log(2.0)))
	local pot_height = math.pow(2, math.ceil(math.log(self.tile_h-0.1) / math.log(2.0)))
	self.kamPurple = core.display.newSurface(pot_width, pot_height)
	self.kamPurple:erase(255, 0, 255, self.fbo and 150 or 90)
	self.kamPurple = self.kamPurple:glTexture()
end

return _M