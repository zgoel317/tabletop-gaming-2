-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- Enable RLS on all tables and define access rules
-- ============================================================

-- ============================================================
-- PROFILES
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Public profiles are readable by all authenticated users
CREATE POLICY "profiles_select_public"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    is_public = true
    OR id = auth.uid()
  );

-- Users can only update their own profile
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Insert is handled by the trigger; allow users to re-insert defensively
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- ============================================================
-- GAMING PREFERENCES
-- ============================================================

ALTER TABLE gaming_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gaming_prefs_select"
  ON gaming_preferences FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = gaming_preferences.user_id AND p.is_public = true
    )
  );

CREATE POLICY "gaming_prefs_insert_own"
  ON gaming_preferences FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "gaming_prefs_update_own"
  ON gaming_preferences FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- USER PREFERRED GENRES
-- ============================================================

ALTER TABLE user_preferred_genres ENABLE ROW LEVEL SECURITY;

CREATE POLICY "genres_select"
  ON user_preferred_genres FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = user_preferred_genres.user_id AND p.is_public = true
    )
  );

CREATE POLICY "genres_insert_own"
  ON user_preferred_genres FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "genres_delete_own"
  ON user_preferred_genres FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- GAMES
-- ============================================================

ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Games are publicly readable
CREATE POLICY "games_select_all"
  ON games FOR SELECT
  TO authenticated
  USING (true);

-- Only service role can insert/update games (BGG sync)
CREATE POLICY "games_insert_service"
  ON games FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "games_update_service"
  ON games FOR UPDATE
  TO service_role
  USING (true);

-- ============================================================
-- USER GAME COLLECTION
-- ============================================================

ALTER TABLE user_game_collection ENABLE ROW LEVEL SECURITY;

CREATE POLICY "collection_select"
  ON user_game_collection FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = user_game_collection.user_id AND p.is_public = true
    )
  );

CREATE POLICY "collection_insert_own"
  ON user_game_collection FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "collection_update_own"
  ON user_game_collection FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "collection_delete_own"
  ON user_game_collection FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- USER REVIEWS
-- ============================================================

ALTER TABLE user_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reviews_select_public"
  ON user_reviews FOR SELECT
  TO authenticated
  USING (is_public = true OR reviewer_id = auth.uid() OR reviewee_id = auth.uid());

CREATE POLICY "reviews_insert_own"
  ON user_reviews FOR INSERT
  TO authenticated
  WITH CHECK (reviewer_id = auth.uid());

CREATE POLICY "reviews_update_own"
  ON user_reviews FOR UPDATE
  TO authenticated
  USING (reviewer_id = auth.uid())
  WITH CHECK (reviewer_id = auth.uid());

CREATE POLICY "reviews_delete_own"
  ON user_reviews FOR DELETE
  TO authenticated
  USING (reviewer_id = auth.uid());

-- ============================================================
-- GROUPS
-- ============================================================

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "groups_select"
  ON groups FOR SELECT
  TO authenticated
  USING (
    is_public = true
    OR EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = groups.id AND gm.user_id = auth.uid()
    )
  );

CREATE POLICY "groups_insert_authenticated"
  ON groups FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "groups_update_organizer"
  ON groups FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = groups.id
        AND gm.user_id = auth.uid()
        AND gm.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "groups_delete_owner"
  ON groups FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = groups.id
        AND gm.user_id = auth.uid()
        AND gm.role = 'owner'
    )
  );

-- ============================================================
-- GROUP MEMBERS
-- ============================================================

ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "group_members_select"
  ON group_members FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM groups g
      WHERE g.id = group_members.group_id AND g.is_public = true
    )
  );

CREATE POLICY "group_members_insert"
  ON group_members FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Users can join public groups themselves
    user_id = auth.uid()
    -- OR organizers can add members
    OR EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.user_id = auth.uid()
        AND gm.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "group_members_update_organizer"
  ON group_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.user_id = auth.uid()
        AND gm.role IN ('owner', 'organizer')
    )
  );

CREATE POLICY "group_members_delete"
  ON group_members FOR DELETE
  TO authenticated
  USING (
    -- Members can leave themselves
    user_id = auth.uid()
    -- Organizers can remove members
    OR EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id = group_members.group_id
        AND gm.user_id = auth.uid()
        AND gm.role IN ('owner', 'organizer')
    )
  );

