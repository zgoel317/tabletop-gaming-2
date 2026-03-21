'use client';

import React from 'react';
import type { PlayerProfile } from '@/types/player';
import PlayerCard from './PlayerCard';

interface PlayerGridProps {
  players: PlayerProfile[];
  loading: boolean;
  onMessageClick?: (playerId: string) => void;
}

function SkeletonCard() {
  return (
    <div className="bg-gray-200 rounded-xl animate-pulse h-64" />
  );
}

function EmptyState() {
  return (
    <div className="col-span-full flex flex-col items-center justify-center py-20 text-center">
      <svg
        className="w-16 h-16 text-gray-300 mb-4"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={1.5}
          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
        />
      </svg>
      <h3 className="text-lg font-semibold text-gray-600 mb-1">No players found</h3>
      <p className="text-sm text-gray-400">Try adjusting your filters</p>
    </div>
  );
}

export default function PlayerGrid({ players, loading, onMessageClick }: PlayerGridProps) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {loading ? (
        Array.from({ length: 12 }).map((_, i) => <SkeletonCard key={i} />)
      ) : players.length === 0 ? (
        <EmptyState />
      ) : (
        players.map((player) => (
          <PlayerCard key={player.id} player={player} onMessageClick={onMessageClick} />
        ))
      )}
    </div>
  );
}
