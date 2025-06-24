local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local events = require('events')
local emptySlot
local targetCrop

-- ====================== THE LOOP ======================
local function cleanStorage() 
    for slot=1, config.storageFarmArea, 1 do
        gps.go(gps.storageSlotToPos(slot))
        
        if database.slotHasCrop(slot) then
            -- Pickup cropstick and crop and dump to storage chest 
            action.clearBlock() 
        end

        if action.halfCharge() then
            action.charge()
        end

        if action.fullInventory() then 
            action.dumpToStorageAndCharge()
        end
    end

    database.resetStorage()
end 

local function cleanFarm()
    for slot=1, config.workingFarmArea, 1 do
        gps.go(gps.workingSlotToPos(slot))
    
        if database.farmHasCrop(slot) then
            -- Pickup cropstick and crop and dump to storage chest 
            action.clearBlock() 
        end
    
        if action.halfCharge() then
            action.charge()
        end

        if action.fullInventory() then 
            action.dumpToStorageAndCharge()
        end
    end
end



-- ======================== MAIN ========================

local function main()
    action.initWork()
    database.resetStorage()
    database.resetFarm()
    print('cleanStorage: Scanning Storage')

    -- Scan the storage
    database.scanStorage()
    action.dumpToStorageAndCharge()
    
    -- Clean the storage
    cleanStorage()
    action.dumpToStorageAndCharge()

    -- Scan the farm
    database.scanFarm()
    action.dumpToStorageAndCharge()

    -- Clean the farm
    cleanFarm()
    action.dumpToStorageAndCharge()

    -- Terminated Early
    if events.needExit() then
        action.dumpToStorageAndCharge()
        action.restockAll()
    end

    -- Finish
    if config.cleanUp then
        action.cleanUp()
    end

    events.unhookEvents()
    print('cleanStorage: Complete!')
end

main()