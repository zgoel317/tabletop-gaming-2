import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "@/lib/database.types";

/**
 * Creates a Supabase browser client with full Database type safety.
 *
 * Use this in Client Components ("use client") and browser-side code.
 *
 * Example:
 *   const supabase = createClient()
 *   const { data } = await supabase.from('profiles').select('*')
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
