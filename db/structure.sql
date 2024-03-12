SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: create_refresh_tokens_table_range_partition(text, timestamp without time zone, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.create_refresh_tokens_table_range_partition(IN p_partition_interval text, IN p_from timestamp without time zone, IN p_to timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
  DECLARE
    partition_time TIMESTAMP;
    table_range_partition_name TEXT;
    index_name TEXT;
    interval_name TEXT;
  BEGIN
    SELECT UPPER(SUBSTRING(p_partition_interval, '[a-zA-Z]+')) INTO interval_name;

    FOR partition_time IN SELECT generate_series(DATE_TRUNC(interval_name, p_from),
                                                 DATE_TRUNC(interval_name, p_to),
                                                 p_partition_interval::INTERVAL)::TIMESTAMP
    LOOP
      table_range_partition_name := get_table_range_partition_name('refresh_tokens',
                                                                   p_partition_interval,
                                                                   partition_time);

      CALL create_table_range_partition('refresh_tokens',
                                        p_partition_interval,
                                        partition_time,
                                        partition_time);

      index_name := get_table_range_partition_name('inx_refresh_tokens_on_dev_usr_id_created_at',
                                                   interval_name::TEXT,
                                                   partition_time);
      -- maximum name length is 63 characters
      -- To create an index without locking out writes to the table
      -- CREATE INDEX CONCURRENTLY cannot be executed from a function
      EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I USING BTREE (user_id, created_at DESC)',
                      index_name,
                      table_range_partition_name);
    END LOOP;
  END;
$$;


--
-- Name: create_table_range_partition(text, text, timestamp without time zone, timestamp without time zone); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.create_table_range_partition(IN table_name text, IN p_partition_interval text, IN p_from timestamp without time zone, IN p_to timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
      DECLARE
        partition_interval INTERVAL;
        table_range_partition_name TEXT;
        partition_time TIMESTAMP;
      BEGIN

        SELECT CAST(p_partition_interval AS INTERVAL) INTO partition_interval;


        FOR partition_time IN SELECT generate_series(p_from, p_to, partition_interval)::TIMESTAMP LOOP

         table_range_partition_name := get_table_range_partition_name(table_name,
                                                                      p_partition_interval,
                                                                      partition_time);

         EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I
                         FOR VALUES FROM (%L) TO (%L);',
                         table_range_partition_name,
                         table_name,
                         partition_time,
                         partition_time + partition_interval);
       END LOOP;


      END;
$$;


--
-- Name: get_table_range_partition_name(text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_table_range_partition_name(table_name text, p_interval_name text, partition_time timestamp without time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
  DECLARE
    interval_name TEXT;
    p_interval_frmt TEXT;
  BEGIN
    SELECT UPPER(SUBSTRING(p_interval_name, '[a-zA-Z]+')) INTO interval_name;

    CASE
    WHEN interval_name = 'HOUR' OR interval_name = 'HOURS' THEN
      SELECT to_char(partition_time, 'YYYYMMDD_HH24MISS') INTO p_interval_frmt;

      return format('%s_p%s', table_name, p_interval_frmt);
    WHEN interval_name = 'MINUTE' OR interval_name = 'MINUTES' THEN
      SELECT to_char(partition_time, 'YYYYMMDD_HH24MISS') INTO p_interval_frmt;

      return format('%s_p%s', table_name, p_interval_frmt);
    WHEN interval_name = 'SECOND' OR interval_name = 'SECONDS' THEN
      SELECT to_char(partition_time, 'YYYYMMDD_HH24MISS') INTO p_interval_frmt;

      return format('%s_p%s', table_name, p_interval_frmt);
    ELSE
      SELECT to_char(partition_time, 'YYYYMMDD') INTO p_interval_frmt;

      return format('%s_p%s', table_name, p_interval_frmt);
    END CASE;
  END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    user_id uuid,
    token text,
    device text,
    action text,
    reason text,
    expire_at timestamp without time zone,
    created_at timestamp without time zone
)
PARTITION BY RANGE (created_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: user_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_emails (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    email public.citext NOT NULL,
    validated boolean DEFAULT false,
    validated_otp boolean DEFAULT false,
    otp_tail character varying DEFAULT ''::character varying NOT NULL,
    otp_secret_key character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    password character varying,
    password_digest character varying,
    first_name character varying NOT NULL,
    last_name character varying,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: user_emails user_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_emails
    ADD CONSTRAINT user_emails_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_user_emails_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_emails_on_email ON public.user_emails USING btree (email);


--
-- Name: index_user_emails_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_emails_on_user_id ON public.user_emails USING btree (user_id);


--
-- Name: user_emails fk_rails_410ac92848; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_emails
    ADD CONSTRAINT fk_rails_410ac92848 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240301183409'),
('20240223160241'),
('20240223095201'),
('20240223084146'),
('20240218125826'),
('20240218124032'),
('20240218120326'),
('20240218120325');

