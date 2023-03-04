local player = game.player

local KamCalc = require "mod.KamHelperFunctions"
local Talents = require "engine.interface.ActorTalents"

local specialCondition = player:knowTalent(player.T_EQUILIBRIUM_POOL) or KamCalc:isAllowInscriptions(player)
local teleportCondition = false
local q = game.player:hasQuest("start-spellweaver")

if not specialCondition then
	local count = player:getTalentLevelRaw(player.T_KAM_SPELLWEAVER_WARP_CORE)
	count = count + player:getTalentLevelRaw(player.T_KAM_SPELLWEAVER_WARP_FIZZLE)
	count = count + player:getTalentLevelRaw(player.T_KAM_SPELLWEAVER_WARP_PRECISION)
	count = count + player:getTalentLevelRaw(player.T_KAM_SPELLWEAVER_TELEPORT_MASTERY)
	if count > 15 then
		specialCondition = true
		teleportCondition = true
	end
end

if not player.subclass == "Spellweaver" then

newChat{ id = "welcome",
text = _t[[Oh, @playername@! I heard you came here from Maj'Eyal from a farportal. Best of luck on your adventures!]],
	answers = {
		{_t"Thank you."}
	}
}

elseif (not q) and (not player.kam_talked_to_professor_arbus) and (not specialCondition) then

newChat{ id = "welcome",
text = _t[[Oh, @playername@! I heard you came here from Maj'Eyal. We didn't know that there was anyone practicing Spellweaving magic in the West before.]],
	answers = {
		{_t"Yes, although not as much as here."}
		{_t"Do you need any help?", jump = "hinttext"},
	}
}

newChat{ id = "hinttext", -- Nature/teleportation hint hint.
text = _t[[Nah, not really. I'm just enjoying nature before I have more teaching to do. I'll be doing some teaching on teleporting and nature-based Spellweaving today, so I have to be prepared.]],
	answers = {
		{_t"Makes sense."}
	}
}


elseif (not player.kam_talked_to_professor_arbus) and (not specialCondition) then

newChat{ id = "welcome",
text = _t[[Oh, @playername@! You here to smell the flowers?]],
	answers = {
		{_t"Yes, I just wanted to see the garden."}
		{_t"Do you need any help?", jump = "hinttext"},
	}
}

newChat{ id = "hinttext", -- Nature/teleportation hint hint.
text = _t[[Nah, not really. I'm just enjoying nature before I have more teaching to do. I'll be doing some teaching on teleporting and nature-based Spellweaving today, so I have to be prepared.]],
	answers = {
		{_t"Makes sense."}
	}
}

elseif not player.kam_talked_to_professor_arbus and not teleportCondition then

newChat{ id = "welcome",
text = _t[[#LIGHT_GREEN#Professor Arbus cheerfully looks at you.
#WHITE#Ooh, @playername@, I can just feel that natural power radiating from you.]],
	answers = {
		{_t"Huh?", jump="nature"}
	}
}

newChat{ id = "nature",
text = _t[[You've been augmenting your Spellweaving knowledge with nature, I can just tell.
You know, as another person interested in Spellweaving and Nature, I suppose I could give you a special Spellweaving technique.]],
	answers = {
		{_t"Oh, thank you, Professor.", jump="nature2"}
	}
}

newChat{ id = "nature2",
text = _t[[Oh, just call me Arbus, the title is way too much formality. 
Anyways, just envision the flow of natural energy and magical energies. Think about them as two seperate spirals, coming forth from you. If you think about the flow of energies that way, you can make two spirals at once.]],
	answers = {
		{_t"Thank you.", jump="nature-finish"}
	}
}

newChat{ id = "nature-finish",
text = _t[[Of course! Use it well, it's one of my favorite little tricks in Spellweaving.]],
	answers = {
		{_t"Of course, Arbus.", action = function(_, player)
			player:learnTalent(Talents.T_KAM_SHAPE_DOUBLE_SPIRAL, true)
			player.kam_talked_to_professor_arbus = true
			game.log("#YELLOW#You have learned the Double Spiral Spell Shape!")
		end}
	}
}

elseif not player.kam_talked_to_professor_arbus then

newChat{ id = "welcome",
text = _t[[#LIGHT_GREEN# Professor Arbus looks at you with interest.
#WHITE#You know, @playername@, I can tell that you've learned a lot about teleportation magic.]],
	answers = {
		{_t"Huh?", jump="teleport"}
	}
}

newChat{ id = "teleport",
text = _t[[Your Spellwoven teleportation is impressive. Nearly every Spellweaver learns the basics, but most never really master it like you have.
You know, for another person who really specializes in it, I think I can teach you my special Spellweaving technique.]],
	answers = {
		{_t"Oh, thank you, Professor.", jump="teleport2"}
	}
}

newChat{ id = "teleport2",
text = _t[[Oh, just call me Arbus, the title is way too much formality.
Now, consider the spiral shape that I've talked about in my classes. Now, divide that energy up a bit to form a second one and concentrate it a little bit away.
If you try that a few times, you should be able to form two interlocking spirals.]],
	answers = {
		{_t"Thank you.", jump="teleport-finish"}
	}
}

newChat{ id = "teleport-finish",
text = _t[[Of course! Use it well, it's one of my favorite little tricks in Spellweaving.]],
	answers = {
		{_t"Of course, Arbus.", action = function(_, player)
			player:learnTalent(Talents.T_KAM_SHAPE_DOUBLE_SPIRAL, true)
			player.kam_talked_to_professor_arbus = true
			game.log("#YELLOW#You have learned the Double Spiral Spell Shape!")
		end}
	}
}

else

newChat{ id = "welcome",
text = _t[[Ah, @playername@. How has adventuring been treating you?]],
	answers = {
		{_t"*Spend a while talking about adventuring and nature with Arbus.*"}
	}
}
end

return "welcome"