-- ============================================================
-- EVENTS
-- ============================================================

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "events_select"
  ON events FOR SELECT
  TO authenticated
  USING (
    status = 'published'
    OR organizer_id = auth.uid()
    OR (
      group_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM group_members gm
        WHERE gm.group_id = events.group_id AND gm.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "events_insert_authenticated"
  ON events FOR INSERT
  TO authenticated
  WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "events_update_organizer"
  ON events FOR UPDATE
  TO authenticated
  USING (
    organizer_id = auth.uid()
    OR (
      group_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM group_members gm
        WHERE gm.group_id = events.group_id
          AND gm.user_id = auth.uid()
          AND gm.role IN ('owner', 'organizer')
      )
    )
  );

CREATE POLICY "events_delete_organizer"
  ON events FOR DELETE
  TO authenticated
  USING (organizer_id = auth.uid());

-- ============================================================
-- EVENT RSVPs
-- ============================================================

ALTER TABLE event_rsvps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rsvps_select"
  ON event_rsvps FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_rsvps.event_id AND e.organizer_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_rsvps.event_id AND e.status = 'published'
    )
  );

CREATE POLICY "rsvps_insert_own"
  ON event_rsvps FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "rsvps_update_own"
  ON event_rsvps FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "rsvps_delete_own"
  ON event_rsvps FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_rsvps.event_id AND e.organizer_id = auth.uid()
    )
  );

-- ============================================================
-- LFG POSTS
-- ============================================================

ALTER TABLE lfg_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lfg_select_active"
  ON lfg_posts FOR SELECT
  TO authenticated
  USING (is_active = true OR user_id = auth.uid());

CREATE POLICY "lfg_insert_own"
  ON lfg_posts FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "lfg_update_own"
  ON lfg_posts FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "lfg_delete_own"
  ON lfg_posts FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- CONVERSATIONS
-- ============================================================

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversations_select_participant"
  ON conversations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversations.id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "conversations_insert_authenticated"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "conversations_update_participant"
  ON conversations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversations.id AND cp.user_id = auth.uid()
    )
  );

-- ============================================================
-- CONVERSATION PARTICIPANTS
-- ============================================================

ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conv_participants_select"
  ON conversation_participants FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM conversation_participants cp2
      WHERE cp2.conversation_id = conversation_participants.conversation_id
        AND cp2.user_id = auth.uid()
    )
  );

CREATE POLICY "conv_participants_insert"
  ON conversation_participants FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
  );

CREATE POLICY "conv_participants_update_own"
  ON conversation_participants FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "conv_participants_delete"
  ON conversation_participants FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_participants.conversation_id
        AND c.created_by = auth.uid()
    )
  );

-- ============================================================
-- MESSAGES
-- ============================================================

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "messages_select_participant"
  ON messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "messages_insert_participant"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "messages_update_own"
  ON messages FOR UPDATE
  TO authenticated
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "messages_delete_own"
  ON messages FOR DELETE
  TO authenticated
  USING (sender_id = auth.uid());

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_insert_service"
  ON notifications FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Also allow the app to insert notifications via authenticated functions
CREATE POLICY "notifications_insert_system"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- USER BLOCKS
-- ============================================================

ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blocks_select_own"
  ON user_blocks FOR SELECT
  TO authenticated
  USING (blocker_id = auth.uid());

CREATE POLICY "blocks_insert_own"
  ON user_blocks FOR INSERT
  TO authenticated
  WITH CHECK (blocker_id = auth.uid());

CREATE POLICY "blocks_delete_own"
  ON user_blocks FOR DELETE
  TO authenticated
  USING (blocker_id = auth.uid());

-- ============================================================
-- USER CONNECTIONS
-- ============================================================

ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "connections_select_own"
  ON user_connections FOR SELECT
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

CREATE POLICY "connections_insert_own"
  ON user_connections FOR INSERT
  TO authenticated
  WITH CHECK (requester_id = auth.uid());

CREATE POLICY "connections_update_addressee"
  ON user_connections FOR UPDATE
  TO authenticated
  USING (addressee_id = auth.uid() OR requester_id = auth.uid());

CREATE POLICY "connections_delete_own"
  ON user_connections FOR DELETE
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());
