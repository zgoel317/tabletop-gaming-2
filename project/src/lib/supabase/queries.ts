/**
 * Reusable typed query helpers for common database operations.
 * Each function accepts an optional Supabase client so it works
 * in both browser and server contexts.
 */

import type { SupabaseClient } from '@supabase/supabase-js'
import type {
  Database,
  Profile,
  ProfileSummary,
  ProfileUpdate,
  GamingPreference,
  GameGenre,
  Game,
  UserGameCollection,
  UserGameCollectionInsert,
  UserGameCollectionUpdate,
  CollectionStatus,
  UserRatingInsert,
  NearbyProfile,
  ProfileSearchResult,
  FollowCounts,
} from './types'

type SupabaseDB = SupabaseClient<Database>

// ============================================================
// PROFILES
// ============================================================

/** Fetch the full profile for the authenticated user */
export async function getMyProfile(client: SupabaseDB) {
  const { data, error } = await client
    .from('profiles')
    .select('*')
    .eq('id', (await client.auth.getUser()).data.user?.id ?? '')
    .single()

  if (error) throw error
  return data as Profile
}

/** Fetch a public profile summary by username */
export async function getProfileByUsername(
  client: SupabaseDB,
  username: string,
): Promise<ProfileSummary | null> {
  const { data, error } = await client
    .from('profile_summaries')
    .select('*')
    .eq('username', username)
    .single()

  if (error) {
    if (error.code === 'PGRST116') return null // not found
    throw error
  }
  return data as ProfileSummary
}

/** Fetch a public profile summary by ID */
export async function getProfileById(
  client: SupabaseDB,
  profileId: string,
): Promise<ProfileSummary | null> {
  const { data, error } = await client
    .from('profile_summaries')
    .select('*')
    .eq('id', profileId)
    .single()

  if (error) {
    if (error.code === 'PGRST116') return null
    throw error
  }
  return data as ProfileSummary
}

/** Update the authenticated user's profile */
export async function updateProfile(
  client: SupabaseDB,
  profileId: string,
  updates: ProfileUpdate,
): Promise<Profile> {
  const { data, error } = await client
    .from('profiles')
    .update(updates)
    .eq('id', profileId)
    .select()
    .single()

  if (error) throw error
  return data as Profile
}

/** Set or update the user's geographic location */
export async function setProfileLocation(
  client: SupabaseDB,
  profileId: string,
  latitude: number,
  longitude: number,
): Promise<void> {
  const { error } = await client.rpc('set_profile_location', {
    p_profile_id: profileId,
    p_latitude: latitude,
    p_longitude: longitude,
  })
  if (error) throw error
}

/** Search profiles by username / display name */
export async function searchProfiles(
  client: SupabaseDB,
  query: string,
  limit = 20,
  offset = 0,
): Promise<ProfileSearchResult[]> {
  const { data, error } = await client.rpc('search_profiles', {
    p_query: query,
    p_limit: limit,
    p_offset: offset,
  })
  if (error) throw error
  return (data ?? []) as ProfileSearchResult[]
}

/** Find profiles near a geographic point */
export async function findNearbyProfiles(
  client: SupabaseDB,
  latitude: number,
  longitude: number,
  radiusKm = 50,
  limit = 20,
  offset = 0,
): Promise<NearbyProfile[]> {
  const { data, error } = await client.rpc('find_nearby_profiles', {
    p_latitude: latitude,
    p_longitude: longitude,
    p_radius_km: radiusKm,
    p_limit: limit,
    p_offset: offset,
  })
  if (error) throw error
  return (data ?? []) as NearbyProfile[]
}

// ============================================================
// GAMING PREFERENCES
// ============================================================

/** Get all gaming preferences for a profile */
export async function getGamingPreferences(
  client: SupabaseDB,
  profileId: string,
): Promise<GamingPreference[]> {
  const { data, error } = await client
    .from('gaming_preferences')
    .select('*')
    .eq('profile_id', profileId)
    .order('preference_level', { ascending: false })

  if (error) throw error
  return (data ?? []) as GamingPreference[]
}

/** Upsert a single genre preference for the current user */
export async function upsertGamingPreference(
  client: SupabaseDB,
  genre: GameGenre,
  preferenceLevel: 1 | 2 | 3 | 4 | 5 = 3,
): Promise<GamingPreference> {
  const { data, error } = await client.rpc('upsert_gaming_preference', {
    p_genre: genre,
    p_preference_level: preferenceLevel,
  })
  if (error) throw error
  return data as GamingPreference
}

/** Delete a gaming preference for the current user */
export async function deleteGamingPreference(
  client: SupabaseDB,
  preferenceId: string,
): Promise<void> {
  const { error } = await client
    .from('gaming_preferences')
    .delete()
    .eq('id', preferenceId)
  if (error) throw error
}

// ============================================================
// GAMES
// ============================================================

/** Get a game by its Supabase UUID */
export async function getGameById(
  client: SupabaseDB,
  gameId: string,
): Promise<Game | null> {
  const { data, error } = await client
    .from('games')
    .select('*')
    .eq('id', gameId)
    .single()

  if (error) {
    if (error.code === 'PGRST116') return null
    throw error
  }
  return data as Game
}

