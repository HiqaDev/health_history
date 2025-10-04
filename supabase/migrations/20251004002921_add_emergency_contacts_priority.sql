-- Add priority column to emergency_contacts table
-- This allows QR code generation to order emergency contacts by priority

ALTER TABLE public.emergency_contacts 
ADD COLUMN priority INTEGER DEFAULT 1;

-- Create index for better query performance
CREATE INDEX idx_emergency_contacts_priority ON public.emergency_contacts(user_id, priority);

-- Update existing emergency contacts to set priority based on is_primary
-- Primary contacts get priority 1, others get priority 2
UPDATE public.emergency_contacts 
SET priority = CASE 
    WHEN is_primary = true THEN 1 
    ELSE 2 
END;

-- Add a constraint to ensure priority is positive
ALTER TABLE public.emergency_contacts 
ADD CONSTRAINT emergency_contacts_priority_positive 
CHECK (priority > 0);
