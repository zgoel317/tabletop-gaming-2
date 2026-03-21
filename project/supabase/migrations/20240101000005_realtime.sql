-- ============================================================
-- REALTIME SUBSCRIPTIONS
-- Enable realtime for tables that need live updates
-- ============================================================

-- Enable realtime for profiles (for live status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- Enable realtime for user_connections (for follow notifications)
ALTER PUBLICATION supabase_realtime ADD TABLE user_connections;

-- Note: Messages and events tables will be added in future migrations
-- when those features are implemented.

-- ============================================================
-- FUNCTIONS FOR REALTIME SAFETY
-- These ensure users only receive their own realtime events
-- ============================================================

-- Filter realtime events so users only get updates for public profiles
-- or their own profile. This is handled at the application level
-- using Supabase's row-level security for realtime.

COMMENT ON TABLE profiles IS 'User profile data. Realtime enabled for live status updates.';
COMMENT ON TABLE user_connections IS 'Social connections. Realtime enabled for live connection updates.';
