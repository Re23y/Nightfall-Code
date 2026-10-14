# NIGHTFALL — Architecture

**What this is:** one row per system, four short answers each. Not a design document, not
prose. If a row takes more than a sentence per column, the system is probably doing two jobs.

**How it gets filled in:** after you build something, Claude asks you the four questions and
you answer in a sentence. It's a record of decisions you already made, not homework.

**The game design lives in a separate design document, which isn't public.** This file answers
*who owns what*; that one answers *what the game is*. Where a decision here depends on a game
rule, the rule is summarised in place.

**The four questions**

| Question | What it means | Why it matters |
|---|---|---|
| **What does it own?** | The data or objects only this system is allowed to change | Two systems writing the same thing is the #1 source of bugs nobody can trace |
| **Who starts it?** | The event or moment it comes into existence | L7: a loop that ends when a player leaves must *start* when the player arrives |
| **When does it stop?** | The condition that ends it — or "never" | If this doesn't match "who starts it", **it leaks** |
| **What does it need?** | The other systems or data it reads | Long list = too tangled. Circular = it will break in L9 |

---

## Systems built so far

*(From Unit 1. These were built as lesson drills but are real Nightfall systems.)*

### RoundClock — `Lesson5Drill`

| | |
|---|---|
| **Owns** | The round's elapsed time, and which announcements have already fired |
| **Started by** | The server, once, when a round begins |
| **Stops when** | `os.clock() - startTime >= ROUND_LENGTH` |
| **Needs** | `ROUND_LENGTH` (config). Nothing else. |

*Notes: measures against a real clock, so its error is bounded by one tick rather than
accumulating. Announcements are threshold-crossing, so they survive any tick rate.*

### PlayerTracker — `Lesson6Drill`

| | |
|---|---|
| **Owns** | The `alivePlayers` list — the single truth about who is still in the round |
| **Started by** | The server, once, at round start |
| **Stops when** | The round ends (list is cleared/rebuilt) |
| **Needs** | Nothing. Everything it works on is passed in. |

*Notes: takes the list as a parameter rather than reaching for a global, so it can be
tested in isolation and moved into a ModuleScript in L12 unchanged. Hands out copies via
`getDisplayList` so nothing else can corrupt the real list.*

### VoidWatcher — `Lesson7Drill`

| | |
|---|---|
| **Owns** | Nothing. It only reads positions and sets health to 0. |
| **Started by** | The server, once, at startup |
| **Stops when** | Never — the void is always there |
| **Needs** | `Players:GetPlayers()`, read fresh every tick |

*Notes: one loop for all players, not one per player. Looks characters up fresh rather than
capturing them, so respawns need no bookkeeping. The first version was started inside
`CharacterAdded` and leaked one loop per life.*

### HealPad — `Lesson7Drill`

| | |
|---|---|
| **Owns** | Its own cooldown flag (`debounce`) and its colour |
| **Started by** | The server, once, at startup — the pad exists for the server's whole life |
| **Stops when** | Never |
| **Needs** | `Players:GetPlayerFromCharacter` to turn a limb into a player |

*Notes: the `Touched` connection belongs to the **pad**, which exists once — not to the
character, which is replaced on every respawn. Connecting it in `CharacterAdded` would
stack one handler per life.*

### CoverWall — `Lesson8Drill` (server `Script`)

| | |
|---|---|
| **Owns** | The `CoverWall` part. It creates it and is the only thing entitled to decide what is true about it. |
| **Started by** | The server, once, at startup |
| **Stops when** | Never — the wall stands for the whole server session |
| **Needs** | `Workspace.Lobby.Floor`, to sit the wall flush on top of it |

*Notes: position is derived (`floorTop + Size.Y/2`), not hardcoded, so it survives a resize.
At L18 this row changes to "started at round start / destroyed at round end" — and then
something has to own the teardown.*

### CoverCheat — `Lesson8DrillClient` (`LocalScript`)

| | |
|---|---|
| **Owns** | This player's local *view* of the wall. Nothing that matters. |
| **Started by** | This player joining. One copy per player. |
| **Stops when** | This player leaves — or sooner, if the server ever writes `Transparency` or `CanCollide` itself and overwrites the lie |
| **Needs** | The wall, found by name in `Workspace.Lobby`. Nothing else. |

*Notes: built deliberately as an exploit, to find the edge of what a client's lie can do.
The wall stayed solid on the server (verified: server printed `Transparency 0, CanCollide
true` while the client had it hidden) — **and the character still walked through it**,
because the client owns its own character's physics and the server accepts the reported
position. The forever-loop sits at the top level of the LocalScript: starts when the player
joins, ends when the player leaves — questions 2 and 3 match, so it doesn't leak.*

### GameConfig — `ReplicatedStorage.Shared.GameConfig` (ModuleScript) — *was `GameConfigDrill` until 2026-09-29*

| | |
|---|---|
| **Owns** | The *starting values* for every tuned system: round length, announcement marks, void height, pad and cover properties. It owns no running state. |
| **Started by** | The first `require` on each machine. Runs once per machine, then cached. |
| **Stops when** | Never — the cached table lives as long as that machine's session |
| **Needs** | **Nothing, and this is a hard rule.** A config module that requires anything stops being the bottom of the dependency graph, and it's the thing you extract to break a circular require. |

*Notes: lives in `ReplicatedStorage`, so it is published — every client can read it (L8b).
Filed on **secrecy**, not usage: "would a player knowing this hurt us?", never "does the
client currently read it?" — usage changes, secrecy doesn't. Nothing in Nightfall is secret yet,
so `ServerStorage.ServerConfigDrill` exists and is correctly empty. `NAME` constants
(`HealPad`, `CoverWall`) are here because **two machines must agree on a string** — the same
reason remote names will live here at L10.*

