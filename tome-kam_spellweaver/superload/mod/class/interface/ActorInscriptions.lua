local _M = loadPrevious(...)

require "engine.class"
local KamCalc = require "mod.KamHelperFunctions"

module(..., package.seeall, class.make)

local base_getInscriptionData = _M.getInscriptionData
function _M:getInscriptionData(name) -- Should be a fairly safe superload, barring a change to runes.
	local doChange = false
	if (name:find("RUNE") or name:find("TAINT") or (KamCalc:isAllowInscriptions(self) and name:find("INFUSION"))) and self:knowTalent(self.T_KAM_RUNIC_ADAPTION) then -- Just set fakes to use_any_stat for display.
		if (self.__inscription_data_fake) then
			self.__inscription_data_fake.kam_old_use_any_stat = self.__inscription_data_fake.use_any_stat
			doChange = true
			local tal = self:getTalentFromId(self.T_KAM_RUNIC_ADAPTION)
			self.__inscription_data_fake.use_any_stat = 1 + tal.getScalingBonus(self, tal) / 100
		end
	end
	local retval = base_getInscriptionData(self, name)
	if (doChange) then 
		self.__inscription_data_fake.use_any_stat = self.__inscription_data_fake.kam_old_use_any_stat
		self.__inscription_data_fake.kam_old_use_any_stat = nil
	end
	return retval
end