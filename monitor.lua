-- [[ 
--  Project: MTA:SA Network Stress & Security Monitor
--  Author: mustafa-z3hir
--  Description: Monitors server health and analyzes packet-driven CPU spikes.
-- ]]

local monitorSettings = {
    cpuLimit = 75, -- Warn if CPU usage exceeds 75%
    logInterval = 1000, -- Check every 1 second
}

-- Monitoring logic for network-driven resource usage
local function analyzeNetworkImpact()
    -- Get Lua timing stats to see if scripts are struggling
    local _, _, luaTiming = getPerformanceStats("Lua timing")
    
    for _, row in ipairs(luaTiming) do
        local resourceName = row[1]
        local cpuUsage = tonumber(row[2])
        
        if cpuUsage and cpuUsage > monitorSettings.cpuLimit then
            outputDebugString(string.format("[SECURITY-WARN] Resource '%s' is causing a CPU spike: %s%%", resourceName, cpuUsage), 2)
        end
    end
end

-- Initialize Monitoring
addEventHandler("onResourceStart", resourceRoot, function()
    print("******************************************")
    print("* MTA:SA Security & Stress Monitor Active *")
    print("******************************************")
    
    setTimer(function()
        analyzeNetworkImpact()
    end, monitorSettings.logInterval, 0)
end)
