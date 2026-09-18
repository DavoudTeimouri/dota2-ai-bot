-- AetherWeaver Dota 2 Bot - Main Entry Point
-- Workshop addon: vscripts/bots/init.lua

-- Module table
local AetherWeaver = {}

-- ============================================================================
-- LOAD MODULES
-- ============================================================================
local BotNames = require("bot_names")
local GameIntelligence = require("game_intelligence")
local GameIntelligenceExtended = require("game_intelligence_extended")
local ItemPurchase = require("item_purchase_generic")
local AbilityUsage = require("ability_item_usage_generic")
local Courier = require("courier_generic")
local Rune = require("rune_generic")
local SkillBuild = require("skill_build_generic")
local Patch741f = require("patch_741f")
local GuideIntegration = require("guide_integration")

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
    "%s: 'Well played!' Me: *misses every skillshot* Also me: 'Thanks!'",
    "%s: 'Get back!' Me: *dives tier 3* Me: 'Oops.'",
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
    kill_streak_7 = "Godlike! One more for Beyond Godlike. Or one death for 'worth.'",
    death_5 = "5 deaths. My respawn timer is longer than my attention span.",
    death_10 = "10 deaths. I've spent more time dead than alive. Efficient.",
    perfect_game = "Perfect game? No deaths? Suspicious. Are you a smurf? Or just lucky?",
    rampage = "RAMPAGE! The announcer lady is impressed. My mom would be too.",
    denied_ally = "Denied ally. 'For the greater good.' (Narrator: It wasn't.)",
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
    naga_in_game = "Naga Siren. Song of the Siren. Sleep setup. My BKB: 'Wait for song.'",
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
    marci_in_game = "Marci. Rebound. Sidekick. Dispose. My position: 'Yeeted into enemy team.'",
    dawnbreaker_in_game = "Dawnbreaker. Solar Guardian. Global presence. My TP: 'Cancelled by hammer.'",
    primal_beast_in_game = "Primal Beast. Trample. Uproar. Pulverize. My HP bar: 'Trampled.'",
    muerta_in_game = "Muerta. Gunslinger. The Calling. Pierce the Veil. My physical damage: 'Useless.'",
    ringmaster_in_game = "Ringmaster. Impalement Arts. Tame the Beast. Wheel. My movement: 'Impaled.'",
    kez_in_game = "Kez. Kazurai. Katana. Echo Slash. My reflexes: 'Too slow.'",
}

