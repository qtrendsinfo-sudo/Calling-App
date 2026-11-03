-- ============================================================
-- Migration: 20261002000006_chat_messaging.sql
-- Application: Telora (com.rlstudio.telora)
-- Description: Security-hardened chat messaging with RLS enforcement of active
--              connection status, bidirectional block blocking, cascade cleanup,
--              explicit anonymous denial (auth.uid() IS NULL = FALSE),
--              and least-privilege EXECUTE grant restrictions.
-- ============================================================

-- 0. Drop legacy overloaded function signatures to prevent bypasses
DROP FUNCTION IF EXISTS public.get_or_create_direct_conversation(UUID, UUID);

-- 1. Hardened helper functions: protect against unauthorized parameter probing / relationship leakage
--    Explicitly denies unauthenticated (auth.uid() IS NULL) and third-party probes.
CREATE OR REPLACE FUNCTION public.is_blocked_relationship(
    p_user_a UUID,
    p_user_b UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
BEGIN
    v_caller_id := auth.uid();

    -- 1. Explicitly deny unauthenticated/anonymous callers
    IF v_caller_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 2. Prevent third-party probing: caller must be one of the two participants
    IF v_caller_id <> p_user_a AND v_caller_id <> p_user_b THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.blocked_users
        WHERE (blocker_id = p_user_a AND blocked_id = p_user_b)
           OR (blocker_id = p_user_b AND blocked_id = p_user_a)
    );
END;
$$;

COMMENT ON FUNCTION public.is_blocked_relationship IS 'Returns true if either user has blocked the other. Denies unauthenticated calls and third-party probing.';

CREATE OR REPLACE FUNCTION public.is_conversation_member(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
BEGIN
    v_caller_id := auth.uid();

    -- 1. Explicitly deny unauthenticated/anonymous callers
    IF v_caller_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 2. Prevent third-party probing: caller must be the user or already a verified member
    IF v_caller_id <> p_user_id THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.conversation_members
            WHERE conversation_id = p_conversation_id AND user_id = v_caller_id
        ) THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.conversation_members
        WHERE conversation_id = p_conversation_id
          AND user_id = p_user_id
    );
END;
$$;

COMMENT ON FUNCTION public.is_conversation_member IS 'Recursion-safe membership check with caller validation to prevent probing.';

-- 2. Master security function to check if a user can access or message in a conversation.
--    Enforces that for 1-to-1 direct conversations:
--    a) Caller must be authenticated (auth.uid() IS NOT NULL).
--    b) Caller must evaluate access only for themselves (p_user_id = auth.uid()).
--    c) Caller must be one of the two participants.
--    d) Neither user has blocked the other.
--    e) Both users must currently have an accepted connection in public.user_connections.
CREATE OR REPLACE FUNCTION public.can_access_conversation(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
    v_type TEXT;
    v_user_a UUID;
    v_user_b UUID;
BEGIN
    v_caller_id := auth.uid();

    -- 1. Explicitly deny unauthenticated/anonymous callers and null parameters
    IF v_caller_id IS NULL OR p_user_id IS NULL OR p_conversation_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 2. Prohibit third-party probing: p_user_id must match auth.uid()
    IF p_user_id <> v_caller_id THEN
        RETURN FALSE;
    END IF;

    SELECT type, user_a, user_b INTO v_type, v_user_a, v_user_b
    FROM public.conversations
    WHERE id = p_conversation_id;

    IF v_type IS NULL THEN
        RETURN FALSE;
    END IF;

    -- For 1-to-1 direct conversations:
    IF v_type = 'direct' THEN
        -- 3. Caller must be a direct participant
        IF v_caller_id <> v_user_a AND v_caller_id <> v_user_b THEN
            RETURN FALSE;
        END IF;

        -- 4. Enforce blocking: If either user blocked the other, deny all access
        IF public.is_blocked_relationship(v_user_a, v_user_b) THEN
            RETURN FALSE;
        END IF;

        -- 5. Enforce connection: Must have an active accepted connection in public.user_connections
        IF NOT EXISTS (
            SELECT 1 FROM public.user_connections
            WHERE status = 'accepted'
              AND (
                (requester_id = v_user_a AND receiver_id = v_user_b)
                OR (requester_id = v_user_b AND receiver_id = v_user_a)
              )
        ) THEN
            RETURN FALSE;
        END IF;
    ELSE
        -- For future group conversations, verify registered membership
        IF NOT public.is_conversation_member(p_conversation_id, v_caller_id) THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.can_access_conversation IS 'Validates conversation authorization enforcing authentication, membership, active connection status, and bidirectional block rules.';

CREATE OR REPLACE FUNCTION public.can_message_in_conversation(
    p_conversation_id UUID,
    p_sender_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    RETURN public.can_access_conversation(p_conversation_id, p_sender_id);
END;
$$;

-- 3. Hardened RLS Policies on public.conversations (SELECT, INSERT, UPDATE)
DROP POLICY IF EXISTS conversations_select_members ON public.conversations;
CREATE POLICY conversations_select_members ON public.conversations
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND public.can_access_conversation(conversations.id, auth.uid())
);

DROP POLICY IF EXISTS conversations_insert_authenticated ON public.conversations;
CREATE POLICY conversations_insert_authenticated ON public.conversations
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
        (type = 'direct'
         AND (user_a = auth.uid() OR user_b = auth.uid())
         AND user_a < user_b
         AND NOT public.is_blocked_relationship(user_a, user_b)
         AND EXISTS (
             SELECT 1 FROM public.user_connections
             WHERE status = 'accepted'
               AND (
                 (requester_id = user_a AND receiver_id = user_b)
                 OR (requester_id = user_b AND receiver_id = user_a)
               )
         )
        )
        OR (type = 'group')
    )
);

