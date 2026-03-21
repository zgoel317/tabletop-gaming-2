// ============================================================
// Database Types — Auto-mirrors the Supabase schema
// Provides end-to-end type safety for all database interactions
//
// Import pattern:
//   import type { Database, Profile, Game } from '@/types/database';
// ============================================================

// ============================================================
// ENUMS
// ============================================================

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert';

export type PlayerCountPreference = 'solo' | 'small_group' | 'medium_group' | 'large_group';

export type AvailabilityDay =
  | 'monday'
  | 'tuesday'
  | 'wednesday'
  | 'thursday'
  | 'friday'
  | 'saturday'
  | 'sunday';

export type GameCollectionStatus = 'owned' | 'wishlist' | 'previously_owned';

export type SessionStatus = 'scheduled' | 'cancelled' | 'completed';

export type RsvpStatus = 'going' | 'maybe' | 'not_going' | 'waitlisted';

export type GroupRole = 'organizer' | 'moderator' | 'member';

export type MessageType = 'direct' | 'group' | 'event';

// ============================================================
// ROW TYPES — match database column names exactly (snake_case)
// ============================================================

export interface Profile {
  id: string;
  username: string;
  display_name: string;
  bio: string | null;
  avatar_url: string | null;
  location_name: string | null;
  latitude: number | null;
  longitude: number | null;
  is_location_public: boolean;
  experience_level: ExperienceLevel;
  is_looking_for_group: boolean;
  created_at: string;
  updated_at: string;
}

export interface Game {
  id: string;
  bgg_id: number | null;
  name: string;
  description: string | null;
  min_players: number | null;
  max_players: number | null;
  average_playtime_minutes: number | null;
  image_url: string | null;
  thumbnail_url: string | null;
  year_published: number | null;
  created_at: string;
  updated_at: string;
}

export interface GameGenre {
  id: string;
  name: string;
  description: string | null;
  created_at: string;
}

export interface GameGenreMapping {
  game_id: string;
  genre_id: string;
}

export interface UserFavoriteGame {
  id: string;
  user_id: string;
  game_id: string;
  created_at: string;
}

export interface UserFavoriteGenre {
  id: string;
  user_id: string;
  genre_id: string;
}

export interface UserAvailability {
  id: string;
  user_id: string;
  day_of_week: AvailabilityDay;
  start_time: string; // TIME columns returned as "HH:MM:SS" strings
  end_time: string;
  created_at: string;
}

export interface GameCollection {
  id: string;
  user_id: string;
  game_id: string;
  status: GameCollectionStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserRating {
  id: string;
  rater_id: string;
  rated_user_id: string;
  rating: number;
  review: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================================
// INSERT TYPES
// id, created_at, updated_at are omitted (DB-generated).
// Optional fields use `?` to match nullable / defaulted columns.
// ============================================================

export interface ProfileInsert {
  id: string; // Must match auth.users.id
  username: string;
  display_name: string;
  bio?: string | null;
  avatar_url?: string | null;
  location_name?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  is_location_public?: boolean;
  experience_level?: ExperienceLevel;
  is_looking_for_group?: boolean;
}

export interface GameInsert {
  bgg_id?: number | null;
  name: string;
  description?: string | null;
  min_players?: number | null;
  max_players?: number | null;
  average_playtime_minutes?: number | null;
  image_url?: string | null;
  thumbnail_url?: string | null;
  year_published?: number | null;
}

export interface GameCollectionInsert {
  user_id: string;
  game_id: string;
  status?: GameCollectionStatus;
  notes?: string | null;
}

export interface UserRatingInsert {
  rater_id: string;
  rated_user_id: string;
  rating: number;
  review?: string | null;
}

export interface UserAvailabilityInsert {
  user_id: string;
  day_of_week: AvailabilityDay;
  start_time: string;
  end_time: string;
}

export interface UserFavoriteGameInsert {
  user_id: string;
  game_id: string;
}

export interface UserFavoriteGenreInsert {
  user_id: string;
  genre_id: string;
}

// ============================================================
// UPDATE TYPES — all fields Partial (id is excluded as it's immutable)
// ============================================================

export type ProfileUpdate = Partial<Omit<ProfileInsert, 'id'>>;

export type GameUpdate = Partial<GameInsert>;

export type GameCollectionUpdate = Partial<Omit<GameCollectionInsert, 'user_id' | 'game_id'>>;

export type UserRatingUpdate = Partial<Omit<UserRatingInsert, 'rater_id' | 'rated_user_id'>>;

// ============================================================
// JOINED / EXTENDED TYPES — for common query patterns
// ============================================================

/**
 * Full profile with all related data loaded.
 * Used for profile detail pages and player discovery.
 */
export interface ProfileWithDetails extends Profile {
  favorite_games: (UserFavoriteGame & { game: Game })[];
  favorite_genres: (UserFavoriteGenre & { genre: GameGenre })[];
  availability: UserAvailability[];
  game_collections: (GameCollection & { game: Game })[];
  average_rating: number | null;
  rating_count: number;
}

/**
 * Game with its associated genres loaded.
 */
export interface GameWithGenres extends Game {
  genres: GameGenre[];
}

// ============================================================
// DATABASE INTERFACE — for Supabase generic typing
// Pass this as the generic parameter to createClient<Database>()
// ============================================================

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: ProfileInsert;
        Update: ProfileUpdate;
      };
      games: {
        Row: Game;
        Insert: GameInsert;
        Update: GameUpdate;
      };
      game_genres: {
        Row: GameGenre;
        Insert: { name: string; description?: string | null };
        Update: Partial<Omit<GameGenre, 'id' | 'created_at'>>;
      };
      game_genre_mappings: {
        Row: GameGenreMapping;
        Insert: GameGenreMapping;
        Update: never;
      };
      user_favorite_games: {
        Row: UserFavoriteGame;
        Insert: UserFavoriteGameInsert;
        Update: never;
      };
      user_favorite_genres: {
        Row: UserFavoriteGenre;
        Insert: UserFavoriteGenreInsert;
        Update: never;
      };
      user_availability: {
        Row: UserAvailability;
        Insert: UserAvailabilityInsert;
        Update: Partial<UserAvailabilityInsert>;
      };
      game_collections: {
        Row: GameCollection;
        Insert: GameCollectionInsert;
        Update: GameCollectionUpdate;
      };
      user_ratings: {
        Row: UserRating;
        Insert: UserRatingInsert;
        Update: UserRatingUpdate;
      };
    };
    Enums: {
      experience_level: ExperienceLevel;
      player_count_preference: PlayerCountPreference;
      availability_day: AvailabilityDay;
      game_collection_status: GameCollectionStatus;
      session_status: SessionStatus;
      rsvp_status: RsvpStatus;
      group_role: GroupRole;
      message_type: MessageType;
    };
  };
}
