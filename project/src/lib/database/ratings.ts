/**
 * User ratings and reviews database operations.
 */

import { createClient } from '@/lib/supabase';
import type {
  UserRating,
  UserRatingInsert,
  UserRatingUpdate,
  RatingWithRater,
} from '@/types/database';

/**
 * Get all ratings for a user.
 */
export async function getUserRatings(
  profileId: string,
  options: {
    publicOnly?: boolean;
    limit?: number;
    offset?: number;
  } = {}
): Promise<RatingWithRater[]> {
  const supabase = createClient();

  let query = supabase
    .from('user_ratings')
    .select(`
      *,
      rater:profiles!rater_id(
        id,
        username,
        display_name,
        avatar_url
      )
    `)
    .eq('rated_id', profileId)
    .order('created_at', { ascending: false })
    .limit(options.limit ?? 20);

  if (options.publicOnly) {
    query = query.eq('is_public', true);
  }

  if (options.offset) {
    query = query.range(options.offset, options.offset + (options.limit ?? 20) - 1);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(`Failed to fetch ratings: ${error.message}`);
  }

  return data as RatingWithRater[];
}

/**
 * Get a specific rating between two users.
 */
export async function getRatingBetweenUsers(
  raterId: string,
  ratedId: string
): Promise<UserRating | null> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_ratings')
    .select('*')
    .eq('rater_id', raterId)
    .eq('rated_id', ratedId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch rating: ${error.message}`);
  }

  return data;
}

/**
 * Submit a rating for another user.
 */
export async function submitRating(
  rating: UserRatingInsert
): Promise<UserRating> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_ratings')
    .insert(rating)
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      throw new Error('You have already rated this user');
    }
    if (error.code === '23514') {
      throw new Error('You cannot rate yourself');
    }
    throw new Error(`Failed to submit rating: ${error.message}`);
  }

  return data;
}

/**
 * Update an existing rating.
 */
export async function updateRating(
  ratingId: string,
  updates: UserRatingUpdate
): Promise<UserRating> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_ratings')
    .update(updates)
    .eq('id', ratingId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update rating: ${error.message}`);
  }

  return data;
}

/**
 * Delete a rating.
 */
export async function deleteRating(
  ratingId: string,
  raterId: string
): Promise<void> {
  const supabase = createClient();

  const { error } = await supabase
    .from('user_ratings')
    .delete()
    .eq('id', ratingId)
    .eq('rater_id', raterId);

  if (error) {
    throw new Error(`Failed to delete rating: ${error.message}`);
  }
}

/**
 * Get the average rating for a user.
 */
export async function getUserAverageRating(
  profileId: string
): Promise<{ average: number | null; count: number }> {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('user_ratings')
    .select('rating')
    .eq('rated_id', profileId)
    .eq('is_public', true);

  if (error) {
    throw new Error(`Failed to fetch average rating: ${error.message}`);
  }

  if (data.length === 0) {
    return { average: null, count: 0 };
  }

  const sum = data.reduce((acc, r) => acc + r.rating, 0);
  return {
    average: Math.round((sum / data.length) * 100) / 100,
    count: data.length,
  };
}
