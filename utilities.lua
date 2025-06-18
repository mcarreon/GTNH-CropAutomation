local function defer(func)
    return setmetatable({}, { __close = func })
end

return {
    defer = defer
}