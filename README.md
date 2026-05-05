# EcoRoute - Construction Waste Logistics Platform

## Complete Documentation & Implementation Plan

**Version:** 1.0  
**Last Updated:** 2026-05-04  
**Status:** In Development

---

## Executive Summary

**EcoRoute** is a multi-role mobile application connecting **Developers**, **Haulers**, and **Recyclers** to streamline construction waste management. The platform enables waste generators to post listings, transportation providers to accept jobs, and processing facilities to receive materials — with full compliance tracking and environmental impact reporting.

### Key Differentiators
- Three-sided marketplace with role-specific workflows
- Full chain-of-custody documentation (waste manifests, recycling certificates)
- Environmental impact tracking (CO₂ savings, diversion rates)
- Offline-first architecture for construction sites
- OpenStreetMap integration (no Google Maps API costs)
- Integrated admin panel for platform management

---

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Framework** | Flutter 3.x / Dart 3.x | Cross-platform, single codebase |
| **State Management** | BLoC/Cubit (`flutter_bloc`) | Event-driven, testable |
| **Backend** | Supabase | PostgreSQL, Auth, Realtime, Storage |
| **Authentication** | Supabase Auth | Email + phone, role-based |
| **Database** | PostgreSQL (Supabase) | Relational, RLS security |
| **Storage** | Supabase Storage | Photos, documents |
| **Realtime** | Supabase Realtime | Chat, status updates |
| **Maps** | `flutter_map` + OSM | Free, no API key |
| **Geocoding** | Nominatim | Free address search |
| **Routing** | OSRM | Free driving directions |
| **Offline** | Hive + sync queue | Local caching |
| **Notifications** | FCM (Firebase) | Push notifications |
| **Navigation** | GoRouter | Auth guards |
| **Code Gen** | Freezed + `build_runner` | Immutable models |
| **DI** | `get_it` | Service locator |
| **Networking** | Dio | Interceptors, retry |

---

## User Roles

### 1. Developer (Waste Generator)
- Post waste listings with photos, quantity, location
- Review hauler offers and accept bids
- Track booking status from pickup to delivery
- Download recycling certificates
- View environmental impact metrics
- Manage multiple construction sites

### 2. Hauler (Transportation Provider)
- Browse available waste listings on map or list
- Submit quotes or accept instant bookings
- Update job status manually
- Navigate via Google Maps/Waze
- Track earnings and job history
- Manage fleet (multiple trucks)

### 3. Recycler (Processing Facility)
- View incoming waste listings
- Accept/decline incoming deliveries
- Track processing pipeline
- Issue recycling certificates
- View analytics
- Manage facility schedule

### 4. Admin (Platform Manager)
- Dashboard with platform overview
- User management
- Content moderation
- Dispute resolution
- Analytics and exports

---

## App Structure

```
Root
├── /splash
├── /login
├── /register
│   ├── /developer
│   ├── /hauler
│   └── /recycler
├── Shell: Developer
│   ├── /home (Dashboard)
│   ├── /listings
│   ├── /bookings
│   ├── /chat
│   ├── /map
│   └── /profile
├── Shell: Hauler
│   ├── /home (Fleet)
│   ├── /job-board
│   ├── /jobs
│   ├── /chat
│   ├── /map
│   └── /profile
├── Shell: Recycler
│   ├── /home (Processing)
│   ├── /incoming
│   ├── /schedule
│   ├── /processing
│   ├── /certificates
│   ├── /analytics
│   ├── /chat
│   ├── /map
│   └── /profile
└── Shell: Admin
    ├── /admin (Dashboard)
    ├── /admin/users
    ├── /admin/listings
    ├── /admin/bookings
    ├── /admin/reports
    ├── /admin/analytics
    └── /admin/settings
```

---

## Database Schema

