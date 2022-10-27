Type = {
    consumable = "consumable",
    sword = "sword",
    helmet = "helmet",
    chestplate = "chestplate",
    leggings = "leggings",
    boots = "boots",
}

Rarity = {
    common = "common",
    rare = "rare",
    very_rare = "very_rare",
    epic = "epic",
    legendary = "legendary",
    unique = "unique",
}

Items = {
    potion = { name = "potion", type = Type.consumable, rarity = Rarity.rare, value = 50 },
    bread = { name = "bread", type = Type.consumable, rarity = Rarity.common, value = 25 },
    apple = { name = "apple", type = Type.consumable, rarity = Rarity.common, value = 25 },
    rice = { name = "rice", type = Type.consumable, rarity = Rarity.common, value = 25 },
    potato = { name = "potato", type = Type.consumable, rarity = Rarity.common, value = 25 },
}

return Items
