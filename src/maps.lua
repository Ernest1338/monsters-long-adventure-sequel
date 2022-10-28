Json = require("src/utils/json")

Maps = {}

local function load_map(map_name)
    local map = {}
    local map_file = "maps/" .. map_name .. ".txt"
    local index = 1
    for line in io.lines(map_file) do
        table.insert(map, {})
        for i = 1, #line do
            local c = line:sub(i, i)
            table.insert(map[index], c)
        end
        index = index + 1
    end
    return map
end

function Maps.load_maps()
    local maps_file = assert(io.open("maps/maps.json", "rb"))
    local maps = Json.decode(maps_file:read("*all"))
    for k, _ in pairs(maps) do
        maps[k].data = load_map(maps[k].map_name)
    end
    return maps
end

-- function Maps.save_map()
--
-- end

return Maps
