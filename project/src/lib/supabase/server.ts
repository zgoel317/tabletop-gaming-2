import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/lib/database.types";

/**
 * Creates a Supabase server client with full Database type safety.
 *
 * Use this in Server Components, Route Handlers, and Server Actions.
 *
 * Example:
 *   const supabase = await createClient()
 *   const { data } = await supabase.from('profiles').select('*')
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // setAll is called from a Server Component where cookies
            // cannot be mutated. This is safe to ignore if you have
            // a middleware refreshing sessions.
          }
        },
      },
    }
  );
}
