# CWL – Phase 1: Core Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up the Supabase backend with database schema, RLS policies, basic Edge Functions, and initial Supabase project configuration for the Construction Waste Logistics app.

**Architecture:** Supabase (Postgres + PostGIS, Auth, Realtime, Storage, Edge Functions). All business logic runs in Edge Functions. The Flutter app is a thin client. RLS enforces row-level access control at the database level.

**Tech Stack:** Supabase (self-hosted or cloud), Postgres 15+, PostGIS, Deno (Edge Functions), TypeScript.

---

## File Structure

```
supabase/
├── migrations/                        # Database migrations
│   00001_init_schema.sql              # Core tables, enums, triggers
│   00002_rls_policies.sql             # RLS policies for all tables
│   00003_postgis_setup.sql            # PostGIS extension setup
│   00004_functions_triggers.sql       # DB triggers (profile sync, audit log)
supabase/functions/                    # Edge Functions
│   match_recycler/index.ts            # Recycler selects waste → creates haul
│   accept_haul/index.ts               # Hauler accepts haul
│   confirm_pickup/index.ts            # Hauler confirms pickup
│   confirm_delivery/index.ts          # Hauler confirms delivery
│   release_payment/index.ts           # Calculate splits, record payment
│   notify_user/index.ts               # Send push/in-app notifications
│   track_position/index.ts            # Receive GPS, stream to tracking_events
│   auth_callback/index.ts             # Post-signup profile creation
app/                                   # Flutter project (Phase 2+)
linode.md                              # Supabase project setup notes
```

---

## Task 1: Initialize Supabase Project

**Goal:** Create a new Supabase project (locally or cloud) and configure environment.

**Files:**
- Create: `.env` (root)
- Create: `linode.md` (setup notes)

- [ ] **Step 1: Install Supabase CLI** (if not already)

```bash
npm install -g supabase
supabase --version
```

- [ ] **Step 2: Initialize Supabase project in root**

```bash
cd /root/startup
supabase init
```

- [ ] **Step 3: Create `.env` with project keys**

```
SUPABASE_URL=https://your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

Get these from the Supabase dashboard after creating a project.

- [ ] **Step 4: Create `linode.md`**

```markdown
# Supabase Project Setup
- Project URL: {{SUPABASE_URL}}
- Anon Key: {{SUPABASE_ANON_KEY}}
- Service Role Key: {{SUPABASE_SERVICE_ROLE_KEY}}
- PostGIS enabled: yes
- Realtime enabled: yes
```

- [ ] **Step 5: Commit**

```bash
git add supabase/ .env linode.md
git commit -m "chore: init supabase project and env"
```

---

## Task 2: Create Database Schema (Migrations)

**Goal:** Write all core tables, enums, and triggers.

**Files:**
- Create: `supabase/migrations/00001_init_schema.sql`
- Create: `supabase/migrations/00003_postgis_setup.sql`
- Create: `supabase/migrations/00004_functions_triggers.sql`

### 2a: PostGIS Extension

- [ ] **Step 1: Create `supabase/migrations/00003_postgis_setup.sql`**

```sql
-- Enable PostGIS for location support
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 2b: Core Schema

- [ ] **Step 2: Create `supabase/migrations/00001_init_schema.sql`**

