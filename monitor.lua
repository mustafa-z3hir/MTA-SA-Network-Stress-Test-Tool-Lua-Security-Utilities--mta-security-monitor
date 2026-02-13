--[[
    MTA:SA Security & CPU Monitor
    Author: mustafa-z3hir
    Version: 2.0
]]

local settings = {
    cpuLimit = 75,
    checkInterval = 5000,
    maxHistory = 50
}

local history = {}
local alertCount = 0

-- Get timestamp
local function getTimestamp()
    local t = getRealTime()
    return string.format("%02d:%02d:%02d", t.hour, t.minute, t.second)
end

-- Main monitoring function
local function analyzeNetworkImpact()
    local success, err = pcall(function()
        local _, _, luaTiming = getPerformanceStats("Lua timing")
        
        if not luaTiming then return end
        
        for _, row in ipairs(luaTiming) do
            local resourceName = row[1]
            local cpuUsage = tonumber(row[2])
            
            if cpuUsage and cpuUsage > settings.cpuLimit then
                -- Alert
                local msg = string.format("[SECURITY-WARN] %s | '%s' CPU spike: %s%%", 
                    getTimestamp(), resourceName, cpuUsage)
                outputDebugString(msg, 2)
                
                -- Store history
                table.insert(history, 1, {
                    resource = resourceName,
                    cpu = cpuUsage,
                    time = getTimestamp()
})
                
                -- Limit history
                if #history > settings.maxHistory then
                    table.remove(history)
                end
                
                alertCount = alertCount + 1
            end
        end
    end)
    
    if not success then
        outputDebugString("[SECURITY-ERROR] " .. tostring(err), 1)
    end
end

-- Admin command: /checkcpu
addCommandHandler("checkcpu", function(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then
        outputChatBox("Login required!", player, 255, 0, 0)
        return
    end
    
    if not isObjectInACLGroup("user." .. getAccountName(account), aclGetGroup("Admin")) then
        outputChatBox("No permission!", player, 255, 0, 0)
        return
    end
    
    -- Show report
    outputChatBox("╔════════════════════════════════╗", player, 0, 150, 255)
    outputChatBox("║     CPU MONITOR REPORT         ║", player, 0, 150, 255)
    outputChatBox("╠════════════════════════════════╣", player, 0, 150, 255)
    outputChatBox("║ Total Alerts: " .. alertCount, player, 255, 255, 255)
    outputChatBox("╠════════════════════════════════╣", player, 0, 150, 255)
    
    if #history == 0 then
        outputChatBox("║ No CPU issues detected", player, 0, 255, 0)
    else
        for i = 1, math.min(10, #history) do
            local h = history[i]
            outputChatBox(string.format("║ %s | %s: %s%%", h.time, h.resource:sub(1,15), h.cpu), 
                player, 255, 200, 0)
        end
    end
    
    outputChatBox("╚════════════════════════════════╝", player, 0, 150, 255)
end)

-- Clear history command: /clearcpu
addCommandHandler("clearcpu", function(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then return end
    
    if not isObjectInACLGroup("user." .. getAccountName(account), aclGetGroup("Admin")) then
        outputChatBox("Admin only!", player, 255, 0, 0)
        return
    end
    
    history = {}
    alertCount = 0
    outputChatBox("History cleared!", player, 0, 255, 0)
end)

-- Initialize
addEventHandler("onResourceStart", resourceRoot, function()
    print("╔══════════════════════════════════════╗")
    print("║  MTA:SA Security & CPU Monitor v2.0  ║")
    print("║  Commands: /checkcpu | /clearcpu     ║")
    print("╚══════════════════════════════════════╝")
    
    setTimer(analyzeNetworkImpact, settings.checkInterval, 0)
end)
