-- ============================================================
-- SEED DATA — DEVELOPMENT ONLY
-- Run this file only in development. Do NOT run in production.
--
-- Uses hardcoded UUIDs so data is stable and re-runnable.
-- All inserts use ON CONFLICT DO NOTHING for idempotency.
--
-- NOTE: Because the handle_new_user() trigger automatically
-- creates profile rows when auth.users rows are inserted, in
-- a real local dev environment you would sign up via the Auth
-- API. These direct inserts into profiles bypass the trigger
-- and are provided for convenience in DB-only testing.
-- ============================================================

-- Sample user UUIDs (match test accounts in your local Auth setup)
-- User 1: alice@example.com
-- User 2: bob@example.com
-- User 3: carol@example.com

-- ============================================================
-- PROFILES
-- ============================================================
INSERT INTO profiles (
  id,
  username,
  full_name,
  bio,
  avatar_url,
  location_city,
  location_state,
  location_country,
  location_lat,
  location_lng,
  is_public
) VALUES
(
  '00000000-0000-0000-0000-000000000001',
  'alice_gamer',
  'Alice Thompson',
  'Lifelong board game enthusiast. I love heavy euro games and teaching new players. Organizer of the Wednesday Night Gamers group in Portland.',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=alice',
  'Portland',
  'OR',
  'US',
  45.523064,
  -122.676483,
  true
),
(
  '00000000-0000-0000-0000-000000000002',
  'bobplays',
  'Bob Martinez',
  'Casual gamer who loves thematic adventure games. Always up for a good dungeon crawl or cooperative experience.',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=bob',
  'Portland',
  'OR',
  'US',
  45.512794,
  -122.679565,
  true
),
(
  '00000000-0000-0000-0000-000000000003',
  'carol_strategist',
  'Carol Chen',
  'Competitive player focused on strategy and optimization. Tournament organizer. Private profile — connect with me through groups.',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=carol',
  'Seattle',
  'WA',
  'US',
  47.606209,
  -122.332071,
  false  -- private profile
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- GAMING PREFERENCES
-- ============================================================
INSERT INTO gaming_preferences (
  id,
  user_id,
  experience_level,
  preferred_genres,
  favorite_games,
  preferred_player_count_min,
  preferred_player_count_max,
  preferred_session_length_hours,
  availability_notes,
  willing_to_teach,
  willing_to_travel_miles
) VALUES
(
  '00000000-0000-0000-0001-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'advanced',
  ARRAY['Euro', 'Strategy', 'Worker Placement', 'Engine Building'],
  ARRAY['Terraforming Mars', 'Wingspan', 'Viticulture', 'Agricola', 'Brass: Birmingham'],
  2,
  5,
  3.0,
  'Available Wednesday evenings and weekend afternoons. Occasional Friday nights.',
  true,
  25
),
(
  '00000000-0000-0000-0001-000000000002',
  '00000000-0000-0000-0000-000000000002',
  'beginner',
  ARRAY['Thematic', 'Adventure', 'Cooperative', 'Dungeon Crawl'],
  ARRAY['Gloomhaven', 'Pandemic', 'Spirit Island', 'Betrayal at House on the Hill'],
  3,
  6,
  2.5,
  'Weekends only. Prefer afternoon sessions. Can host occasionally.',
  false,
  10
),
(
  '00000000-0000-0000-0001-000000000003',
  '00000000-0000-0000-0000-000000000003',
  'expert',
  ARRAY['Abstract', 'Strategy', 'War Games', 'Economic'],
  ARRAY['Through the Ages', 'Twilight Imperium', 'War of the Ring', 'Power Grid', 'Food Chain Magnate'],
  2,
  4,
  4.5,
  'Flexible schedule. Prefer longer sessions. Available for full-day gaming events.',
  false,
  50
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- GAME COLLECTIONS
-- BGG IDs: Catan=13, Ticket to Ride=9209, Pandemic=30549,
--          Wingspan=266192, Terraforming Mars=167791,
--          Gloomhaven=174430, Carcassonne=822, Dominion=36218
-- ============================================================

-- Alice's collection
INSERT INTO game_collections (
  id, user_id, bgg_game_id, game_name, game_image_url, collection_type, user_rating, notes
) VALUES
(
  '00000000-0000-0000-0002-000000000001',
  '00000000-0000-0000-0000-000000000001',
  167791,
  'Terraforming Mars',
  'https://cf.geekdo-images.com/wg9oOLcsKvDesSUdZQ4rxw__imagepage/img/BTxqxgYay5tHJfVoJ2NF7rKgCTY=/fit-in/900x600/filters:no_upscale():strip_icc()/pic3536616.jpg',
  'owned',
  9,
  'My absolute favorite. Have all expansions.'
),
(
  '00000000-0000-0000-0002-000000000002',
  '00000000-0000-0000-0000-000000000001',
  266192,
  'Wingspan',
  'https://cf.geekdo-images.com/yLZJCVLlIx4c7eJEWUNJ7w__imagepage/img/uIjeoKgHMcRtzRSR4MoUYl3nXxs=/fit-in/900x600/filters:no_upscale():strip_icc()/pic4458123.jpg',
  'owned',
  8,
  'Great for introducing new players to euro games.'
),
(
  '00000000-0000-0000-0002-000000000003',
  '00000000-0000-0000-0000-000000000001',
  13,
  'Catan',
  'https://cf.geekdo-images.com/W3Bsga_uLP9kO91gZ7H8yw__imagepage/img/M_3Vg1j2HlNcONnTNKfTMuzKgfY=/fit-in/900x600/filters:no_upscale():strip_icc()/pic2419375.jpg',
  'owned',
  6,
  'Good gateway game but have moved on to heavier stuff.'
),
(
  '00000000-0000-0000-0002-000000000004',
  '00000000-0000-0000-0000-000000000001',
  174430,
  'Gloomhaven',
  NULL,
  'wishlist',
  NULL,
  'Want to pick this up for campaign nights.'
),

-- Bob's collection
(
  '00000000-0000-0000-0002-000000000005',
  '00000000-0000-0000-0000-000000000002',
  30549,
  'Pandemic',
  'https://cf.geekdo-images.com/S3ybV1LAp0RVQPqrYElCJg__imagepage/img/0aDM9xFLbMchKMKQdovdHhCK4w8=/fit-in/900x600/filters:no_upscale():strip_icc()/pic1534148.jpg',
  'owned',
  7,
  'My go-to for cooperative play nights.'
),
(
  '00000000-0000-0000-0002-000000000006',
  '00000000-0000-0000-0000-000000000002',
  9209,
  'Ticket to Ride',
  'https://cf.geekdo-images.com/raQaADpMKHnEHBbADnSRdA__imagepage/img/KlAn2C3oqPaT5dB0PqbOJMm6Oc0=/fit-in/900x600/filters:no_upscale():strip_icc()/pic38668.jpg',
  'owned',
  8,
  'Great for game nights with non-gamers.'
),
(
  '00000000-0000-0000-0002-000000000007',
  '00000000-0000-0000-0000-000000000002',
  174430,
  'Gloomhaven',
  NULL,
  'wishlist',
  NULL,
  'High priority wishlist item!'
),
(
  '00000000-0000-0000-0002-000000000008',
  '00000000-0000-0000-0000-000000000002',
  822,
  'Carcassonne',
  NULL,
  'played',
  7,
  'Played at a friend''s place. Would love to own it.'
),

-- Carol's collection
(
  '00000000-0000-0000-0002-000000000009',
  '00000000-0000-0000-0000-000000000003',
  167791,
  'Terraforming Mars',
  NULL,
  'owned',
  8,
  'Solid game. Prefer the corporate era variant.'
),
(
  '00000000-0000-0000-0002-000000000010',
  '00000000-0000-0000-0000-000000000003',
  36218,
  'Dominion',
  NULL,
  'selling',
  6,
  'Moving on from this one. All base cards included.'
),
(
  '00000000-0000-0000-0002-000000000011',
  '00000000-0000-0000-0000-000000000003',
  9209,
  'Ticket to Ride',
  NULL,
  'played',
  5,
  'Too light for my taste but fine as a gateway game.'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PLAYER RATINGS
-- Alice rates Bob; Bob rates Alice
-- ============================================================
INSERT INTO player_ratings (
  id, rater_id, rated_id, rating, review_text
) VALUES
(
  '00000000-0000-0000-0003-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  4,
  'Bob is a great gaming partner — always in good spirits, follows rules well, and is fun to play with. Would definitely game with him again!'
),
(
  '00000000-0000-0000-0003-000000000002',
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  5,
  'Alice is an excellent host and teacher. She explained complex rules clearly and made sure everyone had a great time. Highly recommend gaming with her!'
)
ON CONFLICT (id) DO NOTHING;
