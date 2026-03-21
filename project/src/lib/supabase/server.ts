import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@/types/database';

/**
 * Server-side Supabase client factory, typed with the full Database schema.
 *
 * Call this function inside Server Components, Server Actions, and Route
 * Handlers. A new client is created per request so that cookies (and
 * therefore the user session) are correctly scoped.
 *
 * Example:
 *   const supabase = createSupabaseServerClient();
 *   const { data: { user } } = await supabase.auth.getUser();
 */
export function createSupabaseServerClient() {
  const cookieStore = cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch {
            // set() can throw in read-only Server Component contexts;
            // the middleware is responsible for refreshing the session.
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: '', ...options });
          } catch {
            // Same as above — safe to ignore in read-only contexts.
          }
        },
      },
    }
  );
}
