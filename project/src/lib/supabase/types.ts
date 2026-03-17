/**
 * TypeScript types derived from the Supabase database schema.
 * These are hand-maintained companions to the migration files.
 * For production use, generate these automatically with:
 *   npx supabase gen types typescript --project-id <id> > src/lib/supabase/types.ts
 */

// ============================================================
// ENUMS
// ============================================================

export type UserRole = 'user' | 'admin' | 'moderator'

export type ExperienceLevel =
  | 'newcomer'
  | 'beginner'
  | 'intermediate'
  | 'advanced'
  | 'expert'

export type GameGenre =
  | 'strategy'
  | 'euro'
  | 'thematic'
  | 'abstract'
  | 'party'
  | 'cooperative'
  | 'deck_building'
  | 'worker_placement'
  | 'area_control'
  | 'roll_and_write'
  | 'push_your_luck'
  | 'social_deduction'
  | 'legacy'
  | 'wargame'
  | 'rpg'
  | 'other'

export type AvailabilityDay =
  | 'monday'
  | 'tuesday'
  | 'wednesday'
  | 'thursday'
  | 'friday'
  | 'saturday'
  | 'sunday'

export type AvailabilityTime = 'morning' | 'afternoon' | 'evening' | 'night'

export type CollectionStatus =
  | 'owned'
  | 'wishlist'
  | 'previously_owned'
  | 'want_to_play'

// ============================================================
// TABLE ROW TYPES
// ============================================================

export interface Profile {
  id: string
  username: string
  display_name: string | null
  bio: string | null
  avatar_url: string | null
  website_url: string | null

  // Location
  city: string | null
  state_province: string | null
  country: string
  postal_code: string | null
  /** PostGIS geography — returned as GeoJSON string from Supabase */
  location: string | null
  location_public: boolean

  // Gaming identity
  experience_level: ExperienceLevel
  preferred_player_count_min: number | null
  preferred_player_count_max: number | null

  // Availability
  available_days: AvailabilityDay[] | null
  available_times: AvailabilityTime[] | null

  // Social flags
  is_looking_for_group: boolean
  is_open_to_teach: boolean
  is_open_to_learn: boolean

  // Account
  role: UserRole
  is_active: boolean
  onboarding_completed: boolean

  // Stats
  total_sessions_played: number
  total_sessions_hosted: number
  average_rating: number | null
  total_ratings: number

  // Timestamps
  created_at: string
  updated_at: string
}

export interface GamingPreference {
  id: string
  profile_id: string
  genre: GameGenre
  /** 1 = dislike, 3 = neutral, 5 = love */
  preference_level: number
  created_at: string
}

export interface Game {
  id: string
  bgg_id: number | null
  name: string
  description: string | null
  thumbnail_url: string | null
  image_url: string | null

  min_players: number | null
  max_players: number | null
  min_playtime: number | null
  max_playtime: number | null
  min_age: number | null
  complexity_rating: number | null
  bgg_rating: number | null
  year_published: number | null

  genres: GameGenre[] | null
  categories: string[] | null
  mechanics: string[] | null
  designers: string[] | null
  publishers: string[] | null

  is_expansion: boolean
  base_game_id: string | null

  created_at: string
  updated_at: string
}

export interface UserGameCollection {
  id: string
  profile_id: string
  game_id: string
  status: CollectionStatus
  personal_rating: number | null
  notes: string | null
  times_played: number
  willing_to_bring: boolean
  created_at: string
  updated_at: string
}

export interface UserRating {
  id: string
  rater_id: string
  rated_id: string
  session_id: string | null
  rating: number
  comment: string | null
  created_at: string
  updated_at: string
}

export interface ProfileFollow {
  follower_id: string
  following_id: string
  created_at: string
}

// ============================================================
// VIEW TYPES
// ============================================================

export interface ProfileSummary {
  id: string
  username: string
  display_name: string | null
  avatar_url: string | null
  bio: string | null
  city: string | null
  state_province: string | null
  country: string
  experience_level: ExperienceLevel
  is_looking_for_group: boolean
  is_open_to_teach: boolean
  is_open_to_learn: boolean
  available_days: AvailabilityDay[] | null
  available_times: AvailabilityTime[] | null
  total_sessions_played: number
  total_sessions_hosted: number
  average_rating: number | null
  total_ratings: number
  created_at: string
  preferred_genres: GameGenre[]
}

