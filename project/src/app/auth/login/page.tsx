'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import AuthForm from '@/components/auth/AuthForm';
import InputField from '@/components/auth/InputField';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      const { error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError) {
        setError(authError.message);
        return;
      }

      router.push('/dashboard');
    } catch {
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <AuthForm
      title="Welcome back"
      subtitle="Sign in to your TabletopConnect account"
      onSubmit={handleSubmit}
      submitLabel="Sign In"
      isLoading={isLoading}
      error={error}
    >
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
        placeholder="••••••••"
        autoComplete="current-password"
      />
      <p className="text-sm text-center text-gray-600">
        Don&apos;t have an account?{' '}
        <Link
          href="/auth/signup"
          className="text-indigo-600 hover:text-indigo-500 font-medium"
        >
          Sign up
        </Link>
      </p>
    </AuthForm>
  );
}