/** Get a game by its BoardGameGeek ID */
export async function getGameByBggId(
  client: SupabaseDB,
  bggId: number,
): Promise<Game | null> {
  const { data, error } = await client
    .from('games')
    .select('*')
    .eq('bgg_id', bggId)
    .single()

  if (error) {
    if (error.code === 'PGRST116') return null
    throw error
  }
  return data as Game
}

/** Search games by name */
export async function searchGames(
  client: SupabaseDB,
  query: string,
  limit = 20,
  offset = 0,
): Promise<Game[]> {
  const { data, error } = await client
    .from('games')
    .select('*')
    .ilike('name', `%${query}%`)
    .order('bgg_rating', { ascending: false })
    .range(offset, offset + limit - 1)

  if (error) throw error
  return (data ?? []) as Game[]
}

/** Filter games by genre */
export async function getGamesByGenre(
  client: SupabaseDB,
  genre: GameGenre,
  limit = 20,
  offset = 0,
): Promise<Game[]> {
  const { data, error } = await client
    .from('games')
    .select('*')
    .contains('genres', [genre])
    .order('bgg_rating', { ascending: false })
    .range(offset, offset + limit - 1)

  if (error) throw error
  return (data ?? []) as Game[]
}

// ============================================================
// USER GAME COLLECTION
// ============================================================

/** Get a user's game collection, optionally filtered by status */
export async function getUserCollection(
  client: SupabaseDB,
  profileId: string,
  status?: CollectionStatus,
) {
  let query = client
    .from('user_collection_details')
    .select('*')
    .eq('profile_id', profileId)
    .order('game_name', { ascending: true })

  if (status) {
    query = query.eq('status', status)
  }

  const { data, error } = await query
  if (error) throw error
  return data ?? []
}

/** Add a game to the current user's collection */
export async function addToCollection(
  client: SupabaseDB,
  entry: UserGameCollectionInsert,
): Promise<UserGameCollection> {
  const { data, error } = await client
    .from('user_game_collection')
    .insert(entry)
    .select()
    .single()

  if (error) throw error
  return data as UserGameCollection
}

/** Update a collection entry */
export async function updateCollectionEntry(
  client: SupabaseDB,
  entryId: string,
  updates: UserGameCollectionUpdate,
): Promise<UserGameCollection> {
  const { data, error } = await client
    .from('user_game_collection')
    .update(updates)
    .eq('id', entryId)
    .select()
    .single()

  if (error) throw error
  return data as UserGameCollection
}

/** Remove a game from the current user's collection */
export async function removeFromCollection(
  client: SupabaseDB,
  entryId: string,
): Promise<void> {
  const { error } = await client
    .from('user_game_collection')
    .delete()
    .eq('id', entryId)
  if (error) throw error
}

// ============================================================
// USER RATINGS
// ============================================================

/** Submit a rating for another user */
export async function submitUserRating(
  client: SupabaseDB,
  rating: UserRatingInsert,
) {
  const { data, error } = await client
    .from('user_ratings')
    .insert(rating)
    .select()
    .single()

  if (error) throw error
  return data
}

/** Get all ratings received by a user */
export async function getUserRatings(client: SupabaseDB, profileId: string) {
  const { data, error } = await client
    .from('user_ratings')
    .select('*, rater:profiles!rater_id(id, username, avatar_url)')
    .eq('rated_id', profileId)
    .order('created_at', { ascending: false })

  if (error) throw error
  return data ?? []
}

// ============================================================
// FOLLOWS
// ============================================================

/** Follow a user */
export async function followUser(
  client: SupabaseDB,
  followerId: string,
  followingId: string,
): Promise<void> {
  const { error } = await client
    .from('profile_follows')
    .insert({ follower_id: followerId, following_id: followingId })
  if (error) throw error
}

/** Unfollow a user */
export async function unfollowUser(
  client: SupabaseDB,
  followerId: string,
  followingId: string,
): Promise<void> {
  const { error } = await client
    .from('profile_follows')
    .delete()
    .eq('follower_id', followerId)
    .eq('following_id', followingId)
  if (error) throw error
}

/** Check whether the current user follows a specific profile */
export async function isFollowing(
  client: SupabaseDB,
  followerId: string,
  followingId: string,
): Promise<boolean> {
  const { data, error } = await client
    .from('profile_follows')
    .select('follower_id')
    .eq('follower_id', followerId)
    .eq('following_id', followingId)
    .maybeSingle()

  if (error) throw error
  return data !== null
}

/** Get follower / following counts for a profile */
export async function getFollowCounts(
  client: SupabaseDB,
  profileId: string,
): Promise<FollowCounts> {
  const { data, error } = await client.rpc('get_follow_counts', {
    p_profile_id: profileId,
  })
  if (error) throw error
  const row = (data as FollowCounts[])?.[0]
  return row ?? { followers: 0, following: 0 }
}
