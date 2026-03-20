'use client';

import { useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import AuthForm from '@/components/auth/AuthForm';
import InputField from '@/components/auth/InputField';

export default function SignupPage() {
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      setError('Password must be at least 8 characters long.');
      return;
    }

    setIsLoading(true);

    try {
      const { error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            display_name: displayName,
          },
        },
      });

      if (authError) {
        setError(authError.message);
        return;
      }

      setIsSuccess(true);
    } catch {
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }

  if (isSuccess) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
        <div className="max-w-md w-full mx-auto mt-16 p-8 rounded-xl shadow-lg bg-white text-center">
          <div className="mb-4">
            <div className="w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg
                className="w-8 h-8 text-indigo-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">
              Check your email
            </h1>
            <p className="text-gray-600">
              We&apos;ve sent a confirmation link to{' '}
              <span className="font-medium text-gray-900">{email}</span>.
              Click the link to activate your account.
            </p>
          </div>
          <Link
            href="/auth/login"
            className="text-indigo-600 hover:text-indigo-500 font-medium text-sm"
          >
            Return to sign in
          </Link>
        </div>
      </div>
    );
  }

  return (
    <AuthForm
      title="Create your account"
      subtitle="Join TabletopConnect and find your gaming group"
      onSubmit={handleSubmit}
      submitLabel="Create Account"
      isLoading={isLoading}
      error={error}
    >
      <InputField
        id="displayName"
        label="Display name"
        type="text"
        value={displayName}
        onChange={(e) => setDisplayName(e.target.value)}
        required
        placeholder="Your gamer name"
        autoComplete="name"
      />
      <InputField
        id="email"
        label="Email address"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
        placeholder="you@example.com"
        autoComplete="email"
      />
      <InputField
        id="password"
        label="Password"
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
        minLength={8}
        placeholder="At least 8 characters"
        autoComplete="new-password"
      />
      <InputField
        id="confirmPassword"
        label="Confirm password"
        type="password"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        required
        minLength={8}
        placeholder="Repeat your password"
        autoComplete="new-password"
      />
      <p className="text-sm text-center text-gray-600">
        Already have an account?{' '}
        <Link
          href="/auth/login"
          className="text-indigo-600 hover:text-indigo-500 font-medium"
        >
          Sign in
        </Link>
      </p>
    </AuthForm>
  );
}
