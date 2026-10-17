# UnderTheSea
11,037 Leagues Under the Sea loop.

`git checkout Astro3207/UnderTheSea`

## Hard requirements

- **KoLmafia r29057 or newer.**
- **`autoSatisfyWithNPCs = true`** in mafia's preferences.
- **A clan with a stocked photobooth** — the script claims the three sheriff
  props daily and aborts if the booth is empty.
- **Aftercore mode (running the sea outside the path):** The script prompts for which boss to fight.
- **A Monodent of the Sea.**
- **The Eternity Codpiece**, loaded with unblemished pearls before
  ascending. 
- **A Congressional Medal of Insanity** 
- **3 Familiars** Grouper Groupie, Glover, Foul Ball

## Options

| Command | What it does |
|---|---|
| `UnderTheSea` | Runs the loop: the full run, from initialization through the sorceress. |
| `UnderTheSea sim` | Checklist only: prints which supported IOTMs, skills and familiars you own and which pulls are stocked in Hagnk's. Nothing is pulled, fought or spent; use it before ascending to build a shopping list. |
| `UnderTheSea postloop` | Runs only the postloop steps — the pilsner drain, the first codpiece pass, the screech rundown, the pearlo pearl farm, the final codpiece pass and `uts_postloopCommand` — and none of the run. Use it to exercise the `uts_postLoop*` preferences on a finished account, where a bare `UnderTheSea` would start an aftercore Sea run instead. Each step still self-gates on its own preference. |

Preferences, set once in the gCLI; all default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |
| `set uts_usePilsners = true` | After the run, drink out your astral pilsners — cracking six-packs as it goes, under Ode to Booze — so the supply turns into adventures for whatever you run next instead of sitting in the bag. Empties Hagnk's first when the supply is sitting there, and runs first, before the codpiece prep and the screech rundown, so an abort in either still leaves the supply drunk. Without it, the screech rundown still drinks one pilsner whenever it runs out of adventures, and `uts_postLoopFarmPearls` drinks the whole held supply before calling pearlo, both within the same liver limit. Leaves out any liver capacity that equipment or the familiar is lending, so the next script's re-dress can't leave you falling-down drunk. It does spend liver: a pilsner is at most 11 adventures, 12 under Ode, for one drunkenness — worse than most aftercore booze — and ⭐garbo⭐ has its own `garbo_usePilsners`, so you want one or the other, not both. |
| `set uts_postLoopRunOutEagleBanish = true` | **Experimental.** After the run finishes, keep adventuring until the patriotic eagle's Patriotic Screech stops banishing the construct phylum, which can make other scripts (⭐garbo⭐) misbehave. Empties Hagnk's first, then burns the turns in the pearl zones (18 res, then +combat) until the screech recharges, and screeches in the Smut Orc Logging Camp. Any pearl progress it makes is kept for the pearl farm. |
| `set uts_postLoopFarmPearls = true` | After the run (and after the first codpiece pass and the screech rundown, if enabled), farm the day's unblemished pearls with [pearlo](https://github.com/xn/pearlo). pearlo prices each zone against your `valueOfAdventure` (UnderTheSea passes `voa=4000` when it's 0 or less and `pearlo_voa` is unset) and skips zones that don't pay. Empties Hagnk's first, then drinks your held astral pilsners within your own liver (not liver lent by gear or the familiar), since pearlo never drinks; adventures pearlo leaves go to `uts_postloopCommand`. Your own `pearlo_*` preferences apply to this call too. pearlo installs as a dependency of UnderTheSea; if it's missing, the postloop prints the install command (`git checkout xn/pearlo release`) and skips the farm. Prints which of the five pearls are claimed today afterwards. If pearlo aborts, the final codpiece pass and `uts_postloopCommand` don't run either. |
| `set uts_postLoopCloverFishy = true` | With `uts_postLoopFarmPearls`, passes pearlo's `luckyfishy`, so it refreshes Fishy with Lucky! trips to The Brinier Deepers from its own wider list of Lucky! sources (see pearlo's README, "Fishy refreshes"). With `uts_postLoopRunOutEagleBanish`, the rundown does the same when it runs out of Fishy: free Aug. 2nd casts first, then an 11-leaf clover from inventory or, with `autoSatisfyWithCoinmasters` enabled, the hermit's three a day; when none of those can be used, the rundown stops. Does nothing without one of those two. |
| `set uts_pearloArgs = <arguments>` | Extra arguments appended to the postloop's `pearlo` call, e.g. `potionprice=2000 mombuff=true`, with extra spaces trimmed. A `voa`, `luckyfishy` or `!luckyfishy` here replaces the one UnderTheSea would add. `pearlo help` lists them all; pearlo rejects unknown or repeated arguments, which skips the farm. |
| `set uts_postLoopPrepCodpiece = true` | After the run, load The Eternity Codpiece with five unblemished pearls for your next ascension, in two passes; a codpiece already holding five is left alone. The first pass runs right after the pilsner drain, before the screech rundown and the pearlo farm can abort: it empties Hagnk's (`pull all`) and buys pearls if you're short. With five between the codpiece and your inventory it takes the gems out and slots five pearls; otherwise it notes the count, leaves the codpiece as it is, and leaves the rest to the second pass. The second runs after the pearlo farm, does the same with the farmed pearls, and aborts if it still can't reach five. Buying from the mall needs `autoSatisfyWithMall = true` and an `autoBuyPriceLimit` at or above the pearl's mall price (mafia's default limit of 20000 is below it). |

## High shiny, low shiny

The script sorts your account into a resource tier and routes accordingly:

- **Low shiny** — you own none of the 2002 Mr. Store Catalog, cursed monkey's
  paw or august scepter. The script assumes pulls are precious and farms
  drops it would otherwise pull or wish for, and leans harder on the
  Congressional Medal of Insanity.
- **High shiny** — an Asdon Martin workshed plus
  `garbo_valueOfFreeFight > valueOfAdventure`: your free fights are worth
  more to aftercore meat farming than to the run, so the script *conserves*
  free kills, copies and maps for after the loop instead of spending them
  in-run, taking a slightly longer run for more profitable days.
- **Neither** (mid shiny) — every daily resource gets spent on making the run
  as short as possible.

## Things to prepare BEFORE ascending

- Load up the codpiece with unblemished pearls
- Have all of the underwater maps done
- Have a damp old wallet (not required but saves a turn)
- Have black crayon golem and unholy diver in the combat lover's locket
  (optional — the summon ladder uses fax, locket, mimic egg or genie,
  whichever is available otherwise)
- Familiars: Grouper groupie, glover, foul ball
- For a competitive turn count: push the noncombat A Mer-kin Graffiti out of
  the noncombat queue

## Important IOTMs

| IOTM | Why it matters |
|---|---|
| closed-circuit pay phone | With Monodent, free shadow-rift fights allow free sea lasso training. |
| CyberRealm keycode | Free Mom quest. |
| cursed monkey's paw | Free sea lassos and sea cowbells for the seahorse taming instead of farming them. |
| Book of Facts | Just the Facts wishes and Monster Habitats copy chains cut the adventures needed to find Mom in The Caliginous Abyss |
| patriotic eagle (hatchling) | Patriotic Screech in combation with Cyberrealm |

Useful but relatively strict on item requirement Ploop alternative for this script: https://github.com/UtoTurtMcGurt/LoopTheSea

If you are having the issue of it getting caught on the initial NC, there is nothing that can be done right now. You have to hit it manually or add ``visit_url("main.php"); run_choice(1);`` to the end of your preascension script.


Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