**The rule this module enforces:** modules share *code* and *starting values*, never *running
state*. Test any candidate value with one question — **does this change while the game is
running?** If yes, it belongs to one system at runtime, not to config.

### Decided at L9, to be built at L15 — attribute-driven placement

*(George's design, arrived at unprompted while filing config.)* Arena maps carry **invisible
marker parts with attributes** saying what may spawn where, instead of objects being placed
from hardcoded coordinates. That's the L15 tags-and-attributes decoupling pattern, and it's
the right answer for `MapService`. Recorded now so it isn't reinvented — the config file for
it is deliberately **not** created yet, because the system doesn't exist (name files after
what exists, not what you plan).

---

### MapVote — `Lesson10Drill` (server `Script` + `Lesson10ClientDrill`)

| | |
|---|---|
| **Owns** | `votes` — one entry per player, holding which map they picked. Nothing else may write it. The tally is **not** owned, because it is not stored. |
| **Started by** | The remotes: the server, once, at startup. An entry: `PlayerAdded`, plus a `GetPlayers()` catch-up loop for anyone already here. |
| **Stops when** | The remotes: never. An entry: `PlayerRemoving`. At L17 a third lifetime appears — the voting *period* — and only the entries' values reset with it. |
| **Needs** | `GameConfigDrill`, for the remote names, the map whitelist and the player-facing messages. Nothing else. |

*Notes: three remotes, one message each, one direction each — request up, private result down,
public announcement to all. The client sends a **key** from the shared `Maps` whitelist and
never a value, so there is nothing to lie about; the same table also builds the client's menu,
so the two machines' idea of what is legal cannot drift.*

*The tally is **derived on every read**, never stored — so a player leaving needs no
bookkeeping, their vote simply stops being counted. The one thing that must still be sent is a
fresh snapshot on `PlayerRemoving`, or every client keeps displaying a vote that has gone.*

*What it lets the client know: every map name, and every vote cast. Both are public by
design — the client cannot draw a vote menu without them.*

*At L17 this row gains "voting opens at intermission / closes at round start", and **the
remotes must not move into that lifetime** — recreating them each round leaves every client
holding a destroyed object, firing into nothing, with no error. That is also where the winner
stops being derived and becomes a stored decision.*

### SprintZone — `Lesson11Drill` (server `Script`)

| | |
|---|---|
| **Owns** | Nothing. It stores no state; it reads positions and writes `WalkSpeed`. |
| **Started by** | The server, once, at startup |
| **Stops when** | Never — the zone is always there |
| **Needs** | `Players:GetPlayers()`, read fresh every tick; the zone part's position and size; the `WalkSpeed` base + bonus (config) |

*Notes: **the stateless version is the point.** George first built a per-character
stat/source modifier table and it fought him; the version that shipped was reached by
deleting code, not adding it. With no stored state, "died inside the zone, respawned
outside" needs **no** handling at all — the next tick reads where the player actually is.
State you don't keep can't go stale.*

*Two structural decisions worth keeping. `getLiveParts` answers "is there a character worth
acting on?" in exactly one place — exists / has its parts / `Health > 0` — so a corpse, a
missing character and a half-assembled one are all one `nil`. And `applySpeed` **returns
whether it changed** rather than printing, so the caller (which knows *who*) does the
reporting; `applySpeed` mentions no player, no zone and no print, and moves into the
modifier stack unchanged.*

*Known limit, written in the file as a comment: **this breaks the moment any other system
writes `WalkSpeed`.** Absolute writes don't compose — last writer wins, and whoever removes
their effect last stamps their idea of "normal" over everyone else's. Fix is the L15 row.*

### Decided at L11, still unbuilt — the stat modifier stack

George proposed this himself and got most of the way there before we deliberately deferred
it. The design he reached, which stands:

| | |
|---|---|
| **Owns** | Every character's active stat modifiers, and the only function permitted to write a Humanoid stat |
| **Started by** | Per character, in `CharacterAdded` |
| **Stops when** | That character is *removed* — `CharacterRemoving`, not `Died`. Entries must be **deleted**, not just abandoned |
| **Needs** | The stat table (base values), and a recompute from anything that adds or removes a modifier |

*Shape: `state[character][stat][source] = amount`, keyed by **the object that granted it**,
never by a category string — two sprint zones are two keys, with no naming scheme to invent.
A dictionary keyed by source rather than a list makes `add` **idempotent**, which matters
because a sweep loop calls it every tick; `table.insert` would stack the same bonus ten
times a second.*

*Lua has no composite-key syntax — `t[{stat, source}]` stores under a brand-new anonymous
table and is unreachable forever, because tables compare by identity, not contents. Nesting
is how a composite key is spelled. Nest `[stat][source]` rather than `[source][stat]`:
the recompute is the hot path and wants one index straight to the stat's bucket.*

*The rule that makes it worth having: **`WalkSpeed` is written in exactly one function**, and
it is always `BASE + sum(modifiers)`. If the write appears twice, the stack bought nothing.*

*Settled at L17 opening, by George: **the cleanup hangs off `CharacterRemoving`, not `Died`.***
An Instance key is a strong reference, so a table that only grows pins every destroyed character
in memory — invisible in solo testing, found by reasoning rather than by playing. `Died` is the
wrong hook twice over: the corpse Instance still exists when it fires, and it does not fire at
all for a character removed without dying. Three scopes, outside-in: `start()` connects
`Players.PlayerAdded`; that handler connects `player.CharacterRemoving`; that handler does the
delete. **`start()`, not `init()`, because it reaches for `Players`** — a service is something
else, and touching something else is what `start` is for.

*Two things still open on it.* **Does `CharacterRemoving` fire when a player leaves, or only on
respawn?** Unverified — not asserted either way; measure it on a two-player local server at L19.
If it does not, disconnects leak and the `PlayerRemoving` path is required too. And note the
wrinkle George's own L11 key choice creates: **a table keyed by `character` cannot be cleaned
from a player-shaped event.** `PlayerRemoving` hands you a `player`, and `player.Character` may
be `nil` or may already be a *different* character than the one holding entries. The belt-and-
braces answer is cheap because **cleanup is idempotent** — `t[k] = nil` on an absent key costs
nothing, so clean up twice rather than reason about which event won the race.

