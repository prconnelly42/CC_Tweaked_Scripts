local TU = require "turtle_utilities"


VALID_FUEL = {'minecraft:coal', 'minecraft:charcoal', 'minecraft:coal_block', 'minecraft:lava_bucket'}
POLISHED_DEEPSLATE = 'minecraft:polished_deepslate'
DEEPSLATE_BRICKS = 'minecraft:deepslate_bricks'
VALID_BLOCKS = {POLISHED_DEEPSLATE, DEEPSLATE_BRICKS}
CHUNK_LOADER_3X3 = 'chunkloaders:basic_chunk_loader'
EMPTY_BUCKET = 'minecraft:bucket'
CHUNK_LOADERS = {'chunkloaders:basic_chunk_loader'}
AUTO_LOAD_CHUNKS = true
MOVES_TO_MAKE_A_LEVEL = 50
NUM_POLISHED_IN_ONE_LEVEL = 16
NUM_BRICKS_IN_ONE_LEVEL = 40

offset_from_origin_x = 0
offset_from_origin_z = 0
offset_from_origin_y = 0
facing_direction = 0
current_height = nil
minimum_fuel_level = 0
reset = false
chunk_loader_location_x = nil
chunk_loader_location_y = nil
chunk_loader_location_z = nil
chunk_loader_range = 16
local chunk_loader_already_placed = false

--Networked items
connected_to_network = false
modem = nil
turtleName = nil
chest = nil
chest_name = nil



function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do
      -- nothing
    end
end


function moveCursorToBeginningOfLine()
    term.clearLine()
    local cursor_x = nil
    local cursor_y = nil
    cursor_x, cursor_y = term.getCursorPos()
    term.setCursorPos(1, cursor_y)
end


function moveBackward()
    connected_to_network = false
    turtle.back()
    if(facing_direction == 0) then
        offset_from_origin_z = offset_from_origin_z - 1
    elseif(facing_direction == 1) then
        offset_from_origin_x = offset_from_origin_x - 1
    elseif(facing_direction == 2) then
        offset_from_origin_z = offset_from_origin_z + 1
    elseif(facing_direction == 3) then
        offset_from_origin_x = offset_from_origin_x + 1
    end
end


function digAndMoveForward()
    local new_offset_z = offset_from_origin_z
    local new_offset_x = offset_from_origin_x

    connected_to_network = false

    if(facing_direction == 0) then
        new_offset_z = offset_from_origin_z + 1
    elseif(facing_direction == 1) then
        new_offset_x = offset_from_origin_x + 1
    elseif(facing_direction == 2) then
        new_offset_z = offset_from_origin_z - 1
    elseif(facing_direction == 3) then
        new_offset_x = offset_from_origin_x - 1
    end

    --[[
    if(AUTO_LOAD_CHUNKS and chunk_loader_location_z ~= nil) then
        local separation_z = new_offset_z - chunk_loader_location_z
        if(math.abs(separation_z) > chunk_loader_range - 1) then
            local old_chunk_loader_location_x = chunk_loader_location_x
            local old_chunk_loader_location_y = chunk_loader_location_y
            local old_chunk_loader_location_z = chunk_loader_location_z
            placeChunkLoader()
            retrieveLastChunkLoader(old_chunk_loader_location_x, old_chunk_loader_location_y, old_chunk_loader_location_z)
        end
    end
    --]]

    while(not turtle.forward()) do
        turtle.dig()
    end

    offset_from_origin_z = new_offset_z
    offset_from_origin_x = new_offset_x
end


function digAndMoveUp()
    local new_offset_y = offset_from_origin_y + 1
    connected_to_network = false

    if(AUTO_LOAD_CHUNKS and chunk_loader_location_y ~= nil) then
        local separation_y = new_offset_y - chunk_loader_location_y
        if(math.abs(separation_y) > chunk_loader_range - 1) then
            local old_chunk_loader_location_x = chunk_loader_location_x
            local old_chunk_loader_location_y = chunk_loader_location_y
            local old_chunk_loader_location_z = chunk_loader_location_z
            placeChunkLoader()
            retrieveLastChunkLoader(old_chunk_loader_location_x, old_chunk_loader_location_y, old_chunk_loader_location_z)
        end
    end

    while(not turtle.up()) do
        turtle.digUp()
    end

    offset_from_origin_y = new_offset_y
