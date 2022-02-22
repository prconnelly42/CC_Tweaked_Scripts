local U = require "utilities"

-- Module containing various utility functions for turtles
local M = {}

M.AUTO_LOAD_CHUNKS = true
M.CHUNK_LOADER_3X3 = 'chunkloaders:basic_chunk_loader'
M.EMPTY_BUCKET = 'minecraft:bucket'
M.CHUNK_LOADERS = {'chunkloaders:basic_chunk_loader'}
M.VALID_FUEL = {'minecraft:coal', 'minecraft:charcoal', 'minecraft:coal_block', 'minecraft:lava_bucket'}
M.CHUNK_LOADERS = {['chunkloaders:basic_chunk_loader'] = 16}
M.CHUNK_LOADER_DEFAULT_DIRECTION = "up"
M.ORIGIN_OFFSET = vector.new(0,0,0)

local connected_to_inventory = false
local network_inventory = nil
local network_inventory_name = nil
local turtleName = nil
local turtle_facing_direction = 0
local turtle_offset = vector.new(0, 0, 0)
local chunk_loader_offset = nil
local chunk_loader_type = M.CHUNK_LOADER_3X3

-- Function Declarations --
local getTurtleOffset
local printFuelInfo
local turn
local turnToFace
local connectToInventory
local disconnectFromInventory
local retrieveItem
local retrieveItemsBlackList
local retrieveItemsWhiteList
local depositAllOfType
local depositAllWhitelist
local depositAllBlacklist
local depositAll
local refuel
local retrieveFuel
local selectedSlotHasThisItem
local selectedSlotHasItemInThisList
local getNumOfThisItemInInventory
local isInventoryEmpty
local emptySlotExists
local turtleHasItemInList
local turtleHasItemNotInList
local isChunkLoader
local getSideBlockName
local getChunkLoaderIfNotInInventory
local placeItem
local placeItemOfType
local moveBackward
local moveForward
local moveUp
local moveDown
local goToOffset
local placeChunkLoader
local retrieveLastChunkLoader
local replaceChunkLoader
local resetState


-- Get the current offset of the turtle from it's starting point
-- @return Vector - the current offset of the turtle
function getTurtleOffset()
    return turtle_offset
end
M.getTurtleOffset = getTurtleOffset


-- Print current fuel level to the console
function printFuelInfo()
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
function connectToInventory(peri)
    U.sleep(0.3)
    peri = peri or "back"
    modem = peripheral.wrap(peri) or error(("Could not connect to '%s' modem"):format(peri))
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
function disconnectFromInventory()
    connected_to_inventory = false
    network_inventory = nil
    network_inventory_name = nil
end
M.disconnectFromInventory = disconnectFromInventory


-- Retrieve specific item from network inventory
-- @param target_item_name This string is the name of the item to deposit
-- @param count (Optional) Number - how many of this item we're attempting to get
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "back"
-- @return Boolean specifying if we have successfully retrieved at least one of the target item
function retrieveItem(target_item_name, count, peri)
    assert(type(target_item_name) == "string")
    assert(count > 0)
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print(("Unable to retrieve %s"):format(target_item_name))
        return false
    end

    local total_pulled = 0
    for slot, item in pairs(network_inventory.list()) do
        if(item.name == target_item_name) then
            local num_pulled = network_inventory.pushItems(turtleName, slot, count)
            count = count - num_pulled
            total_pulled = total_pulled + num_pulled
        end
    end
    if(total_pulled > 0) then
        print(("Retrieved %d %s from network inventory"):format(total_pulled, target_item_name))
    end
    if(total_pulled == 0) then
        error(("Error - Did not retrieve any %s"):format(target_item_name))
    end
    return total_pulled
end
M.retrieveItem = retrieveItem


-- Retrieve specific item from network inventory
-- @param item_list This table is a list of the items to skip when retrieving
-- @param count (Optional) Number - how many items we're attempting to get
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "back"
-- @return Boolean specifying if we have successfully retrieved at least one item
function retrieveItemsBlackList(item_list, count, peri)
    assert(type(item_list) == "table")
    assert(count > 0)
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print(("Unable to retrieve %s"):format(target_item_name))
        return false
    end

    local total_pulled = 0
    for slot, item in pairs(network_inventory.list()) do
        local valid_block = true
        for i, val in ipairs(item_list) do
            if(val == item.name) then
                valid_block = false
                break
            end
        end
        if(valid_block) then
            local num_pulled = network_inventory.pushItems(turtleName, slot, count)
            count = count - num_pulled
            total_pulled = total_pulled + num_pulled
        end
    end
    if(total_pulled > 0) then
        print(("Retrieved %d from network inventory"):format(total_pulled))
    end
    if(total_pulled == 0) then
        error("Error - Did not retrieve any items not in list")
    end
    return total_pulled
end
M.retrieveItemsBlackList = retrieveItemsBlackList


