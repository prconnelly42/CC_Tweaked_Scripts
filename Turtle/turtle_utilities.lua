local U = require "utilities"

-- Module containing various utility functions for turtles
local M = {}

M.AUTO_LOAD_CHUNKS = true
M.CHUNK_LOADER_3X3 = 'chunkloaders:basic_chunk_loader'
M.EMPTY_BUCKET = 'minecraft:bucket'
M.CHUNK_LOADERS = {'chunkloaders:basic_chunk_loader'}
M.VALID_FUEL = {'minecraft:coal', 'minecraft:charcoal', 'minecraft:coal_block', 'minecraft:lava_bucket'}
M.CHUNK_LOADERS = {'chunkloaders:basic_chunk_loader' : 16}

local connected_to_inventory = false
local network_inventory = nil
local network_inventory_name = nil
local turtleName = nil
local turtle_facing_direction = 0
local turtle_offset = vector.new(0, 0, 0)
local chunk_loader_offset = nil
local type_of_chunk_loader = M.CHUNK_LOADER_3X3


-- Print current fuel level to the console
local function printFuelInfo()
    print(("Current fuel: %s"):format(turtle.getFuelLevel()))
end
M.printFuelInfo = printFuelInfo


-- Turn the turtle
-- @param direction This string is the direction to turn (either "R" or "L")
-- @return Boolean specifying if we have successfully turned
function turn(direction)
    local success
    if(direction == "R") then
        success = turtle.turnRight()
        turtle_facing_direction = math.fmod(turtle_facing_direction + 1, 4)
    else
        success = turtle.turnLeft()
        turtle_facing_direction = math.fmod(turtle_facing_direction + 3, 4)
    end
    return success
end
M.turn = turn



-- Turn the turtle to face a particular direction
-- @param target_facing_direction This number is between 0 and 3, 0 being the direction upon program start
-- @return Boolean specifying if we are facing the target direction
function turnToFace(target_facing_direction)
    assert(target_facing_direction >=0 and target_facing_direction < 4)
    local success = true
    if(math.fmod(turtle_facing_direction - target_facing_direction + 4, 4) == 1) then
        success = success and turn("L")
    else
        while(turtle_facing_direction ~= target_facing_direction and success) do
            success = success and turn("R")
        end
    end
    return success
end
M.turnToFace = turnToFace


-- Scroll the display by one line of text
-- @param peri This string is the name of the peripheral to wrap (E.g. front, top, back)
-- @return Boolean specifying if we have successfully connected to the network inventory
local function connectToInventory(peri)
    U.sleep(0.3)
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


-- Retrieve specific item from network inventory
-- @param target_item_name This string is the name of the item to deposit
-- @param count (Optional) Number - how many of this item we're attempting to get
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "front"
-- @return Boolean specifying if we have successfully retrieved at least one of the target item
local function retrieveItem(target_item_name, count, peri)
    assert(target_item_name ~= nil)
    assert(count > 0)
    peri = peri or "front"
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print(("Unable to retrieve %s"):format(target_item_name))
        return false
    end

    local total_pulled = 0
    for slot, item in pairs(network_inventory.list()) do
        if(item.name == target_item_name) then
            local num_pulled = chest.pushItems(turtleName, slot, count)
            total_pulled = total_pulled + num_pulled
        end
    end
    if(total_pulled > 0) then
        print(("Retrieved %d %s from chest"):format(total_pulled, target_item_name))
    end
    if(total_pulled == 0) then
        print("Error - Did not retrieve any blocks")
    end
    return total_pulled
end
M.retrieveItem = retrieveItem


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
        if(item ~= nil and (item.name == target_item_name)) then
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
        if(item ~= nil) then
            for i, val in ipairs(target_item_list) do
                if(val == item.name) then
                    valid_item = true
                    break
                end
            end
            if(valid_item) then
                network_inventory.pullItems(turtleName, slot)
                if(turtle.getItemCount() > 0) then
                    print(("Unable to deposit %s"):format(target_item_name))
                    return false
                end
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
        if(item ~= nil) then
            for i, val in ipairs(target_item_list) do
                if(val == item.name) then
                    valid_item = false
                    break
                end
            end
            if(valid_item) then
                network_inventory.pullItems(turtleName, slot)
                if(turtle.getItemCount() > 0) then
                    print(("Unable to deposit %s"):format(target_item_name))
                    return false
                end
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
    return depositAllBlacklist({}, peri)
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


