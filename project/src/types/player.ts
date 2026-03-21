export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert';

export interface Availability {
  monday: boolean;
  tuesday: boolean;
  wednesday: boolean;
  thursday: boolean;
  friday: boolean;
  saturday: boolean;
  sunday: boolean;
  timePreference: 'morning' | 'afternoon' | 'evening' | 'night' | 'flexible';
}

export interface GamePreference {
  gameId: string;
  gameName: string;
  bggId?: number;
}

export interface PlayerProfile {
  id: string;
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  city: string | null;
  state: string | null;
  country: string | null;
  latitude: number | null;
  longitude: number | null;
  experienceLevel: ExperienceLevel;
  favoriteGames: GamePreference[];
  availability: Availability | null;
  rating: number | null;
  reviewCount: number;
  createdAt: string;
}

export interface PlayerSearchFilters {
  query?: string;
  city?: string;
  state?: string;
  country?: string;
  experienceLevel?: ExperienceLevel[];
  games?: string[];
  availableDays?: Array<keyof Omit<Availability, 'timePreference'>>;
  timePreference?: Availability['timePreference'];
  maxDistanceKm?: number;
  page?: number;
  pageSize?: number;
}

export interface PlayerSearchResult {
  players: PlayerProfile[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
