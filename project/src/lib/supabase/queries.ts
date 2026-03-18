/**
 * Common Supabase query helpers for profiles and gaming data.
 * These functions abstract common data access patterns.
 */

import { createClient } from '@/lib/supabase/server';
import type {
  Profile,
  GamingPreferences,
  AvailabilitySlot,
  ProfileSummary,
  UserGamingProfile,
  Game,
  UserGameCollection,
  CollectionStatus,
  ExperienceLevel,
  GameGenre,
} from '@/types/database.types';

// ============================================================
// PROFILE QUERIES
// ============================================================

/**
 * Fetch a user's full profile by ID.
 * Returns null if not found or not accessible.
 */
export async function getProfileById(
  userId: string
): Promise<Profile | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('Error fetching profile:', error.message);
    return null;
  }

  return data;
}

/**
 * Fetch a user's profile by username.
 */
export async function getProfileByUsername(
  username: string
): Promise<Profile | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('username', username)
    .eq('is_profile_public', true)
    .single();

  if (error) {
    console.error('Error fetching profile by username:', error.message);
    return null;
  }

  return data;
}

/**
 * Fetch a profile summary (with computed stats) by ID.
 */
export async function getProfileSummaryById(
  userId: string
): Promise<ProfileSummary | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('profile_summaries')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('Error fetching profile summary:', error.message);
    return null;
  }

  return data;
}

/**
 * Search profiles by name or username with optional filters.
 */
export async function searchProfiles(params: {
  query?: string;
  experienceLevel?: ExperienceLevel;
  isLookingForGroup?: boolean;
  limit?: number;
  offset?: number;
}): Promise<ProfileSummary[]> {
  const supabase = await createClient();
  const { query, experienceLevel, isLookingForGroup, limit = 20, offset = 0 } = params;

  let queryBuilder = supabase
    .from('profile_summaries')
    .select('*')
    .order('last_active_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (query) {
    queryBuilder = queryBuilder.or(
      `display_name.ilike.%${query}%,username.ilike.%${query}%`
    );
  }

  if (experienceLevel) {
    queryBuilder = queryBuilder.eq('experience_level', experienceLevel);
  }

  if (isLookingForGroup !== undefined) {
    queryBuilder = queryBuilder.eq('is_looking_for_group', isLookingForGroup);
  }

  const { data, error } = await queryBuilder;

  if (error) {
    console.error('Error searching profiles:', error.message);
    return [];
  }

  return data || [];
}

/**
 * Find profiles near a geographic location.
 */
export async function findNearbyProfiles(params: {
  lat: number;
  lng: number;
  radiusKm?: number;
  limit?: number;
  offset?: number;
}): Promise<Array<ProfileSummary & { distance_km: number }>> {
  const supabase = await createClient();
  const { lat, lng, radiusKm = 25, limit = 20, offset = 0 } = params;

  const { data: nearbyData, error: nearbyError } = await supabase
    .rpc('find_nearby_profiles', {
      lat,
      lng,
      radius_km: radiusKm,
      limit_count: limit,
      offset_count: offset,
    });

  if (nearbyError || !nearbyData?.length) {
    if (nearbyError) console.error('Error finding nearby profiles:', nearbyError.message);
    return [];
  }

  const profileIds = nearbyData.map((r: { profile_id: string }) => r.profile_id);
  const distanceMap = new Map(
    nearbyData.map((r: { profile_id: string; distance_km: number }) => [
      r.profile_id,
      r.distance_km,
    ])
  );

  const { data: profiles, error: profilesError } = await supabase
    .from('profile_summaries')
    .select('*')
    .in('id', profileIds);

  if (profilesError) {
    console.error('Error fetching nearby profile details:', profilesError.message);
    return [];
  }

  return (profiles || []).map((p) => ({
    ...p,
    distance_km: distanceMap.get(p.id) ?? 0,
  }));
}

/**
 * Update a user's profile.
 */
export async function updateProfile(
  userId: string,
  updates: Partial<Omit<Profile, 'id' | 'created_at' | 'updated_at'>>
): Promise<Profile | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    console.error('Error updating profile:', error.message);
    return null;
  }

  return data;
}

// ============================================================
// GAMING PREFERENCES QUERIES
// ============================================================

/**
 * Fetch gaming preferences for a user.
 */
export async function getGamingPreferences(
  userId: string
): Promise<GamingPreferences | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('gaming_preferences')
    .select('*')
    .eq('profile_id', userId)
    .single();

  if (error) {
    console.error('Error fetching gaming preferences:', error.message);
    return null;
  }

  return data;
}

/**
 * Update gaming preferences for a user (upsert).
 */
export async function upsertGamingPreferences(
  userId: string,
  preferences: Partial<Omit<GamingPreferences, 'id' | 'profile_id' | 'created_at' | 'updated_at'>>
): Promise<GamingPreferences | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('gaming_preferences')
    .upsert({ profile_id: userId, ...preferences })
    .select()
    .single();

  if (error) {
    console.error('Error upserting gaming preferences:', error.message);
    return null;
  }

  return data;
}

