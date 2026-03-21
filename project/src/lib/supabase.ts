import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

/**
 * Browser-side Supabase client, typed with the full Database schema.
 *
 * Import this in Client Components and browser-side utility modules.
 * For Server Components and Route Handlers use the server client
 * from '@/lib/supabase/server' instead.
 */
export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey);

/**
 * Helper that returns the typed browser client.
 * Useful when you need to pass the client as a dependency.
 */
export function getSupabaseClient() {
  return supabase;
}

// Re-export createClient so database.ts can instantiate its own typed client
// without duplicating the import path.
export { createClient };
