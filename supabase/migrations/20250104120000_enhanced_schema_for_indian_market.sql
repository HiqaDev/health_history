-- Enhanced Schema for Indian Health App - Phase 2
-- Target Market: India
-- Features: Doctor onboarding, QR codes, advanced sharing, timeline enhancements

-- 1. ENHANCED ENUMS FOR INDIAN MARKET
CREATE TYPE public.doctor_specialization AS ENUM (
    'general_medicine', 'cardiology', 'neurology', 'orthopedics', 'gynecology', 
    'pediatrics', 'dermatology', 'psychiatry', 'radiology', 'pathology',
    'ent', 'ophthalmology', 'urology', 'oncology', 'endocrinology',
    'pulmonology', 'gastroenterology', 'nephrology', 'rheumatology', 'anesthesiology'
);

CREATE TYPE public.sharing_type AS ENUM ('emergency_qr', 'doctor_visit', 'insurance_claim', 'family_access', 'second_opinion');
CREATE TYPE public.reminder_type AS ENUM ('medication', 'appointment', 'test_due', 'vaccination', 'custom');
CREATE TYPE public.timeline_event_type AS ENUM ('diagnosis', 'treatment', 'surgery', 'test', 'vaccination', 'hospital_visit', 'prescription', 'symptom');
CREATE TYPE public.file_category AS ENUM ('prescription', 'lab_report', 'xray', 'mri', 'ct_scan', 'ultrasound', 'ecg', 'bill', 'insurance', 'vaccination_record', 'discharge_summary');

