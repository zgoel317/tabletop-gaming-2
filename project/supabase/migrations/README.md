# Database Migrations

This directory contains ordered SQL migrations for the Tabletop Gaming
Networking App Supabase database.

## Migration Order

| File | Description |
|------|-------------|
| `00001_initial_schema.sql` | Core user profiles, gaming preferences, game catalog, ratings, friendships |
| `00002_groups_and_events.sql` | Gaming groups, events/sessions, RSVP system, LFG posts |
| `00003_messaging.sql` | Conversations, direct messages, group chat, notifications |
| `00004_utility_functions.sql` | Helper functions, views, stored procedures |
| `00005_seed_data.sql` | Development seed data (top board games catalog) |

## Running Migrations

### Via Supabase CLI (recommended)

