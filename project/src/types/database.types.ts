/**
 * TypeScript type definitions generated from the Supabase database schema.
 * These types correspond to the tables defined in the migrations.
 */

// ============================================================
// ENUM TYPES
// ============================================================

export type ExperienceLevel =
  | 'beginner'
  | 'casual'
  | 'intermediate'
  | 'experienced'
  | 'expert';

export type GameGenre =
  | 'strategy'
  | 'worker_placement'
  | 'deck_building'
  | 'cooperative'
  | 'competitive'
  | 'party'
  | 'role_playing'
  | 'war_game'
  | 'euro_game'
  | 'thematic'
  | 'abstract'
  | 'family'
  | 'trivia'
  | 'dexterity'
  | 'social_deduction'
  | 'legacy'
  | 'dungeon_crawl'
  | 'engine_building'
  | 'area_control'
  | 'push_your_luck';

export type CollectionStatus =
  | 'owned'
  | 'wishlist'
  | 'previously_owned'
  | 'want_to_play';

export type AvailabilityDay =
  | 'monday'
  | 'tuesday'
  | 'wednesday'
  | 'thursday'
  | 'friday'
  | 'saturday'
  | 'sunday';

export type AvailabilityTime = 'morning' | 'afternoon' | 'evening' | 'night';

export type ConnectionStatus = 'following' | 'connected' | 'blocked';

export type MessagePermission = 'all' | 'connections' | 'none';

export type PlayFrequency =
  | 'daily'
  | 'multiple_per_week'
  | 'weekly'
  | 'biweekly'
  | 'monthly'
  | 'occasional';

// ============================================================
// TABLE ROW TYPES
// ============================================================

export interface Profile {
  id: string;
  username: string;
  display_name: string;
  bio: string | null;
  avatar_url: string | null;
  website_url: string | null;

  // Location
  city: string | null;
  state_province: string | null;
  country: string;
  postal_code: string | null;
  location: unknown | null; // PostGIS Geography type
  max_travel_distance_km: number;
  show_exact_location: boolean;

  // Gaming info
  experience_level: ExperienceLevel;
  years_gaming: number | null;
  languages: string[];

  // Social links
  bgg_username: string | null;
  discord_username: string | null;

  // Preferences
  is_profile_public: boolean;
  is_looking_for_group: boolean;
  allow_messages_from: MessagePermission;
  notification_email: boolean;
  notification_push: boolean;
  notification_in_app: boolean;

  // Metadata
  last_active_at: string | null;
  onboarding_completed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface GamingPreferences {
  id: string;
  profile_id: string;

  preferred_genres: GameGenre[];

  min_players_preferred: number;
  max_players_preferred: number;

  preferred_session_length_min: number | null;
  preferred_session_length_max: number | null;
  preferred_frequency: PlayFrequency | null;

  min_complexity: number;
  max_complexity: number;

  prefers_competitive: boolean;
  prefers_cooperative: boolean;
  prefers_team_games: boolean;
  prefers_solo_capable: boolean;
  open_to_teaching: boolean;
  open_to_being_taught: boolean;
  comfortable_with_mature_themes: boolean;

  created_at: string;
  updated_at: string;
}

export interface AvailabilitySlot {
  id: string;
  profile_id: string;
  day_of_week: AvailabilityDay;
  time_of_day: AvailabilityTime;
  is_available: boolean;
  created_at: string;
  updated_at: string;
}

export interface Game {
  id: string;
  bgg_id: number | null;

  name: string;
  description: string | null;
  thumbnail_url: string | null;
  image_url: string | null;

  year_published: number | null;
  min_players: number | null;
  max_players: number | null;
  min_playtime: number | null;
  max_playtime: number | null;
  min_age: number | null;
  complexity_rating: number | null;
  average_rating: number | null;

  genres: GameGenre[];
  categories: string[];
  mechanics: string[];
  designers: string[];
  publishers: string[];

  is_expansion: boolean;
  base_game_id: string | null;

  search_vector: unknown | null; // TSVector type
  created_at: string;
  updated_at: string;
}

export interface UserGameCollection {
  id: string;
  profile_id: string;
  game_id: string;

  status: CollectionStatus;
  user_rating: number | null;
  review: string | null;
  play_count: number;
  willing_to_bring: boolean;
  willing_to_teach: boolean;
  notes: string | null;

  acquired_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserFavoriteGame {
  id: string;
  profile_id: string;
  game_id: string;
  sort_order: number;
  created_at: string;
}

export interface UserRating {
  id: string;
  rater_id: string;
  rated_id: string;

  rating: number;
  review: string | null;

  reliability_rating: number | null;
  sportsmanship_rating: number | null;
  rules_knowledge_rating: number | null;
  fun_factor_rating: number | null;

  event_id: string | null;
  is_public: boolean;