-- Retrieve specific item from network inventory
-- @param item_list This table is a list of the items retrieve from
-- @param count (Optional) Number - how many items we're attempting to get
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "back"
-- @return Boolean specifying if we have successfully retrieved at least one item
function retrieveItemsWhiteList(item_list, count, peri)
    assert(type(item_list) == "table")
    assert(count > 0)
    U.any_tostring(item_list)
    if(not connected_to_inventory and not connectToInventory(peri)) then
        print("Not connected to network")
        print(("Unable to retrieve %s"):format(target_item_name))
        return false
    end

    local total_pulled = 0
    for slot, item in pairs(network_inventory.list()) do
        local valid_block = false
        for i, val in ipairs(item_list) do
            if(val == item.name) then
                valid_block = true
                break
            end
        end
        if(valid_block) then
            local num_pulled = network_inventory.pushItems(turtleName, slot, count)
            count = count - num_pulled
            total_pulled = total_pulled + num_pulled
        end
    end
    if(total_pulled > 0) then
        print(("Retrieved %d from network inventory"):format(total_pulled))
    end
    if(total_pulled == 0) then
        error("Error - Did not retrieve any items from list")
    end
    return total_pulled
end
M.retrieveItemsWhiteList = retrieveItemsWhiteList


-- Deposit all items of a specified name into network inventory
-- @param target_item_name This string is the name of the item to deposit
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "back"
-- @return Boolean specifying if we have successfully deposited all of the specified items
function depositAllOfType(target_item_name, peri)
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
function depositAll(peri)
    return depositAllBlacklist({}, peri)
end
M.depositAll = depositAll


-- Refuel the turtle using available fuel in its inventory
-- @param minimum_fuel_level This number is the fuel level at which to stop refueling
function refuel(minimum_fuel_level)
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
-- @param minimum_fuel_level (Optional) This number is the fuel level at which to stop refueling
-- @param peri (Optional) This string is the name of the peripheral to wrap (E.g. front, top, back). Defaults to "back"
-- @return Boolean specifying if the turtle has refueled past the minimum level
function retrieveFuel(minimum_fuel_level, peri)
    minimum_fuel_level = minimum_fuel_level or 1
    print("Retrieving fuel")
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
        for i, val in ipairs(M.VALID_FUEL) do
            if(val == item.name) then
                if(turtle.getFuelLevel() >= minimum_fuel_level*10) then
                    print("Max fuel")
                    max_fuel_flag = true
                    depositAllOfType(M.EMPTY_BUCKET)
                    break
                end
                num_pulled = network_inventory.pushItems(turtleName, slot)
                print(("Retrieved %d %s"):format(num_pulled, item.name))
                refuel()
                depositAllOfType(M.EMPTY_BUCKET)
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
function selectedSlotHasThisItem(target_item_name, slot)
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
function selectedSlotHasItemInThisList(target_item_list, slot)
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
function getNumOfThisItemInInventory(target_item_name)
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
        if(selectedSlotHasItemInThisList(target_item_list)) then
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
        if(not selectedSlotHasItemInThisList(target_item_list)) then
            return true
        end
    end
    return false
end
M.turtleHasItemNotInList = turtleHasItemNotInList


-- Check if the slot has a chunk loader
-- @param slot (Optional) This number refers to the slot we are looking at
-- @return Boolean specifying if there is a chunk loader in this slot
function isChunkLoader(slot)
    return selectedSlotHasItemInThisList(M.CHUNK_LOADERS, slot)
end
M.isChunkLoader = isChunkLoader


-- Get the name of a block above, in front of, or below the turtle
-- @param String direction - "up", "front", or "down"
-- @return String - the name of the block
function getSideBlockName(direction)
    local block_exists = nil
    local block_details = nil

    if(direction == "up") then
        block_exists, block_details = turtle.inspectUp()
    elseif(direction == "front") then
        block_exists, block_details = turtle.inspect()
    elseif(direction == "down") then
        block_exists, block_details = turtle.inspectDown()
    else
        error("Invalid direction for block inspection")
    end

    if(block_exists) then
        return block_details.name
    end
    return nil
end
M.getSideBlockName = getSideBlockName


-- Make sure there is 2 chunk loaders in inventory, or 1 placed and one in inventory
-- @param String peri (Optional) - The name of the peripheral to wrap (E.g. front, top, back)
-- @return Boolean specifying if there is a chunk loader in this slot
function getChunkLoaderIfNotInInventory(peri)
    local total = 0
    if(chunk_loader_offset ~= nil) then
        total = 1
    elseif(U.listContains(U.getTableKeys(M.CHUNK_LOADERS), getSideBlockName("up"))) then
        total = 1
        chunk_loader_offset = turtle_offset:add(vector.new(0,1,0))
    end

    total = total + getNumOfThisItemInInventory(chunk_loader_type)

    if(total < 2) then
        print("Getting chunk loaders from network inventory")
        total = total + retrieveItemsWhiteList(U.getTableKeys(M.CHUNK_LOADERS), 2, peri)
    end

    return total > 1
