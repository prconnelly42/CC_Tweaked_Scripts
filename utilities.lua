-- Module containing various utility functions for computers
local M = {}


-- Pause for a specified period of time
-- @param n This is a float specifing the number of seconds to sleep
local function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do
      -- nothing
    end
end
M.sleep = sleep


-- Clear the line and move the cursor to left side of the terminal
function moveCursorToBeginningOfLine()
    term.clearLine()
    local cursor_x = nil
    local cursor_y = nil
    cursor_x, cursor_y = term.getCursorPos()
    term.setCursorPos(1, cursor_y)
end
M.moveCursorToBeginningOfLine = moveCursorToBeginningOfLine