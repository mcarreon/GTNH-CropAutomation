local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local targetCrop

local function checkChild(slot, crop)
    if crop.isCrop and crop.name ~= 'emptyCrop' then

        -- place crop sticks in air
        if crop.name == 'air' then
            action.placeCropStick(2)

        -- deweed in case of weeds
        elseif scanner.isWeed(crop, 'working') then
            action.deweed()
            action.placeCropStick()

        -- remove if crop is same as targetCrop
        elseif crop.name == targetCrop then
            action.deweed()
            action.placeCropStick()

        -- if it exists in storage, remove it
        elseif database.existInStorage(crop) then
            action.deweed()
            action.placeCropStick()
            
        -- if its a new crop, place it in storage and save it
        else
            action.transplant(gps.workingSlotToPos(slot), gps.storageSlotToPos(database.nextStorageSlot()))
            action.placeCropStick(2)
            database.addToStorage(crop)
        end
    end
end

local function checkParent(slot, crop)
    if crop.isCrop and crop.name ~= 'air' and crop.name ~= 'emptyCrop' then
        if scanner.isWeed(crop, 'working') then
            action.deweed()
            database.updateFarm(slot, {isCrop=true, name='emptyCrop'})
        end
    end
end


-- ====================== THE LOOP ======================

local function maintainAndBreedOnce()
    for slot=1, config.workingFarmArea, 1 do

        -- End Case
        if #database >= config.storageFarmArea then
            print('breeding: Storage Full!')
            return false
        end

        -- Scan
        gps.go(gps.workingSlotToPos(slot))
        local crop = scanner.scan()

        if slot % 2 == 0 then
            checkChild(slot, crop)
        else
            checkParent(slot, crop)
        end

        if action.needCharge() then
            action.charge()
        end
    end
    return true
end


-- ======================== MAIN ========================

local function init()
    database.resetStorage()
    database.scanFarm()
    action.restockAll()

    targetCrop = database.getFarm()[1].name
    print('autoMaintainBreedingWithStorage')
    print('maintaining target crops, moving novel crops to storage')
end


local function main()
    init()

    -- Loop
    while maintainAndBreedOnce() do
        action.restockAll()
    end

    -- Finish
    if config.cleanUp then
        action.cleanUp()
    end

    print('autoMaintainBreedingWithStorage: Complete!')
end

main()