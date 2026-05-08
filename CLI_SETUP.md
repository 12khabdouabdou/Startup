# Supabase CLI Setup Guide

## Prerequisites

Install the Supabase CLI globally on your local machine:
```bash
# Using npm:
npm install -g supabase

# Using Homebrew (macOS):
brew install supabase-cli
```

Verify installation:
```bash
supabase --version
```

## 1. Authenticate the CLI

```bash
supabase login
```

This will open a browser window for you to log into your Supabase account. After
logging in, the CLI stores a personal access token in `~/.supabase/config.toml`.

## 2. Link to your live project

```bash
cd /root/startup
supabase link --project-ref jrfwxnwoeetqjbvicokb
```

This connects your local directory to the live project. After linking, your
local `supabase/` directory knows where to deploy.

## 3. Deploy Edge Functions

```bash
supabase functions deploy
```

Or deploy a specific function:
```bash
supabase functions deploy match_recycler
supabase functions deploy accept_haul
```

## 4. Push Database Migrations

```bash
supabase db push
```

This applies all migrations from `supabase/migrations/` to your live database.

## 5. Apply Seed Data (optional, for dev)

```bash
supabase db seed
```

Or manually insert seed data via the SQL Editor in the Supabase Dashboard.

## 6. Verify the deployment

Open the Supabase dashboard and check:
- **Database** → Tables: `profiles`, `waste_posts`, `hauls`, `payments`, etc.
- **Edge Functions** → All 14 functions should be listed
- **Authentication** → Should be enabled (email/password by default)

## Troubleshooting

- **"Not linked to a project"**: Run `supabase link --project-ref jrfwxnwoeetqjbvicokb`
- **"Unauthorized"**: Re-run `supabase login` to refresh the access token
- **Migrations fail**: Check the SQL error in the dashboard Logs → Postgres
- **Edge Functions fail to deploy**: Ensure `supabase functions deploy` is run from the project root

## Project Details

| Item | Value |
|------|-------|
| Project URL | https://jrfwxnwoeetqjbvicokb.supabase.co |
| Project Ref | `jrfwxnwoeetqjbvicokb` |
| Region | (TBD - check Dashboard) |
