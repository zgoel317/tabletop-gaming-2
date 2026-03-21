-- ============================================================
-- SEED DATA
-- Initial data for development and testing
-- ============================================================

-- ============================================================
-- SEED GAMES (sample board games referencing BGG IDs)
-- ============================================================

INSERT INTO games (
  bgg_id, name, description, min_players, max_players,
  min_playtime_minutes, max_playtime_minutes, min_age,
  complexity_rating, average_rating, year_published,
  publisher, designer, genres, bgg_rank
) VALUES
(
  167791,
  'Terraforming Mars',
  'In the 2400s, megacorporations race to terraform Mars by raising the temperature, oxygen level, and ocean coverage. Players control corporations and work together in the terraforming process while competing for victory points.',
  1, 5, 120, 180, 12,
  3.26, 8.40, 2016,
  'FryxGames', 'Jacob Fryxelius',
  ARRAY['strategy', 'worker_placement']::game_genre[], 4
),
(
  224517,
  'Brass: Birmingham',
  'An economic strategy game set in Birmingham during the industrial revolution. Players develop, build, and establish their industries and network, creating a web of connections.',
  2, 4, 60, 120, 14,
  3.91, 8.66, 2018,
  'Roxley', 'Gavan Brown, Matt Tolman, Martin Wallace',
  ARRAY['strategy', 'euro']::game_genre[], 1
),
(
  174430,
  'Gloomhaven',
  'A game of Euro-inspired tactical combat in a persistent world of shifting motives. Players take on the role of wandering adventurers with unique skill sets and motives.',
  1, 4, 60, 120, 14,
  3.86, 8.79, 2017,
  'Cephalofair Games', 'Isaac Childres',
  ARRAY['cooperative', 'roleplaying']::game_genre[], 2
),
(
  161936,
  'Pandemic Legacy: Season 1',
  'A cooperative game where players work as a team of specialists to prevent the outbreak of diseases around the world. Unlike other Pandemic games, the world changes permanently.',
  2, 4, 60, 75, 13,
  2.83, 8.62, 2015,
  'Z-Man Games', 'Rob Daviau, Matt Leacock',
  ARRAY['cooperative', 'legacy']::game_genre[], 3
),
(
  266192,
  'Wingspan',
  'A competitive bird-collection, engine-building game. Players are bird enthusiasts—researchers, bird watchers, ornithologists—seeking to discover and attract the best birds to their network of wildlife preserves.',
  1, 5, 40, 70, 10,
  2.45, 8.08, 2019,
  'Stonemaier Games', 'Elizabeth Hargrave',
  ARRAY['strategy', 'euro', 'family']::game_genre[], 10
),
(
  316554,
  'Dune: Imperium',
  'A deck-building game that finds inspiration in the Dune universe. You will guide one of the great factions to victory by deploying unique agents, deploying troops, and wielding influence.',
  1, 4, 60, 120, 14,
  3.01, 8.40, 2020,
  'Dire Wolf', 'Paul Dennen',
  ARRAY['strategy', 'deck_building', 'worker_placement']::game_genre[], 6
),
(
  12333,
  'Twilight Struggle',
  'A two-player game simulating the Cold War. Players control either the US or USSR and attempt to control countries and regions.',
  2, 2, 120, 180, 13,
  3.59, 8.25, 2005,
  'GMT Games', 'Ananda Gupta, Jason Matthews',
  ARRAY['strategy', 'wargame']::game_genre[], 15
),
(
  36218,
  'Dominion',
  'The first deck-building game! Players start with identical small decks and expand them by purchasing cards from a central supply.',
  2, 4, 30, 30, 13,
  2.33, 7.61, 2008,
  'Rio Grande Games', 'Donald X. Vaccarino',
  ARRAY['strategy', 'deck_building']::game_genre[], 50
),
(
  233078,
  'Spirit Island',
  'A complex cooperative game about defending an island from colonizers. Different Spirits with different abilities must work together.',
  1, 4, 90, 120, 13,
  3.86, 8.35, 2017,
  'Greater Than Games', 'R. Eric Reuss',
  ARRAY['strategy', 'cooperative']::game_genre[], 9
),
(
  342942,
  'Pandemic Legacy: Season 0',
  'A prequel to Season 1. Players are Cold War-era CDC agents trying to prevent Soviet bio-terrorism.',
  2, 4, 60, 75, 14,
  3.18, 8.09, 2020,
  'Z-Man Games', 'Rob Daviau, Matt Leacock',
  ARRAY['cooperative', 'legacy']::game_genre[], 22
),
(
  31260,
  'Agricola',
  'A worker placement game where players develop a farm, gathering resources and feeding their family. Avoid starvation while improving your homestead.',
  1, 5, 30, 150, 12,
  3.64, 7.97, 2007,
  'Lookout Games', 'Uwe Rosenberg',
  ARRAY['strategy', 'worker_placement', 'euro']::game_genre[], 25
),
(
  230802,
  'Azul',
  'Players are artisans tasked with beautifying the royal palace of Evora. Compete to create the most beautiful tile mosaic.',
  2, 4, 30, 45, 8,
  1.77, 7.80, 2017,
  'Next Move Games', 'Michael Kiesling',
  ARRAY['strategy', 'abstract', 'family']::game_genre[], 30
),
(
  9209,
  'Ticket to Ride',
  'Build train routes across North America, collecting cards to claim routes and complete destination tickets.',
  2, 5, 45, 75, 8,
  1.86, 7.41, 2004,
  'Days of Wonder', 'Alan R. Moon',
  ARRAY['strategy', 'family']::game_genre[], 45
),
(
  822,
  'Carcassonne',
  'A tile-placement game in which players take turns drawing and placing tiles to build cities, roads, monasteries, and farms.',
  2, 5, 30, 45, 7,
  1.89, 7.42, 2000,
  'Hans im Glück', 'Klaus-Jürgen Wrede',
  ARRAY['strategy', 'family', 'euro']::game_genre[], 48
),
(
  68448,
  'Seven Wonders',
  'Lead one of the seven greatest cities of the ancient world. Exploit your city's natural resources, develop commerce routes, and apply your military strength.',
  3, 7, 30, 30, 10,
  2.33, 7.72, 2010,
  'Repos Production', 'Antoine Bauza',
  ARRAY['strategy', 'euro', 'competitive']::game_genre[], 35
);

