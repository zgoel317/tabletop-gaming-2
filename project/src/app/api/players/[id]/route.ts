import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabase/server';
import type { PlayerProfile } from '@/types/player';

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

export async function GET(
  _request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const supabase = createServerClient();

    const { data, error } = await supabase
      .from('player_profiles')
      .select('*')
      .eq('id', params.id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return NextResponse.json(
          { error: 'Player not found' },
          { status: 404, headers: corsHeaders }
        );
      }
      console.error('Supabase error fetching player:', error);
      return NextResponse.json(
        { error: 'Failed to fetch player', details: error.message },
        { status: 500, headers: corsHeaders }
      );
    }

    if (!data) {
      return NextResponse.json(
        { error: 'Player not found' },
        { status: 404, headers: corsHeaders }
      );
    }

    const player = toPlayerProfile(data as Record<string, unknown>);
    return NextResponse.json(player, { headers: corsHeaders });
  } catch (err) {
    console.error('Unexpected error fetching player by id:', err);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    );
  }
}
