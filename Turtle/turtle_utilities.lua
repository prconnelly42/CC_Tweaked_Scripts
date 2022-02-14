-- Module containing various utility functions for turtles
local M = {}

M.CHUNK_LOADER_3X3 = 'chunkloaders:basic_chunk_loader'
M.EMPTY_BUCKET = 'minecraft:bucket'
M.CHUNK_LOADERS = {'chunkloaders:basic_chunk_loader'}
M.VALID_FUEL = {'minecraft:coal', 'minecraft:charcoal', 'minecraft:coal_block', 'minecraft:lava_bucket'}

local connected_to_inventory = false
local network_inventory = nil
local network_inventory_name = nil
local turtleName = nil


-- Print current fuel level to the console
local function printFuelInfo()
    print(("Current fuel: %s"):format(turtle.getFuelLevel()))
end
M.printFuelInfo = printFuelInfo

-- Pause for a specified period of time
-- @param n This is a float specifing the number of seconds to sleep
local function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do
      -- nothing
    end
end
M.sleep = sleep


-- Scroll the display by one line of text
-- @param peri This string is the name of the peripheral to wrap (E.g. front, top, back)
-- @return Boolean specifying if we have successfully connected to the network inventory
local function connectToInventory(peri)
    sleep(0.2)
    modem = peripheral.wrap(peri)
    turtleName = modem.getNameLocal()
    network_inventory = peripheral.find("inventory")
    if(modem == nil or turtleName == nil or network_inventory == nil) then
        connected_to_inventory = false
    else
        network_inventory_name = peripheral.getName(network_inventory)
        connected_to_inventory = true
    end
    return connected_to_inventory
end
M.connectToInventory = connectToInventory


-- Set status of network inventory connection
local function disconnectFromInventory()
    connected_to_inventory = false
    network_inventory = nil
    network_inventory_name = nil
end
M.disconnectFromInventory = disconnectFromInventory


-- Deposit all items of a specified name into network inventory
-- @param target_item_name This string is the name of the item to deposit
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "front"
-- @return Boolean specifying if we have successfully deposited all of the specified items
local function depositAllOfType(target_item_name, peri)
    peri = peri or "front"
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print(("Unable to deposit %s"):format(target_item_name))
        return false
    end

    for slot=1,16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if(item ~= nil and (item.name == target_item_name or target_item_name == "ALL")) then
            network_inventory.pullItems(turtleName, slot)
            if(turtle.getItemCount() > 0) then
                print(("Unable to deposit %s"):format(target_item_name))
                return false
            end
        end
    end
    return true
end
M.depositAllOfType = depositAllOfType


-- Deposit all items in local inventory from a list
-- @param target_item_name This table is a list with the names of the item to deposit
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to front
-- @return Boolean specifying if we have successfully deposited all of the items
function depositAllWhitelist(target_item_list, peri)
    peri = peri or "front"
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print("Unable to deposit items in list")
        return false
    end

    for slot=1,16 do
        turtle.select(slot)
        local valid_item = false
        local item = turtle.getItemDetail()
        for i, val in ipairs(target_item_list) do
            if(val == item.name) then
                valid_item = true
                break
            end
        end
        if(item ~= nil and valid_item) then
            network_inventory.pullItems(turtleName, slot)
            if(turtle.getItemCount() > 0) then
                print(("Unable to deposit %s"):format(target_item_name))
                return false
            end
        end
    end
    return true
end
M.depositAllWhitelist = depositAllWhitelist


-- Deposit all items in local inventory not in a list
-- @param target_item_name This table is a list with the names of the item not to deposit
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to front
-- @return Boolean specifying if we have successfully deposited all of the items
function depositAllBlacklist(target_item_list, peri)
    peri = peri or "front"
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print("Unable to deposit items not in list")
        return false
    end

    for slot=1,16 do
        turtle.select(slot)
        local valid_item = true
        local item = turtle.getItemDetail()
        for i, val in ipairs(target_item_list) do
            if(val == item.name) then
                valid_item = false
                break
            end
        end
        if(item ~= nil and valid_item) then
            network_inventory.pullItems(turtleName, slot)
            if(turtle.getItemCount() > 0) then
                print(("Unable to deposit %s"):format(target_item_name))
                return false
            end
        end
    end
    return true
end
M.depositAllBlacklist = depositAllBlacklist


-- Deposit all items in local inventory
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back).
-- @return Boolean specifying if we have successfully deposited all of the items
local function depositAll(peri)
    return depositAllOfType("ALL", peri)
end
M.depositAll = depositAll


