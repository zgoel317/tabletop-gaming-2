/**
 * TypeScript types for the groups and events database schema.
 * These mirror the PostgreSQL tables defined in the migration.
 */

// ============================================================
// ENUMS
// ============================================================

export type GroupRole = 'organizer' | 'co_organizer' | 'member';

export type GroupVisibility = 'public' | 'private' | 'invite_only';

export type MembershipStatus = 'pending' | 'active' | 'banned' | 'left';

export type EventStatus = 'draft' | 'published' | 'cancelled' | 'completed';

export type RsvpStatus = 'attending' | 'maybe' | 'declined' | 'waitlisted';

export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced' | 'all_levels';

export type LocationType =
  | 'home'
  | 'game_store'
  | 'library'
  | 'community_center'
  | 'online'
  | 'other';

// ============================================================
// DATABASE ROW TYPES (match exact DB columns)
// ============================================================

export interface GroupRow {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  short_description: string | null;

  // Location
  city: string | null;
  state_province: string | null;
  country: string | null;
  latitude: number | null;
  longitude: number | null;
  // location_point is a PostGIS geometry, typically omitted in API responses

  // Settings
  visibility: GroupVisibility;
  max_members: number | null;
  is_active: boolean;

  // Gaming focus
  primary_game_types: string[] | null;
  featured_games: string[] | null;
  experience_levels: ExperienceLevel[];

  // Media
  banner_image_url: string | null;
  avatar_image_url: string | null;

  // Social
  website_url: string | null;
  discord_url: string | null;
  rules: string | null;
  tags: string[] | null;

  // Ownership
  created_by: string;

  // Timestamps
  created_at: string;
  updated_at: string;
}

