local player = game.player

newChat{ id = "welcome",
text = _t[[#WHITE#Ah, @playername@. Since you requested more field work, we have something that should be nice and easy to start you out with.
Recently, the Spellweaver Kia has stopped sending us their regular food shipments that we get in exchange for assisting in their research. We are a little worried about Kia. We doubt orcs would have made it there, but either way, we need you to go there and check it out. Help Kia if possible, although if things are too dangerous, come and get one of us.
Now, I don't know how much time you took to prepare, so let me know when you're ready.]],
	answers = {
		{_t"I will."},
		{_t"I am ready now.", jump="send-to-woven-woods"}
	}
}
newChat{ id = "send-to-woven-woods",
	text = _t[[#WHITE#Then I will send you there. Take this teleportation scroll and use it when you need to get back. It should work as long as magic is not too disturbed where you are.]],
	answers = {
		{_t"I will return soon.", action = function(npc, player)
			game:changeLevel(1, "kam-spellweaver-woven-woods")
		end},
	}
}

return "welcome"
