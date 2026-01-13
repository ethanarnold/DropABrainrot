# Drop A Brainrot - Implementation Plan

This plan tracks implementation progress across multiple sessions.

## Phase 1: Data Layer (Foundation) ✅

- [x] Define shared types/constants in `src/shared/`
  - [x] Brainrot definitions (id, name, level, rarity, incomePerSecond)
  - [x] Bag definitions (level, capacity, maxBrainrotLevel)
  - [x] Upgrade definitions (costs, effects)
- [x] Create PlayerData module
  - [x] Data schema (currency, bagLevel, inventory, plotSlots, placedBrainrots, upgrades)
  - [x] Default player data template
- [x] Implement DataStore persistence on server
  - [x] Load on PlayerAdded
  - [x] Save on PlayerRemoving and periodic autosave
  - [x] Session locking to prevent data loss (via ProfileService)

## Phase 2: Core Systems ✅

> **Clarification:** The bag is an upgradable **tool** that determines pickup eligibility and inventory capacity.
> Bag level determines: (1) which brainrot levels can be picked up (brainrot.level <= bagLevel), (2) inventory capacity.
> Brainrots are stored in the player's **inventory**, not in the bag itself.

### Schema Updates
- [x] Rename `bagContents` → `inventory` in Types.luau and PlayerData.luau

### Communication Layer
- [x] Create `src/shared/Remotes.luau` - Centralized RemoteEvents/RemoteFunctions
  - Client→Server: PickupBrainrot, PlaceBrainrot, RemoveBrainrot, CollectIncome
  - Server→Client: CurrencyUpdated, InventoryUpdated, PlotUpdated, ShowMessage
  - Request/Response: GetPlayerData, GetInventory, GetPlotState

### Server Services
- [x] CurrencyService (`src/server/Services/CurrencyService.luau`)
  - [x] add(player, amount) - Add currency, fire CurrencyUpdated
  - [x] spend(player, amount) - Spend if sufficient
  - [x] get(player) - Get current balance
- [x] BagService (`src/server/Services/BagService.luau`)
  - [x] canPickup(player, brainrotId) - Validate level + capacity
  - [x] addToInventory(player, brainrotId) - Add to inventory
  - [x] removeFromInventory(player, index) - Remove from inventory
  - [x] Handle PickupBrainrot remote (validate brainrot exists in workspace.SpawnedBrainrots)
- [x] PlotService (`src/server/Services/PlotService.luau`)
  - [x] placeBrainrot(player, inventoryIndex, slotIndex)
  - [x] removeBrainrot(player, slotIndex)
  - [x] calculateIncome(player) - Sum incomePerSecond * elapsed * multiplier
  - [x] collectIncome(player) - Triggered by Touched event on plot Part
- [x] DebugService (`src/server/Services/DebugService.luau`)
  - [x] Admin command to spawn test brainrots into workspace.SpawnedBrainrots

### Client Services
- [x] ClientDataService (`src/client/Services/ClientDataService.luau`)
  - [x] Cache player data locally
  - [x] Listen to update events (CurrencyUpdated, InventoryUpdated, PlotUpdated)
  - [x] Expose data getters and change signals

### Client Controllers
- [x] PickupController (`src/client/Controllers/PickupController.luau`)
  - [x] Right-click (Button2Down) to pick up brainrot
  - [x] Raycast to detect brainrot in workspace.SpawnedBrainrots
- [x] PlotController (`src/client/Controllers/PlotController.luau`)
  - [x] Click plot slot to open inventory for placement
  - [x] Fire PlaceBrainrot/RemoveBrainrot remotes

### Client UI
- [x] CurrencyDisplay (`src/client/UI/CurrencyDisplay.luau`)
  - [x] TextLabel showing current currency
- [x] InventoryUI (`src/client/UI/InventoryUI.luau`)
  - [x] Grid showing inventory contents
  - [x] Show capacity (e.g., 3/5)
  - [x] Popup mode for placement selection
- [x] MessageDisplay (`src/client/UI/MessageDisplay.luau`)
  - [x] Toast messages ("Bag level too low!", "Inventory full!")

### Init Scripts
- [x] Update `src/server/init.server.luau` - Initialize all services
- [x] Update `src/client/init.client.luau` - Initialize services, controllers, UI

## Phase 3: World Mechanics

> **Note:** Pickup system was moved to Phase 2. Phase 3 focuses on automated spawning.

