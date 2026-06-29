local wallStates     = {}   -- [wallId] = { ownerGang, tagStyle, contestGang, contestCount }
local wallBlips      = {}   -- [wallId] = blipHandle
local nearbyWallId   = nil
local isSprayActive  = false
local textUIShown    = false
local nuiIsOpen      = false
local openedWallId   = nil
local lastSprayTime  = 0    -- GetGameTimer() of last completed spray

-- ─── 3D text helper ──────────────────────────────────────────────────────────

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local cx, cy, cz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(cx, cy, cz) - vector3(x, y, z))
    local scale = math.min(0.45, (1.0 / dist) * 3.5)
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 210)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(sx, sy - 0.005)
end

-- ─── Blip management ─────────────────────────────────────────────────────────

local function getBlipColor(gang)
    if not gang then return Config.GangColors.unclaimed end
    return Config.GangColors[gang] or Config.GangColors.default
end

local function setBlipLabel(blip, wallName, ownerGang)
    local label = wallName .. (ownerGang and (' — ' .. ownerGang) or ' — Unclaimed')
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
end

local function setBlipContestPulse(blip, isContested)
    SetBlipFlashes(blip, isContested)
    if isContested then SetBlipFlashTimer(blip, 800) end
end

local function buildBlips(walls)
    for _, b in pairs(wallBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    wallBlips = {}

    for _, wall in ipairs(Config.Walls) do
        local state = walls[wall.id] or {}
        local blip  = AddBlipForCoord(wall.coords.x, wall.coords.y, wall.coords.z)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipScale(blip, Config.BlipScale)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, getBlipColor(state.ownerGang))
        setBlipLabel(blip, wall.name, state.ownerGang)
        setBlipContestPulse(blip, state.contestGang ~= nil)
        wallBlips[wall.id] = blip
    end
end

local function refreshBlip(wallId, state)
    wallStates[wallId] = state
    local blip = wallBlips[wallId]
    if not blip or not DoesBlipExist(blip) then return end
    SetBlipColour(blip, getBlipColor(state.ownerGang))
    setBlipContestPulse(blip, state.contestGang ~= nil)
    local wallConfig = nil
    for _, w in ipairs(Config.Walls) do
        if w.id == wallId then wallConfig = w; break end
    end
    if wallConfig then setBlipLabel(blip, wallConfig.name, state.ownerGang) end
end

-- ─── Leaderboard (computed locally to avoid extra callback on wallUpdated) ───

local function computeLeaderboard()
    local gangCounts = {}
    for _, state in pairs(wallStates) do
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
end

-- ─── UI ──────────────────────────────────────────────────────────────────────

local function openTagUI(wallId)
    local wallConfig = nil
    for _, w in ipairs(Config.Walls) do
        if w.id == wallId then wallConfig = w; break end
    end
    if not wallConfig then return end

    local state       = wallStates[wallId] or {}
    local playerGang  = lib.callback.await('187graffiti:getPlayerGang', false)
    local leaderboard = computeLeaderboard()
    local myStats     = lib.callback.await('187graffiti:getMyStats', false)

    nuiIsOpen    = true
    openedWallId = wallId

    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data   = {
            wall = {
                id           = wallId,
                name         = wallConfig.name,
                ownerGang    = state.ownerGang,
                tagStyle     = state.tagStyle,
                contestGang  = state.contestGang,
                contestCount = state.contestCount or 0,
            },
            playerGang  = playerGang or '',
            tagStyles   = Config.TagStyles,
            leaderboard = leaderboard,
            totalWalls  = #Config.Walls,
            sprayCount  = Config.SprayCount,
            playerStats = myStats or { total_sprays = 0, walls_tagged = 0, walls_lost = 0 },
        }
    })
end

-- ─── Spray sequence ───────────────────────────────────────────────────────────

