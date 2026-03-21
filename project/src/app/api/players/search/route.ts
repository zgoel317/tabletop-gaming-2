import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabase/server';
import type { PlayerProfile, PlayerSearchResult } from '@/types/player';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders });
}

function toPlayerProfile(row: Record<string, unknown>): PlayerProfile {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    displayName: row.display_name as string,
    avatarUrl: (row.avatar_url as string) ?? null,
    bio: (row.bio as string) ?? null,
    city: (row.city as string) ?? null,
    state: (row.state as string) ?? null,
    country: (row.country as string) ?? null,
    latitude: (row.latitude as number) ?? null,
    longitude: (row.longitude as number) ?? null,
    experienceLevel: row.experience_level as PlayerProfile['experienceLevel'],
    favoriteGames: (row.favorite_games as PlayerProfile['favoriteGames']) ?? [],
    availability: (row.availability as PlayerProfile['availability']) ?? null,
    rating: (row.rating as number) ?? null,
    reviewCount: (row.review_count as number) ?? 0,
    createdAt: row.created_at as string,
  };
}

export async function GET(request: NextRequest) {
  try {
    const supabase = createServerClient();
    const sp = request.nextUrl.searchParams;

    const query = sp.get('query') ?? '';
    const city = sp.get('city') ?? '';
    const state = sp.get('state') ?? '';
    const country = sp.get('country') ?? '';
    const experienceLevelRaw = sp.get('experienceLevel') ?? '';
    const gamesRaw = sp.get('games') ?? '';
    const availableDaysRaw = sp.get('availableDays') ?? '';
    const timePreference = sp.get('timePreference') ?? '';
    const page = Math.max(1, parseInt(sp.get('page') ?? '1', 10));
    const pageSize = Math.min(48, Math.max(1, parseInt(sp.get('pageSize') ?? '12', 10)));

    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let dbQuery = supabase
      .from('player_profiles')
      .select('*', { count: 'exact' });

    if (query) {
      dbQuery = dbQuery.or(
        `display_name.ilike.%${query}%,bio.ilike.%${query}%,city.ilike.%${query}%`
      );
    }

    if (city) {
      dbQuery = dbQuery.ilike('city', `%${city}%`);
    }

    if (state) {
      dbQuery = dbQuery.ilike('state', `%${state}%`);
    }

    if (country) {
      dbQuery = dbQuery.ilike('country', `%${country}%`);
    }

    if (experienceLevelRaw) {
      const levels = experienceLevelRaw.split(',').filter(Boolean);
      if (levels.length > 0) {
        dbQuery = dbQuery.in('experience_level', levels);
      }
    }

    if (gamesRaw) {
      const gameNames = gamesRaw.split(',').filter(Boolean);
      for (const gameName of gameNames) {
        dbQuery = dbQuery.contains('favorite_games', [{ gameName }]);
      }
    }

    if (availableDaysRaw) {
      const days = availableDaysRaw.split(',').filter(Boolean);
      for (const day of days) {
        dbQuery = dbQuery.eq(`availability->>${day}`, 'true');
      }
    }

    if (timePreference) {
      dbQuery = dbQuery.eq('availability->>timePreference', timePreference);
    }

    dbQuery = dbQuery
      .order('rating', { ascending: false, nullsFirst: false })
      .order('review_count', { ascending: false })
      .range(from, to);

    const { data, error, count } = await dbQuery;

    if (error) {
      console.error('Supabase query error:', error);
      return NextResponse.json(
        { error: 'Failed to fetch players', details: error.message },
        { status: 500, headers: corsHeaders }
      );
    }

    const players: PlayerProfile[] = (data ?? []).map((row) =>
      toPlayerProfile(row as Record<string, unknown>)
    );

    const total = count ?? 0;
    const totalPages = Math.ceil(total / pageSize);

    const result: PlayerSearchResult = {
      players,
      total,
      page,
      pageSize,
      totalPages,
    };

    return NextResponse.json(result, { headers: corsHeaders });
  } catch (err) {
    console.error('Unexpected error in players/search:', err);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    );
  }
}
