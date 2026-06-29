local wallStates    = {}   -- [wallId] = { ownerGang, tagStyle, contestGang, contestCount }
local wallBlips     = {}   -- [wallId] = blipHandle
local nearbyWallId  = nil
local isSprayActive = false
local textUIShown   = false

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
        wallBlips[wall.id] = blip
    end
end

local function refreshBlip(wallId, state)
    wallStates[wallId] = state
    local blip = wallBlips[wallId]
    if not blip or not DoesBlipExist(blip) then return end
    SetBlipColour(blip, getBlipColor(state.ownerGang))
    local wallConfig = nil
    for _, w in ipairs(Config.Walls) do
        if w.id == wallId then wallConfig = w; break end
    end
    if wallConfig then setBlipLabel(blip, wallConfig.name, state.ownerGang) end
end

-- ─── UI ──────────────────────────────────────────────────────────────────────

local function openTagUI(wallId)
    local wallConfig = nil
    for _, w in ipairs(Config.Walls) do
        if w.id == wallId then wallConfig = w; break end
    end
    if not wallConfig then return end

    local state      = wallStates[wallId] or {}
    local playerGang = lib.callback.await('187graffiti:getPlayerGang', false)
    local leaderboard = lib.callback.await('187graffiti:getLeaderboard', false)

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
            leaderboard = leaderboard or {},
            totalWalls  = #Config.Walls,
            sprayCount  = Config.SprayCount,
        }
    })
end

-- ─── Spray sequence ───────────────────────────────────────────────────────────

local function doSpraySequence(wallId, tagStyle)
    if isSprayActive then return end
    isSprayActive = true

    -- Spray-can pull-out sound
    PlaySoundFrontend(-1, 'PULL_OUT_AWARD', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)

    -- Spray animation (arm raise + hold)
    local animDict = 'weapon@w_sp_flaregun'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Citizen.Wait(10) end
    TaskPlayAnim(cache.ped, animDict, 'idle_intro', 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Paint mist particle at arm level
    local coords = GetEntityCoords(cache.ped)
    local fwd    = GetEntityForwardVector(cache.ped)
    local px, py, pz = coords.x + fwd.x * 0.6, coords.y + fwd.y * 0.6, coords.z + 0.9

    RequestNamedPtfxAsset('scr_rcpaparazzo')
    while not HasNamedPtfxAssetLoaded('scr_rcpaparazzo') do Citizen.Wait(10) end
    UseParticleFxAssetNextCall('scr_rcpaparazzo')
    local pfx = StartParticleFxLoopedAtCoord('scr_meth_pipe_smoke', px, py, pz, 0.0, 0.0, 0.0, 0.25, false, false, false, false)

    -- Spray drip sound loop (repurposed)
    PlaySoundFromCoord(-1, 'ATM_WINDOW', 'SCRIPTS/ATMS', px, py, pz, 0, true, 5.0, false)

    -- Progress bar (cancelable)
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
        -- Sparks burst on finish
        UseParticleFxAssetNextCall('scr_rcpaparazzo')
        StartParticleFxNonLoopedAtCoord('scr_meth_pipe_smoke', px, py, pz, 0.0, 0.0, 0.0, 0.6, false, false, false)

        PlaySoundFrontend(-1, 'CHECKPOINT_COLLECTED', 'HUD_MINI_GAME_SOUNDSET', true)
        AnimpostfxPlay('SuccessNeutral', 400, false)

        TriggerServerEvent('187graffiti:spray', { wallId = wallId, tagStyle = tagStyle })
    else
        PlaySoundFrontend(-1, 'CANCEL', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end

    isSprayActive = false
end

-- ─── NUI callbacks ───────────────────────────────────────────────────────────

RegisterNUICallback('spray', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
    Citizen.SetTimeout(150, function()
        doSpraySequence(tonumber(data.wallId), tostring(data.tagStyle))
    end)
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ─── Server events ────────────────────────────────────────────────────────────

RegisterNetEvent('187graffiti:wallUpdated', function(wallId, state)
    refreshBlip(wallId, state)
end)

RegisterNetEvent('187graffiti:notify', function(type, message)
    lib.notify({ title = '187Graffiti', description = message, type = type })
end)

-- ─── Main proximity thread ───────────────────────────────────────────────────

Citizen.CreateThread(function()
    -- Load initial state and build blips
    local walls = lib.callback.await('187graffiti:getWalls', false)
    if walls then
        for id, state in pairs(walls) do
            wallStates[tonumber(id)] = state
        end
        buildBlips(walls)
    end

    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local closest      = nil
        local closestDist  = Config.SprayDistance

        for _, wall in ipairs(Config.Walls) do
            local d = #(playerCoords - vector3(wall.coords.x, wall.coords.y, wall.coords.z))
            if d < closestDist then
                closestDist = d
                closest     = wall
            end
        end

        if closest and not isSprayActive then
            nearbyWallId = closest.id

            if not textUIShown then
                lib.showTextUI(Locale['press_to_tag'], { position = 'left-center' })
                textUIShown = true
            end

            if IsControlJustReleased(0, 38) then -- E key
                lib.hideTextUI()
                textUIShown = false
                openTagUI(nearbyWallId)
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
