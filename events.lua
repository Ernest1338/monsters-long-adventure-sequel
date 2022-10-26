EVENT_TYPE = {
    quest = "quest",
    special = "special",
    location_marker = "location_marker",
    npc = "npc",
    well = "well",
}

EVENTS = {
    { x = 11, y = 2, type = EVENT_TYPE.quest, active = true, finished = false, activates = "", data = "quest 1 heh" },
    { x = 11, y = 3, type = EVENT_TYPE.npc, active = true, finished = false, activates = "", data = "someone" },
    { x = 6, y = 17, type = EVENT_TYPE.special, active = true, finished = false, activates = "", data = "You stop and see an apple laying near the rock\nProbably it fell off a tree...", on_finish = "backpack add apple" },
    { x = 15, y = 8, type = EVENT_TYPE.special, active = true, finished = false, activates = "", data = "You see a strange bootle", on_finish = "backpack add potion" },
}

return EVENTS
