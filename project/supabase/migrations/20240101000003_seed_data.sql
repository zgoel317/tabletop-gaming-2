-- ============================================================
-- SEED DATA
-- Sample games for development and testing
-- ============================================================

-- Insert popular board games for development
INSERT INTO games (
  bgg_id, name, description, min_players, max_players,
  min_playtime_minutes, max_playtime_minutes, min_age,
  complexity_rating, bgg_rating, year_published,
  is_expansion, categories, mechanics, designers
) VALUES
(
  174430,
  'Gloomhaven',
  'A game of Euro-inspired tactical combat in a persistent world of shifting motives.',
  1, 4, 60, 120, 14, 3.86, 8.79, 2017, false,
  ARRAY['Adventure', 'Exploration', 'Fantasy', 'Fighting'],
  ARRAY['Campaign', 'Card Drafting', 'Hand Management', 'Modular Board'],
  ARRAY['Isaac Childres']
),
(
  167791,
  'Terraforming Mars',
  'Compete with rival CEOs to make Mars habitable and build your corporate empire.',
  1, 5, 120, 120, 12, 3.26, 8.43, 2016, false,
  ARRAY['Economic', 'Environmental', 'Science Fiction'],
  ARRAY['Card Drafting', 'Hand Management', 'Tile Placement', 'Variable Player Powers'],
  ARRAY['Jacob Fryxelius']
),
(
  161936,
  'Pandemic Legacy: Season 1',
  'A co-operative campaign game where your choices carry over from session to session.',
  2, 4, 60, 75, 13, 2.83, 8.62, 2015, false,
  ARRAY['Medical', 'Cooperative'],
  ARRAY['Co-operative Play', 'Hand Management', 'Point to Point Movement', 'Variable Player Powers'],
  ARRAY['Rob Daviau', 'Matt Leacock']
),
(
  68448,
  'Seven Wonders',
  'Draft cards to develop your ancient civilization and build a majestic wonder.',
  2, 7, 30, 30, 10, 2.33, 7.75, 2010, false,
  ARRAY['Ancient', 'Card Game', 'Civilization'],
  ARRAY['Card Drafting', 'Hand Management', 'Set Collection', 'Simultaneous Action Selection'],
  ARRAY['Antoine Bauza']
),
(
  224517,
  'Brass: Birmingham',
  'Build networks, grow industries, and traverse the canals and railways of the Industrial Revolution.',
  2, 4, 60, 120, 14, 3.91, 8.66, 2018, false,
  ARRAY['Economic', 'Industry / Manufacturing', 'Transportation'],
  ARRAY['Hand Management', 'Network and Route Building', 'Pick-up and Deliver'],
  ARRAY['Martin Wallace']
),
(
  36218,
  'Dominion',
  'You are a monarch building the greatest kingdom with the best deck of cards.',
  2, 4, 30, 30, 13, 2.35, 7.60, 2008, false,
  ARRAY['Card Game', 'Medieval'],
  ARRAY['Deck Building', 'Hand Management'],
  ARRAY['Donald X. Vaccarino']
),
(
  178900,
  'Codenames',
  'Two spymasters know the secret identities of 25 agents. Their teammates know the agents only by their codenames.',
  2, 8, 15, 15, 14, 1.26, 7.63, 2015, false,
  ARRAY['Card Game', 'Party Game', 'Spies / Secret Agents', 'Word Game'],
  ARRAY['Communication Limits', 'Square Grid', 'Team-Based Game', 'Voting'],
  ARRAY['Vlaada Chvátil']
),
(
  70323,
  'King of Tokyo',
  'Play as a mutant monster, rampaging robot, or alien life form trying to take over Tokyo.',
  2, 6, 30, 30, 8, 1.52, 7.20, 2011, false,
  ARRAY['Fighting', 'Monsters/Beasts', 'Science Fiction'],
  ARRAY['Dice Rolling', 'Player Elimination', 'Press Your Luck', 'Variable Player Powers'],
  ARRAY['Richard Garfield']
),
(
  31260,
  'Agricola',
  'Live the life of a farmer: grow crops, raise animals, and build your homestead.',
  1, 5, 30, 150, 12, 3.64, 7.99, 2007, false,
  ARRAY['Animals', 'Economic', 'Farming'],
  ARRAY['Hand Management', 'Worker Placement'],
  ARRAY['Uwe Rosenberg']
),
(
  120677,
  'Terra Mystica',
  'Faction-based strategic game where players terraform land to build their civilizations.',
  2, 5, 60, 150, 14, 3.95, 8.13, 2012, false,
  ARRAY['City Building', 'Economic', 'Fantasy', 'Civilization'],
  ARRAY['Area Majority / Influence', 'Income', 'Tile Placement', 'Worker Placement'],
  ARRAY['Jens Drögemüller', 'Helge Ostertag']
),
(
  342942,
  'Ark Nova',
  'Plan and design a modern, scientifically managed zoo.',
  1, 4, 90, 150, 14, 3.72, 8.60, 2021, false,
  ARRAY['Animals', 'Economic', 'Environmental'],
  ARRAY['Card Drafting', 'Hand Management', 'Set Collection', 'Tile Placement'],
  ARRAY['Mathias Wigge']
),
(
  266192,
  'Wingspan',
  'Attract birds to your wildlife preserves in this engine-building game.',
  1, 5, 40, 70, 10, 2.45, 8.08, 2019, false,
  ARRAY['Animals', 'Card Game', 'Environmental'],
  ARRAY['Card Drafting', 'Deck Building', 'Engine Building', 'Hand Management'],
  ARRAY['Elizabeth Hargrave']
),
(
  230802,
  'Azul',
  'Artisans have been tasked with decorating the walls of the royal palace of Evora.',
  2, 4, 30, 45, 8, 1.77, 7.80, 2017, false,
  ARRAY['Abstract Strategy', 'Puzzle'],
  ARRAY['Drafting', 'Pattern Building', 'Tile Placement'],
  ARRAY['Michael Kiesling']
),
(
  13,
  'Catan',
  'Negotiate, trade, and build your way to dominance on the island of Catan.',
  3, 4, 60, 120, 10, 2.33, 7.15, 1995, false,
  ARRAY['City Building', 'Economic', 'Negotiation'],
  ARRAY['Dice Rolling', 'Modular Board', 'Network and Route Building', 'Trading'],
  ARRAY['Klaus Teuber']
),
(
  9209,
  'Ticket to Ride',
  'Build your railroad empire across America by claiming railway routes between cities.',
  2, 5, 30, 75, 8, 1.86, 7.41, 2004, false,
  ARRAY['Trains'],
  ARRAY['Card Drafting', 'Hand Management', 'Network and Route Building', 'Set Collection'],
  ARRAY['Alan R. Moon']
)
ON CONFLICT (bgg_id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  min_players = EXCLUDED.min_players,
  max_players = EXCLUDED.max_players,
  min_playtime_minutes = EXCLUDED.min_playtime_minutes,
  max_playtime_minutes = EXCLUDED.max_playtime_minutes,
  min_age = EXCLUDED.min_age,
  complexity_rating = EXCLUDED.complexity_rating,
  bgg_rating = EXCLUDED.bgg_rating,
  year_published = EXCLUDED.year_published,
  categories = EXCLUDED.categories,
  mechanics = EXCLUDED.mechanics,
  designers = EXCLUDED.designers,
  updated_at = NOW();
