# Database Migrations

This directory contains PostgreSQL migration files for the Tabletop Gaming Networking App.

## Migration Files

### `001_groups_and_events.sql`
Core schema for social and event features:

#### Tables
| Table | Description |
|-------|-------------|
| `groups` | Gaming groups with location, visibility, and game preferences |
| `group_memberships` | User-group relationships with roles (organizer, co_organizer, member) and statuses |
| `events` | Game sessions with scheduling, location, capacity, and game details |
| `event_rsvps` | Player RSVPs with waitlist support and check-in tracking |
| `group_threads` | Discussion forum threads within groups |
| `group_thread_replies` | Replies to discussion threads (supports nesting) |
| `event_templates` | Recurring session templates with RRULE-based scheduling |

#### Views
| View | Description |
|------|-------------|
| `groups_summary` | Groups with aggregated member and event counts |
| `upcoming_events_summary` | Published future events with RSVP breakdowns and full status |
| `user_group_memberships` | A user's group memberships with basic group details |

#### Key Features

**Automatic behaviors (via triggers):**
- `updated_at` timestamps are maintained automatically on all tables
- Latitude/longitude pairs are synced to PostGIS `geometry(POINT, 4326)` columns for geo queries
- `events.current_attendees` is kept in sync with attending RSVPs
- Waitlist positions are auto-assigned and compacted when someone leaves
- Thread `reply_count` and `last_reply_at` are maintained automatically
- Membership `joined_at` / `left_at` dates are set on status transitions
- Event `published_at` / `cancelled_at` are set on status transitions

**Row Level Security (RLS):**
- All tables have RLS enabled
- Public groups/events are readable without authentication
- Private groups are only visible to members
- Only organizers/co-organizers can manage groups and memberships
- Users can only modify their own RSVPs
- Organizers can check in attendees and approve RSVPs

#### Enums
