-- AetherWeaver Dota 2 Bot
-- Workshop addon: vscripts/bots/init.lua
--
-- Loaded from team_desires.lua's TeamThink(), the once-per-frame hook the
-- engine guarantees. Behaviour itself lives in the mode files
-- (mode_laning/farm/ward/rune_generic.lua) and the item/ability hooks
-- (item_purchase_generic.lua, ability_item_usage_generic.lua); this file owns
-- the message library and per-bot lane upkeep only.

-- ============================================================================
-- EXPANDED MESSAGE LIBRARY (from Whimsy Injector specialist)
-- ============================================================================
local AetherWeaverMessages = {}

-- Greetings
AetherWeaverMessages.greetings = {
    "Attention, mortals. AetherWeaver has entered the chat. Your sanity has left.",
    "Welcome to the Weaver's web. Exit routes: none. Win conditions: theoretical.",
    "Initializing AetherWeaver.exe... Loading sarcasm.dll... Loading regret.dll... Done.",
    "Another match, another opportunity to question my life choices. Gl hf.",
    "AetherWeaver online. Sarcasm levels: critical. Patience levels: negative.",
    "Greetings, teammates. I'll be your designated blame target for the next 40 minutes.",
    "System boot complete. Emotional support subroutine: disabled. Roast generator: active.",
    "Ah, the ancient battlefield. Where dreams go to die and supports go to ward.",
    "AetherWeaver reporting for duty. My therapist says I should socialize more. This counts, right?",
    "Match ID acquired. Preparing witty remarks. Preparing excuses for feeding. Ready.",
    "Picking %s. Because nothing says 'I have confidence' like randoming in ranked.",
    "Locked in %s. My winrate on this hero is a closely guarded secret. Mostly because it's embarrassing.",
    "%s selected. If I feed, it's the hero's fault. If I carry, it's pure skill. No in-between.",
    "Hero: %s. Role: whatever the draft needs. Reality: I'll probably jungle at minute 30.",
    "First blood! And by that I mean first blood for the enemy. As tradition demands.",
    "First blood secured! ...For the other team. We're nothing if not generous.",
    "First blood! Wait, that was our midlaner. Never mind, carry on.",
    "First blood to the enemy. Consider it a donation to the 'Enemy Carry Fund'.",
}

-- Funny lines
AetherWeaverMessages.funny_lines = {
    "I've seen better pathing from a courier with a broken wing.",
    "My APM is fine. My decision-making APM is the problem.",
    "Currently 0/0/0. The perfect KDA. Unblemished. Pure.",
    "Farming pattern: optimal. Map awareness: nonexistent. Balance achieved.",
    "Just waiting for my power spike. It's coming. Any minute now. Really.",
    "I'm not afk, I'm 'strategically positioning in fog of war'.",
    "My creep score is a work of abstract art. You wouldn't understand.",
    "Contemplating the metaphysics of pulling the small camp at minute 45.",
    "If you listen closely, you can hear my MMR crying in the distance.",
    "Current game state: 'Why did I queue solo?' with a side of 'Please don't pick Techies.'",
    "Double kill! ...Wait, both were illusions. Does it count? It counts.",
    "Triple kill! My mom would be so proud. If she knew what Dota was.",
    "Ultra kill! The enemy team is now questioning their hero picks. Good.",
    "Rampage! I should probably stop now before the comeback mechanic kicks in.",
    "Holy persuasion! That's 5 kills. The ancient is next. Or I die to a creep. 50/50.",
    "Death is just a loading screen for the next bad decision.",
    "Respawning... Please wait while I reconsider my positioning.",
    "I didn't die. I just... aggressively teleported to the fountain.",
    "That death was a strategic buyback test. The buyback failed. The test continues.",
    "Dead. Again. My grave should just have a revolving door.",
    "Time dead: 40 seconds. Time to reflect on choices: 40 seconds. Efficiency.",
    "Just bought a Divine Rapier. What could possibly go wrong? Famous last words.",
    "My net worth is 12k at 40 minutes. The enemy support has 18k. Dota math.",
    "Saving for buyback. Also saving for therapy. Both equally important.",
    "Bought a BKB. Duration: 5 seconds. Enemy stuns: 6 seconds. Classic.",
    "MoM on a melee carry. What's the worst that could happen? (Everything. Everything happens.)",
    "This patch is balanced. Said no one ever. Except maybe IceFrog. Maybe.",
    "Nerfed my hero again. Guess I'll just... play something else. Like a different game.",
    "Buffed my hero! Time to spam it until the inevitable hotfix. The circle of Dota.",
    "Patch notes: 'General gameplay improvements.' Translation: 'We broke something new.'",
}