### Brainrot Tank & Spawning
- [ ] Server: TankService
  - [ ] Explosion timer (configurable interval)
  - [ ] Spawn brainrot instances into workspace.SpawnedBrainrots
  - [ ] Weighted random selection based on rarity
  - [ ] Scatter physics/positioning in catch area
  - [ ] Despawn uncollected brainrots after timeout
- [ ] Client: Visual/audio effects for explosion

### Plot Integration (World <-> Data)
> **Note:** PlotService handles data (placement, income calculation). This section connects it to physical plots.

- [ ] Define plot structure in world
  - [ ] Determine where plots live (workspace folder? Per-player instances?)
  - [ ] Define slot identification (Part names, Attributes, or ClickDetectors?)
  - [ ] Define income collection zone (Part with Touched event)
- [ ] Server: Plot assignment on player join
  - [ ] Assign physical plot to player
  - [ ] Track player -> plot mapping
- [ ] Server: Connect PlotService to physical plots
  - [ ] Spawn brainrot model on slot when placed
  - [ ] Remove brainrot model when removed from slot
  - [ ] Connect collection zone Touched to PlotService.collectIncome
- [ ] Client: Plot slot interaction
  - [ ] Detect click on empty slot -> open InventoryUI in selection mode
  - [ ] Detect click on occupied slot -> show remove option
  - [ ] Visual highlighting when hovering over slots

### Polish
- [ ] Client: Visual feedback on successful pickup (particles, sound)
- [ ] Client: Income collection effects (coins flying, sound)

## Phase 4: Shops & Upgrades

### Bag Shop
- [ ] Server: PurchaseService for bag upgrades
  - [ ] BagCapacity upgrade
  - [ ] BagLevel upgrade
- [ ] Client: Bag shop UI
  - [ ] Display current stats
  - [ ] Show upgrade costs and effects
  - [ ] Purchase buttons

### Plot Upgrades
- [ ] Server: Plot slot purchases
- [ ] Client: Plot upgrade UI

### Player Upgrades
- [ ] Server: Player upgrade purchases
  - [ ] Autocollect
  - [ ] Offline income hours
  - [ ] Offline income multiplier
  - [ ] Global income multipliers
- [ ] Client: Player upgrades UI

## Phase 5: Tutorial

- [ ] Shared: Tutorial state enum (NotStarted, GetBag, GoToCatchArea, PickupBrainrot, PlaceBrainrot, Complete)
- [ ] Server: Track tutorial progress in PlayerData
- [ ] Client: Arrow beam system pointing to objectives
- [ ] Server: Spawn "starter brainrot" for tutorial players
- [ ] Client: Tutorial prompts/instructions UI

## Phase 6: Polish

- [ ] Offline income calculation on rejoin
- [ ] Sound effects
- [ ] Particle effects
- [ ] Animations
- [ ] Leaderboards
- [ ] Additional brainrot types/rarities
- [ ] Cosmetics system

---

## Session Notes

_Use this section to track progress and leave notes for future sessions._

**Session 1:** Created initial project structure and planning documents.

**Session 2:** Completed Phase 1 (Data Layer):
- Created BRAINROTS.md with all 75 brainrots and rarity assignments
- Added ProfileService via Wally for data persistence
- Created Types.luau with all shared type definitions
- Created Data modules: Brainrots.luau, Bags.luau, Upgrades.luau
- Created PlayerData.luau with default data template
- Implemented DataService with ProfileService integration
- Updated server init to initialize DataService
- **All tests passed:** Selene linting clean, Wally install successful, Rojo sync verified, DataService initializes correctly, player profiles load on join. ProfileService gracefully falls back to mock mode in Studio (expected behavior).

**Session 3:** Completed Phase 2 (Core Systems):
- Clarified bag mechanics: bag is a tool that determines pickup eligibility + inventory capacity (not a container)
- Renamed `bagContents` → `inventory` in schema
- Created `Remotes.luau` for centralized client-server communication
- Created server services: CurrencyService, BagService, PlotService, DebugService
- Created client service: ClientDataService for local data caching
- Created client controllers: PickupController (right-click pickup), PlotController (plot interaction)
- Created client UI: CurrencyDisplay, InventoryUI (toggle with 'I'), MessageDisplay (toast messages)
- Updated init scripts for both server and client
- **Debug commands available:** `/spawn <brainrotId>`, `/spawnat`, `/clearbrainrots`, `/givecurrency`, `/listbrainrots`
- **Selene lint:** 0 errors, 0 warnings
