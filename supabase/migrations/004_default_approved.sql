-- Change default: new users are approved by default
-- Admin can deactivate accounts later
-- Run this in Supabase SQL Editor

-- Set default to true for new users
ALTER TABLE users ALTER COLUMN is_approved SET DEFAULT true;

-- Approve all existing unapproved users (optional - if you want everyone active now)
UPDATE users SET is_approved = true WHERE is_approved = false AND is_admin = false;
