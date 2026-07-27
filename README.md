# UnderTheSea
11,037 Leagues Under the Sea loop.

`git checkout Astro3207/UnderTheSea`

Installing through mafia's `git checkout` also installs
[seedfinder](https://github.com/VeeArrKoL/seedfinder) from `dependencies.txt`.
Run `verify UnderTheSea.ash` in the gCLI after installing — a clean verify
means every dependency landed.

## Hard requirements

The script aborts early and loudly when one of these is missing, so check the
list before starting a run:

- **KoLmafia r29057 or newer.**
- **seedfinder** installed (see above). It solves the dreadscroll from the
  clues instead of guessing.
- **`autoSatisfyWithNPCs = true`** in mafia's preferences.
- **A clan with a stocked photobooth** — the script claims the three sheriff
  props daily and aborts if the booth is empty (it will suggest one).
- **A Congressional Medal of Insanity** in storage. The script refuses to buy
  one for you.
- **Aftercore mode (running the sea outside the path):** at least 4 fullness
  and 5 spleen free at start; the script prompts for which boss to fight.

Everything else in the script is ownership-guarded: an IOTM you don't own is
skipped, and the route falls back to slower alternatives.

## Options

Set once in the gCLI; both default to off:

| Preference | What it does |
|---|---|
| `set uts_godRunGuard = true` | Abort at ≤17 turns played if the dreadscroll 7 clue is still unknown, so you can eat a sushi for it instead of burning a record attempt. Only worth enabling if you are chasing a top turncount. |
| `set uts_postloopCommand = <command>` | CLI command to run once the loop finishes (e.g. a farming script). Leave empty to skip. |

## High shiny, low shiny

The script sorts your account into a resource tier and routes accordingly:

- **Low shiny** — you own none of the 2002 Mr. Store Catalog, cursed monkey's
  paw or august scepter. The script assumes pulls are precious and farms
  drops it would otherwise pull or wish for, and leans harder on the
  Congressional Medal of Insanity for +item.
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
  whichever is available)
- Familiars: Grouper Groupie, Glover, Foul Ball
- For a competitive turn count: push the noncombat A Mer-kin Graffiti out of
  the noncombat queue

## What the script pulls

Ronin allows 20 pulls a day and the script manages them itself, including
holding slots back for items it knows it will need later (`reservedPulls()`).
Mall purchases into storage respect `autoBuyPriceLimit` and confirm before
exceeding it.

At the start of each run the script logs a pull checklist: what is already
stocked in Hagnk's, what will be mall-bought if the route needs it, and — in
red — anything absent that cannot be bought and should be acquired ahead of
time.

Each table is ranked by **Turns saved** — what the run loses doing without
that pull (farming the item instead, or skipping what it enables). Cleanup
pulls pay out the *next* day and are marked accordingly. Same methodology
note as the IOTM tables below: estimates overlap and do not sum.

### Pulled early, every run

| Item | Turns saved | Why |
|---|---|---|
| Congressional Medal of Insanity | 1–2 | Large +item accessory worn through most farming; must already be in storage — the script won't buy one |
| sea lasso | 1–2 | Lasso training toward 20 and seahorse taming; skipped when the Sword of S Words plan or monkey's paw wishes will supply them |
| Mer-kin sneakmask | ~1 | Underwater-legal −combat hat for every noncombat hunt (outpost, pearl zones) |
| shark jumper | ~1 | Underwater +item shirt for the Caliginous Abyss and copy fights |
| scale-mail underwear | ~1 | Underwater +item pants, same fights |
| Flash Liquidizer Ultra Dousing Accessory | ~1 | Douse Foe procs on the shadow slab during the pay-phone free fights |

### Pulled when the route needs them

