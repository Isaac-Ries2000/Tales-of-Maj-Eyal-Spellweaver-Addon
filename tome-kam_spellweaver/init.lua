-- This addon entirely came from me saying "Okay, so I can create and edit talents on the fly, not just when I make a class. What if I made a class where that was the whole gimmick?"
--
-- This is a ToME addon, you can edit it as you wish.
-- But also my codestyle is kinda terrible because I've basically been doing that thing where people start working on stuff, then run into problems because of how they designed something
-- and instead of changing everything, just build a workaround. So you can edit this, but please don't code like this if anyone else might read it. It could be worse but.
--
-- Kamani Arbus
-- shiningterrapin@gmail.com

-- So, as a note: When new resources are added to ToME, the resource omni-drain must be updated (see manastorm and the one shield bonus)

long_name = "Class: Spellweaver"
short_name = "kam_spellweaver"
for_module = "tome"
version = {1,7,4}
addon_version = { 0, 2, 16 }
weight = 15
author = { "Kamani", "shiningterrapin@gmail.com" }
homepage = "None yet"
description = [[Adds the Spellweaver, a Mage subclass who creates custom spells with Spellweaving components.
For example, a Spellweaver might make a spell using the Fire element, the Beam shape, and the Damage Over Time effect to make a simple Damage over Time Fire Beam. However, spells can get vastly more complicated, with things like a "Grand Checkerboard of Eclipsing and Feverish Wallweaving and Prismatic and Radiat Lingering Harm" if you want to be way over the top.
Additionally, Spellweavers can make shielding and teleportation spells with components too, although all three types of spells use the same slots.
Spellweavers who are Humans, Elves, Dwarves or Undeads will also begin in Wovenhome in the East and have a special dungeon to start the game.

Note: This is only an early release, so it probably is not terribly well balanced yet. If you try it out, let me know what you think.]]
overload = true
superload = true
hooks = true 
data = true
tags = {'kamani', "spellweaver", "class", "magic"}

