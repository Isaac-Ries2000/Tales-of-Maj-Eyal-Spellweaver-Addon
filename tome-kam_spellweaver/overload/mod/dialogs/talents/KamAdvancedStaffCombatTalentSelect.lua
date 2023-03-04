-- Largely a copy of the dialogue MagicalCombatArcaneCombat from Arcane Combat
require "engine.class"
local Dialog = require "engine.ui.Dialog"
local TreeList = require "engine.ui.TreeList"
local ListColumns = require "engine.ui.ListColumns"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"

module(..., package.seeall, class.inherit(Dialog))

-- Generate talent status separately to enable quicker refresh of Dialog
local function TalentStatus(who,t) 
	local status = tstring{{"color", "LIGHT_GREEN"}, "Active"} 

	return tostring(status) 
end

function _M:init(actor)
	self.actor = actor
	actor.hotkey = actor.hotkey or {}
	Dialog.init(self, _t"Advanced Staff Combat", game.w * 0.6, game.h * 0.8)

	local vsep = Separator.new{dir="horizontal", size=self.ih - 10}
	self.c_tut = Textzone.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=1, auto_height=true, no_color_bleed=true, text=_t[[
You may select a Spellwoven Attack spell for Arcane Combat to trigger first. If that spell is on cooldown, or if you select 'Random spells', a random spell will be selected each time.
]]}
	self.c_desc = TextzoneList.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=self.ih - self.c_tut.h - 20, scrollbar=true, no_color_bleed=true}

	self:generateList()

	local cols = {
		{name=_t"", width={40,"fixed"}, display_prop="char"},
		{name=_t"Talent", width=80, display_prop="name"},
	}
	self.c_list = TreeList.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=self.ih - 10, all_clicks=true, scrollbar=true, columns=cols, tree=self.list, fct=function(item, sel, button) self:use(item, button) end, select=function(item, sel) self:select(item) end}
	self.c_list.cur_col = 2

	self:loadUI{
		{left=0, top=0, ui=self.c_list},
		{right=0, top=self.c_tut.h + 20, ui=self.c_desc},
		{right=0, top=0, ui=self.c_tut},
		{hcenter=0, top=5, ui=vsep},
	}
	self:setFocus(self.c_list)
	self:setupUI()

	self.key:addCommands{
		__TEXTINPUT = function(c)
			if c == '~' then
				self:use(self.cur_item)
			end
			if self.list and self.list.chars[c] then
				self:use(self.list.chars[c])
			end
		end,
	}
	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:select(item)
	if item then
		self.c_desc:switchItem(item, item.desc)
		self.cur_item = item
	end
end

-- Don't close the dialog until the player clicks an appropriate option
function _M:use(item)
	if item and (item.talent or item.use_random) then
		self.actor:talentDialogReturn(item.talent, item.use_random)
		game:unregisterDialog(self)
	else
		return
	end
end

-- Display the player tile
function _M:innerDisplay(x, y, nb_keyframes)
	if self.cur_item and self.cur_item.entity then
		self.cur_item.entity:toScreen(game.uiset.hotkeys_display_icons.tiles, x + self.iw - 64, y + self.iy + self.c_tut.h - 32 + 10, 64, 64)
	end
end

function _M:generateList()
	local list = {}
	local letter = 1

	local talents = {}
	local chars = {}

	for _, t in pairs(self.actor.talents_def) do
		if t.isKamAttackSpell and self.actor:knowTalent(t) then
			local status = tstring{{"color", "LIGHT_GREEN"}, "Talents"}
			
			-- Pregenerate icon with the Tiles instance that allows images
			if t.display_entity then t.display_entity:getMapObjects(game.uiset.hotkeys_display_icons.tiles, {}, 1) end

			talents[#talents+1] = {
				name = ((t.display_entity and t.display_entity:getDisplayString() or "")..t.name):toTString(),
				cname = t.name,
				status = status,
				entity = t.display_entity,
				talent = t.id,
				desc = self.actor:getTalentFullDescription(t),
				slot=t.kamSpellSlotNumber,
				color = function() return {0xFF, 0xFF, 0xFF} end
			}
		end
	end

	table.sort(talents, function(s1, s2) return s1.slot < s2.slot end)
	
	talents[#talents+1] = {
		name = _t"Random spells",
		use_random = true,
		desc = _t"Don't priorize any specific spell. Whenever Advanced Staff Combat triggers, just use any random spell."
	}
	
	for _, node in ipairs(talents) do
		node.char = self:makeKeyChar(letter)
		chars[node.char] = node
		letter = letter + 1
	end

	list = {
		{ char='', name=(_t'#{bold}#Choose a spell#{normal}#'):toTString(), status='', hotkey='', desc=_t"All known Spellwoven Attack spells.", color=function() return colors.simple(colors.LIGHT_GREEN) end, nodes=talents, shown=true },
		chars = chars,
	}
	self.list = list
end
