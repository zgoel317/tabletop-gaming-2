import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '@/lib/supabase/types'

/**
 * Browser-side Supabase client — safe to use in React components and hooks.
 * Typed against the Database interface generated from our schema.
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  )
}

/**
 * Singleton browser client for use outside React (utilities, etc.)
 */
export const supabase = createClient()
