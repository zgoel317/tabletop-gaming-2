/**
 * TypeScript type definitions generated from the Supabase database schema.
 * These types mirror the database tables, views, enums, and functions.
 *
 * In production, use `supabase gen types typescript --project-id YOUR_PROJECT_ID`
 * to auto-generate these from your live schema.
 */

// ============================================================
// ENUMS
// ============================================================

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert'

export type GameGenre =
  | 'strategy'
  | 'worker_placement'
  | 'deck_building'
  | 'cooperative'
  | 'competitive'
  | 'party'
  | 'roleplaying'
  | 'wargame'
  | 'abstract'
  | 'family'
  | 'euro'
  | 'ameritrash'
  | 'trivia'
  | 'dexterity'
  | 'legacy'

export type AvailabilityDay =
  | 'monday'
  | 'tuesday'
  | 'wednesday'
  | 'thursday'
  | 'friday'
  | 'saturday'
  | 'sunday'

export type GroupRole = 'owner' | 'organizer' | 'member'

export type EventStatus = 'draft' | 'published' | 'cancelled' | 'completed'

export type RsvpStatus = 'going' | 'maybe' | 'not_going' | 'waitlisted'

export type MessageType = 'direct' | 'group' | 'event'

export type CollectionStatus = 'owned' | 'wishlist' | 'previously_owned' | 'for_trade'

export type NotificationType =
  | 'event_invite'
  | 'event_reminder'
  | 'message_received'
  | 'group_invite'
  | 'rsvp_update'
  | 'review_received'
  | 'session_cancelled'
  | 'waitlist_promoted'

// ============================================================
// DATABASE ROW TYPES
// ============================================================

export interface Profile {
  id: string
  username: string
  display_name: string
  bio: string | null
  avatar_url: string | null
  website: string | null
  city: string | null
  state_province: string | null
  country: string | null
  postal_code: string | null
  /** PostGIS geography - returned as GeoJSON or WKT from Supabase */
  location: unknown | null
  location_public: boolean
  search_radius_km: number
  is_public: boolean
  is_active: boolean
  onboarding_completed: boolean
  last_seen_at: string | null
  created_at: string
  updated_at: string
}

export interface ProfileInsert {
  id: string
  username: string
  display_name: string
  bio?: string | null
  avatar_url?: string | null
  website?: string | null
  city?: string | null
  state_province?: string | null
  country?: string | null
  postal_code?: string | null
  location?: unknown | null
  location_public?: boolean
  search_radius_km?: number
  is_public?: boolean
  is_active?: boolean
  onboarding_completed?: boolean
  last_seen_at?: string | null
}

export interface ProfileUpdate extends Partial<ProfileInsert> {
  updated_at?: string
}

// ============================================================

export interface GamingPreferences {
  id: string
  user_id: string
  experience_level: ExperienceLevel
  preferred_player_count_min: number | null
  preferred_player_count_max: number | null
  preferred_session_length_hours: number | null
  available_days: AvailabilityDay[] | null
  available_time_start: string | null
  available_time_end: string | null
  playstyle_notes: string | null
  looking_for_group: boolean
  willing_to_teach: boolean
  willing_to_travel: boolean
  created_at: string
  updated_at: string
}

export interface GamingPreferencesUpdate {
  experience_level?: ExperienceLevel
  preferred_player_count_min?: number | null
  preferred_player_count_max?: number | null
  preferred_session_length_hours?: number | null
  available_days?: AvailabilityDay[] | null
  available_time_start?: string | null
  available_time_end?: string | null
  playstyle_notes?: string | null
  looking_for_group?: boolean
  willing_to_teach?: boolean
  willing_to_travel?: boolean
}

// ============================================================

export interface UserPreferredGenre {
  user_id: string
  genre: GameGenre
  created_at: string
}

// ============================================================

export interface Game {
  id: string
  bgg_id: number | null
  name: string
  description: string | null
  thumbnail_url: string | null
  image_url: string | null
  min_players: number | null
  max_players: number | null
  min_playtime_minutes: number | null
  max_playtime_minutes: number | null
  min_age: number | null
  complexity_rating: number | null
  average_rating: number | null
  year_published: number | null
  publisher: string | null
  designer: string | null
  genres: GameGenre[] | null
  bgg_rank: number | null
  bgg_last_synced_at: string | null
  created_at: string
  updated_at: string
}

