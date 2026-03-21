/**
 * database.ts
 *
 * Typed Supabase query helper module.
 *
 * Wraps common database queries with full TypeScript type safety using
 * the Database interface. All functions handle errors by logging them
 * and returning null or an empty array so callers can handle missing
 * data gracefully without unhandled exceptions.
 *
 * Usage:
 *   import { getProfile, updateProfile } from '@/lib/database';
 *
 * For server-side (Next.js Server Components / Route Handlers) use
 * the server Supabase client directly from '@/lib/supabase/server'
 * and pass queries inline, or create a parallel server helpers module.
 */

import { createClient } from '@/lib/supabase';
import type { Database } from '@/types/database';
import type {
  Game,
  GameCollection,
  Profile,
  ProfileUpdate,
  UserAvailability,
  UserAvailabilityInsert,
  UserFavoriteGame,
  UserRating,
} from '@/types/database';

// ============================================================
// Typed Supabase client instance
// Import this when you need direct, typed access to the client.
// ============================================================
export const db = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// ============================================================
// Profile helpers
// ============================================================

/**
 * Fetch a single profile by user ID (UUID).
 * Returns null if not found or on error.
 */
export async function getProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await db
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('[getProfile]', error.message);
    return null;
  }

  return data;
}

/**
 * Fetch a single profile by username (case-sensitive).
 * Returns null if not found or on error.
 */
export async function getProfileByUsername(username: string): Promise<Profile | null> {
  const { data, error } = await db
    .from('profiles')
    .select('*')
    .eq('username', username)
    .single();

  if (error) {
    console.error('[getProfileByUsername]', error.message);
    return null;
  }

  return data;
}

/**
 * Update a profile row for the given user ID.
 * Returns the updated profile or null on error.
 * Requires the user to be authenticated as the profile owner (enforced by RLS).
 */
export async function updateProfile(
  userId: string,
  updates: ProfileUpdate
): Promise<Profile | null> {
  const { data, error } = await db
    .from('profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    console.error('[updateProfile]', error.message);
    return null;
  }

  return data;
}

// ============================================================
// Favorite games helpers
// ============================================================

/**
 * Fetch all favorite games for a user, with the full game record joined.
 * Returns an empty array on error.
 */
export async function getUserFavoriteGames(
  userId: string
): Promise<(UserFavoriteGame & { game: Game })[]> {
  const { data, error } = await db
    .from('user_favorite_games')
    .select(`
      id,
      user_id,
      game_id,
      created_at,
      game:games (*)
    `)
    .eq('user_id', userId);

  if (error) {
    console.error('[getUserFavoriteGames]', error.message);
    return [];
  }

  // Supabase returns the joined relation as an object; cast to expected type.
  return (data ?? []) as unknown as (UserFavoriteGame & { game: Game })[];
}

/**
 * Add a game to a user's favorites.
 * Returns the new row or null on error (e.g. duplicate).
 */
export async function addFavoriteGame(
  userId: string,
  gameId: string
): Promise<UserFavoriteGame | null> {
  const { data, error } = await db
    .from('user_favorite_games')
    .insert({ user_id: userId, game_id: gameId })
    .select()
    .single();

  if (error) {
    console.error('[addFavoriteGame]', error.message);
    return null;
  }

  return data;
}

/**
 * Remove a game from a user's favorites.
 * Silently logs errors but does not throw.
 */
export async function removeFavoriteGame(userId: string, gameId: string): Promise<void> {
  const { error } = await db
    .from('user_favorite_games')
    .delete()
    .eq('user_id', userId)
    .eq('game_id', gameId);

  if (error) {
    console.error('[removeFavoriteGame]', error.message);
  }
}

// ============================================================
// Availability helpers
// ============================================================

/**
 * Fetch all availability windows for a user, ordered by day.
 * Returns an empty array on error.
 */
export async function getUserAvailability(userId: string): Promise<UserAvailability[]> {
  const { data, error } = await db
    .from('user_availability')
    .select('*')
    .eq('user_id', userId)
    .order('day_of_week');

  if (error) {
    console.error('[getUserAvailability]', error.message);
    return [];
  }

  return data ?? [];
}

/**
 * Upsert a set of availability windows for a user.
 * Uses conflict resolution on (user_id, day_of_week, start_time) to update
 * existing slots or insert new ones.
 * Returns the resulting rows or an empty array on error.
 */
export async function upsertAvailability(
  userId: string,
  availability: UserAvailabilityInsert[]
): Promise<UserAvailability[]> {
  // Ensure all rows carry the correct user_id
  const rows = availability.map((slot) => ({ ...slot, user_id: userId }));

  const { data, error } = await db
    .from('user_availability')
    .upsert(rows, { onConflict: 'user_id,day_of_week,start_time' })
    .select();

  if (error) {
    console.error('[upsertAvailability]', error.message);
    return [];
  }

  return data ?? [];
}

// ============================================================
// Game collection helpers
// ============================================================

/**
 * Fetch a user's entire game collection with full game details joined.
 * Returns an empty array on error.
 */
export async function getGameCollection(
  userId: string
): Promise<(GameCollection & { game: Game })[]> {
  const { data, error } = await db
    .from('game_collections')
    .select(`
      id,
      user_id,
      game_id,
      status,
      notes,
      created_at,
      updated_at,
      game:games (*)
    `)
    .eq('user_id', userId);

  if (error) {
    console.error('[getGameCollection]', error.message);
    return [];
  }

  return (data ?? []) as unknown as (GameCollection & { game: Game })[];
}

// ============================================================
// Rating helpers
// ============================================================

/**
 * Fetch all ratings received by a user.
 * Returns an empty array on error.
 */
export async function getUserRatings(userId: string): Promise<UserRating[]> {
  const { data, error } = await db
    .from('user_ratings')
    .select('*')
    .eq('rated_user_id', userId);

  if (error) {
    console.error('[getUserRatings]', error.message);
    return [];
  }

  return data ?? [];
}

/**
 * Calculate the average rating for a user.
 * Uses Supabase's aggregate select to avoid fetching all rows.
 * Returns null if the user has no ratings or on error.
 */
export async function getAverageRating(userId: string): Promise<number | null> {
  // Supabase does not support SQL AVG() directly via the JS client;
  // we fetch all ratings and compute the average in JS instead.
  const { data, error } = await db
    .from('user_ratings')
    .select('rating')
    .eq('rated_user_id', userId);

  if (error) {
    console.error('[getAverageRating]', error.message);
    return null;
  }

  if (!data || data.length === 0) return null;

  const sum = data.reduce((acc, row) => acc + row.rating, 0);
  return sum / data.length;
}

// ============================================================
// Game search helpers
// ============================================================

/**
 * Full-text search for games by name.
 * Uses case-insensitive ILIKE for broad matching.
 * Returns an empty array on error or no results.
 */
export async function searchGames(query: string): Promise<Game[]> {
  if (!query.trim()) return [];

  const { data, error } = await db
    .from('games')
    .select('*')
    .ilike('name', `%${query.trim()}%`)
    .order('name')
    .limit(50);

  if (error) {
    console.error('[searchGames]', error.message);
    return [];
  }

  return data ?? [];
}