--[[
-- Change Log --
Version 2.17:
Burst damage increased to 90%


Version 2.16:
Grand Elementalist now raises your talent cap for Spellweaving/Elementalist talents by 1 (allowing you to get Elemental Purification without already having 3 points in every talent).
Fixed a bug with Adapted Adaption and Infusions.

Version 2.15:
The Spellweaver's Reflection Class Evolution now has a readable description courtesy Recaiden and Moasseman. Also you can command staff it to change its damage type, and it gives you some crit mult.


Version 2.14:
Added Spellweaver's Reflection, and with it, The Beacon Of The Spellweavers.


Version 2.13:
Shields now correctly display that they are affected by Etheral Embrace and the shield power increasing egos.
Storm Bringer's Gauntlets now correctly increases talent level on Relentless Hailstorm.
Duo Prismatic and Exploit-Prismatic function correctly again.


Version 2.12:
While doing an additional test of the previous issue, noticed that the Shield spell lacked tactical information. Corrected this so that Inner Demons or your Doomed Shadow or whatever will be able to use basic Shield spells.


Version 2.11:
Fixed bug with Reflection shield potentially doing recursion if two things had it.


Version 2.10:
Minor changes to Professor Hundredeyes' dialogue about the Staff of Absorption.
Emergency patched Random element colors to work again since the Version 2.8 particle fixes broke them.


Version 2.9:
Forceful mode description in Spellweaver Adept updated to match current version of Forceful.
Exploit Weakness and Powerful Opening damage boosts are no longer stacking so that if you say, used Powerful Opening on a group, it would double the damage to each target, cumulatively, causing ludicrously high damage.
Runic Perfection now correctly only applies to the first spell cast per rune, but it also now stacks additively with consecutive runes used.
Meta Empowerment now updates the named spell correctly when switching spells, and lists the Spell Slot number, since that can help with spell ID if you have duplicates.
Prismatic Exploit Weakness can now apply status effects again.
Exploit Weakness now functions correctly with double elements.
Forceful now uses element-unmodified damage, such that Fire is not DRASTICALLY weaker as Forceful (Light is slightly worse as Forceful as compared to last version though).
Fire DoT is now 80% instead of 75%.
Woven animals in the Woven Woods will no longer use their beams when you are not within range.


Version 2.8:
Weight increased to be higher than DLCs.
Various typos and text inconsistencies fixed.
Void Dance no longer lists the ID of the movement speed increase instead of the actual movement speed increase.
Lightning element spells now correctly charges up Relentless Hailstorm instead of triggering overcharge.
Lingering map effects are now one map effect, reducing lag in slower machines.
Wallweaving now has a special increase in cooldown duration (because making 5 turn walls is inherently good regardless of power), slightly reduced chances, and displays better details in crafted spells.
Particles now display more correctly with Wallweave double shapes.


Version 2.7:
Adjusted dates on Spellweaver lore since I realized that the Mardrop Expedition would have arrived in Var'Eyal during early Age of Pyre, not halfway through the Age of Dusk as I previously calculalted for. I had mixed up the Naloren lands being sunk as due to the Spellblaze proper instead of the Cataclysm 1567 years later.
Powerful Opening Spellweave Multiplier is now 1 (which it said it was anyways but)
Corrected Changeup's description
Molten Shield renamed to Slag Shield because of Molten Molten Shields of Thorns.
Non-Duo lingering harm tiles now correctly don't cause friendly fire (duo ones already worked right).
Double shapes now correctly use element descriptor text instead of element names in crafted spells
Aeryn will now only give Spellweavers the special Spellweaver dialogue
Spellweavers now begin with Wovenhome revealed on the map.
Hailstorming effect display now more correct when used in a crafted spell as the first thing in a duo element.
Barrage now plays sound on each spell cast instead of just the last.
Crafted Changeup spells now actually list that you get Changeup
Forceful now simply doesn't apply status effects AT ALL.
Resistance Breaking and Elemental Shielding describe their effects better on crafted spells. Also, the double % symbol thing was fixed.
Crafted spell tooltips with Ruin now list Ruin instead of Eclipse.
Spellpower scaling is now listed on many talents that lacked it previously (including every element talent and Staff Resonance).
Resistance Breaking, Elemental Shielding, Exploit Weakness, and the Controller Construct now function correctly with daze-safe lightning.
Arcane manaburn lists manaburn numbers more accurately.
Relentless hailstorm will not generate completely meaningless crit messages when you overcharge it at 0 power (it didn't actually trigger anyways).
Checkerboard particle effects temporarily significantly-simplified to see if it helps with lag for some weaker machines. If it does I might make a setting or use an existing setting to set full vs. simple particles.


Version 2.6:
Daze-safe lightning actually functions correctly. My bad.
Gloves of the Woven Elementalist damage function made more strongly favoring stronger elements.
Hailstorm damage from Eyal's Storm no longer breaks dazes.


Version 2.5:
Silence works on crafted Attack and Shield spells
Shapes now check range consistently for their descriptions (really only noticable in that if you take Range Amplification Device, they'll update now).
Bolts are no longer blocked by allies.
Unending Melting now buffs Molten even when not sustained.
Change Spellwoven lightning damage does not remove Daze.
Range of elemental beam from Wovenwoods animals reduced to 7 (matching player beams)
Mana costs reduced for attack and teleport spells to 15, and shield spells to 20, elemental sustains sustained mana reduced to 35
Spellweaver's Precision wall creation typo fixed.
Bumped Square range to 6 (matching Burst)
Burst, Cone, Checkerboard, and Widebeam Spellweave Multiplier bumped to 0.85, Huge to 0.45, Abstract Flower and Doublespiral to 0.7, Eightpoint to 0.8.
Checkerboard and Grand Checkerboard sizes clarified.
Molten Shield and the other shields now display their current absorb value in the buff/sustain icon.
Relentless Hailstorm displays its current power in the sustain icon.
Elemental Nullification damage reduction increased to 30% since it means that you can only resist it with all resistance.
Elemental Purification elementless damage now ignores 50% of all resistance. No idea how balanced it is but since it's such a pain to get it deserves something cool.
The staff all damage effect from Elementalist has been moved to Adept. True Elementalist instead gains +10% all resistance piercing.
Touch now gets an extra one range if you are sustaining Range Amplification Device, because you deserve it for taking it.


Version 2.4:
Fixed a description error in Fire element.


Version 2.3:
Molten Drain now actually affects the right targets. Whoops.
Changeup now correctly displays its Spellweave Multiplier (0.5).
Gravechill armor stacks to 20
Double Shapes don't friendlyfire.


Version 2.2:
Silence actually applies to Spellwoven spells now.
Spellweavers have Combat Training available from the start (mostly for ASC working better in Arena and Infinite Dungeon, although if you want to try Heavy Armor Spellweaver be my guest).
Spellweavers start out with one more Spell Slot.
Most of Fire's damage is dealt through DoT now, also the DoT is now not affected by saves and powers (because having more than 60% of your damage get Shrugged Off hurts a lot)
Status inflict chances are generally better.
Attack Spell Slots now have a cooldown of 5 so that you can actually do something most turns.
Spellweaving Mastery now has max level 3 for all talents.
Grand Elementalist no longer needs extra elements known to learn. (It requires 10, which is what you start with, and is just for flavor since it should be impossible to fail)
Spellwoven talents now have a different color based on whether they are Attack, Teleport, or Shield spells, plus a greyscale version for uncrafted talents.
Illuminate has been correctly relabled to Luminescence, since that's what the effect is actually called, also its power has been listed (20).
Darklight Confusion effect clarified.
Spellweaver damage buffed slightly.
Acidic Pestilence damage is no longer ridiculous (as in more than three times damage ridiculous).
Spellweaver spells are now correctly treated as spells.
Spellweavers now get 4 default spells so that initial crafting for starts that start in combat (namely Doomelf) is less problems, plus less tedious.
Spellshattered Staff's STR requirement is now 10, so it's less of a problem for wearing it (it was only supposed to be flavor, I just forget that most people don't only play ghoul).
Gloves of the Woven Elementalist now have proper melee effects, as well as an activatable talent (which I will say is mostly on so that it can be randomly activated on hit since it's new).
Spellwoven talents are now slightly better set up for any clones of the player to use.
Buffed Fever diseases a bit.
Spellweaver attack spells now play talents/arcane sound effect. At some point I'll go change them to be based on elements but that'll take time and this takes minimal effort.
Nerfed the Controller Construct a bit because it seemed a touch too annoying to fight.
Grand Elementalist now gives one point in each Elementalist talent if you already know the category. This allows you to get to 20 points in True Elementalist, which will award you with a bonus element, Elemental Purification.
Added the Random element to Metaweaving. Chaos chaos.
Double shapes now work better with walls. This is about the third time I've fixed this problem, so hopefully I won't overhaul how special shapes work again and make it necessary again.
Fixed some minor typos and appearance issues (like Harmonic Paradise effects now use the right icon).


Version 2.1:
Extended duration of Void Dance buffs to make them useable more reliably (they still say one turn since a lot of the time they ARE, very short buff durations can act kind of odd).
Spell crafting methods now each have a unique talent icon.
Fixed many typos, neated up some phrasing to be more understandable.
Threadswitch now fails correctly when neither spell has any cooldown.
Radiamark and arcane manaburning both substantially weakened.
Molten shield now only plays noise when activated, instead of nightmarishly frequently.
Elementalist tree staff effect now works correctly on certain artifact staves that do not act like normal ones (like Bolbum's Big Knocker)
Metaweaving has slightly more spread out numbers.
Lightning Dash displays movespeed correctly and will have less poorly defined behavior when changing floors with an Illusions Lightning Dash.
Spellweave Power is now called Spellweave Multiplier.
Contingency applies BEFORE the hit that would have dealt the damage, thus making one-shots through the talent less of an issue, so it's less terrible.
Defeating the Controller Construct fully heals you, refreshes your cooldowns, and removes any debuffs on you so that you don't drop out into a new floor and immediately die.
Spell slots now have numbered images and sort by numbered image in slot selection menus.
Spell slots are now always obtained in numbered order, since number matters a bit more now.
The Woven Woods actually has music now. (my bad)
Spellweave crafting talents now have unique icons instead of all just being that anvil.


Version 2.0:
First proper release.
Added everything of substance.


Version 1.X:
Very early demo versions so I could link talents in chat.
Note: No longer necessary, see special thanks.


Special Thanks:
Darkgod: Made ToME. Also I definitely copied code from ToME to make individual modes and stuff so.
Lukeasaur (https://te4.org/users/lukeasaur): Gave me the idea for the Runic tree, and the Tinker based Class Evolution I may or may not have added yet.
Nekarcos (https://te4.org/users/nekarcoss): The Teleport mode's code was inspired by the code for the skill Buzz Off from Nekarcos's Odyssey of the Summoner.
The entire ToME Discord addons channel folks (especially minmay and Recaiden): Helped me to solve some truly bizarre code errors that can happen when you do Very Weird Things. 
Agrimley (https://te4.org/users/agrimley) and changeling (could not find): Helped to inspire the secondary effect of Otherworldly that I was very stuck on.
The entire ToME Discord addons channel folks again (especially Moasseman, Creature, and Erenion) for giving feedback on the original version and it's many typos, unclear phrasings, and glitches.
Moasseman, Recaiden, and Mannendake (again): Recaiden literally wrote the new description for Spellweaver's Reflection and it's wayyyy more readable, and Moas and Mannendake both gave helpful feedback on it.


Reminders to self:
Professor shape talents:
- Hundredeyes - Abstract Flower -- Spellweaver Plot
- Paradise - Smiley -- 15 elements
- Ifnai - 8point -- 10 artifacts
- Arbus - Doublespiral -- Knows nature, have equilibrium pool, or have 15 points in teleport talents.
--]]