end


function digAndMoveDown()
    local new_offset_y = offset_from_origin_y - 1
    connected_to_network = false

    if(AUTO_LOAD_CHUNKS and chunk_loader_location_y ~= nil) then
        local separation_y = new_offset_y - chunk_loader_location_y
        if(math.abs(separation_y) > chunk_loader_range - 1) then
            local old_chunk_loader_location_x = chunk_loader_location_x
            local old_chunk_loader_location_y = chunk_loader_location_y
            local old_chunk_loader_location_z = chunk_loader_location_z
            placeChunkLoader()
            retrieveLastChunkLoader(old_chunk_loader_location_x, old_chunk_loader_location_y, old_chunk_loader_location_z)
        end
    end

    while(not turtle.down()) do
        turtle.digDown()
    end

    offset_from_origin_y = new_offset_y
end


function updateDirection(direction)
    connected_to_network = false
    if(direction == "R") then
        turtle.turnRight()
        facing_direction = math.fmod(facing_direction + 1, 4)
    else
        turtle.turnLeft()
        facing_direction = math.fmod(facing_direction + 3, 4)
    end
end


function selectedSlotHasThisItem(target_item_name)
    item = turtle.getItemDetail()
    item_name = nil
    if(item ~= nil) then
        item_name = item.name
        return item_name == target_item_name
    else
        return false
    end
end


function selectedSlotHasItemInThisList(target_item_list)
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


function isChunkLoader()
    return selectedSlotHasItemInThisList(CHUNK_LOADERS)
end


function placeItemOfType(target_item_name, direction, dig_flag)
    for i=0,16 do
        if(i ~= 0) then
            turtle.select(i)
        end
        if(selectedSlotHasThisItem(target_item_name)) then
            if(direction == "forward") then
                if(dig_flag and turtle.detect()) then
                    turtle.dig()
                end
                return turtle.place()
            elseif(direction == "up") then
                if(dig_flag and turtle.detectUp()) then
                    turtle.digUp()
                end
                return turtle.placeUp()
            elseif(direction == "down") then
                if(dig_flag and turtle.detectDown()) then
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


function placeChunkLoader()
    local success = nil
    local old_offset_x = offset_from_origin_x
    local old_offset_z = offset_from_origin_z
    if(offset_from_origin_x ~= 0 or offset_from_origin_z ~= 0) then
        goToOffsetLocation(0, offset_from_origin_y, 0)
    end
    while(facing_direction ~= 2) do
        updateDirection("R")
    end
    local block_is_present, data = turtle.inspect()
    if(block_is_present and data.name == CHUNK_LOADER_3X3) then
        chunk_loader_already_placed = true
        success = true
    else
        chunk_loader_already_placed = false
        success = placeItemOfType(CHUNK_LOADER_3X3, 'forward', true)
    end

    if(success) then
        print("Chunk loader placed")
        chunk_loader_location_x = offset_from_origin_x
        chunk_loader_location_y = offset_from_origin_y
        chunk_loader_location_z = offset_from_origin_z - 1
    else
        print("Failed to place chunk loader")
    end
    goToOffsetLocation(old_offset_x, offset_from_origin_y, old_offset_z)
    while(facing_direction ~= 0) do
        updateDirection("R")
    end
    return success
end


function goForwardLRight()
    digAndMoveForward()
    updateDirection("R")
    digAndMoveForward()
end


