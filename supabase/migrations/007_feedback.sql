-- Feedback system with upvotes
-- Run this in Supabase SQL Editor

-- Feedback posts
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Upvotes (one per user per feedback)
CREATE TABLE IF NOT EXISTS feedback_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  feedback_id UUID REFERENCES feedback(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(feedback_id, user_id)
);

-- RLS
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view feedback" ON feedback FOR SELECT USING (true);
CREATE POLICY "Users can create feedback" ON feedback FOR INSERT WITH CHECK (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can delete own feedback" ON feedback FOR DELETE USING (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);

CREATE POLICY "Anyone can view votes" ON feedback_votes FOR SELECT USING (true);
CREATE POLICY "Users can vote" ON feedback_votes FOR INSERT WITH CHECK (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can remove own vote" ON feedback_votes FOR DELETE USING (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
);

-- Indexes
CREATE INDEX idx_feedback_created ON feedback(created_at DESC);
CREATE INDEX idx_feedback_votes_feedback ON feedback_votes(feedback_id);
CREATE INDEX idx_feedback_votes_user ON feedback_votes(user_id);

-- View: feedback with vote count (for easy querying)
CREATE OR REPLACE VIEW feedback_with_votes AS
SELECT
  f.id,
  f.user_id,
  f.content,
  f.created_at,
  u.name AS author_name,
  u.building AS author_building,
  COUNT(fv.id)::int AS vote_count
FROM feedback f
JOIN users u ON f.user_id = u.id
LEFT JOIN feedback_votes fv ON f.id = fv.feedback_id
GROUP BY f.id, f.user_id, f.content, f.created_at, u.name, u.building
ORDER BY vote_count DESC, f.created_at DESC;
