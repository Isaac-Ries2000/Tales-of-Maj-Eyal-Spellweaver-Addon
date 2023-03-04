local _M = loadPrevious(...)

require "engine.class"

module(..., package.seeall, class.make)

local base_getTalentCooldown = _M.getTalentCooldown
function _M:getTalentCooldown(t, base) -- Fairly safe superload barring significant changes to cooldowns. Reduces cooldown for inscriptions if the user knows the relevant talent.
	local cd = base_getTalentCooldown(self, t, base)
	
	if self:knowTalent(self.T_KAM_WOVENHOME_ORC_SURVIVALIST) and t.type[1]:find("^inscriptions/") then
		local tal = self:getTalentFromId(self.T_KAM_WOVENHOME_ORC_SURVIVALIST)
		cd = math.ceil(cd * (1 - (tal.runeReduction(self, t) / 100)))
	end
	return cd
end