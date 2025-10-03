-- Location: supabase/migrations/20250103120913_health_history_complete_schema.sql
-- Schema Analysis: No existing schema found - fresh project
-- Integration Type: Complete health management system
-- Dependencies: None - creating complete schema

-- 1. EXTENSIONS & TYPES
CREATE TYPE public.user_role AS ENUM ('patient', 'doctor', 'admin');
CREATE TYPE public.document_type AS ENUM ('lab_report', 'prescription', 'medical_image', 'insurance', 'vaccination', 'other');
CREATE TYPE public.medication_frequency AS ENUM ('once_daily', 'twice_daily', 'three_times_daily', 'four_times_daily', 'as_needed', 'weekly', 'custom');
CREATE TYPE public.appointment_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');
CREATE TYPE public.sharing_permission AS ENUM ('view', 'download', 'full');
CREATE TYPE public.health_metric_type AS ENUM ('blood_pressure', 'weight', 'blood_sugar', 'heart_rate', 'temperature', 'cholesterol', 'bmi');

-- 2. CORE TABLES
-- User profiles table (intermediary for auth)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'patient'::public.user_role,
    phone TEXT,
    date_of_birth DATE,
    gender TEXT,
    blood_group TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    profile_picture_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Medical documents table
CREATE TABLE public.medical_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    document_type public.document_type NOT NULL,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    tags TEXT[],
    date_of_document DATE,
    healthcare_provider TEXT,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Medications table
CREATE TABLE public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency public.medication_frequency NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    instructions TEXT,
    prescribing_doctor TEXT,
    is_active BOOLEAN DEFAULT true,
    reminder_times TIME[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Health metrics table
CREATE TABLE public.health_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    metric_type public.health_metric_type NOT NULL,
    value DECIMAL NOT NULL,
    unit TEXT NOT NULL,
    notes TEXT,
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Appointments table
CREATE TABLE public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    healthcare_provider TEXT NOT NULL,
    appointment_date TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    location TEXT,
    status public.appointment_status DEFAULT 'scheduled'::public.appointment_status,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Health timeline events table
CREATE TABLE public.health_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_type TEXT,
    healthcare_provider TEXT,
    related_document_id UUID REFERENCES public.medical_documents(id) ON DELETE SET NULL,
    is_milestone BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Document sharing table
CREATE TABLE public.document_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES public.medical_documents(id) ON DELETE CASCADE,
    shared_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    shared_with_email TEXT NOT NULL,
    shared_with_name TEXT,
    permission public.sharing_permission DEFAULT 'view'::public.sharing_permission,
    access_code TEXT,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Emergency contacts table
CREATE TABLE public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    relationship TEXT,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. ESSENTIAL INDEXES
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_medical_documents_user_id ON public.medical_documents(user_id);
CREATE INDEX idx_medical_documents_type ON public.medical_documents(document_type);
CREATE INDEX idx_medical_documents_date ON public.medical_documents(date_of_document);
CREATE INDEX idx_medications_user_id ON public.medications(user_id);
CREATE INDEX idx_medications_active ON public.medications(user_id, is_active);
CREATE INDEX idx_health_metrics_user_id ON public.health_metrics(user_id);
CREATE INDEX idx_health_metrics_type ON public.health_metrics(user_id, metric_type);
CREATE INDEX idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX idx_appointments_date ON public.appointments(appointment_date);
CREATE INDEX idx_health_events_user_id ON public.health_events(user_id);
CREATE INDEX idx_health_events_date ON public.health_events(event_date);
CREATE INDEX idx_document_shares_document_id ON public.document_shares(document_id);

-- 4. STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'medical-documents',
    'medical-documents',
    false,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
);

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    false,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- 5. HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'patient')::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 6. RLS SETUP
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

-- 7. RLS POLICIES

-- User profiles policies (Pattern 1: Core user table)
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Medical documents policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_medical_documents"
ON public.medical_documents
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Medications policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_medications"
ON public.medications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Health metrics policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_health_metrics"
ON public.health_metrics
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Appointments policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_appointments"
ON public.appointments
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Health events policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_health_events"
ON public.health_events
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Document shares policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_document_shares"
ON public.document_shares
FOR ALL
TO authenticated
USING (shared_by = auth.uid())
WITH CHECK (shared_by = auth.uid());

-- Emergency contacts policies (Pattern 2: Simple user ownership)
CREATE POLICY "users_manage_own_emergency_contacts"
ON public.emergency_contacts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Storage policies for medical documents
CREATE POLICY "users_view_own_medical_files"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'medical-documents' AND owner = auth.uid());

CREATE POLICY "users_upload_own_medical_files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'medical-documents' 
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "users_update_own_medical_files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'medical-documents' AND owner = auth.uid())
WITH CHECK (bucket_id = 'medical-documents' AND owner = auth.uid());

CREATE POLICY "users_delete_own_medical_files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'medical-documents' AND owner = auth.uid());

-- Storage policies for profile images
CREATE POLICY "users_view_own_profile_images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'profile-images' AND owner = auth.uid());

CREATE POLICY "users_upload_own_profile_images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile-images' 
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "users_update_own_profile_images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'profile-images' AND owner = auth.uid());

CREATE POLICY "users_delete_own_profile_images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'profile-images' AND owner = auth.uid());

-- 8. TRIGGERS
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_medical_documents_updated_at
    BEFORE UPDATE ON public.medical_documents
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_medications_updated_at
    BEFORE UPDATE ON public.medications
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at
    BEFORE UPDATE ON public.appointments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_health_events_updated_at
    BEFORE UPDATE ON public.health_events
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at
    BEFORE UPDATE ON public.emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 9. MOCK DATA
