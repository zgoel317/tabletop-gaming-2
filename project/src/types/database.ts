export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert';

export type GameGenre = 
  | 'strategy'
  | 'cooperative'
  | 'party'
  | 'rpg'
  | 'deck_building'
  | 'miniatures'
  | 'war_games'
  | 'card_games'
  | 'dice_games'
  | 'word_games'
  | 'trivia'
  | 'other';

export type PlayStyle = 'casual' | 'competitive' | 'narrative' | 'social';

export type CollectionStatus = 'owned' | 'wishlist' | 'previously_owned' | 'want_to_play';

export type DayOfWeek = 
  | 'monday'
  | 'tuesday'
  | 'wednesday'
  | 'thursday'
  | 'friday'
  | 'saturday'
  | 'sunday';

export interface Profile {
  id: string;
  username: string;
  display_name: string | null;
  bio: string | null;
  avatar_url: string | null;
  location_text: string | null;
  latitude: number | null;
  longitude: number | null;
  experience_level: ExperienceLevel;
  is_looking_for_group: boolean;
  created_at: string;
  updated_at: string;
}

export interface GamingPreferences {
  id: string;
  user_id: string;
  favorite_genres: GameGenre[];
  preferred_play_styles: PlayStyle[];
  min_players: number | null;
  max_players: number | null;
  preferred_session_length_minutes: number | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface GameCollectionItem {
  id: string;
  user_id: string;
  game_name: string;
  bgg_id: number | null;
  status: CollectionStatus;
  rating: number | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface Availability {
  id: string;
  user_id: string;
  day_of_week: DayOfWeek | null;
  specific_date: string | null;
  start_time: string;
  end_time: string;
  is_recurring: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserRating {
  id: string;
  reviewer_id: string;
  reviewed_id: string;
  rating: number;
  review_text: string | null;
  session_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Omit<Profile, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Profile>;
      };
      gaming_preferences: {
        Row: GamingPreferences;
        Insert: Omit<GamingPreferences, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<GamingPreferences>;
      };
      game_collection: {
        Row: GameCollectionItem;
        Insert: Omit<GameCollectionItem, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<GameCollectionItem>;
      };
      availability: {
        Row: Availability;
        Insert: Omit<Availability, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Availability>;
      };
      user_ratings: {
        Row: UserRating;
        Insert: Omit<UserRating, 'id' | 'created_at' | 'updated_at'> & {
          id?: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<UserRating>;
      };
    };
  };
}
