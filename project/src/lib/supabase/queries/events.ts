/**
 * Supabase query helpers for event and RSVP operations.
 */
import { createClient } from '@/lib/supabase/server';
import type {
  CreateEventInput,
  UpdateEventInput,
  CreateRsvpInput,
  UpdateRsvpInput,
  EventRow,
  EventRsvpRow,
  UpcomingEventsSummaryRow,
  EventStatus,
  RsvpStatus,
  ExperienceLevel,
} from '@/lib/supabase/types';

// ============================================================
// EVENT QUERIES
// ============================================================

/**
 * Fetch a single event by its slug.
 */
export async function getEventBySlug(slug: string): Promise<EventRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('events')
    .select('*')
    .eq('slug', slug)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch event: ${error.message}`);
  }

  return data;
}

/**
 * Fetch upcoming public events with summary (attendee counts, group info).
 */
export async function getUpcomingPublicEvents(options: {
  search?: string;
  gameTitle?: string;
  experienceLevel?: ExperienceLevel;
  city?: string;
  country?: string;
  groupId?: string;
  fromDate?: Date;
  toDate?: Date;
  limit?: number;
  offset?: number;
}): Promise<{ data: UpcomingEventsSummaryRow[]; count: number }> {
  const {
    search,
    gameTitle,
    experienceLevel,
    city,
    country,
    groupId,
    fromDate,
    toDate,
    limit = 20,
    offset = 0,
  } = options;

  const supabase = await createClient();

  let query = supabase
    .from('upcoming_events_summary')
    .select('*', { count: 'exact' })
    .order('starts_at', { ascending: true })
    .range(offset, offset + limit - 1);

  if (search) {
    query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%,game_title.ilike.%${search}%`);
  }

  if (gameTitle) {
    query = query.ilike('game_title', `%${gameTitle}%`);
  }

  if (experienceLevel) {
    query = query.eq('experience_level', experienceLevel);
  }

  if (city) {
    query = query.ilike('city', `%${city}%`);
  }

  if (country) {
    query = query.eq('country', country);
  }

  if (groupId) {
    query = query.eq('group_id', groupId);
  }

  if (fromDate) {
    query = query.gte('starts_at', fromDate.toISOString());
  }

  if (toDate) {
    query = query.lte('starts_at', toDate.toISOString());
  }

  const { data, error, count } = await query;
  if (error) throw new Error(`Failed to fetch events: ${error.message}`);

  return { data: data ?? [], count: count ?? 0 };
}

/**
 * Get all events for a specific group.
 */
export async function getGroupEvents(
  groupId: string,
  options: {
    status?: EventStatus;
    upcoming?: boolean;
    limit?: number;
    offset?: number;
  } = {}
): Promise<EventRow[]> {
  const { status, upcoming, limit = 20, offset = 0 } = options;
  const supabase = await createClient();

  let query = supabase
    .from('events')
    .select('*')
    .eq('group_id', groupId)
    .order('starts_at', { ascending: true })
    .range(offset, offset + limit - 1);

  if (status) {
    query = query.eq('status', status);
  }

  if (upcoming) {
    query = query.gte('starts_at', new Date().toISOString());
  }

  const { data, error } = await query;
  if (error) throw new Error(`Failed to fetch group events: ${error.message}`);

  return data ?? [];
}

/**
 * Get events created by a specific user.
 */
export async function getUserCreatedEvents(
  userId: string,
  options: { status?: EventStatus; limit?: number } = {}
): Promise<EventRow[]> {
  const { status, limit = 20 } = options;
  const supabase = await createClient();

  let query = supabase
    .from('events')
    .select('*')
    .eq('created_by', userId)
    .order('starts_at', { ascending: false })
    .limit(limit);

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;
  if (error) throw new Error(`Failed to fetch user events: ${error.message}`);

  return data ?? [];
}

/**
 * Create a new event.
 */
export async function createEvent(
  input: CreateEventInput,
  userId: string
): Promise<EventRow> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('events')
    .insert({ ...input, created_by: userId })
    .select()
    .single();

  if (error) throw new Error(`Failed to create event: ${error.message}`);
  return data;
}

/**
 * Update an event. RLS ensures only creator or group organizer can do this.
 */
export async function updateEvent(
  eventId: string,
  input: UpdateEventInput
): Promise<EventRow> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('events')
    .update(input)
    .eq('id', eventId)
    .select()
    .single();

  if (error) throw new Error(`Failed to update event: ${error.message}`);
  return data;
}

/**
 * Publish a draft event.
 */
export async function publishEvent(eventId: string): Promise<EventRow> {
  return updateEvent(eventId, { status: 'published' });
}

/**
 * Cancel an event with a reason.
 */
export async function cancelEvent(
  eventId: string,
  reason: string
): Promise<EventRow> {
  return updateEvent(eventId, {
    status: 'cancelled',
    cancellation_reason: reason,
  });
}

/**
 * Mark an event as completed.
 */
export async function completeEvent(eventId: string): Promise<EventRow> {
  return updateEvent(eventId, { status: 'completed' });
}

// ============================================================
// RSVP QUERIES
// ============================================================

/**
 * Get all RSVPs for an event.
 */
export async function getEventRsvps(
  eventId: string,
  options: { status?: RsvpStatus } = {}
): Promise<EventRsvpRow[]> {
  const { status } = options;
  const supabase = await createClient();

  let query = supabase
    .from('event_rsvps')
    .select('*')
    .eq('event_id', eventId)
    .order('created_at', { ascending: true });

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;
  if (error) throw new Error(`Failed to fetch RSVPs: ${error.message}`);

  return data ?? [];
}