DO $$
DECLARE
    patient_uuid UUID := gen_random_uuid();
    doctor_uuid UUID := gen_random_uuid();
    admin_uuid UUID := gen_random_uuid();
    doc1_uuid UUID := gen_random_uuid();
    doc2_uuid UUID := gen_random_uuid();
    med1_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (patient_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'patient@healthvault.com', crypt('Patient123!', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Anderson", "role": "patient"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (doctor_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'doctor@healthvault.com', crypt('Doctor456!', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Dr. Sarah Wilson", "role": "doctor"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@healthvault.com', crypt('Admin789!', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Wait for trigger to create user profiles
    PERFORM pg_sleep(0.1);

    -- Update user profiles with additional data
    UPDATE public.user_profiles SET
        phone = '+1-555-0101',
        date_of_birth = '1978-05-15',
        gender = 'Male',
        blood_group = 'O+',
        emergency_contact_name = 'Jane Anderson',
        emergency_contact_phone = '+1-555-0102'
    WHERE id = patient_uuid;

    UPDATE public.user_profiles SET
        phone = '+1-555-0201'
    WHERE id = doctor_uuid;

    -- Sample medical documents
    INSERT INTO public.medical_documents (id, user_id, title, description, document_type, file_path, file_name, tags, date_of_document, healthcare_provider) VALUES
        (doc1_uuid, patient_uuid, 'Blood Test Results - Annual Checkup', 'Complete blood count and lipid panel results from annual physical examination', 'lab_report'::public.document_type, 'medical-documents/blood-test-2024.pdf', 'blood-test-2024.pdf', ARRAY['blood test', 'annual checkup', 'lab results'], '2024-03-15', 'City Medical Center'),
        (doc2_uuid, patient_uuid, 'Prescription - Blood Pressure Medication', 'Lisinopril 10mg daily prescription for hypertension management', 'prescription'::public.document_type, 'medical-documents/prescription-lisinopril.pdf', 'prescription-lisinopril.pdf', ARRAY['prescription', 'blood pressure', 'lisinopril'], '2024-03-16', 'Dr. Sarah Wilson');

    -- Sample medications
    INSERT INTO public.medications (id, user_id, name, dosage, frequency, start_date, instructions, prescribing_doctor, reminder_times) VALUES
        (med1_uuid, patient_uuid, 'Lisinopril', '10mg', 'once_daily'::public.medication_frequency, '2024-03-16', 'Take with food in the morning', 'Dr. Sarah Wilson', ARRAY['08:00:00'::time]),
        (gen_random_uuid(), patient_uuid, 'Vitamin D3', '1000 IU', 'once_daily'::public.medication_frequency, '2024-01-01', 'Take with breakfast', 'Dr. Sarah Wilson', ARRAY['08:30:00'::time]);

    -- Sample health metrics
    INSERT INTO public.health_metrics (user_id, metric_type, value, unit, recorded_at) VALUES
        (patient_uuid, 'blood_pressure'::public.health_metric_type, 118, 'mmHg (systolic)', now() - interval '1 day'),
        (patient_uuid, 'blood_pressure'::public.health_metric_type, 78, 'mmHg (diastolic)', now() - interval '1 day'),
        (patient_uuid, 'weight'::public.health_metric_type, 74.5, 'kg', now() - interval '1 day'),
        (patient_uuid, 'blood_sugar'::public.health_metric_type, 94, 'mg/dL', now() - interval '2 days'),
        (patient_uuid, 'heart_rate'::public.health_metric_type, 72, 'bpm', now() - interval '1 day');

    -- Sample appointments
    INSERT INTO public.appointments (user_id, title, description, healthcare_provider, appointment_date, location) VALUES
        (patient_uuid, 'Annual Physical Examination', 'Comprehensive health checkup including blood work and vital signs', 'Dr. Sarah Wilson', now() + interval '2 weeks', 'City Medical Center - Suite 201'),
        (patient_uuid, 'Cardiologist Consultation', 'Follow-up appointment for blood pressure monitoring', 'Dr. Michael Chen', now() + interval '1 month', 'Heart Health Clinic - Room 105');

    -- Sample health events
    INSERT INTO public.health_events (user_id, title, description, event_date, event_type, healthcare_provider, related_document_id, is_milestone) VALUES
        (patient_uuid, 'Diagnosed with Hypertension', 'Initial diagnosis of high blood pressure during routine checkup', '2024-03-15', 'Diagnosis', 'Dr. Sarah Wilson', doc1_uuid, true),
        (patient_uuid, 'Started Blood Pressure Medication', 'Began taking Lisinopril 10mg daily for hypertension management', '2024-03-16', 'Treatment', 'Dr. Sarah Wilson', doc2_uuid, false),
        (patient_uuid, 'Completed Annual Physical', 'All tests completed including blood work, EKG, and vital signs assessment', '2024-03-15', 'Checkup', 'Dr. Sarah Wilson', doc1_uuid, false);

    -- Sample emergency contacts
    INSERT INTO public.emergency_contacts (user_id, name, phone, email, relationship, is_primary) VALUES
        (patient_uuid, 'Jane Anderson', '+1-555-0102', 'jane.anderson@email.com', 'Spouse', true),
        (patient_uuid, 'Michael Anderson', '+1-555-0103', 'michael.anderson@email.com', 'Brother', false);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;