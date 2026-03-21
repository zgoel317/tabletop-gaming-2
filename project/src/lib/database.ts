// ============================================================
// Database Helper Functions — Tabletop Gaming Networking App
//
// Server-side abstraction over raw Supabase queries.
// All functions create their own Supabase client via
// createServerSupabaseClient() which uses the user's session
// cookie and therefore respects Row Level Security (RLS).
//
// IMPORTANT: Do NOT manually insert into `profiles` after a
// user signs up. The `handle_new_user()` trigger on auth.users
// automatically creates a profile and default gaming_preferences
// row. Use updateProfile() to fill in optional fields during
// onboarding instead.
//
// The SUPABASE_SERVICE_ROLE_KEY bypasses RLS — never use it
// in client-side code or expose it to the browser.
// ============================================================

import { createServerSupabaseClient } from '@/lib/supabase/server';
import type {
  Profile,
  ProfileUpdate,
  GamingPreferences,
  GamingPreferencesUpdate,
  GameCollection,
  GameCollectionInsert,
  GameCollectionUpdate,
  PlayerRating,
  PlayerRatingInsert,
  CollectionType,
  ProfileFull,
} from '@/types/database';

// ============================================================
// PROFILES
// ============================================================

/**
 * Fetch a single profile by its UUID (same as auth.users id).
 * Returns null if not found or if RLS blocks access.
 */
export async function getProfileById(id: string): Promise<Profile | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Row not found
      console.error('[database] getProfileById error:', error.message);
      return null;
    }

    return data as Profile;
  } catch (err) {
    console.error('[database] getProfileById unexpected error:', err);
    return null;
  }
}

/**
 * Fetch a single profile by username.
 * Returns null if not found or if RLS blocks access.
 */
export async function getProfileByUsername(username: string): Promise<Profile | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('username', username)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Row not found
      console.error('[database] getProfileByUsername error:', error.message);
      return null;
    }

    return data as Profile;
  } catch (err) {
    console.error('[database] getProfileByUsername unexpected error:', err);
    return null;
  }
}

/**
 * Apply a partial update to a profile row.
 * Only the authenticated user can update their own profile (enforced by RLS).
 * Returns the updated profile or null on failure.
 */
export async function updateProfile(
  id: string,
  updates: ProfileUpdate
): Promise<Profile | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', id)
      .select('*')
      .single();

    if (error) {
      console.error('[database] updateProfile error:', error.message);
      return null;
    }

    return data as Profile;
  } catch (err) {
    console.error('[database] updateProfile unexpected error:', err);
    return null;
  }
}

// ============================================================
// GAMING PREFERENCES
// ============================================================

/**
 * Fetch gaming preferences for a given user.
 * Returns null if not found or if the profile is private and
 * the caller is not the owner (enforced by RLS).
 */
export async function getGamingPreferences(
  userId: string
): Promise<GamingPreferences | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('gaming_preferences')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Row not found
      console.error('[database] getGamingPreferences error:', error.message);
      return null;
    }

    return data as GamingPreferences;
  } catch (err) {
    console.error('[database] getGamingPreferences unexpected error:', err);
    return null;
  }
}

/**
 * Upsert gaming preferences for the authenticated user.
 * Uses user_id as the conflict key. Creates a new row if none
 * exists, or updates the existing one.
 * Returns the resulting row or null on failure.
 */
export async function upsertGamingPreferences(
  userId: string,
  prefs: GamingPreferencesUpdate
): Promise<GamingPreferences | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('gaming_preferences')
      .upsert(
        { ...prefs, user_id: userId },
        { onConflict: 'user_id' }
      )
      .select('*')
      .single();

    if (error) {
      console.error('[database] upsertGamingPreferences error:', error.message);
      return null;
    }

    return data as GamingPreferences;
  } catch (err) {
    console.error('[database] upsertGamingPreferences unexpected error:', err);
    return null;
  }
}

// ============================================================
// GAME COLLECTIONS
// ============================================================

/**
 * Fetch a user's game collection, optionally filtered by type.
 * Returns an empty array if not found, access is denied, or
 * the collection is empty.
 *
 * @param userId  The profile UUID to fetch the collection for.
 * @param type    Optional CollectionType filter ('owned', 'wishlist', etc.)
 */
export async function getGameCollection(
  userId: string,
  type?: CollectionType
): Promise<GameCollection[]> {
  try {
    const supabase = createServerSupabaseClient();
    let query = supabase
      .from('game_collections')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (type) {
      query = query.eq('collection_type', type);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[database] getGameCollection error:', error.message);
      return [];
    }

    return (data ?? []) as GameCollection[];
  } catch (err) {
    console.error('[database] getGameCollection unexpected error:', err);
    return [];
  }
}

