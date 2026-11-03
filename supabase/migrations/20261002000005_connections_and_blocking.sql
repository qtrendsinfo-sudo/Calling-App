-- ============================================================
-- Migration: 20261002000005_connections_and_blocking.sql
-- Application: Telora (com.rlstudio.telora)
-- Description: Bidirectional uniqueness constraint, block cascade cleanup trigger,
--              and secure connection relationship helpers.
-- ============================================================

-- 1. Ensure bidirectional uniqueness so duplicate requests in opposite directions are prohibited
CREATE UNIQUE INDEX IF NOT EXISTS unique_connection_pair_bidirectional 
ON public.user_connections (LEAST(requester_id, receiver_id), GREATEST(requester_id, receiver_id));

-- 2. Trigger on blocked_users: Automatically purge any existing connection or pending request upon blocking
CREATE OR REPLACE FUNCTION public.handle_user_blocked()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Remove any connection or pending/cancelled request between the blocker and blocked user
    DELETE FROM public.user_connections
    WHERE (requester_id = NEW.blocker_id AND receiver_id = NEW.blocked_id)
       OR (requester_id = NEW.blocked_id AND receiver_id = NEW.blocker_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_user_blocked ON public.blocked_users;
CREATE TRIGGER trg_handle_user_blocked
AFTER INSERT ON public.blocked_users
FOR EACH ROW
EXECUTE FUNCTION public.handle_user_blocked();

-- 3. Relationship status helper for profile views
CREATE OR REPLACE FUNCTION public.get_relationship_status(
    p_target_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_status TEXT;
    v_requester_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL OR p_target_user_id IS NULL OR v_user_id = p_target_user_id THEN
        RETURN 'self';
    END IF;

    -- Check if current user blocked target
    IF EXISTS (SELECT 1 FROM public.blocked_users WHERE blocker_id = v_user_id AND blocked_id = p_target_user_id) THEN
        RETURN 'blocked_by_me';
    END IF;

    -- Check if target blocked current user
    IF EXISTS (SELECT 1 FROM public.blocked_users WHERE blocker_id = p_target_user_id AND blocked_id = v_user_id) THEN
        RETURN 'blocked_by_them';
    END IF;

    -- Check existing connection record
    SELECT status, requester_id INTO v_status, v_requester_id
    FROM public.user_connections
    WHERE (requester_id = v_user_id AND receiver_id = p_target_user_id)
       OR (requester_id = p_target_user_id AND receiver_id = v_user_id)
    LIMIT 1;

    IF v_status = 'accepted' THEN
        RETURN 'connected';
    ELSIF v_status = 'pending' THEN
        IF v_requester_id = v_user_id THEN
            RETURN 'pending_sent';
        ELSE
            RETURN 'pending_received';
        END IF;
    END IF;

    RETURN 'none';
END;
$$;

COMMENT ON FUNCTION public.get_relationship_status IS 'Returns relationship state between authenticated user and target user.';
