local q = game.player:hasQuest("start-spellweaver")
local q2 = game.player:hasQuest("kam-spellweaver-second-quest")
local Talents = require "engine.interface.ActorTalents"
local player = game.player

if q then
	if not q:isCompleted("defeat-controller") then

		newChat{ id = "welcome",
			text = _t[[#WHITE#Do you need something, @playername@?]],
			answers = {
				{_t"No, thank you."},
				{_t"Do you need help with anything?", jump="come-back-later"}
			}
		}

		newChat{ id = "come-back-later",
			text = _t[[#WHITE#Not anything you can help with right now. I do have a problem I could use help with, but maybe after you have a bit more field work finished.]],
			answers = {
				{_t"Alright."}
			}
		}
		
	elseif not q:isCompleted("return") then
	
		newChat{ id = "welcome",
			text = _t[[#WHITE#Welcome back, @playername@. I'm glad you're alright. You should go talk to Professor Hundredeyes though. We have all been worried about you, but they took it harder than the rest of us. Once you do inform Hundredeyes, I could potentially use your help with something, if you would be willing.]],
			answers = {
				{_t"Will do."}
			}
		}
	
	elseif not q2 then

		newChat{ id = "welcome",
			text = _t[[#WHITE#Welcome back, @playername@. I'm glad you're alright. I heard you say to Professor Hundredeyes that you went all the way to Maj'Eyal and back. It seems like you have grown greatly as a Spellweaver. Actually, I think you might be able to help me with something, if you were willing.]],
			answers = {
				{_t"What do you need?", jump = "quest-info"},
				{_t"I can't, I need to get the Staff of Absorption back quickly."}
			}
		}
		
		newChat{ id = "quest-info",
text = _t[[#WHITE#I heard from a contact of mine that some of the Vor Pride mages discovered an old ruin that shows signs of Spellwoven magic. It's probably about four hundred years old, which puts it fairly early in the time of Spellweavers. There's no records of it or any real signs of anything important there, and Spellweavers haven't historically built much outside of Wovenhome, but just in case, could you go take a look? Hundredeyes has done a lot for us, and I would hate to see any kind of Spellweaving used against us.]],
			answers = {
				{_t"I can take a look.", jump="accept"},
				{_t"I should focus on finding the Staff of Absorption."}
			}
		}
		
		newChat{ id = "accept",
text = _t[[#WHITE#Thanks. If you head north and then follow the first river upstream into the mountains, you should find it.]],
			answers = {
				{_t"I'll let you what I find.", action = function(_, player)
					player:grantQuest("kam-spellweaver-second-quest")
				end}
			}
		}
		
	elseif q2 and not q2:isCompleted("defeat-tyrant") then

		newChat{ id = "welcome",
			text = _t[[#WHITE#Have you had time to look into the ruin yet?]],
			answers = {
				{_t"Not yet."}
			}
		}

	elseif q2 and not q2:isCompleted("turned-in") then

		newChat{ id = "welcome",
			text = _t[[#WHITE#Have you had time to look into the ruin yet?]],
			answers = {
				{_t"I have.", jump = "turn-in"}
			}
		}

		newChat{ id = "turn-in",
			text = _t[[#WHITE#Did you find anything of note?]],
			answers = {
				{_t"(Explain the situation at the Elemental Ruins.)", jump = "complete"}
			}
		}

		newChat{ id = "turn-in",
text = _t[[#WHITE#... oh dear. I thought that any Spellweaving magic in a four hundred year old ruin would be harmless. At worst, I thought you would need to grab some abandoned Spellweaving texts to keep them away from the Vor Pride. But an elemental like that?
Well, I apologize @playername@. You've done far more than I would have expected from you. Take this. It's not much, but hopefully it can help you out. Also, if you ever need any help, feel free to call on us. I think some of the Wovenhome orcs have been a bit more interested in adventuring since they heard of your adventures.]],
			answers = {
				{_t"Thank you."}
			}
		}
		
	else

		newChat{ id = "welcome",
			text = _t[[#WHITE#Best of luck on your journey, @playername@.]],
			answers = {
				{_t"Thank you."}
			}
		}

	end

	return "welcome"
else 
	newChat{ id = "welcome",
text = _t[[#GREEN#A somewhat shorter orc stands in front of you, in Spellweaver's robes.
#WHITE#Do you need something?]],
		answers = {
			{_t"No, thank you."},
			{_t"Who are you?", jump="who"}
		}
	}

	newChat{ id = "who",
		text = _t[[#WHITE#I am Grath, of the Wovenhome orcs. We mean no harm, and have split off from the Prides because they turned against us. If you mean us no harm, we guarentee the same to you.]],
		answers = {
			{_t"Okay."}
		}
	}
	
	return "welcome"
end