-- ============================================================
-- HELPFUL VIEWS
-- ============================================================

-- Public profiles view (excludes sensitive location data when not public)
CREATE OR REPLACE VIEW public_profiles AS
SELECT
  p.id,
  p.username,
  p.display_name,
  p.bio,
  p.avatar_url,
  p.website,
  CASE WHEN p.location_public THEN p.city ELSE NULL END AS city,
  CASE WHEN p.location_public THEN p.state_province ELSE NULL END AS state_province,
  CASE WHEN p.location_public THEN p.country ELSE NULL END AS country,
  p.is_active,
  p.last_seen_at,
  p.created_at,
  gp.experience_level,
  gp.looking_for_group,
  gp.willing_to_teach,
  COALESCE(
    (SELECT ROUND(AVG(r.rating)::NUMERIC, 2) FROM user_reviews r WHERE r.reviewee_id = p.id AND r.is_public),
    0
  ) AS avg_rating,
  (SELECT COUNT(*) FROM user_reviews r WHERE r.reviewee_id = p.id AND r.is_public) AS review_count
FROM profiles p
LEFT JOIN gaming_preferences gp ON gp.user_id = p.id
WHERE p.is_public = true AND p.is_active = true;

COMMENT ON VIEW public_profiles IS 'Safe public view of user profiles with aggregated stats';

-- Upcoming events view
CREATE OR REPLACE VIEW upcoming_events AS
SELECT
  e.id,
  e.title,
  e.description,
  e.starts_at,
  e.ends_at,
  e.timezone,
  e.venue_name,
  e.venue_address,
  e.city,
  e.state_province,
  e.country,
  e.location,
  e.is_online,
  e.online_platform,
  e.min_players,
  e.max_players,
  e.current_player_count,
  e.waitlist_count,
  e.waitlist_enabled,
  e.cost_per_player,
  e.experience_required,
  COALESCE(g.name, e.game_name) AS game_name,
  g.thumbnail_url AS game_thumbnail,
  g.min_players AS game_min_players,
  g.max_players AS game_max_players,
  p.username AS organizer_username,
  p.display_name AS organizer_display_name,
  p.avatar_url AS organizer_avatar_url,
  gr.name AS group_name,
  gr.slug AS group_slug,
  e.created_at
FROM events e
JOIN profiles p ON p.id = e.organizer_id
LEFT JOIN games g ON g.id = e.game_id
LEFT JOIN groups gr ON gr.id = e.group_id
WHERE
  e.status = 'published'
  AND e.starts_at >= NOW();

COMMENT ON VIEW upcoming_events IS 'Published future events with enriched details';

-- Active LFG posts view
CREATE OR REPLACE VIEW active_lfg_posts AS
SELECT
  l.id,
  l.title,
  l.description,
  l.players_needed,
  l.experience_required,
  l.preferred_days,
  l.city,
  l.state_province,
  l.country,
  l.location,
  l.is_online,
  l.expires_at,
  l.created_at,
  COALESCE(g.name, l.game_name) AS game_name,
  g.thumbnail_url AS game_thumbnail,
  p.username,
  p.display_name,
  p.avatar_url,
  gp.experience_level AS poster_experience_level
FROM lfg_posts l
JOIN profiles p ON p.id = l.user_id
LEFT JOIN games g ON g.id = l.game_id
LEFT JOIN gaming_preferences gp ON gp.user_id = l.user_id
WHERE
  l.is_active = true
  AND (l.expires_at IS NULL OR l.expires_at > NOW());

COMMENT ON VIEW active_lfg_posts IS 'Active LFG posts with poster profile and game details';

-- User game library view
CREATE OR REPLACE VIEW user_game_library AS
SELECT
  ugc.user_id,
  ugc.status,
  ugc.willing_to_lend,
  ugc.notes,
  ugc.condition,
  g.id AS game_id,
  g.name AS game_name,
  g.bgg_id,
  g.thumbnail_url,
  g.min_players,
  g.max_players,
  g.min_playtime_minutes,
  g.max_playtime_minutes,
  g.complexity_rating,
  g.average_rating,
  g.genres,
  ugc.created_at
FROM user_game_collection ugc
JOIN games g ON g.id = ugc.game_id;

COMMENT ON VIEW user_game_library IS 'Enriched view of user game collections';

-- ============================================================
-- GRANT PERMISSIONS TO AUTHENTICATED ROLE
-- ============================================================

GRANT SELECT ON public_profiles TO authenticated;
GRANT SELECT ON upcoming_events TO authenticated;
GRANT SELECT ON active_lfg_posts TO authenticated;
GRANT SELECT ON user_game_library TO authenticated;

-- Allow anonymous/public access to read published events and profiles
GRANT SELECT ON upcoming_events TO anon;
GRANT SELECT ON active_lfg_posts TO anon;
GRANT SELECT ON public_profiles TO anon;
GRANT SELECT ON games TO anon;
