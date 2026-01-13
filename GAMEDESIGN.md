# Drop A Brainrot

## Place design:

1. A large **central area** containing:
    1. The *brainrot tank* into which newly spawned brainrots fall into. The *brainrot tank* periodically explodes, scattering all of the brainrots onto the **catch area**
    2. The *catch area* ****surrounds the *brainrot tank*. Players can collect brainrots from this area by using a upgradable *bag.* 
2. Player **plots** surround the catch area (8 plots arranged in a circle). This is where players can place their collected brainrots.
    1. Each plot contains 1 brainrot slot by default, but more slots can be purchased
    2. Brainrots generate passive income (collected by walking over the plot platform)
    3. Players can see and visit each other's plots
3. A ***bag shop*** where players can upgrade their bag, allowing them to capture even higher-level brainrots.

## Tutorial flow:

1. Players spawn at their new, empty plot containing one brainrot slot.
2. They are directed by an arrow beam that directs them to the bag shop, where they purchase the starter bag.
3. They are directed to the *catch area,* ****where they see eye-catching brainrots spawning into the *brainrot tank.* The tank explodes, releasing many brainrots of various rarities, most of which the player cannot yet catch, as they will need to upgrade their bag to do so. 
4. Among the brainrots is one “starter brainrot” (name/model to be chosen) that they are directed (with a beam arrow) to pick up and bring back to their plot and place. 

## Gameplay loop:

1. Every so often, the brainrot chamber explodes, scattering brainrots all over the catch area.
2. Any player with a sufficiently-high-level bag can pick up a brainrot, creating a short burst of fast-paced competition at every explosion where players are racing to pick up the brainrots they want.
3. After collecting brainrots with their bag, players can place them onto their plot, where they become statues that generate passive income. The income is collected by the player by walking over the platform.

## Upgrades:

### Bag upgrades:

1. BagCapacity
2. BagLevel (can pick up brainrots with level ≤ bag level)
3. Cosmetics
4. More to be ideated

### Plot upgrades:

1. Brainrot slots
2. Cosmetics

### **Player upgrades:**

1. Autocollect brainrot passive income
2. Offline income "hours" — num hours where offline income accrues
3. Offline income "multiplier" — multiplier for offline income
4. Global income multipliers
5. Cosmetics

---

## Data & Parameters

### Currency

- Primary currency: **Dollars ($)**
- Robux purchases: To be implemented later

### Brainrots

See `BRAINROTS.md` for the full table of brainrots, their asset locations, and rarities.

**Rarity spawn rates** (when a brainrot spawns):
| Rarity    | Chance |
|-----------|--------|
| Common    | 75%    |
| Uncommon  | 20%    |
| Rare      | 4%     |
| Epic      | 0.9%   |
| Legendary | 0.09%  |
| Mythic    | 0.01%  |

### Tank & Spawning

- **Spawn interval**: 15 seconds (brainrots fall into tank)
- **Explosion interval**: 2 minutes (tank explodes, scattering all brainrots in tank to catch area)
- **Despawn timer**: 30 seconds (uncollected brainrots disappear)
- Players can spawn additional brainrots via a UI element (to be implemented)

### Bag Mechanics

- **Capacity**: Number of brainrots (not weight-based)
- **Duplicates**: Allowed (can hold multiple of same brainrot type)
- **Full bag**: Pickup blocked (cannot pick up more until bag has space)
- **Level gating**: Can only pick up brainrots with level ≤ bag level

### Placed Brainrots

- Brainrots can be swapped/removed after placement
- Income accumulates unlimited (no cap)
- Income collected via one-time walk-over pickup (not continuous)
- Offline income accrues at the same rate as online, for up to 4 hours by default (upgradable)

### Multiplayer

- **Competition**: First-come-first-serve for catching brainrots
- **Visibility**: Players can see and visit all 8 plots

### Economy (Placeholder)

All upgrades cost **$141** (placeholder value to be balanced later)