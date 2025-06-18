local action = require('action')
local database = require('database')
local gps = require('gps')
local scanner = require('scanner')
local config = require('config')

local function checkChild(slot, crop)
    if crop.isCrop and crop.name ~= 'emptyCrop' then

        if crop.name == 'air' then
            action.placeCropStick(2)

        elseif scanner.isWeed(crop, 'working') then
            action.deweed()
            action.placeCropStick()
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

local function maintainOnce()
    for slot=1, config.workingFarmArea, 1 do

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

    print('autoMaintaining')
end


local function main()
    init()

    -- Loop
    while maintainOnce() do
        action.restockAll()
    end

    -- Finish
    if config.cleanUp then
        action.cleanUp()
    end

    print('autoMaintain: Complete!')
end

main()