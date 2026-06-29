if Config.Framework ~= 'esx' then return end
if not IsDuplicityVersion() then return end

Framework = {}

local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function Framework.getPlayer(source)
    return ESX.GetPlayerFromId(source)
end

function Framework.getMoney(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.getMoney() or 0
end

function Framework.addMoney(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then xPlayer.addMoney(amount) end
end

function Framework.removeMoney(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then xPlayer.removeMoney(amount) end
end

function Framework.getJob(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.job.name or 'unemployed'
end

-- Gang detection: reads the 'gang' metadata field set by gang plugins (e.g. esx_gang).
-- If your server uses job names as gangs instead, replace with xPlayer.job.name.
function Framework.getGang(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return '' end
    local gang = xPlayer.getMeta('gang')
    if gang and gang ~= '' then return string.lower(tostring(gang)) end
    return ''
end

function Framework.notify(source, message, type)
    TriggerClientEvent('esx:showNotification', source, message)
end
