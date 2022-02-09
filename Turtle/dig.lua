VALID_FUEL = {'minecraft:coal', 'minecraft:charcoal', 'minecraft:coal_block', 'minecraft:lava_bucket'}
INVALID_BLOCKS = {'minecraft:gravel', 'minecraft:sand', 'minecraft:charcoal', 'minecraft:anvil',
'minecraft:chipped_anvil', 'minecraft:damaged_anvil', 'minecraft:red_sand', 'minecraft:bucket',
'chunkloaders:basic_chunk_loader', 'minecraft:lava_bucket'}
CHUNK_LOADERS = {'chunkloaders:basic_chunk_loader'}
AUTO_LOAD_CHUNKS = true

offset_from_origin_x = 0
offset_from_origin_z = 0
offset_from_origin_y = 0
facing_direction = 0
current_length = 0
minimum_fuel_level = 0
reset = false
chunk_loader_location_x = 0
chunk_loader_location_z = 0
size = 0
chunk_loader_range = 16



function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do
      -- nothing
    end
end


function moveBackward()
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

    if(facing_direction == 0) then
        new_offset_z = offset_from_origin_z + 1
    elseif(facing_direction == 1) then
        new_offset_x = offset_from_origin_x + 1
    elseif(facing_direction == 2) then
        new_offset_z = offset_from_origin_z - 1
    elseif(facing_direction == 3) then
        new_offset_x = offset_from_origin_x - 1
    end

    if(AUTO_LOAD_CHUNKS) then
        local separation_z = new_offset_z - chunk_loader_location_z
        if(math.abs(separation_z) > chunk_loader_range - 1) then
            local old_chunk_loader_location_x = chunk_loader_location_x
            local old_chunk_loader_location_z = chunk_loader_location_z
            if(placeChunkLoader()) then
                print("chunk loader place")
            end
            retrieveLastChunkLoader(old_chunk_loader_location_x, old_chunk_loader_location_z)
        end
    end

    while(not turtle.forward()) do
        turtle.dig()
    end

    offset_from_origin_z = new_offset_z
    offset_from_origin_x = new_offset_x
end


function digAndMoveUp()
    while(not turtle.up()) do
        turtle.digUp()
    end
    offset_from_origin_y = offset_from_origin_y + 1
end


function digAndMoveDown()
    while(not turtle.down()) do
        turtle.digDown()
    end
    offset_from_origin_y = offset_from_origin_y - 1
end


function updateDirection(direction)
    if(direction == "R") then
        turtle.turnRight()
        facing_direction = math.fmod(facing_direction + 1, 4)
    else
        turtle.turnLeft()
        facing_direction = math.fmod(facing_direction + 3, 4)
    end
end


function isNotFallingBlock()
    item = turtle.getItemDetail()
    item_name = nil
    if(item ~= nil) then
        item_name = item.name
    else
        return false
    end
    for i, val in ipairs(INVALID_BLOCKS) do
        if(val == item_name) then
            return false
        end
    end
    return true
end


function isChunkLoader()
    item = turtle.getItemDetail()
    item_name = nil
    if(item == nil) then
        return false
    else
        item_name = item.name
    end
    for i, val in ipairs(CHUNK_LOADERS) do
        if(val == item_name) then
            return true
        end
    end
    return false
end


function validBlockExists()
    for i=1,16 do
        turtle.select(i)
        if(isNotFallingBlock() and not isChunkLoader()) then
            return true
        end
    end
    return false
end


function isInventoryEmpty()
    for i=1,16 do
        turtle.select(i)
        if(turtle.getItemCount() ~= 0) then
            return false
        end
    end
    return true
end


function placeBlockDown()
    if(turtle.detectDown()) then
        return true
    end
    if(isNotFallingBlock() and not isChunkLoader() and turtle.placeDown()) then
        return true
    end
    for i=1,16 do
        turtle.select(i)
        if(isNotFallingBlock() and not isChunkLoader() and turtle.placeDown()) then
            return true
        end
    end

    print("Unable to place block")

    return false
