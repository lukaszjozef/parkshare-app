-- Push Notification Triggers
-- These call the send-push Edge Function when key events happen
-- Run this in Supabase SQL Editor

-- Enable the pg_net extension for HTTP calls from triggers
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Helper function: call send-push Edge Function
CREATE OR REPLACE FUNCTION notify_push(
  p_user_ids UUID[],
  p_title TEXT,
  p_body TEXT,
  p_url TEXT DEFAULT '/',
  p_tag TEXT DEFAULT 'parkshare',
  p_exclude_user_id UUID DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
  payload JSONB;
BEGIN
  -- Use Supabase project URL for Edge Function
  edge_function_url := current_setting('app.settings.supabase_url', true)
    || '/functions/v1/send-push';
  service_role_key := current_setting('app.settings.service_role_key', true);

  -- If settings not configured, use direct URL
  IF edge_function_url IS NULL OR service_role_key IS NULL THEN
    RETURN;
  END IF;

  payload := jsonb_build_object(
    'title', p_title,
    'body', p_body,
    'url', p_url,
    'tag', p_tag
  );

  IF p_user_ids IS NOT NULL THEN
    payload := payload || jsonb_build_object('user_ids', p_user_ids);
  END IF;

  IF p_exclude_user_id IS NOT NULL THEN
    payload := payload || jsonb_build_object('exclude_user_id', p_exclude_user_id);
  END IF;

  PERFORM extensions.http_post(
    edge_function_url,
    payload::TEXT,
    'application/json',
    ARRAY[
      extensions.http_header('Authorization', 'Bearer ' || service_role_key)
    ]
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: New availability = "Nowe wolne miejsce!"
-- Notifies all users EXCEPT the owner
CREATE OR REPLACE FUNCTION on_new_availability()
RETURNS TRIGGER AS $$
DECLARE
  spot_owner_id UUID;
  spot_building TEXT;
  spot_number TEXT;
BEGIN
  SELECT ps.owner_id, ps.building, ps.spot_number
  INTO spot_owner_id, spot_building, spot_number
  FROM parking_spots ps
  WHERE ps.id = NEW.spot_id;

  PERFORM notify_push(
    NULL, -- all users
    'Nowe wolne miejsce!',
    'Miejsce ' || spot_number || ' (budynek ' || spot_building || ') jest dostępne',
    '/search',
    'new-availability',
    spot_owner_id -- exclude owner
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_new_availability
  AFTER INSERT ON availability
  FOR EACH ROW
  EXECUTE FUNCTION on_new_availability();

-- Trigger: New reservation = notify spot owner
CREATE OR REPLACE FUNCTION on_new_reservation()
RETURNS TRIGGER AS $$
DECLARE
  spot_owner_id UUID;
  requester_name TEXT;
BEGIN
  SELECT ps.owner_id INTO spot_owner_id
  FROM parking_spots ps
  WHERE ps.id = NEW.spot_id;

  SELECT u.name INTO requester_name
  FROM users u
  WHERE u.id = NEW.requester_id;

  PERFORM notify_push(
    ARRAY[spot_owner_id],
    'Nowa prośba o rezerwację',
    COALESCE(requester_name, 'Ktoś') || ' chce zarezerwować Twoje miejsce',
    '/reservations',
    'new-reservation'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_new_reservation
  AFTER INSERT ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION on_new_reservation();

-- Trigger: Reservation accepted = notify requester
CREATE OR REPLACE FUNCTION on_reservation_status_change()
RETURNS TRIGGER AS $$
DECLARE
  spot_building TEXT;
  spot_number TEXT;
BEGIN
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  SELECT ps.building, ps.spot_number
  INTO spot_building, spot_number
  FROM parking_spots ps
  WHERE ps.id = NEW.spot_id;

  IF NEW.status = 'accepted' THEN
    PERFORM notify_push(
      ARRAY[NEW.requester_id],
      'Rezerwacja zaakceptowana!',
      'Miejsce ' || spot_number || ' (budynek ' || spot_building || ') jest Twoje',
      '/reservations',
      'reservation-accepted'
    );
  ELSIF NEW.status = 'rejected' THEN
    PERFORM notify_push(
      ARRAY[NEW.requester_id],
      'Rezerwacja odrzucona',
      'Niestety, miejsce ' || spot_number || ' nie jest dostępne',
      '/reservations',
      'reservation-rejected'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_reservation_status
  AFTER UPDATE ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION on_reservation_status_change();
