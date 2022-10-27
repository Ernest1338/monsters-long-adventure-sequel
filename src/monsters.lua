Type = {
    hostile = "hostile",
    neutral = "neutral",
    friendly = "friendly",
}

Monsters = {
    -- TODO: health and attack random range (scale with level)
    Zombie = { name = "zombie", type = Type.hostile, health = 100, attack = 10 },
    Spider = { name = "spider", type = Type.hostile, health = 100, attack = 10 },
    Skeleton = { name = "skeleton", type = Type.hostile, health = 100, attack = 10 },
    Demogorgon = { name = "demogorgon", type = Type.hostile, health = 100, attack = 10 },
    Slenderman = { name = "slenderman", type = Type.hostile, health = 100, attack = 10 },
}

return Monsters