function buildTowerLevel()
    moveCursorToBeginningOfLine()
    term.write(("Building level %d\n"):format(current_height))
    for rotation=1,4 do
        placeItemOfType(POLISHED_DEEPSLATE, "down", true)
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        goForwardLRight()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        updateDirection("L")
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        goForwardLRight()
        placeItemOfType(POLISHED_DEEPSLATE, "down", true)
        updateDirection("L")
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        digAndMoveForward()
        placeItemOfType(POLISHED_DEEPSLATE, "down", true)
        updateDirection("L")
        goForwardLRight()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        digAndMoveForward()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        updateDirection("L")
        goForwardLRight()
        placeItemOfType(DEEPSLATE_BRICKS, "down", true)
        digAndMoveForward()
        placeItemOfType(POLISHED_DEEPSLATE, "down", true)
        updateDirection("L")
        goForwardLRight()
        updateDirection("L")
    end

    current_height = current_height + 1
    
    if(AUTO_LOAD_CHUNKS) then
        minimum_fuel_level = MOVES_TO_MAKE_A_LEVEL + (current_height*4)
    else
        minimum_fuel_level = MOVES_TO_MAKE_A_LEVEL + (current_height*2)
    end

    return true
end


function printFuelInfo()
    print(("Current fuel: %s"):format(turtle.getFuelLevel()))
end


function connectToNetwork()
    while(facing_direction ~= 2) do
        updateDirection("R")
    end
    sleep(0.2)
    modem = peripheral.wrap("front")
    turtleName = modem.getNameLocal()
    chest = peripheral.find("inventory")
    if(modem == nil or turtleName == nil or chest == nil) then
        connected_to_network = false
        return false
    end
    chest_name = peripheral.getName(chest)
    connected_to_network = true
    return true
end


function depositAllOfType(target_item_name)
    connectToNetwork()
    if(not connected_to_network) then
        print("Not connected to network")
        print(("Unable to deposit %s"):format(target_item_name))
        return false
    end
    for slot=1,16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if(item ~= nil and (item.name == target_item_name or target_item_name == "ALL")) then
            chest.pullItems(turtleName, slot)
            if(turtle.getItemCount() > 0) then
                print(("Unable to deposit %s"):format(target_item_name))
                return false
            end
        end
    end
    return true
end


function depositAll()
    return depositAllOfType("ALL")
end


function refuel()
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


function retrieveChunkLoaders()
    print("Retrieving chunk loaders")
    connectToNetwork()
    if(not connected_to_network) then
        print("Not connected to network")
        print("Unable to retrieve chunk loaders")
        return false
    end
    local count = getNumOfThisItemInInventory(CHUNK_LOADER_3X3)
    local retrievedFlag = false
    -- Look at every item in the chest
    for slot, item in pairs(chest.list()) do
        -- Compare this item to every valid chunk loader
        for i, val in ipairs(CHUNK_LOADERS) do
            if(val == item.name) then
                num_pulled = chest.pushItems(turtleName, slot)
                count = count + num_pulled
                print(("Retrieved %d %s"):format(num_pulled, item.name))
                if(count > 1 or (count == 1 and chunk_loader_location_x ~= nil)) then
                    retrievedFlag = true
                    break
                end
            end
        end
        if(retrievedFlag) then
            break
        end
    end
    return retrievedFlag
end



function getChunkLoaderIfNotInInventory()
    local total = getNumOfThisItemInInventory(CHUNK_LOADER_3X3)
    if(total > 1 or (total == 1 and chunk_loader_location_x ~= nil)) then
        return true
    end
    return retrieveChunkLoaders()
end


function retrieveFuel()
    print("Retrieving fuel")
    connectToNetwork()
    if(not connected_to_network) then
        print("Not connected to network")
        print("Unable to retrieve fuel")
        return false
    end
    -- While we need more fuel
    local max_fuel_flag = false 
        -- Look at every item in the chest
    for slot, item in pairs(chest.list()) do
        -- Compare this item to every valid fuel
        for i, val in ipairs(VALID_FUEL) do
            if(val == item.name) then
                if(turtle.getFuelLevel() >= minimum_fuel_level*10) then
                    print("Max fuel")
                    max_fuel_flag = true
                    break
                end
                num_pulled = chest.pushItems(turtleName, slot)
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


