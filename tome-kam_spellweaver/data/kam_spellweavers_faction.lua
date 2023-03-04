-- Spellweavers reactions are a copy of the sunwall except they don't get along quite as well with the Sunwall and are neutral with undead.
engine.Faction:add{ name = "Spellweavers", reaction={} }
engine.Faction:copyReactions("spellweavers", "sunwall")
engine.Faction:setInitialReaction("spellweavers", "spellweavers", 100, true)
-- Spellweavers get along well with each other.
engine.Faction:setInitialReaction("spellweavers", "undead", 0, true)
-- Multiple Spellweavers are undead.
engine.Faction:setInitialReaction("spellweavers", "sunwall", 50, true) 
-- They aren't enemies, but since the Spellweavers kind of withdrew from fighting orcs they aren't 100 level friends. Spellweavers still help out with like nagas and stuff though.