| Item | Turns saved | Why |
|---|---|---|
| Mer-kin prayerbeads | 3–5 | Yog-Urt: three equipped means only two healing items to shed Suckrament |
| sea cowbell | 2–3 | Seahorse taming needs three thrown |
| null-day exploit | 1–2 | Null afternoon replaces crayon shavings as the Shub/colosseum deleveler |
| Mer-kin digpick | 1–2 | Mine teflon ore for the swim fins tailpiece; also flags miner fights as killable |
| comb jelly | 1–2 | Jelly Combed +item buff before Abyss and corral trips |
| Mer-kin healscroll | 1–2 | Dreadscroll clue 2 (thrown in the library) and a Yog-Urt healing item |
| Mer-kin killscroll | 1–2 | Dreadscroll clue 5 (thrown at a mer-kin) |
| pro skateboard | 1–2 | Do an epic McTwist forces the corral opener's drops |
| fish sauce / Aldebaran sardines / cheapest pasta | 1–2 | Keeping Fishy up (diet path depends on gear owned) |
| lodestone | ~1 | Loded effect: extra mining attempts after Unaccompanied Miner's five run out |
| Elf Guard SCUBA tank | ~1 | Waterbreathing gear that frees the pants slot during habitat fights and the lasso backup plan |
| rusty rivet | ~1 | Tops the diver hunt up to 8 when one short |
| Mer-kin worktea | ~1 | Dreadscroll clue 7 via the sushi meal |
| Mer-kin knucklebone | ~1 | Dreadscroll clue 4 on use |
| Mer-kin cheatsheet | ~1 | Tops up the 9-sheet vocabulary grind |
| Mer-kin hallpass | ~1 | Steers the elementary school noncombat cycle |
| Mer-kin hidepaint | ~1 | Colorfully Concealed −combat for the Grandpa noncombat hunt |
| software glitch | ~1 | Corral opener: swaps the fight for the Bugged bugbear |
| pulled yellow taffy | ~1 | Yellow-ray combat item for the corral opener |
| waffle | ~1 | Re-rolls a monster in place: seahorse phase and peanut fights |
| skate blade | ~1 | Skate Park war gear for the Holey Rollers resolution |
| New Age healing crystal / soggy used band-aid | ~1 | Yog-Urt healing when prayerbeads are short |
| damp old wallet | ~1 | Sand dollars for the Old Guy's boot without spending a clover adventure |
| pie man was not meant to eat | ~1 | One-pull Asdon Martin fuel for Driving Waterproofly |
| Handheld Allied radio / Clara's bell / stench jelly | ~1 | Noncombat forcer of last resort, only when no forcer IOTM is owned |

### End-of-run cleanup pulls (whatever slots remain)

| Item | Turns saved | Why |
|---|---|---|
| peppermint parasol | ~1 (next day) | Three free runaways for the next day's farming |
| ink bladder | <1 (next day) | Underwater free-run combat item |
| Mer-kin pinkslip | <1 (next day) | Free-run item that works on any mer-kin |
| stuffed yam stinkbomb | <1 | Banishing free run |
| Louder Than Bomb | <1 (next day) | Banishing free run |
| anchor bomb | <1 (next day) | Banishing free run (TakerSpace) |

## IOTMs the script uses

None are strictly required — every use is guarded — but turn count scales
with what you own. At the start of each run the script logs which of these
your account owns and which are missing, as a shopping list for future
acquisitions.

Each table is ranked by **Turns saved**: an estimate of the turns a run
loses without *just* that item, the rest of the kit held constant, modeled
against a measured 47-turn reference run. The estimates overlap heavily —
they price individual purchases, they do not sum.

### The most important ones

These carry the route. Missing one of them doesn't stop the run, but it
changes how whole phases play out:

| IOTM | Turns saved | Why it matters |
|---|---|---|
| Fourth of May Cosplay Saber | 4–6 | Use the Force: deterministic diver, sea cow, prayerbead and scroll drops via the Force budget ladder |
| closed-circuit pay phone | 4–6 | Eleven free shadow fights a day carry the whole lasso-training block; several route branches key on owning it |
| cursed monkey's paw | 2–4 | Wishes replace whole corral farming loops (lasso, cowbell); selects the summon-based diver plan |
| 2002 Mr. Store Catalog | 2–4 | Spooky VHS copies, the pro skateboard's McTwist, software glitch — the corral opener and Mom-rescue copies come from here |
| monodent of the sea | 2–3 | The underwater weapon the route lives in: lightning-bolt banishes shape the corral and outpost pools, and it anchors most farming outfits |
| book of facts | 2–3 | Just the Facts wishes and Monster Habitats copy chains for the Mom rescue |
| august scepter | 1–2 | Waffles re-roll monsters in place; Aug. 2nd is a free Lucky!; the script's resource tiering keys on the catalog/paw/scepter trio |
| patriotic eagle (hatchling) | 1–2 | RWB blast forces the flytrap pellet; phylum screech banishes constructs; Cyberzone partner |

### Route drivers (each worth multiple turns)

| IOTM | Turns saved | Why it's used |
|---|---|---|
| Jurassic Parka | 2–3 | Dilophosaur yellow ray; spikolodon spikes force noncombats |
| McHugeLarge duffel bag | 2–3 | Avalanche noncombat force; left pole tracks squid/tippler; slash olfaction |
| Apriling band helmet | 2–3 | Tuba noncombat forces; patrol beat −combat |
| CyberRealm keycode | 1–2 | Cyberzone 1 free fights drive Mom-rescue progress |
| Peridot of Peril | 1–2 | One forced encounter per zone per day, aimed by `zoneTarget()` |
| Comprehensive Cartography | 1–2 | Three more forced encounters (Map the Monsters), same targeting |
| backup camera | 1–2 | Copies: golem stat-chains and lockkey-monster repeats |
| blood cubic zirconia | 1–2 | Sweat Bullets free kills; Refracted Gaze substat farming on free fights |
| baseball diamond | 1–2 | Team pitches: yellow ray, free kill and banish outcomes |
| Cincho de Mayo | 1–2 | Fiesta Exit noncombat forces, recharged through free rests |
| bat wings | 1–2 | Five free fights, swoop, and upside-down free rests |
| Heartstone | ~1 | %banish skill plus the Ultraheart colosseum buff |
| spring shoes | ~1 | Spring Kick banish and Spring Away free runs |
| Everfull Dart Holster | ~1 | Bullseye free kills once the perk set supports them |
| Mayam Calendar | ~1 | Daily ring resources claimed at initialization |
| Leprecondo | <1 | Passive furniture buffs, need-ordered install |
| April Shower Thoughts shield | <1 | Spitball yellow ray fallback; daily glob claim |

