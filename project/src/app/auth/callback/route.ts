import { NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabase/server';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code');

  if (code) {
    try {
      const supabase = createServerClient();
      await supabase.auth.exchangeCodeForSession(code);
    } catch {
      return NextResponse.redirect(
        new URL('/auth/login?error=auth_callback_error', request.url)
      );
    }
  }

  return NextResponse.redirect(new URL('/dashboard', request.url));
}
