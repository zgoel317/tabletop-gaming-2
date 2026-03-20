# Database Migrations

This directory contains the Supabase database migrations for the Tabletop Gaming Networking App.

## Migration Files

### `20240101000000_initial_schema.sql`
Creates the core database schema including:

- **Extensions**: `uuid-ossp`, `postgis` (spatial queries), `pg_trgm` (fuzzy text search)
- **Enums**: `experience_level`, `game_genre`, `collection_status`, `availability_day`, `availability_time`
- **Tables**:
  - `profiles` — Extends `auth.users` with gaming profile data, location (PostGIS), and preferences
  - `gaming_preferences` — Genre preferences with 1–5 weighting for matching
  - `games` — Board game catalog with BGG integration fields
  - `user_game_collection` — Personal game collections (own/wishlist/etc.)
  - `favorite_games` — Explicitly favorited games for profile display
  - `user_availability` — Weekly availability schedule
  - `user_ratings` — Peer ratings between users
- **View**: `profile_stats` — Aggregated profile statistics
- **Indexes**: Spatial (GiST), trigram (GIN), and standard B-tree indexes
- **Triggers**: `updated_at` auto-update, PostGIS location point sync

### `20240101000001_row_level_security.sql`
Configures Row Level Security (RLS) policies:

- All tables have RLS enabled
- Public profiles/data are readable by anyone
- Users can only modify their own data
- Games table is publicly readable; authenticated users can suggest games
- Ratings enforce no self-rating constraint

### `20240101000002_auth_triggers.sql`
Authentication-related triggers and functions:

- `handle_new_user()` — Auto-creates a profile when a user signs up
- `handle_user_deletion()` — Cleanup hook on user deletion
- `get_nearby_players()` — PostGIS-powered proximity search
- `search_players()` — Fuzzy + ILIKE text search for players
- `get_profile_with_details()` — Returns a full profile JSON with all related data

### `20240101000003_seed_data.sql`
Development seed data:
- 15 popular board games pre-loaded from BoardGameGeek

## Running Migrations

### Using Supabase CLI