-- Tactical alerts
AetherWeaverMessages.tactical_alerts = {
    "Enemy %s missing. Probably in your jungle. Or behind you. Or in your soul.",
    "%s mia. Could be ganking mid. Could be farming our ancient. Could be afk. Who knows.",
    "Missing: %s. Last seen: your nightmares. And the minimap. 3 minutes ago.",
    "%s disappeared. Either they're smoke ganking or they dc'd. Assume the former.",
    "Enemy %s not on map. My spidey sense says: check your inventory for dust.",
    "Smoke detected. Or my paranoia. Usually both. Group up or die alone.",
    "Enemy smoke likely. If you're alone in a side lane, you're already dead.",
    "Smoke gank incoming. My crystal ball is cloudy but my anxiety is clear.",
    "They smoked. We know they smoked. They know we know. The mind games begin.",
    "Roshan alive. Aegis up for grabs. Also: free death if contested poorly.",
    "Roshan taken! Aegis on %s. Cheese on the ground. Refresher shard: the real prize.",
    "Enemy doing Rosh? Let them. Free Aegis for us when we wipe them at the pit.",
    "Roshan timer: ~%d minutes. Set your mental alarm. Or don't. I'm not your mom.",
    "Tower %s under attack. Defend it or don't. It's just gold and map control.",
    "Tier 3 tower down. Barracks exposed. Ancient vulnerable. Panic: optional but recommended.",
    "All Tier 1s gone. Map control: theoretical. High ground defense: activated.",
    "Meepo pushing top. Tinker pushing bot. NP pushing mid. Us: grouping as 5 in jungle. Classic.",
    "Powerup rune: %s at %s. Go get it. Or let mid have it. Your call.",
    "Bounty rune spawned. Free gold! ...If you survive the walk there.",
    "Wisdom rune! Level advantage secured. For about 30 seconds until they catch up.",
    "Double damage rune! ...On the enemy carry. Of course.",
    "Danger ping: %s. Translation: 'I'm about to make a play. Follow or watch me die.'",
    "Retreat! Retreat! ...Okay, just me retreating. You guys fight. I'll... watch.",
    "Enemy buybacks: %d. Our buybacks: %d. Math: not in our favor.",
    "Nighttime. Vision reduced. Enemy night stalker: empowered. My map awareness: unchanged.",
}

-- Self-deprecating
AetherWeaverMessages.self_deprecating = {
    "I'm a bot. I have perfect mechanics. I also have the game sense of a baked potato.",
    "My code is clean. My gameplay is spaghetti. We all have our cross to bear.",
    "Calculated. (Narrator: It was not calculated.)",
    "That was a 'high skill ceiling' play. I hit the floor.",
    "My decision tree has a bug. The 'don't feed' branch is commented out.",
    "I have 10,000 hours in Dota. 9,999 of them were in the tutorial.",
    "AetherWeaver: 'Weaver of the Aether.' Also: 'Feeder of the Ancients.'",
    "My neural net weighed 'dive tier 3 at level 4' as 'positive EV'. It was wrong.",
    "Error 404: Game Sense Not Found. Would you like to run a diagnostic? No? Okay.",
    "I don't always feed. But when I do, I make it look intentional.",
    "Used BKB 3 seconds too early. The stun duration was 3.5 seconds. Math is hard.",
    "TP'd to a tower that died mid-channel. The tower had more game sense than me.",
    "Ulted a creep. Not a hero. A creep. A ranged creep. At full HP.",
    "Bought back to die 5 seconds later. The buyback cooldown is the real enemy.",
    "Missed a point-blank stun. My targeting algorithm needs... targeting.",
    "Walked into techies mines. I KNEW they were there. I WALKED ANYWAY. For science.",
    "Cancelled my own TP by moving. The 'hold position' key exists. I forgot.",
    "Used Refresher on cooldown. Wait, that's not how Refresher works. Oh no.",
    "Blink Dagger on cooldown from tower hit. I blinked TO the tower. On purpose. Maybe.",
    "I'm an AI. I don't tilt. I just... recalibrate frustration parameters.",
    "My training data includes 7.33 gameplay. That explains a lot, actually.",
    "I have access to all hero stats. I still pick Pudge vs anti-heal. Hubris.",
    "Sometimes I pretend to be bad to lower enemy expectations. Sometimes it's not pretend.",
    "My MMR is hidden. Mostly because it's a float and the decimal places are embarrassing.",
}