### Copy and free-turn engines

| IOTM | Turns saved | Why it's used |
|---|---|---|
| tearaway pants | 3–4 | Skips the moxie guild test; Tear Away banishes plants |
| Time-Spinner | 1–2 | Guaranteed re-fight of a just-fought target for one turn |
| Source Terminal | 1–2 | items.enh +item buff; duplicate.edu doubles the diver's (or cow's) table |
| emotion chip | 1–2 | Feel Hatred banish; Feel Nostalgic re-rolls a copied drop table |
| Lil' Doctor™ bag | 1–2 | Chest X-Ray free kills, Otoscope +200% item, Reflex Hammer banish |
| Meteor Lore (Macrometeorite) | 1–2 | Ten monster re-rolls a day from a skill, no gear slot |
| a workshed | 1–2 | Asdon: Driving Waterproofly; train set: resources; TakerSpace: anchor bomb; Mayo Clinic |
| January's Garbage Tote | ~1 | The champagne bottle doubles the item bonus at roll-heavy zones |
| combat lover's locket | ~1 | Diver and golem summons |
| miniature crystal ball | ~1 | Predicts the corral so seahorse attempts aren't wasted |
| autumn-aton | ~1 | Background farming (digpick zone, shadow rift) while you adventure |
| Kremlin's Greatest Briefcase | ~1 | Items Are Forever +50% item for 50 turns (needs the case opened) |
| Eight Days a Week Pill Keeper | ~1 | Free pill: Fidoxene familiar-weight floor, or Sneakisol as a forcer |
| Sept-Ember Censer | ~1 | Septapus charms: seven pickpockets against the shadow slab |
| vampyric cloake | ~1 | Become a Bat: +50% item per farming fight, ten a day |
| clan photobooth | ~1 | Sheriff set: Assert Your Authority free kills |
| Powerful Glove | 0–1 | Monster re-rolls when Macrometeorite casts run out |
| mumming trunk | <1 | Prince George: +item that lasts until rollover, not N turns |
| Cargo Cultist Shorts | <1 | Pocket 494: Vinegavotte, +20% item for 50 turns |
| knock-off retro superhero cape | <1 | Colosseum kill-mode fallback |
| roman candelabra | <1 | Purple candle copies of the habitat monsters |
| latte lovers member's mug | <1 | Throw Latte banish |
| V for Vivala mask | <1 | Creepy grin banish |
| designer sweatpants | <1 | Sweat-powered free runs during the guild unlock |
| S.I.T. Course | <1 | Daily certificate skill |
| clan pool table | <1 | Hustlin' in the superitdrop mood |

### Familiars

| Familiar | Turns saved | Why it's used |
|---|---|---|
| Grouper Groupie | 2–3 | The underwater fairy the route leans on by default |
| chest mimic | 1–2 | Diver insurance eggs and fight copies |
| Pocket Professor | 1–2 | Lecture copy chains on the diver and the sea cow |
| Sword of S Words | 1–2 | Kill-a-lot chains for lasso and cowbell farming |
| Jill-of-All-Trades | 1–2 | Best fairy once Driving Waterproofly is up |
| Red-Nosed Snapper | 1–2 | Phylum tracking on top of a stronger underwater fairy |
| patriotic eagle | 1–2 | RWB pellet forcing, zone citizenship, construct screech |
| Space Jellyfish | ~1 | Full fairy underwater, plus stench jelly as a free forcer |
| Glover | ~1 | Cyberzone 1 fights |
| peace turkey / disgeist | ~1 | −combat for the noncombat hunts |
| Foul Ball | <1 | Colosseum support |
| Jumpsuited Hound Dog | <1 | +combat for the gymnasium |
| Tiny Plastic Santa Claus Skeleton | — | Aftercore Dad Sea Monkee fight only |

Useful skills and iotms and stuff: https://docs.google.com/spreadsheets/d/1bAZj17ZUb9cd4V1Nnda8--SiTlJvGQZWJvYz5CUA8G4/edit?usp=sharing

## Items to add support for

- Folder Holder
