#!/usr/bin/luajit

--[[

TODOs:
- equipement (backpack system, equip items (change stats))
- look arouund (special events)
- eating gives XP? (or xp potions)

level system:
- max hp +
- attack +
- special moves?
- events

monster type
fire, water, ...
special attack for special type of monster

sleep mechanic for hp restore (potions and food to restore hp in a fight)

]] --

-- i think they should be globals (CAPS)
local is_debug = false
if os.getenv("DEBUG") then
    is_debug = true
end

local skip_delays = false
if os.getenv("SKIP_DELAYS") then
    skip_delays = true
end

local skip_prologue = false
if os.getenv("SKIP_PROLOGUE") then
    skip_prologue = true
end

CURRENT_POS = {
    Y = 19,
    X = 11,
}
MAP_SIZE = 20

EVENTS = require("events")
ITEMS = require("items")
MONSTERS = require("monsters")
COLOR = require("colors")

SPEED = {
    NORMAL = 1,
    SLOW = 2,
    FAST = 0.5,
    INSTANT = 0,
}

TEXT_BUFFER = {}

STATE = {
    normal = COLOR.green .. "[>]",
    fight = COLOR.red .. "[!]",
    --DEBUG = "DEBUG",
}

CURRENT_STATE = STATE.normal

PLAYER = {
    health = 100,
    max_hp = 140,
    -- default backpack
    backpack = { ITEMS.potion, ITEMS.bread },
    attack = 10,
    level = 1,
    xp = 0,
}

local function sleep(ms)
    local skip = false
    if ms == 0 then
        skip = true
    end
    if not skip_delays and not skip then
        -- still not perfect but must do for now
        local timer = assert(io.popen("sleep " .. ms / 1000))
        timer:close()
    end
end

local function print_fancy(message, speed, after_sleep)
    if speed == nil then
        speed = SPEED.INSTANT
    end
    for i = 1, #message do
        local char = string.sub(message, i, i)
        io.write(char)
        io.flush()
        if char == " " then
            sleep(100 * speed)
        elseif char == "," then
            sleep(200 * speed)
        elseif char == "." then
            sleep(500 * speed)
        else
            sleep(50 * speed)
        end
    end
    if after_sleep == nil then
        after_sleep = 0
    end
    sleep(after_sleep) -- after_sleep * speed to scale delay with the speed
    print()
end

local function insert_into_text_buffer(text_object)
    table.insert(TEXT_BUFFER, text_object)
end

local function print_text(text, speed, delay)
    local speed_local = SPEED.INSTANT
    if speed ~= nil then
        speed_local = speed
    end
    local delay_local = 0
    if delay ~= nil then
        delay_local = speed
    end
    insert_into_text_buffer({ data = text, speed = speed_local, delay = delay_local })
end

local function handle_text_buffer()
    for _, obj in pairs(TEXT_BUFFER) do
        local speed = SPEED.INSTANT
        if obj.speed ~= nil then
            speed = obj.speed
        end
        local delay = 0
        if obj.after_delay ~= nil then
            delay = obj.after_delay
        end
        print_fancy(obj.data, speed, delay)
    end
    TEXT_BUFFER = {}
end

local function set_color(color)
    io.write(color)
    io.flush()
end

local function reset_color()
    io.write(COLOR.reset)
    io.flush()
end

local function debug(message)
    if is_debug then
        print("[DEBUG] " .. message)
    end
end

local function error_print(message)
    print("[ERROR] " .. message)
end

