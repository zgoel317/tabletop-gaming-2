/**
 * Supabase query helpers for group-related operations.
 */
import { createClient } from '@/lib/supabase/server';
import type {
  CreateGroupInput,
  UpdateGroupInput,
  CreateGroupMembershipInput,
  UpdateGroupMembershipInput,
  GroupRow,
  GroupMembershipRow,
  GroupsSummaryRow,
  UserGroupMembershipRow,
  GroupRole,
  MembershipStatus,
} from '@/lib/supabase/types';

// ============================================================
// GROUP QUERIES
// ============================================================

/**
 * Fetch a single group by its slug.
 * Respects RLS — private groups only visible to members.
 */
export async function getGroupBySlug(slug: string): Promise<GroupRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('groups')
    .select('*')
    .eq('slug', slug)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null; // Not found
    throw new Error(`Failed to fetch group: ${error.message}`);
  }

  return data;
}

/**
 * Fetch a group with member and event counts via the summary view.
 */
export async function getGroupSummaryBySlug(slug: string): Promise<GroupsSummaryRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('groups_summary')
    .select('*')
    .eq('slug', slug)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch group summary: ${error.message}`);
  }

  return data;
}

/**
 * Search public groups with optional filters.
 */
export async function searchPublicGroups(options: {
  search?: string;
  gameTypes?: string[];
  city?: string;
  country?: string;
  limit?: number;
  offset?: number;
}): Promise<{ data: GroupsSummaryRow[]; count: number }> {
  const { search, gameTypes, city, country, limit = 20, offset = 0 } = options;
  const supabase = await createClient();

  let query = supabase
    .from('groups_summary')
    .select('*', { count: 'exact' })
    .eq('visibility', 'public')
    .eq('is_active', true)
    .order('member_count', { ascending: false })
    .range(offset, offset + limit - 1);

  if (search) {
    query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
  }

  if (gameTypes && gameTypes.length > 0) {
    query = query.overlaps('primary_game_types', gameTypes);
  }

  if (city) {
    query = query.ilike('city', `%${city}%`);
  }

  if (country) {
    query = query.eq('country', country);
  }

  const { data, error, count } = await query;

  if (error) throw new Error(`Failed to search groups: ${error.message}`);

  return { data: data ?? [], count: count ?? 0 };
}

/**
 * Create a new group. Automatically creates an organizer membership for the creator.
 */
export async function createGroup(
  input: CreateGroupInput,
  userId: string
): Promise<GroupRow> {
  const supabase = await createClient();

  // Create the group
  const { data: group, error: groupError } = await supabase
    .from('groups')
    .insert({ ...input, created_by: userId })
    .select()
    .single();

  if (groupError) throw new Error(`Failed to create group: ${groupError.message}`);

  // Auto-create organizer membership for creator
  const { error: memberError } = await supabase
    .from('group_memberships')
    .insert({
      group_id: group.id,
      user_id: userId,
      role: 'organizer' as GroupRole,
      status: 'active' as MembershipStatus,
    });

  if (memberError) {
    // Group was created but membership failed — attempt cleanup
    console.error('Failed to create organizer membership:', memberError.message);
  }

  return group;
}

/**
 * Update a group. RLS ensures only organizers can do this.
 */
export async function updateGroup(
  groupId: string,
  input: UpdateGroupInput
): Promise<GroupRow> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('groups')
    .update(input)
    .eq('id', groupId)
    .select()
    .single();

  if (error) throw new Error(`Failed to update group: ${error.message}`);
  return data;
}

/**
 * Soft-delete a group by marking it inactive.
 */
export async function deactivateGroup(groupId: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase
    .from('groups')
    .update({ is_active: false })
    .eq('id', groupId);

  if (error) throw new Error(`Failed to deactivate group: ${error.message}`);
}

// ============================================================
// MEMBERSHIP QUERIES
// ============================================================

/**
 * Get all active members of a group.
 */
export async function getGroupMembers(
  groupId: string,
  options: { role?: GroupRole; limit?: number; offset?: number } = {}
): Promise<GroupMembershipRow[]> {
  const { role, limit = 50, offset = 0 } = options;
  const supabase = await createClient();

  let query = supabase
    .from('group_memberships')
    .select('*')
    .eq('group_id', groupId)
    .eq('status', 'active')
    .order('joined_at', { ascending: true })
    .range(offset, offset + limit - 1);

  if (role) {
    query = query.eq('role', role);
  }

  const { data, error } = await query;
  if (error) throw new Error(`Failed to fetch group members: ${error.message}`);

  return data ?? [];
}

/**
 * Get the current user's membership in a group.
 */
export async function getUserMembership(
  groupId: string,
  userId: string
): Promise<GroupMembershipRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('group_memberships')
    .select('*')
    .eq('group_id', groupId)
    .eq('user_id', userId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(`Failed to fetch membership: ${error.message}`);
  }

  return data;
}

/**
 * Get all groups a user belongs to.
 */
export async function getUserGroups(
  userId: string,
  status: MembershipStatus = 'active'
): Promise<UserGroupMembershipRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('user_group_memberships')
    .select('*')
    .eq('user_id', userId)
    .eq('status', status)
    .order('joined_at', { ascending: false });

  if (error) throw new Error(`Failed to fetch user groups: ${error.message}`);
  return data ?? [];
}

/**
 * Join a group (creates a pending or active membership based on group settings).
 */
export async function joinGroup(
  groupId: string,
  userId: string,
  requiresApproval = false
): Promise<GroupMembershipRow> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('group_memberships')
    .insert({
      group_id: groupId,
      user_id: userId,
      role: 'member',
      status: requiresApproval ? 'pending' : 'active',
    } satisfies CreateGroupMembershipInput)
    .select()
    .single();

  if (error) throw new Error(`Failed to join group: ${error.message}`);
  return data;
}

/**
 * Leave a group by setting status to 'left'.
 */
export async function leaveGroup(groupId: string, userId: string): Promise<void> {
  const supabase = await createClient();
  const { error } = await supabase
    .from('group_memberships')
    .update({ status: 'left' } satisfies UpdateGroupMembershipInput)
    .eq('group_id', groupId)
    .eq('user_id', userId);

  if (error) throw new Error(`Failed to leave group: ${error.message}`);
}

/**
 * Update a member's role or status (organizer action).
 */
export async function updateMembership(
  membershipId: string,
  input: UpdateGroupMembershipInput
): Promise<GroupMembershipRow> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('group_memberships')
    .update(input)
    .eq('id', membershipId)
    .select()
    .single();

  if (error) throw new Error(`Failed to update membership: ${error.message}`);
  return data;
}

/**
 * Approve a pending membership.
 */
export async function approveMembership(membershipId: string): Promise<GroupMembershipRow> {
  return updateMembership(membershipId, { status: 'active' });
}

/**
 * Ban a member from a group.
 */
export async function banMember(
  membershipId: string,
  reason: string
): Promise<GroupMembershipRow> {
  return updateMembership(membershipId, { status: 'banned', ban_reason: reason });
}
