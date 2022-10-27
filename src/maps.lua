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

Maps = {
    main = {
        data = load_map("main"),
        regions = {},
    },
}

return Maps
