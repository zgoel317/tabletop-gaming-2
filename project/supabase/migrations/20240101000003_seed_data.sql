-- ============================================================
-- SEED DATA: Sample games for development/testing
-- ============================================================

-- Insert some popular board games for testing
INSERT INTO games (id, bgg_id, name, description, year_published, min_players, max_players, min_playtime, max_playtime, min_age, complexity_rating, average_rating, genres, categories, mechanics, designers)
VALUES
  (
    uuid_generate_v4(),
    174430,
    'Gloomhaven',
    'Gloomhaven is a game of Euro-inspired tactical combat in a persistent world of shifting motives. Players take on the role of a wandering adventurer with their own special set of skills and their own reasons for traveling to this dark corner of the world.',
    2017,
    1, 4, 60, 150, 14,
    3.86, 8.78,
    ARRAY['dungeon_crawl', 'cooperative']::game_genre[],
    ARRAY['Adventure', 'Exploration', 'Fantasy', 'Fighting', 'Miniatures'],
    ARRAY['Card Drafting', 'Hand Management', 'Modular Board', 'Simultaneous Action Selection', 'Variable Player Powers'],
    ARRAY['Isaac Childres']
  ),
  (
    uuid_generate_v4(),
    224517,
    'Brass: Birmingham',
    'Brass: Birmingham is an economic strategy game sequel to Martin Wallace''s 2007 masterpiece, Brass. Birmingham tells the story of competing entrepreneurs in Birmingham during the Industrial Revolution.',
    2018,
    2, 4, 60, 120, 14,
    3.91, 8.66,
    ARRAY['strategy', 'euro_game', 'engine_building']::game_genre[],
    ARRAY['Economic', 'Industry / Manufacturing', 'Trains'],
    ARRAY['Hand Management', 'Network and Route Building', 'Set Collection'],
    ARRAY['Gavan Brown', 'Matt Tolman', 'Martin Wallace']
  ),
  (
    uuid_generate_v4(),
    316554,
    'Pandemic Legacy: Season 0',
    'It''s 1962, and you are CIA operatives working under the guise of medical personnel to stop the spread of the Soviet biological weapon program and prevent the onset of the Cold War going hot.',
    2020,
    2, 4, 60, 75, 14,
    3.53, 8.53,
    ARRAY['cooperative', 'legacy', 'strategy']::game_genre[],
    ARRAY['Medical', 'Puzzle'],
    ARRAY['Action Points', 'Cooperative Game', 'Hand Management', 'Point to Point Movement', 'Variable Player Powers'],
    ARRAY['Rob Daviau', 'Matt Leacock']
  ),
  (
    uuid_generate_v4(),
    233078,
    'Spirit Island',
    'Spirit Island is a complex and thematic cooperative game about defending your island home from colonizing Invaders. Players are different spirits of the land.',
    2017,
    1, 4, 90, 120, 13,
    3.89, 8.52,
    ARRAY['cooperative', 'strategy', 'area_control']::game_genre[],
    ARRAY['Fantasy', 'Fighting', 'Territory Building'],
    ARRAY['Cooperative Game', 'Hand Management', 'Modular Board', 'Variable Player Powers'],
    ARRAY['R. Eric Reuss']
  ),
  (
    uuid_generate_v4(),
    167791,
    'Terraforming Mars',
    'In the 2400s, mankind begins to terraform the planet Mars. Giant corporations, sponsored by the World Government on Earth, initiate huge projects to raise the temperature, the oxygen level, and the ocean coverage.',
    2016,
    1, 5, 120, 150, 12,
    3.26, 8.43,
    ARRAY['strategy', 'engine_building', 'euro_game']::game_genre[],
    ARRAY['Economic', 'Environmental', 'Science Fiction', 'Space Exploration', 'Territory Building'],
    ARRAY['Card Drafting', 'Hand Management', 'Set Collection', 'Tile Placement', 'Variable Player Powers'],
    ARRAY['Jacob Fryxelius']
  ),
  (
    uuid_generate_v4(),
    115746,
    'Tzolk''in: The Mayan Calendar',
    'Tzolk''in: The Mayan Calendar presents a new game mechanism: dynamic worker placement. Players representing different Mayan tribes place their workers on giant connected gears.',
    2012,
    2, 4, 90, 90, 13,
    3.72, 8.07,
    ARRAY['strategy', 'worker_placement', 'euro_game']::game_genre[],
    ARRAY['Ancient', 'Economic', 'Religious'],
    ARRAY['Worker Placement', 'Variable Player Powers'],
    ARRAY['Simone Luciani', 'Daniele Tascini']
  ),
  (
    uuid_generate_v4(),
    161936,
    'Pandemic Legacy: Season 1',
    'Pandemic Legacy is a co-operative campaign game, with an overarching story-arc played through 12-24 sessions, depending on how well the players master the game.',
    2015,
    2, 4, 60, 75, 13,
    2.83, 8.62,
    ARRAY['cooperative', 'legacy', 'strategy']::game_genre[],
    ARRAY['Medical'],
    ARRAY['Action Points', 'Cooperative Game', 'Hand Management', 'Point to Point Movement', 'Variable Player Powers'],
    ARRAY['Rob Daviau', 'Matt Leacock']
  ),
  (
    uuid_generate_v4(),
    220308,
    'Gaia Project',
    'Gaia Project is a new game in the line of Terra Mystica. As in the original Terra Mystica, fourteen different factions live on seven different kinds of planets.',
    2017,
    1, 4, 60, 150, 12,
    4.28, 8.50,
    ARRAY['strategy', 'euro_game', 'engine_building', 'area_control']::game_genre[],
    ARRAY['Economic', 'Science Fiction', 'Space Exploration', 'Territory Building'],
    ARRAY['Tile Placement', 'Variable Player Powers', 'Worker Placement'],
    ARRAY['Jens Drögemüller', 'Helge Ostertag']
  ),
  (
    uuid_generate_v4(),
    342942,
    'Ark Nova',
    'In Ark Nova, you will plan and design a modern, scientifically managed zoo. With the ultimate goal of owning the most successful zoological establishment.',
    2021,
    1, 4, 90, 150, 14,
    3.72, 8.63,
    ARRAY['strategy', 'euro_game', 'engine_building']::game_genre[],
    ARRAY['Animals', 'Economic', 'Environmental'],
    ARRAY['Card Drafting', 'Hand Management', 'Set Collection', 'Variable Player Powers'],
    ARRAY['Mathias Wigge']
  ),
  (
    uuid_generate_v4(),
    193738,
    'Great Western Trail',
    'America in the 19th century: You are a rancher and repeatedly herd your cattle from Texas to Kansas City, where they are then shipped by train. Each time you herd, you improve your ranch.',
    2016,
    2, 4, 75, 150, 12,
    3.70, 8.27,
    ARRAY['strategy', 'euro_game', 'engine_building', 'worker_placement']::game_genre[],
    ARRAY['American West', 'Animals', 'Economic', 'Transportation'],
    ARRAY['Deck Building', 'Hand Management', 'Network and Route Building', 'Variable Player Powers', 'Worker Placement'],
    ARRAY['Alexander Pfister']
  ),
  -- Party/Social games
  (
    uuid_generate_v4(),
    172308,
    'Codenames',
    'Two rival spymasters know the secret identities of 25 agents. Their teammates know the agents only by their codenames. The teams compete to see who can make contact with all of their agents first.',
    2015,
    2, 8, 15, 30, 10,
    1.25, 7.65,
    ARRAY['party', 'social_deduction', 'competitive']::game_genre[],
    ARRAY['Card Game', 'Deduction', 'Party Game', 'Spies/Secret Agents', 'Word Game'],
    ARRAY['Team-Based Game', 'Voting'],
    ARRAY['Vlaada Chvátil']
  ),
  (
    uuid_generate_v4(),
    254640,
    'Just One',
    'Just One is a cooperative party game in which you play together to discover as many mystery words as possible. Find the best clue to help your teammate. But each identical clue will be cancelled.',
    2018,
    3, 7, 20, 20, 8,
    1.07, 7.67,
    ARRAY['party', 'cooperative']::game_genre[],
    ARRAY['Card Game', 'Party Game', 'Word Game'],
    ARRAY['Cooperative Game', 'Voting'],
    ARRAY['Ludovic Roudy', 'Bruno Sautter']
  ),
  -- Family games
  (
    uuid_generate_v4(),
    68448,
    'Seven Wonders',
    'You are the leader of one of the 7 great cities of the Ancient World. Gather resources, develop commercial routes, and affirm your military supremacy. Build your city and erect an architectural wonder which will transcend future times.',
    2010,
    2, 7, 30, 45, 10,
    2.33, 7.72,
    ARRAY['strategy', 'competitive']::game_genre[],
    ARRAY['Ancient', 'Card Game', 'City Building', 'Civilization', 'Economic'],
    ARRAY['Card Drafting', 'Hand Management', 'Set Collection', 'Simultaneous Action Selection'],
    ARRAY['Antoine Bauza']
  ),
  (
    uuid_generate_v4(),
    9209,
    'Ticket to Ride',
    'With elegantly simple gameplay, Ticket to Ride can be learned in under 15 minutes, while providing enough strategy and tension to engage players for years.',
    2004,
    2, 5, 45, 75, 8,
    1.86, 7.41,
    ARRAY['family', 'strategy', 'competitive']::game_genre[],
    ARRAY['Trains', 'Transportation'],
    ARRAY['Card Drafting', 'Hand Management', 'Network and Route Building', 'Set Collection'],
    ARRAY['Alan R. Moon']
  ),
  (
    uuid_generate_v4(),
    13,
    'Catan',
    'In CATAN (formerly The Settlers of Catan), players try to be the dominant force on the island of Catan by building settlements, cities, and roads.',
    1995,
    3, 4, 60, 120, 10,
    2.33, 7.15,
    ARRAY['family', 'strategy', 'competitive']::game_genre[],
    ARRAY['Civilization', 'Economic', 'Negotiation'],
    ARRAY['Dice Rolling', 'Hand Management', 'Network and Route Building', 'Trading', 'Variable Setup'],
    ARRAY['Klaus Teuber']
  )
ON CONFLICT (bgg_id) DO NOTHING;
