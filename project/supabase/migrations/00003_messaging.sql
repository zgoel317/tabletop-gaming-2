-- ============================================================
-- Migration: 00003_messaging.sql
-- Description: In-app messaging system including direct
--              messages, group chats, and event discussions
-- ============================================================

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE conversation_type AS ENUM (
  'direct',   -- 1-on-1 direct messages
  'group',    -- Group chat (linked to a gaming group)
  'event'     -- Event-specific discussion thread
);

CREATE TYPE message_type AS ENUM (
  'text',
  'image',
  'system'  -- Automated messages (e.g., "John joined the group")
);

-- ============================================================
-- CONVERSATIONS TABLE
-- Thread container for both DMs and group chats
-- ============================================================

CREATE TABLE conversations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type            conversation_type NOT NULL DEFAULT 'direct',

  -- For group conversations: display name
  name            TEXT,
  avatar_url      TEXT,

  -- FK links to context (only one should be set for non-direct)
  group_id        UUID REFERENCES groups(id) ON DELETE CASCADE,
  event_id        UUID REFERENCES events(id) ON DELETE CASCADE,

  -- Denormalized: ID of the most recent message for quick preview
  last_message_id UUID,  -- FK added after messages table
  last_message_at TIMESTAMPTZ,

  created_by      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- A group/event should have at most one conversation
  UNIQUE (group_id),
  UNIQUE (event_id),

  CONSTRAINT conversation_context_check CHECK (
    (type = 'direct'  AND group_id IS NULL AND event_id IS NULL) OR
    (type = 'group'   AND group_id IS NOT NULL AND event_id IS NULL) OR
    (type = 'event'   AND event_id IS NOT NULL AND group_id IS NULL)
  )
);

COMMENT ON TABLE conversations IS 'Message thread containers for DMs, group chats, and event discussions';

-- ============================================================
-- CONVERSATION PARTICIPANTS TABLE
-- ============================================================

CREATE TABLE conversation_participants (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id   UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  profile_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Timestamp of the last message this user has read
  last_read_at      TIMESTAMPTZ,
  -- Whether user has muted this conversation
  is_muted          BOOLEAN DEFAULT FALSE,
  -- Whether user has left (for group chats)
  left_at           TIMESTAMPTZ,

  joined_at         TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at        TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (conversation_id, profile_id)
);

COMMENT ON TABLE conversation_participants IS 'Users participating in a conversation';

-- ============================================================
-- MESSAGES TABLE
-- ============================================================

CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

  -- Reply thread support
  reply_to_id     UUID REFERENCES messages(id) ON DELETE SET NULL,

  type            message_type DEFAULT 'text',
  content         TEXT,
  -- For image messages
  image_url       TEXT,
  -- JSON payload for system messages
  metadata        JSONB,

  -- Soft delete: hide message but preserve thread
  is_deleted      BOOLEAN DEFAULT FALSE,
  deleted_at      TIMESTAMPTZ,

  -- Edit history
  is_edited       BOOLEAN DEFAULT FALSE,
  edited_at       TIMESTAMPTZ,

  created_at      TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  CONSTRAINT message_content_check CHECK (
    (type = 'text'   AND content IS NOT NULL AND char_length(content) > 0) OR
    (type = 'image'  AND image_url IS NOT NULL) OR
    (type = 'system' AND metadata IS NOT NULL)
  ),
  CONSTRAINT message_content_length CHECK (char_length(content) <= 10000)
);

COMMENT ON TABLE messages IS 'Individual messages within conversations';

-- Add FK from conversations.last_message_id to messages
ALTER TABLE conversations
  ADD CONSTRAINT fk_conversations_last_message
  FOREIGN KEY (last_message_id) REFERENCES messages(id) ON DELETE SET NULL;

-- ============================================================
-- MESSAGE REACTIONS TABLE
-- Emoji reactions on messages
-- ============================================================

CREATE TABLE message_reactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id  UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  emoji       TEXT NOT NULL,

  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  UNIQUE (message_id, profile_id, emoji),
  CONSTRAINT emoji_length CHECK (char_length(emoji) <= 10)
);

COMMENT ON TABLE message_reactions IS 'Emoji reactions to messages';

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================

CREATE TYPE notification_type AS ENUM (
  'message',
  'event_invite',
  'event_reminder',
  'event_cancelled',
  'group_invite',
  'group_join_request',
  'friend_request',
  'friend_accepted',
  'new_follower',
  'rating_received',
  'lfg_response',
  'system'
);

CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        notification_type NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT,
  -- Deep link / route within the app
  action_url  TEXT,
  -- Contextual data as JSON
  data        JSONB,

  is_read     BOOLEAN DEFAULT FALSE,
  read_at     TIMESTAMPTZ,

  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE notifications IS 'In-app notifications for users';

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update conversations.last_message_at on new message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET
    last_message_id = NEW.id,
    last_message_at = NEW.created_at,
    updated_at      = NOW()
  WHERE id = NEW.conversation_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_conversation_last_message
  AFTER INSERT ON messages
  FOR EACH ROW
  WHEN (NEW.is_deleted = FALSE)
  EXECUTE FUNCTION update_conversation_last_message();

