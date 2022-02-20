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
local function moveCursorToBeginningOfLine()
    term.clearLine()
    local cursor_x = nil
    local cursor_y = nil
    cursor_x, cursor_y = term.getCursorPos()
    term.setCursorPos(1, cursor_y)
end
M.moveCursorToBeginningOfLine = moveCursorToBeginningOfLine


-- Code modified from https://stackoverflow.com/questions/12674345/lua-retrieve-list-of-keys-in-a-table
-- Get a list of keys from a dictionary
-- @param table inTable - The dictionary to get keys from 
-- @return table - List of keys
local function getTableKeys(inTable)
    local keyset = {}
    local n = 0
    for k,v in pairs(inTable) do
        n=n+1
        keyset[n]=k
    end
    return keyset
end
M.getTableKeys = getTableKeys


-- Code modified from https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
-- Return anything as a string
-- @param input - whatever we want to see as a string
-- @return String - input as a String
function any_tostring(input)
    if type(input) == 'table' then
        local s = '{ '
        for k,v in pairs(input) do
            if type(k) ~= 'number' then 
                k = '"'..k..'"' 
            end
            s = s .. '['..k..'] = ' .. any_tostring(v) .. ','
        end
        return s .. '} '
    else
        return tostring(input)
    end
end
M.any_tostring = any_tostring


-- Code taken from https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
-- @param table input - any table
-- @return number - the length of the table
local function tablelength(input)
    local count = 0
    for _ in pairs(input) do 
        count = count + 1 
    end
    return count
end
M.tablelength = tablelength

return M