/**
 * Get full gaming profile (preferences + favorites) for a user.
 */
export async function getUserGamingProfile(
  userId: string
): Promise<UserGamingProfile | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('user_gaming_profile')
    .select('*')
    .eq('profile_id', userId)
    .single();

  if (error) {
    console.error('Error fetching user gaming profile:', error.message);
    return null;
  }

  return data;
}

// ============================================================
// AVAILABILITY QUERIES
// ============================================================

/**
 * Fetch all availability slots for a user.
 */
export async function getUserAvailability(
  userId: string
): Promise<AvailabilitySlot[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('availability_slots')
    .select('*')
    .eq('profile_id', userId)
    .order('day_of_week')
    .order('time_of_day');

  if (error) {
    console.error('Error fetching availability:', error.message);
    return [];
  }

  return data || [];
}

/**
 * Set availability for a specific day/time slot (upsert).
 */
export async function setAvailabilitySlot(
  userId: string,
  dayOfWeek: AvailabilitySlot['day_of_week'],
  timeOfDay: AvailabilitySlot['time_of_day'],
  isAvailable: boolean
): Promise<AvailabilitySlot | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('availability_slots')
    .upsert({
      profile_id: userId,
      day_of_week: dayOfWeek,
      time_of_day: timeOfDay,
      is_available: isAvailable,
    })
    .select()
    .single();

  if (error) {
    console.error('Error setting availability slot:', error.message);
    return null;
  }

  return data;
}

// ============================================================
// GAME COLLECTION QUERIES
// ============================================================

/**
 * Fetch a user's game collection with game details.
 */
export async function getUserGameCollection(
  userId: string,
  status?: CollectionStatus
): Promise<Array<UserGameCollection & { game: Game }>> {
  const supabase = await createClient();

  let query = supabase
    .from('user_game_collections')
    .select(`
      *,
      game:games(*)
    `)
    .eq('profile_id', userId)
    .order('created_at', { ascending: false });

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;

  if (error) {
    console.error('Error fetching game collection:', error.message);
    return [];
  }

  return (data || []) as Array<UserGameCollection & { game: Game }>;
}

/**
 * Add a game to a user's collection.
 */
export async function addGameToCollection(
  userId: string,
  gameId: string,
  status: CollectionStatus,
  extras?: Partial<Omit<UserGameCollection, 'id' | 'profile_id' | 'game_id' | 'status' | 'created_at' | 'updated_at'>>
): Promise<UserGameCollection | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('user_game_collections')
    .upsert({
      profile_id: userId,
      game_id: gameId,
      status,
      ...extras,
    })
    .select()
    .single();

  if (error) {
    console.error('Error adding game to collection:', error.message);
    return null;
  }

  return data;
}

/**
 * Remove a game from a user's collection.
 */
export async function removeGameFromCollection(
  userId: string,
  gameId: string,
  status: CollectionStatus
): Promise<boolean> {
  const supabase = await createClient();

  const { error } = await supabase
    .from('user_game_collections')
    .delete()
    .eq('profile_id', userId)
    .eq('game_id', gameId)
    .eq('status', status);

  if (error) {
    console.error('Error removing game from collection:', error.message);
    return false;
  }

  return true;
}

// ============================================================
// GAME SEARCH QUERIES
// ============================================================

/**
 * Search games by name using full-text search.
 */
export async function searchGames(params: {
  query: string;
  genres?: GameGenre[];
  minPlayers?: number;
  maxPlayers?: number;
  minComplexity?: number;
  maxComplexity?: number;
  limit?: number;
  offset?: number;
}): Promise<Game[]> {
  const supabase = await createClient();
  const {
    query,
    genres,
    minPlayers,
    maxPlayers,
    minComplexity,
    maxComplexity,
    limit = 20,
    offset = 0,
  } = params;

  let queryBuilder = supabase
    .from('games')
    .select('*')
    .order('average_rating', { ascending: false })
    .range(offset, offset + limit - 1);

  if (query) {
    queryBuilder = queryBuilder.ilike('name', `%${query}%`);
  }

  if (genres?.length) {
    queryBuilder = queryBuilder.overlaps('genres', genres);
  }

  if (minPlayers !== undefined) {
    queryBuilder = queryBuilder.lte('min_players', minPlayers);
  }

  if (maxPlayers !== undefined) {
    queryBuilder = queryBuilder.gte('max_players', maxPlayers);
  }

  if (minComplexity !== undefined) {
    queryBuilder = queryBuilder.gte('complexity_rating', minComplexity);
  }

  if (maxComplexity !== undefined) {
    queryBuilder = queryBuilder.lte('complexity_rating', maxComplexity);
  }

  const { data, error } = await queryBuilder;

  if (error) {
    console.error('Error searching games:', error.message);
    return [];
  }

  return data || [];
}

/**
 * Get a game by its BoardGameGeek ID.
 */
export async function getGameByBggId(bggId: number): Promise<Game | null> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('games')
    .select('*')
    .eq('bgg_id', bggId)
    .single();

  if (error) {
    console.error('Error fetching game by BGG ID:', error.message);
    return null;
  }

  return data;
}
