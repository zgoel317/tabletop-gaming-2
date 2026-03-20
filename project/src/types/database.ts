/**
 * TypeScript types generated from the Supabase database schema.
 * These types provide full type safety for all database operations.
 */

// ============================================================
// ENUMS
// ============================================================

export type ExperienceLevel =
  | 'beginner'
  | 'casual'
  | 'intermediate'
  | 'advanced'
  | 'expert';

export type GameGenre =
  | 'strategy'
  | 'worker_placement'
  | 'deck_building'
  | 'cooperative'
  | 'competitive'
  | 'party'
  | 'rpg'
  | 'war_game'
  | 'euro_game'
  | 'ameritrash'
  | 'abstract'
  | 'trivia'
  | 'social_deduction'
  | 'dungeon_crawler'
  | 'legacy'
  | 'puzzle'
  | 'family'
  | 'filler'
  | 'thematic'
  | 'train_game';

export type CollectionStatus =
  | 'own'
  | 'wishlist'
  | 'previously_owned'
  | 'want_to_play'
  | 'for_trade';

export type AvailabilityDay =
  | 'monday'
  | 'tuesday'
  | 'wednesday'
  | 'thursday'
  | 'friday'
  | 'saturday'
  | 'sunday';

export type AvailabilityTime =
  | 'morning'
  | 'afternoon'
  | 'evening'
  | 'night';

// ============================================================
// DATABASE ROW TYPES
// ============================================================

export interface Profile {
  id: string;
  username: string;
  display_name: string | null;
  bio: string | null;
  avatar_url: string | null;
  banner_url: string | null;
  city: string | null;
  state: string | null;
  country: string | null;
  postal_code: string | null;
  latitude: number | null;
  longitude: number | null;
  location_point: unknown | null; // PostGIS geography type
  location_public: boolean;
  experience_level: ExperienceLevel;
  preferred_player_count_min: number | null;
  preferred_player_count_max: number | null;
  preferred_session_length_hours: number | null;
  is_public: boolean;
  is_looking_for_group: boolean;
  show_email: boolean;
  created_at: string;
  updated_at: string;
}

export interface GamingPreference {
  id: string;
  profile_id: string;
  genre: GameGenre;
  preference_weight: number; // 1-5
  created_at: string;
}

export interface Game {
  id: string;
  bgg_id: number | null;
  name: string;
  description: string | null;
  thumbnail_url: string | null;
  image_url: string | null;
  min_players: number | null;
  max_players: number | null;
  min_playtime_minutes: number | null;
  max_playtime_minutes: number | null;
  min_age: number | null;
  complexity_rating: number | null;
  bgg_rating: number | null;
  year_published: number | null;
  is_expansion: boolean;
  categories: string[] | null;
  mechanics: string[] | null;
  designers: string[] | null;
  publishers: string[] | null;
  created_at: string;
  updated_at: string;
}