---

## Unit 3 — the real structure (L12, L13, L14)

*Everything above was a lesson script in a flat folder. From here the tree below
is real, and every row below is a file that exists in `src/`.*

```
ServerScriptService/
  Bootstrap                  -- the ONLY Script on the server
  Server/
    RemoteService            -- ModuleScript
    VoidWatcher              -- ModuleScript
    HealPad                  -- ModuleScript
    SprintZone               -- ModuleScript   (migrated at L14)
    MatchState               -- ModuleScript   (L14)
    StateBoard               -- ModuleScript   (L14)
    CapturePoint             -- ModuleScript   (L14 drill)
    Hazard                   -- ModuleScript   (L15 drill)
  Lessons/                   -- 32 archived lesson scripts, ALL disabled
ReplicatedStorage/
  Shared/
    GameConfig               -- renamed from GameConfigDrill 2026-09-29
    CharacterUtil
    Signal                   -- ModuleScript   (L15)
  Remotes/                   -- built at runtime by RemoteService.init
StarterPlayer/StarterPlayerScripts/
  ClientBootstrap            -- the ONLY LocalScript that starts anything  (L14)
  Client/
    StateWatcher             -- ModuleScript   (L14)
  Lessons/                   -- 7 archived LocalScripts, all disabled
```

### Bootstrap — `ServerScriptService.Bootstrap` (`Script`)

| | |
|---|---|
| **Owns** | The list of systems, and the order they come up in. Nothing else. |
| **Started by** | Roblox, because it is the one remaining `Script`. Everything else is a module that does nothing until this file calls it. |
| **Stops when** | Never |
| **Needs** | Every module under `Server/`. That is the point of it — the dependency list is the file. |

*Two phases, and the invariant between them is the whole design:* **every system's `init()`
finishes before any system's `start()` begins.** So a `start()` may rely on every other
system's `init()` having happened, and **the order of the list stops deciding anything that
`init` built.** Proved by running with `HealPad` listed first and `RemoteService` — whose
`init` it depends on — listed last.

*Tolerates a missing `init` (`if system.init then`), so a system with nothing to build says
so by omission rather than by an empty function.*

*Not yet handled, and it is real: if one system's `init` throws, the loop dies and every
system after it never starts. That is L11's unguarded-error lesson at the architecture
level. **L16.***

### RemoteService — `Server.RemoteService`

| | |
|---|---|
| **Owns** | The `ReplicatedStorage.Remotes` folder and every RemoteEvent in it. Nothing else may create one. |
| **Started by** | `Bootstrap`, in the **init** phase |
| **Stops when** | Never — the remotes outlive every round (see the L10 MapVote note: recreating them per round leaves clients holding destroyed objects) |
| **Needs** | `GameConfig.Remotes`. Nothing else, deliberately. |

*The clearest possible `init`: **nobody waits on it, everybody waits for it**, and every
client is sitting in `WaitForChild` until the folder exists.*

*The folder is filled and then parented — **parent last**, and here it is load-bearing.
A client that sees the folder mid-fill gets `nil` from `FindFirstChild` and a partial set
from `GetChildren`, silently and permanently for that session. Parent-last turns a race into
all-or-nothing: the folder existing becomes a promise that its contents are complete.*

*Systems call `RemoteService.get(name)` and never `ReplicatedStorage.Remotes.X`. The direct
path would hardcode the location into every system and turn a typo into
`attempt to index nil with 'FireAllClients'` from a line that never mentions remotes.*

*What it lets the client know: every remote's name. Unavoidable — the client cannot connect
to a remote it cannot find, and the defence was never the name (L9).*

### CharacterUtil — `ReplicatedStorage.Shared.CharacterUtil`

| | |
|---|---|
| **Owns** | **Nothing, and it never will.** Pure functions of their arguments. |
| **Started by** | Nobody. It has no lifecycle, because it has no state. |
| **Stops when** | n/a |
| **Needs** | Nothing |

*The rule that put it here: **share code that has no owner; never share an owner.**
`getLiveParts` moved because two systems needed it; `distanceBetween` stayed in SprintZone
because one does.*

*In `Shared` rather than `Server` on the **secrecy** test, not the ownership one — nothing
about finding a humanoid is secret, and the client wants this exact function at L22/L23.
Those are two different tests and they decide two different questions.*

### VoidWatcher, HealPad — revised at L12/L13

*Both moved out of `Lesson7Drill` into `Server/`, and both are unchanged in all four
answers — which is the test that the boundary was drawn in the right place. **Moving a
system into the real tree must not change what it owns.***

**Changed:** neither starts itself any more; `Bootstrap` does. Both do their world reads
inside `start()`, not in the module body, so nothing happens at `require` time.
`VoidWatcher` gained `FireAllClients(player.Name)` on `VOID_FALL`; `HealPad` gained
`FireClient(player)` on `HEAL_NOTICE` — a death is public, your healing is not. Both now
**need `RemoteService`**, which is the first real inter-system dependency in the game and
the reason the two phases exist.

*Still true and still the reason `HealPad` is one file: it owns its pad, its cooldown and
its colour. `VoidWatcher` owns nothing.*

---

## Unit 3 continued — the L14 systems

### MatchState — `Server.MatchState`

| | |
|---|---|
| **Owns** | Which phase the match is in, and which changes to it are legal. Nothing else — it creates no Instance and touches no part of the world. |
| **Started by** | `Bootstrap`, in the **start** phase |
| **Stops when** | Never |
| **Needs** | `GameConfig.Match` (state names, durations) and `RemoteService` (to announce). |

