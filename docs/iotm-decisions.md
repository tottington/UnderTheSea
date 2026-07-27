# Why these IOTMs are not wired in

A record of what was investigated and rejected, with the evidence, so none of it gets
re-investigated from scratch. Everything that *is* wired in lives in `iotm.ash` and is
guarded on actually owning the item — a character without it skips the path silently.

## The three mechanics that decide almost everything

**1. Drop slots cap at 100%.** The loop already stacks roughly +300% item drops in a
plain `itdrop` mood, and closer to +600–700% in `superitdrop` once Steely-Eyed Squint
doubles the stack. Each drop rolls its own slot and each slot caps at 100%, so once
`base_rate × multiplier ≥ 1` that slot is guaranteed and further +item buys nothing from
it. This is why a headline number like "+30% item drops" is often worth well under a
turn, and why **duration beats magnitude**: +20% over 50 turns outperforms +30% over 20.

**2. Combat frequency has hard diminishing returns.** The first 25 points of a modifier
count in full; every further 5 points contributes only 1. `mood("-combat")` already casts
about −50 raw before gear, which lands at **−30 effective**. Another −5 or −10 raw is
worth one or two effective points. Forced noncombats ("sneaks") bypass the roll entirely
and are not subject to this, which is why the script forces rather than buffs.

**3. A free kill or a free copy is a whole turn.** Chest X-Ray kills "without spending an
adventure" while still granting drops, and a copy is an extra encounter that costs no
adventure. One of those outvalues almost any percentage buff, because it removes a turn
outright rather than improving the odds on one.

## Rejected, with the specific reason

### Bastille Battalion
The wiki lists castle styles carrying "+25% Item Drops from Monsters", which looks
promising. Those are **in-game styles that apply inside the minigame**, not a buff you
keep. The three effects actually granted are `Bastille Bourgeoisie` (Mysticality, spell
crit, MP regen), `Bastille Braggadocio` (Moxie, initiative, **meat**) and `Bastille
Budgeteer` (Muscle, crit, HP regen) — **none carries Item Drop or Combat Rate**. The
`Bastille Battalion control rig` itself has no modifier beyond `Free Pull`. Nothing here
touches turns.

### Tome of Clip Art
Three summons a day. The only item on its list with an item bonus is **"+25% Item Drops
from Monsters, *when unarmed*"**. This route is never unarmed — it runs the legendary
seal-clubbing club, the monodent, and now the broken champagne bottle — so the bonus can
never apply. Everything else it summons is stats, MP, elemental damage, or rollover
adventures.

### Deck of Every Card
15 draws a day, and `cheat` picks a specific card for **5 draws**, so three targeted
cards a day. The mechanism is fine; the problem is the target. Nothing identified in the
deck is on this route's critical path — the cards that matter are largely for other
content. **Limitation worth stating plainly:** the full card list was not enumerated
card-by-card. If a specific need appears (a particular item the loop is currently farming
by hand), this is worth revisiting, because `cheat` can fetch it deterministically.

### Feel Envy
Reads like the strongest skill available — "Get all the things from monsters" forces
every drop, and the diver has six drop slots. But the wiki is explicit: **"Does not cause
items to drop underwater."** The entire route is underwater. Worth exactly zero here.

### God Lobster
Three free fights a day, but they advance no quest, so the fights themselves save
nothing. The only turn-relevant reward is `Silence of the God Lobster`, **−5% combat for
33 turns**, and it requires God Lobster's Ring equipped. Under mechanic 2 that −5 raw is
**one effective point**. It was implemented, measured, and removed.

### Briefcase −combat enchantment, and the −combat cargo pockets
Same arithmetic. The briefcase enchantment is −5 raw (one effective point, ~0.5 turns);
`Barely Visible` is −10 raw (two effective points, ~1.0 turns). Both are also plausibly
worth **zero**, because the Mer-Kin Outpost — where nearly all the −combat hunting
happens — is gated at `turns_spent < 26` before the lockkey monster appears, and the
noncombat hunt already finishes inside that gate. On top of that the briefcase is an
**accessory**, competing with the blood cubic zirconia's 9 free kills and the backup
camera's 11 copies. The briefcase's *tab buff* is taken; only the enchantment is skipped.

### Source Terminal Portscan
Provokes a government agent into the next combat, 3/day. Same objection that rejected
digitize: it inserts an unaimable wanderer that costs a turn and displaces the noncombats
the Outpost block is hunting.

### SongBoom BoomBox
All five songs checked — `Eye of the Giger`, `Food Vibrations`, `Remainin' Alive`, `These
Fists Were Made for Punchin'`, `Total Eclipse of Your Meat`. **None is +item.** Food,
meat, damage and HP/MP only.

### Familiars that duplicate what is already run
`Intergnat`, `XO Skeleton`, `Ms. Puck Man`, `Stocking Mimic`, `Robortender` — Fairy,
Cocoabo or Leprechaun class. The +item familiar slot already holds a full Fairy, and
`Red-Nosed Snapper` is better than one underwater (`Fairy: [1+0.5*env(underwater)]`, i.e.
**1.5x**). None of these beat what is there.

### Items with no relevant modifier at all
`RetroSpecs`, `shrunken head`, `li'l orphan tot` — checked directly against KoLMafia's
`modifiers.txt` and none has an Item Drop or Combat Rate entry. Stats, HP, MP and damage
reduction only.

### Wrong axis
`Cup of 13s`, `diabolic pizza cube`, `moon-rune spoon`, `New-You Club`, `Bird-a-Day
calendar`, `Beach Comb`, `mushroom garden`, `Thanksgarden`, `Boxing Daycare`,
`heart-shaped crate`, `pasta wand`, `box o' ghosts`, and the clan `fireworks shop`,
`Floundry`, `hot dog stand`, `looking glass`, `speakeasy` and `Carnival Game`. These
produce adventures, meat, food, booze, stats or consumables. **Adventures are explicitly
not the goal — the goal is fewer turns spent**, and gaining rollover adventures does not
shorten the route.

### Separate zones
`Spacegate`, `FantasyRealm`, `PirateRealm`, `KoLHS`, `Batfellow`, `Pokéfam` and the
`Neverending Party` are content you adventure *in*. They cost turns rather than saving
them. The `DIY protonic accelerator` is the near miss: its ghosts genuinely are free
fights, but they spawn in zones this route never visits.

## Audit false negatives — already in use

A name-based grep over the ownership sheet reports these as unused. They are not:

- **Clan pool table** — used via `Hustlin'` in the `superitdrop` mood.
- **Emotion chip** — used via `Feel Hatred` in `free_run()` and `Feel Nostalgic` in the CCS.
- **Lil' Doctor bag** — the item name appears, but all three of its skills are now used
  (`Chest X-Ray`, `Otoscope`, `Reflex Hammer`).

Any future audit should check granted skills and derived items, not just item names.
