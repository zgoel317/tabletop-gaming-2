import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// Typed Supabase client for browser/client-side usage.
// Uses the anon key and respects Row Level Security (RLS).
// The Database generic provides full TypeScript type inference
// on all table queries throughout the application.
export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey);