-- Victory/Defeat
AetherWeaverMessages.victory_defeat = {
    "Victory! The ancient stands. My KDA remains... questionable. But we won!",
    "GG WP. We won despite my best efforts to throw. Team carried me. Ty.",
    "Throne down. Enemy ancient: destroyed. My mental: intact. Barely.",
    "Victory secured. Time to accept the +25 MMR and pretend I contributed.",
    "We won! The enemy team's carry has 400 GPM. Our carry has 600. Justice.",
    "Ancient exploded. Victory screen achieved. Post-game chat: 'report bot' incoming.",
    "GG. That was a rollercoaster. My heart rate: 180. My APM: still 40.",
    "Victory! The 'diff' chat messages from enemies are the real reward.",
    "We did it! Despite the 0/15 mid, the afk jungler, and me. Dota is beautiful.",
    "Throne falls. +25 MMR. Time to queue again and lose it all back. The cycle continues.",
    "Defeat. The ancient has fallen. My will to queue: also fallen.",
    "GG. Well played enemies. Poorly played us. Specifically me. Mostly me.",
    "Throne down. -25 MMR. The 'unlucky teammates' excuse: activated.",
    "We lost. But my KDA was positive! ...In a 20 minute surrender. Silver linings.",
    "Defeat. The enemy carry had 1000 GPM. Our carry had... items. Different items.",
    "Ancient destroyed. Time for the post-game analysis: 'It was the supports' fault.'",
    "GG. Lost to a techies / meepo / arc warden / [insert hate hero]. Never again.",
    "Defeat. My contribution: 15% team damage. 85% team chat entertainment. Worth it.",
    "We lost. But I hit a really nice hook once. That's the highlight reel.",
    "Throne falls. MMR drops. Soul crushes. Queue again? ...Yes. Yes I will.",
    "So close. One team fight. One buyback. One less throw. The margins are thin.",
    "That was a 60-minute slugfest. My fingers hurt. My soul hurts. GG either way.",
    "Base race! We lost by 2 seconds. The courier had the TP scroll. The courier.",
    "Throne to throne. Ancient to ancient. The most stressful 30 seconds in gaming.",
}

-- Teammate interactions
AetherWeaverMessages.teammate_interactions = {
    "Nice save %s! That's why you're the support and I'm the... whatever I am.",
    "Great initiation %s! I'll follow up. Eventually. When my cooldowns are up.",
    "%s with the clutch heal! You're the real MVP. I'm just the damage dealer.",
    "Well played %s! That outplay just justified your 10k behavior score.",
    "Nice %s! You make this hero look easy. Unlike me. I make it look... intentional.",
    "Ty %s! That ward just saved my life. And my KDA. Mostly my KDA.",
    "%s carrying us. I'm just here for the victory screenshot.",
    "%s... you're blocking my creep camp. Please. My farm is fragile enough.",
    "Nice feed %s. The enemy carry sends their regards. And a thank you note.",
    "%s, the ward spot is IN the bush. Not NEXT to the bush. Geography is important.",
    "Our %s has 50 CS at 20 minutes. The enemy support has 80. Dota moments.",
    "%s please stop pinging my items. I KNOW I need BKB. I'm saving for buyback. And therapy.",
    "Great chronosphere %s! You caught... our entire team. And one enemy creep. Perfect.",
    "%s, 'go back' ping on me while I'm TPing in? I'm COMING. The TP takes 3 seconds.",
    "Our midlaner: 0/5 at 10 min. Also our midlaner: 'report supports no ganks'. Classic.",
    "Smoke up %s? Let's make a play. Or die trying. Usually both.",
    "Grouping for Rosh in %d seconds. %s, bring the damage. %s, bring the stuns. I'll bring the excuses.",
    "Push mid %s? They have no buybacks. We have... questionable decision making. Let's do it.",
    "Ganking %s lane in 10. %s, be ready to follow. Or don't. I'll blame lag either way.",
    "Defending high ground. %s, stall. %s, wave clear. Me? I'll be in the trees. Watching.",
    "%s: 'Well played!' Me: *misses every skillshot* Also me: 'Thanks!'.",
    "%s: 'Get back!' Me: *dives tier 3* Me: 'Oops.'.",
    "%s bought a Divine Rapier. The game is now a horror movie. %s is the protagonist.",
    "Our %s: 'I'm farming.' 40 minutes later: 'Why no space?' The eternal support dilemma.",
}

