-- Fix missing columns for QR code generation functionality
-- This migration adds all the columns that the QR code service expects

-- Add missing columns to health_events table
ALTER TABLE public.health_events 
ADD COLUMN IF NOT EXISTS severity TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add missing columns to medications table  
ALTER TABLE public.medications 
ADD COLUMN IF NOT EXISTS medication_name TEXT,
ADD COLUMN IF NOT EXISTS purpose TEXT;

-- Update existing medications to populate medication_name from name field
UPDATE public.medications 
SET medication_name = name 
WHERE medication_name IS NULL;

-- Create health_insurance table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.health_insurance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_name TEXT NOT NULL,
    policy_number TEXT,
    group_number TEXT,
    member_id TEXT,
    coverage_type TEXT,
    effective_date DATE,
    expiration_date DATE,
    contact_phone TEXT,
    contact_email TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_health_events_severity ON public.health_events(user_id, severity) 
WHERE severity IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_health_insurance_active ON public.health_insurance(user_id, is_active) 
WHERE is_active = true;

-- Enable RLS on health_insurance table
ALTER TABLE public.health_insurance ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for health_insurance (drop if exists first)
DROP POLICY IF EXISTS "users_manage_own_insurance" ON public.health_insurance;
CREATE POLICY "users_manage_own_insurance"
ON public.health_insurance
FOR ALL
TO authenticated
USING (auth.uid() = user_id);

-- Create or replace trigger function for health_insurance updated_at
CREATE OR REPLACE FUNCTION update_health_insurance_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for health_insurance updated_at (drop if exists first)
DROP TRIGGER IF EXISTS update_health_insurance_updated_at ON public.health_insurance;
CREATE TRIGGER update_health_insurance_updated_at
    BEFORE UPDATE ON public.health_insurance
    FOR EACH ROW EXECUTE PROCEDURE update_health_insurance_updated_at();