local function dump_table(o)
    if type(o) == 'table' then
        local s = '{'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump_table(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function clear_screen()
    local escape_char = string.char(27)
    io.write(escape_char .. "[1;1H" .. escape_char .. "[2J")
    io.flush()
end

local function table_contains(table, contains)
    for _, value in pairs(table) do
        if value == contains then
            return true
        end
    end
    return false
end

local function split_into_words(str)
    local words = {}
    for w in string.gmatch(str, "[^ ]+") do
        table.insert(words, w)
    end
    return words
end

local function load_map(map_name)
    local map = {}
    local map_file = map_name .. ".txt"
    debug("map_file: " .. map_file)
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

MAIN_MAP = load_map("main_map")

local function prompt()
    io.write(CURRENT_STATE .. COLOR.reset .. " ")
    return io.stdin.read(io.stdin)
end

local function welcome_screen()
    clear_screen()
    print([[

     _ __ ___   ___  _ __  ___| |_ ___ _ __ ___          | | ___  _ __   __ _       
    | '_ ` _ \ / _ \| '_ \/ __| __/ _ \ '__/ __|  _____  | |/ _ \| '_ \ / _` |
    | | | | | | (_) | | | \__ \ ||  __/ |  \__ \ |_____| | | (_) | | | | (_| |  
    |_| |_| |_|\___/|_| |_|___/\__\___|_|  |___/         |_|\___/|_| |_|\__, | 
                                                                        |___/       
                         _                 _                                        
                __ _  __| |_   _____ _ __ | |_ _   _ _ __ ___                       
               / _` |/ _` \ \ / / _ \ '_ \| __| | | | '__/ _ \                 
              | (_| | (_| |\ V /  __/ | | | |_| |_| | | |  __/                     
               \__,_|\__,_| \_/ \___|_| |_|\__|\__,_|_|  \___|               
    
                                the sequel                                          
    ]])
end

local function print_help_screen()
    print_text("Currently available actions:")
    if CURRENT_STATE == STATE.normal then
        print_text([[    move in a direction (north, east, south, west) - go, g
    use an item                                    - use, u
    backpack contents                              - backpack, b
    show player stats                              - stats, s
    clear the screen                               - clear
    display this help screen                       - help, ?
    exit from the game                             - quit, q]])
    elseif CURRENT_STATE == STATE.fight then
        -- TODO: handle_attack func, different types of attack (pokemon style)
        print_text([[    attack                   - attack, a
    run away                 - run, r
    use an item              - use, u
    backpack contents        - backpack, b
    show player stats        - stats, s
    clear the screen         - clear
    display this help screen - help, ?
    exit from the game       - quit, q]])
    end
end

local function prologue()
    set_color(COLOR.gold)
    print_fancy("Once upon a time, there was nothing, but pure evilness", SPEED.NORMAL, 500)
    print_fancy("and the culpruit was, no surprice, " .. COLOR.blue .. "sonic the hedgehog", SPEED.NORMAL, 500)
    set_color(COLOR.gold)
    print_fancy("this time it was no a clear case of beeing bad", SPEED.NORMAL, 500)
    print_fancy("it was even worse...\n", SPEED.NORMAL, 500)
    set_color(COLOR.blue)
    print_fancy("sonic", SPEED.SLOW, 1000)
    set_color(COLOR.light_pink)
    print_fancy("was gay!\n", SPEED.NORMAL, 1000)
    set_color(COLOR.gold)
    print_fancy("who would have thought?", SPEED.NORMAL, 500)
    print_fancy("unsuprisingly, everyone", SPEED.NORMAL, 500)
    print_fancy("with that said, let's hop right into the game!", SPEED.NORMAL, 2000)
    --print_fancy("what the FUCK was that? idk lets start", SPEED.NORMAL, 2000)
    reset_color()
end

local function item_name_to_object(name)
    for item_name, item in pairs(ITEMS) do
        if name == item_name then
            return item
        end
    end
    return nil
end

local function handle_event(event)
    if event.finished == true then return end
    print_text(event.data, SPEED.NORMAL)
    local finish_data = split_into_words(event.on_finish)
    if finish_data[1] == "backpack" then
        if finish_data[2] == "add" then
            -- TODO: probably should export adding item to a function
            local item = item_name_to_object(finish_data[3])
            if item == nil then return end
            table.insert(PLAYER.backpack, item)
            print_text("\n" ..
                COLOR.cyan .. "Backpack: " .. COLOR.yellow .. "+" .. item.name .. COLOR.reset .. "\n")
            event.finished = true
            MAIN_MAP[event.y][event.x] = " "
        end
    end
end

local function handle_position(direction)
    -- this can shurely be improved
    direction = string.lower(direction)
    if direction == "north" or direction == "n" or direction == "up" or direction == "u" then
        local map_element = MAIN_MAP[CURRENT_POS.Y - 1][CURRENT_POS.X]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        CURRENT_POS.Y = CURRENT_POS.Y - 1
    elseif direction == "east" or direction == "e" or direction == "right" or direction == "r" then
        local map_element = MAIN_MAP[CURRENT_POS.Y][CURRENT_POS.X + 1]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        CURRENT_POS.X = CURRENT_POS.X + 1
    elseif direction == "south" or direction == "s" or direction == "down" or direction == "d" then
        local map_element = MAIN_MAP[CURRENT_POS.Y + 1][CURRENT_POS.X]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        CURRENT_POS.Y = CURRENT_POS.Y + 1
    elseif direction == "west" or direction == "w" or direction == "left" or direction == "l" then
        local map_element = MAIN_MAP[CURRENT_POS.Y][CURRENT_POS.X - 1]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        CURRENT_POS.X = CURRENT_POS.X - 1
    else
        print_text("Unknown direction")
        return
    end
    local current_event = nil
    for _, event in pairs(EVENTS) do
        if event.x == CURRENT_POS.X and event.y == CURRENT_POS.Y then
            current_event = event
        end
    end
    if current_event ~= nil then
        handle_event(current_event)
    end
end

local function render_map()
    local view_distance = 4
    io.write("\u{250c}")
    for _ = 0, view_distance * 2 do
        io.write("\u{2500}")
    end
    print("\u{2510}")
    for y = CURRENT_POS.Y - view_distance, CURRENT_POS.Y + view_distance do
        io.write("\u{2502}")
        for x = CURRENT_POS.X - view_distance, CURRENT_POS.X + view_distance do
            if MAIN_MAP[y] == nil or MAIN_MAP[y][x] == nil then
                io.write("█")
            else
                if y == CURRENT_POS.Y and x == CURRENT_POS.X then
                    --io.write("\u{1f643}")
                    io.write("!")
                else
                    if MAIN_MAP[y][x] == "#" then
                        io.write("█")
                    else
                        io.write(MAIN_MAP[y][x])
                    end
                end
            end
        end
        print("\u{2502}")
    end
    io.write("\u{2514}")
    for _ = 0, view_distance * 2 do
        io.write("\u{2500}")
    end
    print("\u{2518}")
end

local function show_backpack()
    local string_to_write = COLOR.cyan .. "Backpack: " .. COLOR.reset
    for i, item in pairs(PLAYER.backpack) do
        if i == #PLAYER.backpack then
            string_to_write = string_to_write .. item.name
        else
            string_to_write = string_to_write .. item.name .. ", "
        end
    end
    if #PLAYER.backpack == 0 then
        string_to_write = string_to_write .. "<EMPTY>"
    end
    print_text(string_to_write)
end

local function use(item)
    if not table_contains(PLAYER.backpack, item) then
        print_text("You don't have any " .. item.name .. " in your backpack!")
        return
    end
    debug(item.name .. " found in the backpack")
    if item.type == "consumable" then
        local should_heal = true
        local healing_ammount = item.value
        if PLAYER.health + item.value > PLAYER.max_hp then
            healing_ammount = PLAYER.max_hp - PLAYER.health
        end
        if healing_ammount == 0 then
            render_map()
            print("You have reached max health, are you sure you want to use this item? (y/n)")
            local heal_choice = prompt()
            if heal_choice ~= "y" then
                should_heal = false
                print_text("Aborting using item")
            end
            clear_screen()
        end
        if should_heal == false then return end
        PLAYER.health = PLAYER.health + healing_ammount
        print_text("Used " .. item.name .. "! Restored " .. healing_ammount .. " health points")
        for v, backpack_item in ipairs(PLAYER.backpack) do
            if item == backpack_item then
                table.remove(PLAYER.backpack, v)
                return
            end
        end
    end
end

local function print_player_stats()
    print_text("Your player stats:")
    -- TODO: highlight color based on ammount of health (<10% then red, >80% green, else white)
    print_text("    " .. COLOR.red .. "health" .. COLOR.reset .. ": " .. PLAYER.health)
    for v, stat in pairs(PLAYER) do
        if v ~= "backpack" and v ~= "health" then
            -- TODO: level xp X out of X for the next level
            print_text("    " .. COLOR.cyan .. v .. COLOR.reset .. ": " .. stat)
        end
    end
end

local function handle_action(action)
    action = split_into_words(action)
    if action[1] == "quit" or action[1] == "q" then
        -- TODO: save state
        -- TODO: ask: are you sure you want to quit? make sure you saved your game
        set_color(COLOR.yellow)
        print("\nBye bye!\n")
        reset_color()
        os.exit(0)
    elseif action[1] == "use" or action[1] == "u" then
        if action[2] == nil then
            -- TODO: ask player for which item to use (display backpack) and use it
            print_text("Usage: use <item name> (use \"backpack\" for item list)")
            return
        end
        local item = item_name_to_object(string.lower(action[2]))
        if item == nil then
            print_text("Item " .. action[2] .. " doesn't exist")
            return
        end
        use(item)
    elseif action[1] == "help" or action[1] == "?" then
        print_help_screen()
    elseif action[1] == "clear" then
        clear_screen()
    elseif action[1] == "go" or action[1] == "g" then
        if action[2] == nil then
            print_text("Usage: go <direction> (north(up), east(right), south(down), west(left))")
            return
        end
        handle_position(action[2])
    elseif action[1] == "backpack" or action[1] == "b" then
        show_backpack()
    elseif action[1] == "stats" or action[1] == "s" then
        print_player_stats()
    else
        print_text("Action not found, type \"" ..
            COLOR.cyan .. "help" .. COLOR.reset .. "\" for action list")
    end
end

function Main()
    clear_screen()

    debug(dump_table(EVENTS))
    debug(dump_table(ITEMS))
    debug(dump_table(MONSTERS))
    debug(dump_table(MAIN_MAP))
    debug(dump_table(CURRENT_POS))

    if not skip_prologue then
        sleep(1000)
        prologue()
        welcome_screen()
        sleep(5000)
    end
    clear_screen()
    render_map()
    print("type \"help\" to get action list")

    local user_input = prompt()

    -- game loop
    while true do
        clear_screen()
        handle_action(user_input)
        render_map()
        handle_text_buffer()
        user_input = prompt()

        debug(dump_table(PLAYER))
        debug(dump_table(CURRENT_POS))
    end
end

Main()