local function doSpraySequence(wallId, tagStyle)
    if isSprayActive then return end

    -- Client-side cooldown guard (server enforces authoritatively)
    local now = GetGameTimer()
    if (now - lastSprayTime) < (Config.SprayCooldown * 1000) then
        local remaining = math.ceil((Config.SprayCooldown * 1000 - (now - lastSprayTime)) / 1000)
        lib.notify({ title = '187Graffiti', description = Locale['spray_cooldown']:format(remaining), type = 'warning' })
        return
    end

    isSprayActive = true

    PlaySoundFrontend(-1, 'PULL_OUT_AWARD', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

    local animDict = 'weapon@w_sp_flaregun'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Citizen.Wait(10) end
    TaskPlayAnim(cache.ped, animDict, 'idle_intro', 8.0, -8.0, -1, 49, 0, false, false, false)

    local coords = GetEntityCoords(cache.ped)
    local fwd    = GetEntityForwardVector(cache.ped)
    local px, py, pz = coords.x + fwd.x * 0.6, coords.y + fwd.y * 0.6, coords.z + 0.9

    RequestNamedPtfxAsset('scr_rcpaparazzo')
    while not HasNamedPtfxAssetLoaded('scr_rcpaparazzo') do Citizen.Wait(10) end
    UseParticleFxAssetNextCall('scr_rcpaparazzo')
    local pfx = StartParticleFxLoopedAtCoord('scr_meth_pipe_smoke', px, py, pz, 0.0, 0.0, 0.0, 0.25, false, false, false, false)

    local completed = lib.progressBar({
        duration     = Config.SprayDuration,
        label        = 'Tagging wall...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
    })

    StopParticleFxLooped(pfx, false)
    ClearPedTasks(cache.ped)

    if completed then
        UseParticleFxAssetNextCall('scr_rcpaparazzo')
        StartParticleFxNonLoopedAtCoord('scr_meth_pipe_smoke', px, py, pz, 0.0, 0.0, 0.0, 0.6, false, false, false)

        PlaySoundFrontend(-1, 'CHECKPOINT_COLLECTED', 'HUD_MINI_GAME_SOUNDSET', true)
        AnimpostfxPlay('SuccessNeutral', 400, false)
        lastSprayTime = GetGameTimer()
        TriggerServerEvent('187graffiti:spray', { wallId = wallId, tagStyle = tagStyle })
    else
        PlaySoundFrontend(-1, 'CANCEL', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end

    isSprayActive = false
end

-- ─── NUI callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback('spray', function(data, cb)
    nuiIsOpen    = false
    openedWallId = nil
    SetNuiFocus(false, false)
    cb('ok')
    Citizen.SetTimeout(150, function()
        doSpraySequence(tonumber(data.wallId), tostring(data.tagStyle))
    end)
end)

RegisterNUICallback('close', function(_, cb)
    nuiIsOpen    = false
    openedWallId = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ─── Server events ────────────────────────────────────────────────────────────

RegisterNetEvent('187graffiti:wallUpdated', function(wallId, state)
    refreshBlip(wallId, state)

    if nuiIsOpen then
        SendNUIMessage({ action = 'leaderboardUpdate', data = { leaderboard = computeLeaderboard() } })

        if openedWallId == wallId then
            local wallConfig = nil
            for _, w in ipairs(Config.Walls) do
                if w.id == wallId then wallConfig = w; break end
            end
            if wallConfig then
                SendNUIMessage({
                    action = 'wallStateUpdate',
                    data   = {
                        wall = {
                            id           = wallId,
                            name         = wallConfig.name,
                            ownerGang    = state.ownerGang,
                            tagStyle     = state.tagStyle,
                            contestGang  = state.contestGang,
                            contestCount = state.contestCount or 0,
                        }
                    }
                })
            end
        end
    end
end)

RegisterNetEvent('187graffiti:notify', function(type, message)
    lib.notify({ title = '187Graffiti', description = message, type = type })
end)

-- Screen shock + sound when losing territory
RegisterNetEvent('187graffiti:wallLost', function()
    PlaySoundFrontend(-1, 'CANCEL', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    AnimpostfxPlay('Damage', 600, false)
end)

-- ─── Tag label render thread ─────────────────────────────────────────────────
-- Draws emoji + gang name above every claimed wall when player is within 30m

local styleEmoji = {}
for _, s in ipairs(Config.TagStyles) do styleEmoji[s.id] = s.emoji end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(cache.ped)

        for _, wall in ipairs(Config.Walls) do
            local state = wallStates[wall.id]
            if state and state.ownerGang then
                local dist = #(playerCoords - vector3(wall.coords.x, wall.coords.y, wall.coords.z))
                if dist < 30.0 then
                    local emoji = styleEmoji[state.tagStyle] or '🎨'
                    DrawText3D(wall.coords.x, wall.coords.y, wall.coords.z + 1.5, emoji .. ' ' .. state.ownerGang)
                end
            end
        end
    end
end)

-- ─── Main proximity thread ───────────────────────────────────────────────────

Citizen.CreateThread(function()
    local walls = lib.callback.await('187graffiti:getWalls', false)
    if walls then
        for id, state in pairs(walls) do
            wallStates[tonumber(id)] = state
        end
        buildBlips(walls)

        -- Populate style emoji lookup for any walls already claimed
        for _, s in ipairs(Config.TagStyles) do styleEmoji[s.id] = s.emoji end
    end

    while true do
        local playerCoords     = GetEntityCoords(cache.ped)
        local closestMarker    = nil   -- within 8m (ground marker)
        local closestInteract  = nil   -- within SprayDistance (text UI + E key)
        local markerDist       = 8.0
        local interactDist     = Config.SprayDistance

        for _, wall in ipairs(Config.Walls) do
            local d = #(playerCoords - vector3(wall.coords.x, wall.coords.y, wall.coords.z))
            if d < markerDist then
                markerDist    = d
                closestMarker = wall
            end
            if d < interactDist then
                interactDist     = d
                closestInteract  = wall
            end
        end

        if closestMarker and not isSprayActive then
            -- Ground marker to guide player to exact wall spot
            DrawMarker(25,
                closestMarker.coords.x, closestMarker.coords.y, closestMarker.coords.z,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.6, 0.6, 0.25,
                139, 92, 246, 130,
                false, false, 2, false, nil, nil, false)

            if closestInteract then
                nearbyWallId = closestInteract.id

                if not textUIShown then
                    lib.showTextUI(Locale['press_to_tag'], { position = 'left-center' })
                    textUIShown = true
                end

                if IsControlJustReleased(0, 38) then
                    lib.hideTextUI()
                    textUIShown = false
                    openTagUI(nearbyWallId)
                end
            else
                if textUIShown then
                    lib.hideTextUI()
                    textUIShown = false
                end
                nearbyWallId = nil
            end

            Citizen.Wait(0)
        else
            if textUIShown then
                lib.hideTextUI()
                textUIShown = false
            end
            nearbyWallId = nil
            Citizen.Wait(500)
        end
    end
end)

-- ─── Cleanup ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, blip in pairs(wallBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    if textUIShown then lib.hideTextUI() end
    if isSprayActive then ClearPedTasks(cache.ped) end
    SetNuiFocus(false, false)
end)