-- 2. DOCTOR PROFILES TABLE
CREATE TABLE public.doctor_profiles (
    id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    medical_license_number TEXT UNIQUE NOT NULL,
    specialization public.doctor_specialization[] NOT NULL,
    qualification TEXT NOT NULL, -- MBBS, MD, etc.
    years_of_experience INTEGER,
    hospital_affiliations TEXT[],
    clinic_address TEXT,
    consultation_fee DECIMAL(10,2),
    available_days TEXT[], -- ['monday', 'tuesday', etc.]
    consultation_hours JSONB, -- {"start": "09:00", "end": "17:00"}
    is_verified BOOLEAN DEFAULT false,
    verification_documents TEXT[], -- License, degree certificates
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    bio TEXT,
    languages_spoken TEXT[], -- ['english', 'hindi', 'tamil', etc.]
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. QR CODES TABLE
CREATE TABLE public.qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    qr_type public.sharing_type NOT NULL,
    qr_data JSONB NOT NULL, -- Contains emergency info or document IDs
    access_code TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ,
    view_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. ENHANCED REMINDERS TABLE
CREATE TABLE public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    reminder_type public.reminder_type NOT NULL,
    related_medication_id UUID REFERENCES public.medications(id) ON DELETE CASCADE,
    related_appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
    scheduled_time TIMESTAMPTZ NOT NULL,
    repeat_pattern JSONB, -- {"type": "daily", "interval": 1, "days": ["monday"]}
    is_active BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    notification_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. ENHANCED TIMELINE TABLE (replacing health_events)
CREATE TABLE public.timeline_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type public.timeline_event_type NOT NULL,
    event_date TIMESTAMPTZ NOT NULL,
    doctor_id UUID REFERENCES public.doctor_profiles(id) ON DELETE SET NULL,
    hospital_name TEXT,
    department TEXT,
    diagnosis_codes TEXT[], -- ICD-10 codes
    symptoms TEXT[],
    treatment_notes TEXT,
    related_document_ids UUID[],
    medications_prescribed JSONB[], -- Array of medication objects
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    is_critical BOOLEAN DEFAULT false,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. DOCTOR NOTES TABLE
CREATE TABLE public.doctor_notes (
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
    voice_note_url TEXT, -- For voice-to-text notes
    is_shared_with_patient BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. ENHANCED SHARING TABLE
CREATE TABLE public.secure_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shared_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    shared_with_email TEXT,
    shared_with_doctor_id UUID REFERENCES public.doctor_profiles(id) ON DELETE SET NULL,
    sharing_type public.sharing_type NOT NULL,
    shared_data JSONB NOT NULL, -- Document IDs, timeline events, etc.
    access_code TEXT UNIQUE NOT NULL,
    password_protected BOOLEAN DEFAULT false,
    access_password TEXT,
    max_access_count INTEGER,
    current_access_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    access_log JSONB[], -- Track who accessed when
    purpose TEXT, -- Why sharing (insurance claim, second opinion, etc.)
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. OFFLINE SYNC TABLE
CREATE TABLE public.offline_sync (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    data JSONB NOT NULL,
    sync_status TEXT DEFAULT 'pending', -- 'pending', 'synced', 'failed'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMPTZ
);

-- 9. HEALTH INSURANCE TABLE (for Indian market)
CREATE TABLE public.health_insurance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_name TEXT NOT NULL,
    policy_number TEXT NOT NULL,
    policy_holder_name TEXT NOT NULL,
    relationship_to_user TEXT, -- 'self', 'parent', 'spouse', etc.
    coverage_amount DECIMAL(12,2),
    premium_amount DECIMAL(10,2),
    policy_start_date DATE NOT NULL,
    policy_end_date DATE NOT NULL,
    network_hospitals TEXT[],
    covered_treatments TEXT[],
    exclusions TEXT[],
    claim_history JSONB[],
    documents TEXT[], -- Policy documents
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 10. ENHANCED MEDICAL DOCUMENTS (replacing existing with categories)
DROP TABLE IF EXISTS public.medical_documents_new;
CREATE TABLE public.medical_documents_enhanced (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    doctor_id UUID REFERENCES public.doctor_profiles(id) ON DELETE SET NULL,
    timeline_event_id UUID REFERENCES public.timeline_events(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    file_category public.file_category NOT NULL,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    thumbnail_path TEXT, -- For image previews
    ocr_text TEXT, -- Extracted text for search
    tags TEXT[],
    document_date DATE NOT NULL,
    hospital_name TEXT,
    doctor_name TEXT,
    department TEXT,
    lab_values JSONB, -- Structured lab results
    is_abnormal BOOLEAN DEFAULT false, -- AI analysis flag
    is_favorite BOOLEAN DEFAULT false,
    is_critical BOOLEAN DEFAULT false, -- For emergency access
    sharing_allowed BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 11. VACCINATION RECORDS (important for Indian market)
CREATE TABLE public.vaccinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    vaccine_name TEXT NOT NULL,
    vaccine_type TEXT, -- 'covid', 'hepatitis', 'typhoid', etc.
    dose_number INTEGER,
    total_doses INTEGER,
    administered_date DATE NOT NULL,
    administered_by TEXT,
    hospital_clinic TEXT,
    batch_number TEXT,
    manufacturer TEXT,
    next_dose_due DATE,
    side_effects TEXT,
    certificate_url TEXT, -- Vaccination certificate
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 12. ENHANCED INDEXES
CREATE INDEX idx_doctor_profiles_specialization ON public.doctor_profiles USING GIN(specialization);
CREATE INDEX idx_doctor_profiles_location ON public.doctor_profiles(clinic_address);
CREATE INDEX idx_doctor_profiles_verified ON public.doctor_profiles(is_verified);

CREATE INDEX idx_qr_codes_access_code ON public.qr_codes(access_code);
CREATE INDEX idx_qr_codes_user_active ON public.qr_codes(user_id, is_active);

CREATE INDEX idx_reminders_user_scheduled ON public.reminders(user_id, scheduled_time);
CREATE INDEX idx_reminders_type_active ON public.reminders(reminder_type, is_active);

CREATE INDEX idx_timeline_events_user_date ON public.timeline_events(user_id, event_date DESC);
CREATE INDEX idx_timeline_events_type ON public.timeline_events(event_type);
CREATE INDEX idx_timeline_events_doctor ON public.timeline_events(doctor_id);
CREATE INDEX idx_timeline_events_critical ON public.timeline_events(user_id, is_critical);

CREATE INDEX idx_doctor_notes_patient_date ON public.doctor_notes(patient_id, visit_date DESC);
CREATE INDEX idx_doctor_notes_doctor ON public.doctor_notes(doctor_id);

CREATE INDEX idx_secure_shares_access_code ON public.secure_shares(access_code);
CREATE INDEX idx_secure_shares_shared_by ON public.secure_shares(shared_by);

CREATE INDEX idx_offline_sync_user_status ON public.offline_sync(user_id, sync_status);

CREATE INDEX idx_medical_documents_enhanced_user_category ON public.medical_documents_enhanced(user_id, file_category);
CREATE INDEX idx_medical_documents_enhanced_date ON public.medical_documents_enhanced(document_date DESC);
CREATE INDEX idx_medical_documents_enhanced_critical ON public.medical_documents_enhanced(user_id, is_critical);
CREATE INDEX idx_medical_documents_enhanced_search ON public.medical_documents_enhanced USING GIN(to_tsvector('english', title || ' ' || COALESCE(description, '') || ' ' || COALESCE(ocr_text, '')));

CREATE INDEX idx_vaccinations_user_date ON public.vaccinations(user_id, administered_date DESC);
CREATE INDEX idx_vaccinations_type ON public.vaccinations(vaccine_type);

-- 13. ENHANCED STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'medical-images',
    'medical-images',
    false,
    104857600, -- 100MB for X-rays, MRI, CT scans
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/tiff', 'image/dicom', 'application/dicom']
) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'voice-notes',
    'voice-notes',
    false,
    10485760, -- 10MB for voice recordings
    ARRAY['audio/mpeg', 'audio/wav', 'audio/m4a', 'audio/webm']
) ON CONFLICT (id) DO NOTHING;

-- 14. ENHANCED FUNCTIONS
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

CREATE OR REPLACE FUNCTION public.create_emergency_qr(user_uuid UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    access_code TEXT;
    emergency_data JSONB;
BEGIN
    -- Generate unique access code
    LOOP
        access_code := public.generate_access_code();
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.qr_codes WHERE access_code = access_code);
    END LOOP;
    
    -- Get emergency data
    SELECT jsonb_build_object(
        'blood_group', up.blood_group,
        'allergies', up.raw_user_meta_data->'allergies',
        'medical_conditions', up.raw_user_meta_data->'medical_conditions',
        'emergency_contacts', (
            SELECT jsonb_agg(jsonb_build_object('name', ec.name, 'phone', ec.phone, 'relationship', ec.relationship))
            FROM public.emergency_contacts ec WHERE ec.user_id = user_uuid
        ),
        'critical_medications', (
            SELECT jsonb_agg(jsonb_build_object('name', m.name, 'dosage', m.dosage))
            FROM public.medications m WHERE m.user_id = user_uuid AND m.is_active = true
        )
    ) INTO emergency_data
    FROM public.user_profiles up
    WHERE up.id = user_uuid;
    
    -- Create QR code record
    INSERT INTO public.qr_codes (user_id, qr_type, qr_data, access_code, expires_at)
    VALUES (user_uuid, 'emergency_qr', emergency_data, access_code, CURRENT_TIMESTAMP + INTERVAL '1 year');
    
    RETURN access_code;
END;
$$;

-- 15. RLS POLICIES FOR NEW TABLES
ALTER TABLE public.doctor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.secure_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_sync ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_insurance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_documents_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vaccinations ENABLE ROW LEVEL SECURITY;

-- Doctor profiles policies
CREATE POLICY "doctors_manage_own_profile"
ON public.doctor_profiles FOR ALL TO authenticated
USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "public_read_verified_doctors"
ON public.doctor_profiles FOR SELECT TO authenticated
USING (is_verified = true);

-- QR codes policies
CREATE POLICY "users_manage_own_qr_codes"
ON public.qr_codes FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Other policies follow similar pattern...
CREATE POLICY "users_manage_own_reminders" ON public.reminders FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_timeline_events" ON public.timeline_events FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_health_insurance" ON public.health_insurance FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_enhanced_documents" ON public.medical_documents_enhanced FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_vaccinations" ON public.vaccinations FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "users_manage_own_offline_sync" ON public.offline_sync FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Doctor notes policies (doctors can read/write, patients can read their own)
CREATE POLICY "doctors_manage_own_notes" ON public.doctor_notes FOR ALL TO authenticated USING (doctor_id = auth.uid()) WITH CHECK (doctor_id = auth.uid());
CREATE POLICY "patients_read_own_notes" ON public.doctor_notes FOR SELECT TO authenticated USING (patient_id = auth.uid());

-- Secure shares policies
CREATE POLICY "users_manage_own_shares" ON public.secure_shares FOR ALL TO authenticated USING (shared_by = auth.uid()) WITH CHECK (shared_by = auth.uid());

-- 16. TRIGGERS FOR NEW TABLES
CREATE TRIGGER update_doctor_profiles_updated_at
    BEFORE UPDATE ON public.doctor_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_qr_codes_updated_at
    BEFORE UPDATE ON public.qr_codes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at
    BEFORE UPDATE ON public.reminders
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_timeline_events_updated_at
    BEFORE UPDATE ON public.timeline_events
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_doctor_notes_updated_at
    BEFORE UPDATE ON public.doctor_notes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_health_insurance_updated_at
    BEFORE UPDATE ON public.health_insurance
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_medical_documents_enhanced_updated_at
    BEFORE UPDATE ON public.medical_documents_enhanced
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_vaccinations_updated_at
    BEFORE UPDATE ON public.vaccinations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();