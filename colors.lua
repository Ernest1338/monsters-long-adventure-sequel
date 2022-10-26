local escape_char = string.char(27)
COLOR = {
    black = escape_char .. "[30m",
    red = escape_char .. "[31m",
    green = escape_char .. "[32m",
    gold = escape_char .. "[33m",
    blue = escape_char .. "[34m",
    pink = escape_char .. "[35m",
    cyan = escape_char .. "[36m",
    gray = escape_char .. "[90m",
    light_red = escape_char .. "[91m",
    light_green = escape_char .. "[92m",
    yellow = escape_char .. "[93m",
    purple = escape_char .. "[94m",
    light_pink = escape_char .. "[95m",
    light_blue = escape_char .. "[96m",
    white = escape_char .. "[97m",
    bold = escape_char .. "[1m",
    faint = escape_char .. "[2m",
    italic = escape_char .. "[3m",
    underline = escape_char .. "[4m",
    blink = escape_char .. "[5m",
    invert = escape_char .. "[7m",
    strike = escape_char .. "[9m",
    reset = escape_char .. "[00m",
}

return COLOR