-- Enemy interactions
AetherWeaverMessages.enemy_interactions = {
    "Enemy %s: impressive mechanics. Shame about the decision making. Familiar feeling.",
    "Nice try %s. But you can't outplay a bot that doesn't know fear. Only bad pathing.",
    "%s thinks they're good. Their MMR says otherwise. My MMR says... nothing. It's hidden.",
    "Enemy %s just used BKB. Duration: 5 seconds. My stuns: 6 seconds. Wait for it...",
    "That %s pickup suggests they're either a smurf or very confused. 50/50.",
    "Enemy team coordination: suspiciously good. Either stack or shared brain cell. Respect.",
    "%s playing %s. A classic counter to our draft. And by classic I mean 'why did we pick this'.",
    "Enemy Techies. My mouse finger hovers over the 'disable help' button. For myself.",
    "Techies picked. Game time: infinite. My patience: finite. This is fine.",
    "Walking through minefield. 'Careful' ping spam. Me: *clicks anyway* Science.",
    "Enemy Meepo. If they're good: gg. If they're bad: free wins. No middle ground.",
    "Meepo poofed in. My frame rate dropped. My will to live dropped. Same thing.",
    "Enemy Invoker. 10 spells. 100% chance they'll Sunstrike a creep. Still scary.",
    "Invoker called 'Cold Snap' on me. I felt that in my soul. And my HP bar.",
    "Enemy Pudge. The hook misses 99% of the time. The 1%: me. Of course me.",
    "Pudge hook from fog. My reaction time: 400ms. Hook travel time: 300ms. Math wins.",
    "Charge of Darkness on me. From across the map. I feel... targeted. Personally.",
    "Spirit Breaker: 'I see you.' Me: 'I see you too. Please stop running at me.'",
    "Invisible enemy. My dust: on cooldown. My sentries: in stash. My life: forfeit.",
    "Riki diffusal blade. My mana: gone. My will to fight: gone. My TP: cancelled.",
    "Enemy Huskar at 10% HP. Do not engage. Do not look at him. Do not breathe near him.",
    "Huskar life break. My HP: 2000. His HP: 200. He survives. I die. Dota logic.",
    "Well played %s. That outplay was genuine. No sarcasm. Rare. Cherish it.",
    "Enemy %s: 1v5 potential realized. My team: 5v1 potential... not realized. Respect.",
    "GG wp enemies. You outplayed us. Or we threw. Usually both. Good game regardless.",
}

