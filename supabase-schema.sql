--
-- TURFMAPP Schema for Supabase (Isolated Schema)
--
-- Schema: project_management_tool
-- This creates all TURFMAPP tables in a separate schema for isolation
--

-- Create the schema
CREATE SCHEMA IF NOT EXISTS project_management_tool;

-- Set search path for this session
SET search_path TO project_management_tool, public;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

COMMENT ON SCHEMA project_management_tool IS 'TURFMAPP project management tool tables';


--
-- Name: next_id(); Type: FUNCTION; Schema: project_management_tool; Owner: postgres
--

CREATE FUNCTION project_management_tool.next_id(OUT id bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
      DECLARE
        shard INT := 1;
        epoch BIGINT := 1567191600000;
        sequence BIGINT;
        milliseconds BIGINT;
      BEGIN
        SELECT nextval('project_management_tool.next_id_seq') % 1024 INTO sequence;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO milliseconds;
        id := (milliseconds - epoch) << 23;
        id := id | (shard << 10);
        id := id | (sequence);
      END;
    $$;


ALTER FUNCTION project_management_tool.next_id(OUT id bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.action (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    type text NOT NULL,
    data jsonb NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.action OWNER TO postgres;

--
-- Name: archive; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.archive (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    from_model text NOT NULL,
    original_record_id bigint NOT NULL,
    original_record json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.archive OWNER TO postgres;

--
-- Name: attachment; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.attachment (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    creator_user_id bigint NOT NULL,
    dirname text NOT NULL,
    filename text NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    image jsonb
);


ALTER TABLE project_management_tool.attachment OWNER TO postgres;

--
-- Name: board; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.board (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    project_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.board OWNER TO postgres;

--
-- Name: board_membership; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.board_membership (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    board_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    role text NOT NULL,
    can_comment boolean
);


ALTER TABLE project_management_tool.board_membership OWNER TO postgres;

--
-- Name: card; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.card (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    board_id bigint NOT NULL,
    list_id bigint NOT NULL,
    creator_user_id bigint NOT NULL,
    cover_attachment_id bigint,
    "position" double precision,
    name text NOT NULL,
    description text,
    due_date timestamp without time zone,
    stopwatch jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_due_date_completed boolean,
    estimated_hours character varying(255),
    actual_hours character varying(255),
    complexity character varying(255),
    priority character varying(255),
    percent_complete integer,
    is_blocked boolean DEFAULT false,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    CONSTRAINT card_complexity_check CHECK (((complexity)::text = ANY (ARRAY[('high'::character varying)::text, ('medium'::character varying)::text, ('low'::character varying)::text]))),
    CONSTRAINT card_percent_complete_check CHECK (((percent_complete >= 0) AND (percent_complete <= 100))),
    CONSTRAINT card_priority_check CHECK (((priority)::text = ANY (ARRAY[('urgent'::character varying)::text, ('high'::character varying)::text, ('medium'::character varying)::text, ('low'::character varying)::text])))
);


ALTER TABLE project_management_tool.card OWNER TO postgres;

--
-- Name: card_label; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.card_label (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    label_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.card_label OWNER TO postgres;

--
-- Name: card_membership; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.card_membership (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.card_membership OWNER TO postgres;

--
-- Name: card_subscription; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.card_subscription (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    is_permanent boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.card_subscription OWNER TO postgres;

--
-- Name: identity_provider_user; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.identity_provider_user (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    user_id bigint NOT NULL,
    issuer text NOT NULL,
    sub text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.identity_provider_user OWNER TO postgres;

--
-- Name: label; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.label (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    board_id bigint NOT NULL,
    name text,
    color text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" double precision NOT NULL
);


ALTER TABLE project_management_tool.label OWNER TO postgres;

--
-- Name: list; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.list (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    board_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.list OWNER TO postgres;

--
-- Name: migration; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.migration (
    id integer NOT NULL,
    name character varying(255),
    batch integer,
    migration_time timestamp with time zone
);


ALTER TABLE project_management_tool.migration OWNER TO postgres;

--
-- Name: migration_id_seq; Type: SEQUENCE; Schema: project_management_tool; Owner: postgres
--

CREATE SEQUENCE project_management_tool.migration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE project_management_tool.migration_id_seq OWNER TO postgres;

--
-- Name: migration_id_seq; Type: SEQUENCE OWNED BY; Schema: project_management_tool; Owner: postgres
--

ALTER SEQUENCE project_management_tool.migration_id_seq OWNED BY project_management_tool.migration.id;


--
-- Name: migration_lock; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.migration_lock (
    index integer NOT NULL,
    is_locked integer
);


ALTER TABLE project_management_tool.migration_lock OWNER TO postgres;

--
-- Name: migration_lock_index_seq; Type: SEQUENCE; Schema: project_management_tool; Owner: postgres
--

CREATE SEQUENCE project_management_tool.migration_lock_index_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE project_management_tool.migration_lock_index_seq OWNER TO postgres;

--
-- Name: migration_lock_index_seq; Type: SEQUENCE OWNED BY; Schema: project_management_tool; Owner: postgres
--

ALTER SEQUENCE project_management_tool.migration_lock_index_seq OWNED BY project_management_tool.migration_lock.index;


--
-- Name: next_id_seq; Type: SEQUENCE; Schema: project_management_tool; Owner: postgres
--

CREATE SEQUENCE project_management_tool.next_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE project_management_tool.next_id_seq OWNER TO postgres;

--
-- Name: notification; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.notification (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    user_id bigint NOT NULL,
    action_id bigint NOT NULL,
    card_id bigint NOT NULL,
    is_read boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.notification OWNER TO postgres;

--
-- Name: project; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.project (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    name text NOT NULL,
    background jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    background_image jsonb
);


ALTER TABLE project_management_tool.project OWNER TO postgres;

--
-- Name: project_manager; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.project_manager (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE project_management_tool.project_manager OWNER TO postgres;

--
-- Name: session; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.session (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    user_id bigint NOT NULL,
    access_token text NOT NULL,
    remote_address text NOT NULL,
    user_agent text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    http_only_token text
);


ALTER TABLE project_management_tool.session OWNER TO postgres;

--
-- Name: task; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.task (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    name text NOT NULL,
    is_completed boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "position" double precision NOT NULL
);


ALTER TABLE project_management_tool.task OWNER TO postgres;

--
-- Name: user_account; Type: TABLE; Schema: project_management_tool; Owner: postgres
--

CREATE TABLE project_management_tool.user_account (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    email text NOT NULL,
    password text,
    is_admin boolean NOT NULL,
    name text NOT NULL,
    username text,
    phone text,
    organization text,
    subscribe_to_own_cards boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    language text,
    password_changed_at timestamp without time zone,
    avatar jsonb,
    is_sso boolean NOT NULL
);


ALTER TABLE project_management_tool.user_account OWNER TO postgres;

--
-- Name: migration id; Type: DEFAULT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration ALTER COLUMN id SET DEFAULT nextval('project_management_tool.migration_id_seq'::regclass);


--
-- Name: migration_lock index; Type: DEFAULT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration_lock ALTER COLUMN index SET DEFAULT nextval('project_management_tool.migration_lock_index_seq'::regclass);


--
-- Name: action action_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.action
    ADD CONSTRAINT action_pkey PRIMARY KEY (id);


--
-- Name: archive archive_from_model_original_record_id_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.archive
    ADD CONSTRAINT archive_from_model_original_record_id_unique UNIQUE (from_model, original_record_id);


--
-- Name: archive archive_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.archive
    ADD CONSTRAINT archive_pkey PRIMARY KEY (id);


--
-- Name: attachment attachment_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.attachment
    ADD CONSTRAINT attachment_pkey PRIMARY KEY (id);


--
-- Name: board_membership board_membership_board_id_user_id_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.board_membership
    ADD CONSTRAINT board_membership_board_id_user_id_unique UNIQUE (board_id, user_id);


--
-- Name: board_membership board_membership_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.board_membership
    ADD CONSTRAINT board_membership_pkey PRIMARY KEY (id);


--
-- Name: board board_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.board
    ADD CONSTRAINT board_pkey PRIMARY KEY (id);


--
-- Name: card_label card_label_card_id_label_id_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_label
    ADD CONSTRAINT card_label_card_id_label_id_unique UNIQUE (card_id, label_id);


--
-- Name: card_label card_label_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_label
    ADD CONSTRAINT card_label_pkey PRIMARY KEY (id);


--
-- Name: card_membership card_membership_card_id_user_id_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_membership
    ADD CONSTRAINT card_membership_card_id_user_id_unique UNIQUE (card_id, user_id);


--
-- Name: card_membership card_membership_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_membership
    ADD CONSTRAINT card_membership_pkey PRIMARY KEY (id);


--
-- Name: card card_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card
    ADD CONSTRAINT card_pkey PRIMARY KEY (id);


--
-- Name: card_subscription card_subscription_card_id_user_id_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_subscription
    ADD CONSTRAINT card_subscription_card_id_user_id_unique UNIQUE (card_id, user_id);


--
-- Name: card_subscription card_subscription_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_subscription
    ADD CONSTRAINT card_subscription_pkey PRIMARY KEY (id);


--
-- Name: identity_provider_user identity_provider_user_issuer_sub_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.identity_provider_user
    ADD CONSTRAINT identity_provider_user_issuer_sub_unique UNIQUE (issuer, sub);


--
-- Name: identity_provider_user identity_provider_user_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.identity_provider_user
    ADD CONSTRAINT identity_provider_user_pkey PRIMARY KEY (id);


--
-- Name: label label_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.label
    ADD CONSTRAINT label_pkey PRIMARY KEY (id);


--
-- Name: list list_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.list
    ADD CONSTRAINT list_pkey PRIMARY KEY (id);


--
-- Name: migration_lock migration_lock_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration_lock
    ADD CONSTRAINT migration_lock_pkey PRIMARY KEY (index);


--
-- Name: migration migration_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration
    ADD CONSTRAINT migration_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: project_manager project_manager_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.project_manager
    ADD CONSTRAINT project_manager_pkey PRIMARY KEY (id);


--
-- Name: project_manager project_manager_project_id_user_id_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.project_manager
    ADD CONSTRAINT project_manager_project_id_user_id_unique UNIQUE (project_id, user_id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: session session_access_token_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.session
    ADD CONSTRAINT session_access_token_unique UNIQUE (access_token);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: user_account user_email_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.user_account
    ADD CONSTRAINT user_email_unique EXCLUDE USING btree (email WITH =) WHERE ((deleted_at IS NULL));


--
-- Name: user_account user_username_unique; Type: CONSTRAINT; Schema: project_management_tool; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.user_account
    ADD CONSTRAINT user_username_unique EXCLUDE USING btree (username WITH =) WHERE (((username IS NOT NULL) AND (deleted_at IS NULL)));


--
-- Name: action_card_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX action_card_id_index ON project_management_tool.action USING btree (card_id);


--
-- Name: action_type_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX action_type_index ON project_management_tool.action USING btree (type);


--
-- Name: attachment_card_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX attachment_card_id_index ON project_management_tool.attachment USING btree (card_id);


--
-- Name: board_membership_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX board_membership_user_id_index ON project_management_tool.board_membership USING btree (user_id);


--
-- Name: board_position_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX board_position_index ON project_management_tool.board USING btree ("position");


--
-- Name: board_project_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX board_project_id_index ON project_management_tool.board USING btree (project_id);


--
-- Name: card_board_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX card_board_id_index ON project_management_tool.card USING btree (board_id);


--
-- Name: card_label_label_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX card_label_label_id_index ON project_management_tool.card_label USING btree (label_id);


--
-- Name: card_list_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX card_list_id_index ON project_management_tool.card USING btree (list_id);


--
-- Name: card_membership_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX card_membership_user_id_index ON project_management_tool.card_membership USING btree (user_id);


--
-- Name: card_position_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX card_position_index ON project_management_tool.card USING btree ("position");


--
-- Name: card_subscription_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX card_subscription_user_id_index ON project_management_tool.card_subscription USING btree (user_id);


--
-- Name: identity_provider_user_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX identity_provider_user_user_id_index ON project_management_tool.identity_provider_user USING btree (user_id);


--
-- Name: label_board_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX label_board_id_index ON project_management_tool.label USING btree (board_id);


--
-- Name: label_position_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX label_position_index ON project_management_tool.label USING btree ("position");


--
-- Name: list_board_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX list_board_id_index ON project_management_tool.list USING btree (board_id);


--
-- Name: list_position_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX list_position_index ON project_management_tool.list USING btree ("position");


--
-- Name: notification_action_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX notification_action_id_index ON project_management_tool.notification USING btree (action_id);


--
-- Name: notification_card_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX notification_card_id_index ON project_management_tool.notification USING btree (card_id);


--
-- Name: notification_is_read_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX notification_is_read_index ON project_management_tool.notification USING btree (is_read);


--
-- Name: notification_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX notification_user_id_index ON project_management_tool.notification USING btree (user_id);


--
-- Name: project_manager_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX project_manager_user_id_index ON project_management_tool.project_manager USING btree (user_id);


--
-- Name: session_remote_address_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX session_remote_address_index ON project_management_tool.session USING btree (remote_address);


--
-- Name: session_user_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX session_user_id_index ON project_management_tool.session USING btree (user_id);


--
-- Name: task_card_id_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX task_card_id_index ON project_management_tool.task USING btree (card_id);


--
-- Name: task_position_index; Type: INDEX; Schema: project_management_tool; Owner: postgres
--

CREATE INDEX task_position_index ON project_management_tool.task USING btree ("position");


--
-- Name: SCHEMA project_management_tool; Type: ACL; Schema: -; Owner: pg_database_owner
--

REVOKE USAGE ON SCHEMA project_management_tool FROM PUBLIC;


--
-- PostgreSQL database dump complete
--