-- Test if turtle inventory is empty
-- @return Boolean true if inventory is empty, false otherwise
function isInventoryEmpty()
    for i=1,16 do
        turtle.select(i)
        if(turtle.getItemCount() ~= 0) then
            return false
        end
    end
    return true
end
M.isInventoryEmpty = isInventoryEmpty


-- Test if there is at least one empty slot in turtle inventory
-- @return Boolean true if empty slot exists
function emptySlotExists()
    for i=1,16 do
        if(turtle.getItemCount(i) == 0) then
            return true
        end
    end
    return false
end
M.emptySlotExists = emptySlotExists


-- Check that an item from the given list is in the turtle's inventory
-- @param target_item_name This table is the list to check
-- @return Boolean true if an item from the list is present
function turtleHasItemInList(target_item_list)
    for i=1,16 do
        turtle.select(i)
        if(TU.selectedSlotHasItemInThisList(target_item_list)) then
            return true
        end
    end
    return false
end
M.turtleHasItemInList = turtleHasItemInList


-- Check that an item from the turtle's inventory is not in the given list
-- @param target_item_name This table is the list to check
-- @return Boolean true if an item not from the list is present
function turtleHasItemNotInList(target_item_list)
    for i=1,16 do
        turtle.select(i)
        if(not TU.selectedSlotHasItemInThisList(target_item_list)) then
            return true
        end
    end
    return false
end
M.turtleHasItemNotInList = turtleHasItemNotInList


-- Get at least one chunk loader from the network inventory
-- @return Boolean true if chunk loader was retrieved
function retrieveChunkLoaders()
    print("Retrieving fuel")
    peri = peri or "front"
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print("Unable to retrieve fuel")
        return false
    end

    local count = 0 
    -- Look at every item in the chest
    for slot, item in pairs(chest.list()) do
        -- Compare this item to every valid chunk loader
        for i, val in ipairs(CHUNK_LOADERS) do
            if(val == item.name) then
                num_pulled = chest.pushItems(turtleName, slot)
                count = count + num_pulled
                print(("Retrieved %d %s from chest"):format(num_pulled, item.name))
                if(count > 0) then
                    return true
                end
            end
        end
    end
    return false
end
M.retrieveChunkLoaders = retrieveChunkLoaders


-- Check if the slot has a chunk loader
-- @param slot (Optional) This number refers to the slot we are looking at
-- @return Boolean specifying if there is a chunk loader in this slot
local function isChunkLoader(slot)
    return selectedSlotHasItemInThisList(CHUNK_LOADERS, slot)
end
M.isChunkLoader = isChunkLoader


-- Make sure there is 2 chunk loaders in inventory, or 1 placed and one in inventory
-- @return Boolean specifying if there is a chunk loader in this slot
local function getChunkLoaderIfNotInInventory()
    local total = 0
    if(chunk_loader_offset ~= nil) then
        total = 1
    end
    for i=1,16 do
        turtle.select(i)
        local count = turtle.getItemCount()
        if(isChunkLoader() and count > 0) then
            total = total + count
            if(total > 1) then
                return true
            end
        end
    end
    while(retrieveChunkLoaders() and total < 2) do
    end
    return total > 1
end
M.getChunkLoaderIfNotInInventory = getChunkLoaderIfNotInInventory