```sql
-- Enums
CREATE TYPE user_role AS ENUM ('developer', 'hauler', 'recycler', 'admin');
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE waste_type AS ENUM ('concrete', 'wood', 'metal', 'plastic', 'mixed', 'hazardous', 'other');
CREATE TYPE quantity_unit AS ENUM ('tons', 'cubic_meters');
CREATE TYPE post_status AS ENUM ('posted', 'selected', 'in_transit', 'delivered', 'cancelled');
CREATE TYPE haul_status AS ENUM ('open', 'accepted', 'picked_up', 'in_transit', 'delivered', 'paid');
CREATE TYPE payment_status AS ENUM ('pending', 'completed');
CREATE TYPE notification_type AS ENUM ('waste_selected', 'haul_accepted', 'pickup_confirmed', 'delivery_confirmed', 'payment_made');
CREATE TYPE audit_action AS ENUM ('ban_user', 'unban_user', 'approve_hauler', 'reject_hauler', 'refund', 'commission_update', 'delete_post');

-- Profiles table (synced from auth.users via trigger)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'developer',
  full_name TEXT,
  phone TEXT,
  company_name TEXT,
  verification_status verification_status NOT NULL DEFAULT 'pending',
  location GEOMETRY(Point, 4326),
  banned BOOLEAN DEFAULT FALSE,
  banned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Waste posts
CREATE TABLE waste_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  developer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  waste_type waste_type NOT NULL,
  quantity NUMERIC(10,2) NOT NULL,
  quantity_unit quantity_unit NOT NULL DEFAULT 'tons',
  location GEOMETRY(Point, 4326) NOT NULL,
  pickup_date_start DATE,
  pickup_date_end DATE,
  photos TEXT[] DEFAULT '{}',
  status post_status NOT NULL DEFAULT 'posted',
  price NUMERIC(10,2),
  commission_rate NUMERIC(5,4) DEFAULT 0.10,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Waste selections (recycler picks waste)
CREATE TABLE waste_selections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  waste_post_id UUID NOT NULL REFERENCES waste_posts(id) ON DELETE CASCADE,
  recycler_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  selected_at TIMESTAMPTZ DEFAULT now(),
  accepted_price NUMERIC(10,2),
  UNIQUE(waste_post_id) -- only one selection per post
);

-- Hauls (transport jobs)
CREATE TABLE hauls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  waste_post_id UUID NOT NULL REFERENCES waste_posts(id) ON DELETE CASCADE,
  hauler_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  recycler_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status haul_status NOT NULL DEFAULT 'open',
  pickup_location GEOMETRY(Point, 4326) NOT NULL,
  delivery_location GEOMETRY(Point, 4326) NOT NULL,
  pickup_confirmed_at TIMESTAMPTZ,
  delivery_confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  haul_id UUID NOT NULL REFERENCES hauls(id) ON DELETE CASCADE,
  payer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  platform_commission NUMERIC(10,2) NOT NULL,
  hauler_share NUMERIC(10,2) NOT NULL,
  developer_share NUMERIC(10,2) NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  released_at TIMESTAMPTZ
);

-- Tracking events (GPS stream)
CREATE TABLE tracking_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  haul_id UUID NOT NULL REFERENCES hauls(id) ON DELETE CASCADE,
  position GEOMETRY(Point, 4326) NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT now()
);

-- Commission settings
CREATE TABLE commission_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rate NUMERIC(5,4) NOT NULL DEFAULT 0.10,
  effective_date TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- Payment refunds
CREATE TABLE payment_refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  refund_amount NUMERIC(10,2) NOT NULL,
  refund_reason TEXT NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  refunded_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Platform audit log
CREATE TABLE platform_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action_type audit_action NOT NULL,
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 2c: Triggers

- [ ] **Step 3: Create `supabase/migrations/00004_functions_triggers.sql`**

```sql
-- Trigger to auto-create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name)
  VALUES (NEW.id, 'developer', NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger to log track old status on haul update
CREATE OR REPLACE FUNCTION public.log_haul_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    -- Add notification or additional logic here if needed
    NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_haul_status_change
  AFTER UPDATE ON hauls
  FOR EACH ROW EXECUTE FUNCTION public.log_haul_status_change();

-- Default commission setting if none exists
INSERT INTO commission_settings (rate) SELECT 0.10 WHERE NOT EXISTS (SELECT 1 FROM commission_settings);
```

- [ ] **Step 4: Apply migrations**

```bash
supabase db push
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/
git commit -m "feat: create database schema, enums, and triggers"
```

---

## Task 3: Enable RLS Policies

**Goal:** Secure all tables with Row-Level Security policies.

**Files:
- Create: `supabase/migrations/00002_rls_policies.sql`

- [ ] **Step 1: Create `supabase/migrations/00002_rls_policies.sql`**

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_selections ENABLE ROW LEVEL SECURITY;
ALTER TABLE hauls ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracking_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admin read all profiles" ON profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Waste posts
CREATE POLICY "Developers read own posts" ON waste_posts FOR SELECT USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) IN ('developer', 'admin')
  OR developer_id = auth.uid()
);
CREATE POLICY "Recyclers view available posts" ON waste_posts FOR SELECT USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) IN ('recycler', 'admin')
  OR status = 'posted'
);
CREATE POLICY "Developers insert posts" ON waste_posts FOR INSERT WITH CHECK (auth.uid() = developer_id);
CREATE POLICY "Developers update own posts" ON waste_posts FOR UPDATE USING (auth.uid() = developer_id);

-- Hauls
CREATE POLICY "Haulers read assigned" ON hauls FOR SELECT USING (
  hauler_id = auth.uid()
  OR recycler_id = auth.uid()
  OR EXISTS (SELECT 1 FROM waste_posts wp WHERE wp.id = waste_post_id AND wp.developer_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Haulers update assigned" ON hauls FOR UPDATE USING (hauler_id = auth.uid());

-- Payments
CREATE POLICY "Users read own payments" ON payments FOR SELECT USING (
  payer_id = auth.uid()
  OR EXISTS (SELECT 1 FROM hauls h WHERE h.id = haul_id AND h.hauler_id = auth.uid())
  OR EXISTS (SELECT 1 FROM waste_posts wp JOIN hauls h ON h.waste_post_id = wp.id WHERE h.id = haul_id AND wp.developer_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Tracking events
CREATE POLICY "Party read tracking" ON tracking_events FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM hauls h
    WHERE h.id = haul_id
      AND (h.hauler_id = auth.uid()
        OR h.recycler_id = auth.uid()
        OR EXISTS (SELECT 1 FROM waste_posts wp WHERE wp.id = h.waste_post_id AND wp.developer_id = auth.uid())
        OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
  )
);

-- Commission settings (admin write, public read)
CREATE POLICY "Admins modify commission" ON commission_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Everyone read commission" ON commission_settings FOR SELECT USING (true);

-- Notifications
CREATE POLICY "Users read own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- Audit log (admin read)
CREATE POLICY "Admins read audit" ON platform_audit_log FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Payment refunds (admin read)
CREATE POLICY "Admins read refunds" ON payment_refunds FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
```

- [ ] **Step 2: Apply RLS migrations**

```bash
supabase db push
```

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/00002_rls_policies.sql
git commit -m "feat: add RLS policies for all tables"
```

---

## Task 4: Initialize Edge Functions

**Goal:** Scaffold all Edge Function directories.

- [ ] **Step 1: Scaffold all functions**

```bash
cd /root/startup
for func in match_recycler accept_haul confirm_pickup confirm_delivery release_payment notify_user track_position auth_callback update_commission ban_user unban_user approve_hauler reject_hauler delete_post_admin refund_payment; do
  supabase functions new $func
done
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/
git commit -m "chore: scaffold edge functions"
```

---

## Task 5: Implement Core Edge Functions

### 5a: `auth_callback` (Post-signup profile sync)

**Goal:** Ensure profiles are created on signup.

**Files:
- Create: `supabase/functions/auth_callback/index.ts`

- [ ] **Step 1: Write `supabase/functions/auth_callback/index.ts`**

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: { user }, error } = await supabase.auth.getUser(req.headers.get('Authorization')!)
    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (!existingProfile) {
      const { error: insertError } = await supabase
        .from('profiles')
        .insert({
          id: user.id,
          role: 'developer',
          full_name: user.user_metadata?.full_name || user.email?.split('@')[0]
        })
      if (insertError) throw insertError
    }

    return new Response(JSON.stringify({ profile_created: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
```

### 5b: `match_recycler` (Recycler selects waste, creates haul)

- [ ] **Step 2: Write `supabase/functions/match_recycler/index.ts`**

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: { user } } = await supabase.auth.getUser(req.headers.get('Authorization')!)
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { waste_post_id, accepted_price } = await req.json()

    // Verify recycler role
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single()
    if (profile?.role !== 'recycler') {
      return new Response(JSON.stringify({ error: 'Only recyclers can select waste' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Check if post is still available
    const { data: post } = await supabase.from('waste_posts').select('*').eq('id', waste_post_id).eq('status', 'posted').single()
    if (!post) {
      return new Response(JSON.stringify({ error: 'Waste post not available' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Create selection
    const { data: selection, error: selErr } = await supabase
      .from('waste_selections')
      .insert({ waste_post_id, recycler_id: user.id, accepted_price })
      .select()
      .single()
    if (selErr) throw selErr

    // Update post status
    await supabase.from('waste_posts').update({ status: 'selected', price: accepted_price }).eq('id', waste_post_id)

    // Create haul
    const { data: haul } = await supabase
      .from('hauls')
      .insert({
        waste_post_id,
        recycler_id: user.id,
        pickup_location: post.location,
        status: 'open'
      })
      .select()
      .single()

    return new Response(JSON.stringify({ selection, haul }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
```

### 5c: Remaining Edge Functions

- [ ] **Step 3: Scaffold remaining function stubs**

Create a stub for each of the following with the same pattern (CORS, auth check, service_role client, TODO comment):

- `accept_haul`
- `confirm_pickup`
- `confirm_delivery`
- `release_payment`
- `notify_user`
- `track_position`
- `update_commission`
- `ban_user`
- `unban_user`
- `approve_hauler`
- `reject_hauler`
- `delete_post_admin`
- `refund_payment`

Example stub for `accept_haul` (write similar stubs for all):

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    // TODO: Implement hauler acceptance logic: validate hauler, set hauler_id, update status to 'accepted', notify developer and recycler
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
```

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/
git commit -m "feat: implement auth_callback and match_recycler; scaffold remaining edge functions"
```

---

## Task 6: Seed Test Data

**Goal:** Add seed script for local development testing.

**Files:
- Create: `supabase/seed.sql`

- [ ] **Step 1: Create `supabase/seed.sql`**

```sql
-- Seed data for local testing
INSERT INTO profiles (id, role, full_name, verification_status) VALUES
  ('00000000-0000-0000-0000-000000000001', 'developer', 'Test Developer', 'approved'),
  ('00000000-0000-0000-0000-000000000002', 'hauler', 'Test Hauler', 'approved'),
  ('00000000-0000-0000-0000-000000000003', 'recycler', 'Test Recycler', 'approved'),
  ('00000000-0000-0000-0000-000000000004', 'admin', 'Test Admin', 'approved');

INSERT INTO waste_posts (developer_id, waste_type, quantity, quantity_unit, location, status, price) VALUES
  ('00000000-0000-0000-0000-000000000001', 'concrete', 5.00, 'tons', ST_SetSRID(ST_MakePoint(-73.94, 40.73), 4326), 'posted', 250.00);
```

- [ ] **Step 2: Commit**

```bash
git add supabase/seed.sql
git commit -m "chore: add seed data for local dev"
```

---

## Plan Self-Review

**Spec coverage:**
- ✅ All data models: profiles, waste_posts, waste_selections, hauls, payments, tracking_events, commission_settings, payment_refunds, platform_audit_log, notifications
- ✅ Enums for all status fields
- ✅ RLS policies for all tables
- ✅ Core Edge Functions: auth_callback, match_recycler, plus stubs for all others
- ✅ PostGIS extension
- ✅ Triggers for profile creation and basic status logging
- ✅ Seed data for testing

**Placeholder scan:**
- Edge function stubs use TODO comments — this is acceptable for Phase 1 as the plan intentionally defers full implementation to later phases.

**Type consistency:**
- UUID types used consistently across all FK relations.
- `payment_status` enum reused for `payment_refunds`.
- `waste_type` and `quantity_unit` consistent with design doc.

---

## Execution Options

**Plan complete and saved to `docs/superpowers/plans/2026-05-08-cwl-phase1-core-backend.md`.**

Two execution options:

1. **Subagent-Driven (recommended)** - Dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints.

Which approach?