-- Refuel the turtle using available fuel in its inventory
-- @param minimum_fuel_level This number is the fuel level at which to stop refueling
local function refuel(minimum_fuel_level)
    print("Refueling")
    local need_more_fuel = true
    for i=1,16 do
        turtle.select(i)
        turtle.refuel()
        if(turtle.getFuelLevel() > minimum_fuel_level) then
            need_more_fuel = false
        end

        if(not need_more_fuel) then
            break
        end
    end
end
M.refuel = refuel


-- Refuel the turtle using available fuel in its inventory
-- @param minimum_fuel_level This number is the fuel level at which to stop refueling
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "front"
-- @return Boolean specifying if the turtle has refueled past the minimum level
local function retrieveFuel(minimum_fuel_level, peri)
    print("Retrieving fuel")
    peri = peri or "front"
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print("Unable to retrieve fuel")
        return false
    end

    -- While we need more fuel
    local max_fuel_flag = false 
        -- Look at every item in the network inventory
    for slot, item in pairs(network_inventory.list()) do
        -- Compare this item to every valid fuel
        for i, val in ipairs(VALID_FUEL) do
            if(val == item.name) then
                if(turtle.getFuelLevel() >= minimum_fuel_level*10) then
                    print("Max fuel")
                    max_fuel_flag = true
                    depositAllOfType(EMPTY_BUCKET)
                    break
                end
                num_pulled = network_inventory.pushItems(turtleName, slot)
                print(("Retrieved %d %s"):format(num_pulled, item.name))
                refuel()
                depositAllOfType(EMPTY_BUCKET)
                break
            end
        end
        if(max_fuel_flag) then
            break
        end
    end
    return turtle.getFuelLevel() >= minimum_fuel_level
end
M.retrieveFuel = retrieveFuel


-- Check if a slot has the specified item
-- @param target_item_name This string is the name of the item to check for
-- @param slot (Optional) This number refers to the slot (defaults to the selected slot)
-- @return Boolean specifying if the slot has the item
local function selectedSlotHasThisItem(target_item_name, slot)
    assert(target_item_name ~= nil, "Cannot check for nil item")
    slot = slot or turtle.getSelectedSlot()
    item = turtle.getItemDetail()
    item_name = nil
    if(item ~= nil) then
        item_name = item.name
        return item_name == target_item_name
    else
        return false
    end
end
M.selectedSlotHasThisItem = selectedSlotHasThisItem


-- Check if a slot has the an item from the specified list
-- @param target_item_name This table is a list of the items to check for
-- @param slot (Optional) This number refers to the slot (defaults to the selected slot)
-- @return Boolean specifying if the slot has an item from our list
local function selectedSlotHasItemInThisList(target_item_list, slot)
    assert(target_item_name ~= nil, "Cannot check against a nil table")
    slot = slot or turtle.getSelectedSlot()
    item = turtle.getItemDetail()
    item_name = nil
    if(item ~= nil) then
        item_name = item.name
    else
        return false
    end
    for i, val in ipairs(target_item_list) do
        if(val == item_name) then
            return true
        end
    end
    return false
end
M.selectedSlotHasItemInThisList = selectedSlotHasItemInThisList


-- Count the number of a specified item in local inventory
-- @param target_item_name This string is the name of the item to count
-- @return Number of items
local function getNumOfThisItemInInventory(target_item_name)
    local total = 0
    for i=1,16 do
        turtle.select(i)
        if(selectedSlotHasThisItem(target_item_name)) then
            total = total + turtle.getItemCount()
        end
    end
    return total
end
M.getNumOfThisItemInInventory = getNumOfThisItemInInventory


-- Check if the slot has a chunk loader
-- @param slot (Optional) This number refers to the slot we are looking at
-- @return Boolean specifying if there is a chunk loader in this slot
local function isChunkLoader(slot)
    return selectedSlotHasItemInThisList(CHUNK_LOADERS, slot)
end
M.isChunkLoader = isChunkLoader


-- Place a specific item in a specific direction
-- @param target_item_name This string is the name of the item to place
-- @param direction This string is the name of the direction to place in
-- @param can_dig This boolean specifies if we can dig the current block that is present
-- @return Boolean specifying if we have successfully placed the item
local function placeItemOfType(target_item_name, direction, can_dig)
    for i=0,16 do
        if(i ~= 0) then
            turtle.select(i)
        end
        if(selectedSlotHasThisItem(target_item_name)) then
            if(direction == "forward") then
                if(can_dig and turtle.detect()) then
                    turtle.dig()
                end
                return turtle.place()
            elseif(direction == "up") then
                if(can_dig and turtle.detectUp()) then
                    turtle.digUp()
                end
                return turtle.placeUp()
            elseif(direction == "down") then
                if(can_dig and turtle.detectDown()) then
                    turtle.digDown()
                end
                return turtle.placeDown()
            else
                print("Invalid direction")
                return false
            end
        end
    end
    return false
end
M.placeItemOfType = placeItemOfType



return M