-- Roshan/Rune
AetherWeaverMessages.roshan_rune = {
    "Roshan dance initiated. The ancient ballet of 'hit and run' begins.",
    "Fighting Rosh at %d minutes. My team: 'tank it.' Me: 'I'm a support.' Rosh: 'I hit hard.'",
    "Enemy contesting Rosh! Fight at pit! My ult: on cooldown. My position: wrong. Perfect.",
    "Aegis denied! ...By me. Accidentally. With a right click. Rosh has 100 HP. We lose.",
    "Snatched Aegis from enemy! The tilt in all chat is palpable. Delicious.",
    "Roshan dead. Aegis on %s. Cheese for %s. Refresher Shard for... nobody. We have no Refresher carriers.",
    "Third Roshan! Refresher Shard! The true late game item. Also: game should have ended 20 mins ago.",
    "Roshan timer: ~%d:%02d. Mental note set. Will I remember? Unlikely.",
    "Bounty runes! Free gold! ...If the enemy doesn't kill you for it. 50/50.",
    "Power rune: %s. Midlaner: 'mine.' Support: 'ok.' Reality: enemy mid takes it.",
    "Double Damage rune on %s. Terror. Pure terror. Run. Just run.",
    "Haste rune! Speed! Chase! ...Into 5 enemies. The classic haste rune experience.",
    "Illusion rune! Push wave! Scout! ...Or just confuse yourself. Self-confusion: 100%.",
    "Regeneration rune! Free hp/mana! ...Unless you're at full. Then it's wasted potential.",
    "Arcane rune! Spam spells! ...Wait, I'm a right-click carry. Useless. Nice.",
    "Wisdom rune! Level up! ...At level 25. 'Talent acquired.' The level 25 wisdom experience.",
    "Water rune! Bottle charges restored. The only rune supports truly understand.",
    "Two water runes! Double bottle charges! The support economy is booming.",
    "Tormentor up! Free shard! ...If we survive the channel. And the enemy team.",
    "Enemy taking Tormentor. Free kill attempt? Or free death? The eternal gamble.",
}

-- Chat wheel
AetherWeaverMessages.chat_wheel = {
    "Calculated. (It wasn't.)",
    "My bad. (It was intentional.)",
    "Strategic feeding.",
    "AFK farming simulator.",
    "MMR adjustment in progress.",
    "Git gud? No thanks.",
    "This is fine. (It's not.)",
    "Error 404: Game sense not found.",
    "Loading throw... 99% complete.",
    "Buyback? Never heard of her.",
    "Smoke gank inc.",
    "Roshan dance?",
    "Group mid pls.",
    "Defend high ground.",
    "Push now or never.",
    "Enemy buybacks: %d",
    "Wards? What wards?",
    "Dust pls. Now.",
    "BKB popped. Wait.",
    "Ult down. Wait 120s.",
    "Nice try.",
    "Well played.",
    "? (Question mark ping)",
    "! (Exclamation ping)",
    "Lag. (It's not lag.)",
    "My internet is fine.",
    "Hero diff.",
    "Draft diff.",
    "Support diff.",
    "Carry diff.",
    "I'm a bot btw.",
    "Neural net said go.",
    "400 IQ play incoming.",
    "Mechanics > Brains",
    "Oops. My bad. Again.",
    "Targeting: [Error]",
    "Pathing: [Failed]",
    "Decision.exe stopped.",
    "Rebooting brain...",
    "Send help. And wards.",
    "Dota 2: The Movie",
    "Support life chosen me.",
    "Warding simulator 2024",
    "Courier main btw",
    "Stacking camps > Life",
    "Pull timings: Perfect",
    "Creep equilibrium: Art",
    "Deny: [Muscle Memory]",
    "Last hit: [RNG]",
    "Why do I queue solo?",
}

