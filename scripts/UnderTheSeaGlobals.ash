import <seedfinder/seedfinder.ash>;
// ─── GLOBALS ──────────────────────────────────────────────────────────────────   
    int pearlsDoneToday;
    string boss,modes;
    string choiceStorage = get_property("choiceAdventureScript");
    string betweenBattleStorage = get_property("betweenBattleScript");
    string afterAdventureStorage = get_property("afterAdventureScript");
    string CCSStorage = get_property("customCombatScript");
    string mpAutoRecoveryItemsStorage = get_property("mpAutoRecoveryItems");
    int clanID = get_clan_id();
    if (CCSStorage == "temp") CCSStorage = "default";
    string choice1387Storage = get_property("choiceAdventure1387");
    string [stat] pearlRes = {
        $stat[mysticality]: "hot res",
        $stat[moxie]:       "sleaze res",
        $stat[muscle]:      "spooky res"
    };
    location [stat] pearlLoc = {
        $stat[mysticality]: $location[The Marinara Trench],
        $stat[moxie]:       $location[The Dive Bar],
        $stat[muscle]:      $location[Anemone Mine]
    };
    string [stat] questProp = {
        $stat[mysticality]: "questG07Myst",
        $stat[moxie]:       "questG08Moxie",
        $stat[muscle]:      "questG09Muscle"
    };
    location [stat] questLoc = {
        $stat[mysticality]: $location[The Haunted Pantry],
        $stat[moxie]:       $location[The Sleazy Back Alley],
        $stat[muscle]:      $location[The Outskirts of Cobb's Knob]
    };
    stat ps = my_primestat();
    int [item] pasta_prices;
    foreach it in $items[Frutti di Scatoletta,Pesto alla Marziano,Arrattabbattabiata,Orzo di Riso,Pasta Grimavera,Linguini Ubriacapa,Gnocci Domani,Formica e Pepe,Tubetto Gelatto]{
        pasta_prices[it] = mall_price(it);
    }
// ─── UTILITY HELPERS ────────────────────────────────────────────────────────
    int count_substring(string text, string sub) {
        int count = 0;
        int pos = 0;
        while (true) {
            pos = index_of(text, sub, pos);
            if (pos == -1) break;
            count += 1;
            pos += length(sub);
        }
        return count;
    }

    boolean contains_text_in_array(string [int] map1, string str) {
        foreach num in map1 {
            if (contains_text(map1[num], str))
                return true;
        }
        return false;
    }

    
    void use_if_have_skill(string page_text, skill sk) {
        if (contains_text(page_text, to_string(sk)))
            use_skill(sk);
    }

    boolean have_item(item it) {
        if (available_amount(it) > 0 || storage_amount(it) > 0)
            return true;
        foreach fam in $familiars[] {
            if (have_familiar(fam) && familiar_equipped_equipment(fam) == it)
                return true;
        }
        return false;
    }

    // Returns true if this monster can prvoide a free fight
    boolean free_monster(monster mob) {
        return $monsters[black crayon golem, Black Crayon Beetle, Black Crayon Man, Black Crayon Goblin, Black Crayon Undead Thing, Black Crayon Slime, time cop, sausage goblin,
            kid who is too old to be Trick-or-Treating,
            suburban security civilian, vandal kid] contains mob;
    }

    item effect_to_item(effect ef){
        if (contains_text(ef.default,"drink 1 ") || contains_text(ef.default,"chew 1 ")){
            return delete(to_buffer(ef.default),0,7).to_item();
        } else if (contains_text(ef.default,"eat 1 ") || contains_text(ef.default,"use 1 ")){
            return delete(to_buffer(ef.default),0,6).to_item();
        } else
            return $item[none];
    }

// Account states
    // The IOTM route runs on the Monodent's gear and skills. Without it the
    // run follows the low IOTM guide route, which takes precedence over the other tiers.
    // 1 or 0 once computed, cached for the script run.
    int lowIOTMKnown = -1;
    boolean lowIOTM() {
        if (lowIOTMKnown < 0) {
            lowIOTMKnown = 1;
            foreach it in $items[monodent of the sea, packaged Monodent of the Sea]
                if (have_item(it) || closet_amount(it) + display_amount(it) > 0)
                    lowIOTMKnown = 0;
        }
        return lowIOTMKnown == 1;
    }

    // The low IOTM guide's own steps only run inside 11037 Leagues Under the Sea.
    boolean guideRoute() {
        return lowIOTM() && my_path().id == 55;
    }

    boolean highShiny() {
        return !guideRoute()
            && to_int(get_property("garbo_valueOfFreeFight")) > to_int(get_property("valueOfAdventure"));
    }

    boolean lowShiny() {
        return !have_item($item[2002 Mr. Store Catalog])
            && !have_item($item[cursed monkey's paw])
            && !have_item($item[august scepter]);
    }

    int count_summons(){
        int n;
        if (get_property("_photocopyUsed") == "false" && have_item($item[Clan VIP Lounge key]))
            n += 1;
        if (available_amount($item[combat lover's locket]) > 0){
            string [int] lockets = split_string(get_property("_locketMonstersFought"), ",");
            n += 3-count(lockets);
        }
        if (have_familiar($familiar[chest mimic]))
            n += floor($familiar[chest mimic].experience/200);
        return n;
    }

    boolean gotPeriled (location loc){
        string [int] perilLoc = split_string(get_property("_perilLocations"),",");
        foreach num in perilLoc{
            if (perilLoc[num].to_int().to_location() == loc)
                return true;
        }
        return false;
    }

    int seedPoss(){
        SeedData[int] possibleSeeds=find_seeds();
        return count(possibleSeeds);
    }

    boolean isKBandSushiEnough(){
        SeedData[int] possibleSeeds=find_seeds();
        if (count(possibleSeeds) == 0)
            return false;
        boolean [string] seen;
        foreach idx, seed in possibleSeeds {
            string key = seed.dreadscroll[3] + ":" + seed.dreadscroll[6];
            if (seen contains key)
                return false;
            seen[key] = true;
        }
        return true;
    }

// Game Mechanics
    boolean pulledToday(item it) {
        string [int] pulledToday = split_string(get_property("_roninStoragePulls"), ",");
        if (contains_text_in_array(pulledToday, it.to_int().to_string()))
            return true;
        return false;
    }

    int reservedPulls(){
        int n;
        // The guide route farms its prayerbeads, cowbells and comb jelly, so it holds no pull for them.
        boolean guide = guideRoute();
        if (!guide && available_amount($item[mer-kin prayerbeads]) < 3 && !pulledToday($item[mer-kin prayerbeads]))
            n += 1;
        if (!guide && item_amount($item[sea cowbell]) < 3 && !pulledToday($item[sea cowbell]))
            n += 1;
        if (!guide && !lowShiny() && have_effect($effect[Jelly Combed]) == 0 && available_amount($item[comb jelly]) == 0 && !pulledToday($item[comb jelly]))
            n += 1;
        if (get_property("shubJigguwattDefeated") == "false" && item_amount($item[crayon shavings]) < 4
            && item_amount($item[null-day exploit]) == 0 && !pulledToday($item[null-day exploit]))
            n += 1;
        return n;
    }

    boolean pullSequence(item it) {
        if (pulls_remaining() == 0)
            return false;
        if (!pulledToday(it)) {
            if (storage_amount(it) == 0){
                if (mall_price(it) > to_int(get_property("autoBuyPriceLimit"))){
                    if (!user_confirm("Price of " + it + " exeeds autoBuyPriceLimit, skip?"))
                        abort("Price of " + it + " exeeds autoBuyPriceLimit");
                }
                buy_using_storage(it);
            }
            return take_storage(1, it);
        }
        return false;
    }

    // Owned, already spent today, or mall-buyable with a pull left.
    boolean nullDayAvailable() {
        if (have_item($item[null-day exploit]) || pulledToday($item[null-day exploit])
            || have_effect($effect[Null Afternoon]) > 0)
            return true;
        return pulls_remaining() != 0 && mall_price($item[null-day exploit]) > 0;
    }

    boolean colosseumSpellFamiliar() {
        return (have_familiar($familiar[Foul Ball]) && have_skill($skill[Eggsplosion]))
            || (have_familiar($familiar[Tiny Plastic Santa Claus Skeleton])
                && have_skill($skill[Awesome Balls of Fire]));
    }

    // The spell route's lantern familiar, Foul Ball first as in the guide.
    familiar colosseumFamiliar() {
        if (have_familiar($familiar[Foul Ball]) && have_skill($skill[Eggsplosion]))
            return $familiar[Foul Ball];
        if (have_familiar($familiar[Tiny Plastic Santa Claus Skeleton]) && have_skill($skill[Awesome Balls of Fire]))
            return $familiar[Tiny Plastic Santa Claus Skeleton];
        return $familiar[none];
    }

    // The spell that goes with colosseumFamiliar().
    skill colosseumSpell() {
        if (colosseumFamiliar() == $familiar[Foul Ball])
            return $skill[Eggsplosion];
        if (colosseumFamiliar() == $familiar[Tiny Plastic Santa Claus Skeleton])
            return $skill[Awesome Balls of Fire];
        return $skill[none];
    }

    item colosseumLantern() {
        foreach it in $items[petrified wood wizard's pouch, Congressional Medal of Insanity,
            petrified wood water purifier]
            if (have_item(it))
                return it;
        return $item[none];
    }

    // Spell route hard requirements: a lantern familiar with its matching
    // spell, a lantern item and a null-day exploit.
    boolean colosseumSpellRoute() {
        return colosseumSpellFamiliar() && colosseumLantern() != $item[none]
            && nullDayAvailable();
    }

    // Furious Wallop trains the Mer-kin weapons in-run, so owning it is enough.
    boolean colosseumCombatRoute() {
        return !colosseumSpellRoute() && have_skill($skill[Furious Wallop])
            && my_class() == $class[Seal Clubber];
    }

    // "spell", "combat" or "none". A found route is kept for the ascension, stored
    // as "<ascension>:<route>", so spent pulls or mall prices can't switch it mid-run.
    string colosseumRoute(boolean save) {
        string [int] saved = split_string(get_property("uts_colosseumRoute"), ":");
        if (count(saved) == 2 && to_int(saved[0]) == my_ascensions())
            return saved[1];
        string route = colosseumSpellRoute() ? "spell" : colosseumCombatRoute() ? "combat" : "none";
        if (save && route != "none")
            set_property("uts_colosseumRoute", my_ascensions() + ":" + route);
        return route;
    }

    string colosseumRoute() {
        return colosseumRoute(true);
    }

    // What the spell route lacks, and what the combat route needs.
    string colosseumMissing() {
        string missing;
        if (!colosseumSpellFamiliar())
            missing += " Foul Ball with Eggsplosion, or Tiny Plastic Santa Claus Skeleton with Awesome Balls of Fire.";
        if (colosseumLantern() == $item[none])
            missing += " A lantern item: petrified wood wizard's pouch, Congressional Medal of Insanity or petrified wood water purifier.";
        if (!nullDayAvailable())
            missing += " A null-day exploit, owned or mall-buyable with a pull.";
        return "The spell route is missing:" + missing + " The combat route needs Furious Wallop on a Seal Clubber.";
    }

    // Each Mer-kin weapon's moves in unlock order, at its 5th, 10th and 15th underwater critical hit.
    skill [int] gladiatorMoves(item weapon) {
        if (weapon == $item[Mer-kin dodgeball]) {
            skill [int] ball = {0: $skill[Ball Bust], 1: $skill[Ball Sweat], 2: $skill[Ball Sack]};
            return ball;
        }
        if (weapon == $item[Mer-kin dragnet]) {
            skill [int] net = {0: $skill[Net Gain], 1: $skill[Net Loss], 2: $skill[Net Neutrality]};
            return net;
        }
        if (weapon == $item[Mer-kin switchblade]) {
            skill [int] blade = {0: $skill[Blade Sling], 1: $skill[Blade Roller], 2: $skill[Blade Runner]};
            return blade;
        }
        skill [int] none;
        return none;
    }

    // The boldface word each special is announced by, in the order of gladiatorMoves().
    string [int] gladiatorTells(item weapon) {
        if (weapon == $item[Mer-kin dodgeball]) {
            string [int] ball = {0: "bust", 1: "sweat", 2: "sack"};
            return ball;
        }
        if (weapon == $item[Mer-kin dragnet]) {
            string [int] net = {0: "gain", 1: "loss", 2: "neutrality"};
            return net;
        }
        if (weapon == $item[Mer-kin switchblade]) {
            string [int] blade = {0: "sling", 1: "rolls", 2: "runner"};
            return blade;
        }
        string [int] none;
        return none;
    }

    string gladiatorMovesProp(item weapon) {
        if (weapon == $item[Mer-kin dodgeball])
            return "gladiatorBallMovesKnown";
        if (weapon == $item[Mer-kin dragnet])
            return "gladiatorNetMovesKnown";
        if (weapon == $item[Mer-kin switchblade])
            return "gladiatorBladeMovesKnown";
        return "";
    }

    int gladiatorMovesKnown(item weapon) {
        string prop = gladiatorMovesProp(weapon);
        return prop == "" ? 0 : to_int(get_property(prop));
    }

    // The Mer-kin weapon a gladiator move belongs to, or none.
    item gladiatorMoveWeapon(skill sk) {
        foreach weapon in $items[Mer-kin dodgeball, Mer-kin dragnet, Mer-kin switchblade]
            foreach i, move in gladiatorMoves(weapon)
                if (move == sk)
                    return weapon;
        return $item[none];
    }

    // Known by its weapon's moves-known property, read in unlock order.
    boolean gladiatorMoveKnown(skill sk) {
        item weapon = gladiatorMoveWeapon(sk);
        foreach i, move in gladiatorMoves(weapon)
            if (move == sk)
                return gladiatorMovesKnown(weapon) > i;
        return false;
    }

    // Colosseum rounds cycle balldodger, netdragger, bladeswitcher, countered by dragnet, switchblade, dodgeball.
    item gladiatorWeapon(int roundsWon) {
        item [int] order = {0: $item[Mer-kin dragnet], 1: $item[Mer-kin switchblade], 2: $item[Mer-kin dodgeball]};
        return order[max(0, roundsWon) % 3];
    }

    // The Mer-kin weapon whose moves counter this Colosseum monster, or none.
    item gladiatorCounterWeapon(monster mob) {
        string name = to_lower_case(to_string(mob));
        if (contains_text(name, "balldodger"))
            return $item[Mer-kin dragnet];
        if (contains_text(name, "netdragger"))
            return $item[Mer-kin switchblade];
        if (contains_text(name, "bladeswitcher"))
            return $item[Mer-kin dodgeball];
        return $item[none];
    }

    // The counter to the special this gladiator's fight text announces, or none.
    skill colosseumCounter(monster mob, string text) {
        item weapon = gladiatorCounterWeapon(mob);
        string [int] tells = gladiatorTells(weapon);
        foreach i, move in gladiatorMoves(weapon)
            if (contains_text(text, "<b>" + tells[i] + "</b>"))
                return move;
        return $skill[none];
    }

    int gladiatorMovesTotal() {
        int known;
        foreach weapon in $items[Mer-kin dodgeball, Mer-kin dragnet, Mer-kin switchblade]
            known += min(3, gladiatorMovesKnown(weapon));
        return known;
    }

    boolean gladiatorMovesLocked() {
        return gladiatorMovesTotal() < 9;
    }

    // The combat route still has a Mer-kin weapon move to unlock and the Colosseum still to win.
    boolean gladiatorTrainingPending() {
        return guideRoute() && to_int(get_property("lastColosseumRoundWon")) < 15
            && get_property("isMerkinGladiatorChampion") != "true"
            && colosseumRoute() == "combat" && gladiatorMovesLocked();
    }

    // Inside a training phase: the combat route's Gymnasium, pearl stage 2 or the training sink.
    boolean gladiatorTrainingPhase() {
        return get_property("_utsGladiatorTraining") == "true" && gladiatorTrainingPending();
    }

    // Whether an announced special gets a counter round. Gain (-300% Muscle) and rolls (-300% Moxie) count
    // only against the wielded weapon's attack stat; loss and sweat are attacked through.
    boolean colosseumCounterNeeded(skill counter, stat attackStat) {
        if ($skills[Net Neutrality, Ball Bust, Ball Sack, Blade Runner, Blade Sling] contains counter)
            return true;
        if (counter == $skill[Net Gain])
            return attackStat == $stat[muscle];
        if (counter == $skill[Blade Roller])
            return attackStat == $stat[moxie];
        return false;
    }

    // The held Mer-kin weapon with a locked move that can be wielded now, or none.
    item gladiatorTrainee() {
        foreach weapon in $items[Mer-kin dragnet, Mer-kin switchblade, Mer-kin dodgeball]
            if (available_amount(weapon) > 0 && gladiatorMovesKnown(weapon) < 3 && can_equip(weapon))
                return weapon;
        return $item[none];
    }

    // Why each Mer-kin weapon with a locked move can't be trained now.
    string gladiatorTrainingBlocked() {
        string why;
        foreach weapon in $items[Mer-kin dragnet, Mer-kin switchblade, Mer-kin dodgeball] {
            if (gladiatorMovesKnown(weapon) >= 3)
                continue;
            if (available_amount(weapon) == 0)
                why += " No " + weapon + " is held; it comes from the Mer-kin Gymnasium noncombat.";
            else if (!can_equip(weapon))
                why += " The " + weapon + " needs base " + weapon_type(weapon) + " 85 to wield, and yours is "
                    + my_basestat(weapon_type(weapon)) + ".";
        }
        return "The Colosseum combat route knows " + gladiatorMovesTotal() + " of 9 Mer-kin weapon moves and can't train the rest." + why;
    }

    void getLucky() {
        if (have_effect($effect[Lucky!]) > 0)
            return;
        if (have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5) {
            use_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (available_amount($item[heartstone]) > 0 && get_property("heartstoneLuckUnlocked") == true && get_property("_heartstoneLuckUsed") == false) {
            use_skill($skill[Heartstone: %luck]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        use($item[11-leaf clover]);
    }

// Progress tracker
    void step(string msg) {
        print("UTS: " + msg, "blue");
    }

// ─── EQUIPMENT AND OUTFIT HELPERS ───────────────────────────────────────────
        void codpiece(string input) {
        if (!have_item($item[The Eternity Codpiece]))
            return;
        if (input == "none") {
            string verify = visit_url("inventory.php?action=docodpiece");
            if (!contains_text(verify, " mounted in slot #"))
                return;
            for slots from 1 to 5 {
                if (contains_text(verify," Empty slot #" + slots )){
                    continue;
                } else {
                    visit_url("choice.php?whichchoice=1588&option=2&which=" + slots);
                }
            }
        } else {
            string [int] slots = split_string(input, ",");
            foreach num in slots {
                if (have_equipped(slots[num].to_item()))
                    cli_execute("unequip " + slots[num].to_item());
                if (item_amount(to_item(slots[num])) == 0 ){
                    slots[num] = "";
                    continue;
                }
                print("Inserting "+ to_item(slots[num]) + " into Codpiece");
                visit_url("inventory.php?action=docodpiece");
                visit_url("choice.php?whichchoice=1588&option=1&which=" + (num + 1)
                    + "&iid=" + to_int(to_item(slots[num])));
                visit_url("main.php");
            }
            string verify = visit_url("inventory.php?action=docodpiece");
            foreach num in slots {
                if (slots[num] == "")
                    continue;
                if (!contains_text(verify, to_item(slots[num]) + " mounted in slot #" + (num + 1)))
                    abort("Codpiece slot incorrect");
            }
        }
        cli_execute("refresh inv");
    }

    // Return equip text or empty if unavailable.
    string if_equip(item it) {
        if ($items[baseball diamond, peridot of peril, heartstone, blood cubic zirconia] contains it)
            codpiece("none");
        if (it == $item[none] || available_amount(it) == 0)
            return "";
        else
            return it.to_string() + ",";
    }

    // The Abyss resistance gear when held: the scale-mail underwear, and the shark jumper with a skill to wear a shirt.
    string abyssGear() {
        string gear;
        if (can_equip($item[scale-mail underwear]))
            gear += if_equip($item[scale-mail underwear]);
        if ((have_skill($skill[Torso Awareness]) || have_skill($skill[Best Dressed])) && can_equip($item[shark jumper]))
            gear += if_equip($item[shark jumper]);
        return gear;
    }

    string bathysphere(item it) {
        if (!my_familiar().underwater && have_effect($effect[driving waterproofly]) == 0)
            return "little bitty bathysphere,";
        if (it != $item[none])
            return if_equip(it);
        return "";
    }

    boolean badMaxString(string str){
        foreach c in $strings[\,,0,1,2,3,4,5,6,7,8,9] {
            if (contains_text(str, c))
                return true;
        }
        return false;
    }

    string seaOutfit() {
        foreach str in $strings[Crappy Mer-kin Disguise,
            Mer-kin Gladiatorial Gear, Mer-kin Scholar's Vestments] {
            if (have_outfit(str))
                return str;
        }
        return "";
    }

    item divingHelmet() {
        foreach it in $items[Mer-kin gladiator mask,
            Mer-kin scholar mask, crappy Mer-kin mask, aerated diving helmet, Elf Guard SCUBA tank] {
            if (item_amount(it) > 0 || have_equipped(it))
                return it;
        }
        return $item[none];
    }

    item tailpiece() {
        item it;
        foreach ite in $items[Mer-kin gladiator tailpiece,
            Mer-kin scholar tailpiece, crappy Mer-kin tailpiece, teflon swim fins] {
            if (item_amount(ite) > 0 || have_equipped(ite)){
                it = ite;
                break;
            }
        }
        return it;
    }

    void equipSwimTrunks(){
        if (have_effect($effect[driving waterproofly]) > 0)
            return;
        if (my_path().id == 55){
            equip($item[really, really nice swimming trunks]);
        } else if (my_path().id == 0){
            equip($item[Elf Guard SCUBA tank]);
        }
    }

    void buyScholarGear() {
        if (available_amount($item[Mer-kin scholar mask]) == 0
            && !have_equipped($item[Mer-kin scholar mask])) {
            equip($slot[hat], $item[none]);
            equipSwimTrunks();
            buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar mask]);
        }
        if (available_amount($item[Mer-kin scholar tailpiece]) == 0
            && !have_equipped($item[Mer-kin scholar tailpiece])) {
            equip($slot[pants], $item[none]);
            equipSwimTrunks();
            buy($coinmaster[Grandma Sea Monkey],1,$item[Mer-kin scholar tailpiece]);
        }
    }

    int baseballPlayers(){
        string [int] lineup = split_string(get_property("baseballTeam"), ",");
        int players;
        foreach num in lineup { players = num + 1; }
        return players;
    }
    string baseball_equip(){
        if (baseballPlayers() < 9 && !highShiny())
            return if_equip($item[baseball diamond]);
        return "";
    }

    void yellowRayPrep(){
        if (have_effect($effect[everything looks yellow]) == 0){
            if (have_item($item[jurassic parka]))
                cli_execute("parka dilophosaur; equip jurassic parka");
        else if (have_item($item[April Shower Thoughts shield]) && available_amount($item[spitball]) == 0 && item_amount($item[glob of wet paper]) > 0)
                create($item[spitball]);
        }
    }

    int BCZcost(string BCZskill) {
        int cast = to_int(get_property("_bcz" + BCZskill));
        if (cast == 12) return 420000;
        if (cast > 12) cast -= 1;
        int castMathFloor = floor(cast / 3);
        int castMathModulo = cast % 3;
        int substatBase;
        switch (castMathModulo) {
            case 0: substatBase = 11; break;
            case 1: substatBase = 23; break;
            case 2: substatBase = 37; break;
        }
        // Pattern: 11, 23, 37, 110, 230, 370, ... 13th cast handled separately but unreachable
        return substatBase * 10 ** ((cast < 12 || (cast > 12 && castMathModulo == 0))
            ? castMathFloor : castMathFloor + 1);
    }

    // Assert your Authority needs all three props worn at once. Same test
    // tempEquipment() applies, so a true here means it can dress them.
    boolean sheriffOutfit() {
        foreach it in $items[Sheriff moustache, Sheriff badge, Sheriff pistol]
            if (available_amount(it) == 0)
                return false;
        return true;
    }

    // Quest items worth a turn to claim off a dolphin. A theft is a drop that
    // missed, so the whistle is a second chance, not damage control.
    boolean [item] whistleWorthy = $items[Mer-kin prayerbeads, Mer-kin healscroll,
        Mer-kin lockkey, Mer-kin hallpass, Mer-kin cheatsheet, Mer-kin bunwig,
        rusty rivet, rusty porthole, rusty broken diving helmet, sea leather,
        sea cowbell, sea lasso, Mer-kin digpick];

    // Charges cap at seaPoints, and one in Hagnk's is unusable in Ronin, so
    // possession is not readiness.
    boolean durableWhistleReady() {
        return item_amount($item[durable dolphin whistle]) > 0
            && to_int(get_property("_durableDolphinWhistleUsed"))
                < to_int(get_property("seaPoints"));
    }

    // Last theft reported and the words used, so a retry only speaks on a change.
    item dolphinSaid;
    string dolphinSaidWhy;

    // The 50 sand dollar map to Anemone Mine a guide route non-Muscle class still needs for its teflon ore,
    // while the digpick can be wielded.
    int anemoneMapOwed() {
        if (!guideRoute() || my_primestat() == $stat[muscle]
            || get_property("mapToAnemoneMinePurchased") == "true"
            || tailpiece() != $item[none] || item_amount($item[teflon ore]) > 0
            || !can_equip($item[Mer-kin digpick]))
            return 0;
        return 50;
    }

    // Unbought pearl zone maps at 50 sand dollars each, skipping zones Little Brother opens for this class.
    // None once five pearls are held or the center door is under way.
    int pearlMapsOwed() {
        if (!guideRoute() || item_amount($item[unblemished pearl]) >= 5 || get_property("questL13Final") != "unstarted")
            return 0;
        int n;
        if (get_property("mapToMadnessReefPurchased") != "true")
            n += 50;
        if (my_primestat() != $stat[mysticality] && get_property("mapToTheMarinaraTrenchPurchased") != "true")
            n += 50;
        if (my_primestat() != $stat[moxie] && get_property("mapToTheDiveBarPurchased") != "true")
            n += 50;
        // anemoneMapOwed() already holds these dollars while the map is wanted for teflon ore.
        if (my_primestat() != $stat[muscle] && get_property("mapToAnemoneMinePurchased") != "true" && anemoneMapOwed() == 0)
            n += 50;
        return n;
    }

    // Sand dollars Big Brother is still owed: 13 for the black glass, 50 for
    // the damp old boot. Only the surplus buys whistles.
    int sandDollarsOwed() {
        int n;
        // The Anemone Mine map ranks first: no map, no teflon ore, and no crappy tailpiece.
        n += anemoneMapOwed();
        if (available_amount($item[black glass]) == 0)
            n += 13;
        // Against "true" so an unread preference reserves rather than releases.
        if (get_property("dampOldBootPurchased") != "true")
            n += 50;
        // Bootstraps smith into the teflon swim fins, a tailpiece option.
        if (tailpiece() == $item[none]
            && available_amount($item[waterlogged bootstraps]) == 0)
            n += 10;
        // The pearl zone maps come after the purchases above, ahead of the Skate Park map and the whistles.
        n += pearlMapsOwed();
        return n;
    }

    // Names what an unbounded zone loop is waiting for, every ten turns past the
    // mark. Call before adv(): the modifiers read are whatever is worn.
    void zoneStall(string waitingFor, item gate, location zone, int spent, int mark) {
        if (spent < mark || (spent - mark) % 10 != 0)
            return;
        string why;
        if (gate == $item[none])
            why = (turns_until_forced_noncombat(zone) < 0
                    ? "no forced noncombat here"
                    : "forced noncombat in " + turns_until_forced_noncombat(zone)
                        + " turns")
                + ", combat rate " + round(combat_rate_modifier()) + "%";
        else
            why = gate + " x" + item_amount(gate) + ", item "
                + round(numeric_modifier("Item Drop")) + "% against this zone's "
                + round(numeric_modifier("Loc:" + to_string(zone),
                    "Item Drop Penalty")) + "%";
        print(spent + " turns in " + zone + " still waiting on " + waitingFor
            + ": " + why + ".", "red");
    }

    string freeKill() {
        if (have_effect($effect[everything looks red]) == 0 && available_amount($item[everfull dart holster]) > 0)
            return if_equip($item[everfull dart holster]);
        if (highShiny() && my_familiar() != $familiar[Sword of S Words] && have_effect($effect[everything looks yellow]) == 0){
            modes = "parka dilophosaur";
            return if_equip($item[jurassic parka]);
        }
        if (highShiny())
            return "";
        if (to_int(get_property("_assertYourAuthorityCast")) < 3 && sheriffOutfit()
            && (my_location() == $location[An octopus's garden] || my_location() == $location[mer-kin gymnasium] || my_location() == $location[the caliginous abyss]))
            return "Sheriff moustache,Sheriff badge,Sheriff pistol,";
        if (to_int(get_property("_chestXRayUsed")) < 3 && have_item($item[Lil' Doctor&trade; bag]))
            return "Lil' Doctor™ bag,";
        if ((my_basestat($stat[submoxie]) - 22500) > BCZcost("SweatBulletsCasts"))
            return if_equip($item[blood cubic zirconia]);
        return "";
    }

    string freeRun() {
        if (have_effect($effect[Everything Looks Green]) == 0)
            return if_equip($item[spring shoes]);
        if (available_amount($item[greatest american pants]) > 0 && (get_property("_navelRunaways").to_int() < 3 || (get_property("_navelRunaways").to_int() < 10 && highShiny())) && have_effect($effect[driving waterproofly]) > 0)
            return if_equip($item[greatest american pants]);
        if (available_amount($item[V for vivala mask]) > 0 && get_property("_vmaskBanisherUsed") == false)
            return if_equip($item[V for vivala mask]);
        if (available_amount($item[latte lovers member's mug]) > 0 && get_property("_latteBanishUsed") == false)
            return if_equip($item[latte lovers member's mug]);
        if (have_familiar($familiar[Pair of Stomping Boots]) && round((familiar_weight($familiar[Pair of Stomping Boots]) + weight_adjustment()/5)) > get_property("_banderRunaways").to_int()){
            use_familiar($familiar[Pair of Stomping Boots]);
            return "";
        }
        return freeKill();
    }

    string delay(){
        if (have_item($item[Kramco Sausage-o-Matic&trade;]) && !highShiny())
            return if_equip($item[Kramco Sausage-o-Matic&trade;]) + freeRun();
        return freeRun();
    }

        int [int] mobiusEncounters = {
        0:0,
        1:4,
        2:7,
        3:13,
        4:19,
        5:25,
        6:31,
        7:41,
        8:41,
        9:41,
        10:41,
        11:41,
        12:51,
        13:51,
        14:51,
        15:51,
        16:51,
        17:76,
        18:76,
        19:76,
        20:76
    };

    boolean MobiusNCReady(){
        if (total_turns_played( ) > get_property("_lastMobiusStripTurn").to_int() + mobiusEncounters[get_property("_mobiusStripEncounters").to_int()])
            return true;
        return false;
    }

    // Defined with the fish scale helpers.
    boolean scimitarRetired();

    // Guide route: a club picked for the weapon slot belongs in the main hand, where Batter Up! swings it.
    boolean clubNeedsMainHand(boolean guide, item club, item mainHand) {
        return guide && club != $item[none] && item_type(club) == "club" && mainHand != club;
    }

    void tempEquipment(string maximizerInput, string itemInput){
        string [int] itemMap = split_string(itemInput, ",");
        item [slot] equipmentSelection;
        //Assigning items to slots
        if (have_equipped($item[Elf Guard SCUBA tank]))
            cli_execute("unequip Elf Guard SCUBA tank");
        foreach str in itemMap{
            if (itemMap[str] == "")
                continue;
            if (to_item(itemMap[str]) == $item[none]){
                print("String to item mismatch, item is " + itemMap[str] + ", notify fart scauce","red");
                continue;
            }
            if (equipmentSelection[itemMap[str].to_item().to_slot()] == $item[none]){
                equipmentSelection[itemMap[str].to_item().to_slot()] = itemMap[str].to_item(); 
                continue;
            }
            if (to_slot(to_item(itemMap[str])) == $slot[weapon] && have_skill($skill[Double-Fisted Skull Smashing])){
                if (equipmentSelection[$slot[off-hand]] == $item[none]){
                    equipmentSelection[$slot[off-hand]] = itemMap[str].to_item(); 
                    continue;
                }
            }
            if (to_slot(to_item(itemMap[str])) == $slot[acc1]){
                foreach sl in $slots[acc2,acc3]{
                    if (equipmentSelection[sl] == $item[none]){
                        equipmentSelection[sl] = itemMap[str].to_item(); 
                        continue;
                    }
                }
            }
            if (highShiny() && MobiusNCReady()){
                if (equipmentSelection[$slot[acc3]] == $item[none])
                    equipmentSelection[$slot[acc3]] = $item[M&ouml;bius ring];
            }
        }
        // A two-handed weapon leaves no off-hand to fill.
        if (guideRoute() && weapon_hands(equipmentSelection[$slot[weapon]]) > 1)
            remove equipmentSelection[$slot[off-hand]];
        foreach slo in equipmentSelection{
            if (available_amount(equipmentSelection[slo]) == 0)
                abort("Missing " + equipmentSelection[slo]);
            if (badMaxString(to_string(equipmentSelection[slo])))
                maximizerInput += ", equip [" + to_int(equipmentSelection[slo]) + "]";
            else
                maximizerInput += ", equip " + equipmentSelection[slo];
        }
        // A retired cozy scimitar stays whole for the next run.
        if (scimitarRetired())
            maximizerInput += ", -equip cozy scimitar";
        if (!maximize(maximizerInput, false))
            abort("Maximizer failed");
        // The maximizer may hold the club in the off-hand; the weapon it displaced moves there when it fits.
        item club = equipmentSelection[$slot[weapon]];
        item displaced = equipped_item($slot[weapon]);
        if (clubNeedsMainHand(guideRoute(), club, displaced)) {
            if (!equip($slot[weapon], club))
                print("Couldn't wield the " + club + " in the main hand.", "red");
            else if (displaced != $item[none] && weapon_hands(displaced) == 1 && available_amount(displaced) > 0
                && have_skill($skill[Double-Fisted Skull Smashing]) && equipped_item($slot[off-hand]) == $item[none]
                && !equip($slot[off-hand], displaced))
                print("Couldn't hold the " + displaced + " in the off-hand.", "red");
        }
        if (modes != "")
            cli_execute(modes);
    }

// Quest Related Functions
    string adjacentCaverns(int x_coor, int y_coor) {
        buffer buf;
        int [int] nums = {
            0: (8 * y_coor) + (x_coor - 1),
            1: (8 * y_coor) + (x_coor + 1),
            2: (8 * (y_coor - 1)) + x_coor,
            3: (8 * (y_coor + 1)) + x_coor
        };
        foreach i in nums {
            matcher m = create_matcher(
                "#" + nums[i] + "<img src=\"[^\"]*/([^\"]+)\\.gif\"",
                get_property("mineLayout3")
            );
            if (m.find())
                append(buf, to_string(m.group(1)));
        }
        return to_string(buf);
    }

    // The Anemone Mine spot to mine next, or 0 when no spot qualifies.
    int mineSpot(){
        int num, x_coor, y_coor;
        string itzmine = visit_url("mining.php?mine=3");
        matcher mining_spot = create_matcher(
            "Promising Chunk of Wall \\((\\d+),(\\d+)\\)", itzmine);

        // Try preferred spots first
        foreach str in $strings[(3\,6),(3\,5),(3\,4),(3\,3),(3\,2),(2\,2),(4\,2),(5\,2)] {
            if (!contains_text(itzmine, "Open Cavern " + str)) {
                matcher open_spot = create_matcher("(\\d),(\\d)", str);
                if (open_spot.find()) {
                    x_coor = to_int(open_spot.group(1));
                    y_coor = to_int(open_spot.group(2));
                    num = (8 * y_coor) + x_coor;
                    break;
                }
            }
        }

        // Fall back to promising chunks not near bad ore
        if (num == 0) {
            while (mining_spot.find()) {
                x_coor = to_int(mining_spot.group(1));
                y_coor = to_int(mining_spot.group(2));
                if (y_coor >= 4
                    || contains_text(adjacentCaverns(x_coor, y_coor), "velcroore")
                    || contains_text(adjacentCaverns(x_coor, y_coor), "vinylore"))
                    continue;
                num = (8 * y_coor) + x_coor;
                break;
            }
        }

        // Last resort: any promising chunk not too deep
        if (num == 0) {
            while (mining_spot.find()) {
                x_coor = to_int(mining_spot.group(1));
                y_coor = to_int(mining_spot.group(2));
                print(x_coor + ", " + y_coor);
                if (y_coor >= 4) continue;
                num = (8 * y_coor) + x_coor;
                break;
            }
        }
        return num;
    }

    int mineNum(){
        int num = mineSpot();
        if (num == 0)
            abort("Generic mining did not find teflon ore, mine manually. TIP: the ores show up in adjacent veins of 5.");
        return num;
    }

    int delevelers(){
        int n;
        foreach it in $items[Mer-kin mouthsoap,crayon shavings,table tennis ball,sea lasso,sea cowbell]
            if (item_amount(it) > 0)
                n += 1;
        return n;
    }

    void eatSushi(){
        string [item] sushi_map = {
            $item[beefy fish meat]:	        "beefy nigiri",
            $item[glistening fish meat]:	"glistening nigiri",
            $item[slick fish meat]:	        "slick nigiri"
        };
        foreach it in sushi_map{
            if (item_amount(it) > 0) {
                cli_execute("make " + sushi_map[it]);
                return;
            }
        }
    }

    boolean doneWithCowboy(){
        boolean bool = true;
        if (to_int(get_property("lassoTrainingCount")) + (3*item_amount($item[sea lasso])) < 23)
            bool = false;
        return bool;
    }

    boolean doneWithSeaCow(){
        boolean bool = true;
        if (item_amount($item[sea leather]) + available_amount($item[sea chaps]) + available_amount($item[sea cowboy hat]) < 2)
            bool = false;
        if (item_amount($item[sea cowbell]) < 3)
            bool = false;
        return bool;
    }

    void dreadSeedCheck(){
        if (seedPoss() == 1){
            for x from 1 to 8{
                if (get_property("dreadScroll" + x) == 0){
                    SeedData[int] possibleSeeds=find_seeds();
                    foreach idx, seed in possibleSeeds 
                        set_property("dreadScroll" + x,possibleSeeds[idx].dreadscroll[x-1]);
                }
            }
        } else {
            print(seedPoss() + " possible seeds right now");
        }
    }

    // The eight dreadScroll properties as digits, 0 where the answer is unknown.
    string dreadClues() {
        string clues;
        for x from 1 to 8
            clues += to_string(to_int(get_property("dreadScroll" + x)));
        return clues;
    }

    // Positions where two eight digit dreadscroll answers differ.
    int dreadMismatches(string a, string b) {
        if (length(a) != 8 || length(b) != 8)
            return 8;
        int miss;
        for i from 0 to 7
            if (char_at(a, i) != char_at(b, i))
                miss += 1;
        return miss;
    }

    // True when the answers agree with every known clue digit.
    boolean dreadFitsClues(string answers, string clues) {
        if (length(answers) != 8 || length(clues) != 8)
            return false;
        for i from 0 to 7
            if (char_at(clues, i) != "0" && char_at(clues, i) != char_at(answers, i))
                return false;
        return true;
    }

    // True when the answers fit every rejected "answers:wrong" entry of dreadScrollGuesses.
    boolean dreadFitsGuesses(string answers, string guesses) {
        foreach i, entry in split_string(guesses, ",") {
            string [int] part = split_string(entry, ":");
            if (part[0] == "")
                continue;
            int wrong = count(part) > 1 ? to_int(part[1]) : 0;
            int miss = dreadMismatches(answers, part[0]);
            if (miss == 0 || (wrong > 0 && miss != wrong))
                return false;
        }
        return true;
    }

    boolean dreadSeedTried(int seed, string tried) {
        return contains_text("," + tried + ",", "," + seed + ",");
    }

    string dreadTriedAdd(string tried, int seed) {
        return tried == "" ? to_string(seed) : tried + "," + seed;
    }

    // A seed worth trying: it fits the clues and the rejected guesses, and was not tried today.
    boolean dreadCandidate(string answers, int seed, string clues, string tried, string guesses) {
        return dreadFitsClues(answers, clues) && !dreadSeedTried(seed, tried) && dreadFitsGuesses(answers, guesses);
    }

    // "clues:answers" of this ascension's last seed guess, or empty when there is none.
    string dreadGuessStored() {
        string [int] part = split_string(get_property("utsDreadGuess"), ":");
        if (count(part) != 3 || to_int(part[0]) != my_ascensions() || length(part[1]) != 8 || length(part[2]) != 8)
            return "";
        return part[1] + ":" + part[2];
    }

    // True when the "clues:answers" guess still matches the dreadScroll properties.
    boolean dreadGuessMatches(string stored, string current) {
        string [int] part = split_string(stored, ":");
        return count(part) == 2 && part[1] == current;
    }

    // The stored guess while the properties still hold it. Properties edited by hand end the guessing.
    string dreadGuessActive() {
        string stored = dreadGuessStored();
        if (stored == "" || dreadGuessMatches(stored, dreadClues()))
            return stored;
        set_property("utsDreadGuess", "");
        print("The dreadScroll properties no longer hold the seed guess, so they are taken as set by hand.", "red");
        return "";
    }

    // The list part of an "ascension:list" property, empty when it belongs to another ascension.
    string dreadAscList(string value, int asc) {
        int cut = index_of(value, ":");
        if (cut < 1 || to_int(substring(value, 0, cut)) != asc)
            return "";
        return substring(value, cut + 1);
    }

    // The "ascension:list" value with the entry added, started over for a new ascension.
    string dreadAscAdd(string value, int asc, string entry) {
        string list = dreadAscList(value, asc);
        if (list == "")
            return asc + ":" + entry;
        if (contains_text("," + list + ",", "," + entry + ","))
            return asc + ":" + list;
        return asc + ":" + list + "," + entry;
    }

    // All eight dreadScroll properties set.
    boolean dreadAnswered() {
        return !contains_text(dreadClues(), "0");
    }

    // The one answer string every entry shares, or empty when they differ or there are none.
    string dreadAgreed(string [int] answers) {
        string common;
        foreach i, a in answers {
            if (common == "")
                common = a;
            else if (a != common)
                return "";
        }
        return common;
    }

    int dreadDistinct(string [int] answers) {
        boolean [string] seen;
        foreach i, a in answers
            seen[a] = true;
        return count(seen);
    }

    string seedAnswers(SeedData data) {
        string answers;
        for i from 0 to 7
            answers += to_string(data.dreadscroll[i]);
        return answers;
    }

    // Distinct dreadscroll answers among seedfinder's seeds. When they all agree, the unset properties are filled.
    int dreadAnswersLeft() {
        SeedData[int] seeds = find_seeds();
        string [int] list;
        foreach idx, data in seeds
            list[count(list)] = seedAnswers(data);
        string agreed = dreadAgreed(list);
        if (agreed != "")
            for x from 1 to 8
                if (to_int(get_property("dreadScroll" + x)) == 0)
                    set_property("dreadScroll" + x, char_at(agreed, x - 1));
        return dreadDistinct(list);
    }

    // Sets the dreadscroll answers from one untried seedfinder seed that fits the clues and the rejected answers.
    // False, with the clue properties restored, when no such seed is left.
    boolean dreadGuessNext() {
        string clues = dreadClues();
        string stored = dreadGuessActive();
        if (stored != "") {
            string [int] part = split_string(stored, ":");
            clues = part[0];
        }
        for x from 1 to 8
            set_property("dreadScroll" + x, char_at(clues, x - 1));
        string tried = get_property("_utsDreadTriedSeeds");
        string rejected = get_property("dreadScrollGuesses") + "," + dreadAscList(get_property("utsDreadRejected"), my_ascensions());
        SeedData[int] seeds = find_seeds();
        foreach idx, data in seeds {
            string answers = seedAnswers(data);
            if (!dreadCandidate(answers, data.seed, clues, tried, rejected))
                continue;
            set_property("_utsDreadTriedSeeds", dreadTriedAdd(tried, data.seed));
            set_property("utsDreadGuess", my_ascensions() + ":" + clues + ":" + answers);
            for x from 1 to 8
                set_property("dreadScroll" + x, char_at(answers, x - 1));
            print("Trying ascension seed " + data.seed + " of the " + count(seeds)
                + " seedfinder still lists: dreadscroll answers " + answers + ".", "blue");
            return true;
        }
        return false;
    }

    // The Gelatinous Cubeling's three Daily Dungeon drops held.
    int cubelingDropsHeld() {
        int held;
        foreach it in $items[eleven-foot pole, ring of Detect Boring Doors, Pick-O-Matic lockpicks]
            if (available_amount(it) > 0)
                held += 1;
        return held;
    }

    boolean cheatsheetsNeeded() {
        return item_amount($item[mer-kin cheatsheet]) < 9
            && get_property("merkinVocabularyMastery") == "0";
    }

    int [item] HealingHP = {
        $item[sea gel]:500,
        $item[mer-kin healscroll]:300,
        $item[waterlogged scroll of healing]:250,
        $item[soggy used band-aid]:1000,
        $item[New Age healing crystal]:500
    };

    float trueHPPercent(){
        float n;
        n = round((my_maxhp() - numeric_modifier("maximum hp"))/(my_buffedstat($stat[muscle]) + 3)*100);
        n = n/100;
        return n;
    }

    int [int] YogHealingsNeeded = {
        0:21,
        1:5,
        2:3,
        3:1
    };

    // Defined with the low IOTM pulls.
    boolean guidePullOne(item it);

    int YogHealingsOwned(){
        int n;
        foreach it in $items[sea gel,mer-kin healscroll,waterlogged scroll of healing,soggy used band-aid,New Age healing crystal]{
            if (available_amount(it) > 0)
                n += 1;
        }
        return n;
    }

    boolean YogHpCheck(){
        int maxHeal = 1001;
        int n;
        // Same order yogHealing() throws them in. Iterating the HealingHP map
        // instead walks item id order, so when fewer healings are needed than
        // are owned, this counted items the fight never reaches.
        foreach it in $items[sea gel,mer-kin healscroll,waterlogged scroll of healing,soggy used band-aid,New Age healing crystal] {
            if (n >= (available_amount($item[mer-kin prayerbeads]) <= 3 ? YogHealingsNeeded[available_amount($item[mer-kin prayerbeads])] : 1))
                break;
            if (available_amount(it) > 0){
                if (HealingHP[it] < maxHeal)
                    maxHeal = HealingHP[it];
                n += 1;
            }
        }
        int predictedMus = round(30 * (1+(numeric_modifier("Muscle Percent")/100)))+numeric_modifier("Muscle");
        print ("Predicted Mus "+ predictedMus);
        int predictedHP = round((predictedMus+3)*trueHPPercent()) + numeric_modifier("maximum hp");
        print ("predicted HP " + predictedHP);
        if (predictedHP*0.9*2 > (predictedHP+maxHeal)){
            if (have_effect($effect[gummiheart]) > 0) {
                if (item_amount($item[soft green echo eyedrop antidote]) == 0
                    && pulls_remaining() > reservedPulls()) {
                    // The guide route's pull skips a price over autoBuyPriceLimit instead of prompting.
                    if (guideRoute()) {
                        boolean pulled = guidePullOne($item[soft green echo eyedrop antidote]);
                    } else
                        pullSequence($item[soft green echo eyedrop antidote]);
                }
                if (item_amount($item[soft green echo eyedrop antidote]) > 0)
                    cli_execute("uneffect gummiheart");
            } else
                return false;
            if (have_effect($effect[gummiheart]) > 0)
                return false;
        }
        return true;
    }

//Non-equipment iotm related functions
    boolean parkaForceAvailable(){
        if (have_item($item[jurassic parka]) && to_int(get_property("_spikolodonSpikeUses")) < 5)
            return true;
        return false;
    }

    boolean leftSkiAvailable(){
        if (have_item($item[mchugelarge left ski]) && to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
            return true;
        return false;
    }

    boolean doSWord(){
        if (have_familiar($familiar[Sword of S Words]) && to_int(get_property("swordOfSWordsMonster")) == 776){
            if (highShiny() && item_amount($item[sea lasso]) < 7)
                return true;
            if (!have_item($item[closed-circuit pay phone]) && item_amount($item[sea lasso]) < 4)
                return true;
        }
        return false;
    }
    
    void useAutumnaton(){
        use($item[autumn-aton]);
        string [string] upgradeLocation = {
            "mid indoor":"rightleg1",
            "low underground":"leftleg1",
            "mid outdoor":"rightarm1",
            "low indoor":"leftarm1",
            "high underground":"collectionprow1"
        };
        string autumnOptions = visit_url("inv_use.php?" + my_hash() + "&which=3&whichitem=10954");
        int [int] locations;
        matcher m = create_matcher(
            "<option\\s+value=\"([0-9]+)\">\\s*([^<]+?)\\s*</option>",
            autumnOptions
        );

        int n;
        while (m.find()) {
            int id = to_int(m.group(1));
            string name = m.group(2);
            locations[n] = id;
            n += 1;
        }

        foreach key in locations {
            if (locations[key] == to_int($location[anemone mine]) && available_amount($item[mer-kin digpick]) == 0){
                cli_execute("autumnaton send anemone mine");
                return;
            }
        }
        foreach key in locations {
            if (locations[key] == to_int($location[Shadow Rift (The Misspelled Cemetary)])){
                cli_execute("autumnaton send Shadow Rift");
                return;
            }
        }
        foreach key in locations {
            string type = (to_location(locations[key]).difficulty_level + " " + to_location(locations[key]).environment);
            if (!contains_text(get_property("autumnatonUpgrades"),upgradeLocation[type]) && upgradeLocation[type] != ""){
                cli_execute("autumnaton send " + to_location(locations[key]));
                return;
            }
        }
        cli_execute("autumnaton send noob cave");
        return;
    }

    // Peridot monster for each zone.
    int [location] wantedMonster = {
        $location[An Octopus's Garden]:                 740,   // Neptune flytrap
        $location[The Wreck of the Edgar Fitzsimmons]:  745,   // unholy diver
        $location[The Sleazy Back Alley]:               159,
        $location[The Haunted Pantry]:                  145,
        $location[The Overgrown Lot]:                   1752,
        $location[The Coral Corral]:                    775,   // sea cow
        $location[The Marinara Trench]:                 762,
        $location[Anemone Mine]:                        765,
        $location[The Dive Bar]:                        768,
        $location[Cyberzone 1]:                         2458,
        $location[Mer-kin Library]:                     840,   // Mer-kin researcher
        $location[the mer-kin outpost]:                 773,
        $location[the caliginous abyss]:                1373,
        $location[mer-kin elementary school]:           838,   // Mer-kin teacher
        $location[The Outskirts of Cobb's Knob]:        152,
        $location[Madness Bakery]:                      1750
    };

// Something about cheatsheetsand peridot
int zoneTarget(location loc) {
    if (loc == $location[mer-kin elementary school] && cheatsheetsNeeded())
        return 852;   // Mer-kin monitor
    if (wantedMonster contains loc)
        return wantedMonster[loc];
    return 0;
}

boolean [monster] haveLocketMonster = get_locket_monsters();

// ─── FOURTH OF MAY COSPLAY SABER ──────────────────────────────────────────────
// Use the Force forfeits the win and burns no turn, so saberZone() only
// allows it where the loop is purely on an item count -- never where
// progress gates on wins or turns spent (the outpost lockkey).

boolean saberReady() {
    return have_item($item[Fourth of May Cosplay Saber])
        && get_property("_saberForceUses").to_int() < 5;
}

// False in zones that gate progress on turns spent rather than on drops.
boolean saberZone(location loc) {
    return !($locations[The Mer-Kin Outpost] contains loc);
}

// Equip the saber only where a turn-free exit actually buys us something.
// Takes the target location explicitly because callers set equipment up
// before adv(), so my_location() is still the previous zone here.
string saberEquip(location loc) {
    if (saberReady() && saberZone(loc))
        return if_equip($item[Fourth of May Cosplay Saber]);
        return "";
}

// ─── DETERMINISTIC DIVER PLAN ─────────────────────────────────────────────────
// One Forced diver is a guaranteed 4 rivets + porthole + helmet (its whole
// payload is non-conditional), independent of item bonus.

// The rusty diving helmet takes 1 broken helmet + 1 porthole + 8 rivets, so
// a rivet count alone only settles the hunt under the Force plan, where one
// Forced diver delivers all three at once. Off that plan the three drops roll
// independently, and a dolphin can take any of them.
boolean diverPartsComplete() {
    // The craft consumes all three, so an assembled helmet is the done state.
    if (available_amount($item[rusty diving helmet]) > 0)
        return true;
    return item_amount($item[rusty rivet]) >= 8
        && item_amount($item[rusty porthole]) > 0
        && available_amount($item[rusty broken diving helmet]) > 0;
}

// The rivet hunt is live while nothing that fills the diving-helmet slot is
// owned.
boolean diverHuntActive() {
    if (diverPartsComplete())
        return false;
    return to_slot(divingHelmet()) != $slot[hat];
}

// Mirrors doneWithSeaCow() in UnderTheSea.ash, which parse order keeps out of
// reach of this file.
boolean seaCowNeeded() {
    if (item_amount($item[sea leather]) + available_amount($item[sea chaps])
        + available_amount($item[sea cowboy hat]) < 2)
        return true;
    if (item_amount($item[sea cowbell]) < 3)
        return true;
    return false;
}

boolean prayerbeadsShort() {
    return available_amount($item[mer-kin prayerbeads]) < 3;
}

// Whether a dolphin's item is still worth a turn. The predicates above answer
// that, so ask them rather than restating their numbers.
boolean stillWanted(item it) {
    switch (it) {
    case $item[rusty broken diving helmet]:
    case $item[rusty porthole]:
    case $item[rusty rivet]:
        return diverHuntActive();
    case $item[sea leather]:
        return seaCowNeeded();
    case $item[Mer-kin cheatsheet]:
        // One is consumed per wordquiz, and each quiz is ten of the ninety wanted.
        return item_amount($item[Mer-kin cheatsheet]) * 10
            < 90 - to_int(get_property("merkinVocabularyMastery"));
    case $item[Mer-kin prayerbeads]:
        return prayerbeadsShort();
    case $item[Mer-kin bunwig]:
        return available_amount($item[mer-kin bunwig]) == 0;
    case $item[Mer-kin digpick]:
        // Only the low IOTM route mines the teflon ore with a dropped digpick.
        return guideRoute() && available_amount($item[Mer-kin digpick]) == 0
            && item_amount($item[teflon ore]) == 0 && tailpiece() == $item[none];
    }
    // The rest are thrown or spent, so what the run wants of them moves. The
    // cowbell and the lasso outlive the seahorse as Yog-Urt delevelers.
    return true;
}

// ─── THE FORCE BUDGET ─────────────────────────────────────────────────────────
// 5 saber forces, 2 alloted for unholy diver
int saberChargesLeft() {
    if (!have_item($item[Fourth of May Cosplay Saber]))
        return 0;
    return 5 - get_property("_saberForceUses").to_int();
}

boolean diverForceReady() {
    return diverHuntActive() && saberChargesLeft() > 0;
}

// Charges available to each claimant, after every higher-priority claim.
int forcesAfterDiver() {
    return saberChargesLeft() - (diverHuntActive() ? 2 : 0);
}
int forcesAfterHealer() {
    return forcesAfterDiver() - (prayerbeadsShort() ? 1 : 0);
}
int saberForcesFree() {
    return forcesAfterHealer() - (seaCowNeeded() ? 1 : 0);
}

// Weapon-slot pin for the summoned diver fights, so the Force is castable.
string diverSaber() {
    if (diverForceReady())
        return "Fourth of May Cosplay Saber,";
    return "";
}

// The egg is capped at 11 a day and costs 50 familiar experience. A bare
// cast that fails sets the error state, which ends the run at the next
// statement -- mid-combat, from a consult script -- so check the page too:
// to_string() on this skill yields the literal %fn, which never matches.
void layMimicEgg(string page_text) {
    if (my_familiar() != $familiar[chest mimic])
        return;
    if (get_property("_mimicEggsObtained").to_int() >= 11)
        return;
    if ($familiar[chest mimic].experience < 50)
        return;
    if (!contains_text(page_text, "lay an egg"))
        return;
    use_skill($skill[%fn, lay an egg]);
}

// CCS entry. On the diver: lay the insurance egg for diver #2 while the fight
// is still open, then Force the drops. Returns true when it Forced -- the
// combat is over and the caller must end the consult pass.
boolean diverForce(monster mob, string page_text) {
    if (mob != $monster[unholy diver])
        return false;
    if (!diverForceReady())
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    layMimicEgg(page_text);
    step("Use the Force -> unholy diver (rivets " + item_amount($item[rusty rivet]) + "/8)");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── SEA COW: THE SAME TRICK AT THE CORRAL ────────────────────────────────────
// One Forced cow is a guaranteed leather + cowbell (both non-conditional).

// CCS entry, same contract as diverForce(): true means the fight is over and
// the caller must end the consult pass.
boolean seaCowForce(monster mob, string page_text) {
    if (mob != $monster[sea cow])
        return false;
    if (!seaCowNeeded())
        return false;
    if (forcesAfterHealer() <= 0)
        return false;
    if (have_equipped($item[pro skateboard]) && get_property("_epicMcTwistUsed") == "false")
        return false;
    if ($location[the coral corral].turns_spent <= 1
        && item_amount($item[sea leather]) == 0
        && available_amount($item[sea cowboy hat]) == 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> sea cow");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── OUTPOST HEALER AND LIBRARY RESEARCHER ────────────────────────────────────
boolean healerForce(monster mob, string page_text) {
    if (mob != $monster[Mer-kin healer])
        return false;
    if (!prayerbeadsShort())
        return false;
    if (forcesAfterDiver() <= 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> Mer-kin healer (prayerbeads)");
    use_skill($skill[Use the Force]);
    return true;
}

string healerSaber() {
    if (prayerbeadsShort()
        && forcesAfterDiver() > 0
        && have_item($item[Fourth of May Cosplay Saber]))
        return "Fourth of May Cosplay Saber,";
    return "";
}

boolean researcherForce(monster mob, string page_text) {
    if (mob != $monster[Mer-kin researcher])
        return false;
    if (item_amount($item[mer-kin killscroll]) > 0
        && item_amount($item[mer-kin healscroll]) > 0)
        return false;
    if (saberForcesFree() <= 0)
        return false;
    if (!have_equipped($item[Fourth of May Cosplay Saber]))
        return false;
    if (!contains_text(page_text, "Use the Force"))
        return false;
    step("Use the Force -> Mer-kin researcher (scrolls)");
    use_skill($skill[Use the Force]);
    return true;
}

// ─── ROUTE-SPECIFIC SHARED HELPERS ───────────────────────────────────────────

// Keep duplicate.edu in an educate slot so Duplicate is castable in combat;
// duplicateMonster() below spends the one daily cast.
boolean duplicateEducated() {
    return get_property("sourceTerminalEducate1") == "duplicate.edu"
        || get_property("sourceTerminalEducate2") == "duplicate.edu";
}

boolean duplicateReady() {
    if (get_campground()[$item[Source terminal]] == 0)
        return false;
    if (get_property("_sourceTerminalDuplicateUses").to_int() >= 1)
        return false;
    return contains_text(get_property("sourceTerminalEducateKnown"), "duplicate.edu");
}

void sourceEducate() {
    if (!duplicateReady() || duplicateEducated())
        return;
    cli_execute("terminal educate duplicate.edu");
}

// CCS entry, cast at the top of the fight so nothing ends it first.
void duplicateMonster(monster mob, string page_text) {
    if (!duplicateReady() || !duplicateEducated())
        return;
    // Doubling pays only on a WIN, so never spend the day's cast on a fight
    // the saber is about to Force.
    boolean aboutToForce = have_equipped($item[Fourth of May Cosplay Saber])
        && ((mob == $monster[unholy diver] && diverForceReady())
            || (mob == $monster[sea cow] && seaCowNeeded() && forcesAfterHealer() > 0));
    if (aboutToForce)
        return;
    // Best killed tables the route meets: the golem (free fight, flat 100%
    // crayon shavings -- the Shub deleveler), then the unForced sea cow, the
    // sheet-grind monitor, and the diver only on saberless kits, where a
    // doubled kill rolls its whole table twice.
    boolean wanted = (mob == $monster[Black Crayon Golem] && item_amount($item[crayon shavings]) < 4)
        || (mob == $monster[sea cow] && seaCowNeeded() && !diverHuntActive())
        || (mob == $monster[Mer-kin monitor] && cheatsheetsNeeded())
        || (mob == $monster[unholy diver] && !diverPartsComplete()
            && !have_item($item[Fourth of May Cosplay Saber]));
    if (!wanted)
        return;
    if (!contains_text(page_text, "Duplicate"))
        return;
    step("Duplicate: " + mob);
    use_skill($skill[Duplicate]);
}

// ─── EIGHT DAYS A WEEK PILL KEEPER ────────────────────────────────────────────
// Take only the daily free pill -- the rest cost spleen the diet needs.
// `pill` is a mafia pillkeeper keyword, not a pill name.
void pillKeeper(string pill) {
    if (!have_item($item[Eight Days a Week Pill Keeper]))
        return;
    if (get_property("_freePillKeeperUsed") != "false")
        return;
    step("Pill keeper: " + pill);
    cli_execute("pillkeeper " + pill);
}

// ─── VAMPYRIC CLOAKE ──────────────────────────────────────────────────────────
// Pinned to the back slot so Become a Bat stays castable; all 10 daily form
// uses go to the bat.
boolean cloakeReady() {
    return have_item($item[vampyric cloake])
        && get_property("_vampyreCloakeFormUses").to_int() < 10;
}

// Only the zones we grind purely for a drop count. Anywhere gated on turns spent
// or on finding a noncombat, a bigger item bonus buys nothing, and there are
// only 10 charges to spread across the run.
boolean cloakeZone(location loc) {
    return $locations[The Wreck of the Edgar Fitzsimmons, An Octopus's Garden,
        The Coral Corral, Mer-kin Library, Mer-kin Elementary School] contains loc;
}

// Pins the cloake into the back slot so the skill is actually available in
// combat. Callers set gear up before adv(), so the target zone is passed in
// explicitly -- my_location() is still the previous zone at that point.
string cloakeEquip(location loc) {
    if (cloakeReady() && cloakeZone(loc))
        return "vampyric cloake,";
    return "";
}

// Cast from the CCS at the top of every round. Cheap to call repeatedly: once
// the form is up, have_effect() short-circuits it, which also enforces the
// one-form-per-combat rule for free.
void becomeBat(string page_text) {
    if (!cloakeReady() || !cloakeZone(my_location()))
        return;
    if (have_effect($effect[Bat-Adjacent Form]) > 0)
        return;
    if (!have_equipped($item[vampyric cloake]))
        return;
    if (!contains_text(page_text, "Become a Bat"))
        return;
    use_skill($skill[Become a Bat]);
}

// ─── MAP THE MONSTERS ─────────────────────────────────────────────────────────
// Comprehensive Cartography gives 3 casts a day. Each turns the next fight in a
// zone into a monster of your choosing -- the same job as the Peridot of Peril,
// answered in UnderTheSea_Choice.ash from the same wantedMonster table.
//
// The Peridot is once per zone per day; these are the extra charges once the
// Peridot's is spent, longest odds first. The outpost is excluded: its
// lockkey gates on turns spent, so a chosen encounter saves nothing there.

boolean mapReady() {
    return have_skill($skill[Map the Monsters])
        && get_property("_monstersMapped").to_int() < 3
        && get_property("mappingMonsters") == "false";
}

// Only cast once the Peridot's charge for this zone is gone, so the two do not
// both spend themselves picking the same monster.
void mapMonster(location loc) {
    if (!mapReady())
        return;
    if (available_amount($item[peridot of peril]) > 0
        && !gotPeriled(loc))
        return;
    step("Map the Monsters armed for " + loc);
    use_skill($skill[Map the Monsters]);
}

// ─── TIME-SPINNER ─────────────────────────────────────────────────────────────
// mafia's "timespinner" CLI covers only food and pranks, so Travel to a
// Recent Fight's choice chain (1195 -> 1196, monid submit) is walked by hand.

boolean timeSpinnerReady() {
    return have_item($item[Time-Spinner])
        && to_int(get_property("_timeSpinnerMinutesUsed")) <= 7
        && my_adventures() > 0;
}

// Re-fight `mon` for one turn, guaranteed. Only fires straight after fighting
// that monster (last_monster()), which keeps it inside the recent-fights
// window without guessing at the window's exact size -- and works after
// summoned or Forced fights too, since the list records encounters, not wins.
boolean timeSpinnerFight(monster mon) {
    if (!timeSpinnerReady())
        return false;
    if (last_monster() != mon)
        return false;

    step("Time-Spinner: refighting " + mon);
    visit_url("inv_use.php?whichitem=" + to_int($item[Time-Spinner]) + "&pwd=" + my_hash());
    // mafia auto-resolves choices it has handling for, even on visit_url; if
    // nothing is live any manual answer would abort with "Invalid choice".
    if (!handling_choice()) {
        step("Time-Spinner choice was auto-resolved or never opened; skipping");
        return false;
    }
    int travel;
    int backOut;
    foreach num, optionText in available_choice_options() {
        if (contains_text(optionText, "Travel to a Recent Fight"))
            travel = num;
        if (contains_text(optionText, "Maybe Later"))
            backOut = num;
    }
    // Never leave the run parked inside a choice we could not read.
    if (travel == 0) {
        if (backOut > 0)
            run_choice(backOut);
        return false;
    }
    run_choice(travel);
    run_choice(1, "monid=" + to_int(mon));
    // The monid submit drops us into the fight; without this the session is
    // left mid-combat and the next adv() errors out.
    run_combat();
    return true;
}

void timeSpinnerRefight(location loc) {
    int target = zoneTarget(loc);
    if (target == 0)
        return;
    // Only worth a turn where the target is genuinely rare; these are the same
    // zones Map the Monsters spends its charges on.
    if (my_location() != loc)
        return;
    timeSpinnerFight(to_monster(target));
}

// ─── POCKET PROFESSOR ─────────────────────────────────────────────────────────
// The next lecture needs buffed familiar weight of n^2 + 1 lbs.
int professorLectureLimit() {
    int w = familiar_weight($familiar[Pocket Professor]) + weight_adjustment();
    int n;
    while ((n * n + 1) <= w)
        n += 1;
    return n;
}

boolean professorReady() {
    return have_familiar($familiar[Pocket Professor])
        && get_property("_pocketProfessorLectures").to_int() < professorLectureLimit();
}

void professorFamiliar() {
    if (!professorReady())
        return;
    // Rivet hunt: under the Force plan a diver pays 4 guaranteed rivets and
    // the second one is a Time-Spinner refight away -- lecture copies add
    // nothing, so keep the better drop familiar out.
    if (diverHuntActive()) {
        if (!diverForceReady())
            use_familiar($familiar[Pocket Professor]);
        return;
    }
    // Corral: once the Force budget there is spent, lecture copies of the sea
    // cow are the next cheapest source of leather and cowbells.
    if (seaCowNeeded() && forcesAfterHealer() <= 0) {
        use_familiar($familiar[Pocket Professor]);
        return;
    }
    // Otherwise the route still wants a familiar with good item drop while the
    // professor's lecture copies are still free.
    if (!have_familiar($familiar[Chest Mimic]))
        use_familiar($familiar[Pocket Professor]);
}

void lectureOnRelativity(monster mob, string page_text) {
    if (!professorReady())
        return;
    if (my_familiar() != $familiar[Pocket Professor])
        return;
    // Same targets as professorFamiliar(): the diver while rivets are owed,
    // the sea cow while its drops are.
    boolean wanted = (mob == $monster[unholy diver] && !diverPartsComplete())
        || (mob == $monster[sea cow] && seaCowNeeded());
    if (!wanted)
        return;
    // The skill refuses to fire below 2 adventures, even against a free fight.
    if (my_adventures() < 2)
        return;
    if (!contains_text(page_text, "lecture on relativity"))
        return;
    step("Lecture on Relativity: chaining a free " + mob);
    use_skill($skill[lecture on relativity]);
}

// ─── JANUARY'S GARBAGE TOTE: BROKEN CHAMPAGNE BOTTLE ──────────────────────────
// The bottle's ounces are spent only at the fattest rolled tables.
boolean champagneReady() {
    return have_item($item[broken champagne bottle])
        && get_property("garbageChampagneCharge").to_int() > 0;
}

// Only where a fat table is being ROLLED. Forced drops ignore item bonus, so
// while a Force plan covers the zone the ounces are banked instead.
string champagneEquip(location loc) {
    if (!champagneReady())
        return "";
    if (loc == $location[The Wreck of the Edgar Fitzsimmons] && !diverForceReady())
        return if_equip($item[broken champagne bottle]);
    // The corral inherits the bottle once the Force budget there is spent and
    // the cow's leather/cowbell rolls are back to probability.
    if (loc == $location[The Coral Corral] && seaCowNeeded() && forcesAfterHealer() <= 0)
        return if_equip($item[broken champagne bottle]);
    return "";
}

// Pull the bottle out of the tote once, if we own a tote and have not already
// spent its charges this ascension.
void garbageTote() {
    if (!have_item($item[January's Garbage Tote]))
        return;
    if (have_item($item[broken champagne bottle]))
        return;
    if (get_property("garbageChampagneCharge").to_int() <= 0)
        return;
    step("Garbage tote: fetching the broken champagne bottle");
    visit_url("inv_use.php?whichitem=" + $item[January's Garbage Tote].to_int() + "&pwd=" + my_hash());
    // Same auto-resolution caveat as everywhere: only answer a LIVE choice.
    if (!handling_choice()) {
        step("Tote choice was auto-resolved or never opened; skipping");
        return;
    }
    int grab;
    int leave;
    foreach num, optionText in available_choice_options() {
        if (contains_text(optionText, "champagne"))
            grab = num;
        if (contains_text(optionText, "Ignore the garbage"))
            leave = num;
    }
    // Never leave the run parked inside a choice we could not read.
    if (grab > 0)
        run_choice(grab);
    else if (leave > 0)
        run_choice(leave);
}

// ─── POWERFUL GLOVE ───────────────────────────────────────────────────────────
// Equipped only at re-roll sites, and only once Macrometeorite's casts are
// gone.
boolean gloveReady() {
    return have_item($item[Powerful Glove])
        && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90;
}

// ─── METEOR LORE: MACROMETEORITE ──────────────────────────────────────────────
// Same re-roll as the glove's CHEAT CODE but from a skill; rerollEnemy()
// spends these casts first.
boolean macroReady() {
    return have_skill($skill[Macrometeorite])
        && get_property("_macrometeoriteUses").to_int() < 10;
}

string gloveEquip(location loc) {
    // Macrometeorite does the same job from a skill slot; while it has casts
    // left, the accessory slot goes back to the zirconia and backup camera.
    if (macroReady())
        return "";
    if (gloveReady() && loc == $location[The Wreck of the Edgar Fitzsimmons])
        return if_equip($item[Powerful Glove]);
    return "";
}

// ─── MUMMING TRUNK ────────────────────────────────────────────────────────────
// A second costume overwrites the first, so Prince George goes on whichever
// familiar the item setup actually picks -- hence called from
// use_familiar("itdrop") rather than at a fixed point in the run.
void mummery() {
    if (!have_item($item[mumming trunk]))
        return;
    // _mummeryMods records what has already been applied today; an Item Drop entry means Prince George is spent.
    if (contains_text(get_property("_mummeryMods"), "Item Drop"))
        return;
    if (my_familiar() == $familiar[none])
        return;
    cli_execute("mummery item");
}

// ─── REROLL / REPLACE / FEEL NOSTALGIC / OTOSCOPE ─────────────────────────
// These are called by UnderTheSeaCCS.ash directly.

// ─── SPACE JELLYFISH ──────────────────────────────────────────────────────────
// Extract stench jelly for NCforce(); jelly costs spleen the diet needs, so
// exactly one is taken.
boolean jellyfishReady() {
    return have_familiar($familiar[Space Jellyfish]);
}

void extractJelly(monster mob, string page_text) {
    if (my_familiar() != $familiar[Space Jellyfish])
        return;
    if (mob.attack_element != $element[stench] && mob.defense_element != $element[stench])
        return;
    // Spleen is contested; one forced noncombat is all we are after.
    if (item_amount($item[stench jelly]) > 0)
        return;
    if (!contains_text(page_text, "Extract Jelly"))
        return;
    use_skill($skill[Extract Jelly]);
}

// Casts whichever re-roller is available: Macrometeorite (Meteor Lore, 10 a
// day, no equipment slot) first, the glove's CHEAT CODE second. On true the
// fight holds a NEW monster and the caller MUST re-dispatch the CCS main()
// with last_monster() and a re-fetched fight page -- a bare return would fall
// through to the CCS's safety abort, since mafia does not re-invoke a consult
// script that returns mid-combat.
boolean rerollEnemy(string page_text) {
    if (macroReady() && contains_text(page_text, "Macrometeorite")) {
        step("Macrometeorite: re-rolling the monster");
        use_skill($skill[Macrometeorite]);
        return true;
    }
    if (gloveReady() && have_equipped($item[Powerful Glove])
        && contains_text(page_text, "CHEAT CODE: Replace Enemy")) {
        step("CHEAT CODE: re-rolling the monster");
        use_skill($skill[CHEAT CODE: Replace Enemy]);
        return true;
    }
    return false;
}

// Fitzsimmons policy: re-roll anything that is not the diver while rivets are
// still owed.
boolean replaceEnemy(monster mob, string page_text) {
    if (my_location() != $location[The Wreck of the Edgar Fitzsimmons])
        return false;
    // Never re-roll a free fight: it costs nothing, burns delay, and dies to
    // the location logic's fall-through kill.
    if (free_monster(mob))
        return false;
    // Never re-roll the monster we came for, and stop once its drops are in.
    if (mob == $monster[unholy diver])
        return false;
    if (diverPartsComplete())
        return false;
    return rerollEnemy(page_text);
}

// ─── EMOTION CHIP: FEEL NOSTALGIC ─────────────────────────────────────────────
// Feel Nostalgic pays only on a WIN and does nothing cast on the monster
// being copied.
void feelNostalgic(monster mob, string page_text) {
    if (!have_skill($skill[Feel Nostalgic]))
        return;
    if (get_property("_feelNostalgicUsed").to_int() >= 3)
        return;
    // The appended drops only pay out if this fight is WON. When the saber
    // still has Force charges the rest of the script may spend, free_kill()
    // may Use the Force out of the combat, forfeiting the win and the charge
    // with it -- so never overlap the two.
    if (saberForcesFree() > 0 && have_equipped($item[Fourth of May Cosplay Saber]))
        return;
    // Worth a charge only while the copied table still owes us something:
    // the diver's rivets, the sea cow's leather and cowbells, or the
    // monitor's cheatsheet (~capped at itdrop bonuses) during the grind.
    string copied = get_property("lastCopyableMonster");
    boolean wanted = (copied == "unholy diver" && !diverPartsComplete())
        || (copied == "sea cow" && seaCowNeeded())
        || (copied == "Mer-kin monitor" && cheatsheetsNeeded());
    if (!wanted)
        return;
    // Casting it on the monster we are nostalgic for does nothing.
    if (mob.to_string() == copied)
        return;
    if (!contains_text(page_text, "Feel Nostalgic"))
        return;
    step("Feel Nostalgic: re-rolling the " + copied + " table");
    use_skill($skill[Feel Nostalgic]);
}

// ─── LIL' DOCTOR BAG: OTOSCOPE ────────────────────────────────────────────────
// freeKill() equips the bag for Chest X-Ray; Otoscope rides along, cast
// early so free_kill() cannot end the fight first. Reflex Hammer is wired
// into free_run() with the other banishes.
void otoscope(monster mob, string page_text) {
    // A fight the saber is about to Force has its drops forced anyway; the
    // +200% would be a wasted charge.
    if (diverForceReady() && have_equipped($item[Fourth of May Cosplay Saber]))
        return;
    if (get_property("_otoscopeUsed").to_int() >= 3)
        return;
    if (!have_equipped($item[Lil' Doctor&trade; bag]))
        return;
    if (mob != $monster[unholy diver])
        return;
    if (diverPartsComplete())
        return;
    if (!contains_text(page_text, "Otoscope"))
        return;
    step("Otoscope on " + mob);
    use_skill($skill[Otoscope]);
}

// Roughly how many noncombat forces this account can field. Deliberately does
// NOT count the Pill Keeper: this is the number we use to decide whether the
// free pill needs reserving for Sneakisol, so counting it would be circular.
int NCForceEstimate(){
    int force = 2;
    // Counts remaining CHARGES, not ownership.
    if (have_item($item[Apriling band tuba]))
        force += max(0, 3 - to_int(get_property("_aprilBandTubaUses")));
    if (have_item($item[McHugeLarge left ski]))
        force += max(0, 3 - to_int(get_property("_mcHugeLargeAvalancheUses")));
    if (have_item($item[Cincho de Mayo]))
        force += min(3, 1 + max(0, total_free_rests() - to_int(get_property("timesRested"))) / 2);
    if (have_item($item[Jurassic Parka]))
        force += max(0, 5 - to_int(get_property("_spikolodonSpikeUses")));
    return force;
}

// ─── SOURCE TERMINAL ──────────────────────────────────────────────────────────
// items.enh is re-upped wherever +item setup already happens.

void sourceEnhance() {
    if (get_campground()[$item[Source terminal]] == 0)
        return;
    if (have_effect($effect[items.enh]) > 0)
        return;
    if (get_property("_sourceTerminalEnhanceUses").to_int() >= 3)
        return;
    cli_execute("terminal enhance items.enh");
}

// ─── REMAINING SHARED HELPERS ───────────────────────────────────────────────
// These were previously split across iotm.ash and are now consolidated here so
// UnderTheSea.ash and UnderTheSeaCCS.ash can share a single helper module.

void cargoPocket() {
    if (get_property("cargoPocketsEmptied") == "")
        set_property("cargoPocketsEmptied", "");
    // Comma-delimited match so a pocket number cannot match inside another.
    if (contains_text("," + get_property("cargoPocketsEmptied") + ",", ",494,"))
        return;
    step("Cargo shorts: opening pocket 494");
    cli_execute("cargo pocket 494");
}

// ─── KREMLIN'S GREATEST BRIEFCASE ─────────────────────────────────────────────
// Driven through Ezandora's Briefcase script, which owns the dial, handle
// and tab state machine; "briefcase buff item" clicks until Items Are
// Forever lands.
void briefcase() {
    if (!have_item($item[Kremlin's Greatest Briefcase]))
        return;
    if (have_effect($effect[Items Are Forever]) > 0)
        return;
    // An unopened case has no tabs to read, so asking for a buff would only
    // burn clicks. Opening it is a two-day job and not something a run should
    // be spending its budget on.
    if (get_property("_kgbOpened") == "false")
        return;
    if (get_property("_kgbClicksUsed").to_int() >= 22)
        return;
    cli_execute("briefcase buff item");
}

// ─── NONCOMBAT FORCER ─────────────────────────────────────────────────────────
// Spend the cheapest available forcer charge; NCForceEstimate() counts what
// remains.

boolean restWouldCostFury();

boolean guideForcerUsable(item it) {
    if (it == $item[stench jelly])
        return spleen_limit() - my_spleen_use() >= 1;
    if (it == $item[Clara's bell])
        return get_property("_claraBellUsed") != "true";
    return true;
}

// The low IOTM guide's forcers: stench jelly, Clara's bell, then a handheld Allied radio.
// One on hand goes first, else one is pulled, at most one a day.
void guideForceNC() {
    if (get_property("noncombatForcerActive") == "true")
        return;
    // An $items[] set iterates by item id, so the guide's order needs an indexed map.
    item [int] forcers = {0: $item[stench jelly], 1: $item[Clara's bell], 2: $item[handheld Allied radio]};
    item pick = $item[none];
    foreach i, it in forcers
        if (pick == $item[none] && item_amount(it) > 0 && guideForcerUsable(it))
            pick = it;
    boolean pulled;
    foreach i, it in forcers
        if (pulledToday(it))
            pulled = true;
    // Pulls stay inside the day's plan: none spent below reservedPulls().
    if (pick == $item[none] && !pulled && (pulls_remaining() < 0 || pulls_remaining() - reservedPulls() > 0)) {
        foreach i, it in forcers
            if (pick == $item[none] && storage_amount(it) > 0 && guideForcerUsable(it))
                pick = it;
        foreach i, it in forcers
            if (pick == $item[none] && is_tradeable(it) && mall_price(it) > 0 && guideForcerUsable(it))
                pick = it;
        if (pick != $item[none] && !guidePullOne(pick))
            pick = $item[none];
    }
    if (pick == $item[none])
        return;
    boolean used;
    if (pick == $item[stench jelly])
        used = chew(1, pick);
    else if (pick == $item[Clara's bell])
        used = use(1, pick);
    else
        used = cli_execute("alliedradio misc sniper");
    if (!used)
        print("Couldn't use the " + pick + " to force a noncombat.", "red");
}

void NCforce() {
    if (get_property("noncombatForcerActive") != "true") {
        if (have_item($item[apriling band helmet]) && get_property("_aprilBandTubaUses").to_int() < 3 && have_item($item[Apriling band tuba])) {
            cli_execute("aprilband play tuba");
        // Enter the Cincho branch only if it can actually fire -- either
        // enough cinch already, or free rests left to restore it.
        } else if (have_item($item[Cincho de Mayo])
            && (get_property("_cinchUsed").to_int() <= 40
                || (get_property("timesRested").to_int() < total_free_rests() && !restWouldCostFury()))){
            while (get_property("_cinchUsed").to_int() > 40
                && get_property("timesRested").to_int() < total_free_rests() && !restWouldCostFury()) {
                // The helmet sweetens the rest but is optional; equipping it
                // unowned hard-errors.
                if (have_item($item[Apriling band helmet]))
                    cli_execute("unequip hat; equip apriling band helmet");
                cli_execute("camp rest free");
            }
            if (get_property("_cinchUsed").to_int() <= 40) {
                equip($slot[acc3], $item[cincho de mayo]);
                use_skill($skill[Cincho: Fiesta Exit]);
            }
        } else if (have_item($item[Eight Days a Week Pill Keeper])
            && get_property("_freePillKeeperUsed") == "false") {
            // Sneakisol has Clara's bell's noncombat-forcing behaviour and is
            // free, so it comes before anything that costs a pull. If the free
            // pill already went on Fidoxene this call is a no-op.
            pillKeeper("free noncombat");
        } else if (guideRoute() && !have_item($item[mchugelarge duffel bag]) && !have_item($item[jurassic parka])
            && !have_item($item[allied radio backpack])) {
            guideForceNC();
        } else if (!guideRoute() && !have_item($item[mchugelarge duffel bag]) && !have_item($item[jurassic parka]) && !have_item($item[allied radio backpack])){
            foreach it in $items[Handheld Allied radio, Clara's bell, stench jelly]{
                if (!pulledToday(it)){
                    if (it == $item[Clara's Bell] && storage_amount(it) == 0)
                        continue;
                    if (pulls_remaining() == 0)
                        return;
                    pullSequence(it);
                    if (it == $item[Clara's bell])
                        use (it);
                    else if (it == $item[Handheld Allied radio])
                        cli_execute("alliedradio misc sniper");
                    else if (it == $item[stench jelly])
                        chew(it);
                    break;
                }
            }
        }
    }
}

// ─── TRICK OR TREAT ───────────────────────────────────────────────────────────

void candy(string action) {
    if (action == "fight"){
        int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
        visit_url("place.php?whichplace=town&action=town_trickortreat");
        visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
        run_combat();
    } else if (action == "treat"){
        while(contains_text(get_property("_trickOrTreatBlock"),"L")){
            int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "L");
            visit_url("place.php?whichplace=town&action=town_trickortreat");
            visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
        }
    }
}

void useMapIfAvailable() {
    if (highShiny()) return;
    if (!have_equipped($item[backup camera])) return;
    if (free_monster(get_property("lastCopyableMonster").to_monster())) return;
    if (get_property("_mapToACandyRichBlockUsed") == "false" && item_amount($item[map to a candy-rich block]) > 0) 
        use($item[map to a candy-rich block]);
    if (get_property("_mapToACandyRichBlockUsed") == "true")
        candy("fight");
}

int [string] clan_to_ID {
    "Hyrule" : 72876,
    "Dread and Final" : 2047010985,
    "Dread Mart" : 2047010683,
    "Dread Outlet Bargain Market" : 2047010572,
    "Dreadleys" : 2047010988,
    "DreadNugget" : 2047010986,
    "Dreadway" : 2047010667,
    "Fart Sauce Annex" : 2047010939
};

void whitelist(string clan){
    visit_url("showclan.php?whichclan="+clan_to_ID[clan]+"&action=joinclan&confirm=on");
}

// ─── BANISH UTILITIES ─────────────────────────────────────────────────────────

record ban {
    string pref;
    skill banSkill;
};

ban [item] banMap = {
    // prefs are matched inside \Q..\E against banishedMonsters, so they must
    // be literal prefixes of the recorded banisher name -- no regex escaping.
    $item[spring shoes]:        new ban("Spring Kick",           $skill[spring kick]),
    $item[monodent of the sea]: new ban("Sea *dent",             $skill[Sea *dent: Throw a Lightning Bolt]),
    $item[Heartstone]:          new ban("Heartstone",            $skill[Heartstone: %banish]),
    $item[none]:                new ban("snokebomb",             $skill[snokebomb]),
};

// Returns all locations a given monster can appear in
location [int] monster_found_in(monster m) {
    location [int] output;
    foreach o in $locations[]
        if (o.get_location_monsters() contains m)
            output[count(output)] = o;
    return output;
}

// Returns the monster currently banished by a given banisher string
monster banished(string banisher) {
    matcher m = create_matcher("([^:]+):\\Q" + banisher,
        get_property("banishedMonsters")
    );
    return m.find() ? to_monster(m.group(1)) : $monster[none];
}

// Returns true if the given banisher has been used on a monster at your current location
boolean banishUsedAtYourLocation(string banisher) {
    foreach num in monster_found_in(banished(banisher)) {
        if (monster_found_in(banished(banisher))[num] == my_location())
            return true;
    }
    return false;
}

// Equips the appropriate banish gear for a location (that hasn't been used yet) and sets the slot override property.
// NOTE: has the side effect of setting an Override property — callers should be aware.
item banishGear(location loc) {
    item it;
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
            continue;
        if (appearance_rates(loc)[banished(banMap[ite].pref)] == 0 && have_item(ite)) {
            it = ite;
            break;
        }
    }
    // No candidate leaves it at $item[none]; writing an override for it would
    // create a junk "noneOverride" property.
    if (it != $item[none]) {
        set_property(it.to_slot().to_string() + "Override", ", equip " + it);
        print(it.to_slot().to_string() + "Override");
    }
    return it;
}

// Returns the combat banish skill for the first equipped banish item
// whose target is no longer appearing at your location
skill combatBan() {
    foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
        if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
            continue;
        if (have_equipped(ite)
            && appearance_rates(my_location())[banished(banMap[ite].pref)] == 0) {
            print("Banish item being considered " + ite + " parsed banished monster is " + banished(banMap[ite].pref) + " and the calculated appearance rate at current location is " + appearance_rates(my_location())[banished(banMap[ite].pref)]);
            cli_execute("get banishedMonsters");
            return banMap[ite].banSkill;
        }
    }
    return $skill[none];
}

// ─── LOW IOTM BANISHES AND FISH SCALES ────────────────────────────────────────

// Pristine scales the crappy outfit pieces and the scale-mail underwear not yet made will take.
int pristineScalesWanted() {
    int want;
    if (available_amount($item[crappy Mer-kin mask]) + available_amount($item[Mer-kin gladiator mask])
        + available_amount($item[Mer-kin scholar mask]) == 0)
        want += 3;
    if (available_amount($item[crappy Mer-kin tailpiece]) + available_amount($item[Mer-kin gladiator tailpiece])
        + available_amount($item[Mer-kin scholar tailpiece]) == 0)
        want += 3;
    if (available_amount($item[scale-mail underwear]) == 0)
        want += 1;
    return want;
}

int pristineScalesNeeded() {
    return max(0, pristineScalesWanted() - available_amount($item[pristine fish scale]));
}

int dullScalesNeeded() {
    if (available_amount($item[scale-mail underwear]) > 0)
        return 0;
    return max(0, 25 - available_amount($item[dull fish scale]));
}

// Dull scales the Madness Reef Economist may take: all but the 25 the scale-mail underwear still needs.
int dullScalesSpare() {
    return item_amount($item[dull fish scale]) - (available_amount($item[scale-mail underwear]) > 0 ? 0 : 25);
}

// True while the Economist has a trade: 10 rough for a pristine, or 10 spare dull for a rough.
boolean economistCanTrade() {
    return item_amount($item[rough fish scale]) >= 10 || dullScalesSpare() >= 10;
}

// Scales still to farm: ten rough per missing pristine, traded at Madness Reef, plus the dull shortfall.
int scalesNeeded() {
    return max(0, 10 * pristineScalesNeeded() - available_amount($item[rough fish scale]))
        + dullScalesNeeded();
}

// Dull scales past the 25 for the scale-mail underwear and the ten a rough scale the missing pristine ones take.
int dullScalesSurplus(int dull, int rough, boolean underwear, int pristineNeeded) {
    int reserve = (underwear ? 0 : 25) + 10 * max(0, 10 * pristineNeeded - rough);
    return max(0, dull - reserve);
}

// Rough scales past the ten each missing pristine scale takes.
int roughScalesSurplus(int rough, int pristineNeeded) {
    return max(0, rough - 10 * pristineNeeded);
}

// Healscrolls past one for Yog-Urt and one for the dreadscroll's healscroll clue.
int healscrollSurplus(int held, boolean yogDone, boolean clueOpen) {
    return max(0, held - (yogDone ? 0 : 1) - (clueOpen ? 1 : 0));
}

// A surplus sale waits for 400 meat of goods unless meat is short.
boolean surplusSaleNow(int value, int meat) {
    return value > 0 && (value >= 400 || meat < 2000);
}

// Room for one more song after the route's own songs that are known and not up.
boolean polkaFits(int songs, int limit, int routeSongsMissing) {
    return songs + routeSongsMissing < limit;
}

int songsActive() {
    int n;
    foreach ef in my_effects()
        if (ef.song)
            n += 1;
    return n;
}

int songLimit() {
    return 3 + to_int(numeric_modifier("Additional Song")) + (boolean_modifier("Four Songs") ? 1 : 0);
}

// Songs the item drop and -combat moods cast before the seahorse, known but not up.
int routeSongsMissing() {
    int n;
    foreach ef in $effects[Fat Leon's Phat Loot Lyric, Donho's Bubbly Ballad, The Ballad of Richie Thingfinder,
        The Sonata of Sneakiness]
        if (ef.song && have_skill(to_skill(ef)) && have_effect(ef) == 0)
            n += 1;
    return n;
}

// The cozy wears off after 48 to 52 uses, so the scimitar is set aside at 45 or once no scales are left to farm.
boolean scimitarWornOut(int uses, int scalesLeft) {
    return scalesLeft == 0 || uses >= 45;
}

// Guide route: true once the cozy scimitar is set aside. mafia's cozyCounter6332 counts its combats this ascension.
boolean scimitarRetired() {
    if (!guideRoute() || available_amount($item[cozy scimitar]) == 0)
        return false;
    int uses = to_int(get_property("cozyCounter6332"));
    if (!scimitarWornOut(uses, scalesNeeded()))
        return false;
    if (to_int(get_property("uts_scimitarRetired")) != my_ascensions()) {
        set_property("uts_scimitarRetired", my_ascensions());
        print("Setting the cozy scimitar aside after " + uses + " combats"
            + (scalesNeeded() == 0 ? " with the fish scales in" : "") + ", so it stays whole for the next run.", "blue");
    }
    return true;
}

// Corral lasso training once the sea cow is done.
boolean corralLassoPhase() {
    return get_property("seahorseName") == "" && doneWithSeaCow() && !doneWithCowboy();
}

// False where the zone logic must act first or the guide skips the scale casts.
boolean scaleFight(location loc, monster mob) {
    if (loc == $location[The Coral Corral])
        return corralLassoPhase() && (mob == $monster[none] || mob == $monster[sea cowboy]);
    if ($locations[Mer-kin Colosseum, Mer-kin Temple, Mer-kin Temple (Right Door),
        Mer-kin Temple (Left Door), Mer-kin Temple (Center Door)] contains loc)
        return false;
    return !($monsters[unholy diver, wild seahorse, magic dragonfish] contains mob);
}

// MP the CCS finisher needs: one Saucegeyser or Saucestorm, nothing for a melee kill.
int killReserveMP() {
    if (have_skill($skill[Saucegeyser]))
        return mp_cost($skill[Saucegeyser]);
    if (have_skill($skill[Saucestorm]))
        return mp_cost($skill[Saucestorm]);
    return 0;
}

// MP for one scale fight: both casts that are known plus the finisher.
int scaleFightMP() {
    int mp = killReserveMP();
    if (scalesNeeded() == 0 || available_amount($item[cozy scimitar]) == 0 || scimitarRetired())
        return mp;
    foreach sk in $skills[Harpoon!, Summon Leviatuga]
        if (have_skill(sk))
            mp += mp_cost(sk);
    return mp;
}

// The club Batter Up! swings: the guide's shootin' iron first, else any club that can be wielded.
item guideClub() {
    foreach it in $items[rusted-out shootin' iron, legendary seal-clubbing club, Gnollish flyswatter, seal-clubbing club]
        if (available_amount(it) > 0 && can_equip(it))
            return it;
    if (item_type(equipped_item($slot[weapon])) == "club")
        return equipped_item($slot[weapon]);
    foreach it in get_inventory()
        if (item_type(it) == "club" && can_equip(it))
            return it;
    return $item[none];
}

boolean scimitarWieldable() {
    return available_amount($item[cozy scimitar]) > 0 && can_equip($item[cozy scimitar]) && !scimitarRetired();
}

// Iron Palms makes swords count as clubs. The skill toggles it, so it is cast only while it is off.
boolean ironPalmsUp() {
    if (have_effect($effect[Iron Palms]) > 0)
        return true;
    if (!have_skill($skill[Iron Palm Technique]))
        return false;
    if (!use_skill(1, $skill[Iron Palm Technique]))
        print("Couldn't cast " + $skill[Iron Palm Technique] + ".", "red");
    return have_effect($effect[Iron Palms]) > 0;
}

// Batter Up! needs 5 Fury, which only a Seal Clubber with Ire of the Orca holds, and a club.
boolean batterUpPossible() {
    return have_skill($skill[Batter Up!]) && my_maxfury() >= 5
        && (guideClub() != $item[none]
            || (have_skill($skill[Iron Palm Technique]) && scimitarWieldable()));
}

boolean batterUpReady() {
    string kind = item_type(equipped_item($slot[weapon]));
    return have_skill($skill[Batter Up!]) && my_fury() >= 5
        && (kind == "club" || (kind == "sword" && have_effect($effect[Iron Palms]) > 0));
}

// The guide's Batter Up! targets per zone. Batter Up! holds one monster at a time.
boolean [monster] batterTargets(location loc) {
    boolean [monster] empty;
    boolean tamed = get_property("seahorseName") != "";
    switch (loc) {
        case $location[An Octopus's Garden]:
            return $monsters[sponge, stranglin' algae, moister oyster];
        case $location[The Wreck of the Edgar Fitzsimmons]:
            return $monsters[Mer-kin scavenger];
        case $location[Anemone Mine]:
            return $monsters[Anemone combatant, killer clownfish];
        case $location[The Mer-Kin Outpost]:
            return $monsters[Mer-kin raider];
        case $location[The Coral Corral]:
            // The rustler shows only when the ice house holds something else.
            if (doneWithSeaCow() && doneWithCowboy())
                return $monsters[sea cowboy];
            return $monsters[Mer-kin rustler];
        case $location[The Marinara Trench]:
            if (tamed)
                return $monsters[fisherfish, Mer-kin diver];
            break;
        case $location[The Dive Bar]:
            if (tamed)
                return $monsters[lounge lizardfish, nurse shark];
            break;
        case $location[Madness Reef]:
            if (tamed)
                return $monsters[magic dragonfish];
            break;
        case $location[The Caliginous Abyss]:
            return $monsters[school of many];
    }
    return empty;
}

// The guide's Snokebomb targets per zone. Snokebomb also holds one monster at a time.
boolean [monster] snokeTargets(location loc) {
    boolean [monster] empty;
    switch (loc) {
        case $location[The Wreck of the Edgar Fitzsimmons]:
            // The diver hunt, not the first visit.
            if (get_property("questS02Monkees") != "step1")
                return $monsters[mine crab];
            break;
        case $location[The Coral Corral]:
            if (!doneWithSeaCow())
                return $monsters[sea cowboy];
            if (get_property("seahorseName") == "")
                return $monsters[sea cow];
            break;
        case $location[Mer-kin Library]:
            return $monsters[Mer-kin drifter];
    }
    return empty;
}

// The guide's Snokebomb targets still ahead in the route.
int snokeTargetsAhead() {
    monster held = banished("snokebomb");
    int ahead;
    if (!diverPartsComplete() && to_slot(divingHelmet()) != $slot[hat] && held != $monster[mine crab])
        ahead += 1;
    if (get_property("seahorseName") == "") {
        if (!doneWithSeaCow() && held != $monster[sea cowboy])
            ahead += 1;
        if (held != $monster[sea cow])
            ahead += 1;
    }
    if (get_property("isMerkinHighPriest") != "true" && held != $monster[Mer-kin drifter])
        ahead += 1;
    return ahead;
}

int snokebombsSpare() {
    return 3 - to_int(get_property("_snokebombUsed")) - snokeTargetsAhead();
}

// Guide route: Shattering Punch is kept for the Corral sea cow until its cowbells and leather are in.
boolean punchReserved(boolean guide, boolean seaCowFight, boolean tamed, boolean seaCowDone) {
    return guide && !seaCowFight && !tamed && !seaCowDone;
}

// Steely-Eyed Squint lasts one turn, so it waits for a free kill left for the sea cow, when one is known at all.
boolean squintNow(boolean known, boolean active, boolean usedToday, boolean freeKillKnown, boolean freeKillLeft) {
    return known && !active && !usedToday && (freeKillLeft || !freeKillKnown);
}

boolean seaCowFreeKillKnown() {
    return have_skill($skill[Shattering Punch]) || have_skill($skill[Gingerbread Mob Hit]);
}

boolean seaCowFreeKillLeft() {
    return (have_skill($skill[Shattering Punch]) && to_int(get_property("_shatteringPunchUsed")) < 3)
        || (have_skill($skill[Gingerbread Mob Hit]) && get_property("_gingerbreadMobHitUsed") != "true");
}

// True while Batter Up! holds none of the zone's targets and one is still unbanished.
// One attempt per zone until Batter Up! is spent elsewhere.
boolean batterUpPending(location loc) {
    boolean [monster] targets = batterTargets(loc);
    if ((targets contains banished("batter up!"))
        || (targets contains to_monster(get_property("_utsBatterTried"))))
        return false;
    foreach mob in targets
        if (!create_matcher("(?:^|:)\\Q" + mob + ":\\E", get_property("banishedMonsters")).find())
            return true;
    return false;
}

// On the guide route Snokebomb goes to the guide's own targets, and to Batter Up! targets
// only when Batter Up! is out of reach and a Snokebomb is left over after the targets ahead.
boolean snokebombReserved(location loc, monster mob) {
    if (!guideRoute() || (snokeTargets(loc) contains mob))
        return false;
    return batterUpPossible() || !(batterTargets(loc) contains mob) || snokebombsSpare() < 1;
}

// A rest empties Fury, so it waits while a Batter Up! banish is due here, and in the
// untamed pearl zones where Fury is saved for the banishes after the seahorse.
boolean restWouldCostFury() {
    if (!guideRoute() || my_fury() < 1 || !batterUpPossible())
        return false;
    if (get_property("seahorseName") == ""
        && ($locations[The Marinara Trench, The Dive Bar, Madness Reef, The Briniest Deepests] contains my_location()))
        return true;
    return batterUpPending(my_location());
}

// The VIP pool's swim sprints need a Clan VIP Lounge key in inventory and the pool unused today.
boolean poolSprintOpen(int keys, boolean usedToday) {
    return keys > 0 && !usedToday;
}

// Guide route: mafia's mana burning stays off for the run. The user's threshold waits in uts_manaBurnSaved.
void manaBurnOff() {
    if (get_property("uts_manaBurnSaved") == "")
        set_property("uts_manaBurnSaved", get_property("manaBurningThreshold"));
    set_property("manaBurningThreshold", "-0.05");
}

// Puts back the threshold manaBurnOff() saved, one a killed run left behind included.
void manaBurnRestore() {
    string saved = get_property("uts_manaBurnSaved");
    if (saved == "")
        return;
    set_property("manaBurningThreshold", saved);
    set_property("uts_manaBurnSaved", "");
}

// Club when a banish is due and Fury is full, cozy scimitar while scales are short, else the
// maximizer's pick. Sneak legs take the shootin' iron's -5% combat over the scimitar.
string guideWeapon(location loc, boolean sneak) {
    if (!guideRoute())
        return "";
    item iron = $item[rusted-out shootin' iron];
    if (sneak && available_amount(iron) > 0 && can_equip(iron))
        return iron + ",";
    // In a combat route training phase a Mer-kin weapon with a locked move takes the slot, and banishes yield to it.
    item trainee = sneak || loc.environment != "underwater" ? $item[none] : gladiatorTrainee();
    if (trainee != $item[none] && gladiatorTrainingPhase())
        return trainee + ",";
    boolean wield = scimitarWieldable();
    boolean scales = wield && scalesNeeded() > 0 && scaleFight(loc, $monster[none])
        && (have_skill($skill[Harpoon!]) || have_skill($skill[Summon Leviatuga]));
    boolean banish = batterUpPossible() && batterUpPending(loc);
    item club = guideClub();
    if (banish && wield && (scales || club == $item[none])
        && have_skill($skill[Iron Palm Technique]) && ironPalmsUp())
        return $item[cozy scimitar] + ",";
    if (banish && club != $item[none] && (my_fury() >= 5 || !scales))
        return club + ",";
    if (scales)
        return $item[cozy scimitar] + ",";
    return "";
}

// Guide route: a light MP regen weight, so a spare accessory slot takes the MP regen pull.
// At 0.1 the fin's 10 to 12 MP scores about 1.1, so it only settles slots the zone's own targets leave open.
string guideRegen() {
    return guideRoute() ? ", 0.1 mp regen" : "";
}

// ─── LOW IOTM FINISHER MATH ───────────────────────────────────────────────────
// Pure estimates for the CCS finisher: an attack, Saucestorm or Saucegeyser, at low rolls.

// Low roll of a standard attack: the stat share over Defense, power / 10, flat bonus, then the percent
// bonus and physical resistance. Never under 1 unless the monster is immune.
int meleeLowDamage(float statShare, int defense, int power, float flat, float percent, int physRes) {
    float raw = max(0, floor(statShare) - defense) + floor(power / 10.0) + flat;
    float dmg = floor(raw * (1 + percent / 100) * (100 - physRes) / 100);
    if (physRes >= 100)
        return 0;
    return max(1, to_int(dmg));
}

// Chance a swing lands: (6 + Attack - Defense) / 11 held to 0..1, less the 1 in 22 fumble.
float meleeHitRate(float attack, int defense) {
    float base = (6 + floor(attack) - defense) / 11.0;
    return min(1.0, max(0.0, base)) * 21.0 / 22.0;
}

// A spell element against the monster's own: 0 for the same element, which takes 1 damage,
// 2 for the two elements it is weak to, else 1.
float elementFactor(element spell, element mob) {
    if (mob == $element[none] || spell == $element[none])
        return 1.0;
    if (spell == mob)
        return 0.0;
    string [element] beats = {
        $element[hot]: "spooky,cold",
        $element[spooky]: "cold,sleaze",
        $element[cold]: "sleaze,stench",
        $element[sleaze]: "stench,hot",
        $element[stench]: "hot,spooky"
    };
    return contains_text("," + beats[spell] + ",", "," + mob + ",") ? 2.0 : 1.0;
}

// A monster's resistance to one element.
int monsterElementRes(monster mob, element e) {
    switch (e) {
        case $element[hot]: return mob.hot_resistance;
        case $element[cold]: return mob.cold_resistance;
        case $element[spooky]: return mob.spooky_resistance;
        case $element[sleaze]: return mob.sleaze_resistance;
        case $element[stench]: return mob.stench_resistance;
    }
    return 0;
}

float lanternTop(float [element] comp) {
    float top;
    foreach e, v in comp
        top = max(top, v);
    return top;
}

// Low roll weight of a spell hit and its lanterns in unresisted hits; share is each element's factor after res, none is physical.
// Lanterns add the highest component in wiki order; the Medal sets its picks to it, the worst picks assumed.
float lanternWeight(element spell, element [int] before, int medalPicks, element [int] after, float [element] share) {
    float [element] comp;
    comp[spell] = 1.0;
    foreach i, e in before
        comp[e] += lanternTop(comp);
    float medal;
    if (medalPicks > 0) {
        float top = lanternTop(comp);
        float [int] gains;
        foreach e in $elements[hot, cold, spooky, sleaze, stench]
            gains[count(gains)] = (top - comp[e]) * share[e];
        sort gains by value;
        for i from 0 to min(medalPicks, 3) - 1
            medal += gains[i];
    }
    foreach i, e in after
        comp[e] += lanternTop(comp);
    float w = medal;
    foreach e, v in comp
        w += v * share[e];
    return w;
}

// Lantern elements that act before the Medal, in the wiki's order; none stands for the pouch's physical copy.
element [int] lanternsBeforeMedal() {
    element [int] out;
    if (my_familiar() == $familiar[Foul Ball])
        out[count(out)] = $element[stench];
    foreach it in $items[meteorb, big hot pepper]
        if (have_equipped(it))
            out[count(out)] = $element[hot];
    if (have_equipped($item[snow mobile]))
        out[count(out)] = $element[cold];
    if (have_equipped($item[Rain-Doh green lantern]))
        out[count(out)] = $element[stench];
    if (have_equipped($item[petrified wood wizard's pouch])) {
        out[count(out)] = $element[hot];
        out[count(out)] = $element[none];
    }
    if (have_equipped($item[petrified wood water purifier])) {
        out[count(out)] = $element[cold];
        out[count(out)] = $element[sleaze];
    }
    if (have_effect($effect[Frigidalmatian]) > 0)
        out[count(out)] = $element[cold];
    return out;
}

// The retro cape's spooky lantern acts after the Medal.
element [int] lanternsAfterMedal() {
    element [int] out;
    if (have_equipped($item[unwrapped knock-off retro superhero cape]) && get_property("retroCapeSuperhero") == "heck"
        && get_property("retroCapeWashingInstructions") == "kill")
        out[count(out)] = $element[spooky];
    return out;
}

// Low roll of one sauce hit: base + floor(share * Mys) + flat bonuses under the cap (0 for none), then
// the percent bonus, resistance and the element factor, rounded down.
int spellLowDamage(int base, float share, float mys, int cap, float flat, float percent, int res, float elem) {
    float dmg = base + floor(share * mys) + flat;
    if (cap > 0)
        dmg = min(dmg, to_float(cap));
    dmg = floor(dmg * (1 + percent / 100));
    return max(0, to_int(floor(dmg * (100 - res) / 100 * elem)));
}

// Rounds to take hp at perRound damage with nine tenths of it counted, over the chance each round lands.
// 99 when it does no damage.
int roundsToKill(int hp, int perRound, float landRate) {
    if (perRound <= 0 || landRate <= 0)
        return 99;
    int hits = ceil(max(1, hp) / (perRound * 0.9));
    return min(99, ceil(hits / landRate));
}

// MP to heal damage back in whole casts of the cheapest known heal: Cannelloni Cocoon 1000 HP for 20 MP,
// Tongue of the Walrus 35 HP for 10 MP. Without either, 2 HP a MP.
int healMP(int damage, boolean cocoon, boolean walrus) {
    if (damage <= 0)
        return 0;
    int best = -1;
    if (cocoon)
        best = ceil(damage / 1000.0) * 20;
    if (walrus && (best < 0 || ceil(damage / 35.0) * 10 < best))
        best = ceil(damage / 35.0) * 10;
    return best >= 0 ? best : ceil(damage / 2.0);
}

// The rounds map with 99 for melee once it is off and for any option that ends past lastRound.
int [int] plannableRounds(int [int] rounds, boolean meleeOff, int roundNow, int lastRound) {
    int [int] out;
    foreach i, r in rounds
        out[i] = (i == 0 && meleeOff) || r >= 99 || roundNow + r - 1 > lastRound ? 99 : r;
    return out;
}

// The paid finisher (0 attack, 1 Saucestorm, 2 Saucegeyser, -1 none) killing within maxRounds and surviving a hit
// a round, with the least MP for casts and healing casts. Ties take the lower index.
int cheapestKill(int [int] rounds, int [int] cost, int mp, int hp, int hitTaken, int maxRounds, boolean cocoon, boolean walrus) {
    int best = -1;
    int bestMP;
    for i from 0 to 2 {
        if (!(rounds contains i) || !(cost contains i) || rounds[i] > maxRounds)
            continue;
        int spend = rounds[i] * cost[i];
        int damage = rounds[i] * hitTaken;
        if (spend > mp || damage >= hp)
            continue;
        int total = spend + healMP(damage, cocoon, walrus);
        if (best < 0 || total < bestMP) {
            best = i;
            bestMP = total;
        }
    }
    return best;
}

// Without a cheap safe kill, the finisher that kills soonest and is paid for this round. -1 when none hurts.
int fastestKill(int [int] rounds, int [int] cost, int mp) {
    int best = -1;
    for i from 0 to 2 {
        if (!(rounds contains i) || !(cost contains i) || rounds[i] >= 99 || cost[i] > mp)
            continue;
        if (best < 0 || rounds[i] < rounds[best])
            best = i;
    }
    return best;
}

// The magic dragonfish's res debuff lands after round 1: the cheapest paid one-round kill, else the fastest paid
// spell, and melee only when no spell is paid for. -1 when nothing is.
int dragonfishKill(int [int] rounds, int [int] cost, int mp) {
    int best = -1;
    for i from 0 to 2 {
        if (!(rounds contains i) || !(cost contains i) || rounds[i] != 1 || cost[i] > mp)
            continue;
        if (best < 0 || cost[i] < cost[best])
            best = i;
    }
    if (best >= 0)
        return best;
    int [int] spells;
    foreach i, r in rounds
        if (i != 0)
            spells[i] = r;
    best = fastestKill(spells, cost, mp);
    return best >= 0 ? best : fastestKill(rounds, cost, mp);
}

// ─── EVERFULL DART ────────────────────────────────────────────────────────────
string perks = get_property("everfullDartPerks");
boolean bullseyeReady() {
    int n = count_substring(perks, "25% Better bullseye targeting") + count_substring(perks, "25% better chance to hit bullseyes") + count_substring(perks, "25% More Accurate bullseye targeting");
    return (n >= 2);
}

boolean everfullReady(){
    if (!bullseyeReady())
        return false;
    return (contains_text(perks, "You are less impressed by bullseyes")
            && contains_text(perks, "Bullseyes do not impress you much"))
        || count_substring(perks, "Bullseyes do not impress you much") >= 2
        || count_substring(perks, "You are less impressed by bullseyes") >= 2;
    return true;
}

void darts() {
    while (to_int(get_property("_dartsLeft")) > 0
        && have_equipped($item[everfull dart holster])
        && current_round() > 0) {
        if (contains_text(get_property("everfullDartPerks"), "Butt")) {
            matcher m = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
            if (!m.find()) break;
            use_skill(to_skill(to_int(m.group(1))));
        } else {
            use_skill($skill[Darts: Throw at %part1]);
        }
    }
}

// ─── DARTS, BCZ, TRAINSET, AND LEPRECONDO ──────────────────────────────────

// ─── TRAINSET ─────────────────────────────────────────────────────────────────

void trainset() {
    int pos = to_int(get_property("trainsetPosition")) % 8;
    int [int] slots = {
        (pos)     % 8: 8,   // next station
        (pos + 1) % 8: 1,
        (pos + 2) % 8: 15,
        (pos + 3) % 8: 20,
        (pos + 4) % 8: 3,
        (pos + 5) % 8: 7,
        (pos + 6) % 8: 2,
        (pos + 7) % 8: 19
    };
    visit_url("choice.php?forceoption=0?whichchoice=1485&option=1"
        + "&slot%5B0%5D=" + slots[0]
        + "&slot%5B1%5D=" + slots[1]
        + "&slot%5B2%5D=" + slots[2]
        + "&slot%5B3%5D=" + slots[3]
        + "&slot%5B4%5D=" + slots[4]
        + "&slot%5B5%5D=" + slots[5]
        + "&slot%5B6%5D=" + slots[6]
        + "&slot%5B7%5D=" + slots[7]);
}

// ─── LEPRECONDO ───────────────────────────────────────────────────────────────

string [int] lepRoomToNum = {
    1:"buckets of concrete",        2:"thrift store oil painting",
    3:"boxes of old comic books",   4:"second-hand hot plate",
    5:"beer cooler",                6:"free mattress",
    7:"gigantic chess set",         8:"UltraDance karaoke machine",
    9:"cupcake treadmill",          10:"beer pong table",
    11:"padded weight bench",       12:"internet-connected laptop",
    13:"sous vide laboratory",      14:"programmable blender",
    15:"sensory deprivation tank",  16:"fruit-smashing robot",
    17:"ManCave™ sports bar set",   18:"couch and flatscreen",
    19:"kegerator",                 20:"fine upholstered dining table set",
    21:"whiskeybed",                22:"high-end home workout system",
    23:"complete classics library", 24:"ultimate retro game console",
    25:"Omnipot",                   26:"fully-stocked wet bar",
    27:"four-poster bed"
};

void leprecondo(string input) {
    if (to_int(get_property("_leprecondoRearrangements")) >= 3)
        return;
    boolean [int] discovered;
    foreach i, s in split_string(get_property("leprecondoDiscovered"), ",") {
        if (s != "" && (lepRoomToNum contains to_int(s)))
            discovered[to_int(s)] = true;
    }
    // Wanted rooms first, then any other discovered piece. Furnish takes exactly four.
    int [int] lepRoom;
    int count = 0;
    foreach i, s in split_string(input, ",") {
        int val = to_int(s);
        if (count < 4 && (discovered contains val)) {
            lepRoom[count] = val;
            remove discovered[val];
            count += 1;
        }
    }
    foreach val in discovered {
        if (count >= 4)
            break;
        lepRoom[count] = val;
        count += 1;
    }
    if (count < 4) {
        print("Leprecondo skipped: only " + count + " furniture pieces discovered.", "red");
        return;
    }
    string furnish = "leprecondo furnish "
        + lepRoomToNum[lepRoom[3]] + ","
        + lepRoomToNum[lepRoom[2]] + ","
        + lepRoomToNum[lepRoom[1]] + ","
        + lepRoomToNum[lepRoom[0]];
    if (!cli_execute(furnish))
        print("Leprecondo furnish failed: " + furnish, "red");
}

void fillPrereqs(int outcomeSlot, string pitchType) {
    int filled = 0;
    int before = outcomeSlot - 1;
    while (filled < 2 && before >= 1) {
        if (get_property("pitchNum" + before) == "") {
            set_property("pitchNum" + before, pitchType);
            filled += 1;
        }
        before -= 1;
    }
    if (filled < 2)
        abort("Not enough open slots to fill prereqs for outcome at slot " + outcomeSlot);
}
boolean canBaseballBanish(int p){
    if (get_property("pitchNum9") == "")
        return false;
    for x from 8 to 6 {
        if (get_property("pitchNum" + x) != "" || x == p)
            return true;
    }
    return false;
}
void baseballD() {
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int players;
    foreach num in lineup { players = num + 1; }
    if (players != 9) return;

    try {
        int YRPitchNum;
        int FKPitchNum;
        int BanishPitchNum;

        // Scan 9→3, take the latest slot for each outcome type
        for x from 9 to 3 {
            if (YRPitchNum == 0 && $strings[745,838,775,773,765,768,762,763] contains lineup[x-1]) {
                YRPitchNum = x;
                set_property("pitchNum" + x, "1");
            }
            if (FKPitchNum == 0 && $strings[2499] contains lineup[x-1]) {
                FKPitchNum = x;
                set_property("pitchNum" + x, "3");
            }
            // Banish (third pitch) only activates if slot 9 is already claimed by another outcome
            if (BanishPitchNum == 0 && $strings[764] contains lineup[x-1]
                && canBaseballBanish(x)) {
                BanishPitchNum = x;
                set_property("pitchNum" + x, "2");
            }
        }

        if (YRPitchNum == 0 && FKPitchNum == 0) {
            print("No yellow ray or free kill pitchers in lineup, skipping.", "red");
            return;
        }

        // Assigning other pitches
        int [int] pitchOrder   = {1: YRPitchNum, 2: BanishPitchNum, 3: FKPitchNum};
        string [int] pitchChoice = {1: "1", 2: "2",        3: "3"};

        //Ordering pitches from latest to earliest
        for i from 1 to 3 {
            for j from 1 to (3 - i) {
                if (pitchOrder[j] < pitchOrder[j+1]) {
                    int tmpS = pitchOrder[j];   pitchOrder[j]   = pitchOrder[j+1]; pitchOrder[j+1]   = tmpS;
                    string tmpP = pitchChoice[j]; pitchChoice[j] = pitchChoice[j+1]; pitchChoice[j+1] = tmpP;
                }
            }
        }

        foreach i in pitchOrder {
            if (pitchOrder[i] > 0)
                fillPrereqs(pitchOrder[i], pitchChoice[i]);
        }

        visit_url("inventory.php?pwd&action=pball&pwd=" + my_hash() + "&action=pball", false);
        for x from 1 to 9 {
            string pitch = get_property("pitchNum" + x);
            run_choice(pitch == "" ? 4 : to_int(pitch));
        }
        run_choice(6);

    } finally {
        for x from 1 to 9 {
            set_property("pitchNum" + x, "");
        }
    }
}

// ─── SEPT-EMBER CENSER ────────────────────────────────────────────────────────
// Claim the day's embers, then spend them all on Septapus summoning charms
// for the CCS to throw at the shadow slab.
void censer() {
    if (!have_item($item[Sept-Ember Censer]))
        return;
    if (get_property("_septEmberBalanceChecked") == "false")
        visit_url("shop.php?whichshop=september");
    int wanted = 3 - item_amount($item[Septapus summoning charm]);
    int afford = to_int(get_property("availableSeptEmbers")) / 2;
    if (afford < wanted)
        wanted = afford;
    if (wanted > 0)
        buy($coinmaster[Sept-Ember Censer], wanted, $item[Septapus summoning charm]);
}

// ─── RUN-START CHECKLISTS ─────────────────────────────────────────────────────
// Logged once at initialization: every supported IOTM and every pull the
// route may ask for, one per line -- blue check for present, red cross for
// absent. Purely informational; every use in the script is ownership-guarded
// regardless.
void iotmChecklist() {
    boolean [item] iotmItems = $items[monodent of the sea,
        The Eternity Codpiece,
        closed-circuit pay phone, 2002 Mr. Store Catalog, cursed monkey's paw,
        august scepter, Fourth of May Cosplay Saber, Peridot of Peril,
        blood cubic zirconia, baseball diamond, Heartstone, backup camera,
        Jurassic Parka, spring shoes, Everfull Dart Holster, Mayam Calendar,
        Leprecondo, Cincho de Mayo, McHugeLarge duffel bag,
        Apriling band helmet, April Shower Thoughts shield, bat wings,
        server room key, Time-Spinner, January's Garbage Tote, Powerful Glove,
        combat lover's locket, Lil' Doctor&trade; bag, mumming trunk,
        Kremlin's Greatest Briefcase, Cargo Cultist Shorts,
        Eight Days a Week Pill Keeper, Sept-Ember Censer, vampyric cloake,
        Unwrapped knock-off retro superhero cape, roman candelabra,
        miniature crystal ball, latte lovers member's mug, V for Vivala mask,
        designer sweatpants, tearaway pants, autumn-aton, cosmic bowling ball,Clan VIP Lounge key];
    // The passive, not its combat skills: mafia learns Micrometeorite,
    // Macrometeorite and Meteor Shower only by parsing a fight page, so
    // outside combat have_skill() reads them as absent.
    boolean [skill] iotmSkills = $skills[Just the Facts, Map the Monsters,
        Meteor Lore, Feel Nostalgic];
    boolean [familiar] iotmFamiliars = $familiars[Grouper Groupie,
        Red-Nosed Snapper, Jill-of-All-Trades, Chest Mimic, Patriotic Eagle,
        Sword of S Words, Peace Turkey, Disgeist, Jumpsuited Hound Dog,
        Glover, Foul Ball, Space Jellyfish, Pocket Professor,
        Tiny Plastic Santa Claus Skeleton];

    print("IOTM check — supported IOTMs:");
    int owned;
    int total;
    foreach it in iotmItems {
        total += 1;
        if (have_item(it)) { owned += 1; print("✓ " + it, "blue"); }
        else print("✗ " + it, "red");
    }
    foreach sk in iotmSkills {
        total += 1;
        if (have_skill(sk)) { owned += 1; print("✓ " + sk, "blue"); }
        else print("✗ " + sk, "red");
    }
    foreach fam in iotmFamiliars {
        total += 1;
        if (have_familiar(fam)) { owned += 1; print("✓ " + fam, "blue"); }
        else print("✗ " + fam, "red");
    }
    total += 1;
    if (get_workshed() != $item[none]
        || have_item($item[Asdon Martin keyfob (on ring)])
        || have_item($item[model train set])
        || have_item($item[portable Mayo Clinic])
        || have_item($item[TakerSpace letter of Marque])) {
        owned += 1; print("✓ a workshed", "blue");
    } else
        print("✗ a workshed", "red");
    total += 1;
    if (get_campground() contains $item[Source terminal]) {
        owned += 1; print("✓ Source Terminal", "blue");
    } else
        print("✗ Source Terminal", "red");
    print("IOTM check: " + owned + " of " + total + " supported IOTMs owned.");
}

// Permable skills the route leans on. A skill that stops working the moment
// the IOTM granting it is gone belongs to iotmChecklist(); these survive a
// perm, so they are worth their own list. Informational -- nothing aborts.
record skillNeed {
    int tier;        // 2 required, 1 big turn saver, 0 optional
    string why;
};

skillNeed [skill] routeSkills = {
    // Required -- the run cannot finish without these.
    $skill[Saucegeyser]:            new skillNeed(2, "Kills most of what you fight. Without this or Saucestorm the run stops."),
    $skill[Cannelloni Cocoon]:      new skillNeed(2, "In-run healing."),
    $skill[Empathy of the Newt]:    new skillNeed(2, "Cast before fighting Shub-Jigguwatt."),
    $skill[Deep Dark Visions]:      new skillNeed(2, "The only way to learn the third dreadscroll answer."),

    // Big turn savers.
    $skill[Steely-Eyed Squint]:     new skillNeed(1, "A big once-a-day item drop boost, used to force the drops the run needs."),
    $skill[Unaccompanied Miner]:    new skillNeed(1, "Five free trips into the mine each day, so you need not pull a lodestone for the teflon ore."),
    $skill[Transcendent Olfaction]: new skillNeed(1, "Makes the Neptune flytrap, giant squid and Mer-kin tippler turn up far more often."),
    $skill[Holiday Multitasking]:   new skillNeed(1, "Three crafts a day that cost no adventure."),
    $skill[Tongue of the Walrus]:   new skillNeed(1, "Clears Beaten Up without spending turns resting."),
    $skill[Overclock(10)]:          new skillNeed(1, "Your first ten CyberRealm fights each day are free; used for the Mom quest and to recharge the eagle screech."),
    $skill[Garbage Nova]:           new skillNeed(1, "Extra damage against the school of many. Without it that fight just takes longer."),

    // Optional -- the run copes without any of these.
    $skill[Saucestorm]:             new skillNeed(0, "Backup finisher if you have no Saucegeyser. You need one of the two."),
    $skill[Snokebomb]:              new skillNeed(0, "Banishes a monster you would rather not fight."),
    $skill[Shattering Punch]:       new skillNeed(0, "Kills a monster for free, saving a turn."),
    $skill[Gingerbread Mob Hit]:    new skillNeed(0, "Kills a monster for free, saving a turn."),
    $skill[Perpetrate Mild Evil]:   new skillNeed(0, "Extra damage against the shadow slab."),
    $skill[Raise Backup Dancer]:    new skillNeed(0, "Extra damage in the Naughty Sorceress fight."),
    $skill[Summon Kokomo Resort Pass]: new skillNeed(0, "A free daily summon, picked up during daily setup."),
    $skill[The Ode to Booze]:       new skillNeed(0, "More adventures from every drink."),
    $skill[Ambidextrous Funkslinging]: new skillNeed(0, "Throws two potions at once, halving the fights spent identifying the murky potions."),
    $skill[Double-Fisted Skull Smashing]: new skillNeed(0, "Lets you wield a weapon in each hand, for better equipment."),
    $skill[Gallapagosian Mating Call]: new skillNeed(0, "Another way to make a monster reappear, and the only one that works on the black crayon golem."),
    $skill[Stuffed Mortar Shell]:   new skillNeed(0, "Extra damage while finishing fights without Saucegeyser."),
    $skill[Bind Spice Ghost]:       new skillNeed(0, "Pastamancer thrall for a little extra damage. Any one of the three is enough."),
    $skill[Bind Vermincelli]:       new skillNeed(0, "Pastamancer thrall for a little extra damage. Any one of the three is enough."),
    $skill[Bind Angel Hair Wisp]:   new skillNeed(0, "Pastamancer thrall for a little extra damage. Any one of the three is enough."),

    // Buffs the script puts up before the zones that need them.
    $skill[Fat Leon's Phat Loot Lyric]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[The Ballad of Richie Thingfinder]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Singer's Faithful Ocelot]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Leash of Linguini]:      new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Who's Going to Pay This Drunken Sailor?]: new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Sauce Contemplation]:    new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[Donho's Bubbly Ballad]:  new skillNeed(0, "Cast while the run is hunting a specific item drop."),
    $skill[The Sonata of Sneakiness]: new skillNeed(0, "Fewer combats, so the noncombats the run wants arrive sooner."),
    $skill[Hide From Seekers]:      new skillNeed(0, "Fewer combats, so the noncombats the run wants arrive sooner."),
    $skill[Smooth Movement]:        new skillNeed(0, "Fewer combats, so the noncombats the run wants arrive sooner."),
    $skill[Carlweather's Cantata of Confrontation]: new skillNeed(0, "More combats, for the zones the run needs to fight through."),
    $skill[Musk of the Moose]:      new skillNeed(0, "More combats, for the zones the run needs to fight through."),
    $skill[Attract Snakes]:         new skillNeed(0, "More combats, for the zones the run needs to fight through."),
    $skill[Astral Shell]:           new skillNeed(0, "Elemental resistance for the underwater boss fights."),
    $skill[Elemental Saucesphere]:  new skillNeed(0, "Elemental resistance for the underwater boss fights."),
    $skill[Scarysauce]:             new skillNeed(0, "Elemental resistance for the underwater boss fights."),
    $skill[Carol of the Hells]:     new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Elron's Explosive Etude]: new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Get Big]:                new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[The Magical Mojomuscular Melody]: new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Manicotti Meditation]:   new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
    $skill[Moxie of the Mariachi]:  new skillNeed(0, "Buff for the Mer-kin Colosseum fights."),
};


// A skill you hold only because of your current class is gone next ascension,
// so an owned-but-unpermed skill is flagged. get_permed_skills() is empty
// until a charsheet parse fills it, and an empty map suppresses the note
// rather than marking everything unpermed.
void printSkillTier(int tier, string label) {
    boolean [skill] permed = get_permed_skills();
    print("Skill check — " + label + ":");
    foreach sk in routeSkills {
        if (routeSkills[sk].tier != tier)
            continue;
        if (!have_skill(sk))
            print("✗ " + sk + " — " + routeSkills[sk].why, "red");
        else if (count(permed) > 0 && !(permed contains sk))
            print("✓ " + sk + " (not permed) — " + routeSkills[sk].why, "blue");
        else
            print("✓ " + sk + " — " + routeSkills[sk].why, "blue");
    }
}

void skillChecklist() {
    int owned;
    int total;
    int missingRequired;
    foreach sk in routeSkills {
        total += 1;
        if (have_skill(sk))
            owned += 1;
        else if (routeSkills[sk].tier == 2)
            missingRequired += 1;
    }
    printSkillTier(2, "required");
    printSkillTier(1, "big turn savers");
    printSkillTier(0, "optional");
    print("Skill check: " + owned + " of " + total + " permable skills owned"
        + (missingRequired > 0 ? ", " + missingRequired + " REQUIRED missing" : "") + ".");
}

void pullChecklist() {
    boolean [item] pulls = $items[Mer-kin sneakmask, sea lasso, shark jumper,
        scale-mail underwear, Congressional Medal of Insanity,
        Flash Liquidizer Ultra Dousing Accessory, Mer-kin digpick, lodestone,
        comb jelly, Elf Guard SCUBA tank, rusty rivet, sea cowbell,
        Mer-kin prayerbeads, Mer-kin healscroll, Mer-kin killscroll,
        Mer-kin worktea, Mer-kin knucklebone, Mer-kin cheatsheet,
        Mer-kin hallpass, Mer-kin hidepaint, pro skateboard, software glitch,
        pulled yellow taffy, stuffed yam stinkbomb, waffle, skate blade,
        null-day exploit, New Age healing crystal, soggy used band-aid,
        damp old wallet, fish sauce, Aldebaran sardines,
        pie man was not meant to eat, Handheld Allied radio, Clara's bell,
        stench jelly, peppermint parasol, ink bladder, Mer-kin pinkslip,
        Louder Than Bomb, anchor bomb];

    print("Pull check — Hagnk's stock:");
    foreach it in pulls {
        // Catalog credits create these in-run; only worth stocking without it.
        if (have_item($item[2002 Mr. Store Catalog])
            && $items[pro skateboard, software glitch] contains it)
            continue;
        // Never auto-bought (see the pull loop) -- flag it as a nice-to-have.
        if (it == $item[Congressional Medal of Insanity] && storage_amount(it) == 0 && get_inventory()[it] == 0) {
            print("✗ " + it + " — Currently not optional, just too expensive to have the script buy on its own", "red");
            continue;
        }
        if (storage_amount(it) > 0 || get_inventory()[it] > 0)
            print("✓ " + it, "blue");
        else if (is_tradeable(it))
            print("✗ " + it + " — will be mall-bought if the route needs it", "red");
        else
            print("✗ " + it + " — NOT mall-buyable, acquire before it's needed", "red");
    }
}

// ─── LOW IOTM CHECKLIST ───────────────────────────────────────────────────────
// The low IOTM guide's perms and pulls. A line is met by owning any one of
// its entries, or `need` of them for a skill line.
record guideSkill {
    boolean [skill] any;
    int need;
    string why;
};

guideSkill [int] guideSkills = {
    new guideSkill($skills[The Sonata of Sneakiness], 1, "Noncombat rate."),
    new guideSkill($skills[Smooth Movement], 1, "Noncombat rate."),
    new guideSkill($skills[Hide From Seekers], 1, "Noncombat rate."),
    new guideSkill($skills[Musk of the Moose], 1, "Combat rate."),
    new guideSkill($skills[Carlweather's Cantata of Confrontation], 1, "Combat rate."),
    new guideSkill($skills[The Ode to Booze], 1, "More adventures from the astral pilsners."),
    new guideSkill($skills[Batter Up!], 1, "The route's unlimited banish, with a club and full Fury."),
    new guideSkill($skills[Wrath of the Wolverine], 1, "Fills Fury for Batter Up!"),
    new guideSkill($skills[Ire of the Orca], 1, "Fills Fury for Batter Up!"),
    new guideSkill($skills[Snokebomb], 1, "Three banishes a day."),
    new guideSkill($skills[Summon Leviatuga], 1, "Fish scales with the cozy scimitar, and it replaces the scale-mail underwear pull."),
    new guideSkill($skills[Secret Door Awareness], 1, "Listed by the guide for elemental resistance."),
    new guideSkill($skills[Elemental Saucesphere], 1, "Elemental resistance."),
    new guideSkill($skills[Cold-Blooded Fearlessness, Hypersane, Bravery Gland], 1, "A passive spooky resistance perm."),
    new guideSkill($skills[Who's Going to Pay This Drunken Sailor?, Mad Looting Skillz,
        Fat Leon's Phat Loot Lyric, Donho's Bubbly Ballad, Powers of Observatiogn,
        Singer's Faithful Ocelot, Object Quasi-Permanence], 2, "Item drop perms, at least two."),
    new guideSkill($skills[The Polka of Plenty], 1, "Meat, to afford the 10,000 meat SCUBA tank."),
    new guideSkill($skills[Saucestorm], 1, "A cheap elemental damage spell."),
    new guideSkill($skills[Steely-Eyed Squint], 1, "Doubles item drops once a day."),
    new guideSkill($skills[Shattering Punch], 1, "Three free kills a day."),
    new guideSkill($skills[Torso Awareness], 1, "Lets you wear the shark jumper."),
    new guideSkill($skills[Tongue of the Walrus], 1, "Healing, and clears Beaten Up."),
    new guideSkill($skills[Cannelloni Cocoon], 1, "Healing."),
};

record guidePull {
    boolean [item] any;
    boolean flexible;
    string why;
};

guidePull [int] guidePulls = {
    new guidePull($items[shark jumper], false, "Elemental resistance, and the Mom fight."),
    new guidePull($items[pro skateboard], false, "The McTwist on the unholy diver, for the diving helmet."),
    new guidePull($items[pulled yellow taffy], false, "Used on the unholy diver after the McTwist."),
    new guidePull($items[cozy scimitar], false, "Fish scales with Harpoon! and Summon Leviatuga."),
    new guidePull($items[Centauri fish wine], false, "60 turns of Fishy."),
    new guidePull($items[Aldebaran sardines], false, "60 turns of Fishy."),
    new guidePull($items[Tubetto Gelatto, Frutti di Scatoletta, Pesto alla Marziano,
        Arrattabbattabiata, Orzo di Riso, Pasta Grimavera, Linguini Ubriacapa,
        Gnocci Domani, Formica e Pepe], false, "Fishy, doubled by eating it with your stomach."),
    new guidePull($items[Bram's choker], false, "Noncombat rate."),
    new guidePull($items[rusted-out shootin' iron], false, "Noncombat rate, and a club for Batter Up!"),
    new guidePull($items[null-day exploit], false, "Null Afternoon for the Colosseum and Shub-Jigguwatt."),
    new guidePull($items[patent aggression tonic, lion musk], false, "Combat rate."),
    new guidePull($items[petrified wood wizard's pouch, Congressional Medal of Insanity,
        petrified wood water purifier], false, "The lantern for the Colosseum spell route."),
    new guidePull($items[large box], false, "A blessed large box of bang potions, for the seed finder."),
    new guidePull($items[Mer-kin hallpass], true, "Skips most of the scholar route."),
    new guidePull($items[hardened slime belt, six-rainbow shield], true, "Elemental resistance."),
    new guidePull($items[Pocket Square of Loathing], true, "Elemental resistance."),
    new guidePull($items[1\,970 carat gold], true, "Meat."),
    new guidePull($items[bottle of Lambada Lambic], true, "Item drop for the Coral Corral."),
    new guidePull($items[Mer-kin sneakmask], true, "Noncombat rate."),
    new guidePull($items[peppermint parasol], true, "Free runaways, about 9 turns saved."),
    new guidePull($items[lodestone], true, "Saves 5 turns."),
    new guidePull($items[waffle], true, "Finds the seahorse sooner."),
    new guidePull($items[stench jelly, Clara's bell, handheld Allied radio], true, "A noncombat forcer."),
    new guidePull($items[aquamariner's necklace, lucky rabbitfish fin], true, "MP regen, cheaper than restores."),
};

string skillNames(boolean [skill] list) {
    string out;
    foreach sk in list
        out += (out == "" ? "" : " or ") + sk;
    return out;
}

string itemNames(boolean [item] list) {
    string out;
    foreach it in list
        out += (out == "" ? "" : " or ") + it;
    return out;
}

void printGuidePulls(boolean flexible) {
    foreach num, gp in guidePulls {
        if (gp.flexible != flexible)
            continue;
        boolean held;
        boolean buyable;
        foreach it in gp.any {
            if (have_item(it) || pulledToday(it))
                held = true;
            if (is_tradeable(it))
                buyable = true;
        }
        if (held)
            print("✓ " + itemNames(gp.any) + ": " + gp.why, "blue");
        else if (buyable)
            print("✗ " + itemNames(gp.any) + ": " + gp.why + " Not in Hagnk's, mall-buyable.", "red");
        else
            print("✗ " + itemNames(gp.any) + ": " + gp.why + " NOT mall-buyable, get it before you ascend.", "red");
    }
}

// Resting MP as mafia works it out: the base, scaled by the percent bonus, plus the flat bonus.
int restingMP(float base, float percent, float bonus) {
    int mp = to_int(base);
    if (percent != 0)
        mp = to_int(mp * (percent + 100) / 100);
    return mp + to_int(bonus);
}

// Under 50 MP a rest, a tent or the bare ground, the route buys most of its MP.
boolean housingWeak(int restMP) {
    return restMP < 50;
}

// The sim lists housing to pull and install after ascending, since the dwelling does not carry over.
// In run it reads the resting MP of the dwelling and furniture and names housing on hand when that is weak.
void guideHousingCheck(boolean runStart) {
    boolean [item] homes = $items[Xiblaxian residence-cube, hobo fortress blueprints, gingerbread house,
        house-sized mushroom, house of twigs and spit];
    string onHand;
    string buyable;
    foreach it in homes {
        int more = to_int(numeric_modifier(it, "Base Resting MP"));
        if (available_amount(it) + storage_amount(it) > 0)
            onHand += (onHand == "" ? "" : ", ") + it + " (" + more + " MP"
                + (runStart && available_amount(it) == 0 ? ", one pull" : "") + ")";
        else if (!runStart && mall_price(it) > 0)
            buyable += (buyable == "" ? "" : ", ") + it + " (" + more + " MP, " + mall_price(it) + " meat)";
    }
    if (!runStart) {
        if (onHand != "")
            print("✓ Housing: the dwelling is lost on ascending; " + onHand + " on hand to pull and install in run.", "blue");
        else
            print("✗ Housing: the dwelling is lost on ascending, and the route rests for most of its MP. Put one of these in Hagnk's "
                + "to pull and install in run: " + (buyable == "" ? "none is in the mall" : buyable) + ".", "red");
        return;
    }
    item home = get_dwelling();
    string name = home == $item[none] ? "the ground" : to_string(home);
    int mp = restingMP(numeric_modifier("Base Resting MP"), numeric_modifier("Resting MP Percent"), numeric_modifier("Bonus Resting MP"));
    if (!housingWeak(mp)) {
        print("✓ Housing: " + name + ", " + mp + " MP a rest", "blue");
        return;
    }
    print("✗ Housing: " + name + " gives " + mp + " MP a rest, and the route rests for most of its MP. Short of it, mafia buys MP restores with meat."
        + (onHand == "" ? "" : " Install one now: " + onHand + "."), "red");
}

// Prints the low IOTM route's requirements and returns the hard blockers as
// abort text, empty when the route can start. runStart is false for the sim report.
string lowIOTMChecklist(boolean runStart) {
    string blockers;
    print("Low IOTM route: no Monodent of the Sea, so the run follows the low IOTM guide.", "blue");

    if (!runStart)
        print("Ascend as a Seal Clubber for best results. Batter Up!, its Fury skills and the Colosseum combat route are Seal Clubber skills.", "blue");
    else if (my_class() == $class[Seal Clubber])
        print("✓ Seal Clubber", "blue");
    else
        print("Warning: this low IOTM run is a " + my_class() + ", not a Seal Clubber. A one day run may not complete off Seal Clubber on a low IOTM account. Continuing.", "red");

    if (runStart && in_hardcore()) {
        print("✗ Hardcore: the low IOTM route is softcore only.", "red");
        blockers += "The route is softcore only, it needs the guide's pulls. ";
    }

    // The ice house banish never resets, so mafia's record survives ascending.
    monster iceHouse = banished("ice house");
    if (iceHouse == $monster[Mer-kin rustler])
        print("✓ Ice house: Mer-kin rustler", "blue");
    else if (iceHouse == $monster[none])
        print("✗ Ice house: mafia has no monster recorded there. The route assumes the Mer-kin rustler.", "red");
    else
        print("✗ Ice house: holds the " + iceHouse + ". The route assumes the Mer-kin rustler.", "red");

    // Big Brother's sea maps stay bought across ascensions, and the guide buys them all beforehand.
    string [item] seaMaps = {
        $item[map to Anemone Mine]: "mapToAnemoneMinePurchased",
        $item[map to the Marinara Trench]: "mapToTheMarinaraTrenchPurchased",
        $item[map to the Dive Bar]: "mapToTheDiveBarPurchased",
        $item[map to Madness Reef]: "mapToMadnessReefPurchased",
        $item[map to the Skate Park]: "mapToTheSkateParkPurchased"
    };
    string unbought;
    foreach it, prop in seaMaps
        if (get_property(prop) != "true")
            unbought += (unbought == "" ? "" : ", ") + it + " ("
                + sell_price($coinmaster[Big Brother], it) + " sand dollars)";
    if (unbought == "")
        print("✓ Sea maps: all bought from Big Brother", "blue");
    else
        print("✗ Sea maps not bought from Big Brother yet: " + unbought
            + ". The guide buys them before ascending. In run, Little Brother opens Anemone Mine, the Marinara Trench or the Dive Bar for a Muscle, Mysticality or Moxie class.", "red");

    // Untradeable, so only Hagnk's can supply it. Pulled today or past day one,
    // a missing scimitar has broken after its fights.
    if (have_item($item[cozy scimitar]))
        print("✓ cozy scimitar", "blue");
    else if (runStart && (pulledToday($item[cozy scimitar]) || my_daycount() > 1))
        print("✗ cozy scimitar: not held, so the run falls back to the script's other fish scale sources.", "red");
    else
        print("✗ cozy scimitar: NOT mall-buyable, make it from a scimitar cozy and a fish scimitar before you ascend. Without it the run falls back to the script's other fish scale sources.", "red");

    guideHousingCheck(runStart);

    string route = colosseumRoute(runStart);
    if (route == "spell") {
        print("✓ Colosseum: spell route, lantern " + colosseumLantern() + ".", "blue");
        if (!have_skill($skill[Carol of the Hells]) && !have_skill($skill[Song of Sauce]))
            print("✗ Carol of the Hells or Song of Sauce: a heavy spell damage buff for the spell route.", "red");
    } else if (route == "combat") {
        print("✓ Colosseum: combat route with Furious Wallop. The Mer-kin weapons are trained in-run.", "blue");
        if (!nullDayAvailable())
            print("✗ null-day exploit: none owned and none buyable with a pull. The combat route leans on Null Afternoon.", "red");
    } else if (to_int(get_property("lastColosseumRoundWon")) >= 15) {
        print("✓ Colosseum: already won.", "blue");
    } else {
        print("✗ Colosseum: no route yet, the run stops at the Colosseum without one. " + colosseumMissing(), "red");
    }

    print("Low IOTM check, guide perms:");
    int skillsMet;
    foreach num, gs in guideSkills {
        int owned;
        foreach sk in gs.any
            if (have_skill(sk))
                owned += 1;
        if (owned >= gs.need) {
            skillsMet += 1;
            print("✓ " + skillNames(gs.any) + ": " + gs.why, "blue");
        } else
            print("✗ " + skillNames(gs.any) + ": " + gs.why, "red");
    }
    print("Low IOTM check: " + skillsMet + " of " + count(guideSkills) + " guide perms owned.");

    print("Low IOTM check, guide pulls (practically mandatory):");
    printGuidePulls(false);
    print("Low IOTM check, guide pulls (flexible):");
    printGuidePulls(true);

    if (blockers != "")
        print("Low IOTM check: the run can't start. " + blockers, "red");
    return blockers;
}

// ─── LOW IOTM PULLS, BREAKFAST AND DIET ──────────────────────────────────────
// Pulled by the phase that uses them, not by the breakfast plan.
boolean [item] guidePullsOnDemand = $items[lodestone, waffle, stench jelly, Clara's bell,
    handheld Allied radio];

boolean guidePullOnDemand(guidePull gp) {
    foreach it in gp.any
        if (guidePullsOnDemand contains it)
            return true;
    return false;
}

// Pulls the on-demand lines and reservedPulls() may still need, kept free of the regen pull.
int onDemandPulls() {
    int n = reservedPulls();
    foreach num, gp in guidePulls {
        if (!guidePullOnDemand(gp))
            continue;
        boolean needed = true;
        foreach it in gp.any
            if (available_amount(it) > 0 || pulledToday(it))
                needed = false;
        if ((gp.any contains $item[lodestone]) && storage_amount($item[lodestone]) == 0)
            needed = false;
        if (needed)
            n += 1;
    }
    return n;
}

// The low IOTM breakfast runs once per ascension, recorded as the ascension number.
boolean lowIOTMBreakfastDone() {
    return get_property("uts_lowIOTMBreakfast") == to_string(my_ascensions());
}

// The MP regen pull: the aquamariner's necklace when it can be worn and is in Hagnk's or within
// autoBuyPriceLimit, else the lucky rabbitfish fin. regenPullNote says why, for lowIOTMPulls() to print.
string regenPullNote;

item regenPullChoice() {
    item necklace = $item[aquamariner's necklace];
    item fin = $item[lucky rabbitfish fin];
    int limit = to_int(get_property("autoBuyPriceLimit"));
    int price = mall_price(necklace);
    string why;
    regenPullNote = "";
    if (!can_equip(necklace))
        why = "the " + necklace + " needs 85 Mysticality";
    else if (storage_amount(necklace) > 0)
        return necklace;
    else if (price > 0 && price <= limit) {
        regenPullNote = "Low IOTM pulls: buying the " + necklace + " for " + price + " meat, within autoBuyPriceLimit " + limit + ".";
        return necklace;
    } else if (price > 0)
        why = "the " + necklace + " is not in Hagnk's and costs " + price + " meat, over autoBuyPriceLimit " + limit;
    else
        why = "the " + necklace + " is not in Hagnk's or the mall";
    if (storage_amount(fin) == 0 && mall_price(fin) <= 0) {
        print("Low IOTM pulls: no MP regen pull, " + why + " and the " + fin + " is not in Hagnk's or the mall.", "red");
        return $item[none];
    }
    regenPullNote = "Low IOTM pulls: the " + fin + " for MP regen, since " + why + ".";
    return fin;
}

// The item to pull for a guide line: none when one is on hand, already pulled
// today or unused by this route, else Hagnk's stock, else the cheapest listing.
item guidePullChoice(guidePull gp) {
    foreach it in gp.any
        if (available_amount(it) > 0 || pulledToday(it))
            return $item[none];
    if (gp.any contains $item[aquamariner's necklace])
        return regenPullChoice();
    if ((gp.any contains $item[shark jumper])
        && !have_skill($skill[Torso Awareness]) && !have_skill($skill[Best Dressed])) {
        print("Low IOTM pulls: no Torso Awareness, so no " + $item[shark jumper] + ".", "red");
        return $item[none];
    }
    string route = colosseumRoute(false);
    if ((gp.any contains $item[null-day exploit]) && route != "spell" && route != "combat")
        return $item[none];
    if (gp.any contains $item[petrified wood wizard's pouch]) {
        if (route != "spell")
            return $item[none];
        return storage_amount(colosseumLantern()) > 0 ? colosseumLantern() : $item[none];
    }
    foreach it in gp.any
        if (storage_amount(it) > 0)
            return it;
    item pick = $item[none];
    int best;
    foreach it in gp.any {
        int price = is_tradeable(it) ? mall_price(it) : 0;
        if (price > 0 && (pick == $item[none] || price < best)) {
            pick = it;
            best = price;
        }
    }
    if (pick == $item[none])
        print("Low IOTM pulls: " + itemNames(gp.any) + " is not in Hagnk's or the mall.", "red");
    return pick;
}

// A mall buy over autoBuyPriceLimit is skipped with a note instead of pullSequence()'s prompt.
boolean guidePullOne(item it) {
    if (pulledToday(it) || pulls_remaining() == 0)
        return false;
    if (storage_amount(it) == 0) {
        int limit = to_int(get_property("autoBuyPriceLimit"));
        if (mall_price(it) > limit) {
            print("Low IOTM pulls: " + it + " costs " + mall_price(it) + " meat, over autoBuyPriceLimit "
                + limit + ", skipped.", "red");
            return false;
        }
        if (buy_using_storage(1, it, limit) < 1) {
            print("Low IOTM pulls: couldn't buy a " + it + " into Hagnk's for " + limit + " meat or less.", "red");
            return false;
        }
    }
    if (!take_storage(1, it)) {
        print("Low IOTM pulls: couldn't pull the " + it + ".", "red");
        return false;
    }
    return true;
}

// The guide's pulls in its priority order, once per ascension.
void lowIOTMPulls() {
    if (lowIOTMBreakfastDone())
        return;
    step("low IOTM pulls: " + pulls_remaining() + " left");
    foreach num, gp in guidePulls {
        if (guidePullOnDemand(gp))
            continue;
        item it = guidePullChoice(gp);
        boolean pulling = it != $item[none] && pulls_remaining() != 0;
        if (pulling && (gp.any contains $item[aquamariner's necklace])
            && pulls_remaining() > 0 && pulls_remaining() <= onDemandPulls()) {
            print("Low IOTM pulls: no " + it + ", its pull is kept for the on-demand pulls.", "blue");
            continue;
        }
        if (it != $item[none] && !pulling)
            print("Low IOTM pulls: out of pulls, no " + it + ".", "red");
        if (pulling && (gp.any contains $item[aquamariner's necklace]) && regenPullNote != "")
            print(regenPullNote, "blue");
        if (pulling && guidePullOne(it) && it == $item[Mer-kin hallpass]
            && !put_closet(item_amount(it), it))
            print("Low IOTM pulls: couldn't closet the " + it + ".", "red");
        // A large box without a ten-leaf clover or its blessed box still needs the clover.
        if ((gp.any contains $item[large box]) && available_amount($item[large box]) > 0
            && available_amount($item[ten-leaf clover]) + available_amount($item[blessed large box]) == 0)
            guidePullOne($item[ten-leaf clover]);
    }
}

// The fortune cookie holds a ten-leaf clover for the large box. Eaten only in
// the first breakfast and only on an empty stomach, as the guide's first food.
void lowIOTMFortuneCookie() {
    if (lowIOTMBreakfastDone() || my_fullness() > 0 || fullness_limit() < 1
        || available_amount($item[ten-leaf clover]) + available_amount($item[blessed large box]) > 0)
        return;
    if (available_amount($item[large box]) + storage_amount($item[large box]) == 0
        && (pulledToday($item[large box]) || mall_price($item[large box]) <= 0
            || mall_price($item[large box]) > to_int(get_property("autoBuyPriceLimit"))))
        return;
    if (!retrieve_item(1, $item[fortune cookie]) || !eat(1, $item[fortune cookie])) {
        print("Low IOTM breakfast: couldn't eat a " + $item[fortune cookie] + ".", "red");
        return;
    }
    if (available_amount($item[ten-leaf clover]) == 0)
        print("Low IOTM breakfast: the " + $item[fortune cookie] + " gave no "
            + $item[ten-leaf clover] + ", so the pulls add one for the large box.", "red");
}

// Ode to Booze before a drink. Donho's Bubbly Ballad gives up its song slot
// when Ode won't fit. False when Ode is owned but couldn't be cast.
boolean odeUp() {
    if (!have_skill($skill[The Ode to Booze]) || have_effect($effect[Ode to Booze]) > 0)
        return true;
    if (use_skill(1, $skill[The Ode to Booze]))
        return true;
    if (have_effect($effect[Donho's Bubbly Ballad]) > 0
        && cli_execute("shrug Donho's Bubbly Ballad")
        && use_skill(1, $skill[The Ode to Booze]))
        return true;
    if (guideRoute() && have_effect($effect[Polka of Plenty]) > 0
        && cli_execute("shrug Polka of Plenty")
        && use_skill(1, $skill[The Ode to Booze]))
        return true;
    print("Couldn't cast " + $skill[The Ode to Booze] + ".", "red");
    return false;
}

// Aldebaran sardines and Centauri fish wine need level 4.
boolean fishyFoodsAllowed() {
    return my_level() >= 4;
}

// A legendary pasta food eaten with option 5 of choice 1599, the stomach,
// which doubles the effects of the next three foods.
void eatLegendaryPasta() {
    foreach it in pasta_prices {
        if (item_amount(it) == 0 || fullness_limit() - my_fullness() < 1)
            continue;
        string saved = get_property("choiceAdventure1599");
        boolean ate;
        try {
            set_property("choiceAdventure1599", "5");
            ate = eat(1, it);
        } finally {
            set_property("choiceAdventure1599", saved);
        }
        if (handling_choice() && last_choice() == 1599) {
            print("Legendary Digestion stayed open without the stomach option; taking its first option.", "red");
            foreach opt in available_choice_options() {
                run_choice(opt);
                break;
            }
        }
        if (!ate)
            print("Low IOTM diet: couldn't eat the " + it + ".", "red");
        else if (to_int(get_property("legendaryNoodlesStomach")) == 0)
            print("Low IOTM diet: the " + it + " didn't set up the stomach option.", "red");
        return;
    }
}

// Legendary pasta then the sardines it doubles. The pasta waits for the
// sardines, and both need 3 fullness free.
void eatPastaAndSardines() {
    if (!fishyFoodsAllowed() || item_amount($item[Aldebaran sardines]) == 0
        || fullness_limit() - my_fullness() < 2)
        return;
    if (fullness_limit() - my_fullness() >= 3)
        eatLegendaryPasta();
    if (!eat(1, $item[Aldebaran sardines]))
        print("Low IOTM diet: couldn't eat the " + $item[Aldebaran sardines] + ".", "red");
}

// Guide diet: legendary pasta, Aldebaran sardines at double Fishy, then
// Centauri fish wine and the astral pilsners under Ode. What can't happen now
// waits for the Fishy and zero adventure steps in post_adv().
void lowIOTMDiet() {
    if (!fishyFoodsAllowed())
        print("Low IOTM diet: below level 4, so the " + $item[Aldebaran sardines] + ", "
            + $item[Centauri fish wine] + " and legendary pasta wait.", "red");
    eatPastaAndSardines();
    if (item_amount($item[astral six-pack]) > 0 && !use(1, $item[astral six-pack]))
        print("Low IOTM diet: couldn't open the " + $item[astral six-pack] + ".", "red");
    if (item_amount($item[Centauri fish wine]) + item_amount($item[astral pilsner]) == 0
        || my_inebriety() >= inebriety_limit() || !odeUp())
        return;
    if (fishyFoodsAllowed() && item_amount($item[Centauri fish wine]) > 0
        && inebriety_limit() - my_inebriety() >= 2 && !drink(1, $item[Centauri fish wine]))
        print("Low IOTM diet: couldn't drink the " + $item[Centauri fish wine] + ".", "red");
    while (item_amount($item[astral pilsner]) > 0 && my_inebriety() < inebriety_limit()) {
        int before = item_amount($item[astral pilsner]);
        if (!drink(1, $item[astral pilsner]) || item_amount($item[astral pilsner]) >= before)
            break;
    }
}

// The old SCUBA tank is bought for the hat and chaps lasso training, which ends at 20. The chaps are
// never made while a Mer-kin tailpiece is held.
boolean tankOnRoute(boolean tank, boolean tamed, int training, boolean chaps, boolean tailpiece) {
    return !tank && !tamed && training < 20 && (chaps || !tailpiece);
}

// True when the tank is on route, still to buy, and meat covers its price plus spare.
boolean tankBuyNow(boolean onRoute, boolean held, int meat, int price, int spare) {
    return onRoute && !held && meat >= price + spare;
}

// Guide route: the old SCUBA tank is still to buy for this run's lasso training.
boolean scubaTankOnRoute() {
    if (!guideRoute())
        return false;
    int tailpieces = available_amount($item[crappy Mer-kin tailpiece]) + available_amount($item[Mer-kin gladiator tailpiece])
        + available_amount($item[Mer-kin scholar tailpiece]);
    return tankOnRoute(available_amount($item[old SCUBA tank]) > 0, get_property("seahorseName") != "",
        to_int(get_property("lassoTrainingCount")), available_amount($item[sea chaps]) > 0, tailpieces > 0);
}

// Free rests at the housing, toward 400 MP.
void lowIOTMRestMP() {
    if (restWouldCostFury())
        return;
    int mpTarget = min(my_maxmp(), 400);
    while (my_mp() < mpTarget && to_int(get_property("timesRested")) < total_free_rests()) {
        int before = my_mp();
        if (!cli_execute("rest free") || my_mp() <= before)
            break;
    }
}

// The guide's ascension breakfast, once per ascension. A restart only tops up
// MP, so nothing here, Sea Strength included, lands again before Yog-Urt.
void lowIOTMBreakfast() {
    if (lowIOTMBreakfastDone()) {
        lowIOTMRestMP();
        return;
    }
    step("low IOTM breakfast");
    item gold = $item[1\,970 carat gold];
    if (item_amount(gold) > 0 && !autosell(item_amount(gold), gold))
        print("Low IOTM breakfast: couldn't autosell the " + gold + ".", "red");

    // Three clovers: the Outpost's sand dollars and two Madness Reef visits.
    // The hermit trade gets its own permit and worthless items.
    int clovers = 3 - to_int(get_property("_cloversPurchased"));
    if (clovers > 0 && !hermit(clovers, $item[11-leaf clover]))
        print("Low IOTM breakfast: the hermit didn't trade " + clovers + " " + $item[11-leaf clover] + ".", "red");

    boolean songs;
    foreach sk in $skills[The Ode to Booze, The Sonata of Sneakiness, Fat Leon's Phat Loot Lyric,
        The Polka of Plenty, Carlweather's Cantata of Confrontation, Donho's Bubbly Ballad]
        if (have_skill(sk))
            songs = true;
    if (songs && my_class() != $class[Accordion Thief] && available_amount($item[antique accordion]) == 0
        && !buy(1, $item[antique accordion]))
        print("Low IOTM breakfast: couldn't buy an " + $item[antique accordion] + ".", "red");

    // Batter Up! needs a club unless Iron Palms makes the scimitar count as one.
    boolean club = have_skill($skill[Iron Palm Technique])
        || item_type(equipped_item($slot[weapon])) == "club";
    foreach it in get_inventory()
        if (item_type(it) == "club")
            club = true;
    if (!club && !(knoll_available() && buy(1, $item[Gnollish flyswatter])))
        print("Low IOTM breakfast: no club for Batter Up!, and couldn't buy a "
            + $item[Gnollish flyswatter] + ".", "red");

    if (have_familiar($familiar[grouper groupie]) && my_familiar() != $familiar[grouper groupie]
        && !use_familiar($familiar[grouper groupie]))
        print("Low IOTM breakfast: couldn't switch to the " + $familiar[grouper groupie] + ".", "red");

    // Held for Yog-Urt.
    foreach sc in $items[scroll of sea smarts, scroll of sea smarm]
        if (item_amount(sc) == 0 && !retrieve_item(1, sc))
            print("Low IOTM breakfast: couldn't buy a " + sc + ".", "red");

    lowIOTMRestMP();
    lowIOTMDiet();

    // One scroll for 50 turns. Nothing else applies Sea Strength before Yog-Urt.
    if (have_effect($effect[Sea Strength]) == 0
        && (!retrieve_item(1, $item[scroll of sea strength]) || !use(1, $item[scroll of sea strength])))
        print("Low IOTM breakfast: couldn't use a " + $item[scroll of sea strength] + ".", "red");

    set_property("uts_lowIOTMBreakfast", my_ascensions());
}

// Fishy on the low IOTM route: guide consumables still on hand, then sushi
// from the old man's crate of fish meat. No fish sauce pulls and no clovers.
void lowIOTMFishy() {
    eatPastaAndSardines();
    if (have_effect($effect[Fishy]) > 0)
        return;
    if (fishyFoodsAllowed() && item_amount($item[Centauri fish wine]) > 0
        && inebriety_limit() - my_inebriety() >= 2) {
        odeUp();
        if (drink(1, $item[Centauri fish wine]))
            return;
    }
    if (item_amount($item[crate of fish meat]) > 0 && !use(1, $item[crate of fish meat]))
        print("Couldn't open the " + $item[crate of fish meat] + ".", "red");
    foreach it in $items[beefy fish meat, glistening fish meat, slick fish meat]
        if (item_amount(it) > 0) {
            if (fullness_limit() - my_fullness() < 2)
                print("No stomach room for a nigiri.", "red");
            else if (retrieve_item(1, $item[white rice]))
                eatSushi();
            return;
        }
}

// Fishy from a pull when nothing held gives it: Aldebaran sardines, eaten after a held legendary pasta,
// else Centauri fish wine. Each pull is one per item per day and capped at autoBuyPriceLimit.
boolean lowIOTMFishyPull() {
    if (have_effect($effect[Fishy]) > 0)
        return true;
    if (!fishyFoodsAllowed())
        return false;
    item sardines = $item[Aldebaran sardines];
    item wine = $item[Centauri fish wine];
    if (fullness_limit() - my_fullness() >= sardines.fullness && guidePullOne(sardines))
        eatPastaAndSardines();
    if (have_effect($effect[Fishy]) == 0 && inebriety_limit() - my_inebriety() >= wine.inebriety
        && guidePullOne(wine)) {
        odeUp();
        if (!drink(1, wine))
            print("Couldn't drink the " + wine + ".", "red");
    }
    return have_effect($effect[Fishy]) > 0;
}

// More adventures at zero on the low IOTM route: kelp pucks, then Ocean-Touched
// Rum once Yog-Urt is down, since its Muscle would break the Yog-Urt HP check.
boolean lowIOTMTopUp() {
    int before = my_adventures();
    // Room for one nigiri stays free while a crate or fish meat can still feed Fishy.
    int keep = (get_property("questS01OldGuy") != "finished"
        || item_amount($item[crate of fish meat]) + item_amount($item[beefy fish meat])
            + item_amount($item[glistening fish meat]) + item_amount($item[slick fish meat]) > 0)
        ? 2 : 0;
    if (fullness_limit() - my_fullness() - keep >= 2) {
        if (item_amount($item[kelp puck]) == 0 && item_amount($item[sand penny]) >= 30
            && !buy($coinmaster[Wet Crap For Sale], 1, $item[kelp puck]))
            print("Couldn't buy a " + $item[kelp puck] + ".", "red");
        if (item_amount($item[kelp puck]) > 0 && !eat(1, $item[kelp puck]))
            print("Couldn't eat a " + $item[kelp puck] + ".", "red");
    }
    if (my_adventures() > before)
        return true;
    if (get_property("yogUrtDefeated") == "true" && inebriety_limit() - my_inebriety() >= 2) {
        if (item_amount($item[Ocean-Touched Rum]) == 0 && item_amount($item[sand penny]) >= 30
            && !buy($coinmaster[Wet Crap For Sale], 1, $item[Ocean-Touched Rum]))
            print("Couldn't buy an " + $item[Ocean-Touched Rum] + ".", "red");
        if (item_amount($item[Ocean-Touched Rum]) > 0) {
            odeUp();
            if (!drink(1, $item[Ocean-Touched Rum]))
                print("Couldn't drink the " + $item[Ocean-Touched Rum] + ".", "red");
        }
    }
    return my_adventures() > before;
}
