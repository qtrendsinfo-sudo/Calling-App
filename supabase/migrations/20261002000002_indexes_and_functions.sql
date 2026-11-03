-- ============================================================
-- Migration: 20261002000002_indexes_and_functions.sql
-- Application: Telora (com.rlstudio.telora)
-- Description: Indexes, automated triggers, profile bootstrapping & conversation helpers.
-- ============================================================

-- ============================================================
-- 1. PERFORMANCE INDEXES
-- ============================================================

-- Profiles Indexes
CREATE INDEX IF NOT EXISTS idx_profiles_username_lower ON public.profiles (lower(username));
CREATE INDEX IF NOT EXISTS idx_profiles_username_trgm ON public.profiles USING gin (username gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_profiles_display_name_trgm ON public.profiles USING gin (display_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_profiles_last_seen ON public.profiles (last_seen DESC);

-- User Connections Indexes
CREATE INDEX IF NOT EXISTS idx_connections_requester ON public.user_connections (requester_id, status);
CREATE INDEX IF NOT EXISTS idx_connections_receiver ON public.user_connections (receiver_id, status);

-- Blocked Users Indexes
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON public.blocked_users (blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON public.blocked_users (blocked_id);

-- Conversations Indexes
CREATE INDEX IF NOT EXISTS idx_conversations_user_a ON public.conversations (user_a) WHERE user_a IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_user_b ON public.conversations (user_b) WHERE user_b IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON public.conversations (updated_at DESC);

-- Conversation Members Indexes
CREATE INDEX IF NOT EXISTS idx_conversation_members_user ON public.conversation_members (user_id, conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation ON public.conversation_members (conversation_id);

-- Messages Indexes (Optimized for chronological and cursor pagination)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON public.messages (conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages (sender_id);

-- Calls Indexes (Optimized for Call History queries)
CREATE INDEX IF NOT EXISTS idx_calls_caller ON public.calls (caller_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_receiver ON public.calls (receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_status ON public.calls (status);

-- Notifications Indexes (Optimized for unread counts and recent alerts)
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications (user_id, is_read, created_at DESC);

-- Device Tokens Indexes
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_tokens (user_id);

-- Reports Indexes
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user ON public.reports (reported_user_id);


-- ============================================================
-- 2. REUSABLE UPDATED_AT TRIGGER FUNCTION
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger across all mutable entities
DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON public.profiles;
CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_user_connections_updated_at ON public.user_connections;
CREATE TRIGGER trigger_user_connections_updated_at
    BEFORE UPDATE ON public.user_connections
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_conversations_updated_at ON public.conversations;
CREATE TRIGGER trigger_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_device_tokens_updated_at ON public.device_tokens;
CREATE TRIGGER trigger_device_tokens_updated_at
    BEFORE UPDATE ON public.device_tokens
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER trigger_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- 3. SAFE AUTOMATIC PROFILE & SETTINGS BOOTSTRAPPING
-- Triggered immediately when a new user signs up in auth.users
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_raw_username TEXT;
    v_clean_username TEXT;
    v_display_name TEXT;
    v_attempt INTEGER := 0;
    v_inserted BOOLEAN := false;
BEGIN
    -- Extract desired username or generate fallback based on auth id
    v_raw_username := NEW.raw_user_meta_data->>'username';
    v_display_name := COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''), 'User');

    -- Sanitize username: lowercase, remove invalid chars
    IF v_raw_username IS NOT NULL AND trim(v_raw_username) <> '' THEN
        v_clean_username := lower(regexp_replace(trim(v_raw_username), '[^a-zA-Z0-9_]', '', 'g'));
        IF char_length(v_clean_username) < 3 THEN
            v_clean_username := 'user_' || substr(replace(NEW.id::text, '-', ''), 1, 8);
        END IF;
    ELSE
        v_clean_username := 'user_' || substr(replace(NEW.id::text, '-', ''), 1, 8);
    END IF;

    -- Collision-safe insert loop
    WHILE NOT v_inserted AND v_attempt < 5 LOOP
        BEGIN
            INSERT INTO public.profiles (
                id,
                username,
                display_name,
                avatar_url,
                bio,
                is_online,
                last_seen,
                created_at,
                updated_at
            ) VALUES (
                NEW.id,
                CASE WHEN v_attempt = 0 THEN v_clean_username ELSE v_clean_username || '_' || v_attempt END,
                v_display_name,
                NEW.raw_user_meta_data->>'avatar_url',
                NEW.raw_user_meta_data->>'bio',
                false,
                now(),
                now(),
                now()
            );
            v_inserted := true;
        EXCEPTION WHEN unique_violation THEN
            v_attempt := v_attempt + 1;
        END;
    END LOOP;

    -- Insert default user privacy settings
    INSERT INTO public.user_settings (
        user_id,
        show_last_seen,
        show_online_status,
        allow_messages,
        allow_calls,
        notifications_enabled,
        updated_at
    ) VALUES (
        NEW.id,
        true,
        true,
        true,
        true,
        true,
        now()
    ) ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Bind trigger to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- 4. ATOMIC DIRECT CONVERSATION CREATOR
-- Enforces zero duplicate direct conversations at the database level
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_or_create_direct_conversation(
    p_user_1 UUID,
    p_user_2 UUID
)
RETURNS UUID
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_a UUID;
    v_user_b UUID;
    v_conversation_id UUID;
BEGIN
    IF p_user_1 = p_user_2 THEN
        RAISE EXCEPTION 'Cannot start a direct conversation with yourself';
    END IF;

    -- Canonical order to match check constraint: user_a < user_b
    IF p_user_1 < p_user_2 THEN
        v_user_a := p_user_1;
        v_user_b := p_user_2;
    ELSE
        v_user_a := p_user_2;
        v_user_b := p_user_1;
    END IF;

    -- Check if direct conversation already exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE type = 'direct'
      AND user_a = v_user_a
      AND user_b = v_user_b
    LIMIT 1;

    -- If found, return existing id
    IF v_conversation_id IS NOT NULL THEN
        RETURN v_conversation_id;
    END IF;

    -- Otherwise create new conversation and memberships atomically
    INSERT INTO public.conversations (type, user_a, user_b)
    VALUES ('direct', v_user_a, v_user_b)
    RETURNING id INTO v_conversation_id;

    -- Add both participants to conversation_members
    INSERT INTO public.conversation_members (conversation_id, user_id)
    VALUES 
        (v_conversation_id, v_user_a),
        (v_conversation_id, v_user_b)
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql;
