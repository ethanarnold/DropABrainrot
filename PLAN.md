# Drop A Brainrot - Implementation Plan

This plan tracks implementation progress across multiple sessions.

## Phase 1: Data Layer (Foundation)

- [ ] Define shared types/constants in `src/shared/`
  - [ ] Brainrot definitions (id, name, level, rarity, incomePerSecond)
  - [ ] Bag definitions (level, capacity, maxBrainrotLevel)
  - [ ] Upgrade definitions (costs, effects)
- [ ] Create PlayerData module
  - [ ] Data schema (currency, bagLevel, bagContents, plotSlots, placedBrainrots, upgrades)
  - [ ] Default player data template
- [ ] Implement DataStore persistence on server
  - [ ] Load on PlayerAdded
  - [ ] Save on PlayerRemoving and periodic autosave
  - [ ] Session locking to prevent data loss

## Phase 2: Core Systems

### Bag System
- [ ] Server: BagService
  - [ ] Track bag contents per player
  - [ ] Add/remove brainrots from bag
  - [ ] Validate pickup (check bag level vs brainrot level, capacity)
- [ ] Client: Bag UI
  - [ ] Display current bag contents
  - [ ] Show capacity (e.g., 3/5)

### Plot System
- [ ] Server: PlotService
  - [ ] Assign plots to players on join
  - [ ] Track placed brainrots per slot
  - [ ] Handle placement requests (validate slot availability, remove from bag)
- [ ] Shared: Income calculation logic
- [ ] Server: Passive income accumulation

### Currency System
- [ ] Server: CurrencyService
  - [ ] Add/subtract currency with validation
  - [ ] Replicate currency to client
- [ ] Client: Currency display UI

## Phase 3: World Mechanics

### Brainrot Tank & Spawning
- [ ] Server: TankService
  - [ ] Explosion timer (configurable interval)
  - [ ] Spawn brainrot instances on explosion
  - [ ] Scatter physics/positioning in catch area
  - [ ] Despawn uncollected brainrots after timeout
- [ ] Client: Visual/audio effects for explosion

### Brainrot Pickup
- [ ] Server: Pickup detection and validation
  - [ ] Proximity check (player near brainrot)
  - [ ] Bag level/capacity validation
  - [ ] Transfer brainrot to player's bag
- [ ] Client: Pickup prompt UI
- [ ] Client: Visual feedback on successful pickup

### Income Collection
- [ ] Server: Detect player walking over their plot platform
- [ ] Server: Transfer accumulated income to currency
- [ ] Client: Visual feedback (coins flying, sound)

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

**Session 1 (Current):** Created initial project structure and planning documents.