end


function placeChunkLoader()
    local success = false
    for i=1,16 do
        turtle.select(i)
        if(isChunkLoader() and turtle.placeUp()) then
            success = true
            chunk_loader_location_z = offset_from_origin_z
            chunk_loader_location_x = offset_from_origin_x
            break
        end
    end

    return success
end


function digTunnelSquare(size, build_bridge)
    moveCursorToBeginningOfLine()
    term.write(("Building row %d\n"):format(current_length + 1))
    if(size <=0) then
        print("Tunnel size cannot be 0 or negative")
        return false
    elseif(size == 1) then
        digAndMoveForward()
        if(build_bridge) then
            placeBlockDown()
        end
    else
        current_line = 1
        -- Dig one square of dimensions (size x size)
        digAndMoveForward()
        if(build_bridge) then
            placeBlockDown()
        end
        while(current_line <= size) do
            local start_from_left = false
            if(offset_from_origin_x == 0) then
                start_from_left = true
            end
            position = 1
            if(start_from_left) then
                updateDirection("R")
            else
                updateDirection("L")
            end

            while(position < size) do
                if(current_line < size) then
                    turtle.digUp()
                end
                digAndMoveForward()
                if(current_line == 1 and build_bridge) then
                    placeBlockDown()
                end
                position = position + 1
            end
            if(current_line < size) then
                turtle.digUp()
            end


            if(start_from_left) then
                updateDirection("L")
            else
                updateDirection("R")
            end
            
            -- Move up a line or back to the bottom
            if(current_line < size - 1) then
                digAndMoveUp()
                digAndMoveUp()
                current_line = current_line + 2
            else
                while(current_line > 1) do
                    digAndMoveDown()
                    current_line = current_line - 1
                end
                current_line = size + 1
            end 
        end
    end

    current_length = current_length + 1
    minimum_fuel_level = size*size + current_length
    if(AUTO_LOAD_CHUNKS) then
        minimum_fuel_level = size*size + current_length*2
    end

    return true
end


function moveCursorToBeginningOfLine()
    term.clearLine()
    local cursor_x = nil
    local cursor_y = nil
    cursor_x, cursor_y = term.getCursorPos()
    term.setCursorPos(1, cursor_y)
end


function buildBridgeRow(size)
    moveCursorToBeginningOfLine()
    term.write(("Building row %d\n"):format(current_length + 1))
    if(size <=0) then
        print("Bridge size cannot be 0 or negative")
        return false
    else
        local start_from_left = false
        if(offset_from_origin_x == 0) then
            start_from_left = true
        end

        for i=1,size do
            digAndMoveForward()
            turtle.digUp()
            if(not placeBlockDown()) then
                return false
            end

            if(size == 1) then
                return true
            end

            if(i==1) then
                if(start_from_left) then
                    updateDirection("R")
                else
                    updateDirection("L")
                end
            end
        end

        if(start_from_left) then
            updateDirection("L")
        else
            updateDirection("R")
        end
    end

    current_length = current_length + 1
    
    if(AUTO_LOAD_CHUNKS) then
        minimum_fuel_level = size + (size + current_length)*3
    else
        minimum_fuel_level = size + current_length
    end

    return true
end


function printFuelInfo()
    term.write("Current fuel: ")
    term.write(turtle.getFuelLevel())
    print()
end


