local q = game.player:hasQuest("start-spellweaver")
local Talents = require "engine.interface.ActorTalents"
local player = game.player

if q then

	if q and not q:isCompleted("defeat-controller") then

		newChat{ id = "welcome",
			text = _t[[#WHITE#Ah, @playername@. Have you taken sufficient time to prepare?]],
			answers = {
				{_t"I am ready.", jump="send-to-woven-woods"},
				{_t"I need more time."}
			}
		}
		
	elseif q and not q:isCompleted("return") then

		newChat{ id = "welcome",
			text = _t[[#WHITE#@playername@! You're back! We thought you had died or been stranded somewhere. Kia told us about what happened, but we couldn't find you anywhere on Var'Eyal. Where have you been?]],
			answers = {
				{_t"(Explain your journey to Professor Hundredeyes)", jump = "returning2"}
			}
		}
		
		newChat{ id = "returning2",
text = _t[[#WHITE#Maj'Eyal. None of us Spellweavers have ever been able to make it there, although I have heard that Zemekkys has had some kind of Farportal experiment that might help.
Wait, you said that you found a staff capable of absorbing magic, that felt incredibly powerful, and was grey?
Ifnai, does that sound like the Staff of Absorption to you? 
#SLATE#*Ifnai nods*#WHITE#
@playername@, we need you to get that back. I saw some strange sorcerers examining the High Peak Farportal through my Arcane Eyes, and Grath told me about orcs from the Prides moving some kind of artifact to High Peak. If they know how to tap into the Staff's power, they could use that Farportal to bring about the end of the world. I know we've avoided fighting the orcs, but I don't see any other options. I think you're a better fighter than us right now, so you'll need to be the one to do this. I don't know where all of the orcish Prides are, but Aeryn should be able to tell you. Just try not to hurt any more orcs than you need to. Can we count on you to get that staff safely back so we can seal it away?]],
			answers = {
				{_t"Yes, I will retrieve the staff.", player:setQuestStatus("start-spellweaver", engine.Quest.COMPLETED, "return"), jump="hundredeyes"}
			}
		}
		
		newChat{ id = "hundredeyes",
text = _t[[#WHITE#... you know, you've really come a long way as a Spellweaver since we sent you out to check on Kia. You have clearly learned so much being out there.
Here, let me show you one of my favorite little tricks in Spellweaving. It is not terribly powerful or anything, but it's still one of my favorite little things I have learned.]],
			answers = {
				{_t"Thank you, Professor Hundredeyes.", action = function(_, player)
					player:learnTalent(Talents.T_KAM_SHAPE_FLOWER, true)
					player.kam_talked_to_professor_hundredeyes = true
					game.log("#YELLOW#You have learned the Abstract Flower Spell Shape!")
				end}
			}
		}
		
	else

		newChat{ id = "welcome",
			text = _t[[#WHITE#Good to see you again, @playername@. Learned anything interesting in Spellweaving lately?
#LIGHT_GREEN#You take a minute to discuss Spellweaving with Professor Hundredeyes.]],
			answers = {
				{_t"Bye!"}
			}
		}

	end

	newChat{ id = "send-to-woven-woods",
		text = _t[[#WHITE#Then I will send you there. Take this teleportation scroll and use it when you need to get back. It should work as long as magic is not too disturbed where you are.]],
		answers = {
			{_t"I will return soon.", action = function(npc, player)
				game:changeLevel(1, "kam-spellweaver-woven-woods")
			end},
		}
	}

	return "welcome"
else 
	newChat{ id = "welcome",
		text = _t[[#WHITE#Ah, @playername@. Welcome to Wovenhome. Let one of us professors know if you need help finding anything.]],
		answers = {
			{_t"I will."},
			{_t"Wait, how did you know my name?", jump="professor-hundredeyes"}
		}
	}

	newChat{ id = "professor-hundredeyes",
		text = _t[[#WHITE#I am Professor Hundredeyes. Whatever happens in Var'Eyal, I know.]],
		answers = {
			{_t"Okay."}
		}
	}
	
	return "welcome"
end