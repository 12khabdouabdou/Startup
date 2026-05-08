# Construction Waste Logistics App – Design Document

> Created: 2026-05-08

---

## 1. Overview & Architecture

**App:** Construction Waste Logistics (CWL) – Flutter (Android), single APK with role-based access.  
**Backend:** Supabase (Postgres, Auth, Realtime, Storage, Edge Functions).  
**Maps:** OpenStreetMap via `flutter_map`.

### Three user roles

| Role | What they do |
|------|-------------|
| **Site Developer** | Posts waste jobs (type, quantity, location, pickup windows). |
| **Hauler** | Browses available jobs, accepts assignments, transports to recycler. |
| **Recycling Company** | Browses posted waste, selects which waste they want, pays for it. |

### Flow

1. Site Developer posts a waste job.  
2. Recycling companies browse and select waste they want (by type and location).  
3. Once a recycler selects the waste, the job becomes a "haul" and appears in the hauler feed.  
4. A hauler accepts the haul, picks up the waste, and delivers it.  
5. Recycling company pays the platform owner, who then distributes funds to hauler and site developer (keeping a commission).

### Architecture

```
┌─────────────────┐
│  Flutter App    │
│ (role-based UI) │
└────────┬────────┘
         │
┌────────▼────────┐
│   Supabase      │  ──  Auth, Database, Realtime, Storage
│  - Postgres     │
│  - Auth         │      ┌─────────────────────────┐
│  - Realtime     │◄────┤  Supabase Edge Functions │
│  - Storage      │      │  (Payments, matching,  │
└─────────────────┘      │   commission, notifs)   │
                         └─────────────────────────┘
```

**Key principle:** All business logic (payment splitting, job matching, commission) runs in Supabase Edge Functions. RLS policies restrict what each role can see/modify. The Flutter app is a thin presentation layer.

---

## 2. Data Models (Supabase/Postgres)

### `profiles`
Synced from `auth.users` via trigger.
- `id` (PK, refs `auth.users`)
- `role`: enum (`developer`, `hauler`, `recycler`, `admin`)
- `full_name`, `phone`, `company_name`
- `verification_status`: enum (`pending`, `approved`, `rejected`)
- `location`: `geometry(Point, 4326)` (PostGIS)
- `created_at`

### `waste_posts`
- `id` (PK)
- `developer_id` (FK → `profiles`)
- `waste_type`: enum (`concrete`, `wood`, `metal`, `plastic`, `mixed`, `hazardous`, `other`)
- `quantity`: numeric, `quantity_unit`: (`tons` | `cubic_meters`)
- `location`: PostGIS `geometry(Point, 4326)`
- `pickup_date_start`, `pickup_date_end`
- `photos[]` (array of storage refs)
- `status`: enum (`posted`, `selected`, `in_transit`, `delivered`, `cancelled`)
- `price` (set by platform or recycler)
- `commission_rate` (default 10 %)
- `created_at`, `updated_at`

### `waste_selections`
- `id` (PK)
- `waste_post_id` (FK → `waste_posts`)
- `recycler_id` (FK → `profiles`)
- `selected_at`
- `accepted_price`

### `hauls` (created when recycler selects waste)
- `id` (PK)
- `waste_post_id` (FK)
- `hauler_id` (FK → `profiles`, nullable until accepted)
- `recycler_id` (FK → `profiles`)
- `status`: enum (`open`, `accepted`, `picked_up`, `in_transit`, `delivered`, `paid`)
- `pickup_location`, `delivery_location`: PostGIS
- `pickup_confirmed_at`, `delivery_confirmed_at`
- `created_at`

### `payments`
- `id` (PK)
- `haul_id` (FK)
- `payer_id` (recycler, FK → `profiles`)
- `amount` (total from recycler)
- `platform_commission`, `hauler_share`, `developer_share`
- `status`: enum (`pending`, `completed`)
- `created_at`, `released_at`

