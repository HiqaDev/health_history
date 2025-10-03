-- Add increment_access_count function for secure sharing
CREATE OR REPLACE FUNCTION increment_access_count(share_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE secure_shares 
  SET access_count = COALESCE(access_count, 0) + 1,
      last_accessed_at = NOW()
  WHERE id = share_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;