-- Place a specific item in a specific direction
-- @param direction This string is the name of the direction to place in
-- @param slot (Optional) This number is the slot with the item we are attempting to place (Defaults to selected)
-- @param can_dig (Optional) This boolean specifies if we can dig the current block that is present (Defaults to false)
-- @return Boolean specifying if we have successfully placed the item
local function placeItem(direction, slot, can_dig)
    slot = slot or turtle.getSelectedSlot()
    assert(slot > 0 and slot < 17)
    turtle.select(slot)
    can_dig = can_dig or false
    local item = turtle.getItemDetail()
    if(item ~= nil) then
        if(direction == "forward") then
            while(can_dig and turtle.detect()) do
                turtle.dig()
            end
            return turtle.place()
        elseif(direction == "up") then
            while(can_dig and turtle.detectUp()) do
                turtle.digUp()
            end
            return turtle.placeUp()
        elseif(direction == "down") then
            while(can_dig and turtle.detectDown()) do
                turtle.digDown()
            end
            return turtle.placeDown()
        else
            print("Invalid direction")
            return false
        end
    end
    return false
end
M.placeItemOfType = placeItemOfType


-- Place a specific item in a specific direction
-- @param target_item_name This string is the name of the item to place
-- @param direction This string is the name of the direction to place in
-- @param can_dig (Optional) This boolean specifies if we can dig the current block that is present (Defaults to false)
-- @return Boolean specifying if we have successfully placed the item
local function placeItemOfType(target_item_name, direction, can_dig)
    can_dig = can_dig or false
    for i=0,16 do
        if(i ~= 0) then
            turtle.select(i)
        end
        if(selectedSlotHasThisItem(target_item_name)) then
            if(direction == "forward") then
                while(can_dig and turtle.detect()) do
                    turtle.dig()
                end
                return turtle.place()
            elseif(direction == "up") then
                while(can_dig and turtle.detectUp()) do
                    turtle.digUp()
                end
                return turtle.placeUp()
            elseif(direction == "down") then
                while(can_dig and turtle.detectDown()) do
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


-- Place a chunk loader up
-- @return Boolean specifying if we have successfully placed
function placeChunkLoader()
    for i=1,16 do
        turtle.select(i)
        if(isChunkLoader() and turtle.placeUp()) then
            chunk_loader_offset = turtle_offset:add(vector.new(0, 1, 0))
            return true
        end
    end

    return false
end
M.placeChunkLoader = placeChunkLoader


-- Go get the last chunk loader placed
-- @param old_chunk_loader_offset - Vector
-- @param movement_order Vector - see goToOffset()
-- @return Boolean specifying if we have succeeded
function retrieveLastChunkLoader(old_chunk_loader_offset, movement_order)
    assert(old_chunk_loader_offset ~= nil)

    local current_turtle_offset = turtle_offset
    local current_turtle_direction = turtle_facing_direction
    
    print("Getting last chunk loader")
    goToOffset(old_chunk_loader_offset, movement_order)
    print("last chunk loader retrieved")
    goToOffset(current_turtle_offset, movement_order)
    turnToFace(current_turtle_direction)

    return getNumOfThisItemInInventory(type_of_chunk_loader) > 0
end


-- Place a new chunk loader, retrieve the previous, and return to the current position
-- @param new_offset This vector offset the turtle wants to move to
-- @param check_separation This boolean, if true, means we should only replace the chunk loader
-- if we are about to exceed its maximum range
-- @return Boolean specifying if we have succeeded
function replaceChunkLoader(new_offset, check_separation)
    check_separation = check_separation or false
    if(AUTO_LOAD_CHUNKS) then
        local separation = new_offset:sub(chunk_loader_offset)
        local chunk_loader_range = M.CHUNK_LOADERS[type_of_chunk_loader]
        if(separation:length() > chunk_loader_range - 1) then
            local old_chunk_loader_offset = chunk_loader_offset
            if(placeChunkLoader()) then
                print("Placed chunk loader")
            else
                print("Failed to place chunk loader")
                return false
            end
            if(retrieveLastChunkLoader(old_chunk_loader_offset)) then
                print("Retrieved previous chunk loader")
            else
                print("Failed to retrieve previous chunk loader")
                return false
            end
        end
    end
    return true
end