export interface GameInsert {
  bgg_id?: number | null
  name: string
  description?: string | null
  thumbnail_url?: string | null
  image_url?: string | null
  min_players?: number | null
  max_players?: number | null
  min_playtime_minutes?: number | null
  max_playtime_minutes?: number | null
  min_age?: number | null
  complexity_rating?: number | null
  average_rating?: number | null
  year_published?: number | null
  publisher?: string | null
  designer?: string | null
  genres?: GameGenre[] | null
  bgg_rank?: number | null
  bgg_last_synced_at?: string | null
}

// ============================================================

export interface UserGameCollection {
  id: string
  user_id: string
  game_id: string
  status: CollectionStatus
  notes: string | null
  condition: string | null
  willing_to_lend: boolean
  created_at: string
  updated_at: string
}

export interface UserGameCollectionInsert {
  user_id: string
  game_id: string
  status: CollectionStatus
  notes?: string | null
  condition?: string | null
  willing_to_lend?: boolean
}

// ============================================================

export interface UserReview {
  id: string
  reviewer_id: string
  reviewee_id: string
  rating: number
  review_text: string | null
  session_id: string | null
  is_public: boolean
  created_at: string
  updated_at: string
}

export interface UserReviewInsert {
  reviewer_id: string
  reviewee_id: string
  rating: number
  review_text?: string | null
  session_id?: string | null
  is_public?: boolean
}

// ============================================================

export interface Group {
  id: string
  name: string
  slug: string
  description: string | null
  avatar_url: string | null
  banner_url: string | null
  city: string | null
  state_province: string | null
  country: string | null
  location: unknown | null
  is_public: boolean
  is_active: boolean
  max_members: number | null
  requires_approval: boolean
  member_count: number
  created_by: string
  created_at: string
  updated_at: string
}

export interface GroupInsert {
  name: string
  slug: string
  description?: string | null
  avatar_url?: string | null
  banner_url?: string | null
  city?: string | null
  state_province?: string | null
  country?: string | null
  location?: unknown | null
  is_public?: boolean
  max_members?: number | null
  requires_approval?: boolean
  created_by: string
}

// ============================================================

export interface GroupMember {
  id: string
  group_id: string
  user_id: string
  role: GroupRole
  joined_at: string
  invited_by: string | null
}

export interface GroupMemberInsert {
  group_id: string
  user_id: string
  role?: GroupRole
  invited_by?: string | null
}

// ============================================================

export interface Event {
  id: string
  title: string
  description: string | null
  status: EventStatus
  organizer_id: string
  group_id: string | null
  game_id: string | null
  game_name: string | null
  starts_at: string
  ends_at: string | null
  timezone: string
  is_recurring: boolean
  recurrence_rule: string | null
  min_players: number
  max_players: number | null
  current_player_count: number
  waitlist_enabled: boolean
  waitlist_count: number
  venue_name: string | null
  venue_address: string | null
  city: string | null
  state_province: string | null
  country: string | null
  location: unknown | null
  is_online: boolean
  online_platform: string | null
  meeting_url: string | null
  experience_required: ExperienceLevel | null
  cost_per_player: number
  supplies_needed: string | null
  notes: string | null
  created_at: string
  updated_at: string
}

export interface EventInsert {
  title: string
  description?: string | null
  status?: EventStatus
  organizer_id: string
  group_id?: string | null
  game_id?: string | null
  game_name?: string | null
  starts_at: string
  ends_at?: string | null
  timezone?: string
  is_recurring?: boolean
  recurrence_rule?: string | null
  min_players?: number
  max_players?: number | null
  waitlist_enabled?: boolean
  venue_name?: string | null
  venue_address?: string | null
  city?: string | null
  state_province?: string | null
  country?: string | null
  location?: unknown | null
  is_online?: boolean
  online_platform?: string | null
  meeting_url?: string | null
  experience_required?: ExperienceLevel | null
  cost_per_player?: number
  supplies_needed?: string | null
  notes?: string | null
}

// ============================================================

export interface EventRsvp {
  id: string
  event_id: string
  user_id: string
  status: RsvpStatus
  waitlist_position: number | null
  notes: string | null
  responded_at: string
  created_at: string
  updated_at: string
}

export interface EventRsvpInsert {
  event_id: string
  user_id: string
  status?: RsvpStatus
  notes?: string | null
}

// ============================================================

