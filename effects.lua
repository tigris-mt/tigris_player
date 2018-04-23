local m = tigris.player

m.effects = {}
m.statuses = {}
m.status_keys = {}
m.huds = {}

local players = {}

function m.effect(player, name, set)
    local t = players[player:get_player_name()]

    if set ~= nil then
        assert(m.effects[name])
        t[name] = m.effects[name].set(player, t[name], set)
    end

    if t[name] and t[name].duration == -1 then
        return t[name].on and t[name] or nil
    end

    if t[name] and os.time() - t[name].time <= t[name].duration then
        return t[name]
    end
end

function m.register_effect(n, f)
    m.effects[n] = f

    if f.status then
        m.statuses[n] = f
        table.insert(m.status_keys, n)
        table.sort(m.status_keys)
    end
end

minetest.register_on_joinplayer(function(player)
    players[player:get_player_name()] = {}
    m.huds[player:get_player_name()] = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0, y = 1},
        name = "statuses",
        scale = {x = 1, y = 1},
        alignment = {x = 1, y = -1},
        offset = {x = 4, y = -4},
        text = "",
    })
end)

minetest.register_on_leaveplayer(function(player)
    players[player:get_player_name()] = nil
    m.huds[player:get_player_name()] = nil
end)

local old = {}
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > 1 then
        for _,player in pairs(minetest.get_connected_players()) do
            local n = player:get_player_name()
            local hud = m.huds[n]
            local new = ""
            local combine = {}
            for _,k in ipairs(m.status_keys) do
                local v = m.statuses[k]
                local e = m.effect(player, k)
                if e then
                    local escaped = (e.status or v.status):gsub("(^)", "\\^"):gsub(":", "\\:")
                    escaped = (#combine * 32) .. ",0=" .. escaped
                    table.insert(combine, escaped)
                end
            end

            if #combine > 0 then
                new = "[combine:" .. (#combine * 32) .. "x32:" .. table.concat(combine, ":")
            end

            if new ~= old[n] then
                player:hud_change(hud, "text", new)
                old[n] = new
            end
        end
        timer = 0
    end
end)
