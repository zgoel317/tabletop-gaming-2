-- ============================================================
-- Migration: 00005_seed_data.sql
-- Description: Seed data for development and testing.
--              Includes sample games and game genres.
--              DO NOT run in production without review.
-- ============================================================

-- ============================================================
-- SAMPLE GAMES (from BoardGameGeek top titles)
-- ============================================================

INSERT INTO games (bgg_id, name, description, min_players, max_players, min_play_time, max_play_time, min_age, complexity, bgg_rating, bgg_rank, year_published, publisher, designer) VALUES
(167791, 'Terraforming Mars',
 'In the 2400s, megacorporations compete to terraform Mars by raising temperature, oxygen levels, and ocean coverage.',
 1, 5, 120, 120, 12, 3.24, 8.40, 4, 2016, 'FryxGames', 'Jacob Fryxelius'),

(174430, 'Gloomhaven',
 'A game of Euro-inspired tactical combat in an evolving campaign world. Players control mercenaries with unique abilities.',
 1, 4, 60, 120, 14, 3.86, 8.77, 1, 2017, 'Cephalofair Games', 'Isaac Childres'),

(233078, 'Wingspan',
 'A competitive, medium-weight, card-driven, engine-building board game about attracting birds to your wildlife preserves.',
 1, 5, 40, 70, 10, 2.45, 8.12, 11, 2019, 'Stonemaier Games', 'Elizabeth Hargrave'),

(220308, 'Brass: Birmingham',
 'An economic strategy game about building networks and industries in Birmingham during the industrial revolution.',
 2, 4, 60, 120, 14, 3.91, 8.65, 2, 2018, 'Roxley', 'Gavan Brown'),

(161936, 'Pandemic Legacy: Season 1',
 'A game of global disease outbreak where players work cooperatively to stop pandemics from spreading worldwide.',
 2, 4, 60, 75, 13, 2.84, 8.61, 3, 2015, 'Z-Man Games', 'Rob Daviau'),

(291457, 'Clank! In! Space!',
 'A deck-building adventure. Sneak aboard the starship of an evil lord, steal precious artifacts, and escape!',
 2, 4, 60, 90, 12, 2.73, 7.90, 50, 2017, 'Dire Wolf Digital', 'Paul Dennen'),

(266192, 'Viticulture: Essential Edition',
 'A game of thematic worker placement in which players try to make the most successful winery in Tuscany.',
 1, 6, 45, 90, 13, 2.87, 8.14, 9, 2015, 'Stonemaier Games', 'Jamey Stegmaier'),

(182028, 'Through the Ages: A New Story of Civilization',
 'Build the greatest civilization through careful resource management, military might, and cultural development.',
 2, 4, 120, 240, 14, 4.40, 8.35, 6, 2015, 'Czech Games Edition', 'Vlaada Chvátil'),

(342942, 'Ark Nova',
 'Plan and build a modern, scientifically managed zoo. Support conservation projects around the world.',
 1, 4, 90, 150, 14, 3.72, 8.62, 5, 2021, 'Capstone Games', 'Mathias Wigge'),

(316554, 'Dune: Imperium',
 'Uses deck-building and worker placement to create a tense strategic experience with the Dune universe.',
 1, 4, 60, 120, 14, 3.00, 8.36, 7, 2020, 'Dire Wolf', 'Paul Dennen'),

(84876, 'The Castles of Burgundy',
 'Trade, build and rule the Burgundy region by working with settlements, mines, rivers and castles.',
 2, 4, 30, 90, 12, 2.99, 8.10, 15, 2011, 'Ravensburger', 'Stefan Feld'),

(12333, 'Twilight Imperium: Fourth Edition',
 'An epic game of galactic conquest, diplomacy, and intrigue for 3-6 players.',
 3, 6, 240, 480, 14, 4.29, 8.68, 8, 2017, 'Fantasy Flight Games', 'Christian Petersen'),

(9209, 'Ticket to Ride',
 'Collect cards of various types of train cars you then use to claim railway routes connecting cities.',
 2, 5, 45, 75, 8, 1.86, 7.43, 78, 2004, 'Days of Wonder', 'Alan R. Moon'),

