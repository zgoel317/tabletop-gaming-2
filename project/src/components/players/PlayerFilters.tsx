'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import type { PlayerSearchFilters, ExperienceLevel, Availability } from '@/types/player';

interface PlayerFiltersProps {
  filters: PlayerSearchFilters;
  onChange: (filters: PlayerSearchFilters) => void;
  className?: string;
}

const EXPERIENCE_LEVELS: ExperienceLevel[] = ['beginner', 'intermediate', 'advanced', 'expert'];
const DAYS: Array<keyof Omit<Availability, 'timePreference'>> = [
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
];
const DAY_LABELS: Record<string, string> = {
  monday: 'Monday', tuesday: 'Tuesday', wednesday: 'Wednesday',
  thursday: 'Thursday', friday: 'Friday', saturday: 'Saturday', sunday: 'Sunday',
};
const TIME_PREFS: Array<Availability['timePreference']> = [
  'morning', 'afternoon', 'evening', 'night', 'flexible',
];

export default function PlayerFilters({ filters, onChange, className = '' }: PlayerFiltersProps) {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [queryInput, setQueryInput] = useState(filters.query ?? '');
  const [gameInput, setGameInput] = useState('');
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Sync queryInput when filters.query changes externally
  useEffect(() => {
    if (filters.query !== undefined && filters.query !== queryInput) {
      setQueryInput(filters.query);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters.query]);

  // Debounce query input
  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      if (queryInput !== (filters.query ?? '')) {
        onChange({ ...filters, query: queryInput, page: 1 });
      }
    }, 400);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [queryInput]);

  const handleLocationChange = useCallback(
    (field: 'city' | 'state' | 'country', value: string) => {
      onChange({ ...filters, [field]: value, page: 1 });
    },
    [filters, onChange]
  );

  const handleExperienceToggle = useCallback(
    (level: ExperienceLevel) => {
      const current = filters.experienceLevel ?? [];
      const updated = current.includes(level)
        ? current.filter((l) => l !== level)
        : [...current, level];
      onChange({ ...filters, experienceLevel: updated, page: 1 });
    },
    [filters, onChange]
  );

  const handleDayToggle = useCallback(
    (day: keyof Omit<Availability, 'timePreference'>) => {
      const current = filters.availableDays ?? [];
      const updated = current.includes(day)
        ? current.filter((d) => d !== day)
        : [...current, day];
      onChange({ ...filters, availableDays: updated, page: 1 });
    },
    [filters, onChange]
  );

  const handleTimePreference = useCallback(
    (pref: Availability['timePreference']) => {
      onChange({ ...filters, timePreference: pref, page: 1 });
    },
    [filters, onChange]
  );

  const handleAddGame = useCallback(
    (name: string) => {
      const trimmed = name.trim().replace(/,$/, '').trim();
      if (!trimmed) return;
      const current = filters.games ?? [];
      if (!current.includes(trimmed)) {
        onChange({ ...filters, games: [...current, trimmed], page: 1 });
      }
      setGameInput('');
    },
    [filters, onChange]
  );

  const handleGameInputKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      handleAddGame(gameInput);
    }
  };

  const handleRemoveGame = useCallback(
    (name: string) => {
      const current = filters.games ?? [];
      onChange({ ...filters, games: current.filter((g) => g !== name), page: 1 });
    },
    [filters, onChange]
  );

  const handleReset = useCallback(() => {
    setQueryInput('');
    setGameInput('');
    onChange({});
  }, [onChange]);

  const inputClass =
    'border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 w-full';
  const labelClass = 'block text-sm font-semibold text-gray-700 mb-1';
  const sectionClass = 'border-t border-gray-200 pt-4 mt-4';

  const filterContent = (
    <div className="flex flex-col gap-0">
      {/* Search */}
      <div>
        <label className={labelClass}>Search</label>
        <input
          type="text"
          className={inputClass}
          placeholder="Search by name or bio..."
          value={queryInput}
          onChange={(e) => setQueryInput(e.target.value)}
        />
      </div>

      {/* Location */}
      <div className={sectionClass}>
        <p className={labelClass}>Location</p>
        <div className="flex flex-col gap-2">
          <div>
            <label className="block text-xs text-gray-500 mb-0.5">City</label>
            <input
              type="text"
              className={inputClass}
              placeholder="e.g. Portland"
              value={filters.city ?? ''}
              onChange={(e) => handleLocationChange('city', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-0.5">State / Province</label>
            <input
              type="text"
              className={inputClass}
              placeholder="e.g. Oregon"
              value={filters.state ?? ''}
              onChange={(e) => handleLocationChange('state', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-0.5">Country</label>
            <input
              type="text"
              className={inputClass}
              placeholder="e.g. USA"
              value={filters.country ?? ''}
              onChange={(e) => handleLocationChange('country', e.target.value)}
            />
          </div>
        </div>
      </div>

      {/* Experience Level */}
      <div className={sectionClass}>
        <p className={labelClass}>Experience Level</p>
        <div className="flex flex-col gap-2">
          {EXPERIENCE_LEVELS.map((level) => (
            <label key={level} className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                checked={(filters.experienceLevel ?? []).includes(level)}
                onChange={() => handleExperienceToggle(level)}
              />
              <span className="text-sm text-gray-700 capitalize">{level}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Availability Days */}
      <div className={sectionClass}>
        <p className={labelClass}>Availability</p>
        <div className="flex flex-col gap-2">
          {DAYS.map((day) => (
            <label key={day} className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                checked={(filters.availableDays ?? []).includes(day)}
                onChange={() => handleDayToggle(day)}
              />
              <span className="text-sm text-gray-700">{DAY_LABELS[day]}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Time Preference */}
      <div className={sectionClass}>
        <p className={labelClass}>Time Preference</p>
        <div className="flex flex-col gap-2">
          {TIME_PREFS.map((pref) => (
            <label key={pref} className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="timePreference"
                className="w-4 h-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                checked={filters.timePreference === pref}
                onChange={() => handleTimePreference(pref)}
              />
              <span className="text-sm text-gray-700 capitalize">{pref}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Games */}
      <div className={sectionClass}>
        <p className={labelClass}>Games</p>
        <input
          type="text"
          className={inputClass}
          placeholder="Add a game, press Enter..."
          value={gameInput}
          onChange={(e) => setGameInput(e.target.value)}
          onKeyDown={handleGameInputKeyDown}
          onBlur={() => {
            if (gameInput.trim()) handleAddGame(gameInput);
          }}
        />
        {(filters.games ?? []).length > 0 && (
          <div className="flex flex-wrap gap-1.5 mt-2">
            {(filters.games ?? []).map((game) => (
              <span
                key={game}
                className="flex items-center gap-1 text-xs bg-indigo-100 text-indigo-800 rounded-full px-2.5 py-1"
              >
                {game}
                <button
                  onClick={() => handleRemoveGame(game)}
                  className="ml-0.5 hover:text-indigo-600 focus:outline-none"
                  aria-label={`Remove ${game}`}
                >
                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Reset */}
      <div className={sectionClass}>
        <button
          onClick={handleReset}
          className="w-full py-2 px-4 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
        >
          Reset Filters
        </button>
      </div>
    </div>
  );

  return (
    <div className={className}>
      {/* Mobile toggle button */}
      <div className="md:hidden mb-4">
        <button
          onClick={() => setMobileOpen((prev) => !prev)}
          className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z" />
          </svg>
          Filters
          {mobileOpen ? (
            <svg className="w-4 h-4 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
            </svg>
          ) : (
            <svg className="w-4 h-4 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          )}
        </button>
      </div>

      {/* Desktop: always visible; Mobile: collapsible */}
      <div className={`bg-white rounded-xl shadow-sm border border-gray-200 p-5 ${mobileOpen ? 'block' : 'hidden md:block'}`}>
        {filterContent}
      </div>
    </div>
  );
}
