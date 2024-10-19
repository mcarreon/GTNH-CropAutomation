local event = require('event')
local needExitFlag = false
local needCleanupFlag = false


local function keyboardEvent(eventName, keyboardAddress, charNum, codeNum, playerName)
    -- Exit if 'q' was pressed
    if charNum == 113 then
        needExitFlag = true
        return false -- Unregister this event listener

    -- Exit and cleanup if 'c' was pressed
    elseif charNum == 99 then
        needExitFlag = true
        needCleanupFlag = true
        return false -- Unregister this event listener
    end
end


local function initEvents()
    needExitFlag = false
    needCleanupFlag = false
end


local function hookEvents()
    event.listen("key_up", keyboardEvent)
end


local function unhookEvents()
    event.ignore("key_up", keyboardEvent)
end


local function needExit()
    return needExitFlag
end


local function needCleanup()
    return needCleanupFlag
end


local function setNeedCleanup(value)
    needCleanupFlag = value
end


return {
    initEvents = initEvents,
    hookEvents = hookEvents,
    unhookEvents = unhookEvents,
    needExit = needExit,
    needCleanup = needCleanup,
    setNeedCleanup = setNeedCleanup
}