local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local events = require('events')
local util = require('utilities')
local lowestStat = 0
local lowestStatSlot = 0
local targetCrop 

-- =================== MINOR FUNCTIONS ======================

local function updateLowest()
    local farm = database.getFarm()
    lowestStat = 99
    lowestStatSlot = 0

    -- Find lowest stat slot
    for slot=1, config.workingFarmArea, 2 do
        local crop = farm[slot]
        if crop.isCrop then

            if crop.name == 'air' or crop.name == 'emptyCrop' then
                lowestStat = 0
                lowestStatSlot = slot
                break

            elseif crop.name ~= targetCrop then
                local stat = crop.gr + crop.ga - crop.re - 2
                if stat < lowestStat then
                    lowestStat = stat
                    lowestStatSlot = slot
                end

            else
                local stat = crop.gr + crop.ga - crop.re
                if stat < lowestStat then
                    lowestStat = stat
                    lowestStatSlot = slot
                end
            end
        end
    end
end


local function checkChild(slot, crop, firstRun)
    if crop.isCrop and crop.name ~= 'emptyCrop' then

        if crop.name == 'air' then
            action.placeCropStick(2)

        elseif scanner.isWeed(crop, 'working') then
            action.deweed()
            action.placeCropStick()

        elseif firstRun then
            return

        elseif crop.name == targetCrop then
            local stat = crop.gr + crop.ga - crop.re

            if stat > lowestStat then
                action.transplant(gps.workingSlotToPos(slot), gps.workingSlotToPos(lowestStatSlot))
                action.placeCropStick(2)
                database.updateFarm(lowestStatSlot, crop)
                updateLowest()

            else
                action.deweed()
                action.placeCropStick()
            end

        elseif config.keepMutations and (not database.existInStorage(crop)) then
            action.transplant(gps.workingSlotToPos(slot), gps.storageSlotToPos(database.nextStorageSlot()))
            action.placeCropStick(2)
            database.addToStorage(crop)
            
        else
            action.deweed()
            action.placeCropStick()
        end
    end
end


local function checkParent(slot, crop, firstRun)
    if crop.isCrop and crop.name ~= 'air' and crop.name ~= 'emptyCrop' then
        if scanner.isWeed(crop, 'working') then
            action.deweed()
            database.updateFarm(slot, {isCrop=true, name='emptyCrop'})
            if not firstRun then
                updateLowest()
            end
        end
    end
end

-- ====================== THE LOOP ======================

local function statOnce(firstRun)
    for slot=1, config.workingFarmArea, 1 do

        -- Terminal Condition
        if #database.getStorage() >= config.storageFarmArea then
            print('autoStat: Storage Full!')
            return false
        end

        -- Terminal Condition
        if lowestStat >= config.autoStatThreshold then
            print('autoStat: Minimum Stat Threshold Reached!')
            return false
        end

        -- Terminal Condition
        if events.needExit() then
            print('autoStat: Received Exit Command!')
            return false
        end

        os.sleep(0)

        -- Scan
        gps.go(gps.workingSlotToPos(slot))
        local crop = scanner.scan()

        if firstRun then
            database.updateFarm(slot, crop)
            if slot == 1 then
                targetCrop = database.getFarm()[1].name
                print(string.format('autoStat: Target %s', targetCrop))
            end
        end

        if slot % 2 == 0 then
            checkChild(slot, crop, firstRun)
        else
            checkParent(slot, crop, firstRun)
        end

        if action.needCharge() then
            action.charge()
        end
    end
    return true
end

-- ======================== MAIN ========================
local function main()
    if arg[0] == true then 
        config.keepMutations = true
        print('autoStat: Mutations will be saved')

        defer(function()
            config.keepMutations = false
            print('autoStat: Resetting keepMutations value to false')
        end
        )
    end

    action.initWork()
    print('autoStat: Scanning Farm')

    -- First Run
    statOnce(true)
    action.restockAll()
    updateLowest()

    -- Loop
    while statOnce(false) do
        action.restockAll()
    end

    -- Terminated Early
    if events.needExit() then
        action.restockAll()
    end

    -- Finish
    if config.cleanUp then
        action.cleanUp()
    end

    events.unhookEvents()
    print('autoStat: Complete!')
end

main()