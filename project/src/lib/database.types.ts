/**
 * Supabase Database TypeScript types
 * Generated from the migration schema to provide full type safety
 * across the application.
 *
 * Usage:
 *   import type { Database } from '@/lib/database.types'
 *   import type { Tables, Enums, TablesInsert, TablesUpdate } from '@/lib/database.types'
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

// ---------------------------------------------------------------------------
// Enum types
// ---------------------------------------------------------------------------

export type ExperienceLevel =
  | "beginner"
  | "casual"
  | "intermediate"
  | "experienced"
  | "expert";

export type GameGenre =
  | "strategy"
  | "worker_placement"
  | "deck_building"
  | "cooperative"
  | "social_deduction"
  | "roll_and_write"
  | "engine_building"
  | "area_control"
  | "dungeon_crawl"
  | "legacy"
  | "party"
  | "abstract"
  | "wargame"
  | "eurogame"
  | "ameritrash"
  | "rpg"
  | "trivia"
  | "push_your_luck"
  | "auction_bidding"
  | "tile_placement";

export type AvailabilityDay =
  | "monday"
  | "tuesday"
  | "wednesday"
  | "thursday"
  | "friday"
  | "saturday"
  | "sunday";

export type AvailabilityTime =
  | "morning"
  | "afternoon"
  | "evening"
  | "night";

export type UserRole = "user" | "moderator" | "admin";

export type CollectionStatus =
  | "owned"
  | "wishlist"
  | "previously_owned"
  | "want_to_play";

export type FriendshipStatus = "pending" | "accepted" | "blocked";

export type GroupMemberRole = "owner" | "organizer" | "member";

export type GroupVisibility = "public" | "private" | "unlisted";

export type EventStatus = "draft" | "published" | "cancelled" | "completed";

export type RsvpStatus = "attending" | "maybe" | "declined" | "waitlist";

export type LocationType =
  | "home"
  | "game_store"
  | "library"
  | "community_center"
  | "online"
  | "other";

export type LfgStatus = "open" | "filled" | "closed" | "expired";

export type ConversationType = "direct" | "group" | "event";

export type MessageType = "text" | "image" | "system";

export type NotificationType =
  | "message"
  | "event_invite"
  | "event_reminder"
  | "event_cancelled"
  | "group_invite"
  | "group_join_request"
  | "friend_request"
  | "friend_accepted"
  | "new_follower"
  | "rating_received"
  | "lfg_response"
  | "system";

// ---------------------------------------------------------------------------
// Row types (what you get back from SELECT)
// ---------------------------------------------------------------------------

export interface ProfileRow {
  id: string;
  username: string;
  display_name: string | null;
  bio: string | null;
  avatar_url: string | null;
  website_url: string | null;
  city: string | null;
  state_province: string | null;
  country: string;
  postal_code: string | null;
  /** PostGIS geography - returned as GeoJSON or WKT depending on query */
  location: unknown | null;
  search_radius_km: number;
  location_public: boolean;
  experience_level: ExperienceLevel;
  min_players_pref: number;
  max_players_pref: number;
  session_length_pref: number | null;
  games_played_count: number;
  rating_average: number;
  rating_count: number;
  role: UserRole;
  is_active: boolean;
  is_verified: boolean;
  onboarding_complete: boolean;
  notify_messages: boolean;
  notify_event_invite: boolean;
  notify_event_remind: boolean;
  notify_group_invite: boolean;
  notify_new_follower: boolean;
  created_at: string;
  updated_at: string;
  last_seen_at: string | null;
}

export interface ProfilePreferredGenreRow {
  id: string;
  profile_id: string;
  genre: GameGenre;
  created_at: string;
}

export interface ProfileAvailabilityRow {
  id: string;
  profile_id: string;
  day_of_week: AvailabilityDay;
  time_of_day: AvailabilityTime;
  created_at: string;
}

