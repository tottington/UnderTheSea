# Prerequisites — mr tottington (#2399610)

Derived from the script source (authoritative) cross-referenced against
[greenbox](https://greenbox.loathers.net/?u=2399610) (snapshot: mafia r29114) and the
[prereq sheet](https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit)
linked from the README. Where the sheet and the code disagreed, the code wins.

Bottom line: this account clears every *essential* requirement. Two script
dependencies are not installed yet, and a handful of things greenbox cannot see
need a manual eyeball before you ascend.

---

## 1. Blocking — install these first

| What | Why | Fix (mafia CLI) |
|---|---|---|
| **seedfinder** | `UnderTheSea.ash` line 2 does `import <seedfinder/seedfinder.ash>`. This is a *compile-time* import — without it the script will not even load. | `git checkout https://github.com/VeeArrKoL/seedfinder` |
| **c2t_megg** | `summon()` calls `c2t_megg extract` / `c2t_megg fight` for Chest Mimic egg summons, which is your main summon path (see §4). | `git checkout https://github.com/C2Talon/c2t_megg` |

Both are listed in `dependencies.txt`; neither is present in
`~/Library/Application Support/KoLmafia/git/`. The repos are live and current.

---

## 2. Verified present ✅

**Essential (script cannot run without):**

- packaged Monodent of the Sea
- The Eternity Codpiece — the smuggling trick is worth 50+ turns and the single
  biggest item on the sheet
- Deep Dark Visions, Saucegeyser, Cannelloni Cocoon (all permed)

**High value, all present:**

cursed monkey glove · Cincho de Mayo · lab-grown blood cubic zirconia ·
closed-circuit phone system · book of facts · shrink-wrapped 2002 Mr. Store
Catalog · packaged backup camera · boxed bat wings · Platinum Yendorian Express
Card · boxed Heartstone · Unpeeled Peridot of Peril · wrapped Baseball Diamond ·
in-the-box spring shoes · packaged Everfull Dart Holster · packaged Jurassic
Parka · seal-clubbing club loot box · boxed august scepter · boxed Mayam Calendar ·
packaged miniature crystal ball · new-in-box toy Cupid bow · Möbius ring box ·
boxed Archaeologist's Spade · CyberRealm keycode

**Familiars** — every one the script actually reaches for:
Grouper Groupie, Glover, Foul Ball, Patriotic Eagle, Jill-of-All-Trades,
Chest Mimic, Red-Nosed Snapper, Sword of S Words, Peace Turkey, Disgeist.
(Glover and Foul Ball are the two the sheet marks as *not* supported if missing —
you have both.)

**Skills** — Steely-Eyed Squint, Unaccompanied Miner, Transcendent Olfaction,
Holiday Multitasking, Tongue of the Walrus, OVERCLOCK(10), Just the Facts,
Double-Fisted Skull Smashing, Ambidextrous Funkslinging, Calculate the Universe,
Comprehensive Cartography. All permed.

**Settings** — `autoSatisfyWithNPCs=true` (the script aborts on line ~749
otherwise) and mafia r29114 ≥ the required r29057. Both already correct.

---

## 3. Confirmed missing — all handled, no action needed

Every one of these is behind a `have_item` / `available_amount` guard, so the
script routes around them. Turn costs are the sheet's estimates.

| Missing | Cost | Notes |
|---|---|---|
| McHugeLarge deluxe ski set | ~4+ | Loses left-ski NC force and left-pole sniff. Cincho covers the NC forces. |
| Combat lover's locket | ~5 | `summon()` falls back to fax → Chest Mimic egg → genie wish. This is why c2t_megg matters. |
| Apriling band helmet | ~3 | Was **unguarded** — fixed on this branch (see §6). |
| untorn tearaway pants package | ~6 | Only if you roll a Moxie class; skips the moxie guild quest. |
| undrilled cosmic bowling ball | ~3 | CCS free-kill option. |
| packaged Roman Candelabra | ~1 | One copied free fight. |
| Sealed TakerSpace letter of Marque | ~1 | Workshed free run. |
| assemble-it-yourself Leprecondo | <1 | |
| Rock Garden Guide | ~1 | Only supplies groveling gravel. |
| designer sweatpants | 0 | |
| Camp Scout backpack (allied radio) | 0 | Only matters if short on NC forces. You aren't. |
| April Shower Thoughts shield | — | Spitball fallback only; parka covers the yellow ray. Also was unguarded, fixed. |
| Greatest American Pants · navel ring · V for Vivala mask | — | Free-run alternates. Having none of the three makes `reservedPulls()` hold back 1 extra pull. |
| Jumpsuited Hound Dog | — | `use_familiar("combat")` falls through to Grouper Groupie. |
| Raise Backup Dancer (skill) | — | Was **unguarded** in the NS fight — fixed on this branch. Damage boost only. |

**Workshed:** you have none of Asdon Martin / model train set / portable Mayo
Clinic / TakerSpace, so the workshed stays empty. That means `highShiny()` is
always false and the script takes its standard path throughout — which is the
intended path, not a degraded one. `lowShiny` is also false (you have the 2002
catalog, monkey's paw and august scepter), so you get the full-featured branch.

---

## 4. Greenbox can't see these — check by hand before ascending

These are the real risk items. Each one is a **hard abort** or a silent turn loss.

1. **Congressional Medal of Insanity** — `initialization()` aborts with
   *"Get yer own CMOI, ya filthy animal!"* if it isn't in inventory or storage.
   It's a rare, not an IOTM, so greenbox doesn't track it. **Confirm you own one.**
   The sheet marks CMOI as not-supported-if-missing, and the code agrees.

2. **Clan photo booth** — aborts with *"It seems that your clan may have an
   incomplete photobooth, join BAFH and rerun"* unless it can pull all three of
   sheriff pistol / moustache / badge. Be in a clan with a **complete** booth.
   These drive the Assert Your Authority free kills.

3. **VIP lounge key + stocked lounge** — the sheet marks this
   not-supported-if-missing (3 free kills plus buffs). The colosseum mood asks for
   *Favored by Lyle*, which needs the LI-11 Motor Pool installed in your clan.
   You own the voucher; confirm it's actually installed where you're clanned.

4. **Storage stock** — `initialization()` pulls, and `buy_using_storage()` if
   storage is empty, for: mer-kin sneakmask, sea lasso, shark jumper, scale-mail
   underwear, Flash Liquidizer Ultra Dousing Accessory. Keep meat in storage.

5. **From the README, still true:**
   - All underwater maps done
   - A damp old wallet in storage (saves a turn in `getSandDollar()`)
   - Push *A Mer-kin Graffiti* out of the noncombat queue if you're chasing turncount

6. **Codpiece** — the README says to preload it with an unblemished pearl, but the
   code drives it directly (`codpiece("blood cubic zirconia, peridot of peril")`
   and `codpiece("blood cubic zirconia, heartstone")`) and clears it with
   `codpiece("none")`. Trust the code; no manual loading needed.

---

## 5. Dead code — safe to ignore

`iotm.ash` defines `camo()`, `whitelist()`, `starter()` and `finisher()`, which
carry hardcoded clan IDs and references to the author's other scripts
(`unlockerCCS.ash`, `preadventure.ash`, `generalChoice.ash`, `postloop`).
**None of the four is ever called** by `UnderTheSea.ash`, the CCS, or the choice
adventure script. You do not need those scripts, and you do not need to be
whitelisted in the Dread clans listed there.

---

## 6. Changes made on this branch

| File | Change |
|---|---|
| `UnderTheSea.ash` | `my_id() == 2813285` (the original author's character) replaced with two documented properties: `uts_godRunGuard` and `uts_postloopCommand`. Both default to off. |
| `UnderTheSea.ash` | Apriling band block guarded by `have_item($item[Apriling band helmet])` — previously it fired `aprilband item tuba` unconditionally. |
| `UnderTheSea.ash` | Ski-duffel and April Shower `visit_url` calls guarded by the matching items. |
| `UnderTheSeaCCS.ash` | `use_skill($skill[raise backup dancer])` in the Naughty Sorceress fight guarded by `have_skill` — you don't have it permed. |

Optional config, if you want it:

```
set uts_godRunGuard = true      # abort a sub-17-turn run rather than lose the dreadscroll 7 clue
set uts_postloopCommand = ...   # CLI command to run when the loop finishes
```
