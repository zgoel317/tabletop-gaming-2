export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          email: string
          username: string | null
          full_name: string | null
          avatar_url: string | null
          bio: string | null
          location: string | null
          location_coords: unknown | null
          phone: string | null
          date_of_birth: string | null
          is_active: boolean
          last_seen: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          username?: string | null
          full_name?: string | null
          avatar_url?: string | null
          bio?: string | null
          location?: string | null
          location_coords?: unknown | null
          phone?: string | null
          date_of_birth?: string | null
          is_active?: boolean
          last_seen?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          username?: string | null
          full_name?: string | null
          avatar_url?: string | null
          bio?: string | null
          location?: string | null
          location_coords?: unknown | null
          phone?: string | null
          date_of_birth?: string | null
          is_active?: boolean
          last_seen?: string
          created_at?: string
          updated_at?: string
        }
      }
      gaming_preferences: {
        Row: {
          id: string
          user_id: string
          favorite_genres: string[] | null
          experience_level: 'beginner' | 'intermediate' | 'advanced' | 'expert'
          preferred_game_duration: number | null
          max_travel_distance: number | null
          preferred_group_size_min: number
          preferred_group_size_max: number
          availability_status: 'available' | 'busy' | 'away'
          notes: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          favorite_genres?: string[] | null
          experience_level?: 'beginner' | 'intermediate' | 'advanced' | 'expert'
          preferred_game_duration?: number | null
          max_travel_distance?: number | null
          preferred_group_size_min?: number
          preferred_group_size_max?: number
          availability_status?: 'available' | 'busy' | 'away'
          notes?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          favorite_genres?: string[] | null
          experience_level?: 'beginner' | 'intermediate' | 'advanced' | 'expert'
          preferred_game_duration?: number | null
          max_travel_distance?: number | null
          preferred_group_size_min?: number
          preferred_group_size_max?: number
          availability_status?: 'available' | 'busy' | 'away'
          notes?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      user_availability: {
        Row: {
          id: string
          user_id: string
          day_of_week: number
          start_time: string
          end_time: string
          is_available: boolean
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          day_of_week: number
          start_time: string
          end_time: string
          is_available?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          day_of_week?: number
          start_time?: string
          end_time?: string
          is_available?: boolean
          created_at?: string
        }
      }
      games: {
        Row: {
          id: string
          bgg_id: number | null
          name: string
          description: string | null
          min_players: number
          max_players: number
          min_age: number | null
          playing_time: number | null
          complexity_rating: number | null
          year_published: number | null
          image_url: string | null
          categories: string[] | null
          mechanics: string[] | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          bgg_id?: number | null
          name: string
          description?: string | null
          min_players?: number
          max_players?: number
          min_age?: number | null
          playing_time?: number | null
          complexity_rating?: number | null
          year_published?: number | null
          image_url?: string | null
          categories?: string[] | null
          mechanics?: string[] | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          bgg_id?: number | null
          name?: string
          description?: string | null
          min_players?: number
          max_players?: number
          min_age?: number | null
          playing_time?: number | null
          complexity_rating?: number | null
          year_published?: number | null
          image_url?: string | null
          categories?: string[] | null
          mechanics?: string[] | null
          created_at?: string
          updated_at?: string
        }
      }
      user_games: {
        Row: {
          id: string
          user_id: string
          game_id: string
          ownership_status: 'owned' | 'wishlist' | 'previously_owned'
          rating: number | null
          plays_count: number
          notes: string | null
          acquired_date: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          game_id: string
          ownership_status: 'owned' | 'wishlist' | 'previously_owned'
          rating?: number | null
          plays_count?: number
          notes?: string | null
          acquired_date?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          game_id?: string
          ownership_status?: 'owned' | 'wishlist' | 'previously_owned'
          rating?: number | null
          plays_count?: number
          notes?: string | null
          acquired_date?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      user_reviews: {
        Row: {
          id: string
          reviewer_id: string
          reviewee_id: string
          rating: number
          comment: string | null
          session_id: string | null
          is_anonymous: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          reviewer_id: string
          reviewee_id: string
          rating: number
          comment?: string | null
          session_id?: string | null
          is_anonymous?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          reviewer_id?: string
          reviewee_id?: string
          rating?: number
          comment?: string | null
          session_id?: string | null
          is_anonymous?: boolean
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {}
    Functions: {
      handle_new_user: {
        Args: {}
        Returns: unknown
      }
    }
    Enums: {
      experience_level: 'beginner' | 'intermediate' | 'advanced' | 'expert'
      availability_status: 'available' | 'busy' | 'away'
    }
  }
}

export type User = Database['public']['Tables']['users']['Row']
export type UserInsert = Database['public']['Tables']['users']['Insert']
export type UserUpdate = Database['public']['Tables']['users']['Update']

export type GamingPreferences = Database['public']['Tables']['gaming_preferences']['Row']
export type GamingPreferencesInsert = Database['public']['Tables']['gaming_preferences']['Insert']
export type GamingPreferencesUpdate = Database['public']['Tables']['gaming_preferences']['Update']

export type UserAvailability = Database['public']['Tables']['user_availability']['Row']
export type UserAvailabilityInsert = Database['public']['Tables']['user_availability']['Insert']
export type UserAvailabilityUpdate = Database['public']['Tables']['user_availability']['Update']

export type Game = Database['public']['Tables']['games']['Row']
export type GameInsert = Database['public']['Tables']['games']['Insert']
export type GameUpdate = Database['public']['Tables']['games']['Update']

export type UserGame = Database['public']['Tables']['user_games']['Row']
export type UserGameInsert = Database['public']['Tables']['user_games']['Insert']
export type UserGameUpdate = Database['public']['Tables']['user_games']['Update']

export type UserReview = Database['public']['Tables']['user_reviews']['Row']
export type UserReviewInsert = Database['public']['Tables']['user_reviews']['Insert']
export type UserReviewUpdate = Database['public']['Tables']['user_reviews']['Update']

export type ExperienceLevel = Database['public']['Enums']['experience_level']
export type AvailabilityStatus = Database['public']['Enums']['availability_status']