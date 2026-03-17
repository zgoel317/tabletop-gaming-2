import { createBrowserClient } from '@supabase/ssr'
import type { Database } from './supabase/types'

/**
 * Creates a Supabase client for use in browser/client components.
 * Uses the Database generic for full type safety.
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

/**
 * Singleton browser client instance for convenience.
 * Use this in client components and hooks.
 */
export const supabase = createClient()

export type { Database } from './supabase/types'
