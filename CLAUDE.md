# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important Files

- `GAMEDESIGN.md` - Game design document describing gameplay mechanics and parameters
- `BRAINROTS.md` - Table of all brainrots, asset locations, and rarities
- `PLAN.md` - Implementation plan with checkboxes tracking progress

## Project Overview

DropABrainrot is a Roblox game built using [Rojo](https://rojo.space/docs) for external file syncing with Roblox Studio.

## Development

The place file is maintained separately by the designer. This repo only contains the scripts that get injected via Rojo.

**For human testing only** (Claude should never run this):
```bash
rojo serve  # Syncs scripts to Roblox Studio
```

**Never run `rojo build`** - it will overwrite the designer's place file.

## Architecture

This project uses the standard Rojo project structure defined in `default.project.json`:

- `src/server/` → `ServerScriptService.Server` - Server-side scripts
- `src/client/` → `StarterPlayer.StarterPlayerScripts.Client` - Client-side scripts
- `src/shared/` → `ReplicatedStorage.Shared` - Shared modules accessible by both server and client

## File Naming Conventions

- `*.server.luau` - Server scripts (run only on server)
- `*.client.luau` - Client scripts (run only on client)
- `*.luau` - ModuleScripts (shared code/libraries)
- `init.server.luau` / `init.client.luau` - Entry point scripts that become the parent folder's script

## Asset Locations

- **Brainrot models**: `ServerStorage.Brainrots` - Model names use underscore format (e.g., `Brainrot_God_Lucky_Block`)
- **Wally packages**: `ServerScriptService.Packages` - Server-side dependencies installed via Wally

## Dependencies

Managed via Wally (`wally.toml`):
- `ProfileService` - `alreadypro/profileservice@1.0.4` for player data persistence

Run `wally install` after cloning to fetch dependencies.

## Data Architecture

- `src/shared/Types.luau` - Shared type definitions
- `src/shared/Data/Brainrots.luau` - All 75 brainrot definitions (IDs match ServerStorage model names)
- `src/shared/Data/Bags.luau` - Bag level definitions
- `src/shared/Data/Upgrades.luau` - Upgrade definitions
- `src/shared/PlayerData.luau` - Player data schema and defaults
- `src/server/Services/DataService.luau` - ProfileService-based data persistence

## Git Workflow

1. Create feature branches for new work (e.g., `feature/phase1-data-layer`)
2. Commit changes incrementally with descriptive messages
3. Push and create PRs via `gh pr create`
4. PRs merge into `main`

## Linting

Run `selene src/` to lint. Config is in `selene.toml` with `std = "roblox"`.
