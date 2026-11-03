-- ============================================================
-- Migration: 20261002000007_webrtc_calling.sql
-- Application: Telora (com.rlstudio.telora)
-- Description: Hardened WebRTC voice/video calling signaling, strict participant
--              validation, lifecycle state enforcement, connection & block gating,
--              ephemeral signal cleanup, and least-privilege EXECUTE grants.
-- ============================================================

-- 1. Create call_signals table for secure WebRTC signaling exchange
CREATE TABLE IF NOT EXISTS public.call_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL REFERENCES public.calls(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT check_signal_type CHECK (
        type IN ('offer', 'answer', 'iceCandidate', 'hangup', 'busy', 'reject', 'ringing')
    ),
    CONSTRAINT check_signal_not_self CHECK (sender_id <> receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_call_signals_call_id ON public.call_signals (call_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_call_signals_receiver ON public.call_signals (receiver_id);
CREATE INDEX IF NOT EXISTS idx_call_signals_sender ON public.call_signals (sender_id);

COMMENT ON TABLE public.call_signals IS 'Ephemeral WebRTC signaling exchange table for offer, answer, and ICE candidates.';

-- 2. Master authorization function for calls: can_access_call
CREATE OR REPLACE FUNCTION public.can_access_call(
    p_call_id UUID,
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
    v_rec_caller_id UUID;
    v_rec_receiver_id UUID;
BEGIN
    v_caller_id := auth.uid();

    -- Explicitly deny unauthenticated or null callers
    IF v_caller_id IS NULL OR p_user_id IS NULL OR p_call_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Caller can only evaluate their own access
    IF p_user_id <> v_caller_id THEN
        RETURN FALSE;
    END IF;

    SELECT caller_id, receiver_id INTO v_rec_caller_id, v_rec_receiver_id
    FROM public.calls
    WHERE id = p_call_id;

    IF v_rec_caller_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- User must be a participant in the call
    IF v_caller_id <> v_rec_caller_id AND v_caller_id <> v_rec_receiver_id THEN
        RETURN FALSE;
    END IF;

    -- Block check: if either user blocked the other, deny
    IF public.is_blocked_relationship(v_rec_caller_id, v_rec_receiver_id) THEN
        RETURN FALSE;
    END IF;

    -- Connection check: must have accepted connection
    IF NOT EXISTS (
        SELECT 1 FROM public.user_connections
        WHERE status = 'accepted'
          AND (
            (requester_id = v_rec_caller_id AND receiver_id = v_rec_receiver_id)
            OR (requester_id = v_rec_receiver_id AND receiver_id = v_rec_caller_id)
          )
    ) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.can_access_call IS 'Evaluates call access enforcing authentication, participant match, active connection status, and block rules.';

-- 3. Dedicated Signal Insertion Authorization Function
--    Strictly validates:
--    a) Sender is authenticated user (auth.uid()).
--    b) Receiver is exactly the counterparty in that specific call.
--    c) Call is in an active signaling state (initiated, ringing, accepted, connected).
--    d) Neither user has blocked the other.
--    e) Active accepted connection exists.
CREATE OR REPLACE FUNCTION public.can_signal_in_call(
    p_call_id UUID,
    p_sender_id UUID,
    p_receiver_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
    v_call_caller_id UUID;
    v_call_receiver_id UUID;
    v_call_status TEXT;
BEGIN
    v_caller_id := auth.uid();

    -- 1. Explicitly deny unauthenticated or null callers
    IF v_caller_id IS NULL OR p_call_id IS NULL OR p_sender_id IS NULL OR p_receiver_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 2. sender_id must be the authenticated user
    IF p_sender_id <> v_caller_id THEN
        RETURN FALSE;
    END IF;

    -- 3. Cannot signal yourself
    IF p_sender_id = p_receiver_id THEN
        RETURN FALSE;
    END IF;

    -- 4. Retrieve call metadata
    SELECT caller_id, receiver_id, status
    INTO v_call_caller_id, v_call_receiver_id, v_call_status
    FROM public.calls
    WHERE id = p_call_id;

    IF v_call_caller_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 5. Lifecycle state check: Only active calls can accept signals.
    -- Terminated states (ended, rejected, cancelled, missed, busy, failed) MUST be rejected.
    IF v_call_status NOT IN ('initiated', 'ringing', 'accepted', 'connected') THEN
        RETURN FALSE;
    END IF;

    -- 6. Strict participant pair check:
    -- If sender is call's caller_id, receiver MUST be call's receiver_id.
    -- If sender is call's receiver_id, receiver MUST be call's caller_id.
    IF NOT (
        (p_sender_id = v_call_caller_id AND p_receiver_id = v_call_receiver_id)
        OR (p_sender_id = v_call_receiver_id AND p_receiver_id = v_call_caller_id)
    ) THEN
        RETURN FALSE;
    END IF;

    -- 7. Bidirectional block check: If either user blocked the other, deny
    IF public.is_blocked_relationship(v_call_caller_id, v_call_receiver_id) THEN
        RETURN FALSE;
    END IF;

    -- 8. Active connection check: Must currently have an accepted connection
    IF NOT EXISTS (
        SELECT 1 FROM public.user_connections
        WHERE status = 'accepted'
          AND (
            (requester_id = v_call_caller_id AND receiver_id = v_call_receiver_id)
            OR (requester_id = v_call_receiver_id AND receiver_id = v_call_caller_id)
          )
    ) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.can_signal_in_call IS 'Authorizes signaling insert: sender must be auth.uid(), receiver must be exact counterparty, call must be active, connection accepted, zero blocking.';

-- 4. Dedicated Signal Read Authorization Function
--    Ensures that ONLY the two participants in that call can select/receive signals,
--    and only while the call is in an active signaling state.
CREATE OR REPLACE FUNCTION public.can_read_call_signals(
    p_call_id UUID,
    p_sender_id UUID,
    p_receiver_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
    v_call_caller_id UUID;
    v_call_receiver_id UUID;
    v_call_status TEXT;
BEGIN
    v_caller_id := auth.uid();

    -- 1. Explicitly deny unauthenticated or null callers
    IF v_caller_id IS NULL OR p_call_id IS NULL OR p_sender_id IS NULL OR p_receiver_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 2. Reader must be one of the two signal participants
    IF v_caller_id <> p_sender_id AND v_caller_id <> p_receiver_id THEN
        RETURN FALSE;
    END IF;

    -- 3. Retrieve call record
    SELECT caller_id, receiver_id, status
    INTO v_call_caller_id, v_call_receiver_id, v_call_status
    FROM public.calls
    WHERE id = p_call_id;

    IF v_call_caller_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- 4. Lifecycle state check: signals can only be read/streamed for active calls
    IF v_call_status NOT IN ('initiated', 'ringing', 'accepted', 'connected') THEN
        RETURN FALSE;
    END IF;

    -- 5. Participant pair check: sender and receiver must match the call's participant pair
    IF NOT (
        (p_sender_id = v_call_caller_id AND p_receiver_id = v_call_receiver_id)
        OR (p_sender_id = v_call_receiver_id AND p_receiver_id = v_call_caller_id)
    ) THEN
        RETURN FALSE;
    END IF;

    -- 6. Blocking check
    IF public.is_blocked_relationship(v_call_caller_id, v_call_receiver_id) THEN
        RETURN FALSE;
    END IF;

    -- 7. Active connection check
    IF NOT EXISTS (
        SELECT 1 FROM public.user_connections
        WHERE status = 'accepted'
          AND (
            (requester_id = v_call_caller_id AND receiver_id = v_call_receiver_id)
            OR (requester_id = v_call_receiver_id AND receiver_id = v_call_caller_id)
          )
    ) THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.can_read_call_signals IS 'Authorizes signaling read/stream: reader must be a signal participant, call must be active, connection accepted, zero blocking.';

-- 5. Hardened RLS on public.calls
ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;

-- Call History SELECT policy:
-- Call logs remain visible to participants for audit history even after connection removal,
-- BUT are strictly hidden if either participant blocks the other.
DROP POLICY IF EXISTS calls_select_participants ON public.calls;
CREATE POLICY calls_select_participants ON public.calls
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND (caller_id = auth.uid() OR receiver_id = auth.uid())
    AND NOT public.is_blocked_relationship(caller_id, receiver_id)
);

-- Call Initiation INSERT policy:
-- Requires accepted connection and non-blocked relationship.
DROP POLICY IF EXISTS calls_insert_caller ON public.calls;
CREATE POLICY calls_insert_caller ON public.calls
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL
    AND caller_id = auth.uid()
    AND receiver_id <> auth.uid()
    AND status = 'initiated'
    AND NOT public.is_blocked_relationship(caller_id, receiver_id)
    AND EXISTS (
        SELECT 1 FROM public.user_connections
        WHERE status = 'accepted'
          AND (
            (requester_id = caller_id AND receiver_id = calls.receiver_id)
            OR (requester_id = calls.receiver_id AND receiver_id = caller_id)
          )
    )
);