export interface UserGameCollection {
  id: string;
  profile_id: string;
  game_id: string;
  status: CollectionStatus;
  personal_rating: number | null; // 1-10
  play_count: number;
  notes: string | null;
  acquired_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface FavoriteGame {
  id: string;
  profile_id: string;
  game_id: string;
  display_order: number;
  created_at: string;
}

export interface UserAvailability {
  id: string;
  profile_id: string;
  day_of_week: AvailabilityDay;
  time_of_day: AvailabilityTime;
  created_at: string;
}

export interface UserRating {
  id: string;
  rater_id: string;
  rated_id: string;
  rating: number; // 1-5
  review: string | null;
  is_public: boolean;
  created_at: string;
  updated_at: string;
}

// ============================================================
// VIEW TYPES
// ============================================================

export interface ProfileStats {
  profile_id: string;
  games_owned: number;
  games_wishlisted: number;
  favorite_games_count: number;
  average_rating: number | null;
  total_ratings_received: number;
  genre_preferences_count: number;
}

// ============================================================
// INSERT TYPES (omit auto-generated fields)
// ============================================================

export type ProfileInsert = Omit<Profile, 'created_at' | 'updated_at' | 'location_point'>;

export type ProfileUpdate = Partial<
  Omit<Profile, 'id' | 'created_at' | 'updated_at' | 'location_point'>
>;

export type GamingPreferenceInsert = Omit<GamingPreference, 'id' | 'created_at'>;

export type GamingPreferenceUpdate = Partial<
  Omit<GamingPreference, 'id' | 'profile_id' | 'created_at'>
>;

export type GameInsert = Omit<Game, 'id' | 'created_at' | 'updated_at'>;

export type GameUpdate = Partial<Omit<Game, 'id' | 'created_at' | 'updated_at'>>;

export type UserGameCollectionInsert = Omit<
  UserGameCollection,
  'id' | 'created_at' | 'updated_at'
>;

export type UserGameCollectionUpdate = Partial<
  Omit<UserGameCollection, 'id' | 'profile_id' | 'game_id' | 'created_at' | 'updated_at'>
>;

export type FavoriteGameInsert = Omit<FavoriteGame, 'id' | 'created_at'>;

export type FavoriteGameUpdate = Partial<Omit<FavoriteGame, 'id' | 'profile_id' | 'game_id' | 'created_at'>>;

export type UserAvailabilityInsert = Omit<UserAvailability, 'id' | 'created_at'>;

export type UserRatingInsert = Omit<UserRating, 'id' | 'created_at' | 'updated_at'>;

export type UserRatingUpdate = Partial<
  Omit<UserRating, 'id' | 'rater_id' | 'rated_id' | 'created_at' | 'updated_at'>
>;

// ============================================================
// COMPOSITE / JOIN TYPES
// ============================================================

/** Full profile with all related data, returned by get_profile_with_details() */
export interface ProfileWithDetails {
  profile: Profile;
  stats: ProfileStats;
  gaming_preferences: GamingPreference[] | null;
  favorite_games: Array<{
    id: string;
    display_order: number;
    game: Game;
  }> | null;
  availability: UserAvailability[] | null;
  recent_ratings: Array<{
    id: string;
    rating: number;
    review: string | null;
    created_at: string;
    rater: Pick<Profile, 'id' | 'username' | 'display_name' | 'avatar_url'>;
  }> | null;
}

/** Nearby player result from get_nearby_players() */
export interface NearbyPlayer {
  id: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  experience_level: ExperienceLevel;
  is_looking_for_group: boolean;
  distance_km: number;
  average_rating: number | null;
  city: string | null;
  state: string | null;
  country: string | null;
}

/** Search result from search_players() */
export interface PlayerSearchResult {
  id: string;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  experience_level: ExperienceLevel;
  is_looking_for_group: boolean;
  similarity_score: number;
  average_rating: number | null;
  city: string | null;
  state: string | null;
  country: string | null;
}

/** Game collection entry with joined game data */
export interface CollectionEntryWithGame extends UserGameCollection {
  game: Game;
}

/** User rating with rater profile data */
export interface RatingWithRater extends UserRating {
  rater: Pick<Profile, 'id' | 'username' | 'display_name' | 'avatar_url'>;
}

// ============================================================
// SUPABASE DATABASE TYPE DEFINITION
// ============================================================

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: ProfileInsert;
        Update: ProfileUpdate;
      };
      gaming_preferences: {
        Row: GamingPreference;
        Insert: GamingPreferenceInsert;
        Update: GamingPreferenceUpdate;
      };
      games: {
        Row: Game;
        Insert: GameInsert;
        Update: GameUpdate;
      };
      user_game_collection: {
        Row: UserGameCollection;
        Insert: UserGameCollectionInsert;
        Update: UserGameCollectionUpdate;
      };
      favorite_games: {
        Row: FavoriteGame;
        Insert: FavoriteGameInsert;
        Update: FavoriteGameUpdate;
      };
      user_availability: {
        Row: UserAvailability;
        Insert: UserAvailabilityInsert;
        Update: Partial<Omit<UserAvailability, 'id' | 'profile_id' | 'created_at'>>;
      };
      user_ratings: {
        Row: UserRating;
        Insert: UserRatingInsert;
        Update: UserRatingUpdate;
      };
    };
    Views: {
      profile_stats: {
        Row: ProfileStats;
      };
    };
    Functions: {
      get_nearby_players: {
        Args: {
          lat: number;
          lng: number;
          radius_km?: number;
          result_limit?: number;
          result_offset?: number;
        };
        Returns: NearbyPlayer[];
      };
      search_players: {
        Args: {
          search_query: string;
          result_limit?: number;
          result_offset?: number;
        };
        Returns: PlayerSearchResult[];
      };
      get_profile_with_details: {
        Args: { target_profile_id: string };
        Returns: ProfileWithDetails;
      };
    };
    Enums: {
      experience_level: ExperienceLevel;
      game_genre: GameGenre;
      collection_status: CollectionStatus;
      availability_day: AvailabilityDay;
      availability_time: AvailabilityTime;
    };
  };
}