export interface GroupMembershipRow {
  id: string;
  group_id: string;
  user_id: string;
  role: GroupRole;
  status: MembershipStatus;
  invited_by: string | null;
  joined_at: string | null;
  left_at: string | null;
  ban_reason: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface EventRow {
  id: string;
  group_id: string | null;
  created_by: string;

  // Basic info
  title: string;
  slug: string;
  description: string | null;
  status: EventStatus;

  // Scheduling
  starts_at: string;
  ends_at: string | null;
  timezone: string;
  is_recurring: boolean;
  recurrence_rule: string | null;
  parent_event_id: string | null;

  // Location
  location_type: LocationType;
  location_name: string | null;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  state_province: string | null;
  country: string | null;
  postal_code: string | null;
  latitude: number | null;
  longitude: number | null;
  location_notes: string | null;
  online_url: string | null;

  // Capacity
  min_players: number | null;
  max_players: number | null;
  current_attendees: number;
  waitlist_enabled: boolean;
  waitlist_max: number | null;

  // Game details
  game_title: string | null;
  bgg_game_id: string | null;
  game_description: string | null;
  experience_level: ExperienceLevel;
  is_teach_session: boolean;

  // Requirements
  cost_per_person: number | null;
  cost_currency: string;
  supplies_needed: string[] | null;
  rules_summary: string | null;
  what_to_bring: string | null;
  age_requirement: number | null;

  // Media
  cover_image_url: string | null;
  image_urls: string[] | null;

  // Visibility
  is_public: boolean;
  requires_approval: boolean;

  // Timestamps
  created_at: string;
  updated_at: string;
  published_at: string | null;
  cancelled_at: string | null;
  cancellation_reason: string | null;
}

export interface EventRsvpRow {
  id: string;
  event_id: string;
  user_id: string;
  status: RsvpStatus;
  guests_count: number;
  note: string | null;
  waitlist_position: number | null;
  approved_by: string | null;
  approved_at: string | null;
  rejection_reason: string | null;
  checked_in_at: string | null;
  checked_in_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface GroupThreadRow {
  id: string;
  group_id: string;
  created_by: string;
  event_id: string | null;
  title: string;
  body: string;
  is_pinned: boolean;
  is_locked: boolean;
  reply_count: number;
  created_at: string;
  updated_at: string;
  last_reply_at: string | null;
}

export interface GroupThreadReplyRow {
  id: string;
  thread_id: string;
  created_by: string;
  parent_reply_id: string | null;
  body: string;
  is_deleted: boolean;
  created_at: string;
  updated_at: string;
}

export interface EventTemplateRow {
  id: string;
  group_id: string;
  created_by: string;
  name: string;
  description: string | null;
  default_title: string;
  default_description: string | null;
  default_duration_minutes: number | null;
  default_location_type: LocationType | null;
  default_location_name: string | null;
  default_address_line1: string | null;
  default_city: string | null;
  default_state_province: string | null;
  default_country: string | null;
  default_max_players: number | null;
  default_game_title: string | null;
  default_bgg_game_id: string | null;
  default_experience_level: ExperienceLevel;
  default_cost_per_person: number | null;
  default_what_to_bring: string | null;
  default_supplies_needed: string[] | null;
  recurrence_rule: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ============================================================
// VIEW TYPES
// ============================================================

export interface GroupsSummaryRow extends GroupRow {
  member_count: number;
  organizer_count: number;
  upcoming_event_count: number;
  completed_event_count: number;
}

export interface UpcomingEventsSummaryRow extends EventRow {
  group_name: string | null;
  group_slug: string | null;
  confirmed_attendees: number;
  maybe_attendees: number;
  waitlisted_count: number;
  is_full: boolean;
}

export interface UserGroupMembershipRow {
  user_id: string;
  role: GroupRole;
  status: MembershipStatus;
  joined_at: string | null;
  group_id: string;
  group_name: string;
  group_slug: string;
  avatar_image_url: string | null;
  visibility: GroupVisibility;
  primary_game_types: string[] | null;
}

// ============================================================
// INSERT / UPDATE TYPES
// ============================================================

export type CreateGroupInput = Pick<
  GroupRow,
  | 'name'
  | 'slug'
  | 'visibility'
> & Partial<Omit<GroupRow,
  | 'id'
  | 'created_at'
  | 'updated_at'
  | 'created_by'
>>;

export type UpdateGroupInput = Partial<Omit<GroupRow,
  | 'id'
  | 'created_at'
  | 'updated_at'
  | 'created_by'
>>;

export type CreateEventInput = Pick<
  EventRow,
  | 'title'
  | 'slug'
  | 'starts_at'
  | 'timezone'
  | 'location_type'
> & Partial<Omit<EventRow,
  | 'id'
  | 'created_at'
  | 'updated_at'
  | 'created_by'
  | 'current_attendees'
  | 'published_at'
  | 'cancelled_at'
>>;

export type UpdateEventInput = Partial<Omit<EventRow,
  | 'id'
  | 'created_at'
  | 'updated_at'
  | 'created_by'
  | 'current_attendees'
>>;

export type CreateRsvpInput = Pick<EventRsvpRow, 'event_id' | 'user_id'> & {
  status?: RsvpStatus;
  guests_count?: number;
  note?: string;
};

export type UpdateRsvpInput = Partial<Pick<
  EventRsvpRow,
  | 'status'
  | 'guests_count'
  | 'note'
  | 'approved_by'
  | 'approved_at'
  | 'rejection_reason'
  | 'checked_in_at'
  | 'checked_in_by'
>>;

export type CreateGroupMembershipInput = Pick<
  GroupMembershipRow,
  'group_id' | 'user_id'
> & Partial<Pick<GroupMembershipRow, 'role' | 'status' | 'invited_by' | 'notes'>>;

export type UpdateGroupMembershipInput = Partial<Pick<
  GroupMembershipRow,
  | 'role'
  | 'status'
  | 'ban_reason'
  | 'notes'
>>;

export type CreateGroupThreadInput = Pick<
  GroupThreadRow,
  'group_id' | 'title' | 'body'
> & Partial<Pick<GroupThreadRow, 'event_id' | 'is_pinned'>>;

export type CreateThreadReplyInput = Pick<
  GroupThreadReplyRow,
  'thread_id' | 'body'
> & Partial<Pick<GroupThreadReplyRow, 'parent_reply_id'>>;

export type CreateEventTemplateInput = Pick<
  EventTemplateRow,
  'group_id' | 'name' | 'default_title' | 'recurrence_rule'
> & Partial<Omit<EventTemplateRow,
  | 'id'
  | 'created_at'
  | 'updated_at'
  | 'created_by'
>>;

// ============================================================
// SUPABASE DATABASE TYPE MAP
// Used with the Supabase client: createClient<Database>()
// ============================================================

export interface Database {
  public: {
    Tables: {
      groups: {
        Row: GroupRow;
        Insert: CreateGroupInput & { created_by: string };
        Update: UpdateGroupInput;
      };
      group_memberships: {
        Row: GroupMembershipRow;
        Insert: CreateGroupMembershipInput;
        Update: UpdateGroupMembershipInput;
      };
      events: {
        Row: EventRow;
        Insert: CreateEventInput & { created_by: string };
        Update: UpdateEventInput;
      };
      event_rsvps: {
        Row: EventRsvpRow;
        Insert: CreateRsvpInput;
        Update: UpdateRsvpInput;
      };
      group_threads: {
        Row: GroupThreadRow;
        Insert: CreateGroupThreadInput & { created_by: string };
        Update: Partial<Pick<GroupThreadRow, 'title' | 'body' | 'is_pinned' | 'is_locked'>>;
      };
      group_thread_replies: {
        Row: GroupThreadReplyRow;
        Insert: CreateThreadReplyInput & { created_by: string };
        Update: Partial<Pick<GroupThreadReplyRow, 'body' | 'is_deleted'>>;
      };
      event_templates: {
        Row: EventTemplateRow;
        Insert: CreateEventTemplateInput & { created_by: string };
        Update: Partial<Omit<EventTemplateRow, 'id' | 'created_at' | 'updated_at' | 'created_by' | 'group_id'>>;
      };
    };
    Views: {
      groups_summary: {
        Row: GroupsSummaryRow;
      };
      upcoming_events_summary: {
        Row: UpcomingEventsSummaryRow;
      };
      user_group_memberships: {
        Row: UserGroupMembershipRow;
      };
    };
    Enums: {
      group_role: GroupRole;
      group_visibility: GroupVisibility;
      membership_status: MembershipStatus;
      event_status: EventStatus;
      rsvp_status: RsvpStatus;
      experience_level: ExperienceLevel;
      location_type: LocationType;
    };
  };
}