### `tracking_events`
- `id` (PK)
- `haul_id` (FK)
- `position`: PostGIS
- `recorded_at` (timestamp, default `now()`)
- Old events pruned by pg_cron

### `commission_settings`
Global commission rate config. Managed by admin.
- `id`, `rate` (decimal, default 0.10)
- `effective_date`
- `created_by` (FK → profiles, admin)

### `payment_refunds`
Tracks refunds/partial refunds issued by admin.
- `id`, `payment_id` (FK → payments)
- `refund_amount`, `refund_reason`
- `status`: enum (`pending`, `completed`, `rejected`)
- `refunded_by` (FK → profiles, admin)
- `created_at`

### `platform_audit_log`
Logs all admin actions (refunds, bans, commission changes, approvals).
- `id`, `user_id` (FK → profiles, the admin)
- `action_type`: enum (`ban_user`, `unban_user`, `approve_hauler`, `reject_hauler`, `refund`, `commission_update`, `delete_post`)
- `target_user_id`, `details` (JSONB context)
- `created_at`

### `notifications`
- `id`, `user_id` (FK → `profiles`), `type`, `title`, `body`, `read`, `created_at`

---

## 3. App Screens & Flow (by role)

### Admin Flow
1. **Login** → sees Admin dashboard
2. **Dashboard**: key metrics (total posts, active hauls, total revenue, pending verifications, disputed payments)
3. **User Management**:
   - View all users by role
   - Approve/reject hauler verification (updates `verification_status`)
   - Ban/unban users (sets `banned` / `banned_at` on profiles)
   - View user details and activity
4. **Payment Overview**: list all payments with status; filter by date range, user, dispute flag
5. **Refund Engine**: select a payment, enter refund amount (full or partial), add reason → triggers `refund_payment` Edge Function
6. **Commission Management**: update global commission rate → new row in `commission_settings` takes effect immediately
7. **Audit Log**: view `platform_audit_log` entries with pagination and filtering
8. **Posts Management**: view all posts, force-delete or hide problematic posts

### Site Developer Flow
1. **Login** → sees Developer dashboard
2. **Create Post**: form with waste type, quantity, pickup location, pickup date range, photos
3. **My Posts**: list of posts with status (posted → selected → in_transit → delivered → paid)
4. **Payment History**: list of completed payments showing developer share

### Site Developer Flow
1. **Login** → sees Developer dashboard
2. **Create Post**: form with waste type, quantity, pickup location, pickup date range, photos
3. **My Posts**: list of posts with status (posted → selected → in_transit → delivered → paid)
4. **Payment History**: list of completed payments showing developer share

### Recycling Company Flow
1. **Login** → sees Recycler dashboard
2. **Browse Waste**: map + list view of available `waste_posts` near recycler location; filter by type, distance, price range
3. **Select Waste**: tap a post → confirm selection → creates `waste_selection` + `haul` → lock post from other recyclers
4. **My Selected Waste**: list of selected waste with status; initiate payment here
5. **Payment History**: list of paid hauls

### Hauler Flow
1. **Login** → sees Hauler dashboard (only visible for `verification_status = approved`)
2. **Available Jobs**: map + list of open `hauls`; filter by distance from current location
3. **Accept Job**: tap → accept → sets `hauler_id`, status → `accepted`; send notification to developer and recycler
4. **Active Haul**:
   - Pickup confirmation: hauler at pickup location → confirm → status → `picked_up`
   - Real-time tracking: stream GPS to `tracking_events`
   - Delivery confirmation: at recycler location → confirm → status → `delivered`
5. **My Jobs**: history of completed hauls
6. **Payment History**: list of earnings per haul

---

## 4. Payment & Commission Flow

**Who pays whom:**
1. Recycling company pays **platform owner** (you / the app).
2. Platform holds funds in escrow.
3. Once delivery is confirmed (`status = delivered`), the platform distributes funds via Edge Function.

