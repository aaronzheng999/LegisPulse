-- Add change_seen_at timestamp column for 1-day expiry of LC change marks
ALTER TABLE public.bill_lc_tracking
  ADD COLUMN IF NOT EXISTS change_seen_at timestamptz;
