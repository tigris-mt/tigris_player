local properties = {}

function tigris.player.property(player, id, prop, value)
    local pname = player:get_player_name()
    properties[pname] = properties[pname] or {}
    properties[pname][prop] = properties[pname][prop] or {}
    local t = properties[pname][prop]
    t[id] = value

    if prop == "gravity" or prop == "speed" or prop == "jump" then
        local value = 1
        for _,v in pairs(t) do
            value = value * v
        end
        player:set_physics_override({[prop] = value})
    else
        assert("Invalid property: " .. prop)
    end
end
