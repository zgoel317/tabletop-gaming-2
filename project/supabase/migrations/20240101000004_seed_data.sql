-- ============================================================
-- SEED DATA: Sample Games
-- ============================================================
-- A small set of well-known titles for development/testing.
-- Production data should be populated via the BGG API sync.

INSERT INTO public.games (
  bgg_id, name, description,
  min_players, max_players,
  min_playtime, max_playtime,
  min_age, complexity_rating, bgg_rating,
  year_published, genres, categories, mechanics, designers, publishers
) VALUES
(
  174430,
  'Gloomhaven',
  'Gloomhaven is a game of Euro-inspired tactical combat in a persistent world of shifting motives.',
  1, 4, 60, 120, 14, 3.86, 8.78,
  2017,
  ARRAY['strategy','cooperative','thematic']::game_genre[],
  ARRAY['Adventure','Exploration','Fantasy','Fighting','Miniatures'],
  ARRAY['Action Queue','Campaign / Battle Card Driven','Cooperative Game','Grid Movement','Hand Management'],
  ARRAY['Isaac Childres'],
  ARRAY['Cephalofair Games']
),
(
  167791,
  'Terraforming Mars',
  'Compete with rival corporations to terraform Mars by raising the temperature, oxygen level, and ocean coverage.',
  1, 5, 120, 120, 12, 3.24, 8.43,
  2016,
  ARRAY['strategy','euro']::game_genre[],
  ARRAY['Economic','Environmental','Science Fiction','Territory Building'],
  ARRAY['Card Drafting','Hand Management','Tile Placement','Variable Player Powers'],
  ARRAY['Jacob Fryxelius'],
  ARRAY['FryxGames', 'Stronghold Games']
),
(
  169786,
  'Scythe',
  'It is a time of unrest in 1920s Europa. The ashes from the first great war still darken the snow.',
  1, 5, 90, 115, 14, 3.44, 8.24,
  2016,
  ARRAY['strategy','euro','area_control']::game_genre[],
  ARRAY['Economic','Fighting','Science Fiction','Territory Building'],
  ARRAY['Area Majority / Influence','Engine Building','Resource Management','Variable Player Powers'],
  ARRAY['Jamey Stegmaier'],
  ARRAY['Stonemaier Games']
),
(
  182028,
  'Through the Ages: A New Story of Civilization',
  'Build your civilization through the ages—from ancient history to the modern era.',
  2, 4, 120, 240, 14, 4.43, 8.37,
  2015,
  ARRAY['strategy','euro']::game_genre[],
  ARRAY['Civilization','Economic'],
  ARRAY['Card Drafting','Hand Management','Variable Player Powers','Worker Placement'],
  ARRAY['Vlaada Chvátil'],
  ARRAY['Czech Games Edition']
),
(
  161936,
  'Pandemic Legacy: Season 1',
  'A cooperative legacy game where players work together to stop four diseases from spreading across the globe.',
  2, 4, 60, 75, 13, 2.83, 8.62,
  2015,
  ARRAY['cooperative','legacy','strategy']::game_genre[],
  ARRAY['Medical'],
  ARRAY['Cooperative Game','Hand Management','Point to Point Movement','Variable Player Powers'],
  ARRAY['Rob Daviau','Matt Leacock'],
  ARRAY['Z-Man Games']
),
(
  266192,
  'Wingspan',
  'Attract birds to your wildlife preserve. Each bird extends a powerful chain of combinations in one of your habitats.',
  1, 5, 40, 70, 10, 2.44, 8.07,
  2019,
  ARRAY['euro','strategy']::game_genre[],
  ARRAY['Animals','Educational','Nature'],
  ARRAY['Card Drafting','Engine Building','Hand Management','Set Collection'],
  ARRAY['Elizabeth Hargrave'],
  ARRAY['Stonemaier Games']
),
(
  312484,
  'Lost Ruins of Arnak',
  'Explore uncharted island, discover lost ruins, and uncover the island''s secrets in this deck-building adventure.',
  1, 4, 30, 120, 12, 2.91, 8.08,
  2020,
  ARRAY['euro','deck_building','worker_placement']::game_genre[],
  ARRAY['Adventure','Exploration','Fantasy'],
  ARRAY['Deck Construction','Hand Management','Worker Placement'],
  ARRAY['Mín Lukáš','Pevná Elwen'],
  ARRAY['Czech Games Edition']
),
(
  220308,
  'Gaia Project',
  'A new generation of the celebrated Terra Mystica. Fourteen factions live on seven different planet types.',
  1, 4, 60, 150, 14, 4.52, 8.46,
  2017,
  ARRAY['strategy','euro']::game_genre[],
  ARRAY['Economic','Science Fiction','Territory Building'],
  ARRAY['Area Majority / Influence','Engine Building','Hexagon Grid','Variable Player Powers'],
  ARRAY['Jens Drögemüller','Helge Ostertag'],
  ARRAY['Z-Man Games']
),
(
  316554,
  'Dune: Imperium',
  'Dune: Imperium uses deck-building to add a hidden-information angle to worker placement.',
  1, 4, 60, 120, 14, 3.01, 8.47,
  2020,
  ARRAY['strategy','deck_building','worker_placement']::game_genre[],
  ARRAY['Economic','Fighting','Science Fiction'],
  ARRAY['Deck Construction','Hand Management','Worker Placement'],
  ARRAY['Paul Dennen'],
  ARRAY['Dire Wolf']
),
(
  233078,
  'Twilight Imperium: Fourth Edition',
  'An epic game of galactic conquest in which three to six players fight for the throne of the galaxy.',
  3, 6, 240, 480, 14, 4.28, 8.67,
  2017,
  ARRAY['strategy','area_control','wargame']::game_genre[],
  ARRAY['Negotiation','Political','Science Fiction','Space Exploration','Territory Building'],
  ARRAY['Area Majority / Influence','Diplomacy','Hand Management','Variable Player Powers'],
  ARRAY['Corey Konieczka'],
  ARRAY['Fantasy Flight Games']
),
(
  36218,
  'Dominion',
  'The first modern deck-building game. You are a monarch trying to build the most prosperous kingdom.',
  2, 4, 30, 30, 13, 2.38, 7.60,
  2008,
  ARRAY['deck_building','euro']::game_genre[],
  ARRAY['Card Game','Medieval'],
  ARRAY['Deck Construction','Hand Management'],
  ARRAY['Donald X. Vaccarino'],
  ARRAY['Rio Grande Games']
),
(
  30549,
  'Pandemic',
  'Four diseases threaten the world. Your team of specialists must prevent them from spreading.',
  2, 4, 45, 45, 8, 2.40, 7.59,
  2008,
  ARRAY['cooperative','strategy']::game_genre[],
  ARRAY['Medical'],
  ARRAY['Cooperative Game','Hand Management','Point to Point Movement','Role Playing','Trading'],
  ARRAY['Matt Leacock'],
  ARRAY['Z-Man Games']
),
(
  131357,
  'Coup',
  'In Coup, you must bluff, bribe, and manipulate your way to dominance over a dystopian government.',
  2, 6, 15, 15, 10, 1.43, 7.34,
  2012,
  ARRAY['social_deduction','party']::game_genre[],
  ARRAY['Bluffing','Card Game'],
  ARRAY['Bluffing','Player Elimination'],
  ARRAY['Rikki Tahta'],
  ARRAY['Indie Boards and Cards']
),
(
  9209,
  'Ticket to Ride',
  'Collect and play matching train cards to claim railway routes connecting cities across North America.',
  2, 5, 30, 90, 8, 1.85, 7.41,
  2004,
  ARRAY['strategy','euro']::game_genre[],
  ARRAY['Trains','Transportation'],
  ARRAY['Card Drafting','Hand Management','Route/Network Building','Set Collection'],
  ARRAY['Alan R. Moon'],
  ARRAY['Days of Wonder']
),
(
  68448,
  '7 Wonders',
  'Lead an ancient civilization and develop a city, guiding it over three ages of card drafting.',
  2, 7, 30, 30, 10, 2.33, 7.74,
  2010,
  ARRAY['euro','strategy']::game_genre[],
  ARRAY['Ancient','Card Game','City Building','Civilization'],
  ARRAY['Card Drafting','Hand Management','Set Collection','Simultaneous Action Selection'],
  ARRAY['Antoine Bauza'],
  ARRAY['Repos Production']
);
