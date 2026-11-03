-- ============================================================
-- Migration: 20261002000001_initial_schema.sql
-- Application: Telora (com.rlstudio.telora)
-- Description: Complete relational schema for Telora communications platform.
-- Notes: Does NOT include RLS policies (reserved for Phase 5).
-- ============================================================

-- Ensure uuid-ossp or pgcrypto extensions are available for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ------------------------------------------------------------
-- 1. PROFILES TABLE
-- 1:1 Identity reference to Supabase auth.users
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Username integrity constraints
    CONSTRAINT profiles_username_key UNIQUE (username),
    CONSTRAINT profiles_username_min_length CHECK (char_length(trim(username)) >= 3),
    CONSTRAINT profiles_username_max_length CHECK (char_length(username) <= 30),
    CONSTRAINT profiles_username_valid_chars CHECK (username ~* '^[a-z0-9_]+$'),
    CONSTRAINT profiles_username_not_empty CHECK (trim(username) <> ''),

    -- Display name integrity constraints
    CONSTRAINT profiles_display_name_length CHECK (char_length(trim(display_name)) >= 1 AND char_length(display_name) <= 50),
    CONSTRAINT profiles_display_name_not_empty CHECK (trim(display_name) <> ''),

    -- Bio length limit
    CONSTRAINT profiles_bio_length CHECK (bio IS NULL OR char_length(bio) <= 160)
);

COMMENT ON TABLE public.profiles IS 'Public user profiles linked to auth.users.';
COMMENT ON COLUMN public.profiles.username IS 'Unique, URL-safe lowercase username for user discovery.';
COMMENT ON COLUMN public.profiles.is_online IS 'Current presence state, maintained via Supabase Realtime Presence.';

-- ------------------------------------------------------------
-- 2. USER CONNECTIONS TABLE
-- Manages friendship / contact connection lifecycle
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_connection_not_self CHECK (requester_id <> receiver_id),
    CONSTRAINT check_connection_status_valid CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    CONSTRAINT unique_connection_pair UNIQUE (requester_id, receiver_id)
);

COMMENT ON TABLE public.user_connections IS 'Direct connection/friend requests between users.';

-- ------------------------------------------------------------
-- 3. BLOCKED USERS TABLE
-- Enforces safety, blocking calls, messages, and presence visibility
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_block_not_self CHECK (blocker_id <> blocked_id),
    CONSTRAINT unique_block_pair UNIQUE (blocker_id, blocked_id)
);

COMMENT ON TABLE public.blocked_users IS 'Users blocked from calling, messaging, or contacting the blocker.';

-- ------------------------------------------------------------
-- 4. CONVERSATIONS TABLE
-- Thread container supporting 1-to-1 direct and future group chats
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL DEFAULT 'direct',
    title TEXT,
    -- Canonical ordering for direct conversations to enforce database-level uniqueness
    user_a UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_b UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_conversation_type CHECK (type IN ('direct', 'group')),
    CONSTRAINT check_direct_conversation_users CHECK (
        (type = 'direct' AND user_a IS NOT NULL AND user_b IS NOT NULL AND user_a < user_b) OR
        (type = 'group' AND user_a IS NULL AND user_b IS NULL)
    ),
    CONSTRAINT unique_direct_conversation_pair UNIQUE (user_a, user_b)
);

COMMENT ON TABLE public.conversations IS 'Chat conversations container. Direct conversations strictly enforce unique user pairs.';

-- ------------------------------------------------------------
-- 5. CONVERSATION MEMBERS TABLE
-- Links users to conversation threads with read receipts
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversation_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_read_at TIMESTAMPTZ,

    CONSTRAINT unique_conversation_member UNIQUE (conversation_id, user_id)
);

COMMENT ON TABLE public.conversation_members IS 'Membership list and read-pointer for conversations.';

-- ------------------------------------------------------------
-- 6. MESSAGES TABLE
-- Chat messages supporting text and future media types with soft-delete
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    message_type TEXT NOT NULL DEFAULT 'text',
    content TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    edited_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,

    -- Constraints
    CONSTRAINT check_message_type CHECK (message_type IN ('text', 'image', 'voice', 'file', 'system')),
    CONSTRAINT check_message_content_or_deleted CHECK (
        deleted_at IS NOT NULL OR (content IS NOT NULL AND trim(content) <> '') OR message_type <> 'text'
    )
);

COMMENT ON TABLE public.messages IS 'Individual chat messages. Soft deleted via deleted_at.';

-- ------------------------------------------------------------
-- 7. CALLS TABLE
-- Persistent voice and video call records and status timeline
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    call_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'initiated',
    started_at TIMESTAMPTZ,
    connected_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_call_not_self CHECK (caller_id <> receiver_id),
    CONSTRAINT check_call_type CHECK (call_type IN ('voice', 'video')),
    CONSTRAINT check_call_status CHECK (status IN (
        'initiated', 'ringing', 'accepted', 'connecting',
        'connected', 'rejected', 'cancelled', 'missed',
        'busy', 'failed', 'ended'
    )),
    CONSTRAINT check_call_duration_positive CHECK (duration_seconds >= 0)
);

COMMENT ON TABLE public.calls IS 'Voice and video call log. Live media tracks flow peer-to-peer over WebRTC, not stored here.';

-- ------------------------------------------------------------
-- 8. NOTIFICATIONS TABLE
-- Push & in-app notification events
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_notification_type CHECK (type IN (
        'message', 'incoming_call', 'missed_call',
        'connection_request', 'connection_accepted', 'system'
    ))
);

COMMENT ON TABLE public.notifications IS 'In-app and push notification inbox for each user.';

-- ------------------------------------------------------------
-- 9. DEVICE TOKENS TABLE
-- Push notification tokens (FCM) supporting multi-device per user
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'android',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_device_token_platform CHECK (platform IN ('android', 'ios')),
    CONSTRAINT unique_user_device_token UNIQUE (user_id, token)
);

COMMENT ON TABLE public.device_tokens IS 'Registered FCM device tokens for push notification delivery.';

-- ------------------------------------------------------------
-- 10. USER SETTINGS TABLE
-- User privacy and communication preferences
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    show_last_seen BOOLEAN NOT NULL DEFAULT true,
    show_online_status BOOLEAN NOT NULL DEFAULT true,
    allow_messages BOOLEAN NOT NULL DEFAULT true,
    allow_calls BOOLEAN NOT NULL DEFAULT true,
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.user_settings IS 'User privacy and communication configuration.';

-- ------------------------------------------------------------
-- 11. REPORTS TABLE
-- Trust & Safety user moderation reports
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_report_not_self CHECK (reporter_id <> reported_user_id),
    CONSTRAINT check_report_category CHECK (category IN (
        'spam', 'harassment', 'fake_account', 'inappropriate_content', 'abuse', 'other'
    )),
    CONSTRAINT check_report_status CHECK (status IN (
        'pending', 'reviewing', 'resolved', 'dismissed'
    )),
    CONSTRAINT check_report_description_length CHECK (description IS NULL OR char_length(description) <= 1000)
);

COMMENT ON TABLE public.reports IS 'Abuse and moderation reports filed by users.';
