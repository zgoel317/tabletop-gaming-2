import { supabase } from '../supabase';
import type {
  Profile,
  GamingPreferences,
  GameCollectionItem,
  Availability,
  UserRating
} from '../../types/database';

export async function getProfile(userId: string): Promise<Profile | null> {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error fetching profile:', error);
    return null;
  }
}

export async function updateProfile(userId: string, updates: Partial<Profile>): Promise<Profile | null> {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error updating profile:', error);
    return null;
  }
}

export async function getGamingPreferences(userId: string): Promise<GamingPreferences | null> {
  try {
    const { data, error } = await supabase
      .from('gaming_preferences')
      .select('*')
      .eq('user_id', userId)
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error fetching gaming preferences:', error);
    return null;
  }
}

export async function upsertGamingPreferences(userId: string, prefs: Partial<GamingPreferences>): Promise<GamingPreferences | null> {
  try {
    const { data, error } = await supabase
      .from('gaming_preferences')
      .upsert({ ...prefs, user_id: userId })
      .select()
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error upserting gaming preferences:', error);
    return null;
  }
}

export async function getGameCollection(userId: string): Promise<GameCollectionItem[]> {
  try {
    const { data, error } = await supabase
      .from('game_collection')
      .select('*')
      .eq('user_id', userId);
    
    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching game collection:', error);
    return [];
  }
}

export async function addToGameCollection(item: Omit<GameCollectionItem, 'id' | 'created_at' | 'updated_at'>): Promise<GameCollectionItem | null> {
  try {
    const { data, error } = await supabase
      .from('game_collection')
      .insert(item)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error adding to game collection:', error);
    return null;
  }
}

export async function removeFromGameCollection(itemId: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('game_collection')
      .delete()
      .eq('id', itemId);
    
    if (error) throw error;
  } catch (error) {
    console.error('Error removing from game collection:', error);
  }
}

export async function getAvailability(userId: string): Promise<Availability[]> {
  try {
    const { data, error } = await supabase
      .from('availability')
      .select('*')
      .eq('user_id', userId);
    
    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching availability:', error);
    return [];
  }
}

export async function setAvailability(slot: Omit<Availability, 'id' | 'created_at' | 'updated_at'>): Promise<Availability | null> {
  try {
    const { data, error } = await supabase
      .from('availability')
      .insert(slot)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error setting availability:', error);
    return null;
  }
}

export async function getUserRatings(userId: string): Promise<UserRating[]> {
  try {
    const { data, error } = await supabase
      .from('user_ratings')
      .select('*')
      .eq('reviewed_id', userId);
    
    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching user ratings:', error);
    return [];
  }
}

export async function getAverageRating(userId: string): Promise<number | null> {
  try {
    const { data, error } = await supabase
      .from('user_ratings')
      .select('rating')
      .eq('reviewed_id', userId);
    
    if (error) throw error;
    if (!data || data.length === 0) return null;
    
    const sum = data.reduce((acc, curr) => acc + curr.rating, 0);
    return sum / data.length;
  } catch (error) {
    console.error('Error calculating average rating:', error);
    return null;
  }
}
