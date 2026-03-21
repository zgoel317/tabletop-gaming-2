'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import type { PlayerProfile } from '@/types/player';
import {
  getExperienceBadgeColor,
  formatExperienceLevel,
  getAvailableDays,
  formatDayAbbreviation,
  formatRating,
  getPlayerInitials,
} from '@/lib/playerUtils';

interface PlayerCardProps {
  player: PlayerProfile;
  onMessageClick?: (playerId: string) => void;
}

export default function PlayerCard({ player, onMessageClick }: PlayerCardProps) {
  const availableDays = getAvailableDays(player.availability);
  const displayGames = player.favoriteGames.slice(0, 3);
  const hasLocation = player.city || player.state;

  return (
    <div className="bg-white rounded-xl shadow-md hover:shadow-lg transition-shadow duration-200 overflow-hidden flex flex-col">
      <Link href={`/players/${player.id}`} className="flex-1 p-5 flex flex-col gap-3">
        {/* Avatar + Name */}
        <div className="flex items-center gap-3">
          <div className="flex-shrink-0">
            {player.avatarUrl ? (
              <Image
                src={player.avatarUrl}
                alt={player.displayName}
                width={64}
                height={64}
                className="rounded-full object-cover w-16 h-16"
                unoptimized
              />
            ) : (
              <div className="w-16 h-16 rounded-full bg-indigo-500 flex items-center justify-center text-white text-xl font-bold select-none">
                {getPlayerInitials(player.displayName)}
              </div>
            )}
          </div>
          <div className="min-w-0">
            <h3 className="font-semibold text-gray-900 truncate">{player.displayName}</h3>
            {hasLocation && (
              <div className="flex items-center gap-1 text-sm text-gray-500 mt-0.5">
                <svg
                  className="w-3.5 h-3.5 flex-shrink-0"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <span className="truncate">
                  {[player.city, player.state].filter(Boolean).join(', ')}
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Experience + Rating */}
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <span
            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getExperienceBadgeColor(
              player.experienceLevel
            )}`}
          >
            {formatExperienceLevel(player.experienceLevel)}
          </span>
          {player.rating !== null && (
            <div className="flex items-center gap-1 text-sm text-gray-600">
              <svg
                className="w-4 h-4 text-yellow-400"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
              <span>{formatRating(player.rating)}</span>
              <span className="text-gray-400">({player.reviewCount} reviews)</span>
            </div>
          )}
        </div>

        {/* Favorite Games */}
        {displayGames.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {displayGames.map((game) => (
              <span
                key={game.gameId}
                className="text-xs bg-gray-100 text-gray-700 rounded-full px-2 py-1 truncate max-w-[120px]"
                title={game.gameName}
              >
                {game.gameName}
              </span>
            ))}
            {player.favoriteGames.length > 3 && (
              <span className="text-xs bg-gray-100 text-gray-500 rounded-full px-2 py-1">
                +{player.favoriteGames.length - 3}
              </span>
            )}
          </div>
        )}

        {/* Availability Days */}
        {availableDays.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {availableDays.map((day) => (
              <span
                key={day}
                className="flex items-center gap-1 text-xs text-gray-500"
              >
                <span className="w-1.5 h-1.5 rounded-full bg-green-400 inline-block" />
                {formatDayAbbreviation(day)}
              </span>
            ))}
          </div>
        )}
      </Link>

      {/* Message Button */}
      {onMessageClick && (
        <div className="px-5 pb-4">
          <button
            onClick={(e) => {
              e.preventDefault();
              onMessageClick(player.id);
            }}
            className="w-full py-2 px-4 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg transition-colors duration-150"
          >
            Message
          </button>
        </div>
      )}
    </div>
  );
}
