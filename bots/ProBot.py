from base_bot import BaseBot

class ProBot(BaseBot):
    def initialize(self, world):
        print('[ProBot] Initializing')
        self.world = world
        self.hero = None
        self.tick = 0

    def get_party(self):
        # Return party composition for pick/ban
        return [{'hero_id': 1, 'team_id': self.world.GetTeam()}]

    def actions(self, hero, game_ticks):
        self.tick += 1
        if not self.hero:
            self.hero = hero
            print(f'[ProBot] Got hero: {hero.GetUnitName()}')
        # Simple behavior: move to lane, last hit, use abilities, chat
        # For demo, just print tick and send a chat message every 300 ticks (~100s)
        if self.tick % 300 == 0:
            self.world.Say('GL HF! Let\'s win this!', self.hero.GetPlayerID())
        # Placeholder for actual logic
        return []