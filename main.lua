#!/usr/bin/luajit

--[[

TODOs:
- equipement (backpack system, equip items (change stats))
- look around (special events)
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

Skip_delays = false
if os.getenv("SKIP_DELAYS") then
    Skip_delays = true
end

Is_debug = false
if os.getenv("DEBUG") then
    Is_debug = true
    Skip_delays = true -- automatically skip delays when in debug mode
end

Skip_prologue = false
if os.getenv("SKIP_PROLOGUE") then
    Skip_prologue = true
end

Current_pos = {
    y = 19,
    x = 11,
}

ESCAPE_CHAR = string.char(27)

Events = require("events")
Items = require("items")
Monsters = require("monsters")
Color = require("colors")
Maps = require("maps")

Speed = {
    normal = 1,
    slow = 2,
    fast = 0.5,
    instant = 0,
}

Text_buffer = {}
-- Cursor_pos_buffer = { x = 1, y = 1 }

State = {
    normal = Color.green .. "[>]",
    fight = Color.red .. "[!]",
    confirm = Color.blue .. "[?]"
    --debug = "DEBUG",
}

Current_state = State.normal

Player = {
    health = 100,
    max_hp = 140,
    -- default backpack
    backpack = { Items.potion, Items.bread },
    attack = 10,
    level = 1,
    xp = 0,
}

local function sleep(ms)
    local skip = false
    if ms == 0 then
        skip = true
    end
    if not Skip_delays and not skip then
        -- still not perfect but must do for now
        local timer = assert(io.popen("sleep " .. ms / 1000))
        timer:close()
    end
end

local function set_cursor_pos(x, y)
    io.write(ESCAPE_CHAR .. "[" .. y .. ";" .. x .. "H")
end

local function save_cursor_pos()
    io.write(ESCAPE_CHAR .. "[s")
end

local function restore_cursor_pos()
    io.write(ESCAPE_CHAR .. "[u")
end

-- TODO: This shouldn't use saveCursorPos() because it may overwrite user's wanted data
local function print_in_pos(text, pos)
    save_cursor_pos()
    set_cursor_pos(pos[1], pos[2])
    io.write(text)
    restore_cursor_pos()
end

local function print_fancy(message, speed, after_sleep)
    if speed == nil then
        speed = Speed.instant
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
    table.insert(Text_buffer, text_object)
end

local function print_text(text, speed, delay)
    local speed_local = Speed.instant
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
    for _, obj in pairs(Text_buffer) do
        local speed = Speed.instant
        if obj.speed ~= nil then
            speed = obj.speed
        end
        local delay = 0
        if obj.after_delay ~= nil then
            delay = obj.after_delay
        end
        print_fancy(obj.data, speed, delay)
    end
    Text_buffer = {}
end

local function set_color(color)
    io.write(color)
    io.flush()
end

local function reset_color()
    io.write(Color.reset)
    io.flush()
end

local function debug(message)
    if Is_debug then
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
    io.write(ESCAPE_CHAR .. "[1;1H" .. ESCAPE_CHAR .. "[2J")
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

-- TODO: support this usecase: prompt(State.confirm)
local function prompt()
    io.write(Current_state .. Color.reset .. " ")
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
    if Current_state == State.normal then
        print_text([[    move in a direction (north, east, south, west) - go, g
    use an item                                    - use, u
    backpack contents                              - backpack, b
    show player stats                              - stats, s
    clear the screen                               - clear
    display this help screen                       - help, ?
    exit from the game                             - quit, q]])
    elseif Current_state == State.fight then
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
    set_color(Color.gold)
    print_fancy("Once upon a time, there was nothing, but pure evilness", Speed.normal, 500)
    print_fancy("and the culpruit was, no surprice, " .. Color.blue .. "sonic the hedgehog", Speed.normal, 500)
    set_color(Color.gold)
    print_fancy("this time it was no a clear case of beeing bad", Speed.normal, 500)
    print_fancy("it was even worse...\n", Speed.normal, 500)
    set_color(Color.blue)
    print_fancy("sonic", Speed.slow, 1000)
    set_color(Color.light_pink)
    print_fancy("was gay!\n", Speed.normal, 1000)
    set_color(Color.gold)
    print_fancy("who would have thought?", Speed.normal, 500)
    print_fancy("unsuprisingly, everyone", Speed.normal, 500)
    print_fancy("with that said, let's hop right into the game!", Speed.normal, 2000)
    reset_color()
end

local function item_name_to_object(name)
    for item_name, item in pairs(Items) do
        if name == item_name then
            return item
        end
    end
    return nil
end

local function handle_event(event)
    if event.finished == true then return end
    print_text(event.data, Speed.normal)
    local finish_data = split_into_words(event.on_finish)
    if finish_data[1] == "backpack" then
        if finish_data[2] == "add" then
            -- TODO: probably should export adding item to a function
            local item = item_name_to_object(finish_data[3])
            if item == nil then return end
            table.insert(Player.backpack, item)
            print_text("\n" ..
                Color.cyan .. "Backpack: " .. Color.yellow .. "+" .. item.name .. Color.reset .. "\n")
            event.finished = true
            Maps.main.data[event.y][event.x] = " "
        end
    end
end

local function handle_position(direction)
    -- this can surely be improved
    direction = string.lower(direction)
    if direction == "north" or direction == "n" or direction == "up" or direction == "u" then
        local map_element = Maps.main.data[Current_pos.y - 1][Current_pos.x]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        Current_pos.y = Current_pos.y - 1
    elseif direction == "east" or direction == "e" or direction == "right" or direction == "r" then
        local map_element = Maps.main.data[Current_pos.y][Current_pos.x + 1]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        Current_pos.x = Current_pos.x + 1
    elseif direction == "south" or direction == "s" or direction == "down" or direction == "d" then
        local map_element = Maps.main.data[Current_pos.y + 1][Current_pos.x]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        Current_pos.y = Current_pos.y + 1
    elseif direction == "west" or direction == "w" or direction == "left" or direction == "l" then
        local map_element = Maps.main.data[Current_pos.y][Current_pos.x - 1]
        if map_element == "#" or map_element == nil then
            print_text("Wrong direction")
            return
        end
        Current_pos.x = Current_pos.x - 1
    else
        print_text("Unknown direction")
        return
    end
    local current_event = nil
    for _, event in pairs(Events) do
        if event.x == Current_pos.x and event.y == Current_pos.y then
            -- TODO: to support multiple events on the same block, insert event into a table
            current_event = event
            break
        end
    end
    if current_event ~= nil then
        -- TODO: handle multiple events, from a table (see TODO some lines up)
        handle_event(current_event)
    end
end

local function render_map()
    local view_distance = 4
    io.write("\u{250c}")
    for _ = 0, view_distance * 2 do
        io.write("\u{2500}\u{2500}")
    end
    print("\u{2510}")
    for y = Current_pos.y - view_distance, Current_pos.y + view_distance do
        io.write("\u{2502}")
        for x = Current_pos.x - view_distance, Current_pos.x + view_distance do
            if Maps.main.data[y] == nil or Maps.main.data[y][x] == nil then
                io.write("██")
            else
                if y == Current_pos.y and x == Current_pos.x then
                    io.write("\u{1f643}")
                    --io.write("\u{FF30}")
                else
                    if Maps.main.data[y][x] == "#" then
                        io.write("██")
                    elseif Maps.main.data[y][x] == "*" then
                        io.write("\u{FF0A}")
                    else
                        io.write(string.rep(Maps.main.data[y][x], 2))
                    end
                end
            end
        end
        print("\u{2502}")
    end
    io.write("\u{2514}")
    for _ = 0, view_distance * 2 do
        io.write("\u{2500}\u{2500}")
    end
    print("\u{2518}")
end

local function render_stats()
    local offset_x = 30
    local offset_y = 2
    print_in_pos(Color.red .. "Health " .. Player.health .. " / " .. Player.max_hp, { offset_x, offset_y })
    print_in_pos(Color.light_blue .. "Level " .. Player.level, { offset_x, offset_y + 1 })
    print_in_pos(Color.light_green .. "Attack " .. Player.attack .. Color.reset, { offset_x, offset_y + 2 })
end

local function render_ui()
    render_map()
    render_stats()
end

local function show_backpack()
    local string_to_write = Color.cyan .. "Backpack: " .. Color.reset
    for i, item in pairs(Player.backpack) do
        if i == #Player.backpack then
            string_to_write = string_to_write .. item.name
        else
            string_to_write = string_to_write .. item.name .. ", "
        end
    end
    if #Player.backpack == 0 then
        string_to_write = string_to_write .. "<EMPTY>"
    end
    print_text(string_to_write)
end

local function use(item)
    if not table_contains(Player.backpack, item) then
        print_text("You don't have any " .. item.name .. " in your backpack!")
        return
    end
    debug(item.name .. " found in the backpack")
    if item.type == "consumable" then
        local should_heal = true
        local healing_ammount = item.value
        if Player.health + item.value > Player.max_hp then
            healing_ammount = Player.max_hp - Player.health
        end
        if healing_ammount == 0 then
            render_ui()
            Current_state = State.confirm
            print("You have reached max health, are you sure you want to use this item? (y/n)")
            local heal_choice = prompt()
            Current_state = State.normal
            if heal_choice ~= "y" then
                should_heal = false
                print_text("Aborting using item")
            end
            clear_screen()
        end
        if should_heal == false then return end
        Player.health = Player.health + healing_ammount
        print_text("Used " .. item.name .. "! Restored " .. healing_ammount .. " health points")
        for v, backpack_item in ipairs(Player.backpack) do
            if item == backpack_item then
                table.remove(Player.backpack, v)
                return
            end
        end
    end
end

local function print_player_stats()
    print_text("Your player stats:")
    -- TODO: highlight color based on ammount of health (<10% then red, >80% green, else white)
    print_text("    " .. Color.red .. "health" .. Color.reset .. ": " .. Player.health)
    for v, stat in pairs(Player) do
        if v ~= "backpack" and v ~= "health" then
            -- TODO: level xp X out of X for the next level
            print_text("    " .. Color.cyan .. v .. Color.reset .. ": " .. stat)
        end
    end
end

local function handle_action(action)
    action = split_into_words(action)
    if action[1] == "quit" or action[1] == "q" then
        -- TODO: save state
        -- TODO: ask: are you sure you want to quit? make sure you saved your game
        set_color(Color.yellow)
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
            Color.cyan .. "help" .. Color.reset .. "\" for action list")
    end
end

function Main()
    clear_screen()

    debug(dump_table(Events))
    debug(dump_table(Items))
    debug(dump_table(Monsters))
    debug(dump_table(Maps.main.data))
    debug("PRESS ANY KEY TO START THE GAME")
    debug(prompt())

    if not Skip_prologue then
        sleep(1000)
        prologue()
        welcome_screen()
        sleep(5000)
    end
    clear_screen()
    render_ui()
    print("type \"help\" to get action list")

    local user_input = prompt()

    -- game loop
    while true do
        clear_screen()
        handle_action(user_input)
        render_ui()
        handle_text_buffer()

        debug(dump_table(Player))
        debug(dump_table(Current_pos))

        user_input = prompt()
    end
end

Main()
