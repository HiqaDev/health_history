-- Add is_critical column to medications table
-- This allows QR code generation to filter critical medications for emergency QR codes

ALTER TABLE public.medications 
ADD COLUMN is_critical BOOLEAN DEFAULT false;

-- Create index for better query performance on critical medications
CREATE INDEX idx_medications_critical ON public.medications(user_id, is_critical) 
WHERE is_critical = true;

-- Update existing medications to set some as critical (example: blood thinners, insulin, etc.)
-- This is just sample data - in real use, users would mark medications as critical themselves
UPDATE public.medications 
SET is_critical = true 
WHERE LOWER(name) LIKE '%insulin%' 
   OR LOWER(name) LIKE '%warfarin%' 
   OR LOWER(name) LIKE '%nitroglycerin%'
   OR LOWER(name) LIKE '%epinephrine%'
   OR LOWER(name) LIKE '%prednisone%';
