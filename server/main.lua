local wallsState      = {}   -- [wallId] = { ownerGang, tagStyle, contestGang, contestCount }
local playerCooldowns = {}   -- [identifier] = os.time() of last spray

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getWallConfig(wallId)
    for _, w in ipairs(Config.Walls) do
        if w.id == wallId then return w end
    end
    return nil
end

local function saveWallState(wallId)
    local s = wallsState[wallId]
    MySQL.update(
        'INSERT INTO `187graffiti_walls` (id, owner_gang, tag_style, contest_gang, contest_count) VALUES (?, ?, ?, ?, ?) ' ..
        'ON DUPLICATE KEY UPDATE owner_gang = ?, tag_style = ?, contest_gang = ?, contest_count = ?',
        { wallId, s.ownerGang, s.tagStyle, s.contestGang, s.contestCount,
                  s.ownerGang, s.tagStyle, s.contestGang, s.contestCount }
    )
end

local function updatePlayerStats(identifier, gang, claimed)
    local claimPart = claimed and ', walls_tagged = walls_tagged + 1' or ''
    MySQL.update(
        'INSERT INTO `187graffiti_stats` (identifier, gang, total_sprays) VALUES (?, ?, 1) ' ..
        'ON DUPLICATE KEY UPDATE gang = ?, total_sprays = total_sprays + 1' .. claimPart,
        { identifier, gang, gang }
    )
end

local function incrementWallsLost(identifier)
    MySQL.update(
        'INSERT INTO `187graffiti_stats` (identifier, walls_lost) VALUES (?, 1) ' ..
        'ON DUPLICATE KEY UPDATE walls_lost = walls_lost + 1',
        { identifier }
    )
end

local function notifyGang(gang, message)
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src and Framework.getGang(src) == gang then
            Framework.notify(src, message, 'warning')
        end
    end
end

-- Find identifier of a player who last owned a wall (for stats; best-effort)
local function findGangMemberIdentifier(gang)
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src and Framework.getGang(src) == gang then
            return GetPlayerIdentifier(src, 0)
        end
    end
    return nil
end

