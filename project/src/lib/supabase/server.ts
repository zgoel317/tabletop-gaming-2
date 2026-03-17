import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/lib/supabase/types'

/**
 * Server-side Supabase client for use in Server Components,
 * Route Handlers, and Server Actions.
 *
 * Creates a new client per request (as required by Next.js).
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options })
          } catch {
            // set() can throw in Server Components — safe to ignore
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: '', ...options })
          } catch {
            // remove() can throw in Server Components — safe to ignore
          }
        },
      },
    },
  )
}

/**
 * Service-role client for privileged operations (webhooks, cron jobs, etc.)
 * NEVER expose this to the browser.
 */
export function createServiceClient() {
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      cookies: {
        get: () => undefined,
        set: () => {},
        remove: () => {},
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    },
  )
}
