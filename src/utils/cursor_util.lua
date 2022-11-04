ESCAPE_CHAR = string.char(27)

Cursor_util = {}

function Cursor_util.set_cursor_pos(x, y)
    io.write(ESCAPE_CHAR .. "[" .. y .. ";" .. x .. "H")
end

function Cursor_util.save_cursor_pos()
    io.write(ESCAPE_CHAR .. "[s")
end

function Cursor_util.restore_cursor_pos()
    io.write(ESCAPE_CHAR .. "[u")
end

-- TODO: This shouldn't use saveCursorPos() because it may overwrite user's wanted data
function Cursor_util.print_in_pos(text, pos)
    Cursor_util.save_cursor_pos()
    Cursor_util.set_cursor_pos(pos[1], pos[2])
    io.write(text)
    Cursor_util.restore_cursor_pos()
    io.flush()
end

return Cursor_util
