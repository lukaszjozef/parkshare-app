-- Fix: Add UNIQUE constraint to auth_id column
-- This is required for upsert operations with onConflict: 'auth_id'
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/incgqkflbmcxwjwqxiom/sql

-- Add unique constraint to auth_id
ALTER TABLE users ADD CONSTRAINT users_auth_id_unique UNIQUE (auth_id);
