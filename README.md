# [187] Graffiti

> Gang territory control through street art. Players spray-tag 20 predefined walls across Los Santos to claim territory for their gang. Rival gangs can overwrite tags through repeated sprays. Real-time map blips track who owns what — no combat required, pure strategic presence.

## Preview
<!-- Screenshot or GIF here -->

## Dependencies
| Resource | Link |
|----------|------|
| ox_lib | https://github.com/overextended/ox_lib |
| oxmysql | https://github.com/overextended/oxmysql |

## Installation
1. Place `187Graffiti` in `resources/[187]/`
2. Add `ensure 187Graffiti` in `server.cfg`
3. Import `database.sql` into your database
4. Set `Config.Framework` to `'esx'`, `'qbcore'` or `'standalone'` in `config.lua`
5. If needed, edit `framework/esx.lua` or `framework/qbcore.lua` to match your framework version

## Features
- [x] 20 graffiti walls spread across Los Santos
- [x] 8 tag styles (Ghost, Flame, Crown, Skull, Diamond, Star, Thunder, All-Seeing)
- [x] Spray mechanics: N consecutive sprays from the same gang claim or overwrite a wall
- [x] Contest tracking: shows which gang is currently contesting a wall and their spray count
- [x] Defend mechanic: spraying your own wall resets an active contest
- [x] Real-time map blips — color changes when ownership changes (broadcast to all clients)
- [x] Gang leaderboard tab with territory percentage
- [x] Money reward on wall claim and on defense
- [x] Spray animation + particle effect (paint mist) + sound feedback
- [x] Progress bar (cancelable) for every spray action
- [x] Screen flash effect on successful claim
- [x] Per-player cooldown between spray attempts
- [x] Enemy gang notification when their wall is taken
- [x] Per-player stat tracking (sprays, walls claimed, walls lost)
- [x] Admin command `/greset [id]` — reset a single wall
- [x] Admin command `/gresetall` — reset all walls
- [x] Standalone `/setgang [name]` — assign a gang without a framework
- [x] Soft integration with 187Banking (optional, auto-detected)
- [x] Exports for other scripts to query territory state

## How it works

### Spray flow
1. Player walks within `Config.SprayDistance` meters of a wall → ox_lib text hint appears
2. Press **E** → panel opens with wall info, tag style selector, and territory leaderboard
3. Player selects a tag style and clicks the action button
4. A 4-second progress bar plays with spray animation and paint particle
5. On completion the spray event fires server-side

### Ownership logic (server-side)
- **Unclaimed wall**: any gang sprays it. After `Config.SprayCount` sprays from the same gang → wall is claimed.
- **Own wall**: spraying resets the active contest. Gang receives `Config.RewardOnDefend`.
- **Enemy wall**: a rival gang starts contesting. After `Config.SprayCount` consecutive sprays → ownership transfers. Gang receives `Config.RewardOnClaim`. Previous owner gang members are notified.
- If a different gang interjects mid-contest, the contest counter resets to 1 for the new gang.

### ESX gang detection
The ESX bridge reads the player's `gang` metadata field (set by plugins like `esx_gang`). If your server uses job names as gang identifiers instead, replace the `Framework.getGang` body in `framework/esx.lua` with `return xPlayer.job.name`.

## Configuration
| Parameter | Default | Description |
|-----------|---------|-------------|
| `Config.Framework` | `'esx'` | Framework to use: `'esx'`, `'qbcore'`, `'standalone'` |
| `Config.SprayDistance` | `2.5` | Meters to interact with a wall |
| `Config.SprayCooldown` | `120` | Seconds between sprays per player |
| `Config.SprayCount` | `5` | Consecutive sprays needed to claim/overwrite |
| `Config.SprayDuration` | `4000` | Progress bar duration in ms |
| `Config.RewardOnClaim` | `250` | $ reward on wall ownership change |
| `Config.RewardOnDefend` | `50` | $ reward for defending own territory |
| `Config.RequireItem` | `false` | Require `spray_can` item to spray |
| `Config.Walls` | 20 entries | Graffiti wall locations — add or remove as needed |
| `Config.TagStyles` | 8 styles | Available tag designs — add emoji/label pairs |
| `Config.GangColors` | map | Blip color IDs per gang name |

## Commands & Keybinds
| Command | Permission | Description |
|---------|-----------|-------------|
| `/greset [id]` | `command.greset` ace | Reset a single wall by ID |
| `/gresetall` | `command.gresetall` ace | Reset all walls |
| `/setgang [name]` | anyone | Standalone only: assign yourself to a gang |

Add to `server.cfg` for admin access:
```
add_ace group.admin command.greset allow
add_ace group.admin command.gresetall allow
```

## Exports
| Export | Side | Description |
|--------|------|-------------|
| `getGangWallCount(gang)` | Server | Returns the number of walls owned by a gang |
| `getWallsState()` | Server | Returns the full walls state table |
| `resetWall(wallId)` | Server | Programmatically reset a wall; returns `true` on success |

Usage example from another resource:
```lua
local count = exports['187Graffiti']:getGangWallCount('ballas')
print('Ballas own ' .. count .. ' walls')
```

## Framework compatibility
Works with **ESX**, **QBCore**, and **Standalone**. Set `Config.Framework` in `config.lua`.
Each framework has its own bridge file in `framework/` — edit the one matching your setup if your version uses different function names.

---
**187Scripts** — Quality FiveM Scripts
