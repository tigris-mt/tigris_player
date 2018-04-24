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

tigris.player.register_effect("tigris_player:health_regen", {
    description = "Health Regeneration",
    status = true,
    set = function(player, old, new)
        local remaining = 0

        if old then
            remaining = old.remaining
        end

        local tex = "tigris_player_effect_plus.png^[colorize:#F00:200"
        if new.amount > 1 then
            tex = tex .. "^(tigris_player_effect_enhance.png^[colorize:#F00:200)"
        end

        local d = (remaining + new.duration)
        local a = new.amount * (new.duration / d) + (old and old.amount or 0) * (remaining / d)

        return {
            status = tex,
            text = math.floor(a),
            amount = a,
            remaining = d,
        }
    end,

    apply = function(player, e, dtime)
        player:set_hp(player:get_hp() + e.amount * dtime)
    end,
})
