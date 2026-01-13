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
