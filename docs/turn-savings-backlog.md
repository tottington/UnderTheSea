# Turn-savings backlog

Owned items that are not wired into the loop yet, with what they are worth and what
would have to be decided before using them. Everything already in the script is
ownership-guarded and skips cleanly when the item is absent; anything added from this
list should follow the same rule.

## Ground rules learned so far

Three facts shape every estimate below.

**Drop slots cap at 100%.** The loop already stacks roughly +300% item drops in a plain
`itdrop` mood, and closer to +600-700% in `superitdrop` once Steely-Eyed Squint doubles
the stack. Against that baseline another +15% or +25% moves very little, because the fat
slots are already capped. Duration beats magnitude: a +20% buff over 50 turns is worth
more than a +30% buff over 20.

**Combat frequency has hard diminishing returns.** The first 25 points of a modifier
count in full; every further 5 points contributes 1. `mood("-combat")` already casts
about -50 raw before gear, which lands at -30 effective. Another -5 or -10 raw buys one
or two effective points. Forced noncombats bypass the roll entirely, which is why the
script forces rather than buffs.

**A free kill is a whole turn.** Chest X-Ray and friends kill "without spending an
adventure" while still granting drops, so one free kill outvalues almost any item buff.
Anything that produces an extra *encounter* or an extra *roll* is worth the turns that
encounter would otherwise have cost.

## Worth doing, needs a decision first

Everything that was on this list has now been resolved. Pocket Professor is implemented;
Bastille Battalion, Tome of Clip Art and the Deck of Every Card were investigated and
rejected. See `iotm-decisions.md` for the evidence on each.

The one item left genuinely open is the **Deck of Every Card**, and only conditionally:
`cheat` fetches a specific card for 5 of the day's 15 draws, so three targeted cards a
day. Nothing in the deck is on this route's critical path today, but the full card list
was not enumerated card-by-card. If the loop ever ends up hand-farming a specific item,
check whether a card produces it.

## Assessed and rejected

Kept here so these do not get re-investigated.

| Item | Why not |
|---|---|
| Feel Envy | Forces every drop, but explicitly **does not work underwater** — the entire route |
| God Lobster | Only turn-relevant boon is Silence, -5% combat, which the diminishing returns reduce to one effective point |
| Briefcase -combat enchantment | Same one effective point, and it costs an accessory slot carrying free kills and copies |
| Cargo -combat pockets (Barely Visible) | -10 raw is two effective points; an item pocket is worth more |
| SongBoom BoomBox | All five songs checked — none is +item. Food, meat, damage, HP/MP only |
| Source Terminal Portscan | Inserts an unaimable wanderer that costs a turn, same objection that rejected digitize |
| Intergnat, XO Skeleton, Ms. Puck Man, Stocking Mimic, Robortender | Fairy- or Cocoabo- or Leprechaun-class familiars; the +item familiar slot is already a full Fairy |
| RetroSpecs, shrunken head, li'l orphan tot | No Item Drop or Combat Rate entry in mafia's modifier data — stats, HP and MP only |
| Cup of 13s, diabolic pizza cube, moon-rune spoon, New-You Club, Bird-a-Day, Beach Comb, mushroom garden, Thanksgarden, Boxing Daycare, heart-shaped crate, pasta wand, box o' ghosts, clan fireworks / Floundry / hot dog stand / looking glass / speakeasy / Carnival Game | Wrong axis — adventures, meat, food, stats or consumables rather than turns |
| Spacegate, FantasyRealm, PirateRealm, KoLHS, Batfellow, Pokéfam, Neverending Party, DIY protonic accelerator | Separate zones that cost turns rather than saving them; the accelerator's ghosts are free fights but spawn where this route never goes |

## Already in use, despite not matching a name search

`Clan pool table` via `Hustlin'` in the `superitdrop` mood, and the emotion chip via
`Feel Hatred` in `free_run()` and `Feel Nostalgic` in the CCS. Any future audit that
greps for item names will report these as unused; they are not.
