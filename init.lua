local m = {}
tigris.player = m

-- Get unique faction ID for a player.
-- Override in faction mod.
-- Format:
--- player:<name> if player is not in a faction.
--- faction:<id> if player is in a faction.
function m.faction(name)
    return "player:" .. name
end

tigris.include("effects.lua")
