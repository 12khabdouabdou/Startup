-- Waste Logistics - Supabase SQL Schema
-- Run this in your Supabase project's SQL editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('customer', 'recycler', 'driver', 'admin')),
  company_name TEXT,
  address TEXT,
  profile_image_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  rating DOUBLE PRECISION DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE
);

-- Orders table
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES users(id) NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  pickup_address TEXT NOT NULL,
  pickup_lat DOUBLE PRECISION NOT NULL,
  pickup_lng DOUBLE PRECISION NOT NULL,
  waste_type TEXT NOT NULL,
  estimated_weight DOUBLE PRECISION NOT NULL,
  waste_description TEXT,
  waste_images TEXT[] DEFAULT ARRAY[]::TEXT[],
  scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'inProgress', 'completed', 'cancelled')),
  assigned_driver_id UUID REFERENCES users(id),
  assigned_driver_name TEXT,
  assigned_recycler_id UUID REFERENCES users(id),
  assigned_recycler_name TEXT,
  estimated_price DOUBLE PRECISION NOT NULL,
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
  payment_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  actual_weight DOUBLE PRECISION,
  final_price DOUBLE PRECISION
);

-- Recyclers table
CREATE TABLE recyclers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  company_name TEXT NOT NULL,
  license_number TEXT NOT NULL,
  address TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  accepted_waste_types TEXT[] NOT NULL,
  capacity DOUBLE PRECISION NOT NULL,
  current_load DOUBLE PRECISION DEFAULT 0.0,
  operating_hours TEXT NOT NULL,
  facility_images TEXT[] DEFAULT ARRAY[]::TEXT[],
  certification_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  rating DOUBLE PRECISION DEFAULT 0.0,
  total_reviews INTEGER DEFAULT 0,
  price_per_ton DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drivers table
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  license_number TEXT NOT NULL,
  vehicle_number TEXT NOT NULL,
  vehicle_type TEXT NOT NULL,
  vehicle_capacity DOUBLE PRECISION NOT NULL,
  is_available BOOLEAN DEFAULT TRUE,
  current_order_id UUID REFERENCES orders(id),
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  rating DOUBLE PRECISION DEFAULT 0.0,
  total_deliveries INTEGER DEFAULT 0,
  total_earnings DOUBLE PRECISION DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pricing table
CREATE TABLE pricing (
  waste_type TEXT PRIMARY KEY,
  price_per_ton DOUBLE PRECISION NOT NULL
);

-- Insert default pricing
INSERT INTO pricing (waste_type, price_per_ton) VALUES
  ('concrete', 50.0),
  ('metal', 120.0),
  ('wood', 30.0),
  ('plastic', 80.0),
  ('glass', 60.0),
  ('drywall', 40.0),
  ('asphalt', 55.0),
  ('mixed', 70.0),
  ('other', 45.0);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE recyclers ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Create policies for users
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Create policies for orders
CREATE POLICY "Orders are viewable by involved parties" ON orders FOR SELECT USING (
  customer_id = auth.uid() OR
  assigned_driver_id = auth.uid() OR
  assigned_recycler_id = auth.uid()
);
CREATE POLICY "Customers can create orders" ON orders FOR INSERT WITH CHECK (customer_id = auth.uid());
CREATE POLICY "Drivers can update assigned orders" ON orders FOR UPDATE USING (assigned_driver_id = auth.uid());
CREATE POLICY "Recyclers can update assigned orders" ON orders FOR UPDATE USING (assigned_recycler_id = auth.uid());

-- Create policies for recyclers
CREATE POLICY "Recyclers are viewable by everyone" ON recyclers FOR SELECT USING (is_active = true);
CREATE POLICY "Recyclers can update own profile" ON recyclers FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE id = user_id AND auth.uid() = id)
);

-- Create policies for drivers
CREATE POLICY "Drivers are viewable by everyone" ON drivers FOR SELECT USING (true);
CREATE POLICY "Drivers can update own profile" ON drivers FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE id = user_id AND auth.uid() = id)
);

-- Create indexes for better performance
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_driver_id ON orders(assigned_driver_id);
CREATE INDEX idx_orders_recycler_id ON orders(assigned_recycler_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_scheduled_date ON orders(scheduled_date);
CREATE INDEX idx_recyclers_user_id ON recyclers(user_id);
CREATE INDEX idx_recyclers_is_active ON recyclers(is_active);
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_is_available ON drivers(is_available);
CREATE INDEX idx_users_email ON users(email);

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_active_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for users table
CREATE TRIGGER update_users_last_active_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