-- Call Update UPDATE policy:
-- Participants can update their own call status (e.g. to connected or ended)
DROP POLICY IF EXISTS calls_update_participants ON public.calls;
CREATE POLICY calls_update_participants ON public.calls
FOR UPDATE TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND (caller_id = auth.uid() OR receiver_id = auth.uid())
    AND NOT public.is_blocked_relationship(caller_id, receiver_id)
)
WITH CHECK (
    auth.uid() IS NOT NULL
    AND (caller_id = auth.uid() OR receiver_id = auth.uid())
    AND NOT public.is_blocked_relationship(caller_id, receiver_id)
);

-- 6. Hardened RLS on public.call_signals
ALTER TABLE public.call_signals ENABLE ROW LEVEL SECURITY;

-- Drop any lingering update/delete policies
DROP POLICY IF EXISTS call_signals_update_participants ON public.call_signals;
DROP POLICY IF EXISTS call_signals_delete_participants ON public.call_signals;

-- SELECT: Only active call participants can read signals
DROP POLICY IF EXISTS call_signals_select_participants ON public.call_signals;
CREATE POLICY call_signals_select_participants ON public.call_signals
FOR SELECT TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND (sender_id = auth.uid() OR receiver_id = auth.uid())
    AND public.can_read_call_signals(call_signals.call_id, call_signals.sender_id, call_signals.receiver_id)
);

