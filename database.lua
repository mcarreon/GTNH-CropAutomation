local gps = require('gps')
local scanner = require('scanner')
local config = require('config')
local events = require('events')
local storage = {}
local reverseStorage = {}
local farm = {}

-- ======================== WORKING FARM ========================

local function getFarm()
    return farm
end


local function updateFarm(slot, crop)
    farm[slot] = crop
end

local function farmHasCrop(slot)
    return farm[slot].isCrop == true and farm[slot].name ~= 'emptyCrop'
end

local function resetFarm()
    farm = {}
end

-- ======================== STORAGE FARM ========================

local function getStorage()
    return storage
end


local function resetStorage()
    storage = {}
end


local function addToStorage(crop)
    storage[#storage+1] = crop
    reverseStorage[crop.name] = #storage
end

local function slotHasCrop(slot)
    return storage[slot].isCrop == true and storage[slot].name ~= 'emptyCrop'
end

local function existInStorage(crop)
    if reverseStorage[crop.name] then
        return true
    else
        return false
    end
end

local function scanFarm()
    for slot=1, config.workingFarmArea, 1 do
        gps.go(gps.workingSlotToPos(slot))
        local crop = scanner.scan()
        updateFarm(slot, crop)
    end
end

local function scanStorage()
    for slot=1, config.storageFarmArea, 1 do
        gps.go(gps.storageSlotToPos(slot))
        local crop = scanner.scan()
        addToStorage(crop)
    end
end


local function nextStorageSlot()
    return #storage + 1
end


return {
    getFarm = getFarm,
    updateFarm = updateFarm,
    getStorage = getStorage,
    resetStorage = resetStorage,
    addToStorage = addToStorage,
    existInStorage = existInStorage,
    nextStorageSlot = nextStorageSlot,
    slotHasCrop = slotHasCrop,
    scanFarm = scanFarm,
    scanStorage = scanStorage,
    farmHasCrop = farmHasCrop,
    resetFarm = resetFarm
}