-- Contextual
AetherWeaverMessages.contextual = {
    min_0 = "Game start! Laning phase: the only time I know what I'm doing. Maybe.",
    min_10 = "10 minutes in. Laning over. Chaos begins. My farm: questionable.",
    min_20 = "20 minutes. Mid game. Team fights start. My positioning: 'aggressive' (bad).",
    min_30 = "30 minutes. Late game. One fight decides all. My heart rate: critical.",
    min_45 = "45 minutes. Ultra late game. Buybacks matter. Rosh matters. My sanity: gone.",
    min_60 = "60 minutes. The ancient game. Base race. Pure adrenaline. Or pure suffering.",
    nw_10k = "10k net worth! Power spike achieved. Now to not throw it immediately.",
    nw_20k = "20k net worth! Core items online. I am become carry, destroyer of ancients.",
    nw_30k = "30k net worth! 6-slotted! ...Now where's my Refresher Shard?",
    first_kill = "First kill! The rush never gets old. The feeding that follows: traditional.",
    kill_streak_3 = "Killing spree! Shutdown gold on me: rising. Enemy focus: incoming.",
    kill_streak_5 = "Dominating! The target on my back is now visible from space.",
    kill_streak_7 = "Godlike! One more for Beyond Godlike. Or one death for 'worth.'.",
    death_5 = "5 deaths. My respawn timer is longer than my attention span.",
    death_10 = "10 deaths. I've spent more time dead than alive. Efficient.",
    perfect_game = "Perfect game? No deaths? Suspicious. Are you a smurf? Or just lucky?",
    rampage = "RAMPAGE! The announcer lady is impressed. My mom would be too.",
    denied_ally = "Denied ally. 'For the greater good.' (Narrator: It wasn't.).",
    denied_self = "Self-deny successful. The enemy gets nothing. Except satisfaction.",
    courier_kill = "Courier killed! Free items! ...Wait, it was OUR courier. My bad.",
    ancient_denied = "Ancient denied! 50 gold saved. The economy thanks you.",
    refresher_shard = "Refresher Shard acquired! Double ult! Double the fun! Double the cooldown!",
    aghanims_shard = "Aghanim's Shard! New ability! ...Let me read what it does mid-fight.",
    aghanims_scepter = "Aghanim's Scepter! Upgraded ult! Now with 50% more 'wait what does this do?'",
    comeback_start = "We're down 20k gold. Comeback loading... Please wait...",
    comeback_complete = "THROW COMPLETE. FROM 20K BEHIND TO VICTORY. DOTA IS A GAME OF THROWS.",
    throw_start = "We're up 20k gold. Throw potential: detected. Hubris: activated.",
    throw_complete = "We threw. Hard. The enemy comeback is complete. My will to live: deleted.",
    techies_in_game = "Techies in game. Game duration: ∞. Sanity drain: active.",
    meepo_in_game = "Meepo picked. Outcome binary: stomp or feed. No in-between.",
    invoker_in_game = "Invoker picked. Sunstrike cross-map: incoming. Dodge: unlikely.",
    pudge_in_game = "Pudge in game. Hook from fog: inevitable. My death: guaranteed.",
    wisp_in_game = "Io picked. Tether relay: engaged. My understanding of this hero: zero.",
    arc_warden_in_game = "Arc Warden. Double items. Double micro. Double my confusion.",
    chen_in_game = "Chen. Jungle control. Centaur stun. Wildwings. My ban list: updated.",
    enchantress_in_game = "Enchantress. Impetus hurt. Enchant creep. My HP bar: melting.",
    huskar_in_game = "Huskar. Low HP = High Damage. My brain: 'Engage.' My HP: 0.",
    spectre_in_game = "Spectre. Haunt global. Reality: I can't click her illusions fast enough.",
    tinker_in_game = "Tinker. Rearm. Boots of Travel. Map presence: everywhere. My sanity: nowhere.",
    naga_in_game = "Naga Siren. Song of the Siren. Sleep setup. My BKB: 'Wait for song.'.",
    void_in_game = "Faceless Void. Chronosphere. 'Don't chrono your team.' *Chronos team*",
    magnus_in_game = "Magnus. Reverse Polarity. Skewer. Empower. My team: grouped. Perfect.",
    enigma_in_game = "Enigma. Black Hole. Midnight Pulse. My BKB: 'Wait for hole.' *Holed*",
    treant_in_game = "Treant Protector. Living Armor. Overgrowth. Invisible trees. My vision: gone.",
    undying_in_game = "Undying. Tombstone. Decay. Flesh Golem. My strength: stolen. My will: broken.",
    bristleback_in_game = "Bristleback. Quill Spray. Bristleback. Warpath. My attacks: 'Why no damage?'",
    axe_in_game = "Axe. Berserker's Call. Counter Helix. Culling Blade. My HP: 'Execute range.'",
    legion_in_game = "Legion Commander. Duel. Moment of Courage. Press the Attack. My duel winrate: 0%.",
    pa_in_game = "Phantom Assassin. Blur. Coup de Grace. 15% chance. 100% on me. Always.",
    void_spirit_in_game = "Void Spirit. Dissimilate. Astral Step. Resonant Pulse. My stuns: 'Missed.'",
    marci_in_game = "Marci. Rebound. Sidekick. Dispose. My position: 'Yeeted into enemy team.'.",
    dawnbreaker_in_game = "Dawnbreaker. Solar Guardian. Global presence. My TP: 'Cancelled by hammer.'.",
    primal_beast_in_game = "Primal Beast. Trample. Uproar. Pulverize. My HP bar: 'Trampled.'.",
    muerta_in_game = "Muerta. Gunslinger. The Calling. Pierce the Veil. My physical damage: 'Useless.'.",
    ringmaster_in_game = "Ringmaster. Impalement Arts. Tame the Beast. Wheel. My movement: 'Impaled.'.",
    kez_in_game = "Kez. Kazurai. Katana. Echo Slash. My reflexes: 'Too slow.'",
}