  created_at: string;
  updated_at: string;
}

export interface UserConnection {
  id: string;
  follower_id: string;
  following_id: string;
  status: ConnectionStatus;
  created_at: string;
}

export interface ProfileView {
  id: string;
  viewed_profile_id: string;
  viewer_id: string | null;
  viewer_ip_hash: string | null;
  viewed_at: string;
}

// ============================================================
// VIEW TYPES
// ============================================================

export interface ProfileSummary {
  id: string;
  username: string;
  display_name: string;
  bio: string | null;
  avatar_url: string | null;
  city: string | null;
  state_province: string | null;
  country: string;
  experience_level: ExperienceLevel;
  is_looking_for_group: boolean;
  last_active_at: string | null;
  created_at: string;
  average_rating: number;
  rating_count: number;
  owned_games_count: number;
  wishlist_games_count: number;
  follower_count: number;
  following_count: number;
}

export interface GamePopularity extends Game {
  owner_count: number;
  wishlist_count: number;
  want_to_play_count: number;
  favorite_count: number;
  avg_user_rating: number;
}

export interface UserAvailabilitySummary {
  profile_id: string;
  username: string;
  display_name: string;
  available_days: AvailabilityDay[] | null;
  available_times: AvailabilityTime[] | null;
  available_slot_count: number;
}

export interface UserGamingProfile {
  profile_id: string;
  username: string;
  display_name: string;
  experience_level: ExperienceLevel;
  preferred_genres: GameGenre[];
  min_players_preferred: number;
  max_players_preferred: number;
  preferred_session_length_min: number | null;
  preferred_session_length_max: number | null;
  preferred_frequency: PlayFrequency | null;
  min_complexity: number;
  max_complexity: number;
  prefers_competitive: boolean;
  prefers_cooperative: boolean;
  open_to_teaching: boolean;
  open_to_being_taught: boolean;
  favorite_game_names: string[];
}

// ============================================================
// SUPABASE DATABASE TYPE (for createClient generics)
// ============================================================

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Omit<Profile, 'created_at' | 'updated_at'> &
          Partial<Pick<Profile, 'created_at' | 'updated_at'>>;
        Update: Partial<Omit<Profile, 'id'>>;
      };
      gaming_preferences: {
        Row: GamingPreferences;
        Insert: Omit<GamingPreferences, 'id' | 'created_at' | 'updated_at'> &
          Partial<Pick<GamingPreferences, 'id' | 'created_at' | 'updated_at'>>;
        Update: Partial<Omit<GamingPreferences, 'id' | 'profile_id'>>;
      };
      availability_slots: {
        Row: AvailabilitySlot;
        Insert: Omit<AvailabilitySlot, 'id' | 'created_at' | 'updated_at'> &
          Partial<Pick<AvailabilitySlot, 'id' | 'created_at' | 'updated_at'>>;
        Update: Partial<Omit<AvailabilitySlot, 'id' | 'profile_id'>>;
      };
      games: {
        Row: Game;
        Insert: Omit<Game, 'id' | 'created_at' | 'updated_at' | 'search_vector'> &
          Partial<Pick<Game, 'id' | 'created_at' | 'updated_at' | 'search_vector'>>;
        Update: Partial<Omit<Game, 'id'>>;
      };
      user_game_collections: {
        Row: UserGameCollection;
        Insert: Omit<UserGameCollection, 'id' | 'created_at' | 'updated_at'> &
          Partial<Pick<UserGameCollection, 'id' | 'created_at' | 'updated_at'>>;
        Update: Partial<Omit<UserGameCollection, 'id' | 'profile_id' | 'game_id'>>;
      };
      user_favorite_games: {
        Row: UserFavoriteGame;
        Insert: Omit<UserFavoriteGame, 'id' | 'created_at'> &
          Partial<Pick<UserFavoriteGame, 'id' | 'created_at'>>;
        Update: Partial<Pick<UserFavoriteGame, 'sort_order'>>;
      };
      user_ratings: {
        Row: UserRating;
        Insert: Omit<UserRating, 'id' | 'created_at' | 'updated_at'> &
          Partial<Pick<UserRating, 'id' | 'created_at' | 'updated_at'>>;
        Update: Partial<Omit<UserRating, 'id' | 'rater_id' | 'rated_id'>>;
      };
      user_connections: {
        Row: UserConnection;
        Insert: Omit<UserConnection, 'id' | 'created_at'> &
          Partial<Pick<UserConnection, 'id' | 'created_at'>>;
        Update: Partial<Pick<UserConnection, 'status'>>;
      };
      profile_views: {
        Row: ProfileView;
        Insert: Omit<ProfileView, 'id' | 'viewed_at'> &
          Partial<Pick<ProfileView, 'id' | 'viewed_at'>>;
        Update: never;
      };
    };
    Views: {
      profile_summaries: {
        Row: ProfileSummary;
      };
      game_popularity: {
        Row: GamePopularity;
      };
      user_availability_summary: {
        Row: UserAvailabilitySummary;
      };
      user_gaming_profile: {
        Row: UserGamingProfile;
      };
    };
    Functions: {
      find_nearby_profiles: {
        Args: {
          lat: number;
          lng: number;
          radius_km?: number;
          limit_count?: number;
          offset_count?: number;
        };
        Returns: Array<{ profile_id: string; distance_km: number }>;
      };
      get_user_average_rating: {
        Args: { user_id: string };
        Returns: number;
      };
      get_user_rating_count: {
        Args: { user_id: string };
        Returns: number;
      };
      update_user_last_active: {
        Args: { user_id: string };
        Returns: void;
      };
      is_profile_public: {
        Args: { profile_id: string };
        Returns: boolean;
      };
      is_connected_to: {
        Args: { other_user_id: string };
        Returns: boolean;
      };
      is_blocked_by: {
        Args: { other_user_id: string };
        Returns: boolean;
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
