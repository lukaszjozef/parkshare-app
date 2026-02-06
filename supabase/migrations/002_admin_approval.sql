-- Admin approval system
-- Run this in Supabase SQL Editor

-- Add approval and admin columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- Set your admin account (run this ONCE with your email)
-- UPDATE users SET is_admin = true, is_approved = true WHERE email = 'kunsztyk@wp.pl';

-- Auto-approve admins
CREATE OR REPLACE FUNCTION auto_approve_admin()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_admin = true THEN
    NEW.is_approved = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_auto_approve_admin
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION auto_approve_admin();

-- RLS: Only approved users can see other users
DROP POLICY IF EXISTS "Users can view all users" ON users;
CREATE POLICY "Approved users can view other users" ON users
  FOR SELECT USING (
    -- User can always see themselves
    auth.uid() = auth_id
    OR
    -- Approved users can see other approved users
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_id = auth.uid() AND u.is_approved = true
    )
  );

-- RLS: Only admins can update other users' approval status
CREATE POLICY "Admins can update user approval" ON users
  FOR UPDATE USING (
    -- User can update themselves (except is_admin)
    auth.uid() = auth_id
    OR
    -- Admins can update anyone
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.auth_id = auth.uid() AND u.is_admin = true
    )
  );

-- Create view for pending approvals (for admin panel)
CREATE OR REPLACE VIEW pending_approvals AS
SELECT id, email, name, building, apartment_number, created_at
FROM users
WHERE is_approved = false AND is_admin = false
ORDER BY created_at DESC;

-- Grant access to the view
GRANT SELECT ON pending_approvals TO authenticated;
