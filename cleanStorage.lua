local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local events = require('events')
local emptySlot
local targetCrop
local storageEmpty = true

-- =================== MINOR FUNCTIONS ======================

local function scanStorage() 
    storageEmpty = true
    
    for slot=1, config.storageFarmArea, 1 do
        gps.go(gps.storageSlotToPos(slot))
        local crop = scanner.scan()
        if crop.isCrop and crop.name != 'emptyCrop' then
            database.addToStorage(crop)
            storageEmpty = false
        end
    end
end

-- ====================== THE LOOP ======================
local function cleanStorage() 
    for slot=1, config.storageFarmArea, 1 do
        gps.go(gps.storageSlotToPos(slot))
        if database.slotHasCrop(slot) then
            -- Pickup cropstick and crop and dump to storage chest 
            action.clearBlock() 
        end

        if action.needCharge() then
            action.charge()
        end
    end
end 

-- ======================== MAIN ========================

local function main()
    action.initWork()
    print('cleanStorage: Scanning Storage')

    -- Scan the storage
    scanStorage()
    action.dumpToStorageAndCharge()

    -- Loop
    while storageEmpty ~= true do
        cleanStorage()
        -- Scan storage again to see if work is done
        scanStorage()
        action.charge()
    end

    -- Terminated Early
    if events.needExit() then
        action.dumpToStorageAndCharge()
    end

    -- Finish
    if config.cleanUp then
        action.cleanUp()
    end

    events.unhookEvents()
    print('cleanStorage: Complete!')
end

main()