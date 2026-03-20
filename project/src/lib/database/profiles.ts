/**
 * Profile database operations with full type safety.
 * All functions use RLS policies enforced at the database level.
 */

import { createClient } from '@/lib/supabase';
import { createClient as createServerClient } from '@/lib/supabase/server';
import type {
  Profile,
  ProfileUpdate,
  ProfileWithDetails,
  NearbyPlayer,
  PlayerSearchResult,
  GamingPreference,
  GamingPreferenceInsert,
  UserAvailability,
  UserAvailabilityInsert,
  AvailabilityDay,
  AvailabilityTime,
} from '@/types/database';

// ============================================================
// PROFILE QUERIES
// ============================================================

/**
 * Fetch a profile by user ID.
 * Returns null if not found or not accessible (private profile).
 */
export async function getProfileById(
  profileId: string,
  useServerClient = false
): Promise<Profile | null> {
  const supabase = useServerClient ? await createServerClient() : createClient();

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', profileId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null; // Not found
    throw new Error(`Failed to fetch profile: ${error.message}`);
  }

  return data;
}

/**
 * Fetch a profile by username.
 */
export async function getProfileByUsername(
  username: string,
  useServerClient = false
): Promise<Profile | null> {
  const supabase = useServerClient ? await createServerClient() : createClient();

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('username', username.toLowerCase())
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch profile by username: ${error.message}`);
  }

  return data;
}

/**
 * Fetch a full profile with all related data using the database function.
 */
export async function getProfileWithDetails(
  profileId: string,
  useServerClient = false
): Promise<ProfileWithDetails | null> {
  const supabase = useServerClient ? await createServerClient() : createClient();

  const { data, error } = await supabase
    .rpc('get_profile_with_details', { target_profile_id: profileId });

  if (error) {
    throw new Error(`Failed to fetch profile details: ${error.message}`);
  }

  return data as ProfileWithDetails | null;
}

/**
 * Get the currently authenticated user's profile.
 */
export async function getCurrentUserProfile(
  useServerClient = false
): Promise<Profile | null> {
  const supabase = useServerClient ? await createServerClient() : createClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  return getProfileById(user.id, useServerClient);
}

// ============================================================
// PROFILE MUTATIONS
// ============================================================

/**
 * Update the current user's profile.
 */
export async function updateProfile(
  profileId: string,
  updates: ProfileUpdate
): Promise<Profile> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', profileId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update profile: ${error.message}`);
  }

  return data;
}

/**
 * Update profile location by coordinates.
 * The location_point geography column is automatically synced via trigger.
 */
export async function updateProfileLocation(
  profileId: string,
  location: {
    latitude: number;
    longitude: number;
    city?: string;
    state?: string;
    country?: string;
    postal_code?: string;
  }
): Promise<Profile> {
  return updateProfile(profileId, location);
}

/**
 * Toggle the user's "looking for group" status.
 */
export async function toggleLookingForGroup(
  profileId: string,
  isLooking: boolean
): Promise<Profile> {
  return updateProfile(profileId, { is_looking_for_group: isLooking });
}

/**
 * Check if a username is available.
 */
export async function isUsernameAvailable(
  username: string,
  excludeProfileId?: string
): Promise<boolean> {
  const supabase = createClient();

  let query = supabase
    .from('profiles')
    .select('id')
    .eq('username', username.toLowerCase());

  if (excludeProfileId) {
    query = query.neq('id', excludeProfileId);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(`Failed to check username availability: ${error.message}`);
  }

  return data.length === 0;
}

// ============================================================
// GAMING PREFERENCES
// ============================================================

/**
 * Get all gaming genre preferences for a profile.
 */
export async function getGamingPreferences(
  profileId: string
): Promise<GamingPreference[]> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('gaming_preferences')
    .select('*')
    .eq('profile_id', profileId)
    .order('preference_weight', { ascending: false });

  if (error) {
    throw new Error(`Failed to fetch gaming preferences: ${error.message}`);
  }

  return data;
}

/**
 * Set gaming preferences for the current user.
 * Upserts preferences (creates or updates).
 */
export async function upsertGamingPreferences(
  preferences: GamingPreferenceInsert[]
): Promise<GamingPreference[]> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('gaming_preferences')
    .upsert(preferences, { onConflict: 'profile_id,genre' })
    .select();

  if (error) {
    throw new Error(`Failed to save gaming preferences: ${error.message}`);
  }

  return data;
}

/**
 * Delete a specific genre preference.
 */