/**
 * Add a game to a user's collection.
 * The user_id in the item must match the authenticated user (RLS).
 * Returns the created row or null on failure.
 */
export async function addToCollection(
  item: GameCollectionInsert
): Promise<GameCollection | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('game_collections')
      .insert(item)
      .select('*')
      .single();

    if (error) {
      console.error('[database] addToCollection error:', error.message);
      return null;
    }

    return data as GameCollection;
  } catch (err) {
    console.error('[database] addToCollection unexpected error:', err);
    return null;
  }
}

/**
 * Update an existing game collection entry.
 * The userId guard is in addition to RLS for defence-in-depth.
 * Returns the updated row or null on failure.
 */
export async function updateCollectionItem(
  id: string,
  userId: string,
  updates: GameCollectionUpdate
): Promise<GameCollection | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('game_collections')
      .update(updates)
      .eq('id', id)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error) {
      console.error('[database] updateCollectionItem error:', error.message);
      return null;
    }

    return data as GameCollection;
  } catch (err) {
    console.error('[database] updateCollectionItem unexpected error:', err);
    return null;
  }
}

/**
 * Remove a game from a user's collection.
 * The userId check is applied in addition to RLS.
 * Returns true if a row was deleted, false otherwise.
 */
export async function removeFromCollection(
  id: string,
  userId: string
): Promise<boolean> {
  try {
    const supabase = createServerSupabaseClient();
    const { error, count } = await supabase
      .from('game_collections')
      .delete({ count: 'exact' })
      .eq('id', id)
      .eq('user_id', userId);

    if (error) {
      console.error('[database] removeFromCollection error:', error.message);
      return false;
    }

    return (count ?? 0) > 0;
  } catch (err) {
    console.error('[database] removeFromCollection unexpected error:', err);
    return false;
  }
}

// ============================================================
// PLAYER RATINGS
// ============================================================

/**
 * Fetch all ratings received by a given user.
 * Results are ordered most-recent first.
 * Returns an empty array on error or if no ratings exist.
 */
export async function getPlayerRatings(userId: string): Promise<PlayerRating[]> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('player_ratings')
      .select('*')
      .eq('rated_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[database] getPlayerRatings error:', error.message);
      return [];
    }

    return (data ?? []) as PlayerRating[];
  } catch (err) {
    console.error('[database] getPlayerRatings unexpected error:', err);
    return [];
  }
}

/**
 * Insert or update a player rating.
 * Conflicts on (rater_id, rated_id) — each pair can have only
 * one rating; submitting again updates the existing one.
 * Returns the resulting row or null on failure.
 */
export async function upsertPlayerRating(
  rating: PlayerRatingInsert
): Promise<PlayerRating | null> {
  try {
    const supabase = createServerSupabaseClient();
    const { data, error } = await supabase
      .from('player_ratings')
      .upsert(rating, { onConflict: 'rater_id,rated_id' })
      .select('*')
      .single();

    if (error) {
      console.error('[database] upsertPlayerRating error:', error.message);
      return null;
    }

    return data as PlayerRating;
  } catch (err) {
    console.error('[database] upsertPlayerRating unexpected error:', err);
    return null;
  }
}

// ============================================================
// COMPOSITE / FULL PROFILE
// ============================================================

/**
 * Fetch a fully-hydrated profile including preferences,
 * game collection, received ratings, and computed average rating.
 *
 * Runs all sub-queries in parallel for performance.
 * Returns null if the profile does not exist or is inaccessible.
 */
export async function getProfileFull(id: string): Promise<ProfileFull | null> {
  try {
    // Run all queries concurrently
    const [profile, preferences, collections, ratings] = await Promise.all([
      getProfileById(id),
      getGamingPreferences(id),
      getGameCollection(id),
      getPlayerRatings(id),
    ]);

    // If the profile itself is inaccessible, return null
    if (!profile) {
      return null;
    }

    // Compute average rating from all received ratings
    let average_rating: number | null = null;
    if (ratings.length > 0) {
      const sum = ratings.reduce((acc, r) => acc + r.rating, 0);
      // Round to one decimal place for display
      average_rating = Math.round((sum / ratings.length) * 10) / 10;
    }

    return {
      ...profile,
      gaming_preferences: preferences,
      game_collections: collections,
      received_ratings: ratings,
      average_rating,
    };
  } catch (err) {
    console.error('[database] getProfileFull unexpected error:', err);
    return null;
  }
}
