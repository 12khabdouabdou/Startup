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