export interface LfgPost {
  id: string
  user_id: string
  title: string
  description: string | null
  game_id: string | null
  game_name: string | null
  experience_required: ExperienceLevel | null
  players_needed: number
  preferred_days: AvailabilityDay[] | null
  city: string | null
  state_province: string | null
  country: string | null
  location: unknown | null
  is_online: boolean
  is_active: boolean
  expires_at: string | null
  created_at: string
  updated_at: string
}

export interface LfgPostInsert {
  user_id: string
  title: string
  description?: string | null
  game_id?: string | null
  game_name?: string | null
  experience_required?: ExperienceLevel | null
  players_needed?: number
  preferred_days?: AvailabilityDay[] | null
  city?: string | null
  state_province?: string | null
  country?: string | null
  location?: unknown | null
  is_online?: boolean
  expires_at?: string | null
}

// ============================================================

export interface Conversation {
  id: string
  type: MessageType
  group_id: string | null
  event_id: string | null
  title: string | null
  created_by: string
  last_message_at: string | null
  created_at: string
  updated_at: string
}

export interface ConversationInsert {
  type: MessageType
  group_id?: string | null
  event_id?: string | null
  title?: string | null
  created_by: string
}

// ============================================================

export interface ConversationParticipant {
  id: string
  conversation_id: string
  user_id: string
  last_read_at: string | null
  is_muted: boolean
  joined_at: string
}

export interface ConversationParticipantInsert {
  conversation_id: string
  user_id: string
  last_read_at?: string | null
  is_muted?: boolean
}

// ============================================================

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  content: string
  is_edited: boolean
  is_deleted: boolean
  reply_to_id: string | null
  created_at: string
  updated_at: string
}

export interface MessageInsert {
  conversation_id: string
  sender_id: string
  content: string
  reply_to_id?: string | null
}

// ============================================================

export interface Notification {
  id: string
  user_id: string
  type: NotificationType
  title: string
  body: string | null
  data: Record<string, unknown>
  is_read: boolean
  read_at: string | null
  created_at: string
}

export interface NotificationInsert {
  user_id: string
  type: NotificationType
  title: string
  body?: string | null
  data?: Record<string, unknown>
}

// ============================================================

export interface UserBlock {
  id: string
  blocker_id: string
  blocked_id: string
  created_at: string
}

export interface UserConnection {
  id: string
  requester_id: string
  addressee_id: string
  is_accepted: boolean
  accepted_at: string | null
  created_at: string
}

// ============================================================
// VIEW TYPES
// ============================================================

export interface PublicProfile {
  id: string
  username: string
  display_name: string
  bio: string | null
  avatar_url: string | null
  website: string | null
  city: string | null
  state_province: string | null
  country: string | null
  is_active: boolean
  last_seen_at: string | null
  created_at: string
  experience_level: ExperienceLevel | null
  looking_for_group: boolean | null
  willing_to_teach: boolean | null
  avg_rating: number
  review_count: number
}

export interface UpcomingEvent {
  id: string
  title: string
  description: string | null
  starts_at: string
  ends_at: string | null
  timezone: string
  venue_name: string | null
  venue_address: string | null
  city: string | null
  state_province: string | null
  country: string | null
  location: unknown | null
  is_online: boolean
  online_platform: string | null
  min_players: number
  max_players: number | null
  current_player_count: number
  waitlist_count: number
  waitlist_enabled: boolean
  cost_per_player: number
  experience_required: ExperienceLevel | null
  game_name: string | null
  game_thumbnail: string | null
  game_min_players: number | null
  game_max_players: number | null
  organizer_username: string
  organizer_display_name: string
  organizer_avatar_url: string | null
  group_name: string | null
  group_slug: string | null
  created_at: string
}

export interface ActiveLfgPost {
  id: string
  title: string
  description: string | null
  players_needed: number
  experience_required: ExperienceLevel | null
  preferred_days: AvailabilityDay[] | null
  city: string | null
  state_province: string | null
  country: string | null
  location: unknown | null
  is_online: boolean
  expires_at: string | null
  created_at: string
  game_name: string | null
  game_thumbnail: string | null
  username: string
  display_name: string
  avatar_url: string | null
  poster_experience_level: ExperienceLevel | null
}

