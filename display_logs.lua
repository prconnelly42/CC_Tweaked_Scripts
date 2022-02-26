local U = require "utilities"

-- Function Declarations
local connect_monitor
local reset_display
local scroll_display
local scroll_display_down
local write_newline_to_display
local display_logs
local display_logs_main


-- Global Variables
local b_modem
local monitor
local display_buffer = {}
local first_line_displayed_index
local last_line_displayed_index


function connect_monitor()
    b_modem = peripheral.wrap("back") or error("No modem attached")
    monitor = peripheral.find("monitor") or error("Cannot find monitor")
end


function reset_display()
    assert(monitor ~= nil)
    monitor.clear()
    monitor.setCursorPos(1, 1)
end


-- NOT USED
-- For use with display that saves all text in a buffer
-- Scroll the display by one line of text
-- @param direction This is either a String "up" or "down"
function scroll_display(direction)
    assert(monitor ~= nil)
    local width
    local height
    width, height = monitor.getSize()
    if(direction == "up" and first_line_displayed_index > 0) then
        monitor.scroll(-1)
        monitor.setCursorPos(1, 1)
        first_line_displayed_index = first_line_displayed_index - 1
        monitor.write(display_buffer[first_line_displayed_index])
    elseif(direction == "down" and last_line_displayed_index < U.tablelength(display_buffer) - 1) then
        monitor.scroll(1)
        monitor.setCursorPos(1, height - 1)
        last_line_displayed_index = last_line_displayed_index + 1
        monitor.write(display_buffer[last_line_displayed_index])
    end
end


function scroll_display_down()
    assert(monitor ~= nil)
    monitor.scroll(1)
    U.shiftTableLeft(display_buffer)
    table.remove(display_buffer)
end


function write_newline_to_display(text)
    assert(monitor ~= nil)
    local width
    local height
    width, height = monitor.getSize()
    local num_lines = U.tablelength(display_buffer)
    if(num_lines < height) then
        num_lines = num_lines + 1
    else
        scroll_display_down()
    end
    display_buffer[num_lines - 1] = text
    monitor.setCursorPos(1, num_lines)
    monitor.write(display_buffer[num_lines-1])
end


function display_logs()
    assert(monitor ~= nil)
    rednet.open("right")
    rednet.host("logip", os.getComputerLabel())
    while true do
        local sender_id
        local message
        sender_id, message = rednet.receive("logip")
        local text
        if(type(message) == "table" and (type(message[1]) == "string" and type(message[2] == "string"))) then
            text = message[1] .. ": " .. message[2]
            write_newline_to_display(text)
        elseif(type(message) == "string") then
            write_newline_to_display(message)
        else
            print("Received invalid message")
        end
    end
end


function display_logs_main()
    connect_monitor()
    reset_display()
    display_logs()
end


display_logs_main()
  