export interface GameRow {
  id: string;
  bgg_id: number | null;
  name: string;
  description: string | null;
  thumbnail_url: string | null;
  image_url: string | null;
  min_players: number | null;
  max_players: number | null;
  min_play_time: number | null;
  max_play_time: number | null;
  min_age: number | null;
  complexity: number | null;
  bgg_rating: number | null;
  bgg_rank: number | null;
  year_published: number | null;
  publisher: string | null;
  designer: string | null;
  bgg_synced_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface GameGenreRow {
  game_id: string;
  genre: GameGenre;
}

export interface UserGameCollectionRow {
  id: string;
  profile_id: string;
  game_id: string;
  status: CollectionStatus;
  notes: string | null;
  user_rating: number | null;
  play_count: number;
  created_at: string;
  updated_at: string;
}

export interface ProfileFavoriteGameRow {
  id: string;
  profile_id: string;
  game_id: string;
  sort_order: number;
  created_at: string;
}

export interface UserRatingRow {
  id: string;
  rater_id: string;
  rated_id: string;
  session_id: string | null;
  rating: number;
  review_text: string | null;
  created_at: string;
  updated_at: string;
}

export interface FriendshipRow {
  id: string;
  requester_id: string;
  addressee_id: string;
  status: FriendshipStatus;
  created_at: string;
  updated_at: string;
}

export interface GroupRow {
  id: string;
  name: string;
  description: string | null;
  avatar_url: string | null;
  banner_url: string | null;
  owner_id: string;
  visibility: GroupVisibility;
  city: string | null;
  state_province: string | null;
  country: string;
  location: unknown | null;
  primary_genre: GameGenre | null;
  experience_level: ExperienceLevel | null;
  max_members: number | null;
  member_count: number;
  event_count: number;
  requires_approval: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface GroupMemberRow {
  id: string;
  group_id: string;
  profile_id: string;
  role: GroupMemberRole;
  is_approved: boolean;
  joined_at: string;
  updated_at: string;
}

export interface GroupGameRow {
  group_id: string;
  game_id: string;
  added_by: string | null;
  added_at: string;
}

export interface EventRow {
  id: string;
  host_id: string;
  group_id: string | null;
  game_id: string | null;
  title: string;
  description: string | null;
  starts_at: string;
  ends_at: string | null;
  timezone: string;
  location_type: LocationType;
  location_name: string | null;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  state_province: string | null;
  country: string;
  postal_code: string | null;
  location: unknown | null;
  location_private: boolean;
  online_url: string | null;
  min_players: number;
  max_players: number | null;
  experience_level: ExperienceLevel | null;
  requirements: string | null;
  status: EventStatus;
  attendee_count: number;
  waitlist_count: number;
  is_recurring: boolean;
  recurrence_rule: string | null;
  created_at: string;
  updated_at: string;
}

export interface EventRsvpRow {
  id: string;
  event_id: string;
  profile_id: string;
  status: RsvpStatus;
  waitlist_position: number | null;
  guests: number;
  notes: string | null;
  responded_at: string;
  updated_at: string;
}

export interface EventGameRow {
  event_id: string;
  game_id: string;
  is_primary: boolean;
  added_by: string | null;
}

export interface LfgPostRow {
  id: string;
  author_id: string;
  game_id: string | null;
  title: string;
  description: string | null;
  desired_date: string | null;
  flexible_date: boolean;
  location_type: LocationType;
  city: string | null;
  state_province: string | null;
  country: string;
  location: unknown | null;
  players_needed: number;
  players_joined: number;
  experience_level: ExperienceLevel | null;
  status: LfgStatus;
  expires_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ConversationRow {
  id: string;
  type: ConversationType;
  name: string | null;
  avatar_url: string | null;
  group_id: string | null;
  event_id: string | null;
  last_message_id: string | null;
  last_message_at: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ConversationParticipantRow {
  id: string;
  conversation_id: string;
  profile_id: string;
  last_read_at: string | null;
  is_muted: boolean;
  left_at: string | null;
  joined_at: string;
  updated_at: string;
}

export interface MessageRow {
  id: string;
  conversation_id: string;
  sender_id: string;
  reply_to_id: string | null;
  type: MessageType;
  content: string | null;
  image_url: string | null;
  metadata: Json | null;
  is_deleted: boolean;
  deleted_at: string | null;
  is_edited: boolean;
  edited_at: string | null;
  created_at: string;
}

export interface MessageReactionRow {
  id: string;
  message_id: string;
  profile_id: string;
  emoji: string;
  created_at: string;
}

export interface NotificationRow {
  id: string;
  profile_id: string;
  type: NotificationType;
  title: string;
  body: string | null;
  action_url: string | null;
  data: Json | null;
  is_read: boolean;
  read_at: string | null;
  created_at: string;
}

// ---------------------------------------------------------------------------
// Insert types (what you pass to INSERT)
// ---------------------------------------------------------------------------

export type ProfileInsert = Omit<
  ProfileRow,
  | "games_played_count"
  | "rating_average"
  | "rating_count"
  | "created_at"
  | "updated_at"
  | "last_seen_at"
> & {
  games_played_count?: number;
  rating_average?: number;
  rating_count?: number;
  created_at?: string;
  updated_at?: string;
  last_seen_at?: string;
};

export type ProfilePreferredGenreInsert = Omit<
  ProfilePreferredGenreRow,
  "id" | "created_at"
> & { id?: string; created_at?: string };

export type ProfileAvailabilityInsert = Omit<
  ProfileAvailabilityRow,
  "id" | "created_at"
> & { id?: string; created_at?: string };

export type GameInsert = Omit<GameRow, "id" | "created_at" | "updated_at"> & {
  id?: string;
  created_at?: string;
  updated_at?: string;
};

export type UserGameCollectionInsert = Omit<
  UserGameCollectionRow,
  "id" | "play_count" | "created_at" | "updated_at"
> & {
  id?: string;
  play_count?: number;
  created_at?: string;
  updated_at?: string;
};

export type ProfileFavoriteGameInsert = Omit<
  ProfileFavoriteGameRow,
  "id" | "created_at"
> & { id?: string; created_at?: string };

export type UserRatingInsert = Omit<
  UserRatingRow,
  "id" | "created_at" | "updated_at"
> & { id?: string; created_at?: string; updated_at?: string };

export type FriendshipInsert = Omit<
  FriendshipRow,
  "id" | "created_at" | "updated_at"
> & { id?: string; created_at?: string; updated_at?: string };

export type GroupInsert = Omit<
  GroupRow,
  "id" | "member_count" | "event_count" | "created_at" | "updated_at"
> & {
  id?: string;
  member_count?: number;
  event_count?: number;
  created_at?: string;
  updated_at?: string;
};

export type GroupMemberInsert = Omit<
  GroupMemberRow,
  "id" | "joined_at" | "updated_at"
> & { id?: string; joined_at?: string; updated_at?: string };

export type EventInsert = Omit<
  EventRow,
  | "id"
  | "attendee_count"
  | "waitlist_count"
  | "created_at"
  | "updated_at"
> & {
  id?: string;
  attendee_count?: number;
  waitlist_count?: number;
  created_at?: string;
  updated_at?: string;
};

export type EventRsvpInsert = Omit<
  EventRsvpRow,
  "id" | "responded_at" | "updated_at"
> & { id?: string; responded_at?: string; updated_at?: string };

export type LfgPostInsert = Omit<
  LfgPostRow,
  "id" | "players_joined" | "created_at" | "updated_at"
> & {
  id?: string;
  players_joined?: number;
  created_at?: string;
  updated_at?: string;
};

export type ConversationInsert = Omit<
  ConversationRow,
  "id" | "last_message_id" | "last_message_at" | "created_at" | "updated_at"
> & {
  id?: string;
  last_message_id?: string;
  last_message_at?: string;
  created_at?: string;
  updated_at?: string;
};

export type MessageInsert = Omit<
  MessageRow,
  | "id"
  | "is_deleted"
  | "deleted_at"
  | "is_edited"
  | "edited_at"
  | "created_at"
> & {
  id?: string;
  is_deleted?: boolean;
  deleted_at?: string;
  is_edited?: boolean;
  edited_at?: string;
  created_at?: string;
};

export type NotificationInsert = Omit<
  NotificationRow,
  "id" | "is_read" | "read_at" | "created_at"
> & {
  id?: string;
  is_read?: boolean;
  read_at?: string;
  created_at?: string;
};

// ---------------------------------------------------------------------------
// Update types (partial versions for PATCH-style updates)
// ---------------------------------------------------------------------------

export type ProfileUpdate = Partial<
  Omit<ProfileRow, "id" | "created_at" | "rating_average" | "rating_count" | "games_played_count">
>;

export type GameUpdate = Partial<Omit<GameRow, "id" | "created_at">>;

export type UserGameCollectionUpdate = Partial<
  Omit<UserGameCollectionRow, "id" | "profile_id" | "game_id" | "created_at">
>;

export type GroupUpdate = Partial<
  Omit<GroupRow, "id" | "owner_id" | "member_count" | "event_count" | "created_at">
>;

export type GroupMemberUpdate = Partial<
  Omit<GroupMemberRow, "id" | "group_id" | "profile_id" | "joined_at">
>;

export type EventUpdate = Partial<
  Omit<EventRow, "id" | "host_id" | "attendee_count" | "waitlist_count" | "created_at">
>;

export type EventRsvpUpdate = Partial<
  Omit<EventRsvpRow, "id" | "event_id" | "profile_id" | "responded_at">
>;

export type LfgPostUpdate = Partial<
  Omit<LfgPostRow, "id" | "author_id" | "players_joined" | "created_at">
>;

export type MessageUpdate = Partial<
  Pick<MessageRow, "content" | "is_deleted" | "deleted_at" | "is_edited" | "edited_at">
>;

export type NotificationUpdate = Partial<Pick<NotificationRow, "is_read" | "read_at">>;

// ---------------------------------------------------------------------------
// Composite / joined types for common queries
// ---------------------------------------------------------------------------

/** Profile with aggregated stats from the profile_with_stats view */
export interface ProfileWithStats extends ProfileRow {
  preferred_genres: GameGenre[];
  available_days: AvailabilityDay[];
  favorite_games_count: number;
  owned_games_count: number;
}

/** Event with joined host, game, and group info from event_with_details view */
export interface EventWithDetails extends EventRow {
  host_username: string;
  host_display_name: string | null;
  host_avatar_url: string | null;
  host_rating: number;
  game_name: string | null;
  game_thumbnail_url: string | null;
  game_min_players: number | null;
  game_max_players: number | null;
  game_complexity: number | null;
  group_name: string | null;
  group_avatar_url: string | null;
  has_spots_available: boolean;
}

/** Conversation with latest message preview from conversation_with_preview view */
export interface ConversationWithPreview extends ConversationRow {
  last_message_content: string | null;
  last_message_type: MessageType | null;
  last_message_sender_id: string | null;
  last_message_sender_username: string | null;
  last_message_sender_avatar: string | null;
}

/** Result row from get_nearby_profiles() function */
export interface NearbyProfile {
  id: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  city: string | null;
  experience_level: ExperienceLevel;
  rating_average: number;
  rating_count: number;
  distance_km: number;
}

/** Result row from get_nearby_events() function */
export interface NearbyEvent {
  id: string;
  title: string;
  starts_at: string;
  location_type: LocationType;
  city: string | null;
  host_id: string;
  game_id: string | null;
  attendee_count: number;
  max_players: number | null;
  distance_km: number;
}

// ---------------------------------------------------------------------------
// Full Database type (for Supabase client generic)
// ---------------------------------------------------------------------------

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: ProfileRow;
        Insert: ProfileInsert;
        Update: ProfileUpdate;
      };
      profile_preferred_genres: {
        Row: ProfilePreferredGenreRow;
        Insert: ProfilePreferredGenreInsert;
        Update: never;
      };
      profile_availability: {
        Row: ProfileAvailabilityRow;
        Insert: ProfileAvailabilityInsert;
        Update: never;
      };
      games: {
        Row: GameRow;
        Insert: GameInsert;
        Update: GameUpdate;
      };
      game_genres: {
        Row: GameGenreRow;
        Insert: GameGenreRow;
        Update: never;
      };
      user_game_collection: {
        Row: UserGameCollectionRow;
        Insert: UserGameCollectionInsert;
        Update: UserGameCollectionUpdate;
      };
      profile_favorite_games: {
        Row: ProfileFavoriteGameRow;
        Insert: ProfileFavoriteGameInsert;
        Update: never;
      };
      user_ratings: {
        Row: UserRatingRow;
        Insert: UserRatingInsert;
        Update: Partial<Pick<UserRatingRow, "rating" | "review_text">>;
      };
      friendships: {
        Row: FriendshipRow;
        Insert: FriendshipInsert;
        Update: Partial<Pick<FriendshipRow, "status">>;
      };
      groups: {
        Row: GroupRow;
        Insert: GroupInsert;
        Update: GroupUpdate;
      };
      group_members: {
        Row: GroupMemberRow;
        Insert: GroupMemberInsert;
        Update: GroupMemberUpdate;
      };
      group_games: {
        Row: GroupGameRow;
        Insert: GroupGameRow;
        Update: never;
      };
      events: {
        Row: EventRow;
        Insert: EventInsert;
        Update: EventUpdate;
      };
      event_rsvps: {
        Row: EventRsvpRow;
        Insert: EventRsvpInsert;
        Update: EventRsvpUpdate;
      };
      event_games: {
        Row: EventGameRow;
        Insert: EventGameRow;
        Update: never;
      };
      lfg_posts: {
        Row: LfgPostRow;
        Insert: LfgPostInsert;
        Update: LfgPostUpdate;
      };
      conversations: {
        Row: ConversationRow;
        Insert: ConversationInsert;
        Update: Partial<
          Omit<ConversationRow, "id" | "type" | "created_by" | "created_at">
        >;
      };
      conversation_participants: {
        Row: ConversationParticipantRow;
        Insert: Omit<ConversationParticipantRow, "id" | "joined_at" | "updated_at"> & {
          id?: string;
          joined_at?: string;
          updated_at?: string;
        };
        Update: Partial<
          Pick<
            ConversationParticipantRow,
            "last_read_at" | "is_muted" | "left_at"
          >
        >;
      };
      messages: {
        Row: MessageRow;
        Insert: MessageInsert;
        Update: MessageUpdate;
      };
      message_reactions: {
        Row: MessageReactionRow;
        Insert: Omit<MessageReactionRow, "id" | "created_at"> & {
          id?: string;
          created_at?: string;
        };
        Update: never;
      };
      notifications: {
        Row: NotificationRow;
        Insert: NotificationInsert;
        Update: NotificationUpdate;
      };
    };
    Views: {
      profile_with_stats: {
        Row: ProfileWithStats;
      };
      event_with_details: {
        Row: EventWithDetails;
      };
      conversation_with_preview: {
        Row: ConversationWithPreview;
      };
    };
    Functions: {
      get_nearby_profiles: {
        Args: {
          p_latitude: number;
          p_longitude: number;
          p_radius_km?: number;
          p_limit?: number;
          p_offset?: number;
        };
        Returns: NearbyProfile[];
      };
      get_nearby_events: {
        Args: {
          p_latitude: number;
          p_longitude: number;
          p_radius_km?: number;
          p_limit?: number;
          p_offset?: number;
        };
        Returns: NearbyEvent[];
      };
      search_profiles: {
        Args: {
          p_query: string;
          p_experience?: ExperienceLevel;
          p_genre?: GameGenre;
          p_limit?: number;
          p_offset?: number;
        };
        Returns: Array<
          Pick<
            ProfileRow,
            | "id"
            | "username"
            | "display_name"
            | "avatar_url"
            | "city"
            | "experience_level"
            | "rating_average"
          > & { rank: number }
        >;
      };
      search_games: {
        Args: {
          p_query: string;
          p_genre?: GameGenre;
          p_min_age?: number;
          p_max_complexity?: number;
          p_limit?: number;
          p_offset?: number;
        };
        Returns: Array<
          Pick<
            GameRow,
            | "id"
            | "bgg_id"
            | "name"
            | "thumbnail_url"
            | "min_players"
            | "max_players"
            | "min_play_time"
            | "max_play_time"
            | "complexity"
            | "bgg_rating"
          > & { rank: number }
        >;
      };
      get_or_create_direct_conversation: {
        Args: { p_other_user_id: string };
        Returns: string;
      };
      get_user_unread_counts: {
        Args: Record<string, never>;
        Returns: Array<{ conversation_id: string; unread_count: number }>;
      };
      mark_conversation_read: {
        Args: { p_conversation_id: string };
        Returns: void;
      };
      cleanup_expired_lfg_posts: {
        Args: Record<string, never>;
        Returns: number;
      };
    };
    Enums: {
      experience_level: ExperienceLevel;
      game_genre: GameGenre;
      availability_day: AvailabilityDay;
      availability_time: AvailabilityTime;
      user_role: UserRole;
      collection_status: CollectionStatus;
      friendship_status: FriendshipStatus;
      group_member_role: GroupMemberRole;
      group_visibility: GroupVisibility;
      event_status: EventStatus;
      rsvp_status: RsvpStatus;
      location_type: LocationType;
      lfg_status: LfgStatus;
      conversation_type: ConversationType;
      message_type: MessageType;
      notification_type: NotificationType;
    };
  };
}

// ---------------------------------------------------------------------------
// Convenience type aliases
// ---------------------------------------------------------------------------

/** Shorthand: Tables<'profiles'> → ProfileRow */
export type Tables<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Row"];

/** Shorthand: TablesInsert<'profiles'> → ProfileInsert */
export type TablesInsert<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Insert"];

/** Shorthand: TablesUpdate<'profiles'> → ProfileUpdate */
export type TablesUpdate<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Update"];

/** Shorthand: Enums<'experience_level'> → ExperienceLevel */
export type Enums<T extends keyof Database["public"]["Enums"]> =
  Database["public"]["Enums"][T];
