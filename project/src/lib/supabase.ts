import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database.types';

/**
 * Creates a Supabase client for use in browser/client components.
 * Uses the Database generic type for full type safety.
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}

/**
 * Singleton browser client for convenience in client components.
 * Use createClient() for SSR scenarios or when you need a fresh instance.
 */
export const supabase = createClient();