*The only file so far that is **pure logic**. That is deliberate: the moment it set a floor
colour it would own a Part, need a lobby, and have to run after whatever builds one. Keeping
it clean means it can be reasoned about without running the game.*

*`_current` is a module-level `local` and the only way in is `MatchState.set`. The
alternative — a field on the returned table — would make every rule in `LEGAL` a suggestion,
because `MatchState.current = "Round"` compiles from any file. **A `local` does not
discourage that, it makes it impossible to type.***

*Two tables, not one:* **`LEGAL` is a rule about the machine (permanent); `NEXT` is a policy
(temporary).** `LEGAL` allows `Loading -> Intermission` as an abort; `NEXT` never takes it.
**Done at L17: `NEXT` is deleted from this file** and lives in `RoundService`, which decides
from player count, timers and who won. `LEGAL` stayed exactly where it is, because it is the
gate *inside* `set` — move it to the caller and `set` becomes unguarded for every other
caller in the game. `MatchState.start()` is now four lines: it fetches its remote and stops.
*`set` returns `false` on an illegal transition rather than erroring: the caller has a bug,
but the machine is still in a good state and taking the caller down would lose a working
match.*

*No `init` — it constructs nothing another system must find.*

### StateBoard — `Server.StateBoard`

| | |
|---|---|
| **Owns** | The lobby floor's colour, and nothing else. |
| **Started by** | `Bootstrap`, in the **start** phase |
| **Stops when** | Never |
| **Needs** | `MatchState` (reads, never writes) and `GameConfig.World.StateBoard`. |

*Deliberately a separate system rather than four lines inside `MatchState` — see above.*

***Rewritten at L15, and it was L15's worked example.*** It used to poll four times a second to
notice something that happens four times a *minute* — 112 checks per 28-second cycle to catch 4
changes. It now reads `MatchState.get()` **once** in `start()` and subscribes to
`MatchState.StateChanged` for everything after that. 33 lines → 25, and no loop.

*`shown` and the `if current ~= shown` check are **gone**, not moved. A signal only fires on a real
change, and the only system that can know a change happened is the one that made it.*

*The catch-up line is load-bearing and is the general rule, not a first-paint hack:*
**read the current value once when you start, subscribe for the changes after that.** Events
describe changes and cannot describe the past, so any system that starts mid-game must ask once
then listen. The rejected alternative — firing a fake `Intermission -> Intermission` transition so
the listener updates — is illegal in `LEGAL` *and* would lie to every other listener on the
signal. **Never fire an event to make a listener catch up.**

### CapturePoint — `Server.CapturePoint` (L14 drill)

| | |
|---|---|
| **Owns** | The capture pad, its state, its progress, and its owner. |
| **Started by** | `Bootstrap`, in the **start** phase |
| **Stops when** | Never |
| **Needs** | `GameConfig.World.CapturePoint`, the lobby floor, `Players`, `CharacterUtil`. |

*Four dependencies, but the template's "three is a warning sign" does not fire:* **config and
pure utilities are not systems.** They own nothing and cannot be in a bad state when asked.
Only the lobby and `Players` are real dependencies.

*Three states with a **branch** — `Capturing` goes to `Captured` or back to `Uncaptured`
depending on what happens. The states partition the progress value with no overlaps and no
gaps: `Uncaptured` means exactly 0, `Captured` means exactly max, `Capturing` means strictly
between.*

*Colour is written inside `set`, not polled — the machine already knows the exact moment it
changed, so it skips the compromise `StateBoard` makes.*

*`onPoint` is rebuilt from scratch every tick (`onPoint = {}`) rather than updated
incrementally. That is what makes a **dead** player, a **disconnected** player and a player
whose character is **still loading** all impossible to leave stranded in it — the table is
derived entirely from what is true this tick. (`table.clear` is the no-garbage version if it
ever matters; L28, not today.)*

*`isOnPoint(position)` takes a position rather than a player, so the containment geometry is
testable with no character in the game — which is how the cylinder maths was verified.*

*The pad may not survive into the final game. **The branching machine is the point**, and
L19 (players loading in, some of whom leave mid-load) and L21 (an elimination that may or may
not end the round) are the same shape.*

### ClientBootstrap — `StarterPlayerScripts.ClientBootstrap` (`LocalScript`)

| | |
|---|---|
| **Owns** | The list of **client** systems and the order they come up in. |
| **Started by** | Roblox, because it is the one LocalScript that isn't archived |
| **Stops when** | Never |
| **Needs** | Every module under `Client/`. |

*The asymmetry that makes this different from the server's `Bootstrap`:* **on the server, the
container you write into is the container you run in. On the client it is not.**
`StarterPlayerScripts` is a *template*; the code runs from a clone in
`Players.<name>.PlayerScripts`. Requiring through the template path works — and hands you a
**second, independent copy** of every module. Proved: `require(A) == require(B)` is `false`.
So this file reaches its systems via `script.Parent.Client`, never via `StarterPlayer`.

*A yield inside any `start()` blocks every system listed **after** it, because the start phase
is a plain `for` loop. Zero cost today with one system; the whole HUD at L22.*

### StateWatcher — `Client.StateWatcher`

**Rewritten at L17 pass 2.** It no longer touches remotes at all.

| | |
|---|---|
| **Owns** | Nothing — deliberately. The attribute **is** the storage: any code on this client can read it at any moment, so a cached local would only be a second copy that can drift. *Don't cache what you can read.* At L22 it will own what the HUD displays, still not the phase itself. |
| **Started by** | `ClientBootstrap`, in the **start** phase. One copy per player, on that player's own machine. It does not loop over players. |
| **Stops when** | This client leaves — and the whole Lua VM goes with it, which is **why** there is nothing to clean up. |
| **Needs** | `GameConfig` only (`MatchStatus.FOLDER_NAME` and the two attribute names). |

