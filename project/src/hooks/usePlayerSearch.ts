import { useState, useEffect, useCallback, useRef } from 'react';
import type { PlayerSearchFilters, PlayerSearchResult } from '@/types/player';
import { buildSearchParams } from '@/lib/playerUtils';

export interface UsePlayerSearchReturn {
  filters: PlayerSearchFilters;
  setFilters: React.Dispatch<React.SetStateAction<PlayerSearchFilters>>;
  results: PlayerSearchResult | null;
  loading: boolean;
  error: string | null;
  setPage: (page: number) => void;
}

export function usePlayerSearch(): UsePlayerSearchReturn {
  const [filters, setFilters] = useState<PlayerSearchFilters>({});
  const [results, setResults] = useState<PlayerSearchResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
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

  const setPage = useCallback((page: number) => {
    setFilters((prev) => ({ ...prev, page }));
  }, []);

  return { filters, setFilters, results, loading, error, setPage };
}
