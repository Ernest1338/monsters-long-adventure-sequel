#!/usr/bin/luajit

Input_reader = {}

function Input_reader.read_key()
    local key = nil
    os.execute("stty raw -echo")
    local byte1 = io.read(1)
    if byte1 == string.char(27) then
        local byte2 = io.read(2)
        if byte2 == string.char(91) .. string.char(65) then
            key = "arrow_up"
        elseif byte2 == string.char(91) .. string.char(66) then
            key = "arrow_down"
        elseif byte2 == string.char(91) .. string.char(67) then
            key = "arrow_right"
        elseif byte2 == string.char(91) .. string.char(68) then
            key = "arrow_left"
        else
            key = "unknown_key"
        end
    else
        key = byte1
    end
    io.write("\r\n")
    io.flush()
    os.execute("stty sane")
    return key
end

return Input_reader
