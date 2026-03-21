import type { ExperienceLevel, Availability, PlayerSearchFilters } from '@/types/player';

export function getExperienceBadgeColor(level: ExperienceLevel): string {
  switch (level) {
    case 'beginner':
      return 'bg-green-100 text-green-800';
    case 'intermediate':
      return 'bg-blue-100 text-blue-800';
    case 'advanced':
      return 'bg-purple-100 text-purple-800';
    case 'expert':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
}

export function formatExperienceLevel(level: ExperienceLevel): string {
  return level.charAt(0).toUpperCase() + level.slice(1);
}

export function getAvailableDays(availability: Availability | null): string[] {
  if (!availability) return [];
  const days: Array<keyof Omit<Availability, 'timePreference'>> = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  return days.filter((day) => availability[day] === true);
}

export function formatDayAbbreviation(day: string): string {
  const map: Record<string, string> = {
    monday: 'Mon',
    tuesday: 'Tue',
    wednesday: 'Wed',
    thursday: 'Thu',
    friday: 'Fri',
    saturday: 'Sat',
    sunday: 'Sun',
  };
  return map[day] ?? day;
}

export function formatRating(rating: number | null): string {
  if (rating === null) return '—';
  return rating.toFixed(1);
}

export function buildSearchParams(filters: PlayerSearchFilters): URLSearchParams {
  const params = new URLSearchParams();

  const entries = Object.entries(filters) as [keyof PlayerSearchFilters, unknown][];

  for (const [key, value] of entries) {
    if (value === undefined || value === null || value === '') continue;
    if (Array.isArray(value)) {
      if (value.length === 0) continue;
      params.set(key, value.join(','));
    } else {
      params.set(key, String(value));
    }
  }

  return params;
}

export function getPlayerInitials(displayName: string): string {
  const words = displayName.trim().split(/\s+/);
  if (words.length === 0) return '';
  if (words.length === 1) return words[0].charAt(0).toUpperCase();
  return (
    words[0].charAt(0).toUpperCase() +
    words[words.length - 1].charAt(0).toUpperCase()
  );
}
