local b_modem
local monitor
local display_buffer = {}
local first_line_displayed_index
local last_line_displayed_index

-------------------
-- BEGIN UTILITIES
-------------------


function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do
      -- nothing
    end
end


function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end


function shift_table_left(T)
    table.insert( T, table.remove(T))
end


-------------------
-- END UTILITIES
-------------------


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
    elseif(direction == "down" and last_line_displayed_index < tablelength(display_buffer) - 1) then
        monitor.scroll(1)
        monitor.setCursorPos(1, height - 1)
        last_line_displayed_index = last_line_displayed_index + 1
        monitor.write(display_buffer[last_line_displayed_index])
    end
end


function scroll_display_down()
    assert(monitor ~= nil)
    monitor.scroll(1)
    shift_table_left(display_buffer)
    table.remove(display_buffer)
end


function write_newline_to_display(text)
    assert(monitor ~= nil)
    local width
    local height
    width, height = monitor.getSize()
    local num_lines = tablelength(display_buffer)
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
        if(type(message[0]) == "string" and type(message[1] == "string")) then
            text = message[0] .. ": " .. message[1]
            write_newline_to_display(text)
        elseif(type(message) == "string") then
            write_newline_to_display(message)
        else
            print("Received invalid message")
        end
    end
end


function main()
    connect_monitor()
    reset_display()
    display_logs()
end


main()
  
