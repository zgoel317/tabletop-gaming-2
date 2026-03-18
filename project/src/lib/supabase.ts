import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database';

/**
 * Creates a Supabase client for use in browser/client components.
 * Uses the public anon key which is safe to expose on the client.
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}

/**
 * Singleton browser client instance for use throughout the app.
 * Prefer this over creating new instances in components.
 */
export const supabase = createClient();