(30549, 'Pandemic',
 'Players work as a team of disease-fighting specialists to treat infections and find cures before outbreaks occur.',
 2, 4, 45, 45, 8, 2.41, 7.60, 55, 2008, 'Z-Man Games', 'Matt Leacock'),

(110308, 'Patchwork',
 'A two-player only, tile placement game where players compete to build the most aesthetic quilt.',
 2, 2, 15, 30, 8, 1.67, 7.76, 34, 2014, 'Lookout Games', 'Uwe Rosenberg'),

(13, 'Catan',
 'Players collect resources and use them to build roads, settlements and cities on their way to dominating Catan.',
 3, 4, 60, 120, 10, 2.33, 7.13, 150, 1995, 'KOSMOS', 'Klaus Teuber'),

(68448, 'Dominion',
 'The classic deck-building game. Players purchase cards to add to their deck to build the most efficient engine.',
 2, 4, 30, 30, 13, 2.33, 7.60, 56, 2008, 'Rio Grande Games', 'Donald X. Vaccarino'),

(154203, 'Twilight Struggle',
 'A two-player game simulating the Cold War struggle between the US and USSR from 1945 to 1989.',
 2, 2, 120, 180, 12, 3.58, 8.24, 18, 2005, 'GMT Games', 'Ananda Gupta'),

(128882, 'Agricola',
 'Manage a farm with fields, pastures, houses and animals, feeding your family and building the best homestead.',
 1, 5, 30, 150, 12, 3.64, 7.93, 22, 2007, 'Lookout Games', 'Uwe Rosenberg'),

(192135, 'Spirit Island',
 'Cooperative game where spirits of the land defend their island home from colonizing invaders.',
 1, 4, 90, 120, 13, 3.89, 8.38, 10, 2017, 'Greater Than Games', 'R. Eric Reuss')

ON CONFLICT (bgg_id) DO NOTHING;

-- ============================================================
-- SEED GAME GENRES
-- ============================================================

INSERT INTO game_genres (game_id, genre)
SELECT g.id, unnest(v.genres::game_genre[])
FROM games g
JOIN (VALUES
  (167791, ARRAY['strategy', 'engine_building', 'tile_placement']::game_genre[]),
  (174430, ARRAY['dungeon_crawl', 'cooperative', 'strategy']::game_genre[]),
  (233078, ARRAY['engine_building', 'strategy', 'eurogame']::game_genre[]),
  (220308, ARRAY['strategy', 'eurogame', 'worker_placement']::game_genre[]),
  (161936, ARRAY['cooperative', 'legacy', 'strategy']::game_genre[]),
  (291457, ARRAY['deck_building', 'push_your_luck']::game_genre[]),
  (266192, ARRAY['worker_placement', 'eurogame', 'strategy']::game_genre[]),
  (182028, ARRAY['strategy', 'engine_building']::game_genre[]),
  (342942, ARRAY['strategy', 'engine_building', 'tile_placement']::game_genre[]),
  (316554, ARRAY['deck_building', 'worker_placement', 'strategy']::game_genre[]),
  (84876,  ARRAY['strategy', 'eurogame', 'tile_placement']::game_genre[]),
  (12333,  ARRAY['strategy', 'area_control', 'auction_bidding']::game_genre[]),
  (9209,   ARRAY['strategy', 'eurogame']::game_genre[]),
  (30549,  ARRAY['cooperative', 'strategy']::game_genre[]),
  (110308, ARRAY['abstract', 'tile_placement']::game_genre[]),
  (13,     ARRAY['strategy', 'eurogame']::game_genre[]),
  (68448,  ARRAY['deck_building', 'engine_building']::game_genre[]),
  (154203, ARRAY['strategy', 'wargame']::game_genre[]),
  (128882, ARRAY['worker_placement', 'eurogame', 'strategy']::game_genre[]),
  (192135, ARRAY['cooperative', 'strategy', 'area_control']::game_genre[])
) AS v(bgg_id, genres) ON g.bgg_id = v.bgg_id
ON CONFLICT DO NOTHING;
