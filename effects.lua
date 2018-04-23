local m = tigris.player

m.effects = {}

local players = {}

function m.effect(player, name, set)
    local t = players[player:get_player_name()]

    if set then
        assert(m.effects[name])
        t[name] = m.effects[name].set(player, t[name], set)
    end

    if t[name] and os.time() - t[name].time <= t[name].duration then
        return t[name]
    end
end

function m.register_effect(n, f)
    m.effects[n] = f
end

minetest.register_on_joinplayer(function(player)
    players[player:get_player_name()] = {}
end)

minetest.register_on_leaveplayer(function(player)
    players[player:get_player_name()] = nil
end)
