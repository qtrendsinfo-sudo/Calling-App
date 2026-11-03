-- ============================================================
-- Migration: 20261002000004_user_discovery.sql
-- Application: Telora (com.rlstudio.telora)
-- Description: Secure server-side user discovery function respecting privacy and blocking.
-- ============================================================

CREATE OR REPLACE FUNCTION public.search_users(
    p_query TEXT,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    is_online BOOLEAN,
    last_seen TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_clean_query TEXT;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    v_clean_query := trim(p_query);

    -- Do not execute heavy scan on empty queries
    IF v_clean_query = '' OR v_clean_query IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        v.id,
        v.username,
        v.display_name,
        v.avatar_url,
        v.bio,
        v.is_online,
        v.last_seen
    FROM public.user_profiles_secure v
    WHERE (
        v.username ILIKE '%' || v_clean_query || '%'
        OR v.display_name ILIKE '%' || v_clean_query || '%'
    )
    -- Exclude any blocked relationships (either User A blocked B, or B blocked A)
    AND NOT EXISTS (
        SELECT 1 FROM public.blocked_users b
        WHERE (b.blocker_id = v_user_id AND b.blocked_id = v.id)
           OR (b.blocker_id = v.id AND b.blocked_id = v_user_id)
    )
    ORDER BY 
        -- Exact username match ranks first
        CASE WHEN lower(v.username) = lower(v_clean_query) THEN 0 ELSE 1 END,
        -- Username prefix match ranks second
        CASE WHEN lower(v.username) LIKE lower(v_clean_query) || '%' THEN 0 ELSE 1 END,
        v.display_name ASC
    LIMIT LEAST(p_limit, 50)
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.search_users IS 'Secure server-side user search enforcing privacy masks from user_profiles_secure and excluding blocked relations.';