**Distribution (Edge Function):**
```
platform_commission = haul.price * commission_rate
developer_share     = haul.price * developer_rate   (configurable, e.g., 40 %)
hauler_share        = haul.price - commission - developer_share
```

Payments are **manual or semi-automated** (via Orange Money / MTN Mobile Money / PayPal API) depending on what the user selects. The Edge Function records intent; actual mobile-money transfer may be a manual step in the MVP.

---

## 5. Edge Function APIs

| Function | Purpose |
|----------|---------|
| `match_recycler` | Triggered when recycler selects waste → creates `haul`, locks post |
| `accept_haul` | Triggered when hauler accepts → sets `hauler_id`, notifies parties |
| `confirm_pickup` | Updates `status`, `pickup_confirmed_at` |
| `confirm_delivery` | Updates `status`, `delivery_confirmed_at` → triggers payment release |
| `release_payment` | Calculates splits, records in `payments` table, triggers disbursement |
| `track_position` | Receives GPS stream, inserts into `tracking_events` |
| `notify_user` | Generic push/in-app notification sender |

---

## 6. Security & RLS

All tables have **Row-Level Security** enabled.

| Table | Policy Summary |
|-------|----------------|
| `profiles` | Users read only their own row. Admins read all. |
| `waste_posts` | Developers read/own all their posts. Recyclers can read all `posted` posts. Haulers can read posts they've been assigned. Admins read all. |
| `hauls` | Haulers read/update only their assigned hauls. Recyclers read only their own selected waste's haul. Developers read only their post's haul. Admins read all. |
| `payments` | Users read only payments they are party to. Admins read all. Nobody modifies payments directly. |
| `tracking_events` | Readable by hauler, developer, and recycler of that haul. Admins read all. |

**Key assumption:** No user can modify `payments` or `commission_rate` directly. These are Edge Function–managed. Admins trigger changes only via Edge Functions (e.g., `refund_payment`, `update_commission`).

---

## 7. Location & Map Strategy

- **Library:** `flutter_map` (uses OSM tiles).
- **Permissions:** Runtime `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` in AndroidManifest.
- **Waste browse:** Show posts as markers on the map. Cluster markers when zoomed out.
- **Hauler tracking:** Hauler location streamed to `tracking_events` every 5–10 seconds while transport is active. Map shows latest position via Supabase Realtime subscription.
- **Pickup / delivery:** Reverse geocode coordinates to a human-readable address; allow manual correction before confirm.

---

## 8. Notification Strategy

Supabase Realtime channels + Firebase Cloud Messaging (FCM) for push notifications.

| Event | Notify |
|-------|--------|
| Recycler selects waste | Developer notified |
| Hauler accepts haul | Developer & Recycler notified |
| Pickup confirmed | Recycler notified |
| Delivery confirmed | All parties notified; payment release initiated |
| Payment completed | Hauler & Developer notified |

---

## 9. Tech Stack Summary

| Layer | Choice |
|-------|--------|
| Mobile | Flutter (Dart), single APK |
| Auth | Supabase Auth (email/password + phone OTP) |
| Database | Supabase Postgres with PostGIS extensions |
| Real-time | Supabase Realtime (database changes + presence) |
| File Storage | Supabase Storage (waste photos) |
| Edge functions | Supabase Edge Functions (Deno / TypeScript) |
| Maps | `flutter_map` with OSM tile layer |
| Push notifications | Firebase Cloud Messaging (FCM) |

---

## 10. MVP Scope

In scope:
- Role-based authentication and profile creation.
- Posting waste, browsing, and selecting waste.
- Hauler acceptance and basic status tracking.
- Pickup and delivery confirmation with status updates.
- Payment recording and commission splitting logic.
- Basic OSM map integration with markers for waste posts.
- In-app notifications via Realtime.

Not in scope (future):
- Automatic mobile-money (MTN/Orange Money) disbursement.
- Route optimization for haulers.
- Advanced reporting / analytics dashboards.
- Web admin panel.
