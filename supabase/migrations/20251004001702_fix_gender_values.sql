-- Fix existing gender values to match the check constraint
-- Convert any uppercase gender values to lowercase

UPDATE public.user_profiles 
SET gender = LOWER(gender) 
WHERE gender IS NOT NULL 
  AND gender IN ('Male', 'Female', 'Other', 'MALE', 'FEMALE', 'OTHER');

-- Ensure all gender values conform to the check constraint
UPDATE public.user_profiles 
SET gender = CASE 
  WHEN LOWER(gender) = 'male' THEN 'male'
  WHEN LOWER(gender) = 'female' THEN 'female'
  WHEN LOWER(gender) = 'other' THEN 'other'
  ELSE NULL
END
WHERE gender IS NOT NULL;
