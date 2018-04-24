local m = tigris.player

-- Registered effects.
m.effects = {}

-- Registered status effects.
m.statuses = {}

-- Advanced processing sorted keys.
m.status_keys = {}

-- Status image elements.
m.huds = {}

-- Status text elements (player indexed).
m.sts = {}

local players = {}

-- Get/set effect.
function m.effect(player, name, set)
    local t = players[player:get_player_name()]
    local old = t[name]

    if set ~= nil then
        assert(m.effects[name])
        t[name] = m.effects[name].set(player, t[name], set)
    end

    -- If duration is -1, check on.
    if t[name] and t[name].duration == -1 then
        return t[name].on and t[name] or nil
    end

    -- Check duration.
    if t[name] and os.time() - t[name].time <= t[name].duration then
        return t[name]
    end

    -- If effect is no longer valid, but was valid before this call, run the stop callback.
    if old and m.effects[name].stop then
        m.effects[name].stop(player, old)
    end
end

function m.register_effect(n, f)
    m.effects[n] = f

    -- Advanced effect.
    if f.status or f.apply then
        m.statuses[n] = f
        table.insert(m.status_keys, n)
        table.sort(m.status_keys)
    end
end

minetest.register_on_joinplayer(function(player)
    -- (Re-)set effects for player.
    players[player:get_player_name()] = {}

    -- Create status image element/
    m.huds[player:get_player_name()] = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0, y = 1},
        name = "statuses",
        scale = {x = 1, y = 1},
        alignment = {x = 1, y = -1},
        offset = {x = 4, y = -4},
        text = "",
    })

    -- Create text elements.
    m.sts[player:get_player_name()] = {}
    for i=1,10 do
        m.sts[i] = player:hud_add({
            position = {x = 0, y = 1},
            name = "sts_" .. i,
            scale = {x = 100, y = 100},
            alignment = {x = 1, y = -1},
            offset = {x = 4 + ((i - 1) * 32), y = -36},
            text = "",
            number = 0xFFFFFF,
        })
    end
end)

-- Clear player data.
minetest.register_on_leaveplayer(function(player)
    players[player:get_player_name()] = nil
    m.huds[player:get_player_name()] = nil
    m.sts[player:get_player_name()] = nil
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
            local texts = {}
            for _,k in ipairs(m.status_keys) do
                local v = m.statuses[k]
                local e = m.effect(player, k)

                -- Run apply function.
                if v.apply and e then
                    v.apply(player, e)
                end

                -- Test effect second time, apply may have stopped it.
                e = m.effect(player, k)

                -- Create status elements.
                if v.status then
                    if e then
                        local tex = (e.status or v.status)
                        local escaped = tex:gsub("(^)", "\\^"):gsub(":", "\\:")
                        escaped = (#combine * 32) .. ",0=" .. escaped
                        table.insert(combine, escaped)

                        local text = (e.text or "")
                        if e.text and e.duration > 0 then
                            text = text .. "\n"
                        end

                        if e.duration > 0 then
                            text = text .. math.ceil(e.duration - (os.time() - e.time))
                        end

                        texts[#combine] = text
                    end
                end
            end

            -- Set status text.
            for i,v in ipairs(m.sts) do
                player:hud_change(v, "text", texts[i] or "")
            end

            -- Set status image.
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

-- Clear status effects upon death.
minetest.register_on_dieplayer(function(player)
    local t = players[player:get_player_name()]
    local d = {}
    for k,v in pairs(t) do
        -- If timed, set time expired.
        if v.duration > 0 then
            v.time = 0
        -- Else mark for deletion.
        else
            d[k] = true
        end
    end

    -- Delete marked.
    for k in pairs(d) do
        t[k] = nil
    end
end)