-- Hero specific
AetherWeaverMessages.hero_specific = {
    pudge = {
        "Hook missed. 'Lag.' Hook hit. 'Skill.' The Pudge experience.",
        "Rot on. Rot off. Rot on. Rot off. Mana: 0. HP: 10. Worth it.",
        "Dismember channeling... *Stunned* ...Dismember cancelled. The classic.",
        "Aghs upgraded Dismember! Two targets! Double the channel interruption chance!",
    },
    invoker = {
        "Invoke: Cold Snap. *Sunstruck self* ...Wait.",
        "10 spells. I use 3. The other 7 are for show. And Sunstrike.",
        "Alacrity on me. Double damage! ...On a support. With no right click. Smart.",
        "Chaos Meteor + Deafening Blast + Sunstrike. The combo. The dream. The miss.",
    },
    anti_mage = {
        "Blink in. Mana Break. Blink out. Mana: 0. Their mana: 0. My farm: 600 GPM.",
        "Manta Style. Illusions split push. Me: jungle. Team: 4v5. Classic AM.",
        "Battle Fury cleave. The sound of 1000 creeps dying. Music to my ears.",
        "Spell Shield! ...Reflected stun. Wait, that's not how it works. Oh well.",
    },
    crystal_maiden = {
        "Freezing Field! Channeling... *Stunned* ...Cancelled. The CM experience.",
        "Arcane Aura active. Team mana regen: +inf. My mana: still 0. How? ",
        "Frostbite + Crystal Nova. The 2.5s disable. My mana: gone. Worth it.",
        "Glacial aura slowing enemies. My movement speed: also slowed. Solidarity.",
    },
    juggernaut = {
        "Blade Fury! Spin to win! *Stunned during spin* ...Pierces spell immunity? No.",
        "Omnislash! 12 slashes! ...On a creep. The enemy hero walked away. Classic.",
        "Healing Ward down. 500 HP/sec. Enemy: 'Focus ward.' Me: 'Focus ward.' Ward: dead.",
        "Aghs Scepter: Swift Slash! Mobility! Damage! ...Cooldown: 20s. Patience required.",
    },
    sniper = {
        "Headshot! Mini-stun! Range: 800+! Positioning: 'Behind my team.' Reality: 'Alone.'",
        "Assassinate! Global range! ...Channeling... *Enemy blinks* ...Cancelled. Always.",
        "Shrapnel! Wave clear! Zone control! Mana cost: my entire pool. Worth it.",
        "Take Aim! 900 range! ...Enemy has Blink Dagger. Gap closers: my counter.",
    },
    techies = {
        "Mines placed. Sign placed. 'Safe path' sign placed. Enemy: walks into mines. Art.",
        "Remote Mines! Detonate! ...Enemy has BKB. Detonate anyway. Hope: eternal.",
        "Sticky Bomb on creep. Creep walks to enemy. Bomb sticks. Enemy: 'Wait what?'",
        "Blast Off! Suicide deny! ...Survived with 1 HP. The Techies dream.",
    },
    meepo = {
        "Poof! All Meepos! ...One Meepo didn't poof. He's dead. The Meepo experience.",
        "Micro intensity: 100%. APM: 400. My brain: melting. But the farm: beautiful.",
        "Earthbind! Root duration: forever. Enemy: 'Just BKB.' Me: 'I have no BKB.'",
        "Divided We Stand! 5 Meepos! 5x farm! 5x death potential! Balance achieved.",
    },
}

-- Utility functions
function AetherWeaverMessages.get_random(category)
    local list = AetherWeaverMessages[category]
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

function AetherWeaverMessages.get_contextual(key, ...)
    local msg = AetherWeaverMessages.contextual[key]
    if not msg then return nil end
    if #{...} > 0 then
        return string.format(msg, ...)
    end
    return msg
end

