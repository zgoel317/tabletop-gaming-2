import Link from 'next/link';
import React from 'react';

export default function PlayersLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Link href="/" className="text-xl font-bold text-indigo-600">
            TableTop Connect
          </Link>
          <div className="flex items-center gap-4">
            <Link
              href="/players"
              className="text-sm font-medium text-gray-700 hover:text-indigo-600 transition-colors"
            >
              Find Players
            </Link>
            <Link
              href="/groups"
              className="text-sm font-medium text-gray-700 hover:text-indigo-600 transition-colors"
            >
              Groups
            </Link>
            <Link
              href="/events"
              className="text-sm font-medium text-gray-700 hover:text-indigo-600 transition-colors"
            >
              Events
            </Link>
          </div>
        </div>
      </nav>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">{children}</div>
    </div>
  );
}
