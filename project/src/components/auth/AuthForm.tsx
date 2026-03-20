import React from 'react';

interface AuthFormProps {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  onSubmit: (e: React.FormEvent) => void;
  submitLabel: string;
  isLoading: boolean;
  error?: string | null;
}

export default function AuthForm({
  title,
  subtitle,
  children,
  onSubmit,
  submitLabel,
  isLoading,
  error,
}: AuthFormProps) {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div className="max-w-md w-full mx-auto mt-16 p-8 rounded-xl shadow-lg bg-white">
        {/* Header */}
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-1">{title}</h1>
          {subtitle && <p className="text-sm text-gray-600">{subtitle}</p>}
        </div>

        {/* Error alert */}
        {error && (
          <div className="mb-4 px-4 py-3 rounded-md bg-red-50 border border-red-200">
            <p className="text-sm text-red-700">{error}</p>
          </div>
        )}

        {/* Form */}
        <form onSubmit={onSubmit} noValidate className="space-y-4">
          {children}

          <button
            type="submit"
            disabled={isLoading}
            className="w-full mt-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-400 disabled:cursor-not-allowed text-white font-medium py-2 px-4 rounded-md text-sm transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            {isLoading ? 'Loading...' : submitLabel}
          </button>
        </form>
      </div>
    </div>
  );
}
