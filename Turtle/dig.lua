local TU = require "turtle_utilities"
local U = require "utilities"

INVALID_BLOCKS = {'minecraft:gravel', 'minecraft:sand', 'minecraft:charcoal', 'minecraft:anvil',
'minecraft:chipped_anvil', 'minecraft:damaged_anvil', 'minecraft:red_sand', 'minecraft:bucket',
'chunkloaders:basic_chunk_loader', 'minecraft:lava_bucket'}

current_length = 0
minimum_fuel_level = 0
reset = false
size = 0
--local w_modem = peripheral.wrap("right") or error("No modem attached", 0)


-- Check if the slot has a block we should not place
-- @param slot (Optional) This number refers to the slot we are looking at
-- @return Boolean true if the block in the specified slot is valid
function isNotInvalidBlock(slot)
    return not TU.selectedSlotHasItemInThisList(INVALID_BLOCKS, slot)
end


-- Check if the turtle has a valid block
-- @return Boolean true if a valid block exists in the turtle inventory
function validBlockExists()
    return TU.turtleHasItemNotInList(INVALID_BLOCKS)
end


-- Place a bridge block down if necessary
-- @return Boolean true if a block exists below the turtle
function placeValidBridgeBlockDown()
    if(turtle.detectDown()) then
        return true
    end
    if(isNotInvalidBlock()) then
        return TU.placeItem("down", nil, false)
    end
    for i=1,16 do
        if(isNotInvalidBlock(i)) then
            return TU.placeItem("down", i, false)
        end
    end

    print("Unable to place block")

    return false
end


-- Dig one square of the tunnel
-- @param size This number is the width of the tunnel square
-- @param build_bridge Boolean true means we place down bridge blocks as we dig
-- @return Boolean specifying if we have successfully dug a square
function digTunnelSquare(size, build_bridge)
    U.moveCursorToBeginningOfLine()
    term.write(("Building row %d\n"):format(current_length + 1))
    if(size <=0) then
        print("Tunnel size cannot be 0 or negative")
        return false
    elseif(size == 1) then
        TU.moveForward()
        if(build_bridge) then
            placeValidBridgeBlockDown()
        end
    else
        current_line = 1
        -- Dig one square of dimensions (size x size)
        TU.moveForward()
        if(build_bridge) then
            placeValidBridgeBlockDown()
        end
        while(current_line <= size) do
            local start_from_left = false
            if(offset_from_origin_x == 0) then
                start_from_left = true
            end
            position = 1
            if(start_from_left) then
                TU.turn("R")
            else
                TU.turn("L")
            end

            while(position < size) do
                if(current_line < size) then
                    turtle.digUp()
                end
                TU.moveForward()
                if(current_line == 1 and build_bridge) then
                    placeValidBridgeBlockDown()
                end
                position = position + 1
            end
            if(current_line < size) then
                turtle.digUp()
            end


            if(start_from_left) then
                TU.turn("L")
            else
                TU.turn("R")
            end
            
            -- Move up a line or back to the bottom
            if(current_line < size - 1) then
                TU.moveUp()
                TU.moveUp()
                current_line = current_line + 2
            else
                while(current_line > 1) do
                    TU.moveDown()
                    current_line = current_line - 1
                end
                current_line = size + 1
            end 
        end
    end

    current_length = current_length + 1
    minimum_fuel_level = size*size + current_length
    if(TU.AUTO_LOAD_CHUNKS) then
        minimum_fuel_level = size*size + current_length*2
    end

    return true
end


-- Build row of the bridge with specified width over 1 block length
-- @param size This number is the width of the bridge
-- @return Boolean specifying if we have successfully built a row
function buildBridgeRow(size)
    U.moveCursorToBeginningOfLine()
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
            TU.moveForward()
            turtle.digUp()
            if(not placeValidBridgeBlockDown()) then
                return false
            end

            if(size == 1) then
                return true
            end

            if(i==1) then
                if(start_from_left) then
                    TU.turn("R")
                else
                    TU.turn("L")
                end
            end
        end

        if(start_from_left) then
            TU.turn("L")
        else
            TU.turn("R")
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


function retrieveBlocks()
    print("Retrieving blocks")
    TU.sleep(0.2)
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


-- Move the turtle down one spot
-- @param movement_order Vector - see TU.goToOffset
-- @return Boolean specifying if we have successfully moved
function returnToOrigin(movement_order)
    print("Returning to origin")
    return TU.goToOffset(vector.new(0,0,0), movement_order)
end


-- Move the turtle to the current end of the tunnel
-- @return Boolean specifying if we have successfully moved
function goToCurrentEndOfTunnel()
    print("Going to current tunnel end")
    return TU.goToOffset(vector.new(0, 0, current_length))
end


-- Return to program start state
-- @param bridge_flag Boolean - true if we are building a bridge
-- @return Boolean - true if we successfully reset
function resetState(bridge_flag)
    local success = nil
    TU.printFuelInfo()
    returnToOrigin()
    success = TU.depositAllBlacklist(TU.CHUNK_LOADERS) and TU.retrieveFuel(minimum_fuel_level)

    if(AUTO_LOAD_CHUNKS) then
        success = success and TU.getChunkLoaderIfNotInInventory()
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
    
    TU.turn("R")
    TU.turn("R")
    reset = true
    print(("Reset successful: %s"):format(tostring(success)))
    return success
end

-- Function will always run at program start
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
            if(turtle.getFuelLevel() > minimum_fuel_level and (bridge_flag or TU.emptySlotExists())) then
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
        TU.refuel()
    else
        print("Please enter valid command")
    end
end

main()
