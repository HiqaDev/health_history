-- QR Code Statistics and Management Functions
-- For Health History Indian Healthcare App

-- Function to increment QR code scan count
CREATE OR REPLACE FUNCTION increment_qr_scan_count(qr_record_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE qr_codes 
  SET 
    scan_count = COALESCE(scan_count, 0) + 1,
    last_scanned_at = NOW()
  WHERE qr_code_id = qr_record_id;
  
  -- If no rows were updated, the QR code doesn't exist
  IF NOT FOUND THEN
    RAISE EXCEPTION 'QR code not found';
  END IF;
END;
$$;

-- Function to get user QR code statistics
CREATE OR REPLACE FUNCTION get_user_qr_stats(user_uuid UUID)
RETURNS TABLE(
  total_codes BIGINT,
  active_codes BIGINT,
  total_scans BIGINT,
  avg_scans_per_code NUMERIC,
  most_scanned_type TEXT,
  last_generated TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_codes,
    COUNT(*) FILTER (
      WHERE is_active = true 
      AND (expires_at IS NULL OR expires_at > NOW())
    ) as active_codes,
    COALESCE(SUM(scan_count), 0) as total_scans,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        COALESCE(SUM(scan_count), 0)::NUMERIC / COUNT(*)::NUMERIC
      ELSE 0
    END as avg_scans_per_code,
    (
      SELECT qr_type 
      FROM qr_codes 
      WHERE user_id = user_uuid 
      GROUP BY qr_type 
      ORDER BY SUM(scan_count) DESC 
      LIMIT 1
    ) as most_scanned_type,
    (
      SELECT MAX(created_at) 
      FROM qr_codes 
      WHERE user_id = user_uuid
    ) as last_generated
  FROM qr_codes 
  WHERE user_id = user_uuid;
END;
$$;

-- Function to cleanup expired QR codes
CREATE OR REPLACE FUNCTION cleanup_expired_qr_codes()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete QR codes that have been expired for more than 30 days
  DELETE FROM qr_codes 
  WHERE expires_at IS NOT NULL 
    AND expires_at < (NOW() - INTERVAL '30 days');
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$;

-- Function to validate QR code access
CREATE OR REPLACE FUNCTION validate_qr_code_access(qr_record_id UUID)
RETURNS TABLE(
  is_valid BOOLEAN,
  user_id UUID,
  qr_type TEXT,
  data JSONB,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  qr_record RECORD;
BEGIN
  -- Get QR code record
  SELECT * INTO qr_record
  FROM qr_codes 
  WHERE qr_code_id = qr_record_id;
  
  -- Check if QR code exists
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, NULL::UUID, NULL::TEXT, NULL::JSONB, 'QR code not found';
    RETURN;
  END IF;
  
  -- Check if QR code is active
  IF NOT qr_record.is_active THEN
    RETURN QUERY SELECT false, qr_record.user_id, qr_record.qr_type, NULL::JSONB, 'QR code is inactive';
    RETURN;
  END IF;
  
  -- Check if QR code is expired
  IF qr_record.expires_at IS NOT NULL AND qr_record.expires_at < NOW() THEN
    RETURN QUERY SELECT false, qr_record.user_id, qr_record.qr_type, NULL::JSONB, 'QR code has expired';
    RETURN;
  END IF;
  
  -- QR code is valid, return data
  RETURN QUERY SELECT true, qr_record.user_id, qr_record.qr_type, qr_record.data, NULL::TEXT;
END;
$$;

-- Function to get emergency QR code data for display
CREATE OR REPLACE FUNCTION get_emergency_qr_display_data(qr_record_id UUID)
RETURNS TABLE(
  patient_name TEXT,
  age INTEGER,
  blood_group TEXT,
  emergency_contacts JSONB,
  critical_allergies JSONB,
  critical_medications JSONB,
  medical_alerts JSONB,
  insurance_info JSONB,
  last_updated TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  qr_data JSONB;
  qr_user_id UUID;
  validation_result RECORD;
BEGIN
  -- Validate QR code access first
  SELECT * INTO validation_result
  FROM validate_qr_code_access(qr_record_id);
  
  IF NOT validation_result.is_valid THEN
    RAISE EXCEPTION 'QR code access denied: %', validation_result.error_message;
  END IF;
  
  -- Only proceed if it's an emergency QR code
  IF validation_result.qr_type != 'emergency' THEN
    RAISE EXCEPTION 'This is not an emergency QR code';
  END IF;
  
  qr_data := validation_result.data;
  qr_user_id := validation_result.user_id;
  
  -- Return the emergency data in a structured format
  RETURN QUERY
  SELECT 
    (qr_data->'patient'->>'name')::TEXT as patient_name,
    (qr_data->'patient'->>'age')::INTEGER as age,
    (qr_data->'patient'->>'blood_group')::TEXT as blood_group,
    qr_data->'emergency_contacts' as emergency_contacts,
    qr_data->'medical_info'->'allergies' as critical_allergies,
    qr_data->'medical_info'->'critical_medications' as critical_medications,
    qr_data->'medical_info'->'medical_alerts' as medical_alerts,
    qr_data->'insurance' as insurance_info,
    (qr_data->>'generated_at')::TIMESTAMP WITH TIME ZONE as last_updated;
  
  -- Log the scan
  PERFORM increment_qr_scan_count(qr_record_id);
END;
$$;

-- Function to get top QR code types by usage
CREATE OR REPLACE FUNCTION get_qr_usage_analytics()
RETURNS TABLE(
  qr_type TEXT,
  total_codes BIGINT,
  total_scans BIGINT,
  avg_scans_per_code NUMERIC,
  active_codes BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.qr_type,
    COUNT(*) as total_codes,
    COALESCE(SUM(q.scan_count), 0) as total_scans,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        COALESCE(SUM(q.scan_count), 0)::NUMERIC / COUNT(*)::NUMERIC
      ELSE 0
    END as avg_scans_per_code,
    COUNT(*) FILTER (
      WHERE q.is_active = true 
      AND (q.expires_at IS NULL OR q.expires_at > NOW())
    ) as active_codes
  FROM qr_codes q
  GROUP BY q.qr_type
  ORDER BY total_scans DESC;
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION increment_qr_scan_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_qr_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_qr_codes() TO authenticated;
GRANT EXECUTE ON FUNCTION validate_qr_code_access(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_emergency_qr_display_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_qr_usage_analytics() TO authenticated;

-- Comment on functions
COMMENT ON FUNCTION increment_qr_scan_count(UUID) IS 'Increments scan count for a QR code and updates last scanned timestamp';
COMMENT ON FUNCTION get_user_qr_stats(UUID) IS 'Returns comprehensive QR code statistics for a specific user';
COMMENT ON FUNCTION cleanup_expired_qr_codes() IS 'Removes QR codes that have been expired for more than 30 days';
COMMENT ON FUNCTION validate_qr_code_access(UUID) IS 'Validates if a QR code can be accessed and returns its data';
COMMENT ON FUNCTION get_emergency_qr_display_data(UUID) IS 'Returns formatted emergency QR code data for medical professionals';
COMMENT ON FUNCTION get_qr_usage_analytics() IS 'Returns analytics about QR code usage by type';