```sql
-- Users and authentication
users (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  role TEXT NOT NULL, -- 'developer', 'hauler', 'recycler', 'admin'
  company_id UUID REFERENCES companies(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Companies
companies (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  address TEXT,
  city TEXT,
  country TEXT,
  license_number TEXT,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Waste listings
waste_listings (
  id UUID PRIMARY KEY,
  developer_id UUID REFERENCES users(id) NOT NULL,
  project_id UUID REFERENCES projects(id),
  site_id UUID REFERENCES sites(id),
  waste_type TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  unit TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  available_from TIMESTAMPTZ,
  available_to TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'active',
  estimated_min NUMERIC,
  estimated_max NUMERIC,
  photos TEXT[],
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Projects
projects (
  id UUID PRIMARY KEY,
  developer_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sites
sites (
  id UUID PRIMARY KEY,
  project_id UUID REFERENCES projects(id),
  name TEXT NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  contact_phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
bookings (
  id UUID PRIMARY KEY,
  listing_id UUID REFERENCES waste_listings(id),
  hauler_id UUID REFERENCES users(id),
  recycler_id UUID REFERENCES users(id),
  developer_id UUID REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'assigned',
  pickup_date TIMESTAMPTZ,
  delivery_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  price NUMERIC,
  truck_id UUID REFERENCES trucks(id),
  pickup_lat DOUBLE PRECISION,
  pickup_lng DOUBLE PRECISION,
  delivery_lat DOUBLE PRECISION,
  delivery_lng DOUBLE PRECISION,
  route_polyline TEXT,
  route_distance_m INTEGER,
  route_duration_s INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Booking status history
booking_status_history (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  status TEXT NOT NULL,
  updated_by UUID REFERENCES users(id),
  notes TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trucks
trucks (
  id UUID PRIMARY KEY,
  hauler_id UUID REFERENCES users(id),
  plate_number TEXT NOT NULL,
  truck_type TEXT NOT NULL,
  capacity_tons NUMERIC,
  status TEXT DEFAULT 'available',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages
messages (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  sender_id UUID REFERENCES users(id),
  content TEXT,
  photo_url TEXT,
  type TEXT DEFAULT 'text',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents
documents (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  uploaded_by UUID REFERENCES users(id),
  type TEXT NOT NULL,
  file_url TEXT NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  verified_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Recycling certificates
recycling_certificates (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  recycler_id UUID REFERENCES users(id),
  developer_id UUID REFERENCES users(id),
  certificate_number TEXT UNIQUE NOT NULL,
  waste_type TEXT,
  quantity NUMERIC,
  unit TEXT,
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  file_url TEXT,
  status TEXT DEFAULT 'draft'
);

-- Reports
reports (
  id UUID PRIMARY KEY,
  reporter_id UUID REFERENCES users(id),
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  reviewed_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disputes
disputes (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  reported_by UUID REFERENCES users(id),
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'open',
  resolution TEXT,
  resolved_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin users
admins (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL,
  permissions JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit log
audit_logs (
  id UUID PRIMARY KEY,
  admin_id UUID REFERENCES admins(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ratings
ratings (
  id UUID PRIMARY KEY,
  booking_id UUID REFERENCES bookings(id),
  rater_id UUID REFERENCES users(id),
  rated_id UUID REFERENCES users(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Booking Status State Machine

```dart
sealed class BookingStatus { const BookingStatus(); }

// Valid statuses:
// Assigned → EnRoutePickup → AtPickupSite → PickedUp → 
// EnRouteDelivery → AtDeliverySite → Delivered → Completed
// Cancelled (any state)
```

---

## Color Palette

### Light Mode
| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `#1B5E20` | Forest Green |
| `secondary` | `#546E7A` | Blue Gray |
| `accent` | `#FF6D00` | Safety Orange |
| `background` | `#FAFAFA` | Off-white |
| `surface` | `#FFFFFF` | White |
| `text` | `#212121` | Charcoal |
| `success` | `#2E7D32` | Green |
| `warning` | `#F9A825` | Amber |
| `error` | `#C62828` | Red |

### Dark Mode
| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `#4CAF50` | Bright Green |
| `secondary` | `#90A4AE` | Light Blue Gray |
| `accent` | `#FF9100` | Bright Orange |
| `background` | `#121212` | True dark |
| `surface` | `#1E1E1E` | Dark surface |
| `text` | `#FAFAFA` | Off-white |
| `success` | `#66BB6A` | Light green |
| `warning` | `#FFCA28` | Light amber |
| `error` | `#EF5350` | Light red |

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Flutter project setup
- [ ] Supabase initialization
- [ ] Authentication (3 roles)
- [ ] GoRouter with guards
- [ ] Theme setup
- [ ] Hive initialization
- [ ] DI setup
- [ ] Freezed models

### Phase 2: Waste Listings (Week 3)
- [ ] Create listing wizard
- [ ] Map picker (Nominatim)
- [ ] Photo upload
- [ ] Listings feed
- [ ] Listing detail

### Phase 3: Booking Flow (Weeks 4-5)
- [ ] Job board
- [ ] Incoming feed
- [ ] Booking state machine
- [ ] Status updates
- [ ] Booking detail

### Phase 4: Map Integration (Week 6)
- [ ] flutter_map setup
- [ ] Listing markers
- [ ] OSRM routing
- [ ] External navigation

### Phase 5: Chat & Notifications (Week 7)
- [ ] Supabase Realtime chat
- [ ] Chat screens
- [ ] FCM integration

### Phase 6: Certificates & Documents (Week 8)
- [ ] Document upload
- [ ] Certificate generation
- [ ] Verification workflow

### Phase 7: Admin Panel (Weeks 9-10)
- [ ] Admin authentication
- [ ] Dashboard
- [ ] User management
- [ ] Moderation

### Phase 8: Analytics & Polish (Week 11)
- [ ] Environmental stats
- [ ] Earnings/spend
- [ ] Exports
- [ ] Error handling

### Phase 9: Offline & Launch (Week 12)
- [ ] Hive caching
- [ ] Sync queue
- [ ] Crashlytics
- [ ] App store prep

---

## Skills Active

1. **dart-flutter-patterns** - BLoC, GoRouter, Freezed, Dio
2. **frontend-design** - Visual design, color systems
3. **tdd-workflow** - Test-first development, 80%+ coverage
4. **verification-loop** - Quality gates after each feature
5. **coding-standards** - Naming, immutability, error handling

---

## Next Steps

1. Create Flutter project
2. Set up Supabase backend
3. Implement authentication
4. Build theme system
5. Configure navigation

**Status: Ready to begin Phase 1**
