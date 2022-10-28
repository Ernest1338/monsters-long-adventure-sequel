Input_reader = {}

Input_reader.Key_code = {
    arrow = {
        up = string.char(65),
        down = string.char(66),
        right = string.char(67),
        left = string.char(68),
    },
    unknown = "",
}

function Input_reader.read_key()
    local Key_code = Input_reader.Key_code
    local key = nil
    os.execute("stty raw -echo")
    local byte1 = io.read(1)
    if byte1 == string.char(27) then
        local byte2 = io.read(2)
        if byte2 == string.char(91) .. Key_code.arrow.up then
            key = Key_code.arrow.up
        elseif byte2 == string.char(91) .. Key_code.arrow.down then
            key = Key_code.arrow.down
        elseif byte2 == string.char(91) .. Key_code.arrow.right then
            key = Key_code.arrow.right
        elseif byte2 == string.char(91) .. Key_code.arrow.left then
            key = Key_code.arrow.left
        else
            key = Key_code.unknown
        end
    else
        key = byte1
    end
    io.write("\r\n")
    io.flush()
    os.execute("stty -raw echo")
    return key
end

return Input_reader