DROP POLICY IF EXISTS conversations_update_members ON public.conversations;
CREATE POLICY conversations_update_members ON public.conversations
FOR UPDATE TO authenticated
USING (public.can_access_conversation(conversations.id, auth.uid()))
WITH CHECK (public.can_access_conversation(conversations.id, auth.uid()));

-- 4. Hardened RLS Policies on public.conversation_members (SELECT, INSERT, UPDATE, DELETE)
DROP POLICY IF EXISTS conversation_members_select_members ON public.conversation_members;
CREATE POLICY conversation_members_select_members ON public.conversation_members
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND public.can_access_conversation(conversation_members.conversation_id, auth.uid())
);

DROP POLICY IF EXISTS conversation_members_insert_authorized ON public.conversation_members;
CREATE POLICY conversation_members_insert_authorized ON public.conversation_members
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL
    AND public.can_access_conversation(conversation_id, auth.uid())
);

DROP POLICY IF EXISTS conversation_members_update_own ON public.conversation_members;
CREATE POLICY conversation_members_update_own ON public.conversation_members
FOR UPDATE TO authenticated
USING (
    user_id = auth.uid()
    AND public.can_access_conversation(conversation_id, auth.uid())
)
WITH CHECK (
    user_id = auth.uid()
    AND public.can_access_conversation(conversation_id, auth.uid())
);

-- 5. Hardened RLS Policies on public.messages (SELECT, INSERT, UPDATE)
--    Supabase Realtime uses the SELECT policy to evaluate whether a message event can be delivered.
DROP POLICY IF EXISTS messages_select_conversation_members ON public.messages;
CREATE POLICY messages_select_conversation_members ON public.messages
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND public.can_access_conversation(messages.conversation_id, auth.uid())
);

DROP POLICY IF EXISTS messages_insert_conversation_members ON public.messages;
CREATE POLICY messages_insert_conversation_members ON public.messages
FOR INSERT TO authenticated
WITH CHECK (
    sender_id = auth.uid()
    AND public.can_access_conversation(conversation_id, auth.uid())
);

DROP POLICY IF EXISTS messages_update_own ON public.messages;
CREATE POLICY messages_update_own ON public.messages
FOR UPDATE TO authenticated
USING (
    sender_id = auth.uid()
    AND public.can_access_conversation(conversation_id, auth.uid())
)
WITH CHECK (
    sender_id = auth.uid()
    AND public.can_access_conversation(conversation_id, auth.uid())
);

-- 6. Cascade triggers to immediately delete conversations upon block or connection removal
CREATE OR REPLACE FUNCTION public.handle_connection_removed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    DELETE FROM public.conversations
    WHERE type = 'direct'
      AND user_a = LEAST(OLD.requester_id, OLD.receiver_id)
      AND user_b = GREATEST(OLD.requester_id, OLD.receiver_id);
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_connection_removed ON public.user_connections;
CREATE TRIGGER trg_handle_connection_removed
AFTER DELETE ON public.user_connections
FOR EACH ROW
EXECUTE FUNCTION public.handle_connection_removed();