*Exists because **module state does not replicate.** The server's `_current` is a `local` in the
server's copy of `MatchState`; no client has ever seen it.*

**Shape: read once, then subscribe.** `applyPhase` and `applyDeadline` are named functions
precisely so each can be **called directly** (the catch-up, the entire point of pass 2) **and
connected** to `GetAttributeChangedSignal` (the future). A subscription can never report what the
value was before you subscribed.

**The clock race — the one thing attributes did not solve.** `workspace:GetServerTimeNow()` returns
**exactly `0`** on a freshly joined client until its clock syncs. The deadline crosses the network
as an *absolute* time, so a client can receive it perfectly and still decode it against a clock it
doesn't have. The phase never broke, because `"Intermission"` needs no interpreter.

*Resolved with two separate pieces, and the split is the lesson:*

| | where | why there |
|---|---|---|
| the **check** | inside `applyDeadline` | it is a precondition of the function, so **both** callers are covered — the direct call and the signal |
| the **wait** | a `task.spawn` in `start()` | a function that reports current state must not contain a delay; and blocking `start()` would block every system after it in `ClientBootstrap`'s loop |

*Rejected: sending a duration instead of a timestamp. It removes the clock dependency and
reintroduces staleness for the late joiner — the exact problem pass 2 exists to fix. George's call,
with that reason.*

*Open nits, neither load-bearing: the clock poll is unbounded (no timeout, no warn — contrast his
own `WaitForChild(…, 5)` two lines up), and `return print(...)` returns print's return value.*
---

## Unit 3 continued — the L15 systems

### Signal — `ReplicatedStorage.Shared.Signal`

| | |
|---|---|
| **Owns** | Nothing. Each signal it makes owns its own listener list, and nothing else can reach that list. |
| **Started by** | Nobody. It has no lifecycle — it is a **factory**, and a signal is created at `require` time by whichever module exposes it. |
| **Stops when** | n/a. An individual **subscription** stops when the subscriber's life ends, via `connection.disconnect()`. |
| **Needs** | Nothing. Pure Luau. |

*In `Shared` rather than `Server` on the secrecy test (nothing about a listener list is secret) and
because the client wants signals at L22. **But note it cannot cross the boundary**: a module
required from two contexts is two copies, so a `Shared` signal is two unrelated objects. Server
signal for server systems, client signal for client systems, RemoteEvent between them.*

*The one sentence:* **a Signal is a RemoteEvent between two systems on the same machine.**
`MatchState.set` now has both lines, side by side — `StateChanged.fire()` for this machine,
`stateRemote:FireAllClients()` for the other.

*The rule for placement:* **create signals at require time, connect to them in `start()`.** A
signal depends on nothing and every `require` in `Bootstrap` finishes before any `init()`, so it
has no ordering problem and needs no phase. Connect in `start()` because `init` means *touch
nothing else*, and connecting to another system's signal is touching another system. **This
corrects a claim made at L13** that the void-fall signal would be the first system genuinely
needing an `init`.

*`fire` uses `task.spawn`, so one listener cannot break the firer or the others — but `task.spawn`
runs the listener **immediately**, not later. That cost a real bug: a listener disconnecting during
`fire` shifted the array under the loop and the next listener was silently skipped (A, B, C ran as
A, C). `fire` walks `table.clone(listeners)`.*

*`connect` returns a handle with `.disconnect()` even though nothing disconnects yet — at L19 a
system will subscribe when a **round** starts and must stop when it ends, and adding the return
value later means editing every caller.*

*Lowercase `connect`/`fire` where Roblox uses `Connect`/`Fire`, deliberately: capital C means a
real `RBXScriptSignal` where `Wait`/`Once` work, lowercase means one of ours.*

### Hazard — `Server.Hazard` (L15 drill)

**Two lifetimes — the first system in the game to have them.**

| | the **system** | one **binding** |
|---|---|---|
| **Owns** | the `bindings` table | that part's `Touched` connection and its debounce flag |
| **Started by** | `Bootstrap`, in the **start** phase | the part gaining the tag, or the opening `GetTagged` sweep |
| **Stops when** | never | the part is untagged, destroyed, or **removed from the DataModel** |
| **Needs** | `CollectionService`, `Players`, `CharacterUtil`, `GameConfig.World.Hazard` | that part's `Damage` attribute |

*`bind`/`unbind` **are** the second lifetime's start and stop. A `bind` with no `unbind` is a start
with no stop.*

***The first system that does not know where its parts are.*** Every earlier world system —
`HealPad`, `SprintZone`, `CapturePoint` — hardcodes `workspace.Lobby` and creates exactly **one**
part at a position baked into config. `Hazard` names no path and counts no parts: it asks
`CollectionService` for a label. **This is the pattern L18 needs**, because `start()` runs at boot
and the map arrives ten minutes later.

*Verified: 50 hazards created at runtime all bound; per-part `Damage` respected (25 vs the
`DEFAULT_DAMAGE` 10 fallback); `RemoveTag` stops damage dead; re-`AddTag` rebinds; destroying the
containing folder produced exactly 52 `unbound` prints and left `GetTagged` at 0; no errors or
warnings for the whole run.*

*Structure worth keeping:* **one table entry per part, with named keys** —
`{ touchConn = ..., debounce = false }`, not parallel tables and not `{ conn, false }`. `unbind` is
then one lookup and one deletion; with parallel tables you must remember to clear all of them and
a forgotten one is a leak nothing reports.

*`Damage` is read **inside** the `Touched` handler rather than cached at bind time, so a designer
can retune a hazard live with no connection and no stale copy.* **Cache a value only if reading it
is expensive or you must react to it changing.**

*The debounce is deliberately **not** an attribute: attributes replicate to every client, and they
persist on the instance — untag a part mid-cooldown and re-tag it and the flag would still be
`true` with nothing left alive to clear it, so the hazard would come back permanently dead.*
**Attributes are for data about the thing in the game world; system bookkeeping stays in the
system.**

