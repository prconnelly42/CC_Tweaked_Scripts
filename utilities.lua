-- Module containing various utility functions for computers
local M = {}

M.LOG_LEVEL_SET = "debug"
M.REMOTE_LOG_LEVEL = "info"
M.LOG_LEVELS = {["error"] = 0, ["warning"] = 1, ["info"] = 2, ["debug"] = 3}
M.PRINT_LOGS_TO_CONSOLE = true
M.SEND_LOGS = true

-- Function Declarations --
local log
local enableRemoteLogging
local sendLogMessage
local sleep
local moveCursorToBeginningOfLine
local getTableKeys
local listContains
local any_tostring
local tablelength

-- Global variables
local remote_logging_enabled = false
local log_pc_id = nil
local modem = nil

-- Log messages
-- @param String message - the log message
-- @param String level - the logging level ("debug", "error", "warning", "info") 
-- @param Table modem (Optional) - the modem on which to send the logs
function log(message, level)
    assert(listContains(getTableKeys(M.LOG_LEVELS), level)) -- Check the level is valid
    if(M.LOG_LEVELS[level] <= M.LOG_LEVELS[M.LOG_LEVEL_SET]) then
        print(("%s: %s"):format(level, message))
    end
    if(M.SEND_LOGS and M.LOG_LEVELS[level] <= M.LOG_LEVELS[M.REMOTE_LOG_LEVEL]) then
        local status, err = pcall(sendLogMessage(("%s: %s"):format(level, message)))
        if(not status) then
            log(err, "warning")
        end
    end
end
M.log = log


-- Discover the logging pc to enable remote logging
-- @param String name - the modem to wrap ("top", "right", etc)
-- @throws error
function enableRemoteLogging(name)
    modem = peripheral.wrap(name)
    if(modem == nil) then
        error("No logging modem attached")
    end
    local remote_pc_id = rednet.lookup("logip")
    if(remote_pc_id == nil) then
        error("No logging PC found")
    end
    log_pc_id = remote_pc_id
    remote_logging_enabled = true
end
M.enableRemoteLogging = enableRemoteLogging


-- Send a message to the logging PC
-- @param String message - the message to be logged
-- @throws error
function sendLogMessage(message)
    local success = rednet.send(log_pc_id, message, "logip")
    if(not success) then
        error("Logging PC is unavailable. Ensure remote logging has been enabled.")
    end
end
M.sendLogMessage = sendLogMessage


-- Pause for a specified period of time
-- @param n This is a float specifing the number of seconds to sleep
function sleep(n)
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


-- Code modified from https://stackoverflow.com/questions/12674345/lua-retrieve-list-of-keys-in-a-table
-- Get a list of keys from a dictionary
-- @param table inTable - The dictionary to get keys from 
-- @return table - List of keys
function getTableKeys(inTable)
    local keyset = {}
    local n = 0
    for k,v in pairs(inTable) do
        n=n+1
        keyset[n]=k
    end
    return keyset
end
M.getTableKeys = getTableKeys


-- Check if a value is in a list
-- @param Table inList - the list of elements to check
-- @param target - the target to check for
-- @return Boolean - true if the element is in the list, false otherwise
function listContains(inList, target)
    for _, e in pairs(inList) do
        if e == target then
          return true
        end
    end
    return false
end
M.listContains = listContains


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
function tablelength(input)
    local count = 0
    for _ in pairs(input) do 
        count = count + 1 
    end
    return count
end
M.tablelength = tablelength

return M


-- Perform a shift left operation on the table
-- Ex: {1, 2, 3} -> {2, 3, 1}
-- @param Table table_in - the table to perform the operation on
-- @return Table - the modified table
function shiftTableLeft(table_in)
    table.insert(table_in, table.remove(table_in))
    return table_in
end