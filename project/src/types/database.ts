// ============================================================
// Database Types — Tabletop Gaming Networking App
//
// These types mirror the Supabase PostgreSQL schema defined in
// supabase/migrations/001_initial_schema.sql
//
// Keep these in sync with the actual schema. Alternatively,
// run `npm run db:types` to auto-generate from a live schema
// and compare against this file.
// ============================================================

// ------------------------------------------------------------
// Enums
// ------------------------------------------------------------

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert';

export type CollectionType = 'owned' | 'wishlist' | 'played' | 'selling';

// ------------------------------------------------------------
// Table Row Types (snake_case matching DB columns)
// ------------------------------------------------------------

export interface Profile {
  id: string;
  username: string;
  full_name: string | null;
  bio: string | null;
  avatar_url: string | null;
  location_city: string | null;
  location_state: string | null;
  location_country: string;
  location_lat: number | null;
  location_lng: number | null;
  is_public: boolean;
  created_at: string;
  updated_at: string;
}

export interface GamingPreferences {
  id: string;
  user_id: string;
  experience_level: ExperienceLevel;
  preferred_genres: string[];
  favorite_games: string[];
  preferred_player_count_min: number;
  preferred_player_count_max: number;
  preferred_session_length_hours: number | null;
  availability_notes: string | null;
  willing_to_teach: boolean;
  willing_to_travel_miles: number;
  created_at: string;
  updated_at: string;
}

export interface GameCollection {
  id: string;
  user_id: string;
  bgg_game_id: number | null;
  game_name: string;
  game_image_url: string | null;
  collection_type: CollectionType;
  user_rating: number | null;
  notes: string | null;
  created_at: string;
}

export interface PlayerRating {
  id: string;
  rater_id: string;
  rated_id: string;
  rating: number;
  review_text: string | null;
  session_id: string | null;
  created_at: string;
  updated_at: string;
}

// ------------------------------------------------------------
// Insert Types
// Omit auto-generated fields (id, created_at, updated_at)
// The consuming code provides only the user-supplied fields.
// ------------------------------------------------------------

export type ProfileInsert = Omit<Profile, 'id' | 'created_at' | 'updated_at'>;

export type GamingPreferencesInsert = Omit<GamingPreferences, 'id' | 'created_at' | 'updated_at'>;

export type GameCollectionInsert = Omit<GameCollection, 'id' | 'created_at'>;

export type PlayerRatingInsert = Omit<PlayerRating, 'id' | 'created_at' | 'updated_at'>;

// ------------------------------------------------------------
// Update Types
// All fields optional; primary keys and owner ids are excluded
// since they should never change after creation.
// ------------------------------------------------------------

export type ProfileUpdate = Partial<ProfileInsert>;

/** user_id cannot be changed after creation */
export type GamingPreferencesUpdate = Partial<Omit<GamingPreferencesInsert, 'user_id'>>;

/** user_id cannot be changed after creation */
export type GameCollectionUpdate = Partial<Omit<GameCollectionInsert, 'user_id'>>;

/** rater_id and rated_id are immutable after creation */
export type PlayerRatingUpdate = Partial<Omit<PlayerRatingInsert, 'rater_id' | 'rated_id'>>;

// ------------------------------------------------------------
// Joined / Enriched Types Used in UI
// ------------------------------------------------------------

/** Profile with gaming preferences — used in player search results */
export interface ProfileWithPreferences extends Profile {
  gaming_preferences: GamingPreferences | null;
}

/** Profile with game collection — used on profile detail page */
export interface ProfileWithCollection extends Profile {
  game_collections: GameCollection[];
}

/** Fully hydrated profile — used on the full profile view */
export interface ProfileFull extends Profile {
  gaming_preferences: GamingPreferences | null;
  game_collections: GameCollection[];
  received_ratings: PlayerRating[];
  /** Mean of all received ratings (1–5), or null if no ratings yet */
  average_rating: number | null;
}

// ------------------------------------------------------------
// Supabase Database Generic Type
// Pass this to createClient<Database>() for full type inference
// on all table queries throughout the application.
// ------------------------------------------------------------

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: ProfileInsert & { id: string };
        Update: ProfileUpdate;
      };
      gaming_preferences: {
        Row: GamingPreferences;
        Insert: GamingPreferencesInsert;
        Update: GamingPreferencesUpdate;
      };
      game_collections: {
        Row: GameCollection;
        Insert: GameCollectionInsert;
        Update: GameCollectionUpdate;
      };
      player_ratings: {
        Row: PlayerRating;
        Insert: PlayerRatingInsert;
        Update: PlayerRatingUpdate;
      };
    };
  };
}