-- INSERT: Sender must be auth.uid(), receiver must be exact counterparty, call active
DROP POLICY IF EXISTS call_signals_insert_participants ON public.call_signals;
CREATE POLICY call_signals_insert_participants ON public.call_signals
FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL
    AND sender_id = auth.uid()
    AND receiver_id <> auth.uid()
    AND public.can_signal_in_call(call_id, sender_id, receiver_id)
);

-- 7. Database-level BEFORE INSERT Trigger on public.call_signals (Defense-in-depth)
CREATE OR REPLACE FUNCTION public.validate_call_signal_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_call_caller_id UUID;
    v_call_receiver_id UUID;
    v_call_status TEXT;
BEGIN
    IF NEW.sender_id IS NULL OR NEW.receiver_id IS NULL OR NEW.sender_id = NEW.receiver_id THEN
        RAISE EXCEPTION 'Invalid signal sender or receiver';
    END IF;

    -- Fetch call info
    SELECT caller_id, receiver_id, status
    INTO v_call_caller_id, v_call_receiver_id, v_call_status
    FROM public.calls
    WHERE id = NEW.call_id;

    IF v_call_caller_id IS NULL THEN
        RAISE EXCEPTION 'Call record % not found', NEW.call_id;
    END IF;

    -- Lifecycle check: Terminated calls cannot accept signals
    IF v_call_status IN ('ended', 'rejected', 'cancelled', 'missed', 'busy', 'failed') THEN
        RAISE EXCEPTION 'Cannot send signal to a terminated call (status: %)', v_call_status;
    END IF;

    -- Participant pair check: receiver_id must be the exact other participant
    IF NOT (
        (NEW.sender_id = v_call_caller_id AND NEW.receiver_id = v_call_receiver_id)
        OR (NEW.sender_id = v_call_receiver_id AND NEW.receiver_id = v_call_caller_id)
    ) THEN
        RAISE EXCEPTION 'Signal receiver (%) does not match call counterparty', NEW.receiver_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_call_signal ON public.call_signals;
CREATE TRIGGER trg_validate_call_signal
BEFORE INSERT ON public.call_signals
FOR EACH ROW
EXECUTE FUNCTION public.validate_call_signal_before_insert();

-- 8. Automatic call duration and timestamp management trigger
CREATE OR REPLACE FUNCTION public.handle_call_status_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Set started_at on initiation
    IF NEW.status = 'initiated' AND NEW.started_at IS NULL THEN
        NEW.started_at := now();
    END IF;

    -- Set connected_at when accepted / connected
    IF NEW.status = 'connected' AND OLD.status <> 'connected' AND NEW.connected_at IS NULL THEN
        NEW.connected_at := now();
    END IF;

    -- Set ended_at when transitioning to a terminated state
    IF NEW.status IN ('ended', 'rejected', 'cancelled', 'missed', 'busy', 'failed')
       AND OLD.status NOT IN ('ended', 'rejected', 'cancelled', 'missed', 'busy', 'failed') THEN
        IF NEW.ended_at IS NULL THEN
            NEW.ended_at := now();
        END IF;

        -- Calculate duration if connected_at was set
        IF NEW.connected_at IS NOT NULL THEN
            NEW.duration_seconds := GREATEST(0, EXTRACT(EPOCH FROM (NEW.ended_at - NEW.connected_at))::INTEGER);
        ELSE
            NEW.duration_seconds := 0;
        END IF;

        -- Automatically clean up ephemeral call signals for terminated calls
        DELETE FROM public.call_signals WHERE call_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_call_status_update ON public.calls;
