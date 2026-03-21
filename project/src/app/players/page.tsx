'use client';

import React, { useState, useCallback, useEffect, useRef } from 'react';
import type { PlayerSearchFilters, PlayerSearchResult } from '@/types/player';
import { PlayerFilters, PlayerGrid, Pagination } from '@/components/players';
import { buildSearchParams } from '@/lib/playerUtils';

export default function PlayersPage() {
  const [filters, setFilters] = useState<PlayerSearchFilters>({});
  const [results, setResults] = useState<PlayerSearchResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const fetchPlayers = useCallback(async (currentFilters: PlayerSearchFilters) => {
    setLoading(true);
    setError(null);
    try {
      const params = buildSearchParams(currentFilters);
      const res = await fetch(`/api/players/search?${params.toString()}`);
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.error ?? `Request failed with status ${res.status}`);
      }
      const data: PlayerSearchResult = await res.json();
      setResults(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch players');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      fetchPlayers(filters);
    }, 300);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [filters, fetchPlayers]);

  const handleFiltersChange = useCallback((updated: PlayerSearchFilters) => {
    setFilters(updated);
  }, []);

  const handlePageChange = useCallback((page: number) => {
    setFilters((prev) => ({ ...prev, page }));
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, []);

  const handleMessageClick = useCallback((playerId: string) => {
    // TODO: open messaging UI
    console.log('Message player:', playerId);
  }, []);

  const currentPage = filters.page ?? 1;
  const totalPages = results?.totalPages ?? 0;

  return (
    <main className="min-h-screen">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Find Players</h1>
        <p className="mt-1 text-gray-500">Connect with tabletop gamers in your area</p>
        {results && !loading && (
          <p className="mt-2 text-sm text-gray-400">
            Showing{' '}
            <span className="font-medium text-gray-600">{results.players.length}</span> of{' '}
            <span className="font-medium text-gray-600">{results.total}</span> players
          </p>
        )}
        {error && (
          <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
            {error}
          </div>
        )}
      </div>

      {/* Mobile Filters Toggle */}
      <div className="md:hidden mb-4">
        <button
          onClick={() => setMobileFiltersOpen((prev) => !prev)}
          className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z" />
          </svg>
          {mobileFiltersOpen ? 'Hide Filters' : 'Show Filters'}
        </button>
      </div>

      {/* Mobile Filters Panel */}
      {mobileFiltersOpen && (
        <div className="md:hidden mb-6">
          <PlayerFilters filters={filters} onChange={handleFiltersChange} />
        </div>
      )}

      {/* Layout */}
      <div className="flex gap-8 items-start">
        {/* Sidebar Filters (desktop) */}
        <aside className="hidden md:block w-72 flex-shrink-0 sticky top-24">
          <PlayerFilters filters={filters} onChange={handleFiltersChange} />
        </aside>

        {/* Main Content */}
        <div className="flex-1 min-w-0">
          <PlayerGrid
            players={results?.players ?? []}
            loading={loading}
            onMessageClick={handleMessageClick}
          />
          {totalPages > 1 && (
            <Pagination
              currentPage={currentPage}
              totalPages={totalPages}
              onPageChange={handlePageChange}
            />
          )}
        </div>
      </div>
    </main>
  );
}