export async function deleteGamingPreference(
  profileId: string,
  preferenceId: string
): Promise<void> {
  const supabase = createClient();

  const { error } = await supabase
    .from('gaming_preferences')
    .delete()
    .eq('id', preferenceId)
    .eq('profile_id', profileId);

  if (error) {
    throw new Error(`Failed to delete gaming preference: ${error.message}`);
  }
}

/**
 * Replace all gaming preferences for the current user.
 */
export async function replaceGamingPreferences(
  profileId: string,
  preferences: GamingPreferenceInsert[]
): Promise<GamingPreference[]> {
  const supabase = createClient();

  // Delete existing preferences
  const { error: deleteError } = await supabase
    .from('gaming_preferences')
    .delete()
    .eq('profile_id', profileId);

  if (deleteError) {
    throw new Error(`Failed to clear gaming preferences: ${deleteError.message}`);
  }

  if (preferences.length === 0) return [];

  // Insert new preferences
  const { data, error } = await supabase
    .from('gaming_preferences')
    .insert(preferences)
    .select();

  if (error) {
    throw new Error(`Failed to insert gaming preferences: ${error.message}`);
  }

  return data;
}

// ============================================================
// USER AVAILABILITY
// ============================================================

/**
 * Get user's availability schedule.
 */
export async function getUserAvailability(
  profileId: string
): Promise<UserAvailability[]> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_availability')
    .select('*')
    .eq('profile_id', profileId)
    .order('day_of_week')
    .order('time_of_day');

  if (error) {
    throw new Error(`Failed to fetch availability: ${error.message}`);
  }

  return data;
}

/**
 * Replace all availability slots for the current user.
 */
export async function replaceUserAvailability(
  profileId: string,
  slots: Array<{ day_of_week: AvailabilityDay; time_of_day: AvailabilityTime }>
): Promise<UserAvailability[]> {
  const supabase = createClient();

  // Delete existing
  const { error: deleteError } = await supabase
    .from('user_availability')
    .delete()
    .eq('profile_id', profileId);

  if (deleteError) {
    throw new Error(`Failed to clear availability: ${deleteError.message}`);
  }

  if (slots.length === 0) return [];

  const inserts: UserAvailabilityInsert[] = slots.map((slot) => ({
    profile_id: profileId,
    ...slot,
  }));

  const { data, error } = await supabase
    .from('user_availability')
    .insert(inserts)
    .select();

  if (error) {
    throw new Error(`Failed to set availability: ${error.message}`);
  }

  return data;
}

// ============================================================
// PLAYER DISCOVERY
// ============================================================

/**
 * Find players near a geographic location.
 */
export async function getNearbyPlayers(
  lat: number,
  lng: number,
  options: {
    radiusKm?: number;
    limit?: number;
    offset?: number;
  } = {}
): Promise<NearbyPlayer[]> {
  const supabase = createClient();

  const { data, error } = await supabase.rpc('get_nearby_players', {
    lat,
    lng,
    radius_km: options.radiusKm ?? 50,
    result_limit: options.limit ?? 20,
    result_offset: options.offset ?? 0,
  });

  if (error) {
    throw new Error(`Failed to find nearby players: ${error.message}`);
  }

  return data as NearbyPlayer[];
}

/**
 * Search players by username or display name.
 */
export async function searchPlayers(
  query: string,
  options: {
    limit?: number;
    offset?: number;
  } = {}
): Promise<PlayerSearchResult[]> {
  const supabase = createClient();

  const { data, error } = await supabase.rpc('search_players', {
    search_query: query,
    result_limit: options.limit ?? 20,
    result_offset: options.offset ?? 0,
  });

  if (error) {
    throw new Error(`Failed to search players: ${error.message}`);
  }

  return data as PlayerSearchResult[];
}

/**
 * Browse public profiles with filters.
 */
export async function browsePlayers(filters: {
  experience_level?: string;
  is_looking_for_group?: boolean;
  limit?: number;
  offset?: number;
}): Promise<Profile[]> {
  const supabase = createClient();

  let query = supabase
    .from('profiles')
    .select('*')
    .eq('is_public', true)
    .order('created_at', { ascending: false })
    .limit(filters.limit ?? 20)
    .range(
      filters.offset ?? 0,
      (filters.offset ?? 0) + (filters.limit ?? 20) - 1
    );

  if (filters.experience_level) {
    query = query.eq('experience_level', filters.experience_level);
  }

  if (filters.is_looking_for_group !== undefined) {
    query = query.eq('is_looking_for_group', filters.is_looking_for_group);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(`Failed to browse players: ${error.message}`);
  }

  return data;
}
