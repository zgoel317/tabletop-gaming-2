/**
 * Authentication utilities for Supabase Auth operations.
 * Wraps Supabase auth methods with proper error handling and type safety.
 */

import { createClient } from '@/lib/supabase';
import { createClient as createServerClient } from '@/lib/supabase/server';
import type { User, Session, AuthError } from '@supabase/supabase-js';

export interface AuthResult {
  user: User | null;
  session: Session | null;
  error: AuthError | null;
}

// ============================================================
// SIGN UP / SIGN IN
// ============================================================

/**
 * Sign up a new user with email and password.
 * A profile is automatically created via database trigger.
 */
export async function signUpWithEmail(
  email: string,
  password: string,
  metadata?: {
    username?: string;
    display_name?: string;
    full_name?: string;
  }
): Promise<AuthResult> {
  const supabase = createClient();

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: metadata,
    },
  });

  return {
    user: data.user,
    session: data.session,
    error,
  };
}

/**
 * Sign in an existing user with email and password.
 */
export async function signInWithEmail(
  email: string,
  password: string
): Promise<AuthResult> {
  const supabase = createClient();

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  return {
    user: data.user,
    session: data.session,
    error,
  };
}

/**
 * Sign in with a third-party OAuth provider.
 */
export async function signInWithOAuth(
  provider: 'google' | 'github' | 'discord',
  redirectTo?: string
): Promise<{ url: string | null; error: AuthError | null }> {
  const supabase = createClient();

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: redirectTo ?? `${window.location.origin}/auth/callback`,
    },
  });

  return { url: data.url, error };
}

/**
 * Sign in with a magic link (passwordless).
 */
export async function signInWithMagicLink(
  email: string,
  redirectTo?: string
): Promise<{ error: AuthError | null }> {
  const supabase = createClient();

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: redirectTo ?? `${window.location.origin}/auth/callback`,
    },
  });

  return { error };
}

// ============================================================
// SESSION MANAGEMENT
// ============================================================

/**
 * Get the current authenticated user (client-side).
 */
export async function getCurrentUser(): Promise<User | null> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * Get the current authenticated user (server-side).
 */
export async function getCurrentUserServer(): Promise<User | null> {
  const supabase = await createServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * Get the current session (client-side).
 */
export async function getCurrentSession(): Promise<Session | null> {
  const supabase = createClient();
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

/**
 * Sign out the current user.
 */
export async function signOut(): Promise<{ error: AuthError | null }> {
  const supabase = createClient();
  const { error } = await supabase.auth.signOut();
  return { error };
}

// ============================================================
// PASSWORD MANAGEMENT
// ============================================================

/**
 * Send a password reset email.
 */
export async function sendPasswordResetEmail(
  email: string,
  redirectTo?: string
): Promise<{ error: AuthError | null }> {
  const supabase = createClient();

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: redirectTo ?? `${window.location.origin}/auth/reset-password`,
  });

  return { error };
}

/**
 * Update the user's password (after reset flow).
 */
export async function updatePassword(
  newPassword: string
): Promise<{ user: User | null; error: AuthError | null }> {
  const supabase = createClient();

  const { data, error } = await supabase.auth.updateUser({
    password: newPassword,
  });

  return { user: data.user, error };
}

/**
 * Update the user's email address.
 */
export async function updateEmail(
  newEmail: string
): Promise<{ user: User | null; error: AuthError | null }> {
  const supabase = createClient();

  const { data, error } = await supabase.auth.updateUser({
    email: newEmail,
  });

  return { user: data.user, error };
}

// ============================================================
// AUTH STATE
// ============================================================

/**
 * Subscribe to auth state changes.
 * Returns an unsubscribe function.
 */
export function onAuthStateChange(
  callback: (user: User | null, session: Session | null) => void
): () => void {
  const supabase = createClient();

  const { data: { subscription } } = supabase.auth.onAuthStateChange(
    (_event, session) => {
      callback(session?.user ?? null, session);
    }
  );

  return () => subscription.unsubscribe();
}