export interface UserCollectionDetail
  extends Omit<UserGameCollection, 'game_id'> {
  game_id: string
  bgg_id: number | null
  game_name: string
  thumbnail_url: string | null
  min_players: number | null
  max_players: number | null
  min_playtime: number | null
  max_playtime: number | null
  complexity_rating: number | null
  bgg_rating: number | null
  game_genres: GameGenre[] | null
}

// ============================================================
// FUNCTION RETURN TYPES
// ============================================================

export interface NearbyProfile {
  id: string
  username: string
  display_name: string | null
  avatar_url: string | null
  bio: string | null
  experience_level: ExperienceLevel
  is_looking_for_group: boolean
  distance_km: number
  average_rating: number | null
  total_ratings: number
}

export interface ProfileSearchResult {
  id: string
  username: string
  display_name: string | null
  avatar_url: string | null
  similarity: number
}

export interface FollowCounts {
  followers: number
  following: number
}

// ============================================================
// INSERT / UPDATE HELPERS
// ============================================================

export type ProfileInsert = Omit<
  Profile,
  | 'role'
  | 'is_active'
  | 'onboarding_completed'
  | 'total_sessions_played'
  | 'total_sessions_hosted'
  | 'average_rating'
  | 'total_ratings'
  | 'created_at'
  | 'updated_at'
>

export type ProfileUpdate = Partial<
  Omit<Profile, 'id' | 'created_at' | 'updated_at' | 'role'>
>

export type GamingPreferenceInsert = Omit<GamingPreference, 'id' | 'created_at'>
export type GamingPreferenceUpdate = Pick<
  GamingPreference,
  'preference_level'
>

export type GameInsert = Omit<Game, 'id' | 'created_at' | 'updated_at'>
export type GameUpdate = Partial<Omit<Game, 'id' | 'created_at' | 'updated_at'>>

export type UserGameCollectionInsert = Omit<
  UserGameCollection,
  'id' | 'created_at' | 'updated_at'
>
export type UserGameCollectionUpdate = Partial<
  Omit<UserGameCollection, 'id' | 'profile_id' | 'game_id' | 'created_at' | 'updated_at'>
>

export type UserRatingInsert = Omit<UserRating, 'id' | 'created_at' | 'updated_at'>
export type UserRatingUpdate = Partial<Pick<UserRating, 'rating' | 'comment'>>

// ============================================================
// SUPABASE DATABASE SCHEMA TYPE
// (used when constructing the Supabase client)
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
        Row: GamingPreference
        Insert: GamingPreferenceInsert
        Update: GamingPreferenceUpdate
      }
      games: {
        Row: Game
        Insert: GameInsert
        Update: GameUpdate
      }
      user_game_collection: {
        Row: UserGameCollection
        Insert: UserGameCollectionInsert
        Update: UserGameCollectionUpdate
      }
      user_ratings: {
        Row: UserRating
        Insert: UserRatingInsert
        Update: UserRatingUpdate
      }
      profile_follows: {
        Row: ProfileFollow
        Insert: Omit<ProfileFollow, 'created_at'>
        Update: never
      }
    }
    Views: {
      profile_summaries: {
        Row: ProfileSummary
      }
      user_collection_details: {
        Row: UserCollectionDetail
      }
    }
    Functions: {
      find_nearby_profiles: {
        Args: {
          p_latitude: number
          p_longitude: number
          p_radius_km?: number
          p_limit?: number
          p_offset?: number
        }
        Returns: NearbyProfile[]
      }
      search_profiles: {
        Args: {
          p_query: string
          p_limit?: number
          p_offset?: number
        }
        Returns: ProfileSearchResult[]
      }
      get_follow_counts: {
        Args: { p_profile_id: string }
        Returns: FollowCounts[]
      }
      set_profile_location: {
        Args: {
          p_profile_id: string
          p_latitude: number
          p_longitude: number
        }
        Returns: void
      }
      upsert_gaming_preference: {
        Args: {
          p_genre: GameGenre
          p_preference_level?: number
        }
        Returns: GamingPreference
      }
      is_admin: {
        Args: Record<string, never>
        Returns: boolean
      }
    }
    Enums: {
      user_role: UserRole
      experience_level: ExperienceLevel
      game_genre: GameGenre
      availability_day: AvailabilityDay
      availability_time: AvailabilityTime
      collection_status: CollectionStatus
    }
  }
}
