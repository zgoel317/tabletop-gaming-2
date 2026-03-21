'use client';

import React, { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import type { PlayerProfile } from '@/types/player';
import {
  getExperienceBadgeColor,
  formatExperienceLevel,
  getAvailableDays,
  formatDayAbbreviation,
  formatRating,
  getPlayerInitials,
} from '@/lib/playerUtils';

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-1">
      {Array.from({ length: 5 }).map((_, i) => (
        <svg
          key={i}
          className={`w-5 h-5 ${i < Math.round(rating) ? 'text-yellow-400' : 'text-gray-300'}`}
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
        </svg>
      ))}
      <span className="ml-1 text-sm text-gray-600">
        {formatRating(rating)} ({0} reviews)
      </span>
    </div>
  );
}

function ProfileSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="bg-indigo-200 h-48 w-full" />
      <div className="max-w-4xl mx-auto px-4 -mt-8">
        <div className="bg-white rounded-2xl shadow-lg p-6 flex flex-col gap-4">
          <div className="w-24 h-24 rounded-full bg-gray-300 -mt-16 border-4 border-white" />
          <div className="h-6 bg-gray-200 rounded w-48" />
          <div className="h-4 bg-gray-200 rounded w-32" />
          <div className="h-4 bg-gray-200 rounded w-full" />
          <div className="h-4 bg-gray-200 rounded w-3/4" />
        </div>
      </div>
    </div>
  );
}

export default function PlayerDetailPage() {
  const params = useParams();
  const id = params?.id as string;

  const [player, setPlayer] = useState<PlayerProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    fetch(`/api/players/${id}`)
      .then(async (res) => {
        if (res.status === 404) {
          setNotFound(true);
          return;
        }
        if (!res.ok) throw new Error('Failed to fetch player');
        const data: PlayerProfile = await res.json();
        setPlayer(data);
      })
      .catch(() => setNotFound(true))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <ProfileSkeleton />;

  if (notFound || !player) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center">
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
            d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <h2 className="text-2xl font-bold text-gray-700 mb-2">Player Not Found</h2>
        <p className="text-gray-500 mb-6">
          The player you&apos;re looking for doesn&apos;t exist or has been removed.
        </p>
        <Link
          href="/players"
          className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition-colors"
        >
          Back to Players
        </Link>
      </div>
    );
  }

  const availableDays = getAvailableDays(player.availability);
  const allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  const location = [player.city, player.state, player.country].filter(Boolean).join(', ');

  return (
    <div className="min-h-screen">
      {/* Hero Banner */}
      <div className="bg-indigo-700 h-48 w-full relative -mx-4 sm:-mx-6 lg:-mx-8 px-4 sm:px-6 lg:px-8 flex items-end pb-0">
        <div className="absolute inset-0 bg-gradient-to-br from-indigo-800 to-indigo-600" />
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto -mt-8 relative">
        <div className="lg:flex lg:gap-8 items-start">
          {/* Main Card */}
          <div className="flex-1 bg-white rounded-2xl shadow-lg overflow-hidden">
            {/* Profile Header */}
            <div className="px-6 pb-6 pt-0">
              <div className="flex flex-col sm:flex-row sm:items-end gap-4 -mt-12 mb-4">
                {/* Avatar */}
                <div className="flex-shrink-0">
                  {player.avatarUrl ? (
                    <Image
                      src={player.avatarUrl}
                      alt={player.displayName}
                      width={96}
                      height={96}
                      className="rounded-full object-cover w-24 h-24 border-4 border-white shadow-md"
                      unoptimized
                    />
                  ) : (
                    <div className="w-24 h-24 rounded-full bg-indigo-500 flex items-center justify-center text-white text-3xl font-bold border-4 border-white shadow-md select-none">
                      {getPlayerInitials(player.displayName)}
                    </div>
                  )}
                </div>
                {/* Name & Location */}
                <div className="pb-1">
                  <h1 className="text-2xl font-bold text-gray-900">{player.displayName}</h1>
                  {location && (
                    <div className="flex items-center gap-1 text-gray-500 text-sm mt-0.5">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      {location}
                    </div>
                  )}
                </div>
              </div>

              {/* Experience + Rating Row */}
              <div className="flex flex-wrap items-center gap-3 mb-5">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getExperienceBadgeColor(player.experienceLevel)}`}>
                  {formatExperienceLevel(player.experienceLevel)}
                </span>
                {player.rating !== null && (
                  <StarRating rating={player.rating} />
                )}
              </div>

              <hr className="border-gray-100 mb-5" />

              {/* Bio */}
              {player.bio && (
                <div className="mb-6">
                  <h3 className="text-base font-semibold text-gray-900 mb-2">About</h3>
                  <p className="text-gray-600 text-sm leading-relaxed">{player.bio}</p>
                </div>
              )}

              {/* Favorite Games */}
              {player.favoriteGames.length > 0 && (
                <div className="mb-6">
                  <h3 className="text-base font-semibold text-gray-900 mb-3">Favorite Games</h3>
                  <div className="flex flex-wrap gap-2">
                    {player.favoriteGames.map((game) => (
                      <span
                        key={game.gameId}
                        className="inline-flex items-center px-3 py-1.5 rounded-full text-sm bg-indigo-50 text-indigo-800 font-medium"
                      >
                        {game.gameName}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Availability */}
              {player.availability && (
                <div className="mb-2">
                  <h3 className="text-base font-semibold text-gray-900 mb-3">Availability</h3>
                  <div className="flex flex-wrap gap-2 mb-3">
                    {allDays.map((day) => {
                      const isAvailable = availableDays.includes(day);
                      return (
                        <span
                          key={day}
                          className={`px-3 py-1.5 rounded-full text-xs font-medium ${
                            isAvailable
                              ? 'bg-green-100 text-green-800'
                              : 'bg-gray-100 text-gray-400'
                          }`}
                        >
                          {formatDayAbbreviation(day)}
                        </span>
                      );
                    })}
                  </div>
                  {player.availability.timePreference && (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-blue-50 text-blue-800">
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      Prefers {player.availability.timePreference}
                    </span>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Sidebar */}
          <div className="lg:w-64 flex-shrink-0 mt-6 lg:mt-0 lg:sticky lg:top-4 flex flex-col gap-3">
            <button className="w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-xl transition-colors shadow-sm">
              Message {player.displayName.split(' ')[0]}
            </button>
            <Link
              href="/players"
              className="w-full py-2.5 px-4 border border-gray-300 text-gray-700 text-sm font-medium rounded-xl hover:bg-gray-50 transition-colors text-center block"
            >
              ← Back to Players
            </Link>
            <button className="text-sm text-gray-400 hover:text-gray-600 transition-colors mt-1 text-center">
              Report Player
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