end
M.getChunkLoaderIfNotInInventory = getChunkLoaderIfNotInInventory


-- Place a specific item in a specific direction
-- @param direction This string is the name of the direction to place in ("forward", "up", or "down")
-- @param slot (Optional) This number is the slot with the item we are attempting to place (Defaults to selected)
-- @param can_dig (Optional) This boolean specifies if we can dig the current block that is present (Defaults to false)
-- @return Boolean specifying if we have successfully placed the item
function placeItem(direction, slot, can_dig)
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
M.placeItem = placeItem


-- Place a specific item in a specific direction
-- @param target_item_name This string is the name of the item to place
-- @param direction - String - See function placeItem
-- @param can_dig (Optional) This boolean specifies if we can dig the current block that is present (Defaults to false)
-- @return Boolean specifying if we have successfully placed the item
function placeItemOfType(target_item_name, direction, can_dig)
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

    if(not turtle.back()) then
        return false
    else
        turtle_offset = new_offset
        disconnectFromInventory()
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

    if(not turtle.forward()) then
        return false
    else
        turtle_offset = new_offset
        disconnectFromInventory()
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

    if(not turtle.up()) then
        return false
    else
        turtle_offset = new_offset
        disconnectFromInventory()
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

    if(not turtle.down()) then
        return false
    else
        turtle_offset = new_offset
        disconnectFromInventory()
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


-- Place a chunk loader up
-- @param direction - String - (Optional - defaults to "up") See function placeItem
-- @return Boolean specifying if we have successfully placed the chunk loader
function placeChunkLoader(direction)
    direction = direction or "up"
    if(placeItemOfType(chunk_loader_type, direction, true)) then
        if(direction == "forward") then
            chunk_loader_offset = turtle_offset:add(vector.new(0, 0, 1))
        elseif(direction == "up") then
            chunk_loader_offset = turtle_offset:add(vector.new(0, 1, 0))
        elseif(direction == "down") then
            chunk_loader_offset = turtle_offset:add(vector.new(0, -1, 0))
        end
        return true
    else
        return false
    end
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

    return getNumOfThisItemInInventory(chunk_loader_type) > 0
end
M.retrieveLastChunkLoader = retrieveLastChunkLoader


-- Place a new chunk loader, retrieve the previous, and return to the current position
-- @param new_offset (Optional - defaults to current_offset) This vector offset the turtle wants to move to
-- @param Boolean check_separation - (Optional - defaults to false) If true, 
--  only replace chunk loader if separation threshold is met
-- @param direction - (Optional) See function placeChunkLoader
-- if we are about to exceed its maximum range
-- @return Boolean specifying if we have succeeded
function replaceChunkLoader(new_offset, check_separation, direction)
    check_separation = check_separation or false
    direction = direction or M.CHUNK_LOADER_DEFAULT_DIRECTION
    if(M.AUTO_LOAD_CHUNKS) then
        local separation = vector.new(0,0,0)
        if(chunk_loader_offset ~= nil) then
            separation = new_offset:sub(chunk_loader_offset)
        end
        local chunk_loader_range = M.CHUNK_LOADERS[chunk_loader_type]
        if(separation:length() > chunk_loader_range - 1 or not check_separation) then
            local old_chunk_loader_offset = chunk_loader_offset
            if(placeChunkLoader(direction)) then
                print("Placed chunk loader")
            else
                print("Failed to place chunk loader")
                return false
            end
            if(old_chunk_loader_offset ~= nil and chunk_loader_offset ~= old_chunk_loader_offset) then
                if(not retrieveLastChunkLoader(old_chunk_loader_offset)) then
                    print("Failed to retrieve previous chunk loader")
                    return false
                end
            end
        end
    end
    return true
end
M.replaceChunkLoader = replaceChunkLoader


-- @param Vector movement_order (Optional) - see goToOffset()
-- @param minimum_fuel_level (Optional) This number is the fuel level at which to stop refueling
-- @return Boolean specifying if we have succeeded
function resetState(movement_order, minimum_fuel_level)
    goToOffset(vector.new(0,0,0), movement_order)
    turnToFace(2)
    local success = depositAllBlacklist(M.CHUNK_LOADERS, "front") and retrieveFuel(minimum_fuel_level, "front")
    
    if(M.AUTO_LOAD_CHUNKS) then
        success = success and getChunkLoaderIfNotInInventory("front")
        if(chunk_loader_offset == nil or not chunk_loader_offset:equals(M.ORIGIN_OFFSET)) then
            success = success and replaceChunkLoader(M.ORIGIN_OFFSET)
        end
    end

    turnToFace(0)

    return success

end
M.resetState = resetState


return M