export interface UserGameLibraryItem {
  user_id: string
  status: CollectionStatus
  willing_to_lend: boolean
  notes: string | null
  condition: string | null
  game_id: string
  game_name: string
  bgg_id: number | null
  thumbnail_url: string | null
  min_players: number | null
  max_players: number | null
  min_playtime_minutes: number | null
  max_playtime_minutes: number | null
  complexity_rating: number | null
  average_rating: number | null
  genres: GameGenre[] | null
  created_at: string
}

// ============================================================
// RPC FUNCTION RETURN TYPES
// ============================================================

export interface NearbyUser {
  user_id: string
  username: string
  display_name: string
  avatar_url: string | null
  distance_km: number
}

export interface NearbyEvent {
  event_id: string
  title: string
  starts_at: string
  game_name: string | null
  organizer_display_name: string
  current_players: number
  max_players: number | null
  distance_km: number | null
}

export interface UserStats {
  games_owned: number
  games_wishlist: number
  events_hosted: number
  events_attended: number
  groups_joined: number
  avg_rating: number | null
  review_count: number
  connections: number
}

// ============================================================
// SUPABASE DATABASE TYPE DEFINITION
// For use with createClient<Database>()
// ============================================================

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile
        Insert: ProfileInsert
        Update: ProfileUpdate
      }
      gaming_preferences: {
        Row: GamingPreferences
        Insert: { user_id: string } & Partial<GamingPreferences>
        Update: GamingPreferencesUpdate
      }
      user_preferred_genres: {
        Row: UserPreferredGenre
        Insert: { user_id: string; genre: GameGenre }
        Update: never
      }
      games: {
        Row: Game
        Insert: GameInsert
        Update: Partial<GameInsert>
      }
      user_game_collection: {
        Row: UserGameCollection
        Insert: UserGameCollectionInsert
        Update: Partial<UserGameCollectionInsert>
      }
      user_reviews: {
        Row: UserReview
        Insert: UserReviewInsert
        Update: Partial<UserReviewInsert>
      }
      groups: {
        Row: Group
        Insert: GroupInsert
        Update: Partial<GroupInsert>
      }
      group_members: {
        Row: GroupMember
        Insert: GroupMemberInsert
        Update: { role?: GroupRole }
      }
      events: {
        Row: Event
        Insert: EventInsert
        Update: Partial<EventInsert>
      }
      event_rsvps: {
        Row: EventRsvp
        Insert: EventRsvpInsert
        Update: { status?: RsvpStatus; notes?: string | null }
      }
      lfg_posts: {
        Row: LfgPost
        Insert: LfgPostInsert
        Update: Partial<LfgPostInsert>
      }
      conversations: {
        Row: Conversation
        Insert: ConversationInsert
        Update: Partial<ConversationInsert>
      }
      conversation_participants: {
        Row: ConversationParticipant
        Insert: ConversationParticipantInsert
        Update: { last_read_at?: string | null; is_muted?: boolean }
      }
      messages: {
        Row: Message
        Insert: MessageInsert
        Update: { content?: string; is_edited?: boolean; is_deleted?: boolean }
      }
      notifications: {
        Row: Notification
        Insert: NotificationInsert
        Update: { is_read?: boolean; read_at?: string | null }
      }
      user_blocks: {
        Row: UserBlock
        Insert: { blocker_id: string; blocked_id: string }
        Update: never
      }
      user_connections: {
        Row: UserConnection
        Insert: { requester_id: string; addressee_id: string }
        Update: { is_accepted?: boolean; accepted_at?: string | null }
      }
    }
    Views: {
      public_profiles: {
        Row: PublicProfile
      }
      upcoming_events: {
        Row: UpcomingEvent
      }
      active_lfg_posts: {
        Row: ActiveLfgPost
      }
      user_game_library: {
        Row: UserGameLibraryItem
      }
    }
    Functions: {
      find_nearby_users: {
        Args: { p_user_id: string; p_radius_km?: number }
        Returns: NearbyUser[]
      }
      find_nearby_events: {
        Args: {
          p_user_id: string
          p_radius_km?: number
          p_from_date?: string
        }
        Returns: NearbyEvent[]
      }
      get_user_stats: {
        Args: { p_user_id: string }
        Returns: UserStats
      }
    }
    Enums: {
      experience_level: ExperienceLevel
      game_genre: GameGenre
      availability_day: AvailabilityDay
      group_role: GroupRole
      event_status: EventStatus
      rsvp_status: RsvpStatus
      message_type: MessageType
      collection_status: CollectionStatus
      notification_type: NotificationType
    }
  }
}
