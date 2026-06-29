if Config.Framework ~= 'qbcore' then return end
if not IsDuplicityVersion() then return end

Framework = {}

local QBCore = exports['qb-core']:GetCoreObject()

function Framework.getPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

function Framework.getMoney(source)
    local player = QBCore.Functions.GetPlayer(source)
    return player and player.PlayerData.money['cash'] or 0
end

function Framework.addMoney(source, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if player then player.Functions.AddMoney('cash', amount) end
end

function Framework.removeMoney(source, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if player then player.Functions.RemoveMoney('cash', amount) end
end

function Framework.getJob(source)
    local player = QBCore.Functions.GetPlayer(source)
    return player and player.PlayerData.job.name or 'unemployed'
end

function Framework.getGang(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return '' end
    local gang = player.PlayerData.gang and player.PlayerData.gang.name
    if gang and gang ~= '' and gang ~= 'none' then return string.lower(tostring(gang)) end
    return ''
end

function Framework.notify(source, message, type)
    TriggerClientEvent('QBCore:Notify', source, message, type or 'primary')
end
