# NIGHTFALL

A round-based hidden-role game for Roblox, in development. Most players are Civilians, one is the
Sheriff and one is the Murderer, and nobody knows who is who. The map starts dark: Civilians win
by restoring its power, or when the Sheriff kills the Murderer. The Murderer wins by killing
everyone, or by running out the clock.

## Status

**What's built is the server-side round framework, not the game yet.** The server cycles
Intermission → MapLoad → Round → Results. It waits for enough players, loads a random map (never
the one just played), deals roles in secret, ends a round early if players leave, and cleans up
the map and the roles on every path back to the lobby. The phase and its countdown are sent to
every client, including players who join mid-round.

Not built yet: telling each player their role, combat, the power objectives, lighting, UI and
saving.

## How it's being made

I'm learning Roblox development with an AI tutor. I'd used Roblox Studio and written a few small
scripts before, but not much, so I asked to be taught from the very basics and not skip anything.
The tutor demonstrates a pattern once; I plan each system in plain English (what it owns, what starts it,
when it stops, what it needs), write it, and fix what the tutor's review finds. The table below
says who wrote each file.

## The systems

| File | What it does | Written by |
|---|---|---|
| `Server/RoundService` | The match loop: phase transitions, early-end reasons, one cleanup for every abort | Me (the timed-wait helper is the tutor's) |
| `Server/MapService` | Clones a map in from `ServerStorage`, no repeats, validates maps at startup, destroys it at round end | Me |
| `Server/RoleService` | Deals roles so counts are exact and scale with player count; deals nothing if it can't deal all | Me |
| `Server/MatchStatus` | Publishes the phase and deadline as attributes, so late joiners get them | Me |
| `Client/StateWatcher` | Reads the phase and deadline on join, then follows changes; waits for the client's clock to sync | Me |
| `ClientBootstrap` | Starts every client system | Me |
| `Server/CapturePoint` | A three-state capture zone with a cylinder containment test; the future power-box objective | Me |
| `Server/Hazard` | Damage parts found by `CollectionService` tag, bound and unbound as parts come and go | Me |
| `Server/HealPad`, `Server/SprintZone` | Lobby test systems from an earlier version of the project | Me |
| `Server/VoidWatcher` | Kills players who fall out of the world | Me; moved into module form by the tutor |
| `Shared/GameConfig` | Every tuned value and shared name, in one place | Me |
| `Shared/CharacterUtil` | `getLiveParts`: one answer to "is this character worth acting on?" | My function; moved into a shared module by the tutor |
| `Server/MatchState` | The state machine: private current state, a table of legal transitions | Tutor; since changed by me |
| `Shared/Signal` | A small event object so server systems can talk without knowing each other | Tutor |
| `Bootstrap` | Starts every server system in two phases: every `init()` before any `start()` | Tutor; systems added by me |
| `Server/RemoteService` | Creates every RemoteEvent before any client looks for one | Tutor |
| `Server/StateBoard` | Colours the lobby floor by phase | Tutor; rewired to use `Signal` by me |

[`ARCHITECTURE.md`](ARCHITECTURE.md) records, for every system, what it owns, what starts it,
when it stops and what it needs, plus the decisions behind each one.

## Layout

The folders mirror where each script lives in Studio.

```
src/
  ServerScriptService/
    Bootstrap.server.luau      the only server Script
    Server/                    one ModuleScript per server system
  ReplicatedStorage/
    Shared/                    code and config both machines use
  StarterPlayer/StarterPlayerScripts/
    ClientBootstrap.client.luau
    Client/                    one ModuleScript per client system
```

`.server.luau` is a Script, `.client.luau` a LocalScript, and plain `.luau` a ModuleScript.

## Running it

Needs [Rokit](https://github.com/rojo-rbx/rokit). Then:

```
rokit install
rojo build -o NIGHTFALL.rbxl
```

**The maps and the lobby are not in this repo.** They were built by hand in Studio. The scripts
expect `Workspace.Lobby.Floor`, and `ServerStorage.Maps` holding maps that each have a
`SpawnPoints` folder, so a place built from this repo alone won't start a round.

`rojo serve` also works with the Rojo Studio plugin. The project only manages the script folders
above, so nothing else in the place is touched.
