TYPE = {
    consumable = "consumable",
    sword = "sword",
    helmet = "helmet",
    chestplate = "chestplate",
    leggings = "leggings",
    boots = "boots",
}

RARITY = {
    common = "common",
    rare = "rare",
    very_rare = "very_rare",
    epic = "epic",
    legendary = "legendary",
    unique = "unique",
}

ITEMS = {
    potion = { name = "potion", type = TYPE.consumable, rarity = RARITY.rare, value = 50 },
    bread = { name = "bread", type = TYPE.consumable, rarity = RARITY.common, value = 25 },
    apple = { name = "apple", type = TYPE.consumable, rarity = RARITY.common, value = 25 },
    rice = { name = "rice", type = TYPE.consumable, rarity = RARITY.common, value = 25 },
    potato = { name = "potato", type = TYPE.consumable, rarity = RARITY.common, value = 25 },
}

return ITEMS