CREATE OR REPLACE FUNCTION public.handle_user_blocked_chat()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    DELETE FROM public.conversations
    WHERE type = 'direct'
      AND user_a = LEAST(NEW.blocker_id, NEW.blocked_id)
      AND user_b = GREATEST(NEW.blocker_id, NEW.blocked_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_user_blocked_chat ON public.blocked_users;
CREATE TRIGGER trg_handle_user_blocked_chat
AFTER INSERT ON public.blocked_users
FOR EACH ROW
EXECUTE FUNCTION public.handle_user_blocked_chat();

-- 7. Automatic conversation updated_at trigger upon new message
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    UPDATE public.conversations
    SET updated_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_new_message ON public.messages;
CREATE TRIGGER trg_handle_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_message();

-- 8. Secure RPC to access or create a 1-to-1 direct conversation between connected users
CREATE OR REPLACE FUNCTION public.get_or_create_direct_conversation(
    p_recipient_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_user_a UUID;
    v_user_b UUID;
    v_conversation_id UUID;
    v_is_connected BOOLEAN;
BEGIN
    v_current_user_id := auth.uid();
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF v_current_user_id = p_recipient_user_id THEN
        RAISE EXCEPTION 'Cannot create conversation with yourself';
    END IF;

    -- Enforce blocking rule: blocked relationships cannot message
    IF public.is_blocked_relationship(v_current_user_id, p_recipient_user_id) THEN
        RAISE EXCEPTION 'Unable to communicate with this user';
    END IF;

    -- Enforce connection rule: must be accepted connections
    SELECT EXISTS (
        SELECT 1 FROM public.user_connections
        WHERE status = 'accepted'
          AND (
            (requester_id = v_current_user_id AND receiver_id = p_recipient_user_id)
            OR (requester_id = p_recipient_user_id AND receiver_id = v_current_user_id)
          )
    ) INTO v_is_connected;

    IF NOT v_is_connected THEN
        RAISE EXCEPTION 'You must be connected to start a conversation';
    END IF;

    -- Canonical ordering for direct conversations
    v_user_a := LEAST(v_current_user_id, p_recipient_user_id);
    v_user_b := GREATEST(v_current_user_id, p_recipient_user_id);

    -- Find existing conversation
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE user_a = v_user_a AND user_b = v_user_b
    LIMIT 1;

    -- Create if not present
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (type, user_a, user_b)
        VALUES ('direct', v_user_a, v_user_b)
        RETURNING id INTO v_conversation_id;

        -- Insert membership rows for both participants
        INSERT INTO public.conversation_members (conversation_id, user_id)
        VALUES 
            (v_conversation_id, v_user_a),
            (v_conversation_id, v_user_b)
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    ELSE
        -- Ensure membership rows exist
        INSERT INTO public.conversation_members (conversation_id, user_id)
        VALUES 
            (v_conversation_id, v_user_a),
            (v_conversation_id, v_user_b)
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN v_conversation_id;
END;
$$;

COMMENT ON FUNCTION public.get_or_create_direct_conversation IS 'Creates or retrieves an existing 1-on-1 direct conversation enforcing connection status and block checking.';

-- 9. Mark conversation messages as read for authenticated user
CREATE OR REPLACE FUNCTION public.mark_conversation_read(
    p_conversation_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL OR p_conversation_id IS NULL THEN
        RETURN;
    END IF;

    UPDATE public.conversation_members
    SET last_read_at = now()
    WHERE conversation_id = p_conversation_id
      AND user_id = v_caller_id;
END;
$$;

-- 10. LEAST-PRIVILEGE EXECUTE GRANTS
--     Revoke EXECUTE from PUBLIC and anon for all security helper functions.
--     Grant EXECUTE only to authenticated role where required by RLS expressions or RPCs.
REVOKE ALL ON FUNCTION public.is_blocked_relationship(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_blocked_relationship(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.is_conversation_member(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_conversation_member(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.can_access_conversation(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_access_conversation(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.can_message_in_conversation(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_message_in_conversation(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_or_create_direct_conversation(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_or_create_direct_conversation(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.mark_conversation_read(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_conversation_read(UUID) TO authenticated;

-- Trigger functions: Revoke from all client roles (executed internally by database engine)
REVOKE ALL ON FUNCTION public.handle_connection_removed() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_user_blocked_chat() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_message() FROM PUBLIC, anon, authenticated;

-- 11. Enable Supabase Realtime publication for chat tables
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    EXCEPTION WHEN duplicate_object THEN
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_members;
    EXCEPTION WHEN duplicate_object THEN
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
    EXCEPTION WHEN duplicate_object THEN
    END;
END;
$$;
