-- Migration: 003_seed_data.sql
-- Description: Seeds initial reference data for game genres.
-- Uses ON CONFLICT (name) DO NOTHING to make this migration idempotent
-- (safe to run multiple times without creating duplicate rows).

INSERT INTO game_genres (name, description) VALUES
  ('Strategy',        'Games requiring strategic thinking and planning'),
  ('Worker Placement','Games where players assign pieces to claim actions'),
  ('Deck Building',   'Games where players construct a card deck during play'),
  ('Cooperative',     'Games where all players work together against the game'),
  ('Social Deduction','Games involving hidden roles and deception'),
  ('Dungeon Crawler', 'Adventure games exploring dungeons and defeating enemies'),
  ('Engine Building', 'Games focused on building efficient, synergistic systems'),
  ('Area Control',    'Games where players compete to dominate regions on the board'),
  ('Eurogame',        'European-style games emphasizing strategy over luck'),
  ('Ameritrash',      'Theme-heavy games with lots of components and luck'),
  ('Abstract',        'Games with minimal theme and pure strategic gameplay'),
  ('Party',           'Light, social games for larger groups'),
  ('Trivia',          'Games testing players knowledge'),
  ('Roll and Write',  'Games where players roll dice and fill in score sheets'),
  ('Push Your Luck',  'Games involving risk management and probability decisions'),
  ('Wargame',         'Games simulating military conflicts'),
  ('Trading Card',    'Games using collectible card systems'),
  ('Miniatures',      'Games featuring miniature figurines')
ON CONFLICT (name) DO NOTHING;
