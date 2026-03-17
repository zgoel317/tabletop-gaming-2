import { Database } from '@/types/database'
import { SupabaseClient } from '@supabase/supabase-js'

export type TypedSupabaseClient = SupabaseClient<Database>

export interface UserProfile extends Database['public']['Tables']['users']['Row'] {
  gaming_preferences?: Database['public']['Tables']['gaming_preferences']['Row']
  user_availability?: Database['public']['Tables']['user_availability']['Row'][]
  user_games?: (Database['public']['Tables']['user_games']['Row'] & {
    games: Database['public']['Tables']['games']['Row']
  })[]
  reviews_given?: Database['public']['Tables']['user_reviews']['Row'][]
  reviews_received?: Database['public']['Tables']['user_reviews']['Row'][]
}

export interface GameWithUserData extends Database['public']['Tables']['games']['Row'] {
  user_games?: Database['public']['Tables']['user_games']['Row']
}

export interface UserWithPreferences extends Database['public']['Tables']['users']['Row'] {
  gaming_preferences: Database['public']['Tables']['gaming_preferences']['Row']
}