function areEnoughBlocksForOneLevel()
    local total_polished = getNumOfThisItemInInventory(POLISHED_DEEPSLATE)
    local total_bricks = getNumOfThisItemInInventory(DEEPSLATE_BRICKS)
    if(total_polished > NUM_POLISHED_IN_ONE_LEVEL and total_bricks > NUM_BRICKS_IN_ONE_LEVEL) then
        return true
    else
        print("Not enough blocks for one level")
        return false
    end
end


function retrieveTowerBlocks()
    print("Retrieving blocks")
    connectToNetwork()
    if(not connected_to_network) then
        print("Not connected to network")
        print("Unable to retrieve tower blocks")
        return false
    end
    local total_polished = getNumOfThisItemInInventory(POLISHED_DEEPSLATE)
    local total_bricks = getNumOfThisItemInInventory(DEEPSLATE_BRICKS)
    local blocks_moved_flag = true

    -- We're looping through both inventories and checking the best blocks to take
    while blocks_moved_flag do
        blocks_moved_flag = false

        -- Look at every item in the chest
        for slot, item in pairs(chest.list()) do
            local brick_flag = true
            local valid_block = false
            local can_grab = false
            local num_pulled = 0
            -- Compare this item to every valid block
            for i, val in ipairs(VALID_BLOCKS) do
                if(val == item.name) then
                    valid_block = true
                    if(val == POLISHED_DEEPSLATE) then
                        brick_flag = false
                    end
                    break
                end
            end
            -- If it's one of our building blocks
            if(valid_block) then
                -- Check if our ratio is in favor of the bricks or polished blocks
                if(brick_flag and (total_bricks == 0 or total_polished/total_bricks >= 0.4)) then
                    can_grab = true
                elseif(not brick_flag and (total_polished/total_bricks <= 0.4)) then
                    can_grab = true
                end
                
                -- Grab the blocks if the ratio and flag are good
                if(can_grab) then
                    num_pulled = chest.pushItems(turtleName, slot)
                    if(brick_flag) then
                        total_bricks = total_bricks + num_pulled
                    else
                        total_polished = total_polished + num_pulled
                    end
                end
                if(num_pulled > 0) then
                    print(("Retrieved %d %s"):format(num_pulled, item.name))
                    blocks_moved_flag = true
                end
            end
        end
    end
    if(not areEnoughBlocksForOneLevel()) then
        print("Error - Not enough blocks to build")
        return false
    end
    return true
end


function goToOffsetLocation(x, y, z)
    while(offset_from_origin_x > x) do
        while(facing_direction ~= 3) do
            updateDirection("R")
        end
        digAndMoveForward()
    end
    while(offset_from_origin_x < x) do
        while(facing_direction ~= 1) do
            updateDirection("R")
        end
        digAndMoveForward()
    end
    while(offset_from_origin_z < z) do
        while(facing_direction ~= 0) do
            updateDirection("R")
        end
        digAndMoveForward()
    end
    while(offset_from_origin_z > z) do
        while(facing_direction ~= 2) do
            updateDirection("R")
        end
        digAndMoveForward()
    end
    while(offset_from_origin_y > y) do
        digAndMoveDown()
    end
    while(offset_from_origin_y < y) do
        digAndMoveUp()
    end
end