-- Auto-update updated_at
CREATE TRIGGER trg_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_conversation_participants_updated_at
  BEFORE UPDATE ON conversation_participants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- INDEXES
-- ============================================================

-- Conversations
CREATE INDEX idx_conversations_group_id    ON conversations USING btree (group_id);
CREATE INDEX idx_conversations_event_id    ON conversations USING btree (event_id);
CREATE INDEX idx_conversations_last_msg    ON conversations USING btree (last_message_at DESC NULLS LAST);

-- Participants
CREATE INDEX idx_participants_profile_id   ON conversation_participants USING btree (profile_id);
CREATE INDEX idx_participants_conv_id      ON conversation_participants USING btree (conversation_id);
CREATE INDEX idx_participants_active       ON conversation_participants USING btree (profile_id, conversation_id)
  WHERE left_at IS NULL;

-- Messages
CREATE INDEX idx_messages_conversation_id  ON messages USING btree (conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender_id        ON messages USING btree (sender_id);
CREATE INDEX idx_messages_reply_to         ON messages USING btree (reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX idx_messages_not_deleted      ON messages USING btree (conversation_id, created_at DESC)
  WHERE is_deleted = FALSE;

-- Reactions
CREATE INDEX idx_reactions_message_id      ON message_reactions USING btree (message_id);

-- Notifications
CREATE INDEX idx_notifications_profile_id  ON notifications USING btree (profile_id, created_at DESC);
CREATE INDEX idx_notifications_unread      ON notifications USING btree (profile_id, created_at DESC)
  WHERE is_read = FALSE;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE conversations             ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications             ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- conversations policies
-- ----------------------------------------------------------------

-- Users can see conversations they are part of, or group/event conversations
-- they have access to
CREATE POLICY "Users can view their conversations"
  ON conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversations.id
        AND cp.profile_id = auth.uid()
        AND cp.left_at IS NULL
    )
    OR (
      type = 'group' AND
      EXISTS (
        SELECT 1 FROM group_members gm
        WHERE gm.group_id = conversations.group_id
          AND gm.profile_id = auth.uid()
      )
    )
    OR (
      type = 'event' AND
      EXISTS (
        SELECT 1 FROM event_rsvps er
        WHERE er.event_id = conversations.event_id
          AND er.profile_id = auth.uid()
          AND er.status = 'attending'
      )
    )
  );

CREATE POLICY "Authenticated users can create direct conversations"
  ON conversations FOR INSERT
  WITH CHECK (
    auth.uid() = created_by
    AND type = 'direct'
  );

-- ----------------------------------------------------------------
-- conversation_participants policies
-- ----------------------------------------------------------------

CREATE POLICY "Participants can view conversation membership"
  ON conversation_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.profile_id = auth.uid()
    )
  );

CREATE POLICY "Users can join conversations"
  ON conversation_participants FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own participant record"
  ON conversation_participants FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- ----------------------------------------------------------------
-- messages policies
-- ----------------------------------------------------------------

CREATE POLICY "Participants can view messages in their conversations"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id
        AND cp.profile_id = auth.uid()
        AND cp.left_at IS NULL
    )
  );

CREATE POLICY "Participants can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id
        AND cp.profile_id = auth.uid()
        AND cp.left_at IS NULL
    )
  );

CREATE POLICY "Users can edit their own messages"
  ON messages FOR UPDATE
  USING (auth.uid() = sender_id)
  WITH CHECK (auth.uid() = sender_id);

-- Soft delete handled by UPDATE policy above
-- No hard DELETE allowed for message integrity

-- ----------------------------------------------------------------
-- message_reactions policies
-- ----------------------------------------------------------------

CREATE POLICY "Participants can view reactions"
  ON message_reactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      JOIN conversation_participants cp ON cp.conversation_id = m.conversation_id
      WHERE m.id = message_reactions.message_id
        AND cp.profile_id = auth.uid()
        AND cp.left_at IS NULL
    )
  );

CREATE POLICY "Participants can react to messages"
  ON message_reactions FOR INSERT
  WITH CHECK (
    auth.uid() = profile_id
    AND EXISTS (
      SELECT 1 FROM messages m
      JOIN conversation_participants cp ON cp.conversation_id = m.conversation_id
      WHERE m.id = message_reactions.message_id
        AND cp.profile_id = auth.uid()
        AND cp.left_at IS NULL
    )
  );

CREATE POLICY "Users can remove their own reactions"
  ON message_reactions FOR DELETE
  USING (auth.uid() = profile_id);

-- ----------------------------------------------------------------
-- notifications policies
-- ----------------------------------------------------------------

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = profile_id);

-- Notifications are inserted by server-side functions/triggers
-- Regular users cannot insert notifications directly
CREATE POLICY "Service role can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (FALSE); -- Only service_role (bypasses RLS) can insert

CREATE POLICY "Users can mark their notifications as read"
  ON notifications FOR UPDATE
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = profile_id);