function depositBucket()
    local modem = peripheral.wrap("front")
    local turtleName = modem.getNameLocal()
    local chest = peripheral.find("inventory")
    local chest_name = peripheral.getName(chest)
    for slot=1,16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if(item ~= nil and item.name == "minecraft:bucket") then
            chest.pullItems(turtleName, slot)
        end
    end
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
    sleep(0.2)
    local modem = peripheral.wrap("front")
    local turtleName = modem.getNameLocal()
    local chest = peripheral.find("inventory")
    local chest_name = peripheral.getName(chest)
    -- While we need more fuel
    local count = 0 
    local retrievedFlag = false
    -- Look at every item in the chest
    for slot, item in pairs(chest.list()) do
        -- Compare this item to every valid chunk loader
        for i, val in ipairs(CHUNK_LOADERS) do
            if(val == item.name) then
                num_pulled = chest.pushItems(turtleName, slot)
                count = count + num_pulled
                print(("Retrieved %d %s from chest"):format(num_pulled, item.name))
                if(count > 1) then
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
    local total = 0
    for i=1,16 do
        turtle.select(i)
        local count = turtle.getItemCount()
        if(isChunkLoader() and count > 0) then
            total = total + count
            if(total > 1 or (total == 1 and chunk_loader_location_x ~= nil)) then
                return true
            end
        end
    end
    return retrieveChunkLoaders()
end


function retrieveFuel()
    print("Retrieving fuel")
    sleep(0.2)
    local modem = peripheral.wrap("front")
    local turtleName = modem.getNameLocal()
    local chest = peripheral.find("inventory")
    local chest_name = peripheral.getName(chest)
    -- While we need more fuel
    local max_fuel_flag = false 
        -- Look at every item in the chest
    for slot, item in pairs(chest.list()) do
        -- Compare this item to every valid fuel
        for i, val in ipairs(VALID_FUEL) do
            if(val == item.name) then
                if(turtle.getFuelLevel() >= minimum_fuel_level*10) then
                    max_fuel_flag = true
                    depositBucket()
                    break
                end
                num_pulled = chest.pushItems(turtleName, slot)
                print(("Retrieved %d %s from chest"):format(num_pulled, item.name))
                refuel()
                depositBucket()
                break
            end
        end
        if(max_fuel_flag) then
            break
        end
    end
    return turtle.getFuelLevel() >= minimum_fuel_level
end


function retrieveBlocks()
    print("Retrieving blocks")
    sleep(0.2)
    local modem = peripheral.wrap("front")
    local turtleName = modem.getNameLocal()
    local chest = peripheral.find("inventory")
    local chest_name = peripheral.getName(chest)
    total_pulled = 0
    -- Look at every item in the chest
    for slot, item in pairs(chest.list()) do
        local valid_block = true
        -- Compare this item to every valid fuel and invalid block
        for i, val in ipairs(VALID_FUEL) do
            if(val == item.name) then
                valid_block = false
                break
            end
        end
        for i, val in ipairs(INVALID_BLOCKS) do
            if(val == item.name) then
                valid_block = false
                break
            end
        end
        if(valid_block) then
            num_pulled = chest.pushItems(turtleName, slot)
            total_pulled = total_pulled + num_pulled
            if(num_pulled > 0) then
                print(("Retrieved %d %s from chest"):format(num_pulled, item.name))
            end
        end
    end
    if(total_pulled == 0) then
        print("Error - Did not retrieve any blocks")
        return false
    end
    return true
end


function emptySlotExists()
    for i=1,16 do
        if(turtle.getItemCount(i) == 0) then
            return true
        end
    end
    print("No empty slots")
    return false
end


function returnToOrigin()
    print("Returning to origin")
    while(offset_from_origin_y > 0) do
        digAndMoveDown()
    end

    while(facing_direction ~= 3) do
        updateDirection("R")
    end
    while(offset_from_origin_x > 0) do
        digAndMoveForward()
    end

    while(facing_direction ~= 2) do
        updateDirection("L")
    end
    while(offset_from_origin_z > 0) do
        digAndMoveForward()
    end
end


function goToCurrentEndOfTunnel()
    print("Going to current tunnel end")
    while(facing_direction ~= 0) do
        updateDirection("R")
    end
    while(offset_from_origin_z < current_length) do
        digAndMoveForward()
    end
end


function goToOffsetLocation(x, y, z)
    while(offset_from_origin_y > y) do
        digAndMoveDown()
    end
    while(offset_from_origin_y < y) do
        digAndMoveUp()
    end
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
end