/**
 * Get the waitlist for an event, ordered by position.
 */
export async function getEventWaitlist(eventId: string): Promise<EventRsvpRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('event_rsvps')
    .select('*')
    .eq('event_id', eventId)
    .eq('status', 'waitlisted')
    .order('waitlist_position', { ascending: true });

  if (error) throw new Error(`Failed to fetch waitlist: ${error.message}`);
  return data ?? [];
}

/**
 * Get a user's RSVP for a specific event.
 */
export async function getUserRsvp(
  eventId: string,
  userId: string
): Promise<EventRsvpRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('event_rsvps')
    .select('*')
    .eq('event_id', eventId)
    .eq('user_id', userId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch RSVP: ${error.message}`);
  }

  return data;
}

/**
 * Get all events a user has RSVPed to.
 */
export async function getUserRsvps(
  userId: string,
  options: { status?: RsvpStatus; upcoming?: boolean; limit?: number } = {}
): Promise<EventRsvpRow[]> {
  const { status, upcoming, limit = 20 } = options;
  const supabase = await createClient();

  let query = supabase
    .from('event_rsvps')
    .select('*, events(*)')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;
  if (error) throw new Error(`Failed to fetch user RSVPs: ${error.message}`);

  // Filter upcoming in application layer if needed (or use a view)
  let results = data ?? [];
  if (upcoming) {
    const now = new Date().toISOString();
    results = results.filter((r: any) => r.events?.starts_at > now);
  }

  return results;
}

/**
 * Create or update a user's RSVP for an event.
 * Handles the full flow: attending → waitlisted if event is full.
 */
export async function upsertRsvp(
  input: CreateRsvpInput
): Promise<EventRsvpRow> {
  const supabase = await createClient();

  // Check if event is full before setting attending status
  if (input.status === 'attending' || input.status === undefined) {
    const { data: event } = await supabase
      .from('events')
      .select('max_players, current_attendees, waitlist_enabled, status')
      .eq('id', input.event_id)
      .single();

    if (event) {
      if (event.status !== 'published') {
        throw new Error('Cannot RSVP to an event that is not published');
      }

      const isFull =
        event.max_players !== null &&
        event.current_attendees >= event.max_players;

      if (isFull) {
        if (!event.waitlist_enabled) {
          throw new Error('This event is full and does not have a waitlist');
        }
        input = { ...input, status: 'waitlisted' };
      }
    }
  }

  const { data, error } = await supabase
    .from('event_rsvps')
    .upsert(
      {
        event_id: input.event_id,
        user_id: input.user_id,
        status: input.status ?? 'attending',
        guests_count: input.guests_count ?? 0,
        note: input.note ?? null,
      },
      { onConflict: 'event_id,user_id' }
    )
    .select()
    .single();

  if (error) throw new Error(`Failed to upsert RSVP: ${error.message}`);
  return data;
}

/**
 * Update an existing RSVP.
 */
export async function updateRsvp(
  rsvpId: string,
  input: UpdateRsvpInput
): Promise<EventRsvpRow> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('event_rsvps')
    .update(input)
    .eq('id', rsvpId)
    .select()
    .single();

  if (error) throw new Error(`Failed to update RSVP: ${error.message}`);
  return data;
}

/**
 * Cancel an RSVP (set status to declined).
 */
export async function cancelRsvp(eventId: string, userId: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase
    .from('event_rsvps')
    .update({ status: 'declined' } satisfies UpdateRsvpInput)
    .eq('event_id', eventId)
    .eq('user_id', userId);

  if (error) throw new Error(`Failed to cancel RSVP: ${error.message}`);
}

/**
 * Check in an attendee at an event.
 */
export async function checkInAttendee(
  rsvpId: string,
  checkedInBy: string
): Promise<EventRsvpRow> {
  return updateRsvp(rsvpId, {
    checked_in_at: new Date().toISOString(),
    checked_in_by: checkedInBy,
  });
}

/**
 * Promote the first waitlisted person to attending
 * (called automatically by DB trigger, but can also be called manually).
 */
export async function promoteFromWaitlist(eventId: string): Promise<EventRsvpRow | null> {
  const supabase = await createClient();

  // Get the first person on the waitlist
  const { data: firstWaiting, error: fetchError } = await supabase
    .from('event_rsvps')
    .select('*')
    .eq('event_id', eventId)
    .eq('status', 'waitlisted')
    .eq('waitlist_position', 1)
    .single();

  if (fetchError || !firstWaiting) return null;

  // Promote them
  const { data, error } = await supabase
    .from('event_rsvps')
    .update({ status: 'attending' } satisfies UpdateRsvpInput)
    .eq('id', firstWaiting.id)
    .select()
    .single();

  if (error) throw new Error(`Failed to promote from waitlist: ${error.message}`);
  return data;
}

/**
 * Approve a pending RSVP (when event requires_approval = true).
 */
export async function approveRsvp(
  rsvpId: string,
  approvedBy: string
): Promise<EventRsvpRow> {
  return updateRsvp(rsvpId, {
    status: 'attending',
    approved_by: approvedBy,
    approved_at: new Date().toISOString(),
  });
}

/**
 * Reject a pending RSVP.
 */
export async function rejectRsvp(
  rsvpId: string,
  reason: string
): Promise<EventRsvpRow> {
  return updateRsvp(rsvpId, {
    status: 'declined',
    rejection_reason: reason,
  });
}