-- Hero specific
AetherWeaverMessages.hero_specific = {
    pudge = {
        "Hook missed. 'Lag.' Hook hit. 'Skill.' The Pudge experience.",
        "Rot on. Rot off. Rot on. Rot off. Mana: 0. HP: 10. Worth it.",
        "Dismember channeling... *stunned* ...Dismember cancelled. The classic.",
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
        "Arcane Aura active. Team mana regen: +inf. My mana: still 0. How?",
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
-- BOT STATE
-- ============================================================================
local MSG_COOLDOWN = 8.0
local lastMsg = 0
local lastLaneChange = 0
local missingEnemyTimer = {}

-- Helper: Send chat message
local function Say(msg, playerID)
    if not playerID then playerID = 0 end
    if GameRules.SendCustomMessage then
        GameRules:SendCustomMessage(msg, playerID, 0)
    end
end

-- Helper: Maybe send message with cooldown
local function MaybeSay(msg)
    local now = GameRules:GetGameTime()
    if now - lastMsg < MSG_COOLDOWN then return end
    Say(msg)
    lastMsg = now
end

-- Helper: Get human heroes and their roles
local function GetHumanRoles()
    local roles = {carry = false, mid = false, offlane = false, support = false}
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and not PlayerResource:IsFakeClient(i) then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                local name = hero:GetUnitName()
                if name:find("antimage") or name:find("juggernaut") or name:find("phantom_assassin") or name:find("spectre") or name:find("medusa") then
                    roles.carry = true
                elseif name:find("invoker") or name:find("storm") or name:find("templar") or name:find("puck") or name:find("ember") then
                    roles.mid = true
                elseif name:find("centaur") or name:find("tidehunter") or name:find("dragon_knight") or name:find("axe") or name:find("mars") then
                    roles.offlane = true
                else
                    roles.support = true
                end
            end
        end
    end
    return roles
end

-- Pick hero after human picks (using GameIntelligence)
local function PickHeroAfterHumans()
    local humanRoles = GetHumanRoles()
    local enemyPicks = {}
    local bannedHeroes = {}
    
    -- Collect enemy picks (simplified)
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= DOTA_TEAM_GOODGUYS then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                table.insert(enemyPicks, hero:GetUnitName())
            end
        end
    end
    
    local heroName = GameIntelligence.PickBan:GetBestPick(humanRoles, enemyPicks, bannedHeroes)
    Say("-pick " .. heroName)
    return heroName
end

-- Assign lane by hero
local function AssignLane(heroName)
    local laneMap = {
        npc_dota_hero_antimage = "safe", npc_dota_hero_juggernaut = "safe", npc_dota_hero_phantom_assassin = "safe", npc_dota_hero_spectre = "safe",
        npc_dota_hero_invoker = "mid", npc_dota_hero_storm_spirit = "mid", npc_dota_hero_templar_assassin = "mid", npc_dota_hero_puck = "mid",
        npc_dota_hero_centaur = "off", npc_dota_hero_tidehunter = "off", npc_dota_hero_dragon_knight = "off", npc_dota_hero_axe = "off",
        npc_dota_hero_crystal_maiden = "support", npc_dota_hero_lich = "support", npc_dota_hero_witch_doctor = "support", npc_dota_hero_shadow_shaman = "support"
    }
    return laneMap[heroName] or "safe"
end

-- Handle chat commands
local function HandleChat(text)
    if not text or text:sub(1,1) ~= "!" then return end
    local cmd = text:sub(2):lower()
    if cmd:find("^push%s+(%a+)") then
        local lane = cmd:match("^push%s+(%a+)")
        MaybeSay("Pushing " .. lane .. " lane!")
    elseif cmd == "roshan" then
        MaybeSay("Let's go Roshan!")
    elseif cmd:find("^ward") then
        MaybeSay("Warding suggested.")
    elseif cmd:find("^lane%s+(%a+)") then
        local lane = cmd:match("^lane%s+(%a+)")
        MaybeSay("Setting lane to " .. lane)
    else
        MaybeSay("Unknown command. Try !push <lane>, !roshan, !ward, !lane <lane>")
    end
end

-- Bot Think function (called every tick)
function AetherWeaver:BotThink()
    if not self.initialized then
        self.initialized = true
        print('[AetherWeaver] Initialized')
        
        -- Initialize missing enemy timers
        for i = 0, 9 do
            missingEnemyTimer[i] = 0
        end
        
        -- Listen for chat
        ListenToGameEvent("player_chat", function(keys)
            if keys.text then HandleChat(keys.text) end
        end, self)
        
        -- Pick hero after delay
        Timers:CreateTimer(2.0, function()
            local hero = PickHeroAfterHumans()
            local lane = AssignLane(hero)
            local msg = string.format(AetherWeaverMessages.get_random("greetings") or "I will play %s in the %s lane.", hero, lane)
            MaybeSay(msg)
        end)
        
        -- Periodic messages with variety
        Timers:CreateTimer(15.0, function()
            local categories = {"funny_lines", "self_deprecating", "tactical_alerts", "chat_wheel"}
            local cat = categories[math.random(#categories)]
            local msg = AetherWeaverMessages.get_random(cat)
            if msg then MaybeSay(msg) end
            return 15.0
        end)
        
        -- Contextual time-based messages
        Timers:CreateTimer(60.0, function()
            local gameTime = GameRules:GetGameTime()
            local mins = math.floor(gameTime / 60)
            local key = string.format("min_%d", mins)
            local msg = AetherWeaverMessages.get_contextual(key)
            if msg then MaybeSay(msg) end
            return 60.0
        end)
        
        -- Game intelligence: periodic decision making
        Timers:CreateTimer(1.0, function()
            if self.hero and not self.hero:IsNull() then
                self:MakeGameDecisions()
            end
            return 1.0
        end)
    end
end

-- Main decision making loop
function AetherWeaver:MakeGameDecisions()
    local bot = self.hero
    local gameTime = GameRules:GetGameTime()
    
    -- Initialize subsystems
    if not bot.initialized then
        bot.initialized = true
        
        -- Determine position/role
        bot.position = self:GetBotPosition(bot)
        bot.role = self:GetBotRole(bot)
        
        -- Load guide-based builds
        local heroName = bot:GetUnitName()
        local guideBuild = GuideIntegration:GetPatchAdjustedBuild(heroName, bot.position)
        local guideSkills = GuideIntegration:GetSkillBuild(heroName, bot.position)
        local patchAdj = Patch741f:GetHeroPlaystyleAdjustments(heroName)
        
        bot.guideItemBuild = guideBuild
        bot.guideSkillBuild = guideSkills
        bot.patchAdjustments = patchAdj
        
        -- Initialize subsystems with guide data
        ItemPurchase:Initialize(bot, guideBuild)
        AbilityUsage:Initialize(bot)
        SkillBuild:Initialize(bot, guideSkills)
        Courier:Think(bot)
    end
    
    -- Run subsystems
    ItemPurchase:Think(bot)
    AbilityUsage:Think(bot)
    SkillBuild:Think(bot)
    Courier:Think(bot)
    Rune:Think(bot)
    
    -- Update missing enemy timers
    self:UpdateMissingEnemyTimers(gameTime)
    
    -- Update lane assignment using extended priority
    local currentLane = bot:GetAssignedLane() or "safe"
    local newLane = self:GetBestLane(bot, gameTime)
    if newLane and newLane ~= currentLane then
        bot:SetAssignedLane(newLane)
        MaybeSay("Switching to " .. newLane .. " lane.")
    end
    
    -- Get farm target
    local farmTarget = GameIntelligence.Farming:GetBestFarmTarget(bot, gameTime)
    if farmTarget then
        bot:Action_AttackUnit(farmTarget, true)
    end
    
    -- Support actions
    if self:GetBotRole(bot) == "support" then
        local wardAction = GameIntelligence.Support:GetNextWardAction(bot, gameTime)
        if wardAction then
            MaybeSay("Placing ward at " .. wardAction.desc)
            -- Place ward logic here
        end
        
        local pullAction = GameIntelligence.Support:GetPullAction(bot, gameTime)
        if pullAction then
            MaybeSay("Pulling the wave!")
        end
        
        local stackAction = GameIntelligence.Support:GetStackAction(bot, gameTime)
        if stackAction then
            MaybeSay("Stacking camp!")
        end
        
        local smokeAction = GameIntelligence.Support:GetSmokeGankAction(bot, gameTime)
        if smokeAction then
            MaybeSay("Smoke ganking " .. smokeAction .. " lane!")
        end
        
        -- Share economy if ahead
        if GameIntelligenceExtended:ShouldShareEconomy(bot) then
            local shareItems = GameIntelligenceExtended:GetEconomyShareItems()
            MaybeSay("I'm ahead! Sharing: " .. table.concat(shareItems, ", "))
        end
    end
    
    -- Ganking
    if GameIntelligence.Ganking:ShouldGank(bot, gameTime) then
        local target = GameIntelligence.Ganking:GetGankTarget(bot)
        if target then
            MaybeSay("Ganking " .. target:GetUnitName() .. "!")
        end
    end
    
    -- Blink dodge skillshots
    self:TryBlinkDodge(bot)
    
    -- Pushing
    if GameIntelligence.Pushing:ShouldPush(bot, gameTime) then
        local pushLane = GameIntelligence.Pushing:GetPushLane(bot)
        if pushLane then
            MaybeSay("Pushing " .. pushLane .. " lane!")
        end
    end
    
    -- Team fight logic
    local enemies = bot:GetNearbyEnemyHeroes(1200)
    if #enemies > 0 then
        local target = GameIntelligence.TeamFight:FindBestTarget(bot, enemies)
        if target then
            local position = GameIntelligence.TeamFight:GetBestPosition(bot, target)
            bot:Action_MoveToLocation(position)
            
            local abilities = GameIntelligence.TeamFight:GetAbilityUsage(bot, target)
            for _, abil in ipairs(abilities) do
                if abil:IsFullyCastable() then
                    bot:Action_UseAbilityOnTarget(abil, target)
                    break
                end
            end
        end
    end
    
    -- Human guidance
    if math.random() < 0.001 then -- 0.1% chance per tick
        local situation = "early_game"
        if gameTime > 1800 then situation = "late_game"
        elseif gameTime > 600 then situation = "mid_game" end
        GameIntelligence.Guidance:SendTipToHumans(bot, situation)
    end
    
    -- Communicate missing enemies and assist requests
    self:CommunicateMissingAndAssist(bot, gameTime)
end

function AetherWeaver:GetBotRole(bot)
    local heroName = bot:GetUnitName()
    local carryHeroes = {"antimage", "juggernaut", "phantom_assassin", "spectre", "medusa", "drow_ranger", "luna", "faceless_void", "terrorblade", "morphling"}
    local midHeroes = {"invoker", "storm_spirit", "templar_assassin", "puck", "ember_spirit", "queenofpain", "shadow_fiend", "zeus", "tinker", "pugna"}
    local offlaneHeroes = {"centaur", "tidehunter", "dragon_knight", "axe", "mars", "underlord", "dark_seer", "bristleback", "timbersaw", "slardar"}
    
    for _, h in ipairs(carryHeroes) do if heroName:find(h) then return "carry" end end
    for _, h in ipairs(midHeroes) do if heroName:find(h) then return "mid" end end
    for _, h in ipairs(offlaneHeroes) do if heroName:find(h) then return "offlane" end end
    return "support"
end

-- Determine bot position (1-5) based on lane assignment and team slot
function AetherWeaver:GetBotPosition(bot)
    local lane = bot:GetAssignedLane() or "safe"
    local team = bot:GetTeam()
    local playerID = bot:GetPlayerID()
    
    -- In Dota 2, positions are typically assigned by player slot:
    -- Radiant: 0=Pos1, 1=Pos2, 2=Pos3, 3=Pos4, 4=Pos5
    -- Dire: 5=Pos1, 6=Pos2, 7=Pos3, 8=Pos4, 9=Pos5
    if team == DOTA_TEAM_GOODGUYS then
        if playerID == 0 then return 1
        elseif playerID == 1 then return 2
        elseif playerID == 2 then return 3
        elseif playerID == 3 then return 4
        elseif playerID == 4 then return 5 end
    else
        if playerID == 5 then return 1
        elseif playerID == 6 then return 2
        elseif playerID == 7 then return 3
        elseif playerID == 8 then return 4
        elseif playerID == 9 then return 5 end
    end
    
    -- Fallback: infer from lane
    if lane == "safe" then return 1
    elseif lane == "mid" then return 2
    elseif lane == "off" then return 3
    else return 4 end
end

-- Update missing enemy timers
function AetherWeaver:UpdateMissingEnemyTimers(gameTime)
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= self.hero:GetTeam() then
            local hero = PlayerResource:GetSelectedHeroEntity(i)
            if hero and not hero:IsNull() then
                if hero:IsAlive() and not hero:IsNull() and hero:GetHealth() > 0 then
                    missingEnemyTimer[i] = 0
                else
                    missingEnemyTimer[i] = missingEnemyTimer[i] + 1
                end
            else
                missingEnemyTimer[i] = missingEnemyTimer[i] + 1
            end
        else
            missingEnemyTimer[i] = 0
        end
    end
end

-- Get the best lane based on extended priority
function AetherWeaver:GetBestLane(bot, gameTime)
    local bestLane = bot:GetAssignedLane() or "safe"
    local bestScore = -1
    
    local lanes = {"safe", "mid", "off", "jungle"}
    for _, lane in ipairs(lanes) do
        local enemyInLane = self:GetPrimaryEnemyInLane(bot, lane)
        local score = GameIntelligenceExtended:GetLanePriority(bot, lane, enemyInLane)
        
        if not enemyInLane then
            score = score + 10
        end
        
        if score > bestScore then
            bestScore = score
            bestLane = lane
        end
    end
    
    return bestLane
end

-- Get the primary enemy hero in a lane (simplified)
function AetherWeaver:GetPrimaryEnemyInLane(bot, lane)
    -- Placeholder: would need to define lane boundaries and check enemy positions
    return nil
end

-- Try to blink dodge incoming projectiles
function AetherWeaver:TryBlinkDodge(bot)
    if not (bot:HasAbility("item_blink") or bot:HasAbility("antimage_blink")) then
        return
    end
    
    -- Check incoming projectiles
    local projectiles = {} -- bot:GetIncomingProjectiles() - not available
    -- For now, we do nothing
end

-- Communicate missing enemies and assist requests
function AetherWeaver:CommunicateMissingAndAssist(bot, gameTime)
    for i = 0, 9 do
        if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) ~= bot:GetTeam() then
            local missingTime = missingEnemyTimer[i]
            if missingTime > 30 then -- missing for 30 seconds
                local hero = PlayerResource:GetSelectedHeroEntity(i)
                if hero and not hero:IsNull() then
                    local heroName = hero:GetUnitName()
                    local msg = GameIntelligenceExtended:GetPingMessageForMissingEnemy(heroName)
                    MaybeSay(msg)
                    missingEnemyTimer[i] = 0
                end
            end
        end
    end
    
    if GameIntelligenceExtended:ShouldRequestAssist(bot, gameTime) then
        local msg = GameIntelligenceExtended:GetAssistRequestMessage()
        MaybeSay(msg)
    end
end

-- Entry point
function Activate()
    print('[AetherWeaver] Activating...')
    GameRules:GetGameModeEntity():SetThink("BotThink", AetherWeaver, 0.1)
end

-- Make sure Timers library is available
if not Timers then
    Timers = {}
    function Timers:CreateTimer(delay, callback)
        local thinkName = "AetherWeaverTimer" .. math.random(1000000)
        GameRules:GetGameModeEntity():SetThink(function()
            local result = callback()
            if result then return result end
            return nil
        end, thinkName, delay)
    end
end

return AetherWeaver