function retrieveLastChunkLoader(loader_offset_x, loader_offset_z)
    if(loader_offset_x == nil or loader_offset_z == nil) then
        return false
    end
    local turtle_offset_x = offset_from_origin_x
    local turtle_offset_z = offset_from_origin_z
    local turtle_current_direction = facing_direction
    print("Getting last chunk loader")
    -- Go to chunk loader location
    goToOffsetLocation(loader_offset_x, 0, loader_offset_z)
    -- Pick up the chunk loader
    turtle.digUp()
    print("last chunk loader retrieved")
    -- Return to last location
    -- last location is to the left
    goToOffsetLocation(turtle_offset_x, 0, turtle_offset_z)
    while(facing_direction ~= turtle_current_direction) do
        updateDirection("R")
    end
end


function depositInventory()
    print("Depositing Inventory")
    sleep(0.2)
    local modem = peripheral.wrap("front")
    local turtleName = modem.getNameLocal()
    local chest = peripheral.find("inventory")
    local chest_name = peripheral.getName(chest)
    for slot=1,16 do
        turtle.select(slot)
        if(not isChunkLoader()) then
            num_moved = chest.pullItems(turtleName, slot)
            if(turtle.getItemCount() > 0 and num_moved == 0) then
                print("Error - Unable to deposit blocks")
                return false
            end
        end
    end
    return true
end


function resetState(bridge_flag)
    local success = nil
    printFuelInfo()
    returnToOrigin()
    success = depositInventory() and retrieveFuel()

    if(AUTO_LOAD_CHUNKS) then
        success = success and getChunkLoaderIfNotInInventory()
        local old_chunk_loader_location_x = chunk_loader_location_x
        local old_chunk_loader_location_z = chunk_loader_location_z
        if(placeChunkLoader()) then
            print("chunk loader place")
        end
        retrieveLastChunkLoader(old_chunk_loader_location_x, old_chunk_loader_location_z)
    end

    if(bridge_flag) then
        success = success and (retrieveBlocks() or validBlockExists())
    end
    
    updateDirection("R")
    updateDirection("R")
    reset = true
    print(("Reset successful: %s"):format(tostring(success)))
    return success
end


function main()
    if(arg[1] == "tunnel" or arg[1] == "tunnelbridge" or arg[1] == "bridge") then
        tunnelbridge = false
        bridge_flag = false
        local reset_success = true
        if(arg[1] == "tunnelbridge" or arg[1] == "bridge") then
            tunnelbridge = true
            if(arg[1] == "bridge") then
                bridge_flag = true
            end
        end
        size = tonumber(arg[2])
        if(arg[3] == nil) then
            target_length = 100000000
        else
            target_length = tonumber(arg[3])
        end

        if(arg[4] ~= nil) then
            current_length = tonumber(arg[4])
        end
        if(AUTO_LOAD_CHUNKS) then
            minimum_fuel_level = current_length*4 + size*size
        else
            minimum_fuel_level = current_length*2 + size*size
        end
        resetState(bridge_flag)
        while (current_length < target_length) do
            if(turtle.getFuelLevel() > minimum_fuel_level and (bridge_flag or emptySlotExists())) then
                if(reset) then
                    goToCurrentEndOfTunnel()
                    reset = false
                end
                dig_success = false
                if(bridge_flag) then
                    dig_success = buildBridgeRow(size)
                else
                    dig_success = digTunnelSquare(size, tunnelbridge)
                end
                if(not dig_success) then
                    print("Error digging/building")
                    reset_success = resetState(bridge_flag)
                end
            elseif(not reset) then
                reset_success = resetState(bridge_flag)
            else
                break
            end
            
            if(not reset_success) then
                break
            end
        end
        print("Program terminated - Resetting")
        resetState(false)
    elseif(arg[1] == "refuel") then
        refuel()
    else
        print("Please enter valid command")
    end
end

main()
