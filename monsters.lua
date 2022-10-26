TYPE = {
    hostile = "hostile",
    neutral = "neutral",
    friendly = "friendly",
}

MONSTERS = {
    -- TODO: health and attack random range (scale with level)
    Zombie = { name = "zombie", type = TYPE.hostile, health = 100, attack = 10 },
    Spider = { name = "spider", type = TYPE.hostile, health = 100, attack = 10 },
    Skeleton = { name = "skeleton", type = TYPE.hostile, health = 100, attack = 10 },
    Demogorgon = { name = "demogorgon", type = TYPE.hostile, health = 100, attack = 10 },
    Slenderman = { name = "slenderman", type = TYPE.hostile, health = 100, attack = 10 },
}

return MONSTERS
