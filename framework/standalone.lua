if Config.Framework ~= 'standalone' then return end
if not IsDuplicityVersion() then return end

Framework = {}

local playerMoney = {}
local playerGangs = {}

function Framework.getPlayer(source)
    return { source = source }
end

function Framework.getMoney(source)
    return playerMoney[source] or 0
end

function Framework.addMoney(source, amount)
    playerMoney[source] = (playerMoney[source] or 0) + amount
end

function Framework.removeMoney(source, amount)
    playerMoney[source] = math.max(0, (playerMoney[source] or 0) - amount)
end

function Framework.getJob(source)
    return 'civilian'
end

-- Gangs are set via /setgang command (see server/main.lua)
function Framework.getGang(source)
    return playerGangs[source] or ''
end

function Framework.setGang(source, gang)
    playerGangs[source] = string.lower(tostring(gang))
end

function Framework.notify(source, message, type)
    TriggerClientEvent('187:notify', source, message, type)
end

-- Clean up on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    playerMoney[src] = nil
    playerGangs[src] = nil
end)