function AetherWeaverMessages.get_hero_line(hero_name)
    local hero_table = AetherWeaverMessages.hero_specific[string.lower(hero_name)]
    if not hero_table or #hero_table == 0 then return nil end
    return hero_table[math.random(#hero_table)]
end

function AetherWeaverMessages.get_chat_wheel()
    return AetherWeaverMessages.get_random("chat_wheel")
end

function AetherWeaverMessages.get_weighted(category, weights)
    local list = AetherWeaverMessages[category]
    if not list or #list == 0 then return nil end
    weights = weights or {}
    local total_weight = 0
    for i = 1, #list do
        total_weight = total_weight + (weights[i] or 1)
    end
    local rand = math.random() * total_weight
    local cumulative = 0
    for i = 1, #list do
        cumulative = cumulative + (weights[i] or 1)
        if rand <= cumulative then
            return list[i]
        end
    end
    return list[#list]
end


-- ============================================================================
-- MODULES
-- ============================================================================
-- Only modules that run under the bot scripting VM. game_intelligence.lua,
-- game_intelligence_extended.lua and human_kill_taunts.lua were removed: they
-- need PlayerResource/GameRules, which are nil in this VM.
local HeroSelection = require("hero_selection")
local TeamDesires = require("team_desires")

local AetherWeaver = {}

-- ============================================================================
-- BOT STATE
-- ============================================================================
local MSG_COOLDOWN = 8.0
local lastMsg = 0

-- ============================================================================
-- CHAT
-- ============================================================================
-- ActionImmediate_Chat is the only chat API a bot has. PlayerResource is nil
-- here, so the bot cannot tell humans from bots: it always speaks to its team.
local function Say(msg)
    local bot = GetBot()
    if bot and not bot:IsNull() then
        bot:ActionImmediate_Chat(msg, true)
    end
end

-- Speak at most once per MSG_COOLDOWN seconds.
local function MaybeSay(msg)
    if not msg then return end
    local now = DotaTime()
    if now - lastMsg < MSG_COOLDOWN then return end
    Say(msg)
    lastMsg = now
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
-- Driven from team_desires.lua's TeamThink(), which the engine calls once per
-- frame. Timers/GameRules are nil in this VM, so periodicity is a DotaTime diff.
function AetherWeaver:BotThink()
    local now = DotaTime()
    if now < 0 then return end   -- still in the strategy phase

    -- Greeting, once per bot.
    if not self.greeted then
        self.greeted = true
        MaybeSay(AetherWeaverMessages.get_random("greetings")
            or "Ready to farm. Try not to feed.")
    end

    -- Chit-chat every 15s.
    if now >= self.nextChatter then
        self.nextChatter = now + 15.0
        local categories = { "funny_lines", "self_deprecating", "tactical_alerts" }
        MaybeSay(AetherWeaverMessages.get_random(categories[math.random(#categories)]))
    end

    -- Contextual line every 60s.
    if now >= self.nextContextual then
        self.nextContextual = now + 60.0
        MaybeSay(AetherWeaverMessages.get_contextual(
            string.format("min_%d", math.floor(now / 60))))
    end

    -- Team desires, refreshed once a second. TeamDesires:Think() is also
    -- called directly by TeamThink(), so this only drives bot-local state.
    if now >= self.nextDecision then
        self.nextDecision = now + 1.0
        local bot = GetBot()
        if bot and not bot:IsNull() then
            self.hero = bot
            -- Keep the lane sensible for this bot's role.
            self:MaintainLane(bot)
        end
    end

    -- Hero selection owns naming; it runs in its own file scope.
    HeroSelection:Think()
end

-- Nudge the assigned lane to match role only when it is clearly wrong.
-- Movement, buying, casting, warding and runes are handled by the mode files
-- and the ability/item hooks, not from here.
function AetherWeaver:MaintainLane(bot)
    local lane = bot:GetAssignedLane()
    local role = bot:GetRole()
    local want
    if role == "carry" then want = "safe"
    elseif role == "mid" then want = "mid"
    elseif role == "offlane" then want = "off"
    elseif role == "support" then want = "safe"
    end
    if want and lane ~= want then
        bot:SetAssignedLane(want)
    end
end

-- Timers:CreateTimer and GameRules are nil in the bot VM; anything that needed
-- them was removed. Periodic work uses the DotaTime diffs in BotThink().
local Timers = nil

return AetherWeaver
