/**
 * Game collection and catalog database operations.
 */

import { createClient } from '@/lib/supabase';
import type {
  Game,
  GameInsert,
  UserGameCollection,
  UserGameCollectionInsert,
  UserGameCollectionUpdate,
  FavoriteGame,
  CollectionEntryWithGame,
  CollectionStatus,
} from '@/types/database';

// ============================================================
// GAME CATALOG
// ============================================================

/**
 * Search the games catalog by name.
 */
export async function searchGames(
  query: string,
  limit = 20
): Promise<Game[]> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('games')
    .select('*')
    .ilike('name', `%${query}%`)
    .order('bgg_rating', { ascending: false, nullsFirst: false })
    .limit(limit);

  if (error) {
    throw new Error(`Failed to search games: ${error.message}`);
  }

  return data;
}

/**
 * Get a game by its database ID.
 */
export async function getGameById(gameId: string): Promise<Game | null> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('games')
    .select('*')
    .eq('id', gameId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch game: ${error.message}`);
  }

  return data;
}

/**
 * Get a game by its BoardGameGeek ID.
 */
export async function getGameByBggId(bggId: number): Promise<Game | null> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('games')
    .select('*')
    .eq('bgg_id', bggId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch game by BGG ID: ${error.message}`);
  }

  return data;
}

/**
 * Upsert a game (for BGG sync).
 */
export async function upsertGame(game: GameInsert): Promise<Game> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('games')
    .upsert(game, { onConflict: 'bgg_id' })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to upsert game: ${error.message}`);
  }

  return data;
}

/**
 * Get popular games sorted by BGG rating.
 */
export async function getPopularGames(
  limit = 20,
  offset = 0
): Promise<Game[]> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('games')
    .select('*')
    .not('bgg_rating', 'is', null)
    .eq('is_expansion', false)
    .order('bgg_rating', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    throw new Error(`Failed to fetch popular games: ${error.message}`);
  }

  return data;
}

// ============================================================
// USER GAME COLLECTION
// ============================================================

/**
 * Get a user's game collection with game details.
 */
export async function getUserCollection(
  profileId: string,
  status?: CollectionStatus
): Promise<CollectionEntryWithGame[]> {
  const supabase = createClient();

  let query = supabase
    .from('user_game_collection')
    .select(`
      *,
      game:games(*)
    `)
    .eq('profile_id', profileId)
    .order('created_at', { ascending: false });

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(`Failed to fetch collection: ${error.message}`);
  }

  return data as CollectionEntryWithGame[];
}

/**
 * Add a game to the user's collection.
 */
export async function addToCollection(
  entry: UserGameCollectionInsert
): Promise<UserGameCollection> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_game_collection')
    .insert(entry)
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      throw new Error('This game is already in your collection with this status');
    }
    throw new Error(`Failed to add to collection: ${error.message}`);
  }

  return data;
}

/**
 * Update a collection entry.
 */
export async function updateCollectionEntry(
  entryId: string,
  updates: UserGameCollectionUpdate
): Promise<UserGameCollection> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_game_collection')
    .update(updates)
    .eq('id', entryId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update collection entry: ${error.message}`);
  }

  return data;
}

/**
 * Remove a game from the user's collection.
 */
export async function removeFromCollection(
  profileId: string,
  entryId: string
): Promise<void> {
  const supabase = createClient();

  const { error } = await supabase
    .from('user_game_collection')
    .delete()
    .eq('id', entryId)
    .eq('profile_id', profileId);

  if (error) {
    throw new Error(`Failed to remove from collection: ${error.message}`);
  }
}

// ============================================================
// FAVORITE GAMES
// ============================================================

/**
 * Get a user's favorite games with game details.
 */
export async function getFavoriteGames(
  profileId: string
): Promise<Array<FavoriteGame & { game: Game }>> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('favorite_games')
    .select(`
      *,
      game:games(*)
    `)
    .eq('profile_id', profileId)
    .order('display_order', { ascending: true });

  if (error) {
    throw new Error(`Failed to fetch favorite games: ${error.message}`);
  }

  return data as Array<FavoriteGame & { game: Game }>;
}

/**
 * Add a game to favorites.
 */
export async function addFavoriteGame(
  profileId: string,
  gameId: string,
  displayOrder = 0
): Promise<FavoriteGame> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('favorite_games')
    .insert({ profile_id: profileId, game_id: gameId, display_order: displayOrder })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      throw new Error('This game is already in your favorites');
    }
    throw new Error(`Failed to add favorite: ${error.message}`);
  }

  return data;
}

/**
 * Remove a game from favorites.
 */
export async function removeFavoriteGame(
  profileId: string,
  gameId: string
): Promise<void> {
  const supabase = createClient();

  const { error } = await supabase
    .from('favorite_games')
    .delete()
    .eq('profile_id', profileId)
    .eq('game_id', gameId);

  if (error) {
    throw new Error(`Failed to remove favorite: ${error.message}`);
  }
}

/**
 * Reorder favorite games.
 */
export async function reorderFavoriteGames(
  profileId: string,
  orderedGameIds: string[]
): Promise<void> {
  const supabase = createClient();

  const updates = orderedGameIds.map((gameId, index) =>
    supabase
      .from('favorite_games')
      .update({ display_order: index })
      .eq('profile_id', profileId)
      .eq('game_id', gameId)
  );

  const results = await Promise.all(updates);
  const failed = results.find((r) => r.error);

  if (failed?.error) {
    throw new Error(`Failed to reorder favorites: ${failed.error.message}`);
  }
}