*Known limits, both fine for now.* The debounce is per *part*, not per *part, per player*: two
players on one lava pit means one takes the hit and the other is immune until the cooldown ends —
**revisit at L21**. And `DEBOUNCE_TIME = 0.1` is 100 damage per second on a default hazard.

*Also settled here, and it decides L18's teardown:* **destroying an instance disconnects its event
connections** (measured). So the leak is not on the destroy path — it is on **untag** and
**reparent out of the DataModel**, which fire removal while leaving the old connection alive.
Store and disconnect anyway: *do not make correctness depend on someone destroying the right
thing.*

### Attribute-driven placement — the L9 design, now unblocked

The design George arrived at unprompted at L9 (arena maps carrying **invisible marker parts with
attributes** saying what may spawn where, instead of hardcoded coordinates) now has all of its
machinery: tags to find the markers without a path, attributes to carry the per-marker data, and
the measured facts that **a clone keeps its tags** and **destroying a Model fires removal for its
tagged children**. Build it as `MapService` at L18.

---

## Unit 4 — the L17 system

### RoundService — `Server.RoundService` (L17)

| | |
|---|---|
| **Owns** | When the current phase ends (its deadline) and **why** it ended (the reason). Also the sequence policy — `NEXT`, moved here out of `MatchState`. |
| **Started by** | `Bootstrap`, in the **start** phase. `start()` spawns a thread and returns immediately. |
| **Stops when** | Never, for the service. **A phase** starts and ends constantly — that is the second lifetime, and it is exactly what "owns the deadline and the reason" means. |
| **Needs** | `MatchState`, `GameConfig.Match`, `Players`, `RemoteService`. |

*The four questions were answered twice here, and George's first answer to "what does it own"
was `NEXT` — a constant lookup table. **A table of constants cannot be wrong at 3am.** The
sharper form of the question, which got the right answer: what does this system introduce that
can be **stale**? The deadline, and the reason.*

***`NEXT` is deleted from `MatchState` and `LEGAL` is untouched***, which is the L14 decision
paying out exactly as written: the machine's permanent rule stays inside the gate, the game's
policy moves to the system making the decision.

*`Round` keeps its single legal exit. George's reasoning: an aborted round still has a Results
phase, it just carries a different reason. **One exit means one teardown** — the second path out
would mean a second copy of "destroy the map, unfreeze players, clear the alive list", and the
copies drift.*

*Intermission is the shape nothing else in the game has: it must end on **timer AND enough
players**, while `waitForPhaseEnd` can only express **timer OR predicate**. Solved without new
machinery — Intermission carries no early-exit test at all, and one `if` after the wait declines
to advance and lets the loop re-enter Intermission. **An early-exit test can only ever mean
"leave sooner"; nothing in it can mean "wait longer".***

*Round's predicate returns **two** reasons — `WINNER` at one player remaining,
`NOT_ENOUGH_PLAYERS` at zero. Naming an abort a "winner" for an empty server was the bug that
forced the split, and it is the payoff for the predicate returning a reason instead of a boolean.*

*The driver loop's first line is a bare, unconditional `task.wait()`. It does **two** jobs and
both are load-bearing: nothing below it can produce a zero-yield iteration, and it guarantees the
whole `Bootstrap` start phase has finished before anything touches `MatchState`. The second job
only holds while **no `start()` in the codebase yields** — verified file by file at L17. When that
breaks (L24, `DataService` loading a DataStore), the fix is `Bootstrap` firing a signal after its
loop, not a longer wait.*

*Known limit, and it is L17 pass 2: **`publishDeadline` fires a RemoteEvent, so it cannot reach a
player who has not joined yet.** The catch-up publish at server start reaches zero clients, and in
a held Intermission the loop republishes only once per phase — so a late joiner may never learn
the deadline. George made the case for an attribute himself before writing the line that proves
it. `StateWatcher` has the same gap for the state itself: it connects `OnClientEvent` and never
reads an initial value.*

---

### MatchStatus — `Server.MatchStatus` (L17 pass 2) — **BUILT AND VERIFIED**

*Built 2026-09-12, entirely by George.*

| | |
|---|---|
| **Owns** | The status folder in `ReplicatedStorage`, and the **list of which match facts are public** — currently `Phase` and `Deadline`, with L21's winner to follow. It owns the **mirror, never the truth**: `MatchState` owns the phase, `MatchStatus` owns the replicated copy. |
| **Started by** | The server at startup, in `init()` — because clients `WaitForChild` it, and everything a client waits for must exist before any `start()` runs. `RemoteService` is the precedent. |
| **Stops when** | Never. |
| **Needs** | `GameConfig` (folder and attribute names), `MatchState` (the initial phase). |
| **Client knows** | The phase and the phase deadline. Both are already public today via remotes; this changes the transport, not the exposure. |

**The decision that matters: `RoundService` is the single writer.** It calls
`MatchStatus.setPhase()` and `.setDeadline()` from its loop; `MatchStatus` subscribes to
nothing. George chose this over having `MatchStatus` subscribe to `MatchState.StateChanged`,
on the grounds that one writer with one route in is simpler. It is — **and it is correct only
because of an invariant that must be written down:**

> **INVARIANT: `RoundService` is the only caller of `MatchState.set`.**
> True today: `set` is called in exactly one place, `nextState`. If a second system ever calls
> it, the client goes stale and **nothing errors**. At L21, elimination must therefore *ask
> `RoundService` to end the phase*, not set the state itself.

*This change deletes more than it adds: `MatchState` loses `stateRemote`, its `start()` and its
`RemoteService` dependency — transport was its second job — and `STATE_CHANGED` and
`PHASE_DEADLINE` leave `GameConfig.Remotes` entirely. `StateWatcher` stops touching remotes.*

