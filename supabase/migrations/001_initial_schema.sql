-- ParkShare Initial Schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/incgqkflbmcxwjwqxiom/sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================
-- USERS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  building TEXT,
  apartment_number TEXT,
  phone TEXT,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- PARKING SPOTS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS parking_spots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  building TEXT NOT NULL,
  level TEXT,
  spot_number TEXT NOT NULL,
  description TEXT,
  photo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- AVAILABILITY TABLE
-- =====================
CREATE TABLE IF NOT EXISTS availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID REFERENCES parking_spots(id) ON DELETE CASCADE NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  is_recurring BOOLEAN DEFAULT false,
  recurrence_rule TEXT,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- RESERVATIONS TABLE
-- =====================
CREATE TYPE reservation_status AS ENUM ('pending', 'accepted', 'rejected', 'cancelled', 'completed');

CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  spot_id UUID REFERENCES parking_spots(id) ON DELETE CASCADE NOT NULL,
  availability_id UUID REFERENCES availability(id) ON DELETE SET NULL,
  requester_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status reservation_status DEFAULT 'pending',
  message TEXT,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- MESSAGES TABLE (Chat)
-- =====================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reservation_id UUID REFERENCES reservations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- ROW LEVEL SECURITY
-- =====================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE parking_spots ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users: can read all, update own
CREATE POLICY "Users can view all users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = auth_id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = auth_id);

-- Parking spots: can read all active, owner can manage
CREATE POLICY "Anyone can view active spots" ON parking_spots FOR SELECT USING (is_active = true);
CREATE POLICY "Owner can manage own spots" ON parking_spots FOR ALL USING (
  owner_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);

-- Availability: can read all, owner can manage
CREATE POLICY "Anyone can view availability" ON availability FOR SELECT USING (true);
CREATE POLICY "Spot owner can manage availability" ON availability FOR ALL USING (
  spot_id IN (
    SELECT ps.id FROM parking_spots ps
    JOIN users u ON ps.owner_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);

-- Reservations: involved parties can view/manage
CREATE POLICY "Users can view own reservations" ON reservations FOR SELECT USING (
  requester_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  OR spot_id IN (
    SELECT ps.id FROM parking_spots ps
    JOIN users u ON ps.owner_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);
CREATE POLICY "Requester can create reservation" ON reservations FOR INSERT WITH CHECK (
  requester_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);
CREATE POLICY "Involved parties can update reservation" ON reservations FOR UPDATE USING (
  requester_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  OR spot_id IN (
    SELECT ps.id FROM parking_spots ps
    JOIN users u ON ps.owner_id = u.id
    WHERE u.auth_id = auth.uid()
  )
);

-- Messages: involved parties can view/send
CREATE POLICY "Chat participants can view messages" ON messages FOR SELECT USING (
  reservation_id IN (
    SELECT r.id FROM reservations r
    JOIN users u ON (r.requester_id = u.id OR r.spot_id IN (
      SELECT ps.id FROM parking_spots ps WHERE ps.owner_id = u.id
    ))
    WHERE u.auth_id = auth.uid()
  )
);
CREATE POLICY "Chat participants can send messages" ON messages FOR INSERT WITH CHECK (
  sender_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);

-- =====================
-- INDEXES
-- =====================
CREATE INDEX idx_parking_spots_owner ON parking_spots(owner_id);
CREATE INDEX idx_parking_spots_building ON parking_spots(building);
CREATE INDEX idx_availability_spot ON availability(spot_id);
CREATE INDEX idx_availability_dates ON availability(starts_at, ends_at);
CREATE INDEX idx_reservations_spot ON reservations(spot_id);
CREATE INDEX idx_reservations_requester ON reservations(requester_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_messages_reservation ON messages(reservation_id);
CREATE INDEX idx_messages_created ON messages(created_at);

-- =====================
-- UPDATED_AT TRIGGER
-- =====================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER parking_spots_updated_at BEFORE UPDATE ON parking_spots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER reservations_updated_at BEFORE UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
