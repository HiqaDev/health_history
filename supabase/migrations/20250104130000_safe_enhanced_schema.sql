-- Complete Safe Enhanced Schema for Indian Health App
-- This migration creates all necessary tables including base tables and enhanced features

-- 1. ENABLE EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. BASE ENUMS
DO $$ BEGIN
    CREATE TYPE public.user_role AS ENUM ('patient', 'doctor', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.blood_group AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.document_type AS ENUM ('prescription', 'lab_report', 'xray', 'mri', 'ct_scan', 'ultrasound', 'ecg', 'bill', 'insurance', 'vaccination_record', 'discharge_summary');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. ENHANCED ENUMS FOR INDIAN MARKET
DO $$ BEGIN
    CREATE TYPE public.doctor_specialization AS ENUM (
        'general_medicine', 'cardiology', 'neurology', 'orthopedics', 'gynecology', 
        'pediatrics', 'dermatology', 'psychiatry', 'radiology', 'pathology',
        'ent', 'ophthalmology', 'urology', 'oncology', 'endocrinology',
        'pulmonology', 'gastroenterology', 'nephrology', 'rheumatology', 'anesthesiology'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.sharing_type AS ENUM ('emergency_qr', 'doctor_visit', 'insurance_claim', 'family_access', 'second_opinion');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.reminder_type AS ENUM ('medication', 'appointment', 'test_due', 'vaccination', 'custom');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.timeline_event_type AS ENUM ('diagnosis', 'treatment', 'surgery', 'test', 'vaccination', 'hospital_visit', 'prescription', 'symptom');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.file_category AS ENUM ('prescription', 'lab_report', 'xray', 'mri', 'ct_scan', 'ultrasound', 'ecg', 'bill', 'insurance', 'vaccination_record', 'discharge_summary');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. BASE TABLES (user_profiles and dependencies)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    phone TEXT,
    address TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    blood_group public.blood_group,
    allergies TEXT[],
    medical_conditions TEXT[],
    user_role public.user_role DEFAULT 'patient',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Emergency contacts
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    relationship TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Medical documents base table
CREATE TABLE IF NOT EXISTS public.medical_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    document_type public.document_type NOT NULL,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    document_date DATE NOT NULL,
    hospital_name TEXT,
    doctor_name TEXT,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Health events base table
CREATE TABLE IF NOT EXISTS public.health_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_type TEXT NOT NULL,
    hospital_name TEXT,
    doctor_name TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Medications base table
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    prescribing_doctor TEXT,
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Appointments base table
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    hospital_name TEXT,
    appointment_date TIMESTAMPTZ NOT NULL,
    purpose TEXT,
    status TEXT DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Health metrics base table
CREATE TABLE IF NOT EXISTS public.health_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    metric_type TEXT NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    unit TEXT NOT NULL,
    recorded_date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. ENHANCED TABLES FOR INDIAN MARKET
-- Doctor profiles enhanced table
CREATE TABLE IF NOT EXISTS public.doctor_profiles (
    id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    medical_license_number TEXT UNIQUE NOT NULL,
    specialization public.doctor_specialization[] NOT NULL,
    qualification TEXT NOT NULL,
    years_of_experience INTEGER,
    hospital_affiliations TEXT[],
    clinic_address TEXT,
    consultation_fee DECIMAL(10,2),
    available_days TEXT[],
    consultation_hours JSONB,
    is_verified BOOLEAN DEFAULT false,
    verification_documents TEXT[],
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    bio TEXT,
    languages_spoken TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. QR CODES TABLE
CREATE TABLE IF NOT EXISTS public.qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    qr_type public.sharing_type NOT NULL,
    qr_data JSONB NOT NULL,
    access_code TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ,
    view_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. ENHANCED REMINDERS TABLE
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    reminder_type public.reminder_type NOT NULL,
    related_medication_id UUID REFERENCES public.medications(id) ON DELETE CASCADE,
    related_appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
    scheduled_time TIMESTAMPTZ NOT NULL,
    repeat_pattern JSONB,
    is_active BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    notification_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. TIMELINE EVENTS TABLE
CREATE TABLE IF NOT EXISTS public.timeline_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type public.timeline_event_type NOT NULL,
    event_date TIMESTAMPTZ NOT NULL,
    doctor_id UUID REFERENCES public.doctor_profiles(id) ON DELETE SET NULL,
    hospital_name TEXT,
    department TEXT,
    diagnosis_codes TEXT[],
    symptoms TEXT[],
    treatment_notes TEXT,
    related_document_ids UUID[],
    medications_prescribed JSONB[],
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    is_critical BOOLEAN DEFAULT false,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. DOCTOR NOTES TABLE
CREATE TABLE IF NOT EXISTS public.doctor_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    doctor_id UUID REFERENCES public.doctor_profiles(id) ON DELETE CASCADE,
    timeline_event_id UUID REFERENCES public.timeline_events(id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    chief_complaint TEXT,
    history_of_present_illness TEXT,
    physical_examination TEXT,
    assessment TEXT,
    plan TEXT,
    voice_note_url TEXT,
    is_shared_with_patient BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. SECURE SHARES TABLE
CREATE TABLE IF NOT EXISTS public.secure_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shared_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    shared_with_email TEXT,
    shared_with_doctor_id UUID REFERENCES public.doctor_profiles(id) ON DELETE SET NULL,
    sharing_type public.sharing_type NOT NULL,
    shared_data JSONB NOT NULL,
    access_code TEXT UNIQUE NOT NULL,
    password_protected BOOLEAN DEFAULT false,
    access_password TEXT,
    max_access_count INTEGER,
    current_access_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    access_log JSONB[],
    purpose TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. HEALTH INSURANCE TABLE
CREATE TABLE IF NOT EXISTS public.health_insurance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_name TEXT NOT NULL,
    policy_number TEXT NOT NULL,
    policy_holder_name TEXT NOT NULL,
    relationship_to_user TEXT,
    coverage_amount DECIMAL(12,2),
    premium_amount DECIMAL(10,2),
    policy_start_date DATE NOT NULL,
    policy_end_date DATE NOT NULL,
    network_hospitals TEXT[],
    covered_treatments TEXT[],
    exclusions TEXT[],
    claim_history JSONB[],
    documents TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 9. VACCINATIONS TABLE
CREATE TABLE IF NOT EXISTS public.vaccinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    vaccine_name TEXT NOT NULL,
    vaccine_type TEXT,
    dose_number INTEGER,
    total_doses INTEGER,
    administered_date DATE NOT NULL,
    administered_by TEXT,
    hospital_clinic TEXT,
    batch_number TEXT,
    manufacturer TEXT,
    next_dose_due DATE,
    side_effects TEXT,
    certificate_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 15. BASE INDEXES
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON public.emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_medical_documents_user_id ON public.medical_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_medical_documents_type ON public.medical_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_medical_documents_date ON public.medical_documents(document_date DESC);
CREATE INDEX IF NOT EXISTS idx_health_events_user_id ON public.health_events(user_id);
CREATE INDEX IF NOT EXISTS idx_health_events_date ON public.health_events(event_date DESC);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON public.medications(user_id);
CREATE INDEX IF NOT EXISTS idx_medications_active ON public.medications(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_id ON public.health_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_health_metrics_type ON public.health_metrics(metric_type);

-- 16. ENHANCED INDEXES
CREATE INDEX IF NOT EXISTS idx_doctor_profiles_specialization ON public.doctor_profiles USING GIN(specialization);
CREATE INDEX IF NOT EXISTS idx_doctor_profiles_verified ON public.doctor_profiles(is_verified);
CREATE INDEX IF NOT EXISTS idx_qr_codes_access_code ON public.qr_codes(access_code);
CREATE INDEX IF NOT EXISTS idx_qr_codes_user_active ON public.qr_codes(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_reminders_user_scheduled ON public.reminders(user_id, scheduled_time);
CREATE INDEX IF NOT EXISTS idx_timeline_events_user_date ON public.timeline_events(user_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_timeline_events_type ON public.timeline_events(event_type);
CREATE INDEX IF NOT EXISTS idx_doctor_notes_patient_date ON public.doctor_notes(patient_id, visit_date DESC);
CREATE INDEX IF NOT EXISTS idx_secure_shares_access_code ON public.secure_shares(access_code);
CREATE INDEX IF NOT EXISTS idx_vaccinations_user_date ON public.vaccinations(user_id, administered_date DESC);

-- 17. SAFE STORAGE BUCKETS
-- Base medical documents bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'medical-documents',
    'medical-documents',
    false,
    52428800, -- 50MB
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'medical-images-enhanced',
    'medical-images-enhanced',
    false,
    104857600,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/tiff', 'image/dicom', 'application/dicom']
) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'voice-notes',
    'voice-notes',
    false,
    10485760,
    ARRAY['audio/mpeg', 'audio/wav', 'audio/m4a', 'audio/webm']
) ON CONFLICT (id) DO NOTHING;

-- 18. BASE FUNCTIONS
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 19. ENHANCED FUNCTIONS
CREATE OR REPLACE FUNCTION public.generate_access_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$;

-- 20. BASE RLS POLICIES
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;

-- Base policies
CREATE POLICY "users_manage_own_profile" ON public.user_profiles FOR ALL TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "users_manage_own_emergency_contacts" ON public.emergency_contacts FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_medical_documents" ON public.medical_documents FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_health_events" ON public.health_events FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_medications" ON public.medications FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_appointments" ON public.appointments FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_health_metrics" ON public.health_metrics FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 21. ENHANCED RLS POLICIES
ALTER TABLE public.doctor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.secure_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_insurance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vaccinations ENABLE ROW LEVEL SECURITY;

-- Enhanced policies
CREATE POLICY "doctors_manage_own_profile" ON public.doctor_profiles FOR ALL TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "public_read_verified_doctors" ON public.doctor_profiles FOR SELECT TO authenticated USING (is_verified = true);
CREATE POLICY "users_manage_own_qr_codes" ON public.qr_codes FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_reminders" ON public.reminders FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_timeline_events" ON public.timeline_events FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_health_insurance" ON public.health_insurance FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_vaccinations" ON public.vaccinations FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "doctors_manage_own_notes" ON public.doctor_notes FOR ALL TO authenticated USING (doctor_id = auth.uid()) WITH CHECK (doctor_id = auth.uid());
CREATE POLICY "patients_read_own_notes" ON public.doctor_notes FOR SELECT TO authenticated USING (patient_id = auth.uid());
CREATE POLICY "users_manage_own_shares" ON public.secure_shares FOR ALL TO authenticated USING (shared_by = auth.uid()) WITH CHECK (shared_by = auth.uid());

-- 22. BASE TRIGGERS
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_medical_documents_updated_at BEFORE UPDATE ON public.medical_documents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_health_events_updated_at BEFORE UPDATE ON public.health_events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON public.medications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 23. ENHANCED TRIGGERS
CREATE TRIGGER update_doctor_profiles_updated_at BEFORE UPDATE ON public.doctor_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_qr_codes_updated_at BEFORE UPDATE ON public.qr_codes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON public.reminders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_timeline_events_updated_at BEFORE UPDATE ON public.timeline_events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_doctor_notes_updated_at BEFORE UPDATE ON public.doctor_notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_health_insurance_updated_at BEFORE UPDATE ON public.health_insurance FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_vaccinations_updated_at BEFORE UPDATE ON public.vaccinations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();