function retrieveLastChunkLoader(loader_offset_x, loader_offset_y, loader_offset_z)
    if(loader_offset_x == nil or loader_offset_y == nil or loader_offset_z == nil) then
        return false
    end
    local turtle_offset_x = offset_from_origin_x
    local turtle_offset_y = offset_from_origin_y
    local turtle_offset_z = offset_from_origin_z
    local turtle_current_direction = facing_direction
    local success = false
    print("Getting last chunk loader")
    -- Go to chunk loader location
    goToOffsetLocation(loader_offset_x, loader_offset_y, loader_offset_z + 1)
    while(facing_direction ~= 2) do
        updateDirection("R")
    end
    -- Pick up the chunk loader
    success = turtle.dig()
    print("last chunk loader retrieved")
    -- Return to last location (go to y first so we don't dig through the tower)
    goToOffsetLocation(loader_offset_x, turtle_offset_y, loader_offset_z + 1)
    goToOffsetLocation(turtle_offset_x, turtle_offset_y, turtle_offset_z)
    while(facing_direction ~= turtle_current_direction) do
        updateDirection("R")
    end
    return success
end


function resetState()
    local success = nil
    printFuelInfo()
    goToOffsetLocation(0,0,0)
    while(facing_direction ~= 2) do
        updateDirection("R")
    end

    local success_checks = {}

    success_checks['depositAll'] = depositAll()
    success_checks['retrieveFuel'] = retrieveFuel()
    if(AUTO_LOAD_CHUNKS) then
        local old_chunk_loader_location_x = chunk_loader_location_x
        local old_chunk_loader_location_y = chunk_loader_location_y
        local old_chunk_loader_location_z = chunk_loader_location_z
        success_checks['getChunkLoaderIfNotInInventory'] = getChunkLoaderIfNotInInventory()
        digAndMoveUp()
        while(facing_direction ~= 0) do
            updateDirection("R")
        end
        success_checks['placeChunkLoader'] = placeChunkLoader()
        digAndMoveDown()

        if(old_chunk_loader_location_x ~= nil and not chunk_loader_already_placed) then
            success_checks['retrieveLastChunkLoader'] = retrieveLastChunkLoader(old_chunk_loader_location_x, old_chunk_loader_location_y, old_chunk_loader_location_z)
        end
    end

    success_checks['retrieveTowerBlocks'] = retrieveTowerBlocks()
    
    while(facing_direction ~= 0) do
        updateDirection("R")
    end
    reset = true

    local failure_reason = ""
    local success_flag = true
    for key, val in pairs(success_checks) do
        if not (val == true) and not(key == 'getChunkLoaderIfNotInInventory' and chunk_loader_already_placed) then
            success_flag = false 
            failure_reason = key
            break
        end
    end
    if(success_flag) then
        print("Reset successful")
    else
        print(("Reset failed: %s"):format(failure_reason))
    end
    return success_flag
end


function main()
    local reset_success = true
    
    if(arg[1] ~= nil) then
        current_height = tonumber(arg[1])
    end

    if(AUTO_LOAD_CHUNKS) then
        if(current_height ~= nil) then
            minimum_fuel_level = current_height*4 + MOVES_TO_MAKE_A_LEVEL
        else
            minimum_fuel_level = 400*4 + MOVES_TO_MAKE_A_LEVEL
        end
    else
        if(current_height ~= nil) then
            minimum_fuel_level = current_height*2 + MOVES_TO_MAKE_A_LEVEL
        else
            minimum_fuel_level = 400*2 + MOVES_TO_MAKE_A_LEVEL
        end
    end

    if(current_height ~= nil and current_height < 20) then
        print("Warning! Below current build ceiling.")
        return false
    end

    reset_success = resetState()
    -- Build until we hit an error
    while (reset_success) do
        if(turtle.getFuelLevel() > minimum_fuel_level and areEnoughBlocksForOneLevel()) then
            if(current_height == nil) then
                current_height = 0
                while(turtle.detect()) do
                    goToOffsetLocation(offset_from_origin_x, current_height+1, offset_from_origin_z)
                    current_height = current_height + 1
                end
            end
            goToOffsetLocation(offset_from_origin_x, current_height+1, offset_from_origin_z)
            goToOffsetLocation(0, offset_from_origin_y, 1)
            while(facing_direction ~= 0) do
                updateDirection("L")
            end
            if(not buildTowerLevel()) then
                print("Error building")
                reset_success = resetState()
            end
        else
            reset_success = resetState()
        end
    end
    print("Program terminated")
end

main()