**As built — the two things that differ from the plan, both improvements:**

- The invariant comment sits **directly above `MatchState.set`**, not at the top of the file.
  A rule is read at the point of temptation: the person about to break it is looking at `set`.
  (A second copy heads `RoundService` — the two are about different things, a privilege and a
  restriction, so it isn't one sentence written twice.)
- `publishDeadline` became **`publishStatus`** and writes *both* facts in one place. Phase and
  deadline are two halves of one statement, and publishing them a frame apart leaves a window
  where the client holds a new phase against a stale deadline. Free to do, because re-setting an
  attribute to its existing value fires nothing.

**Verified 2026-09-12:** `[StateWatcher] - Phase is: Intermission` prints on join, one player,
`MIN_PLAYERS = 2`, held Intermission, **no state change** — the case that was impossible before.
Two-player run cycles all four phases and both clients report on join. The `Deadline == 0` branch
was proven by temporarily widening the window.


---

## Unit 4 continued — the L18 system

### MapService — `Server.MapService` (L18) — **BUILT AND VERIFIED**

*Built 2026-09-21, entirely by George. **The first system in the course with two lifetimes**, so it answers the
four questions twice.*

**Lifetime 1 — the service**

| | |
|---|---|
| **Owns** | `previousMap` (which map was played last) and `eligible` (the maps proven to exist, built once). |
| **Started by** | `Bootstrap`, at server start, in `init()`. **No `start()`** — the first purely passive system in the course. Nothing here ever runs on its own; it waits to be asked. |
| **Stops when** | Never. |
| **Needs** | `ServerStorage.Maps`, `GameConfig`. |

**Lifetime 2 — one loaded map**

| | |
|---|---|
| **Owns** | The cloned map Instance in `Workspace` — **the first system that owns an Instance's whole existence**, the right to create it and the duty to destroy it. |
| **Started by** | `RoundService` entering `MapLoad` and calling `load()`. |
| **Stops when** | `RoundService` enters `Intermission` and calls `unload()`. **One call site, not two** — every path back to a new map goes through Intermission. *(Corrected at L19: the abort paths set Intermission **after** `nextState` has branched, so they never reached the Intermission branch and a role abort leaked the map. The one call site is now `RoundService.cleanupRound()`, reached by every path. See RoleService.)* |
| **Needs** | Nothing. |

| | |
|---|---|
| **Client knows** | **The entire map, because it is in `Workspace`.** Geometry, materials and all 8 `SpawnPoints` markers replicate to every client the moment `Parent` is set — including during `MapLoad`, before the round starts. Fine today (a map's layout is not secret). **The constraint this creates for Nightfall:** anything *staged into* the map before or during a round is public by construction — objective progress, role markers, which fusebox is rigged. Under the game's design rules those must live in server state and be told to clients selectively, never parented into the map and hoped about. Rule 5 of this document, and L18 is where it first bites. |

**Decisions worth keeping**

- **`RoundService` does not pass a map name in.** It says "load one". The choosing happens inside
  MapService, where `previousMap` lives. This came out of the plan review: *owned data with no
  function that touches it means a piece is missing* — Lifetime 1 owned `previousMap` and nothing
  read it, which proved the picker belonged here rather than in the caller.
- **`load` returns a boolean, not the Model.** Handing the Instance out would leak ownership
  through the return value: the caller would hold a reference to something MapService is about to
  destroy, and every later system would ask `RoundService` for the map instead of asking
  MapService.
- **`previousMap` holds the config entry, not the clone.** The clone dies every round; "which map
  did we play" has to outlive it.
- **`unload` is idempotent, and clears the reference as well as destroying the Instance.**
  `:Destroy()` does not nil your variable — it unparents and locks the Instance, but the reference
  still reads. The guard and the `currentMap = nil` are one invariant holding each other up:
  without the nil the guard never fires again, without the guard the first call throws.
- **The picker filters, then picks** — it builds a candidate list excluding `previousMap` and
  chooses from that, rather than choosing and retrying on a clash. Rewritten from a recursive
  retry version, which terminated with probability 1 but had **no bound**. The `#eligible == 1`
  early return survived the rewrite and changed jobs: it used to prevent infinite recursion, it
  now prevents `math.random(1, 0)`.
- **`load` re-validates the template at runtime and warns if it has gone.** A consequence of
  `eligible` holding config entries rather than template Instances, so the lookup still exists.
  Documented as a deliberate trade: the check is defensive rather than structural, and the two
  warns deliberately say `during init` vs `during runtime` — same failure, very different meanings.
- **A lever is silent, an alarm is loud.** `ENABLED = false` skips silently; a map named in config
  with no model in `ServerStorage` warns at every server start. `Tower` is still in
  `GameConfig.Maps.Catalog` with no model, deliberately, as the standing test of this.

**This is the lesson that made `MAP_LOAD -> INTERMISSION` real.** George wrote that second legal
exit into `MatchState.LEGAL` at L14 with nothing in the game able to reach it, and §4's argument
for a passive MapService was that a signal-driven one never could — a function call returns, a
signal handler doesn't. Verified firing 2026-09-21 with both maps disabled.

**Gap CLOSED at L19 (2026-09-25).** `getSpawnPoints()` written by George. Returns `nil, reason` on
all three failure paths — no map loaded, no `SpawnPoints` folder, folder empty — and the array
otherwise, so one caller-side check (`if not spawnPoints then`) catches every case.

- **The return shape was argued for, not assumed.** His first version returned `{}` for "no map
  loaded" and `nil` for the two fault cases — the inverse of his own stated design. **His own
  caller code proved it wrong**: he wrote `if spawnPoints == nil or spawnPoints == {} then`, which
  can never be true, because `{}` constructs a fresh table and `==` on tables compares identity.
  `{}` is also truthy, so it slips past `if not x`, the check a caller would naturally write.
  Rule out of it: **three failure paths, one return shape.**
- **`isUsable` became a pure predicate returning `ok, reason`** — the first multiple-return
  function written in this course. The warns moved to the call sites, restoring the `at init` /
  `at runtime` distinction he invented at L18, now with a varying reason as well as a varying
  moment. `ENABLED = false` returns its own reason, keeping the silent lever separate from faults.
- **`init` now validates that each template has a `SpawnPoints` folder**, not merely that the
  template exists — his own L18 validate-config-against-the-world argument, one level deeper. A map
  that loads but that nobody can be placed on is a broken round, and that belongs at server start.

**Verified 2026-09-25** by reading the console directly, not on report: `2 eligible map(s) found`,
one Tower warning at init, `No map loaded` on the transition into `MapLoad`, `8` on the three
transitions where a map is live, no errors at any boundary.

**Parked, not biting:** `init` does `table.insert(eligible, …)` without clearing first, so calling
it twice would yield four maps. Bootstrap calls it once. Same idempotency question George raised
himself about `unload` at L18.

**Verified 2026-09-21:** four-round run alternating `Ruins, Castle, Ruins, Castle` with no
orphans; `Workspace.Castle.Floor` inspected in the running server at `400, 0, 0` against a
template built at `0, 0, 400`, proving `PivotTo`; one-map run loading `Castle` repeatedly without
hanging; zero-map run printing `No eligible maps available` and taking the abort edge on an ~8s
cycle without ever reaching `Round`.

---

## Unit 4 continued — the L19 system

### RoleService — `Server.RoleService` (L19) — **BUILT AND VERIFIED**

*Built 2026-10-02, entirely by George, from a plan reviewed over four passes.*

| | the **system** | one **entry** (`roles[player]`) |
|---|---|---|
| **Owns** | the role table | that player's role for this round |
| **Started by** | `Bootstrap` calling `start()` (connects `PlayerRemoving`) | `roleSelect()`, called by `RoundService` on entering `MapLoad` |
| **Stops when** | never | the round's cleanup (`roleClear`, on **every** path back to Intermission), or the player leaves |
| **Needs** | `Players`, `GameConfig.Roles` | nothing |
| **Client knows** | **Nothing.** No remote, no attribute. Telling each client its own role is `RoleChannel`'s job. |

**Decisions worth keeping**

- **Deal by pick-and-remove**, not per-player rolls. Each capped slot draws a random index from
  the live `GetPlayers()` list (a fresh table per call, so it is the copy) and removes it;
  whoever is left is a Civilian. Rolling per player only *caps* a role and can produce a round with
  no Murderer; the design needs an **exact** count (the killer count is announced at
  round start). `checkRoleReachedLimit` was planned and cut because the deal can't overfill.
- **Counts:** `max(floor(players / PLAYERS_PER_SLOT), MIN_SLOTS)` per capped role. Named
  *players per slot*, so the name says which way the ratio runs.
- **The guard runs before any role is dealt**, so a failed `roleSelect` leaves nothing behind —
  no half-filled table. Total slots > players returns `false` rather than letting
  `math.random(1, 0)` throw inside `RoundService`'s loop and kill it for good.
- **`getPlayerRole` returns `nil` for "no role this round"**, not a `"None"` string. George first
  chose `"None"`, predicted himself that it is truthy (`if getPlayerRole(p) then` would arm a
  lobby player), and switched. `nil` is free from the table lookup, can only mean one thing here
  (failures error, they don't return), and becomes `Role?` at L20.
- **A server-side getter does not break the information boundary.** The boundary is what crosses
  the wire; the risk lives in whoever calls the getter and what they send. That is why
  `RoleChannel` is a separate file.
- **`Civilian`, not `Innocent`.** In the game design, *innocents* means Civilians **and** Sheriffs, which
  is exactly the group the L25 win check counts.

**The `RoundService` change it forced — one cleanup, every path.** `nextState` reads the state once
and branches, so an abort that sets `Intermission` *afterwards* never reaches the Intermission
branch. First version leaked the map on a role abort; reordering (roles first, cheaper to fail)
then leaked roles on a map abort. Settled as two local functions: **`cleanupRound()`** (the one
place round-lifetime state is cleared) and **`enterIntermission()`** (set + cleanup, used by every
abort). L25/L26/L28 each add one line to `cleanupRound`; a new abort path is one call.

**Verified 2026-10-02:** two-client run dealt `Murderer` / `Sheriff` and loaded the map after.
Claude ran both abort paths solo with temporary config: roles fail → no map loaded, `Roles
cleared`; roles succeed + map fails → `Roles cleared`, Workspace empty. Config restored after.

---

## Rules this document exists to enforce

1. **One owner per piece of data.** If two systems both write it, one of them is wrong.
2. **"Started by" and "stops when" must be about the same thing.** Mismatch = leak.
3. **The client owns nothing that matters.** From L8: it displays, it requests, it never
   decides. Anything a client "owns" is a suggestion the server may ignore.
4. **A long "needs" list is a warning.** Three or more dependencies usually means the system
   should be split, or something should be passed in rather than fetched.
5. **Every system also answers: what does it let the client KNOW?** *(From L8b.)* Anything
   replicated is public — not hard to get, public. Validation defends against *doing*
   something illegal; only **not replicating** defends against *knowing* something. Wallhack
   and aimbot live entirely in the second category. So for any system that puts data or
   objects where a client can see them, the design question is not "can they abuse this?"
   but "should they have it at all?" Hits MapService (L18), SpectateController (L33) and
   anything that stages a round before it starts.

6. **`RoleService` and `RoleChannel` are deliberately two systems.** One owns *who is what*; the
   other owns *who is told what*. Splitting them means the question "could this leak?" has exactly
   one file to audit, and it is the file whose entire job is that question. Merging them would put
   the most dangerous data in the game in the same place as every convenience accessor that wants
   to read it.
