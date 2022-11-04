Type = {
    hostile = "hostile",
    neutral = "neutral",
    friendly = "friendly",
}

Monsters = {
    -- TODO: health and attack random range (scale with level)
    zombie = { name = "zombie", type = Type.hostile, health = 100, attack = 10 },
    spider = { name = "spider", type = Type.hostile, health = 100, attack = 10 },
    skeleton = { name = "skeleton", type = Type.hostile, health = 100, attack = 10 },
    demogorgon = { name = "demogorgon", type = Type.hostile, health = 100, attack = 10 },
    slenderman = { name = "slenderman", type = Type.hostile, health = 100, attack = 10 },
}

return Monsters