-- ─── Startup ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.Wait(1000)

    for _, wall in ipairs(Config.Walls) do
        wallsState[wall.id] = { ownerGang = nil, tagStyle = nil, contestGang = nil, contestCount = 0 }
    end

    local rows = MySQL.query.await('SELECT * FROM `187graffiti_walls`')
    if rows then
        for _, row in ipairs(rows) do
            if wallsState[row.id] then
                wallsState[row.id].ownerGang    = row.owner_gang
                wallsState[row.id].tagStyle     = row.tag_style
                wallsState[row.id].contestGang  = row.contest_gang
                wallsState[row.id].contestCount = row.contest_count or 0
            end
        end
    end

    if Config.Debug then
        print(('[187Graffiti] Loaded %d walls from database.'):format(#Config.Walls))
    end
end)

-- ─── Callbacks ───────────────────────────────────────────────────────────────

lib.callback.register('187graffiti:getWalls', function(source)
    return wallsState
end)

lib.callback.register('187graffiti:getLeaderboard', function(source)
    local gangCounts = {}
    for _, state in pairs(wallsState) do
        if state.ownerGang then
            gangCounts[state.ownerGang] = (gangCounts[state.ownerGang] or 0) + 1
        end
    end
    local board = {}
    for gang, count in pairs(gangCounts) do
        board[#board + 1] = { gang = gang, walls = count }
    end
    table.sort(board, function(a, b) return a.walls > b.walls end)
    return board
end)

lib.callback.register('187graffiti:getPlayerGang', function(source)
    return Framework.getGang(source)
end)

lib.callback.register('187graffiti:getMyStats', function(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then return nil end
    local row = MySQL.query.await('SELECT * FROM `187graffiti_stats` WHERE identifier = ?', { identifier })
    return row and row[1] or { total_sprays = 0, walls_tagged = 0, walls_lost = 0 }
end)

-- ─── Spray event ─────────────────────────────────────────────────────────────

RegisterNetEvent('187graffiti:spray', function(data)
    local source = source
    if not source or source <= 0 then return end
    if type(data) ~= 'table' then return end

    local wallId   = tonumber(data.wallId)
    local tagStyle = type(data.tagStyle) == 'string' and data.tagStyle or ''

    -- Validate wall
    if not wallId or not wallsState[wallId] then
        TriggerClientEvent('187graffiti:notify', source, 'error', Locale['spray_invalid_wall'])
        return
    end

    -- Validate tag style
    local validStyle = false
    for _, s in ipairs(Config.TagStyles) do
        if s.id == tagStyle then validStyle = true; break end
    end
    if not validStyle then
        TriggerClientEvent('187graffiti:notify', source, 'error', Locale['spray_invalid_style'])
        return
    end

    -- Cooldown
    local identifier = GetPlayerIdentifier(source, 0)
    local now        = os.time()
    if playerCooldowns[identifier] and (now - playerCooldowns[identifier]) < Config.SprayCooldown then
        local remaining = Config.SprayCooldown - (now - playerCooldowns[identifier])
        TriggerClientEvent('187graffiti:notify', source, 'warning', Locale['spray_cooldown']:format(remaining))
        return
    end
    playerCooldowns[identifier] = now

    -- Get gang
    local gang = Framework.getGang(source)
    if not gang or gang == '' then
        TriggerClientEvent('187graffiti:notify', source, 'error', Locale['spray_no_gang'])
        return
    end

    local wall       = wallsState[wallId]
    local wallConfig = getWallConfig(wallId)

    -- ── Case 1: Defending own wall ──
    if wall.ownerGang == gang then
        wall.contestGang  = nil
        wall.contestCount = 0
        saveWallState(wallId)
        Framework.addMoney(source, Config.RewardOnDefend)
        TriggerClientEvent('187graffiti:notify', source, 'success', Locale['spray_defended'])
        TriggerClientEvent('187graffiti:notify', source, 'info', Locale['reward_defend']:format(Config.RewardOnDefend))
        updatePlayerStats(identifier, gang, false)
        return
    end

    -- ── Case 2: Unclaimed wall ──
    if wall.ownerGang == nil then
        if wall.contestGang == gang then
            wall.contestCount = wall.contestCount + 1
        else
            wall.contestGang  = gang
            wall.contestCount = 1
        end

        if wall.contestCount >= Config.SprayCount then
            wall.ownerGang    = gang
            wall.tagStyle     = tagStyle
            wall.contestGang  = nil
            wall.contestCount = 0
            saveWallState(wallId)
            Framework.addMoney(source, Config.RewardOnClaim)
            TriggerClientEvent('187graffiti:wallUpdated', -1, wallId, wall)
            TriggerClientEvent('187graffiti:notify', source, 'success', Locale['spray_claimed']:format(gang))
            TriggerClientEvent('187graffiti:notify', source, 'info', Locale['reward_claim']:format(Config.RewardOnClaim))
            updatePlayerStats(identifier, gang, true)

            -- Soft integration: log transaction to 187Banking if running
            if GetResourceState('187Banking') == 'started' then
                exports['187Banking']:logTransaction(source, Config.RewardOnClaim, 'Graffiti territory claim')
            end
        else
            saveWallState(wallId)
            TriggerClientEvent('187graffiti:notify', source, 'info', Locale['spray_contested']:format(wall.contestCount, Config.SprayCount))
            updatePlayerStats(identifier, gang, false)
        end
        return
    end

    -- ── Case 3: Enemy wall ──
    local previousOwner = wall.ownerGang

    if wall.contestGang == gang then
        wall.contestCount = wall.contestCount + 1
    else
        wall.contestGang  = gang
        wall.contestCount = 1
    end

    if wall.contestCount >= Config.SprayCount then
        wall.ownerGang    = gang
        wall.tagStyle     = tagStyle
        wall.contestGang  = nil
        wall.contestCount = 0
        saveWallState(wallId)
        Framework.addMoney(source, Config.RewardOnClaim)
        TriggerClientEvent('187graffiti:wallUpdated', -1, wallId, wall)
        TriggerClientEvent('187graffiti:notify', source, 'success', Locale['spray_claimed']:format(gang))
        TriggerClientEvent('187graffiti:notify', source, 'info', Locale['reward_claim']:format(Config.RewardOnClaim))
        updatePlayerStats(identifier, gang, true)

        -- Notify losing gang and update their stats
        local losingIdentifier = findGangMemberIdentifier(previousOwner)
        if losingIdentifier then incrementWallsLost(losingIdentifier) end
        if wallConfig then
            notifyGang(previousOwner, Locale['wall_taken']:format(gang, wallConfig.name))
        end

        if GetResourceState('187Banking') == 'started' then
            exports['187Banking']:logTransaction(source, Config.RewardOnClaim, 'Graffiti territory takeover')
        end
    else
        saveWallState(wallId)
        TriggerClientEvent('187graffiti:notify', source, 'info', Locale['spray_contested']:format(wall.contestCount, Config.SprayCount))
        updatePlayerStats(identifier, gang, false)
    end
end)

-- ─── Admin commands ───────────────────────────────────────────────────────────

-- /greset [wallId] — reset a single wall (requires ace permission 'command.greset')
RegisterCommand('greset', function(source, args)
    local wallId = tonumber(args[1])
    if not wallId or not wallsState[wallId] then
        local msg = Locale['admin_reset_invalid']:format(#Config.Walls)
        if source > 0 then TriggerClientEvent('187graffiti:notify', source, 'error', msg)
        else print('[187Graffiti] ' .. msg) end
        return
    end

    wallsState[wallId] = { ownerGang = nil, tagStyle = nil, contestGang = nil, contestCount = 0 }
    MySQL.update('UPDATE `187graffiti_walls` SET owner_gang = NULL, tag_style = NULL, contest_gang = NULL, contest_count = 0 WHERE id = ?', { wallId })
    TriggerClientEvent('187graffiti:wallUpdated', -1, wallId, wallsState[wallId])

    local msg = Locale['admin_reset_done']:format(wallId)
    if source > 0 then TriggerClientEvent('187graffiti:notify', source, 'success', msg)
    else print('[187Graffiti] ' .. msg) end
end, true)

-- /gresetall — reset every wall
RegisterCommand('gresetall', function(source, args)
    for _, wall in ipairs(Config.Walls) do
        wallsState[wall.id] = { ownerGang = nil, tagStyle = nil, contestGang = nil, contestCount = 0 }
        TriggerClientEvent('187graffiti:wallUpdated', -1, wall.id, wallsState[wall.id])
    end
    MySQL.update('UPDATE `187graffiti_walls` SET owner_gang = NULL, tag_style = NULL, contest_gang = NULL, contest_count = 0', {})

    local msg = Locale['admin_reset_all']:format(#Config.Walls)
    if source > 0 then TriggerClientEvent('187graffiti:notify', source, 'success', msg)
    else print('[187Graffiti] ' .. msg) end
end, true)

-- /setgang [name] — standalone only: assign yourself to a gang
if Config.Framework == 'standalone' then
    RegisterCommand(Config.StandaloneGangCommand, function(source, args)
        if source == 0 then return end
        if not args[1] then
            TriggerClientEvent('187graffiti:notify', source, 'error', Locale['admin_gang_usage'])
            return
        end
        Framework.setGang(source, args[1])
        TriggerClientEvent('187graffiti:notify', source, 'success', Locale['admin_gang_done']:format(string.lower(args[1])))
    end, false)
end

-- ─── Cleanup ─────────────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    local identifier = GetPlayerIdentifier(source, 0)
    if identifier then playerCooldowns[identifier] = nil end
end)

-- ─── Exports ─────────────────────────────────────────────────────────────────

exports('getGangWallCount', function(gang)
    local count = 0
    for _, state in pairs(wallsState) do
        if state.ownerGang == gang then count = count + 1 end
    end
    return count
end)

exports('getWallsState', function()
    return wallsState
end)

exports('resetWall', function(wallId)
    if not wallsState[wallId] then return false end
    wallsState[wallId] = { ownerGang = nil, tagStyle = nil, contestGang = nil, contestCount = 0 }
    MySQL.update('UPDATE `187graffiti_walls` SET owner_gang = NULL, tag_style = NULL, contest_gang = NULL, contest_count = 0 WHERE id = ?', { wallId })
    TriggerClientEvent('187graffiti:wallUpdated', -1, wallId, wallsState[wallId])
    return true
end)
