local _M = loadPrevious(...)

require "engine.class"
local Map = require "engine.Map"
local Target = require "engine.Target"
local DamageType = require "engine.DamageType"
local KamCalc = require "mod.KamHelperFunctions"

--- Handles actors projecting damage to zones/targets
-- @classmod engine.generator.interface.ActorProject
module(..., package.seeall, class.make)

-- Quick cheat to make it so that Harmonic Paradise halves things BEFORE they can be removed.
local base_timedEffects = _M.timedEffects
function _M:timedEffects(filter)
	if self:hasEffect(self.EFF_KAM_SPELLWEAVER_METAPARADISE) then
		local effs = {}
		for eff, p in pairs(self.tmp) do
			effs[eff] = p
		end
		for eff, p in pairs(effs) do
			def = _M.tempeffect_def[eff]
			if (not filter or filter(def, p)) and def.status == "beneficial" and def.name ~= "KAM_SPELLWEAVER_METAPARADISE" then
				p.dur = p.dur + def.decrease / 2
			end
		end
	end
	base_timedEffects(self, filter)
end

return _M