CREATE TRIGGER trg_handle_call_status_update
BEFORE UPDATE ON public.calls
FOR EACH ROW
EXECUTE FUNCTION public.handle_call_status_update();

-- 9. Cascade Triggers to Terminate Active Calls on Connection Deletion or Block
CREATE OR REPLACE FUNCTION public.handle_call_connection_removed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    UPDATE public.calls
    SET status = 'cancelled',
        ended_at = now()
    WHERE status IN ('initiated', 'ringing', 'accepted', 'connected')
      AND (
        (caller_id = OLD.requester_id AND receiver_id = OLD.receiver_id)
        OR (caller_id = OLD.receiver_id AND receiver_id = OLD.requester_id)
      );
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_call_connection_removed ON public.user_connections;
CREATE TRIGGER trg_handle_call_connection_removed
AFTER DELETE ON public.user_connections
FOR EACH ROW
EXECUTE FUNCTION public.handle_call_connection_removed();

CREATE OR REPLACE FUNCTION public.handle_call_user_blocked()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    UPDATE public.calls
    SET status = 'cancelled',
        ended_at = now()
    WHERE status IN ('initiated', 'ringing', 'accepted', 'connected')
      AND (
        (caller_id = NEW.blocker_id AND receiver_id = NEW.blocked_id)
        OR (caller_id = NEW.blocked_id AND receiver_id = NEW.blocker_id)
      );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_call_user_blocked ON public.blocked_users;
CREATE TRIGGER trg_handle_call_user_blocked
AFTER INSERT ON public.blocked_users
FOR EACH ROW
EXECUTE FUNCTION public.handle_call_user_blocked();

-- 10. Secure RPC to initiate a call with full server-side validation
CREATE OR REPLACE FUNCTION public.initiate_call(
    p_receiver_id UUID,
    p_call_type TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_caller_id UUID;
    v_call_id UUID;
    v_is_connected BOOLEAN;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF v_caller_id = p_receiver_id THEN
        RAISE EXCEPTION 'Cannot call yourself';
    END IF;

    IF p_call_type NOT IN ('voice', 'video') THEN
        RAISE EXCEPTION 'Invalid call type';
    END IF;

    -- Check blocking in either direction
    IF public.is_blocked_relationship(v_caller_id, p_receiver_id) THEN
        RAISE EXCEPTION 'Unable to call this user';
    END IF;

    -- Check active connection
    SELECT EXISTS (
        SELECT 1 FROM public.user_connections
        WHERE status = 'accepted'
          AND (
            (requester_id = v_caller_id AND receiver_id = p_receiver_id)
            OR (requester_id = p_receiver_id AND receiver_id = v_caller_id)
          )
    ) INTO v_is_connected;

    IF NOT v_is_connected THEN
        RAISE EXCEPTION 'You must be connected with this user to call them';
    END IF;

    -- Check if receiver is currently in an active call
    IF EXISTS (
        SELECT 1 FROM public.calls
        WHERE (caller_id = p_receiver_id OR receiver_id = p_receiver_id)
          AND status IN ('initiated', 'ringing', 'accepted', 'connected')
    ) THEN
        RAISE EXCEPTION 'User is currently on another call';
    END IF;

    -- Insert call record
    INSERT INTO public.calls (caller_id, receiver_id, call_type, status, started_at)
    VALUES (v_caller_id, p_receiver_id, p_call_type, 'initiated', now())
    RETURNING id INTO v_call_id;

    RETURN v_call_id;
END;
$$;

COMMENT ON FUNCTION public.initiate_call IS 'Server-validated RPC to initiate a voice or video call between accepted connections.';

-- 11. Add tables to Supabase Realtime publication
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
    EXCEPTION WHEN duplicate_object THEN
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.call_signals;
    EXCEPTION WHEN duplicate_object THEN
    END;
END;
$$;

-- 12. Least-Privilege EXECUTE Grants
REVOKE ALL ON FUNCTION public.can_access_call(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_access_call(UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.can_signal_in_call(UUID, UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_signal_in_call(UUID, UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.can_read_call_signals(UUID, UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_read_call_signals(UUID, UUID, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.initiate_call(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.initiate_call(UUID, TEXT) TO authenticated;

-- Internal trigger functions: revoked from client roles
REVOKE ALL ON FUNCTION public.validate_call_signal_before_insert() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_call_status_update() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_call_connection_removed() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_call_user_blocked() FROM PUBLIC, anon, authenticated;