-- Move the turtle backward one spot
-- @return Boolean specifying if we have successfully moved
function moveBackward()
    local new_offset = turtle_offset

    if(turtle_facing_direction == 0) then
        new_offset = turtle_offset:add(vector.new(0, 0, -1))
    elseif(turtle_facing_direction == 1) then
        new_offset = turtle_offset:add(vector.new(-1, 0, 0))
    elseif(turtle_facing_direction == 2) then
        new_offset = turtle_offset:add(vector.new(0, 0, 1))
    elseif(turtle_facing_direction == 3) then
        new_offset = turtle_offset:add(vector.new(1, 0, 0))
    end

    if(not replaceChunkLoader(new_offset, true)) then
        return false
    end

    if(not turtle.back())
        return false
    else
        turtle_offset = new_offset
        return true
    end

end
M.moveBackward = moveBackward

-- Move the turtle forward one spot
-- @param can_dig This boolean specifies if we can dig through a block to move. Defaults to true
-- @return Boolean specifying if we have successfully moved
function moveForward(can_dig)
    can_dig = can_dig or true
    local new_offset = turtle_offset

    if(turtle_facing_direction == 0) then
        new_offset = turtle_offset:add(vector.new(0, 0, 1))
    elseif(turtle_facing_direction == 1) then
        new_offset = turtle_offset:add(vector.new(1, 0, 0))
    elseif(turtle_facing_direction == 2) then
        new_offset = turtle_offset:add(vector.new(0, 0, -1))
    elseif(turtle_facing_direction == 3) then
        new_offset = turtle_offset:add(vector.new(-1, 0, 0))
    end

    if(not replaceChunkLoader(new_offset, true)) then
        return false
    end

    while(can_dig and turtle.detect()) do
        turtle.dig()
    end

    if(not turtle.forward())
        return false
    else
        turtle_offset = new_offset
        return true
    end
end
M.moveForward = moveForward


-- Move the turtle up one spot
-- @param can_dig This boolean specifies if we can dig through a block to move. Defaults to true
-- @return Boolean specifying if we have successfully moved
function moveUp(can_dig)
    can_dig = can_dig or true
    local new_offset = turtle_offset

    new_offset = turtle_offset:add(vector.new(0, 1, 0))

    if(not replaceChunkLoader(new_offset, true)) then
        return false
    end

    while(can_dig and turtle.detectUp()) do
        turtle.digUp()
    end

    if(not turtle.up())
        return false
    else
        turtle_offset = new_offset
        return true
    end
end
M.moveUp = moveUp



-- Move the turtle down one spot
-- @param can_dig This boolean specifies if we can dig through a block to move. Defaults to true
-- @return Boolean specifying if we have successfully moved
function moveDown(can_dig)
    can_dig = can_dig or true
    local new_offset = turtle_offset

    new_offset = turtle_offset:add(vector.new(0, -1, 0))

    if(not replaceChunkLoader(new_offset, true)) then
        return false
    end

    while(can_dig and turtle.detectDown()) do
        turtle.digDown()
    end

    if(not turtle.down())
        return false
    else
        turtle_offset = new_offset
        return true
    end
end
M.moveDown = moveDown



-- Move the turtle to a specific offset
-- @param target_offset This vector specifies where we want the turtle to go
-- @param movement_order A String designating the order axes are to be moved on, from left to right
--  Ex: xyz, zxy, yzx, xy, zx, y. Default is xyz
-- @return Boolean specifying if the turtle_offset matches the target_offset
function goToOffset(target_offset, movement_order)
    movement_order = movement_order or "xyz"
    for c in movement_order:gmatch"." do
        if(c == "x") then
            while(turtle_offset.x > target_offset.x) do
                turnToFace(3)
                moveForward()
            end
            while(turtle_offset.x < target_offset.x) do
                turnToFace(1)
                moveForward()
            end
        elseif(c == "y") then
            while(turtle_offset.y > target_offset.y) do
                moveDown()
            end
            while(turtle_offset.y < target_offset.y) do
                moveUp()
            end
        elseif(c == "z") then
            while(turtle_offset.z < target_offset.z) do
                turnToFace(0)
                moveForward()
            end
            while(turtle_offset.z > target_offset.z) do
                turnToFace(2)
                moveForward()
            end
        else
            error("Invalid movement order", 0)
        end
    end
    
    return turtle_offset:equals(target_offset)
end
M.goToOffset = goToOffset



return M


