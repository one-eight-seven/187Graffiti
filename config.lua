Config = {}

-- Framework: 'esx', 'qbcore', 'standalone'
Config.Framework = 'esx'
Config.Debug     = false
Config.Locale    = 'en'  -- reserved for future multi-locale support; currently only en.lua is shipped

-- Interaction
Config.SprayDistance = 2.5    -- meters to interact with a wall
Config.SprayCooldown = 120    -- seconds between spray attempts per player
Config.SprayCount    = 5      -- consecutive sprays needed to claim or overwrite a wall
Config.SprayDuration = 4000   -- ms for the spray progress bar

-- Economy
Config.RequireItem    = false      -- require 'spray_can' item to spray
Config.SprayItem      = 'spray_can'
Config.RewardOnClaim  = 250        -- $ reward when a wall changes ownership to your gang
Config.RewardOnDefend = 50         -- $ reward when reinforcing your own wall

-- Map blips
Config.BlipSprite = 431
Config.BlipScale  = 0.8

-- Standalone: command for assigning a gang to yourself (no framework)
Config.StandaloneGangCommand = 'setgang'

-- Territory reward cycle (optional)
Config.RewardCycleEnabled = false       -- set true to award the dominant gang periodically
Config.RewardCycleHours   = 24          -- real-time hours between cycles
Config.RewardCycleAmount  = 500         -- $ per wall owned given to each online gang member

-- Graffiti walls — predefined locations across Los Santos
Config.Walls = {
    { id = 1,  name = 'Vespucci Canals',       coords = vector4(-1097.89, -1449.95,  4.95,  90.0) },
    { id = 2,  name = 'Little Seoul Alley',    coords = vector4(-698.45,   -915.82, 19.22, 180.0) },
    { id = 3,  name = 'Chamberlain Hills',     coords = vector4( 151.72,  -1713.22, 29.29, 270.0) },
    { id = 4,  name = 'Davis Ave',             coords = vector4(  95.85,  -1953.07, 20.74,   0.0) },
    { id = 5,  name = 'Strawberry Ave',        coords = vector4(-242.53,  -1551.29, 31.43,  90.0) },
    { id = 6,  name = 'Forum Drive',           coords = vector4( 140.35,  -1571.44, 29.29, 180.0) },
    { id = 7,  name = 'Jamestown St',          coords = vector4( 270.64,  -1847.08, 26.30,  90.0) },
    { id = 8,  name = 'Olympic Fwy Underpass', coords = vector4(-500.22,  -1217.98, 18.18,   0.0) },
    { id = 9,  name = 'Innocence Blvd West',   coords = vector4(  54.56,  -1657.68, 29.30, 270.0) },
    { id = 10, name = 'Carson Ave',            coords = vector4( 205.45,  -2015.62, 21.12,  90.0) },
    { id = 11, name = 'LSIA Perimeter',        coords = vector4(-1030.88, -2730.80, 13.75, 180.0) },
    { id = 12, name = 'Elgin Ave',             coords = vector4( 314.96,   -678.21, 28.54, 270.0) },
    { id = 13, name = 'Power St',              coords = vector4( 638.73,   -805.45, 28.24,   0.0) },
    { id = 14, name = 'Innocence Blvd East',   coords = vector4( 398.65,  -1645.30, 29.29,  90.0) },
    { id = 15, name = 'Brouge Ave',            coords = vector4( 424.35,  -1965.40, 24.85, 180.0) },
    { id = 16, name = 'Capital Blvd',          coords = vector4( -43.44,  -1744.95, 29.42, 270.0) },
    { id = 17, name = 'Vespucci Beach Wall',   coords = vector4(-1353.77, -1358.32,  3.48,   0.0) },
    { id = 18, name = 'Mirror Park Tunnel',    coords = vector4(1135.40,   -715.69, 57.39,  90.0) },
    { id = 19, name = 'Vinewood Hills',        coords = vector4( 372.10,   -307.68, 44.97, 180.0) },
    { id = 20, name = 'La Mesa Industrial',    coords = vector4( 829.61,  -1309.14, 27.56, 270.0) },
}

-- Tag styles available to every player
Config.TagStyles = {
    { id = 'ghost',   label = 'Ghost Tag',   emoji = '👻' },
    { id = 'flame',   label = 'Flame Burst', emoji = '🔥' },
    { id = 'crown',   label = 'Crown',       emoji = '👑' },
    { id = 'skull',   label = 'Death Mark',  emoji = '💀' },
    { id = 'diamond', label = 'Diamond',     emoji = '💎' },
    { id = 'star',    label = 'Star Burst',  emoji = '⭐' },
    { id = 'bolt',    label = 'Thunder',     emoji = '⚡' },
    { id = 'eye',     label = 'All-Seeing',  emoji = '👁️' },
}

-- Map blip color IDs per gang name (FiveM blip color IDs)
Config.GangColors = {
    grove     = 2,   -- green
    ballas    = 27,  -- purple
    vagos     = 6,   -- yellow
    marabunta = 3,   -- blue
    lost      = 28,  -- dark purple
    angels    = 59,  -- dark red
    default   = 1,   -- red (fallback for unknown gangs)
    unclaimed = 4,   -- white
}
