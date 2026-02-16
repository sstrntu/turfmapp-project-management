-- Supabase Migration Script
-- Generated from production database backup
-- Target schema: project_management_tool

-- Create schema
CREATE SCHEMA IF NOT EXISTS project_management_tool;

-- Set search path
SET search_path TO project_management_tool, public;

--
-- PostgreSQL database dump
--


-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

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
-- Name: SCHEMA project_management_tool; Type: COMMENT; Schema: -; Owner: pg_database_owner
--




--
-- Name: next_id(); Type: FUNCTION; Schema: public; Owner: postgres
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
        SELECT nextval('next_id_seq') % 1024 INTO sequence;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO milliseconds;
        id := (milliseconds - epoch) << 23;
        id := id | (shard << 10);
        id := id | (sequence);
      END;
    $$;




SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: archive; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.archive (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    from_model text NOT NULL,
    original_record_id bigint NOT NULL,
    original_record json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: attachment; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: board; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.board (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    project_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: board_membership; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: card; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: card_label; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.card_label (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    label_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: card_membership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.card_membership (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: card_subscription; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.card_subscription (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    card_id bigint NOT NULL,
    user_id bigint NOT NULL,
    is_permanent boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: identity_provider_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.identity_provider_user (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    user_id bigint NOT NULL,
    issuer text NOT NULL,
    sub text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: label; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.list (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    board_id bigint NOT NULL,
    "position" double precision NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: migration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.migration (
    id integer NOT NULL,
    name character varying(255),
    batch integer,
    migration_time timestamp with time zone
);




--
-- Name: migration_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_management_tool.migration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;




--
-- Name: migration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_management_tool.migration_id_seq OWNED BY project_management_tool.migration.id;


--
-- Name: migration_lock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.migration_lock (
    index integer NOT NULL,
    is_locked integer
);




--
-- Name: migration_lock_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_management_tool.migration_lock_index_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;




--
-- Name: migration_lock_index_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_management_tool.migration_lock_index_seq OWNED BY project_management_tool.migration_lock.index;


--
-- Name: next_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_management_tool.next_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;




--
-- Name: notification; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: project; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.project (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    name text NOT NULL,
    background jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    background_image jsonb
);




--
-- Name: project_manager; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE project_management_tool.project_manager (
    id bigint DEFAULT project_management_tool.next_id() NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);




--
-- Name: session; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: task; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: user_account; Type: TABLE; Schema: public; Owner: postgres
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




--
-- Name: migration id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration ALTER COLUMN id SET DEFAULT nextval('project_management_tool.migration_id_seq'::regclass);


--
-- Name: migration_lock index; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration_lock ALTER COLUMN index SET DEFAULT nextval('project_management_tool.migration_lock_index_seq'::regclass);


--
-- Data for Name: action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.action (id, card_id, user_id, type, data, created_at, updated_at) FROM stdin;
1430502957970883599	1430502957912163342	1430501158790628357	createCard	{"list": {"id": "1430502915348366349", "name": "Test"}}	2025-01-24 12:14:01.318	\N
1430505575434683409	1430502957912163342	1430480385812202497	commentCard	{"text": "hi @sira\\n just test"}	2025-01-24 12:19:13.342	\N
1430519898496304157	1430519898227868700	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Test"}}	2025-01-24 12:47:40.787	\N
1430520865954464803	1430519898227868700	1430480385812202497	commentCard	{"text": "## Test\\n- lorem\\n- ipsum"}	2025-01-24 12:49:36.114	\N
1430520943221933093	1430519898227868700	1430480385812202497	commentCard	{"text": "@sira\\nhi"}	2025-01-24 12:49:45.328	\N
1430528319534662711	1430519898227868700	1430480385812202497	commentCard	{"text": "test"}	2025-01-24 13:04:24.649	\N
1430530139845821500	1430519898227868700	1430480385812202497	commentCard	{"text": "another test"}	2025-01-24 13:08:01.647	\N
1430530452816397376	1430519898227868700	1430480385812202497	commentCard	{"text": "asdasd"}	2025-01-24 13:08:38.955	\N
1430532340035093578	1430519898227868700	1430524402960696364	commentCard	{"text": "@game\\n\\nhii"}	2025-01-24 13:12:23.934	\N
1430945233931076695	1430519898227868700	1430501158790628357	moveCard	{"toList": {"id": "1430532616615887950", "name": "Blocked"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-25 02:52:44.72	\N
1432126863261566048	1432126863186068574	1430480385812202497	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-26 18:00:25.915	\N
1432128234522149993	1432128234438263911	1430480385812202497	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-26 18:03:09.382	\N
1432128251374863468	1432128251324531818	1430480385812202497	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-26 18:03:11.391	\N
1432128678522782835	1432128678245958769	1430480385812202497	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-26 18:04:02.311	\N
1432131205481890943	1432131205364450429	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:09:03.548	\N
1432132167177077896	1432132167101580422	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:10:58.191	\N
1432133165203326096	1432133165018776718	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:12:57.165	\N
1432133249450116243	1432133249383007377	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:13:07.207	\N
1432133309411886230	1432133309344777364	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:13:14.355	\N
1432136214177121450	1432136214110012584	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:19:00.632	\N
1432138030998619314	1432138030939899056	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:22:37.214	\N
1432143088515548350	1432143088423273660	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:32:40.116	\N
1432144454097044675	1432144454029935809	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:35:22.906	\N
1432151592525628619	1432151592458519753	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:49:33.873	\N
1432154072642749651	1432154072584029393	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-26 18:54:29.526	\N
1432375308815697130	1432375308748588264	1430501158790628357	createCard	{"list": {"id": "1432375112018953447", "name": "Fix Alignment on pptx File"}}	2025-01-27 02:14:02.933	\N
1432375465774941421	1432375308748588264	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432375112018953447", "name": "Fix Alignment on pptx File"}}	2025-01-27 02:14:21.642	\N
1432376915703891188	1432376915628393714	1430501158790628357	createCard	{"list": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 02:17:14.489	\N
1432377073652991223	1432377073594270965	1430501158790628357	createCard	{"list": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 02:17:33.318	\N
1432377136081011962	1432377136022291704	1430501158790628357	createCard	{"list": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 02:17:40.76	\N
1432379457837991169	1432379457754105087	1430501158790628357	createCard	{"list": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 02:22:17.535	\N
1432413723481343235	1432377073594270965	1430501158790628357	commentCard	{"text": "Slides - 21, 29, 32, 33, 41, 51, 57,"}	2025-01-27 03:30:22.316	\N
1432413910740239622	1432413910664742148	1430501158790628357	createCard	{"list": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 03:30:44.641	\N
1432432986896205064	1432413910664742148	1430501158790628357	commentCard	{"text": "Slides - 32, 41, 44,"}	2025-01-27 04:08:38.694	\N
1432436561013638409	1432377073594270965	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 04:15:44.762	\N
1432436995660973322	1432413910664742148	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 04:16:36.576	\N
1432437057493402891	1432376915628393714	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432376741665441009", "name": "QC ISSUES"}}	2025-01-27 04:16:43.95	\N
1432439099364476173	1432376915628393714	1430501158790628357	moveCard	{"toList": {"id": "1432375112018953447", "name": "Fix Alignment on pptx File"}, "fromList": {"id": "1432374918888031461", "name": "QC Alignments"}}	2025-01-27 04:20:47.357	\N
1432439119924954382	1432377073594270965	1430501158790628357	moveCard	{"toList": {"id": "1432375112018953447", "name": "Fix Alignment on pptx File"}, "fromList": {"id": "1432374918888031461", "name": "QC Alignments"}}	2025-01-27 04:20:49.81	\N
1432439132885353743	1432413910664742148	1430501158790628357	moveCard	{"toList": {"id": "1432375112018953447", "name": "Fix Alignment on pptx File"}, "fromList": {"id": "1432374918888031461", "name": "QC Alignments"}}	2025-01-27 04:20:51.356	\N
1432440506620577041	1432128678245958769	1430524402960696364	moveCard	{"toList": {"id": "1430532224431686727", "name": "Review / Test"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-27 04:23:35.115	\N
1432457233311991059	1432377073594270965	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432375112018953447", "name": "Upwork Fixing the pptx File"}}	2025-01-27 04:56:49.092	\N
1432457444855907604	1432413910664742148	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432375112018953447", "name": "Upwork Fixing the pptx File"}}	2025-01-27 04:57:14.31	\N
1432466461040837911	1432466460956951829	1430501158790628357	createCard	{"list": {"id": "1432376741665441009", "name": "ISSUES"}}	2025-01-27 05:15:09.125	\N
1432466777224250649	1432466460956951829	1430501158790628357	commentCard	{"text": "Slides - 66,67,68"}	2025-01-27 05:15:46.814	\N
1432466832639395098	1432466460956951829	1430501158790628357	moveCard	{"toList": {"id": "1432375112018953447", "name": "Upwork Fixing the pptx File"}, "fromList": {"id": "1432376741665441009", "name": "ISSUES"}}	2025-01-27 05:15:53.423	\N
1432467553371817246	1432467553304708380	1430501158790628357	createCard	{"list": {"id": "1432375112018953447", "name": "Upwork Fixing the pptx File"}}	2025-01-27 05:17:19.341	\N
1432467662146897184	1432467553304708380	1430501158790628357	commentCard	{"text": "Slide 19"}	2025-01-27 05:17:32.307	\N
1432545381056513319	1432466460956951829	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432375112018953447", "name": "Upwork Fixing the pptx File"}}	2025-01-27 07:51:57.115	\N
1432545395132597545	1432467553304708380	1430501158790628357	moveCard	{"toList": {"id": "1432374918888031461", "name": "QC Alignments"}, "fromList": {"id": "1432375112018953447", "name": "Upwork Fixing the pptx File"}}	2025-01-27 07:51:58.802	\N
1432586914690499883	1432136214110012584	1430524402960696364	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-27 09:14:28.317	\N
1432586952338572589	1432138030939899056	1430524402960696364	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-27 09:14:32.806	\N
1432637826855339311	1432136214110012584	1430524402960696364	moveCard	{"toList": {"id": "1430532224431686727", "name": "Review / Test"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-27 10:55:37.52	\N
1432670857980806449	1432136214110012584	1430524402960696364	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430532224431686727", "name": "Review / Test"}}	2025-01-27 12:01:15.136	\N
1432671574896411956	1432671574854468915	1430524402960696364	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-27 12:02:40.602	\N
1432671689577071926	1432128234438263911	1430524402960696364	moveCard	{"toList": {"id": "1430532224431686727", "name": "Review / Test"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-27 12:02:54.273	\N
1432671735051715899	1432671734758114616	1430524402960696364	createCard	{"list": {"id": "1430532224431686727", "name": "Review / Test"}}	2025-01-27 12:02:59.694	\N
1432671767893116220	1432671734758114616	1430524402960696364	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430532224431686727", "name": "Review / Test"}}	2025-01-27 12:03:03.609	\N
1432671851426874685	1432128678245958769	1430524402960696364	moveCard	{"toList": {"id": "1430532330472080457", "name": "Released"}, "fromList": {"id": "1430532224431686727", "name": "Review / Test"}}	2025-01-27 12:03:13.567	\N
1433130033899111762	1432138030939899056	1430524402960696364	moveCard	{"toList": {"id": "1430532224431686727", "name": "Review / Test"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-28 03:13:33.171	\N
1433130183694484820	1432671734758114616	1430524402960696364	moveCard	{"toList": {"id": "1430532224431686727", "name": "Review / Test"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-28 03:13:51.031	\N
1433174908086519139	1433174908052964706	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Step 1"}}	2025-01-28 04:42:42.594	\N
1433174922682697061	1433174922657531236	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Step 1"}}	2025-01-28 04:42:44.334	\N
1433175105109755238	1433174908052964706	1430525186381186093	moveCard	{"toList": {"id": "1433174850783937888", "name": "Step 2"}, "fromList": {"id": "1433174831095874911", "name": "Step 1"}}	2025-01-28 04:43:06.079	\N
1433175114337224039	1433174908052964706	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "Step 3"}, "fromList": {"id": "1433174850783937888", "name": "Step 2"}}	2025-01-28 04:43:07.181	\N
1433179522609448302	1432128234438263911	1430525186381186093	commentCard	{"text": "@chaowalit hi"}	2025-01-28 04:51:52.688	\N
1433228368626582908	1433228368576251259	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:28:55.588	\N
1433232704589006211	1433232704547063170	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:37:32.474	\N
1433233702623643013	1433233702573311364	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:39:31.449	\N
1433234952660452746	1433233702573311364	1430525186381186093	moveCard	{"toList": {"id": "1433174850783937888", "name": "Get Assets"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:42:00.465	\N
1433234987867440523	1433232704547063170	1430525186381186093	moveCard	{"toList": {"id": "1433174831095874911", "name": "Content Backlog"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:42:04.662	\N
1433235017261122956	1433228368576251259	1430525186381186093	moveCard	{"toList": {"id": "1433174831095874911", "name": "Content Backlog"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:42:08.167	\N
1433235122429101454	1433235122395547021	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 06:42:20.703	\N
1433241292560663953	1433241292510332304	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 06:54:36.24	\N
1433254977307936153	1433254977265993112	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 07:21:47.589	\N
1433255780173219231	1433233702573311364	1430525186381186093	moveCard	{"toList": {"id": "1433255711814452638", "name": "Blocked"}, "fromList": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-01-28 07:23:23.298	\N
1433255867590903200	1433254977265993112	1430525186381186093	moveCard	{"toList": {"id": "1433255711814452638", "name": "Blocked"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 07:23:33.717	\N
1433259305552840111	1433259305485731246	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 07:30:23.554	\N
1433261051339605425	1433261051297662384	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 07:33:51.67	\N
1433271313023108537	1433271312972776888	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 07:54:14.958	\N
1433300241708221898	1433300241649501641	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 08:51:43.526	\N
1433303096729011666	1433303096687068625	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 08:57:23.871	\N
1433314480019736032	1433314479944238559	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 09:20:00.863	\N
1433316010521265638	1433316010454156773	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:23:03.315	\N
1433316651008263656	1433316650974709223	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:24:19.667	\N
1433317255155811818	1433317255122257385	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:25:31.687	\N
1433317981458269678	1433317981407938029	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:26:58.269	\N
1433318486167258610	1433318486083372529	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:27:58.435	\N
1433320073350612473	1433320073308669432	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:31:07.642	\N
1433320514432009725	1433320514390066684	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:32:00.223	\N
1433321620545472005	1433321620511917572	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:34:12.082	\N
1433322124054889991	1433322124021335558	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:35:12.106	\N
1433323813008836105	1433323812958504456	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:38:33.444	\N
1433326151475922445	1433326151408813580	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 09:43:12.211	\N
1433343248507602486	1433259305485731246	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 10:17:10.333	\N
1433343271475611191	1433261051297662384	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 10:17:13.074	\N
1433343318393095736	1433320514390066684	1430534043199341650	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-28 10:17:18.667	\N
1433357513973040697	1433235122395547021	1430525186381186093	moveCard	{"toList": {"id": "1433192294869108087", "name": "Cerezo JP QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 10:45:30.91	\N
1433357613579372091	1433314479944238559	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 10:45:42.783	\N
1433391365009442365	1433261051297662384	1430534043199341650	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-28 11:52:46.267	\N
1433941633576994367	1433235122395547021	1433171377464018261	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192294869108087", "name": "Cerezo JP QC"}}	2025-01-29 06:06:03.393	\N
1433944122602817090	1433944122544096833	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 06:11:00.11	\N
1433947356302149193	1433944122544096833	1433171377464018261	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 06:17:25.595	\N
1433947392188614219	1433944122544096833	1433171377464018261	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-29 06:17:29.875	\N
1433960428253218381	1433259305485731246	1430534043199341650	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-29 06:43:23.893	\N
1434026103948707410	1434026103898375761	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 08:53:53.049	\N
1434027746203272789	1434026103898375761	1433171377464018261	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 08:57:08.818	\N
1434028784142517848	1434028784092186199	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 08:59:12.552	\N
1434029186351105626	1434029186309162585	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 09:00:00.499	\N
1434029700287563356	1434029700119791195	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 09:01:01.765	\N
1434037967504017011	1434037967428519538	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 09:17:27.294	\N
1434038162857920117	1434038162799199860	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 09:17:50.581	\N
1434038741478934136	1433233702573311364	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433255711814452638", "name": "Blocked"}}	2025-01-29 09:18:59.559	\N
1434038848207193723	1434038848156862074	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-29 09:19:12.282	\N
1434041555739477639	1434041555689145990	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-29 09:24:35.045	\N
1434074427749828237	1434038848156862074	1430525186381186093	moveCard	{"toList": {"id": "1433192294869108087", "name": "Cerezo JP QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-29 10:29:53.691	\N
1434084870082004624	1434038848156862074	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192294869108087", "name": "Cerezo JP QC"}}	2025-01-29 10:50:38.515	\N
1434085040244917906	1434038848156862074	1430525186381186093	moveCard	{"toList": {"id": "1433192294869108087", "name": "Cerezo JP QC"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-01-29 10:50:58.8	\N
1434109362040735382	1434109361990403733	1430525186381186093	createCard	{"list": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-01-29 11:39:18.186	\N
1434565850207094425	1434038848156862074	1430534043199341650	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192294869108087", "name": "Cerezo JP QC"}}	2025-01-30 02:46:15.814	\N
1434570298744637083	1433228368576251259	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-30 02:55:06.118	\N
1434570373461968541	1433228368576251259	1430534043199341650	moveCard	{"toList": {"id": "1433174850783937888", "name": "Get Assets"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-30 02:55:15.03	\N
1434580889697781407	1432671734758114616	1430524402960696364	moveCard	{"toList": {"id": "1430532330472080457", "name": "Released"}, "fromList": {"id": "1430532224431686727", "name": "Review / Test"}}	2025-01-30 03:16:08.661	\N
1434581688746247841	1434581688695916192	1430524402960696364	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-01-30 03:17:43.917	\N
1434622121266382522	1434026103898375761	1430534043199341650	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-01-30 04:38:03.847	\N
1434710292624836318	1434710292574504669	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-01-30 07:33:14.694	\N
1434726176630245095	1434109361990403733	1430525186381186093	moveCard	{"toList": {"id": "1433255711814452638", "name": "Blocked"}, "fromList": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-01-30 08:04:48.215	\N
1434727989802698484	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-01-30 08:08:24.359	\N
1434728025496225526	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434703542295201484", "name": "To-do Task"}, "fromList": {"id": "1434704734609999566", "name": "In Progress"}}	2025-01-30 08:08:28.61	\N
1434729164425922297	1434729164375590648	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-01-30 08:10:44.388	\N
1434742760069400330	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-01-30 08:37:45.112	\N
1434742916265281292	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434703542295201484", "name": "To-do Task"}, "fromList": {"id": "1434704734609999566", "name": "In Progress"}}	2025-01-30 08:38:03.735	\N
1435342468919854864	1432136214110012584	1430524402960696364	moveCard	{"toList": {"id": "1430532616615887950", "name": "Blocked"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-01-31 04:29:15.965	\N
1435346986671802132	1435346986613081875	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-31 04:38:14.538	\N
1435347447952967448	1435346986613081875	1430525186381186093	moveCard	{"toList": {"id": "1433255711814452638", "name": "Blocked"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-31 04:39:09.528	\N
1435347538331830042	1434109361990403733	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433255711814452638", "name": "Blocked"}}	2025-01-31 04:39:20.3	\N
1439821519596291768	1439819756243781290	1430480385812202497	commentCard	{"text": "hi"}	2025-02-06 08:48:20.43	\N
1435347571005458205	1435346986613081875	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433255711814452638", "name": "Blocked"}}	2025-01-31 04:39:24.197	\N
1435350747981023009	1433261051297662384	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-01-31 04:45:42.92	\N
1435360247148447527	1433228368576251259	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-01-31 05:04:35.309	\N
1435360273421567785	1433228368576251259	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-01-31 05:04:38.443	\N
1435360556042159915	1433232704547063170	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-01-31 05:05:12.131	\N
1437710352623077171	1433228368576251259	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-03 10:53:49.713	\N
1437710491379042101	1433233702573311364	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:54:06.253	\N
1437710509271942967	1433261051297662384	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:54:08.389	\N
1437710533288527673	1433232704547063170	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:54:11.252	\N
1437710588049360699	1434109361990403733	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:54:17.78	\N
1437711172785669951	1437711172743726910	1430525186381186093	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:55:27.487	\N
1437712148967982915	1433241292510332304	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-03 10:57:23.856	\N
1437712248607868741	1433241292510332304	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:57:35.734	\N
1437712713001207623	1434037967428519538	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-03 10:58:31.091	\N
1437712886175631178	1434037967428519538	1430534043199341650	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-03 10:58:51.736	\N
1437713113582405452	1434041555689145990	1430525186381186093	moveCard	{"toList": {"id": "1433174850783937888", "name": "Get Assets"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-03 10:59:18.847	\N
1438215221498873682	1433314479944238559	1433172478670144855	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 03:36:54.772	\N
1438216855113172822	1433254977265993112	1433172478670144855	commentCard	{"text": "Action: Need GFX support"}	2025-02-04 03:40:09.514	\N
1438216984901715804	1438216984859772763	1430524402960696364	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-02-04 03:40:24.99	\N
1438217313550600032	1433254977265993112	1433172478670144855	commentCard	{"text": "P'Bam and Phyo, please help allocate time to take a look at this card krub"}	2025-02-04 03:41:04.167	\N
1438218125081315176	1438218124980651878	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:42:40.909	\N
1438218418774869869	1438218418741315436	1433172478670144855	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 03:43:15.92	\N
1438218506922362736	1438218506888808303	1433172478670144855	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 03:43:26.428	\N
1438218607862482808	1438218124980651878	1430480385812202497	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:43:38.462	\N
1438218653144188796	1438218418741315436	1433172478670144855	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 03:43:43.86	\N
1438218674358978433	1438218506888808303	1433172478670144855	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 03:43:46.388	\N
1438219017796978570	1438219017729869704	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:44:27.33	\N
1438219109123753869	1438219109073422219	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:44:38.217	\N
1438219198152050576	1438219198076553102	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:44:48.829	\N
1438219891713771414	1438219017729869704	1430480385812202497	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:46:11.508	\N
1438219952833169305	1438219109073422219	1430480385812202497	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-04 03:46:18.794	\N
1438221738381936543	1438221738298050461	1430480385812202497	createCard	{"list": {"id": "1430532224431686727", "name": "Review / Test"}}	2025-02-04 03:49:51.648	\N
1438322380177934256	1438322380127602607	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 07:09:49.085	\N
1438322455281141682	1438322455239198641	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 07:09:58.038	\N
1438405192163788725	1433259305485731246	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 09:54:21.04	\N
1438405249768359863	1433233702573311364	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 09:54:27.91	\N
1438405268449789881	1433261051297662384	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 09:54:30.138	\N
1438405299688966075	1433232704547063170	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 09:54:33.859	\N
1438405422892451773	1433241292510332304	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 09:54:48.546	\N
1438410556963817408	1433303096687068625	1433261799410501042	moveCard	{"toList": {"id": "1433174850783937888", "name": "Get Assets"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 10:05:00.575	\N
1438410581525661633	1433303096687068625	1433261799410501042	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-02-04 10:05:03.505	\N
1438410700190910402	1433303096687068625	1433261799410501042	moveCard	{"toList": {"id": "1433174831095874911", "name": "Content Backlog"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 10:05:17.649	\N
1438422084689594312	1434041555689145990	1430525186381186093	moveCard	{"toList": {"id": "1438421969388177351", "name": "Outsource"}, "fromList": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-02-04 10:27:54.79	\N
1438422116608247755	1433300241649501641	1430525186381186093	moveCard	{"toList": {"id": "1438421969388177351", "name": "Outsource"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 10:27:58.594	\N
1438422228042516429	1438322380127602607	1430525186381186093	moveCard	{"toList": {"id": "1438421969388177351", "name": "Outsource"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 10:28:11.878	\N
1438422244727457742	1438322455239198641	1430525186381186093	moveCard	{"toList": {"id": "1438421969388177351", "name": "Outsource"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-04 10:28:13.867	\N
1438422562555037647	1433259305485731246	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-04 10:28:51.753	\N
1438422717912057809	1433261051297662384	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-04 10:29:10.273	\N
1438423544684873683	1433320514390066684	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-04 10:30:48.832	\N
1438431374385088470	1438431374158596053	1430525186381186093	createCard	{"list": {"id": "1438421969388177351", "name": "Outsource"}}	2025-02-04 10:46:22.207	\N
1438931347962857469	1438931347761530876	1433172478670144855	createCard	{"list": {"id": "1438929933786154997", "name": "To-do Task"}}	2025-02-05 03:19:43.702	\N
1438931810292598783	1437711172743726910	1430525186381186093	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-05 03:20:38.814	\N
1438933352353629197	1438933352294908940	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 03:23:42.644	\N
1438933580288885779	1438933580221776914	1430525186381186093	createCard	{"list": {"id": "1438928962880276463", "name": "Get Assets"}}	2025-02-05 03:24:09.815	\N
1438934380050383915	1438934380025218090	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 03:25:45.155	\N
1438937409193509981	1433316650974709223	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-05 03:31:46.255	\N
1438938542259569760	1438938542184072287	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 03:34:01.329	\N
1438941080107091060	1438938542184072287	1433172244418266454	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 03:39:03.864	\N
1438943393827783800	1438943393743897719	1433172244418266454	createCard	{"list": {"id": "1438943147529864310", "name": "To-do Task"}}	2025-02-05 03:43:39.678	\N
1438944089100780667	1438944089067226234	1430525186381186093	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-05 03:45:02.564	\N
1438945626220921989	1434041555689145990	1430525186381186093	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1438421969388177351", "name": "Outsource"}}	2025-02-05 03:48:05.801	\N
1438945706810279047	1434041555689145990	1430525186381186093	moveCard	{"toList": {"id": "1433174850783937888", "name": "Get Assets"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-05 03:48:15.41	\N
1438948712448525473	1438948712406582432	1433172478670144855	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-05 03:54:13.71	\N
1438948922130171050	1438948922079839401	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 03:54:38.705	\N
1438949933343311024	1438949933292979375	1433172478670144855	createCard	{"list": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-05 03:56:39.252	\N
1438952821994030267	1438952821910144186	1433172244418266454	createCard	{"list": {"id": "1438943147529864310", "name": "To-do Task"}}	2025-02-05 04:02:23.606	\N
1438952923471021245	1438952821910144186	1433172244418266454	moveCard	{"toList": {"id": "1438945086774707327", "name": "Internal QC"}, "fromList": {"id": "1438943147529864310", "name": "To-do Task"}}	2025-02-05 04:02:35.704	\N
1438959873986397377	1438959873944454336	1433172877045138776	createCard	{"list": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-05 04:16:24.269	\N
1438979442243273929	1438979442184553672	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 04:55:16.987	\N
1438980312267752654	1438980312225809613	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 04:57:00.702	\N
1438981359937782999	1438981359895839958	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 04:59:05.594	\N
1438981663966102747	1438981663898993882	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 04:59:41.837	\N
1438983888473949406	1438983888423617757	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:04:07.019	\N
1438985344593691872	1438985344543360223	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:07:00.602	\N
1438985479423788258	1438985479381845217	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:07:16.675	\N
1438985509966709988	1438985509941544163	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:07:20.316	\N
1438985685439612134	1438985685389280485	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:07:41.234	\N
1438985758361781480	1438985758336615655	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:07:49.928	\N
1438985957792548074	1438985957750605033	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:08:13.7	\N
1438986079435752684	1438986079402198251	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:08:28.202	\N
1438986240312476910	1438986240270533869	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:08:47.38	\N
1438986407371605232	1438986407329662191	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:09:07.295	\N
1438986493992371442	1438986493950428401	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:09:17.62	\N
1438986650381190388	1438986650347635955	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:09:36.264	\N
1438991493418190087	1438991493367858438	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 05:19:13.599	\N
1439000237141132554	1439000237099189513	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:36:35.932	\N
1439004132013770011	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:44:20.234	\N
1439009557194999080	1439009557144667431	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:55:06.969	\N
1439009814121284907	1439009814079341866	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:55:37.597	\N
1439010075250263342	1439010075208320301	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:56:08.726	\N
1439010168388977968	1439010168246371631	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:56:19.828	\N
1439010281878455602	1439010281844901169	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 05:56:33.359	\N
1439035918445970814	1439035918395639165	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:47:29.475	\N
1439036085412824450	1439036085295383936	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:47:49.379	\N
1439036397720700292	1439036397678757251	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:48:26.609	\N
1439036438237676934	1439036438204122501	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:48:31.439	\N
1439036465861363080	1439036465827808647	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:48:34.732	\N
1439036570324698506	1439036570291144073	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:48:47.185	\N
1439036641963410828	1439036641913079179	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 06:48:55.725	\N
1439037119115822482	1432379457754105087	1430501158790628357	commentCard	{"text": "https://plan.turfmapp.com/cards/1432377136022291704"}	2025-02-05 06:49:52.604	\N
1439058036176979351	1439058036135036310	1433172478670144855	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 07:31:26.114	\N
1439058369649313178	1439058369607370137	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:32:05.867	\N
1439058853051237796	1438933352294908940	1433172478670144855	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:33:03.491	\N
1439059688036500911	1439059687986169262	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:34:43.03	\N
1439061787906409906	1439061787864466865	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:38:53.355	\N
1439062157290374582	1439062157164545460	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:39:37.389	\N
1439062305189922234	1439062305089258936	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:39:55.021	\N
1439063386900923836	1439063386858980795	1430525186381186093	createCard	{"list": {"id": "1438421969388177351", "name": "Outsource"}}	2025-02-05 07:42:03.97	\N
1439067056908535235	1439067056858203586	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:49:21.469	\N
1439067436207834567	1439067435696129477	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 07:50:06.678	\N
1439075740678096334	1439075740552267212	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 08:06:36.655	\N
1439079687023232465	1439079686972900816	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 08:14:27.096	\N
1439082514051237332	1439082514009294291	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 08:20:04.105	\N
1439083705585894877	1439083705543951836	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 08:22:26.147	\N
1439086276308370914	1439086276258039265	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 08:27:32.6	\N
1439086630131467749	1439086630081136100	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 08:28:14.779	\N
1439088141767017960	1439088141725074919	1433172244418266454	createCard	{"list": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 08:31:14.98	\N
1439094361080989165	1439094361030657516	1430525186381186093	createCard	{"list": {"id": "1438421969388177351", "name": "Outsource"}}	2025-02-05 08:43:36.38	\N
1439129941605090800	1439129941546370543	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 09:54:17.909	\N
1439130116566287858	1439130116532733425	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-05 09:54:38.767	\N
1439186484388169213	1439186484346226172	1433172877045138776	createCard	{"list": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-05 11:46:38.334	\N
1439188311192110598	1439188311150167557	1433172877045138776	createCard	{"list": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-05 11:50:16.106	\N
1439224013594297865	1438938542184072287	1430501158790628357	moveCard	{"toList": {"id": "1434705078811363023", "name": "Post-Production"}, "fromList": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-05 13:01:12.161	\N
1439639875287516682	1433316010454156773	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 02:47:26.739	\N
1439644479022695948	1439644478963975691	1430534043199341650	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 02:56:35.548	\N
1439673066241132056	1438943393743897719	1433172244418266454	moveCard	{"toList": {"id": "1438944971691394174", "name": "In Progress"}, "fromList": {"id": "1438943147529864310", "name": "To-do Task"}}	2025-02-06 03:53:23.397	\N
1439676827072202268	1439676827013482011	1433172877045138776	createCard	{"list": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-06 04:00:51.736	\N
1439677242174080544	1439676827013482011	1433172877045138776	moveCard	{"toList": {"id": "1439185921311245818", "name": "Imposed"}, "fromList": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-06 04:01:41.221	\N
1439678459478541860	1439186484346226172	1433172877045138776	moveCard	{"toList": {"id": "1439185921311245818", "name": "Imposed"}, "fromList": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-06 04:04:06.335	\N
1439683812106700329	1439683812056368680	1433172877045138776	createCard	{"list": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-06 04:14:44.418	\N
1439684182212085290	1433303096687068625	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 04:15:28.535	\N
1439684263850018348	1433320073308669432	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 04:15:38.271	\N
1439689109571372592	1439689109495875119	1433172478670144855	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 04:25:15.925	\N
1439749511726499403	1438938542184072287	1430501158790628357	commentCard	{"text": "3D rendering and photo done. Hand off to Bank"}	2025-02-06 06:25:16.42	\N
1439758144728204880	1439758144677873231	1433172244418266454	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-06 06:42:25.557	\N
1439819756285724331	1439819756243781290	1430524402960696364	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-06 08:44:50.227	\N
1439823527384450755	1439823527275398849	1430480385812202497	createCard	{"list": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-06 08:52:19.778	\N
1439823844129900236	1439823527275398849	1430480385812202497	moveCard	{"toList": {"id": "1430531972286907461", "name": "In Progress"}, "fromList": {"id": "1430502915348366349", "name": "Backlog"}}	2025-02-06 08:52:57.536	\N
1439850137416369873	1438944089067226234	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 09:45:11.938	\N
1439856097388136148	1438218418741315436	1430501158790628357	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-06 09:57:02.421	\N
1439856150764848857	1438218418741315436	1430501158790628357	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-06 09:57:08.788	\N
1439856173565085406	1438218418741315436	1430501158790628357	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-06 09:57:11.505	\N
1439856504579557093	1438218418741315436	1430501158790628357	commentCard	{"text": "Hours: 4"}	2025-02-06 09:57:50.962	\N
1439857429272594155	1439857429213873898	1433171377464018261	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 09:59:41.197	\N
1439857708730681070	1439857429213873898	1433171377464018261	moveCard	{"toList": {"id": "1438421969388177351", "name": "Outsource"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-06 10:00:14.509	\N
1440388860600125169	1433303096687068625	1433172478670144855	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-07 03:35:32.746	\N
1440388881470981875	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434704207083996877", "name": "Block"}, "fromList": {"id": "1434704734609999566", "name": "In Progress"}}	2025-02-07 03:35:35.237	\N
1440388891965130489	1433316650974709223	1433172478670144855	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-07 03:35:36.487	\N
1440388971942119163	1438218506888808303	1433172478670144855	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-07 03:35:46.021	\N
1440389194626107136	1439857429213873898	1433172478670144855	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1438421969388177351", "name": "Outsource"}}	2025-02-07 03:36:12.565	\N
1440389236074219266	1437711172743726910	1433172478670144855	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-07 03:36:17.508	\N
1440389253027596036	1437711172743726910	1433172478670144855	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-07 03:36:19.529	\N
1440389284082222855	1440389283981559558	1430524402960696364	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-02-07 03:36:23.224	\N
1440389331846956809	1440389331821790984	1430524402960696364	createCard	{"list": {"id": "1430531972286907461", "name": "In Progress"}}	2025-02-07 03:36:28.926	\N
1440389382035998474	1439644478963975691	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-07 03:36:34.908	\N
1440389587733055248	1439689109495875119	1433172478670144855	moveCard	{"toList": {"id": "1433192158453564789", "name": "Internal QC"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-07 03:36:59.429	\N
1440389625783781140	1439689109495875119	1433172478670144855	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-07 03:37:03.965	\N
1440398077910320921	1434710292574504669	1433172244418266454	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434704207083996877", "name": "Block"}}	2025-02-07 03:53:51.533	\N
1440417346391901985	1439689109495875119	1430525186381186093	moveCard	{"toList": {"id": "1440417324245976864", "name": "Meeting"}, "fromList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}}	2025-02-07 04:32:08.519	\N
1440417482580952869	1438218506888808303	1430525186381186093	moveCard	{"toList": {"id": "1440417324245976864", "name": "Meeting / Report"}, "fromList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}}	2025-02-07 04:32:24.752	\N
1440417647500986153	1438218506888808303	1430525186381186093	commentCard	{"text": "Cerezo Osaka Truck #5 Report - 2 hours"}	2025-02-07 04:32:44.412	\N
1440417701422958381	1438218418741315436	1430525186381186093	moveCard	{"toList": {"id": "1440417324245976864", "name": "Meeting / Report"}, "fromList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}}	2025-02-07 04:32:50.842	\N
1440417865848063794	1438944089067226234	1430525186381186093	moveCard	{"toList": {"id": "1440417324245976864", "name": "Meeting / Report"}, "fromList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}}	2025-02-07 04:33:10.441	\N
1440419188236617526	1440419188186285877	1430534043199341650	createCard	{"list": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-07 04:35:48.083	\N
1440422192859842368	1433233702573311364	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-07 04:41:46.261	\N
1440425293733955397	1440419188186285877	1430534043199341650	commentCard	{"text": "Build The Perfect Player (Translate) - 15 mins"}	2025-02-07 04:47:55.914	\N
1440425834446849863	1433320514390066684	1430534043199341650	commentCard	{"text": "H2H Osaka Derby - 2 hours"}	2025-02-07 04:49:00.372	\N
1440427105287407432	1433261051297662384	1430534043199341650	commentCard	{"text": "Shunta Tanaka's Interview - 4 hours"}	2025-02-07 04:51:31.868	2025-02-07 04:51:40.239
1440427273235728201	1433259305485731246	1430534043199341650	commentCard	{"text": "Lucas Fernandes' Interview - 3 hours"}	2025-02-07 04:51:51.892	\N
1440427390818846538	1434037967428519538	1430534043199341650	commentCard	{"text": "RECAP PHOTOS - Cerezo Cherry-OT #5 - 1 hour"}	2025-02-07 04:52:05.908	\N
1440427921280862027	1434026103898375761	1430534043199341650	commentCard	{"text": "Cerezo Cherry-OT #5\\nSchool Announcement - 1 hour"}	2025-02-07 04:53:09.142	\N
1440428004168697676	1433944122544096833	1430534043199341650	commentCard	{"text": "Cerezo Cherry-OT #5 - School Guess Poster 🇹🇭 - 1 hour"}	2025-02-07 04:53:19.026	\N
1440428167293568845	1438218418741315436	1430534043199341650	commentCard	{"text": "Cerezo Osaka SNS Monthly Report (January) - 4 hours"}	2025-02-07 04:53:38.469	\N
1440429407977080658	1433241292510332304	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-07 04:56:06.361	\N
1440435386227623764	1434109361990403733	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-07 05:07:59.033	\N
1440575811466823521	1439188311150167557	1433172877045138776	moveCard	{"toList": {"id": "1439184983741695481", "name": "Block"}, "fromList": {"id": "1438949766678447278", "name": "To-do list / Task"}}	2025-02-07 09:46:59.027	\N
1440575831272327010	1439188311150167557	1433172877045138776	moveCard	{"toList": {"id": "1438949766678447278", "name": "To-do list / Task"}, "fromList": {"id": "1439184983741695481", "name": "Block"}}	2025-02-07 09:47:01.389	\N
1442592812364203907	1442592812120934273	1430480385812202497	createCard	{"list": {"id": "1442585390165788529", "name": "Backlog"}}	2025-02-10 04:34:24.271	\N
1442592988826961798	1442592988768241540	1430480385812202497	createCard	{"list": {"id": "1442585953032996727", "name": "Backlog"}}	2025-02-10 04:34:45.308	\N
1442593095244842889	1442593095177734023	1430480385812202497	createCard	{"list": {"id": "1442585953032996727", "name": "Backlog"}}	2025-02-10 04:34:57.994	\N
1442639409353590667	1442639409261315978	1433172478670144855	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-10 06:06:59.064	\N
1442640975691253651	1442640975624144786	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-10 06:10:05.787	\N
1442646983394199446	1433303096687068625	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-10 06:22:01.959	\N
1442647159462692760	1440419188186285877	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-10 06:22:22.949	\N
1442647952009987996	1442647951951267739	1430525186381186093	createCard	{"list": {"id": "1433192158453564789", "name": "Internal QC"}}	2025-02-10 06:23:57.43	\N
1442649482989668256	1433317981407938029	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-10 06:26:59.935	\N
1442653687544547246	1442640975624144786	1433172478670144855	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-10 06:35:21.159	\N
1442656542003300274	1439000237099189513	1433172478670144855	moveCard	{"toList": {"id": "1434704734609999566", "name": "In Progress"}, "fromList": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-10 06:41:01.435	\N
1442656998008031156	1439000237099189513	1433172478670144855	commentCard	{"text": "Status -- Kei send the draft to us but not the final draft yet"}	2025-02-10 06:41:55.795	\N
1442899437805373368	1432128251324531818	1430480385812202497	createTask	{"task": {"id": "1442899437755041719", "name": "Test @[Sharp](1430525186381186093)", "cardId": "1432128251324531818", "position": 65535, "createdAt": "2025-02-10T14:43:36.865Z", "updatedAt": null, "isCompleted": false}, "text": "Test @[Sharp](1430525186381186093)", "mentionedUserIds": ["1430525186381186093"]}	2025-02-10 14:43:36.872	\N
1442899437964756922	1432128251324531818	1430480385812202497	mentionUser	{"task": {"id": "1442899437755041719", "name": "Test @[Sharp](1430525186381186093)", "cardId": "1432128251324531818", "position": 65535, "createdAt": "2025-02-10T14:43:36.865Z", "updatedAt": null, "isCompleted": false}, "text": "Test @[Sharp](1430525186381186093)", "mentionedUserIds": ["1430525186381186093"]}	2025-02-10 14:43:36.892	\N
1443269244396505023	1433232704547063170	1430534043199341650	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-11 02:58:21.252	\N
1443272709311039426	1443272709252319169	1430534043199341650	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-11 03:05:14.303	\N
1443272735634491331	1443272709252319169	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-11 03:05:17.442	\N
1443272815846361029	1443272709252319169	1430534043199341650	createTask	{"task": {"id": "1443272815812806596", "name": "Upload working file", "cardId": "1443272709252319169", "position": 65535, "createdAt": "2025-02-11T03:05:27.000Z", "updatedAt": null, "isCompleted": false}, "text": "Upload working file", "mentionedUserIds": []}	2025-02-11 03:05:27.004	\N
1443280855354050510	1438943393743897719	1433172244418266454	moveCard	{"toList": {"id": "1438945086774707327", "name": "Internal QC"}, "fromList": {"id": "1438944971691394174", "name": "In Progress"}}	2025-02-11 03:21:25.388	\N
1443282843705804755	1438218124980651878	1430524402960696364	moveCard	{"toList": {"id": "1430532224431686727", "name": "Review / Test"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-02-11 03:25:22.416	\N
1443283231116888022	1443283231083333589	1430524402960696364	createCard	{"list": {"id": "1442585390165788529", "name": "Backlog"}}	2025-02-11 03:26:08.601	\N
1443283529910716378	1443283231083333589	1430524402960696364	createTask	{"task": {"id": "1443283529868773337", "name": "Research Plugin", "cardId": "1443283231083333589", "position": 65535, "createdAt": "2025-02-11T03:26:44.213Z", "updatedAt": null, "isCompleted": false}, "text": "Research Plugin", "mentionedUserIds": []}	2025-02-11 03:26:44.22	\N
1443283591759923164	1443283231083333589	1430524402960696364	createTask	{"task": {"id": "1443283591734757339", "name": "Implement Plugin", "cardId": "1443283231083333589", "position": 131070, "createdAt": "2025-02-11T03:26:51.590Z", "updatedAt": null, "isCompleted": false}, "text": "Implement Plugin", "mentionedUserIds": []}	2025-02-11 03:26:51.594	\N
1443283765940979678	1443283231083333589	1430524402960696364	createTask	{"task": {"id": "1443283765907425245", "name": "QC", "cardId": "1443283231083333589", "position": 196605, "createdAt": "2025-02-11T03:27:12.353Z", "updatedAt": null, "isCompleted": false}, "text": "QC", "mentionedUserIds": []}	2025-02-11 03:27:12.357	\N
1443313947649247207	1443313947582138341	1430501158790628357	createCard	{"list": {"id": "1433174850783937888", "name": "Get Assets"}}	2025-02-11 04:27:10.298	\N
1443314315825252333	1443313947582138341	1430501158790628357	createTask	{"task": {"id": "1443314315783309292", "name": "Equipment List", "cardId": "1443313947582138341", "position": 65535, "createdAt": "2025-02-11T04:27:54.181Z", "updatedAt": null, "isCompleted": false}, "text": "Equipment List", "mentionedUserIds": []}	2025-02-11 04:27:54.187	\N
1443314341511170032	1443313947582138341	1430501158790628357	createTask	{"task": {"id": "1443314341486004207", "name": "Shot list", "cardId": "1443313947582138341", "position": 131070, "createdAt": "2025-02-11T04:27:57.246Z", "updatedAt": null, "isCompleted": false}, "text": "Shot list", "mentionedUserIds": []}	2025-02-11 04:27:57.249	\N
1443314381373835251	1443313947582138341	1430501158790628357	createTask	{"task": {"id": "1443314381331892210", "name": "References", "cardId": "1443313947582138341", "position": 196605, "createdAt": "2025-02-11T04:28:01.996Z", "updatedAt": null, "isCompleted": false}, "text": "References", "mentionedUserIds": []}	2025-02-11 04:28:02.001	\N
1443317461620361212	1443317461578418171	1433172478670144855	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-11 04:34:09.196	\N
1443322833433266174	1443322833382934525	1430534043199341650	createCard	{"list": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-11 04:44:49.565	\N
1443322878018717695	1443322833382934525	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-11 04:44:54.881	\N
1443339554084881426	1443339554034549777	1433172478670144855	createCard	{"list": {"id": "1434703542295201484", "name": "To-do Task"}}	2025-02-11 05:18:02.822	\N
1443358580378960917	1438219109073422219	1430480385812202497	moveCard	{"toList": {"id": "1430532330472080457", "name": "Released"}, "fromList": {"id": "1430531972286907461", "name": "In Progress"}}	2025-02-11 05:55:50.932	\N
1443391480138826782	1443391480080106525	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 07:01:12.889	\N
1443391832938513444	1443391832913347619	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 07:01:54.947	\N
1443392056025154604	1443392055991600171	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 07:02:21.541	\N
1443392137814082606	1443392055991600171	1434720470833301219	createTask	{"task": {"id": "1443392137554035757", "name": "Posting in Urawa REDS page", "cardId": "1443392055991600171", "position": 65535, "createdAt": "2025-02-11T07:02:31.259Z", "updatedAt": null, "isCompleted": false}, "text": "Posting in Urawa REDS page", "mentionedUserIds": []}	2025-02-11 07:02:31.291	\N
1443392172173820976	1443392055991600171	1434720470833301219	createTask	{"task": {"id": "1443392172148655151", "name": "Need QC", "cardId": "1443392055991600171", "position": 131070, "createdAt": "2025-02-11T07:02:35.384Z", "updatedAt": null, "isCompleted": false}, "text": "Need QC", "mentionedUserIds": []}	2025-02-11 07:02:35.387	\N
1443396623320220732	1443396623278277691	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 07:11:26.005	\N
1443396872747091007	1443396872721925182	1434720470833301219	createCard	{"list": {"id": "1434619182476953271", "name": "Approved"}}	2025-02-11 07:11:55.739	\N
1443396957136487489	1443396872721925182	1434720470833301219	createTask	{"task": {"id": "1443396957102933056", "name": "posting on Wednesday 12th in Urawa Reds TH page", "cardId": "1443396872721925182", "position": 65535, "createdAt": "2025-02-11T07:12:05.795Z", "updatedAt": null, "isCompleted": false}, "text": "posting on Wednesday 12th in Urawa Reds TH page", "mentionedUserIds": []}	2025-02-11 07:12:05.799	\N
1443397194475373636	1443397194441819203	1434720470833301219	createCard	{"list": {"id": "1434619449494734520", "name": "Posted"}}	2025-02-11 07:12:34.092	\N
1443397437325575239	1443397437266854982	1434720470833301219	createCard	{"list": {"id": "1434619449494734520", "name": "Posted"}}	2025-02-11 07:13:03.041	\N
1443397543860896845	1443397437266854982	1434720470833301219	createTask	{"task": {"id": "1443397543827342412", "name": "posted in Urawa Reds TH page on 7 FEB", "cardId": "1443397437266854982", "position": 65535, "createdAt": "2025-02-11T07:13:15.738Z", "updatedAt": null, "isCompleted": false}, "text": "posted in Urawa Reds TH page on 7 FEB", "mentionedUserIds": []}	2025-02-11 07:13:15.742	\N
1443410876613788765	1443410876563457116	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 07:39:45.13	\N
1443453418860446819	1443410876563457116	1433172244418266454	moveCard	{"toList": {"id": "1434619082375694006", "name": "Internal QC"}, "fromList": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 09:04:16.559	\N
1443457772413781094	1443457772355060837	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 09:12:55.545	\N
1443458771614434413	1443458771580879980	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 09:14:54.659	\N
1443459936775308404	1443459936733365363	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 09:17:13.557	\N
1443460767012619387	1443460766970676346	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 09:18:52.53	\N
1443463685526783107	1443463685484840066	1434720470833301219	createCard	{"list": {"id": "1434615722369091251", "name": "Content"}}	2025-02-11 09:24:40.443	\N
1443497754306282639	1443497754255950990	1430534043199341650	createCard	{"list": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-11 10:32:21.757	\N
1443506919632274576	1433316010454156773	1430525186381186093	moveCard	{"toList": {"id": "1433192321335166328", "name": "Approved"}, "fromList": {"id": "1433174865606608225", "name": "In Progress"}}	2025-02-11 10:50:34.348	\N
1443506943942460562	1433316010454156773	1430525186381186093	moveCard	{"toList": {"id": "1433192440268850553", "name": "Scheduled / Posted"}, "fromList": {"id": "1433192321335166328", "name": "Approved"}}	2025-02-11 10:50:37.248	\N
1443705666022671514	1433322124021335558	1430534043199341650	moveCard	{"toList": {"id": "1433174865606608225", "name": "In Progress"}, "fromList": {"id": "1433174831095874911", "name": "Content Backlog"}}	2025-02-11 17:25:26.764	\N
1444004534710961309	1443283231083333589	1430524402960696364	moveCard	{"toList": {"id": "1442585624451221364", "name": "Review / Test"}, "fromList": {"id": "1442585390165788529", "name": "Backlog"}}	2025-02-12 03:19:14.688	\N
1444007961188893854	1439823527275398849	1430480385812202497	moveCard	{"toList": {"id": "1442585764046047094", "name": "Released"}, "fromList": {"id": "1442585552250472307", "name": "InProgress"}}	2025-02-12 03:26:03.157	\N
1444008068378526879	1438219017729869704	1430480385812202497	moveCard	{"toList": {"id": "1442585734761416565", "name": "Wait for release"}, "fromList": {"id": "1442585552250472307", "name": "InProgress"}}	2025-02-12 03:26:15.936	\N
1444008229045535906	1444008228986815648	1430480385812202497	createCard	{"list": {"id": "1442585552250472307", "name": "InProgress"}}	2025-02-12 03:26:35.089	\N
1444008360184644772	1444008228986815648	1430480385812202497	createTask	{"task": {"id": "1444008360125924515", "name": "Planka tool for ReAct", "cardId": "1444008228986815648", "position": 65535, "createdAt": "2025-02-12T03:26:50.714Z", "updatedAt": null, "isCompleted": false}, "text": "Planka tool for ReAct", "mentionedUserIds": []}	2025-02-12 03:26:50.722	\N
1444008646940820646	1444008228986815648	1430480385812202497	createTask	{"task": {"id": "1444008646907266213", "name": "Implement into ReAct Agent", "cardId": "1444008228986815648", "position": 131070, "createdAt": "2025-02-12T03:27:24.900Z", "updatedAt": null, "isCompleted": false}, "text": "Implement into ReAct Agent", "mentionedUserIds": []}	2025-02-12 03:27:24.906	\N
1444008813026870440	1444008228986815648	1430480385812202497	createTask	{"task": {"id": "1444008812968150183", "name": "Testing", "cardId": "1444008228986815648", "position": 196605, "createdAt": "2025-02-12T03:27:44.696Z", "updatedAt": null, "isCompleted": false}, "text": "Testing", "mentionedUserIds": []}	2025-02-12 03:27:44.704	\N
1692095657294169286	1692095657243837637	1430525186381186093	createCard	{"list": {"id": "1692095336203420865", "name": "Internal QC"}}	2026-01-20 10:32:01.157	\N
1692563975125861595	1692563975067141338	1430534043199341650	createCard	{"list": {"id": "1692095336203420865", "name": "Internal QC"}}	2026-01-21 02:02:28.993	\N
1692664574576166123	1692095657243837637	1430501158790628357	commentCard	{"text": "Slide 3: \\n- include WIN in the New Regulations\\n- New Faces - choose new photos for first and second players\\nSlide 5:\\n- If 2-POINTS -> change to 2-POINT\\nSlide 7:\\n- Specify that these are the blockbuster or match to follow fixtures\\n- I think we should mention which ones are J1 and which ones are J2/J3"}	2026-01-21 05:22:21.38	\N
\.


--
-- Data for Name: archive; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.archive (id, from_model, original_record_id, original_record, created_at, updated_at) FROM stdin;
1430525483841225780	card	1430502957912163342	{"id":"1430502957912163342","createdAt":"2025-01-24T12:14:01.312Z","updatedAt":"2025-01-24T12:51:17.228Z","position":65535,"name":"Test1","description":null,"dueDate":"2025-01-25T05:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1430501369143362568","listId":"1430502915348366349","creatorUserId":"1430501158790628357","coverAttachmentId":null}	2025-01-24 12:58:46.611	\N
1430533310915806289	board	1430533160751334479	{"id":"1430533160751334479","createdAt":"2025-01-24T13:14:01.769Z","updatedAt":null,"position":131070,"name":"Frontend","projectId":"1430501293201294342"}	2025-01-24 13:14:19.669	\N
1432126520402379869	card	1430519898227868700	{"id":"1430519898227868700","createdAt":"2025-01-24T12:47:40.754Z","updatedAt":"2025-01-25T02:52:44.715Z","position":65535,"name":"hi","description":"hey test","dueDate":"2025-01-26T05:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1430501369143362568","listId":"1430532616615887950","creatorUserId":"1430480385812202497","coverAttachmentId":"1430520669526819874"}	2025-01-26 17:59:45.039	\N
1432157325803652313	task	1432151814899238094	{"id":"1432151814899238094","createdAt":"2025-01-26T18:50:00.380Z","updatedAt":null,"position":65535,"name":"Research how to secure Postgres DB","isCompleted":false,"cardId":"1432151592458519753"}	2025-01-26 19:00:57.33	\N
1432157360364717274	task	1432152219783791823	{"id":"1432152219783791823","createdAt":"2025-01-26T18:50:48.646Z","updatedAt":null,"position":131070,"name":"Summary Report of each method","isCompleted":false,"cardId":"1432151592458519753"}	2025-01-26 19:01:01.45	\N
1432374649848595681	board	1432374565257872607	{"id":"1432374565257872607","createdAt":"2025-01-27T02:12:34.294Z","updatedAt":null,"position":65535,"name":"Design","projectId":"1432374492235039965"}	2025-01-27 02:12:44.377	\N
1432376656252634352	card	1432375308748588264	{"id":"1432375308748588264","createdAt":"2025-01-27T02:14:02.922Z","updatedAt":"2025-01-27T02:16:11.203Z","position":65535,"name":"J.LEAGUE 30 Clubs presentation","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1432374743171859682","listId":"1432374918888031461","creatorUserId":"1430501158790628357","coverAttachmentId":"1432376384730170607"}	2025-01-27 02:16:43.557	\N
1432466866143495451	card	1432376915628393714	{"id":"1432376915628393714","createdAt":"2025-01-27T02:17:14.477Z","updatedAt":"2025-01-27T04:20:47.353Z","position":65535,"name":"J1, J2, J3 Footer","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1432374743171859682","listId":"1432375112018953447","creatorUserId":"1430501158790628357","coverAttachmentId":"1432377465073829117"}	2025-01-27 05:15:57.414	\N
1432671629833405749	card	1432671574854468915	{"id":"1432671574854468915","createdAt":"2025-01-27T12:02:40.595Z","updatedAt":null,"position":393210,"name":"Automate RAG","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1430501369143362568","listId":"1430531972286907461","creatorUserId":"1430524402960696364","coverAttachmentId":null}	2025-01-27 12:02:47.15	\N
1433179465046820205	action	1433179415377872234	{"id":"1433179415377872234","createdAt":"2025-01-28T04:51:39.903Z","updatedAt":null,"type":"commentCard","data":{"text":"@apiwat hi"},"cardId":"1432128234438263911","userId":"1430525186381186093"}	2025-01-28 04:51:45.825	\N
1433191747386606963	card	1433174922657531236	{"id":"1433174922657531236","createdAt":"2025-01-28T04:42:44.332Z","updatedAt":null,"position":131070,"name":"card 2","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1430525186381186093","coverAttachmentId":null}	2025-01-28 05:16:09.993	\N
1433191780387390836	card	1433174908052964706	{"id":"1433174908052964706","createdAt":"2025-01-28T04:42:42.590Z","updatedAt":"2025-01-28T04:43:07.177Z","position":65535,"name":"card 1","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174865606608225","creatorUserId":"1430525186381186093","coverAttachmentId":null}	2025-01-28 05:16:13.929	\N
1434005985390757454	task	1433945015763076679	{"id":"1433945015763076679","createdAt":"2025-01-29T06:12:46.584Z","updatedAt":"2025-01-29T06:13:27.608Z","position":196605,"name":"c","isCompleted":true,"cardId":"1433944122544096833"}	2025-01-29 08:13:54.726	\N
1434006008769807951	task	1433944991561942597	{"id":"1433944991561942597","createdAt":"2025-01-29T06:12:43.695Z","updatedAt":"2025-01-29T06:12:51.543Z","position":163837.5,"name":"a","isCompleted":true,"cardId":"1433944122544096833"}	2025-01-29 08:13:57.517	\N
1434006050167588432	task	1433945007248639558	{"id":"1433945007248639558","createdAt":"2025-01-29T06:12:45.568Z","updatedAt":"2025-01-29T06:12:53.249Z","position":131070,"name":"b","isCompleted":true,"cardId":"1433944122544096833"}	2025-01-29 08:14:02.451	\N
1434037236302612079	card	1434028784092186199	{"id":"1434028784092186199","createdAt":"2025-01-29T08:59:12.543Z","updatedAt":"2025-01-29T09:04:38.014Z","position":1310700,"name":"Cerezo Cherry-OT #5 Event recap image","description":"Final Drive :https://drive.google.com/drive/folders/1O7mvMdWSwkC57v293kJ28jhq5zTFBNL2?usp=drive_link","dueDate":"2025-01-31T10:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1433171377464018261","coverAttachmentId":null}	2025-01-29 09:16:00.125	\N
1434037298017601136	card	1434029700119791195	{"id":"1434029700119791195","createdAt":"2025-01-29T09:01:01.741Z","updatedAt":"2025-01-29T09:09:53.783Z","position":1441770,"name":"Cerezo Cherry-OT Event recap Vlog","description":null,"dueDate":"2025-02-04T11:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1433171377464018261","coverAttachmentId":null}	2025-01-29 09:16:07.485	\N
1434037346554087025	card	1434029186309162585	{"id":"1434029186309162585","createdAt":"2025-01-29T09:00:00.490Z","updatedAt":"2025-01-29T09:07:59.045Z","position":1376235,"name":"Cerezo Cherry-OT #5 Event recap VDO","description":null,"dueDate":"2025-02-03T11:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1433171377464018261","coverAttachmentId":null}	2025-01-29 09:16:13.272	\N
1434582017218971300	card	1434581688695916192	{"id":"1434581688695916192","createdAt":"2025-01-30T03:17:43.907Z","updatedAt":null,"position":786420,"name":"Research Metrix open network","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1430501369143362568","listId":"1430502915348366349","creatorUserId":"1430524402960696364","coverAttachmentId":null}	2025-01-30 03:18:23.071	\N
1434743002156238606	card	1434729164375590648	{"id":"1434729164375590648","createdAt":"2025-01-30T08:10:44.379Z","updatedAt":"2025-01-30T08:27:08.972Z","position":131070,"name":"Shooting Ruby reds pack","description":"Execute shots according to the storyboard & shot list.Capture beauty action, on the pitch and off the pitch shots.Collect behind-the-scenes (B-roll) footage for additional content.","dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434703542295201484","creatorUserId":"1433172244418266454","coverAttachmentId":null}	2025-01-30 08:38:13.971	\N
1437713025812399947	card	1434038162799199860	{"id":"1434038162799199860","createdAt":"2025-01-29T09:17:50.573Z","updatedAt":"2025-01-29T09:27:23.905Z","position":1376235,"name":"Cerezo Cherry-OT #5 recap vdo","description":null,"dueDate":"2025-02-03T10:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1433171377464018261","coverAttachmentId":null}	2025-02-03 10:59:08.383	\N
1438232228109748141	project	1438224441292097451	{"id":"1438224441292097451","createdAt":"2025-02-04T03:55:13.856Z","updatedAt":null,"name":"Turfmapp AI","background":null,"backgroundImage":null}	2025-02-04 04:10:42.118	\N
1438927878442977257	board	1438927712809912294	{"id":"1438927712809912294","createdAt":"2025-02-05T03:12:30.356Z","updatedAt":null,"position":262140,"name":"เ","projectId":"1433174555865646425"}	2025-02-05 03:12:50.097	\N
1438933659561231381	card	1438933580221776914	{"id":"1438933580221776914","createdAt":"2025-02-05T03:24:09.808Z","updatedAt":null,"position":65535,"name":"a","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1433174703312209245","listId":"1438928962880276463","creatorUserId":"1430525186381186093","coverAttachmentId":null}	2025-02-05 03:24:19.266	\N
1438933796404593687	label	1438933537750254608	{"id":"1438933537750254608","createdAt":"2025-02-05T03:24:04.746Z","updatedAt":null,"position":65535,"name":"Brandbook","color":"berry-red","boardId":"1433174649205687643"}	2025-02-05 03:24:35.579	\N
1438934376938210344	board	1438929169743349745	{"id":"1438929169743349745","createdAt":"2025-02-05T03:15:24.036Z","updatedAt":"2025-02-05T03:15:50.743Z","position":196605,"name":"Mizuno Morelia Brand Book","projectId":"1434589041889642152"}	2025-02-05 03:25:44.784	\N
1438934568735343664	board	1438929776155822067	{"id":"1438929776155822067","createdAt":"2025-02-05T03:16:36.323Z","updatedAt":null,"position":262140,"name":"Mizuno Morelia Summit","projectId":"1434589041889642152"}	2025-02-05 03:26:07.648	\N
1438934598422627377	board	1434708514550318811	{"id":"1434708514550318811","createdAt":"2025-01-30T07:29:42.731Z","updatedAt":null,"position":131070,"name":"SS26 Sell-in","projectId":"1434589041889642152"}	2025-02-05 03:26:11.187	\N
1438940771339207794	list	1438940203724047466	{"id":"1438940203724047466","createdAt":"2025-02-05T03:37:19.391Z","updatedAt":null,"position":65535,"name":"Monthly Report","boardId":"1434610219668735665"}	2025-02-05 03:38:27.053	\N
1438949526453879980	board	1433174703312209245	{"id":"1433174703312209245","createdAt":"2025-01-28T04:42:18.183Z","updatedAt":"2025-01-28T05:15:01.138Z","position":131070,"name":"Cerezo Cup","projectId":"1433174555865646425"}	2025-02-05 03:55:50.744	\N
1438949549346391213	board	1433191212730287473	{"id":"1433191212730287473","createdAt":"2025-01-28T05:15:06.254Z","updatedAt":null,"position":196605,"name":"Sponsorship","projectId":"1433174555865646425"}	2025-02-05 03:55:53.476	\N
1438953524388955327	attachment	1438953352179221694	{"id":"1438953352179221694","createdAt":"2025-02-05T04:03:26.807Z","updatedAt":null,"dirname":"65e2896c-c273-4445-a143-643b35d7872e","filename":"file.txt","image":null,"name":"file.txt","cardId":"1438952821910144186","creatorUserId":"1433172244418266454"}	2025-02-05 04:03:47.335	\N
1439016501284701494	card	1439010168246371631	{"id":"1439010168246371631","createdAt":"2025-02-05T05:56:19.805Z","updatedAt":null,"position":655350,"name":"Shoot for Urban","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434703542295201484","creatorUserId":"1433172244418266454","coverAttachmentId":null}	2025-02-05 06:08:54.765	\N
1439036979487442321	card	1439036438204122501	{"id":"1439036438204122501","createdAt":"2025-02-05T06:48:31.433Z","updatedAt":null,"position":1196014,"name":"Finalize Storyboard Origin","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434704734609999566","creatorUserId":"1433172478670144855","coverAttachmentId":null}	2025-02-05 06:49:35.959	\N
1439037155186836883	card	1439036397678757251	{"id":"1439036397678757251","createdAt":"2025-02-05T06:48:26.601Z","updatedAt":null,"position":1179630,"name":"Finalize Storyboard Proto","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434704734609999566","creatorUserId":"1433172478670144855","coverAttachmentId":null}	2025-02-05 06:49:56.906	\N
1439037235356763540	card	1439036085295383936	{"id":"1439036085295383936","createdAt":"2025-02-05T06:47:49.365Z","updatedAt":"2025-02-05T06:48:11.530Z","position":1114095,"name":"Finalize Storyboard Origin","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434704734609999566","creatorUserId":"1433172478670144855","coverAttachmentId":null}	2025-02-05 06:50:06.463	\N
1439037353267037589	card	1439036465827808647	{"id":"1439036465827808647","createdAt":"2025-02-05T06:48:34.728Z","updatedAt":null,"position":1187822,"name":"Finalize Storyboard Origin","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434704734609999566","creatorUserId":"1433172478670144855","coverAttachmentId":null}	2025-02-05 06:50:20.517	\N
1439071591697745355	task	1439063571106366913	{"id":"1439063571106366913","createdAt":"2025-02-05T07:42:25.930Z","updatedAt":null,"position":327675,"name":"Full-time","isCompleted":false,"cardId":"1439063386858980795"}	2025-02-05 07:58:22.059	\N
1439078474928096719	card	1439075740552267212	{"id":"1439075740552267212","createdAt":"2025-02-05T08:06:36.638Z","updatedAt":null,"position":249852.1875,"name":"The Bright Road pack (copy)","description":"**5 March**\\n1. Neo IV Beta \\n2. Neo IV\\n3. Moralia II\\n\\n**20 March**\\n4. Neo Sala Beta IN\\n5. Neo Sala Beta TF\\n6. Sala IN\\n7. Sala TF\\n8. Monarcida Neo III\\n9. Monarcida Neo III Wide\\n\\nPriority\\n- KV\\n- อันไหนที่เจ๋ง ต้องรีบส่ง Supporting image ไป","dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1434703208386660040","listId":"1434703542295201484","creatorUserId":"1433172244418266454","coverAttachmentId":null}	2025-02-05 08:12:02.6	\N
1439748247110288968	project	1432374492235039965	{"id":"1432374492235039965","createdAt":"2025-01-27T02:12:25.586Z","updatedAt":null,"name":"J.LEAGUE 30 CLUBS PRESENTATION","background":null,"backgroundImage":null}	2025-02-06 06:22:45.666	\N
1439821455440217782	action	1439820073047951021	{"id":"1439820073047951021","createdAt":"2025-02-06T08:45:27.986Z","updatedAt":null,"type":"commentCard","data":{"text":"test 2 @game"},"cardId":"1439819756243781290","userId":"1430524402960696364"}	2025-02-06 08:48:12.779	\N
1439821468601943735	action	1439819983038187180	{"id":"1439819983038187180","createdAt":"2025-02-06T08:45:17.256Z","updatedAt":null,"type":"commentCard","data":{"text":"test 1"},"cardId":"1439819756243781290","userId":"1430524402960696364"}	2025-02-06 08:48:14.351	\N
1439822451528697534	action	1439820526099891890	{"id":"1439820526099891890","createdAt":"2025-02-06T08:46:21.996Z","updatedAt":null,"type":"commentCard","data":{"text":"test 123"},"cardId":"1439819756243781290","userId":"1430524402960696364"}	2025-02-06 08:50:11.523	\N
1439822463583127231	action	1439821530920912570	{"id":"1439821530920912570","createdAt":"2025-02-06T08:48:21.780Z","updatedAt":null,"type":"commentCard","data":{"text":"test comment 2"},"cardId":"1439819756243781290","userId":"1430524402960696364"}	2025-02-06 08:50:12.962	\N
1439822767183627968	card	1439819756243781290	{"id":"1439819756243781290","createdAt":"2025-02-06T08:44:50.220Z","updatedAt":"2025-02-06T08:49:30.380Z","position":983025,"name":"test card 123","description":"lorem asdasdj saxczxc","dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1430501369143362568","listId":"1430502915348366349","creatorUserId":"1430524402960696364","coverAttachmentId":null}	2025-02-06 08:50:49.152	\N
1439859178238641904	card	1434041555689145990	{"id":"1434041555689145990","createdAt":"2025-01-29T09:24:35.037Z","updatedAt":"2025-02-05T03:48:15.405Z","position":65535,"name":"RECAP VLOG - Cerezo Cherry-OT #5","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174850783937888","creatorUserId":"1433171377464018261","coverAttachmentId":null}	2025-02-06 10:03:09.687	\N
1440389540958177039	card	1438948712406582432	{"id":"1438948712406582432","createdAt":"2025-02-05T03:54:13.703Z","updatedAt":"2025-02-05T03:55:01.424Z","position":1376235,"name":"Cerezo Cherry-OT #5 report","description":null,"dueDate":"2025-02-07T05:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1433172478670144855","coverAttachmentId":null}	2025-02-07 03:36:53.851	\N
1440422334157555524	board	1440422206063511362	{"id":"1440422206063511362","createdAt":"2025-02-07T04:41:47.836Z","updatedAt":null,"position":196605,"name":"GFX 2025","projectId":"1434588557086820006"}	2025-02-07 04:42:03.106	\N
1442584635920877422	board	1442584604690089836	{"id":"1442584604690089836","createdAt":"2025-02-10T04:18:05.839Z","updatedAt":null,"position":196605,"name":"ChatFootball","projectId":"1430501293201294342"}	2025-02-10 04:18:09.564	\N
1442645926412814228	attachment	1434085275486652052	{"id":"1434085275486652052","createdAt":"2025-01-29T10:51:26.842Z","updatedAt":null,"dirname":"97e64354-34df-4f10-89b8-489067bd1819","filename":"Cerezo Chinese new year.psd","image":null,"name":"Cerezo Chinese new year.psd","cardId":"1434038848156862074","creatorUserId":"1433261799410501042"}	2025-02-10 06:19:55.957	\N
1442645947484997525	attachment	1434729227936073466	{"id":"1434729227936073466","createdAt":"2025-01-30T08:10:51.958Z","updatedAt":null,"dirname":"0fa4d715-8592-4baf-9e6a-a5c802c18835","filename":"Cerezo Chinese new year.psd","image":null,"name":"Cerezo Chinese new year.psd","cardId":"1434038848156862074","creatorUserId":"1433261799410501042"}	2025-02-10 06:19:58.472	\N
1442648888480630687	card	1433318486083372529	{"id":"1433318486083372529","createdAt":"2025-01-28T09:27:58.422Z","updatedAt":"2025-01-28T09:28:23.080Z","position":851955,"name":"Discovering Osaka Derby","description":"Final Drive: https://drive.google.com/drive/folders/1U8VR9XgxCtzc_wcMbq3mEbkpm-SO7Gdj?role=writer","dueDate":"2025-02-07T05:00:00.000Z","isDueDateCompleted":false,"stopwatch":null,"boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1430525186381186093","coverAttachmentId":null}	2025-02-10 06:25:49.064	\N
1443332504223220748	card	1443317461578418171	{"id":"1443317461578418171","createdAt":"2025-02-11T04:34:09.189Z","updatedAt":"2025-02-11T05:03:59.410Z","position":1376235,"name":"Shotlist","description":null,"dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"estimatedHours":"5:0","actualHours":null,"complexity":null,"priority":null,"percentComplete":null,"isBlocked":null,"startDate":"2025-02-10T17:00:00.000Z","endDate":"2025-02-13T17:00:00.000Z","boardId":"1433174649205687643","listId":"1433174831095874911","creatorUserId":"1433172478670144855","coverAttachmentId":null}	2025-02-11 05:04:02.41	\N
1443465498606961801	card	1443391480080106525	{"id":"1443391480080106525","createdAt":"2025-02-11T07:01:12.880Z","updatedAt":"2025-02-11T07:10:39.194Z","position":65535,"name":"GFX for 2025 season (wait for approval)","description":"Lists of GFX for sending to approve.\\n\\n.\\n.\\n\\nEach GFX estimated to take 2 hours/day","dueDate":null,"isDueDateCompleted":null,"stopwatch":null,"estimatedHours":null,"actualHours":null,"complexity":null,"priority":null,"percentComplete":null,"isBlocked":false,"startDate":null,"endDate":null,"boardId":"1434609694726424238","listId":"1434615722369091251","creatorUserId":"1434720470833301219","coverAttachmentId":"1443396230532039730"}	2025-02-11 09:28:16.577	\N
1443466769103586442	attachment	1443463343875556481	{"id":"1443463343875556481","createdAt":"2025-02-11T09:23:59.712Z","updatedAt":null,"dirname":"33e774c0-de44-43db-b676-e03753477f79","filename":"image.png","image":{"width":1080,"height":1350,"thumbnailsExtension":"png"},"name":"image.png","cardId":"1443458771580879980","creatorUserId":"1434720470833301219"}	2025-02-11 09:30:48.031	\N
\.


--
-- Data for Name: attachment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.attachment (id, card_id, creator_user_id, dirname, filename, name, created_at, updated_at, image) FROM stdin;
1430520669526819874	1430519898227868700	1430480385812202497	c768c1d1-1093-4de7-92ab-7e08f091c07c	logo-white-1x.png	logo-white-1x.png	2025-01-24 12:49:12.698	\N	{"width": 138, "height": 122, "thumbnailsExtension": "png"}
1432376384730170607	1432375308748588264	1430501158790628357	af1ce320-6ab1-4b8f-9c6b-4ac532e13ed9	Screenshot 2025-01-27 at 9.16.01 AM.png	Screenshot 2025-01-27 at 9.16.01 AM.png	2025-01-27 02:16:11.186	\N	{"width": 1364, "height": 588, "thumbnailsExtension": "png"}
1432377235284690171	1432377073594270965	1430501158790628357	f4c4f03f-eec9-477f-8497-d44a11a187e6	Screenshot 2025-01-27 at 9.17.44 AM.png	Screenshot 2025-01-27 at 9.17.44 AM.png	2025-01-27 02:17:52.586	\N	{"width": 666, "height": 298, "thumbnailsExtension": "png"}
1432377384509637884	1432377136022291704	1430501158790628357	155ea0fa-57b4-4144-9eea-492b7d587162	Screenshot 2025-01-27 at 9.18.04 AM.png	Screenshot 2025-01-27 at 9.18.04 AM.png	2025-01-27 02:18:10.372	\N	{"width": 574, "height": 288, "thumbnailsExtension": "png"}
1432377465073829117	1432376915628393714	1430501158790628357	901ba7f5-c985-40a2-bbbb-49235fe30d65	Screenshot 2025-01-27 at 9.18.12 AM.png	Screenshot 2025-01-27 at 9.18.12 AM.png	2025-01-27 02:18:19.979	\N	{"width": 1424, "height": 146, "thumbnailsExtension": "png"}
1432377633550632190	1432376915628393714	1430501158790628357	77fab7da-6174-4862-93bd-efd76d1ebe88	Screenshot 2025-01-27 at 9.18.33 AM.png	Screenshot 2025-01-27 at 9.18.33 AM.png	2025-01-27 02:18:40.06	\N	{"width": 1358, "height": 104, "thumbnailsExtension": "png"}
1432380060643362050	1432379457754105087	1430501158790628357	e7c1ab34-baeb-45d2-b9ab-a71b513aa71d	Screenshot 2025-01-27 at 9.23.25 AM.png	Screenshot 2025-01-27 at 9.23.25 AM.png	2025-01-27 02:23:29.392	\N	{"width": 1470, "height": 912, "thumbnailsExtension": "png"}
1432414120556102919	1432413910664742148	1430501158790628357	2871c967-d855-49bb-96ae-6a511f48a86d	Screenshot 2025-01-27 at 10.31.07 AM.png	Screenshot 2025-01-27 at 10.31.07 AM.png	2025-01-27 03:31:09.65	\N	{"width": 564, "height": 420, "thumbnailsExtension": "png"}
1432466530741781784	1432466460956951829	1430501158790628357	86ecfbb4-0424-4de8-b498-ae6c1b92b573	Screenshot 2025-01-27 at 12.15.14 PM.png	Screenshot 2025-01-27 at 12.15.14 PM.png	2025-01-27 05:15:17.434	\N	{"width": 614, "height": 254, "thumbnailsExtension": "png"}
1432467619197224223	1432467553304708380	1430501158790628357	4d6de1e4-74ff-4742-9dfb-efa2749dc526	Screenshot 2025-01-27 at 12.17.24 PM.png	Screenshot 2025-01-27 at 12.17.24 PM.png	2025-01-27 05:17:27.187	\N	{"width": 1210, "height": 160, "thumbnailsExtension": "png"}
1433301087372182987	1433300241649501641	1430525186381186093	bae8c7b0-9072-4715-bf07-3c0aab951b79	image.png	image.png	2025-01-28 08:53:24.334	\N	{"width": 1000, "height": 667, "thumbnailsExtension": "png"}
1433309758743381461	1433303096687068625	1430525186381186093	7be2a4c2-ff11-4d0f-b2f9-eebf46e3c275	EN.png	EN.png	2025-01-28 09:10:38.042	\N	{"width": 2159, "height": 2700, "thumbnailsExtension": "png"}
1433314651566769635	1433314479944238559	1430525186381186093	b25518d4-3c6c-4e07-8e1d-893f6c708b57	Worldwide cerezo osaka.jpg	Worldwide cerezo osaka.jpg	2025-01-28 09:20:21.312	\N	{"width": 4404, "height": 1875, "thumbnailsExtension": "jpg"}
1434083557004805775	1434038848156862074	1430525186381186093	2b14ccd9-818c-420d-98c2-5d6f5969a9b0	image (2).png	image (2).png	2025-01-29 10:48:01.978	\N	{"width": 1080, "height": 1380, "thumbnailsExtension": "png"}
1443395356120319025	1443392055991600171	1434720470833301219	9e2fa28f-6342-40f3-8d63-8eb9ec39d000	image.png	image.png	2025-02-11 07:08:54.941	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443396230532039730	1443391480080106525	1434720470833301219	e8f0255e-017e-47a4-9254-206d60360ab1	GFX-for-2025-1.png	GFX-for-2025-1.png	2025-02-11 07:10:39.179	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443396233509995571	1443391480080106525	1434720470833301219	da132e17-c08c-41d3-bd35-a18b74faaa15	GFX-for-2025-2.png	GFX-for-2025-2.png	2025-02-11 07:10:39.536	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443396236647334964	1443391480080106525	1434720470833301219	4dbb03db-b053-4dbc-bb99-0e31ec4dfb57	GFX-for-2025-3.png	GFX-for-2025-3.png	2025-02-11 07:10:39.909	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443396238945813557	1443391480080106525	1434720470833301219	10fc819a-b10e-49bf-9b03-bfced0e3bca5	GFX-for-2025-4.png	GFX-for-2025-4.png	2025-02-11 07:10:40.181	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443396241336566838	1443391480080106525	1434720470833301219	3766a757-b679-4593-bf68-3c23cfab4a23	GFX-for-2025-5.png	GFX-for-2025-5.png	2025-02-11 07:10:40.469	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443396727313794109	1443396623278277691	1434720470833301219	16eb3c83-53f6-4aa0-91aa-8f3b83a0df05	SNS.png	SNS.png	2025-02-11 07:11:38.401	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443397119061787714	1443396872721925182	1434720470833301219	c8af599b-7dc4-4c6e-bc68-7de641d9e788	Home-Grown content.png	Home-Grown content.png	2025-02-11 07:12:25.1	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443397375702860869	1443397194441819203	1434720470833301219	2f47b9b8-8777-490e-a482-3404d698552e	Cover.png	Cover.png	2025-02-11 07:12:55.694	\N	{"width": 1640, "height": 720, "thumbnailsExtension": "png"}
1443397714460017743	1443397437266854982	1434720470833301219	2cf79620-7713-467a-9e4d-600a07686f85	calendar.png	calendar.png	2025-02-11 07:13:36.077	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443410923631936606	1443410876563457116	1434720470833301219	94b8b914-54b1-4246-9c85-44ff5e89c77c	image.png	image.png	2025-02-11 07:39:50.734	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443457807209727079	1443457772355060837	1434720470833301219	a8602ab3-c5fd-473a-8a2f-a72b2e5b192f	image.png	image.png	2025-02-11 09:12:59.693	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443458794414670958	1443458771580879980	1434720470833301219	b78f053f-1b75-4045-bd75-42c1bc24a4ba	image.png	image.png	2025-02-11 09:14:57.376	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443459980622562421	1443459936733365363	1434720470833301219	3ba68455-d3d2-4512-ac99-6f9802a716f4	image.png	image.png	2025-02-11 09:17:18.784	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443460794183320700	1443460766970676346	1434720470833301219	a95031f5-297f-47fd-a67c-cc0ea8e978c3	image.png	image.png	2025-02-11 09:18:55.768	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443463714693973124	1443463685484840066	1434720470833301219	2c85e1c2-c544-47fa-b828-7011d7c2b985	image.png	image.png	2025-02-11 09:24:43.92	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1443466797910066315	1443458771580879980	1434720470833301219	62ef27ec-264f-4ad4-9bc6-6d01c8454d8f	image.png	image.png	2025-02-11 09:30:51.468	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1692106007863362759	1692095657243837637	1430525186381186093	c20e1827-9bd3-4fab-8645-93b5017a3354	Artboard 1.png	Artboard 1.png	2026-01-20 10:52:35.036	\N	{"width": 1080, "height": 1350, "thumbnailsExtension": "png"}
1692111645930685648	1692095657243837637	1433172478670144855	b9f464ea-3bd2-465b-9e0f-a0088981f86c	image.png	ไม่ Align	2026-01-20 11:03:47.146	2026-01-20 11:04:19.272	{"width": 1424, "height": 1764, "thumbnailsExtension": "png"}
1692112401912038609	1692095657243837637	1433172478670144855	13494165-51ae-4dcd-9975-6e01c5bd3090	image.png	POINT ขนาดกับความหนาไม่เท่ากัน	2026-01-20 11:05:17.267	2026-01-20 11:05:30.407	{"width": 1422, "height": 1774, "thumbnailsExtension": "png"}
1692118570030335186	1692095657243837637	1433172478670144855	85195504-f9dd-4f9f-af7c-3a7487b4da89	image.png	2 POINTS?	2026-01-20 11:17:32.565	2026-01-20 11:17:42.459	{"width": 1422, "height": 1756, "thumbnailsExtension": "png"}
1692119310660535507	1692095657243837637	1433172478670144855	c4a67f93-8bdc-4ace-9804-ee6674216054	image.png	MITO match วันที่ 8 รึป่าว?	2026-01-20 11:19:00.855	2026-01-20 11:19:28.864	{"width": 1410, "height": 1758, "thumbnailsExtension": "png"}
1692120162255242452	1692095657243837637	1433172478670144855	3b86ce2c-e764-43ca-b3ed-1b267d337480	image.png	ตั้งใจให้เส้นงอๆใช่มั้ยคะ	2026-01-20 11:20:42.373	2026-01-20 11:21:39.606	{"width": 1404, "height": 1748, "thumbnailsExtension": "png"}
1692123045847631061	1692095657243837637	1433172478670144855	2d8d7a94-219b-4618-9e35-837cbd5e9741	image.png	Align	2026-01-20 11:26:26.123	2026-01-20 11:26:43.856	{"width": 1404, "height": 1756, "thumbnailsExtension": "png"}
\.


--
-- Data for Name: board; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.board (id, project_id, "position", name, created_at, updated_at) FROM stdin;
1432374743171859682	1432374492235039965	65535	30 Clubs Presentation	2025-01-27 02:12:55.5	\N
1434609694726424238	1434588557086820006	65535	SNS	2025-01-30 04:13:22.488	\N
1434610219668735665	1434588557086820006	131070	REPORT	2025-01-30 04:14:25.066	\N
1434692932727736004	1434609486756054700	65535	Project	2025-01-30 06:58:45.23	\N
1434703208386660040	1434589041889642152	65535	Mizuno Projects	2025-01-30 07:19:10.184	2025-02-05 03:26:22.486
1438940137017836646	1438939577170527330	65535	Ladderice	2025-02-05 03:37:11.435	\N
1433174649205687643	1433174555865646425	65535	Cerezo Osaka	2025-01-28 04:42:11.731	2025-02-05 03:55:44.88
1442584220726724453	1430501293201294342	131070	Ladderice	2025-02-10 04:17:20.065	\N
1430501369143362568	1430501293201294342	65535	ChatFootball	2025-01-24 12:10:51.916	2025-02-10 04:18:15.529
1442584975609169775	1430501293201294342	196605	Turfmapp	2025-02-10 04:18:50.056	\N
1692048962560722096	1692048917312570542	65535	Q1 2026	2026-01-20 08:59:14.711	\N
\.


--
-- Data for Name: board_membership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.board_membership (id, board_id, user_id, created_at, updated_at, role, can_comment) FROM stdin;
1430501575033357322	1430501369143362568	1430501158790628357	2025-01-24 12:11:16.457	\N	editor	\N
1430525382833996847	1430501369143362568	1430525186381186093	2025-01-24 12:58:34.57	\N	editor	\N
1432374743280911587	1432374743171859682	1430501158790628357	2025-01-27 02:12:55.508	\N	editor	\N
1432438708178519308	1432374743171859682	1430525186381186093	2025-01-27 04:20:00.724	\N	editor	\N
1432468472838751521	1432374743171859682	1430534043199341650	2025-01-27 05:19:08.948	\N	editor	\N
1433096772799956288	1430501369143362568	1432141375276582075	2025-01-28 02:07:28.139	\N	editor	\N
1433096807545570625	1430501369143362568	1430534043199341650	2025-01-28 02:07:32.284	\N	editor	\N
1433174649239242076	1433174649205687643	1430525186381186093	2025-01-28 04:42:11.737	\N	editor	\N
1433228526248527229	1433174649205687643	1430534043199341650	2025-01-28 06:29:14.375	2025-01-28 08:43:17.643	editor	\N
1433296144309421511	1433174649205687643	1433261799410501042	2025-01-28 08:43:35.076	\N	editor	\N
1433284347124778434	1433174649205687643	1433171377464018261	2025-01-28 08:20:08.741	2025-01-28 08:43:39.261	editor	\N
1433257688044668327	1433174649205687643	1433172478670144855	2025-01-28 07:27:10.73	2025-01-28 08:43:44.863	editor	\N
1433220429547308410	1433174649205687643	1433172244418266454	2025-01-28 06:13:09.173	2025-01-28 08:43:49.469	viewer	t
1434609694759978671	1434609694726424238	1433172244418266454	2025-01-30 04:13:22.494	\N	editor	\N
1434610009248892592	1434609694726424238	1430534043199341650	2025-01-30 04:13:59.982	\N	editor	\N
1434610219710678706	1434610219668735665	1433172244418266454	2025-01-30 04:14:25.073	\N	editor	\N
1434692932761290437	1434692932727736004	1433172244418266454	2025-01-30 06:58:45.237	\N	editor	\N
1434693102227949254	1434692932727736004	1433172478670144855	2025-01-30 06:59:05.437	\N	editor	\N
1434693143625729735	1434692932727736004	1433171377464018261	2025-01-30 06:59:10.374	\N	editor	\N
1434703208445380297	1434703208386660040	1433172244418266454	2025-01-30 07:19:10.193	\N	editor	\N
1434703391778408138	1434703208386660040	1430525186381186093	2025-01-30 07:19:32.047	\N	editor	\N
1434703461412243147	1434609694726424238	1430525186381186093	2025-01-30 07:19:40.35	\N	editor	\N
1434706962557175509	1434703208386660040	1433172478670144855	2025-01-30 07:26:37.719	\N	editor	\N
1434707048943060694	1434703208386660040	1430501158790628357	2025-01-30 07:26:48.017	\N	editor	\N
1434707219928057560	1434703208386660040	1433297069220562376	2025-01-30 07:27:08.398	\N	editor	\N
1434708049838212825	1434609694726424238	1433261799410501042	2025-01-30 07:28:47.331	\N	editor	\N
1435352822903211812	1433174649205687643	1435352068222093091	2025-01-31 04:49:50.269	\N	editor	\N
1438934322093491238	1434703208386660040	1435352068222093091	2025-02-05 03:25:38.246	\N	editor	\N
1438934353122952231	1434703208386660040	1433261799410501042	2025-02-05 03:25:41.946	\N	editor	\N
1438934407380468780	1434703208386660040	1432141375276582075	2025-02-05 03:25:48.413	\N	editor	\N
1438940137059779687	1438940137017836646	1433172478670144855	2025-02-05 03:37:11.444	\N	editor	\N
1438940186711950441	1438940137017836646	1435352068222093091	2025-02-05 03:37:17.363	\N	editor	\N
1438940219746288747	1438940137017836646	1433297069220562376	2025-02-05 03:37:21.301	\N	editor	\N
1438940248829592684	1438940137017836646	1433171377464018261	2025-02-05 03:37:24.768	\N	editor	\N
1438940484390093936	1438940137017836646	1430501158790628357	2025-02-05 03:37:52.85	\N	editor	\N
1438945407295030401	1433174649205687643	1433297069220562376	2025-02-05 03:47:39.703	\N	editor	\N
1439671385474467343	1434610219668735665	1430501158790628357	2025-02-06 03:50:03.046	\N	editor	\N
1439671483596015120	1434610219668735665	1430534043199341650	2025-02-06 03:50:14.743	\N	editor	\N
1439834280162232013	1433174649205687643	1430501158790628357	2025-02-06 09:13:41.606	2025-02-06 09:56:50.734	editor	\N
1440554448484042588	1434610219668735665	1430525186381186093	2025-02-07 09:04:32.36	\N	editor	\N
1442584372459865960	1442584220726724453	1435352068222093091	2025-02-10 04:17:38.157	\N	editor	\N
1442584429888276330	1442584220726724453	1430501158790628357	2025-02-10 04:17:45.003	\N	editor	\N
1442584451748988779	1442584220726724453	1430525186381186093	2025-02-10 04:17:47.609	\N	editor	\N
1442587468955125630	1442584975609169775	1430501158790628357	2025-02-10 04:23:47.288	\N	editor	\N
1442587497845491583	1442584975609169775	1430525186381186093	2025-02-10 04:23:50.732	\N	editor	\N
1442587523338471296	1442584975609169775	1430534043199341650	2025-02-10 04:23:53.771	\N	editor	\N
1692048962594276529	1692048962560722096	1430525186381186093	2026-01-20 08:59:14.715	\N	editor	\N
1692049023789171890	1692048962560722096	1692047903306024107	2026-01-20 08:59:22.01	\N	viewer	t
1692049052436268211	1692048962560722096	1435352068222093091	2026-01-20 08:59:25.425	\N	editor	\N
1692049087500649652	1692048962560722096	1433172244418266454	2026-01-20 08:59:29.605	\N	editor	\N
1692049118018405557	1692048962560722096	1433172478670144855	2026-01-20 08:59:33.242	\N	editor	\N
1692049163727930550	1692048962560722096	1433261799410501042	2026-01-20 08:59:38.692	\N	editor	\N
1692049188390438071	1692048962560722096	1433171377464018261	2026-01-20 08:59:41.632	\N	editor	\N
1692049223328990392	1692048962560722096	1430501158790628357	2026-01-20 08:59:45.797	\N	editor	\N
1692049258611475641	1692048962560722096	1433297069220562376	2026-01-20 08:59:50.002	\N	editor	\N
1692049284398056634	1692048962560722096	1430534043199341650	2026-01-20 08:59:53.077	\N	editor	\N
\.


--
-- Data for Name: card; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.card (id, board_id, list_id, creator_user_id, cover_attachment_id, "position", name, description, due_date, stopwatch, created_at, updated_at, is_due_date_completed, estimated_hours, actual_hours, complexity, priority, percent_complete, is_blocked, start_date, end_date) FROM stdin;
1432466460956951829	1432374743171859682	1432374918888031461	1430501158790628357	1432466530741781784	16383.75	BOLD issue	\N	\N	\N	2025-01-27 05:15:09.113	2025-01-27 07:51:57.108	\N	\N	\N	\N	\N	\N	f	\N	\N
1432467553304708380	1432374743171859682	1432374918888031461	1430501158790628357	1432467619197224223	8191.875	J1, J2, J3	\N	\N	\N	2025-01-27 05:17:19.331	2025-01-27 07:51:58.797	\N	\N	\N	\N	\N	\N	f	\N	\N
1439036641913079179	1434703208386660040	1434704734609999566	1433172478670144855	\N	1181678	Finalize Storyboard Origin	\N	\N	\N	2025-02-05 06:48:55.717	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1439035918395639165	1434703208386660040	1434704734609999566	1433172244418266454	\N	1048560	Pre-production / Final Storyboard Ruby red	Pre-production\n* Finalize \n\t\t\t* Storyboard\n\t\t\t* Equipment list\n\t\t\t* Shot list\n\t\t\t* Moodboard\n\t\t\t* Model / actor\n\t\t\t* Prop\n\t\t\t* Shooting plan\n\nNote:\n* Ruby Red + Origin >> P'MAC -- DP + Video\n* วัดขนาด subject ออกจากฉาก ให้พี่แบงค์	\N	\N	2025-02-05 06:47:29.467	2025-02-05 07:30:33.015	\N	\N	\N	\N	\N	\N	f	\N	\N
1432126863186068574	1430501369143362568	1430531972286907461	1430480385812202497	\N	65535	Custom ReAct Agent	\N	\N	\N	2025-01-26 18:00:25.904	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432132167101580422	1430501369143362568	1430502915348366349	1430480385812202497	\N	131070	Terms & Policies Page	\N	\N	\N	2025-01-26 18:10:58.18	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432131205364450429	1430501369143362568	1430502915348366349	1430480385812202497	\N	65535	Terms and policies text	\N	\N	\N	2025-01-26 18:09:03.529	2025-01-26 18:11:10.484	\N	\N	\N	\N	\N	\N	f	\N	\N
1432133165018776718	1430501369143362568	1430502915348366349	1430480385812202497	\N	196605	Profile Page	\N	\N	\N	2025-01-26 18:12:57.14	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432133249383007377	1430501369143362568	1430502915348366349	1430480385812202497	\N	262140	Logout Feature	\N	\N	\N	2025-01-26 18:13:07.2	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432133309344777364	1430501369143362568	1430502915348366349	1430480385812202497	\N	327675	Change Password Feature	\N	\N	\N	2025-01-26 18:13:14.348	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1433314479944238559	1433174649205687643	1433174865606608225	1430525186381186093	1433314651566769635	3583.9453125	Cerezo Osaka INTL Instagram Opening Post	Final Drive: https://drive.google.com/drive/folders/1fhvzHlFCQ4FF3bD1AJLRFBvBYr0aDCbq?role=writer	\N	\N	2025-01-28 09:20:00.852	2025-02-05 03:20:18.615	\N	\N	\N	\N	\N	\N	f	\N	\N
1433235122395547021	1433174649205687643	1433192321335166328	1430525186381186093	\N	65535	Jaroensak's Interview (in Night Wolf jersey) 🇹🇭	Final Drive: https://drive.google.com/drive/folders/13wuo27OmCD0PKunUhHnQrMWkFngOzy4y?role=writer	2025-01-28 08:00:00	\N	2025-01-28 06:42:20.696	2025-01-29 10:50:46.161	t	\N	\N	\N	\N	\N	f	\N	\N
1432143088423273660	1430501369143362568	1430502915348366349	1430480385812202497	\N	524280	Test report and score	\N	\N	\N	2025-01-26 18:32:40.102	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432144454029935809	1430501369143362568	1430502915348366349	1430480385812202497	\N	589815	Postgres sync between DEV and PROD	\N	\N	\N	2025-01-26 18:35:22.896	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432154072584029393	1430501369143362568	1430502915348366349	1430480385812202497	\N	720885	Docker & Docker Compose	Get familiar with Docker and Docker Compose.	\N	\N	2025-01-26 18:54:29.516	2025-01-26 18:55:13.89	\N	\N	\N	\N	\N	\N	f	\N	\N
1438219198076553102	1442584975609169775	1442585390165788529	1430480385812202497	\N	65535	Merge Turfmapp AI and Planka	\N	\N	\N	2025-02-04 03:44:48.813	2025-02-10 04:24:46.837	\N	\N	\N	\N	\N	\N	f	\N	\N
1432151592458519753	1430501369143362568	1430502915348366349	1430480385812202497	\N	655350	Postgres on Docker VS Digital Ocean VS Suprabase	Compare Pros/cons of Postgres on each platform also the price if we have to switch to one of them	\N	\N	2025-01-26 18:49:33.862	2025-01-26 19:01:49.102	\N	\N	\N	\N	\N	\N	f	\N	\N
1432671734758114616	1430501369143362568	1430532330472080457	1430524402960696364	\N	131070	Automate RAG from Google Sheet	\N	\N	\N	2025-01-27 12:02:59.659	2025-01-30 03:16:08.651	\N	\N	\N	\N	\N	\N	f	\N	\N
1432128234438263911	1430501369143362568	1430532224431686727	1430480385812202497	\N	131070	MLS Clubs and Stadium RAG	\N	\N	\N	2025-01-26 18:03:09.37	2025-01-27 12:02:54.27	\N	\N	\N	\N	\N	\N	f	\N	\N
1433261051297662384	1433174649205687643	1433192440268850553	1430525186381186093	\N	2047.96875	Shunta Tanaka's Interview	Final Drive: https://drive.google.com/drive/folders/1n8o6pZ5nsdj3OX7i1sne1Z9Uigj3cKR9?role=writer	2025-02-01 09:00:00	\N	2025-01-28 07:33:51.663	2025-02-04 10:29:10.269	t	\N	\N	\N	\N	\N	f	\N	\N
1432377136022291704	1432374743171859682	1432376741665441009	1430501158790628357	1432377384509637884	196605	DID YOU KNOW Alignmnet	\N	\N	\N	2025-01-27 02:17:40.753	2025-01-27 02:18:10.383	\N	\N	\N	\N	\N	\N	f	\N	\N
1432379457754105087	1432374743171859682	1432376741665441009	1430501158790628357	1432380060643362050	262140	Club color doesn't match	\N	\N	\N	2025-01-27 02:22:17.521	2025-01-27 02:23:29.403	\N	\N	\N	\N	\N	\N	f	\N	\N
1432128678245958769	1430501369143362568	1430532330472080457	1430480385812202497	\N	65535	Automation Script for  data pulling	\N	\N	\N	2025-01-26 18:04:02.273	2025-01-27 12:03:13.562	\N	\N	\N	\N	\N	\N	f	\N	\N
1433316650974709223	1433174649205687643	1433192158453564789	1430525186381186093	\N	16383.75	Jaroensak's Top 5 Facts 🇹🇭	Final Drive: https://drive.google.com/drive/folders/1RNayy42tfZLomW-qTiLlrxP0nqL6xRiZ?role=writer	\N	\N	2025-01-28 09:24:19.66	2025-02-07 03:35:36.483	\N	\N	\N	\N	\N	\N	f	\N	\N
1433254977265993112	1433174649205687643	1433255711814452638	1430525186381186093	\N	131070	Discovering Cerezo Osaka - Vintage Mizuno Jerseys	Final Drive: https://drive.google.com/drive/folders/1J-CaUU4RaUGuNWfUPObCqmd9i7cxevGv?role=writer	\N	\N	2025-01-28 07:21:47.582	2025-02-03 10:57:17.483	\N	\N	\N	\N	\N	\N	f	\N	\N
1439082514009294291	1434703208386660040	1434704734609999566	1433172244418266454	\N	1445866	Workshop 1 heat-transfer and patches	\N	\N	\N	2025-02-05 08:20:04.097	2025-02-05 08:22:44.237	\N	\N	\N	\N	\N	\N	f	\N	\N
1439088141725074919	1434703208386660040	1434704734609999566	1433172244418266454	\N	1708006	Event space mapping and mock up	\N	\N	\N	2025-02-05 08:31:14.973	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1432377073594270965	1432374743171859682	1432374918888031461	1430501158790628357	1432377235284690171	65535	BALANCE SHEET OVERVIEW Alignment	\N	\N	\N	2025-01-27 02:17:33.307	2025-01-27 04:56:49.086	\N	\N	\N	\N	\N	\N	f	\N	\N
1432413910664742148	1432374743171859682	1432374918888031461	1430501158790628357	1432414120556102919	32767.5	FINANCIAL SUMMARY ALIGNMENT	\N	\N	\N	2025-01-27 03:30:44.63	2025-01-27 04:57:14.301	\N	\N	\N	\N	\N	\N	f	\N	\N
1433271312972776888	1433174649205687643	1433174831095874911	1430525186381186093	\N	393210	Discovering Cerezo Osaka - Lobby & Madam Lobina	Final Drive: https://drive.google.com/drive/folders/117Q7o6F4tr7YvlVDqP-8uE89GSGFRA3p?role=writer\n\nOld Drive: https://drive.google.com/drive/u/0/folders/15HZenHO67oXANBs_JtStVpP0pHa_i6Rq	\N	\N	2025-01-28 07:54:14.949	2025-02-03 10:57:43.13	\N	\N	\N	\N	\N	\N	f	\N	\N
1438959873944454336	1438940137017836646	1438949766678447278	1433172877045138776	\N	131070	Bled Fc	Heat เสื้อที่เหลือตามตัว Prototype	\N	\N	2025-02-05 04:16:24.26	2025-02-05 11:43:24.549	\N	\N	\N	\N	\N	\N	f	\N	\N
1434037967428519538	1433174649205687643	1433192440268850553	1433171377464018261	\N	16383.75	RECAP PHOTOS - Cerezo Cherry-OT #5	Final Drive : https://drive.google.com/drive/folders/1O7mvMdWSwkC57v293kJ28jhq5zTFBNL2?usp=drive_link	2025-01-31 09:00:00	\N	2025-01-29 09:17:27.282	2025-02-03 10:59:36.429	t	\N	\N	\N	\N	\N	f	\N	\N
1432138030939899056	1430501369143362568	1430532224431686727	1430480385812202497	\N	196605	RAG insert script	Prepare the script to convert data from RAG insert UI to make Contextual RAG via LLM and store into vector db	\N	\N	2025-01-26 18:22:37.204	2025-01-28 03:13:33.165	\N	\N	\N	\N	\N	\N	f	\N	\N
1439644478963975691	1433174649205687643	1433174865606608225	1430534043199341650	\N	4927.9248046875	Di-Cut all players for Matchday	\N	\N	\N	2025-02-06 02:56:35.54	2025-02-07 03:36:34.902	\N	\N	\N	\N	\N	\N	f	\N	\N
1439689109495875119	1433174649205687643	1440417324245976864	1433172478670144855	\N	65535	Meeting with Pak-san for Cerezo Cup 10th	02/02/2025\n12:30 ICT	\N	\N	2025-02-06 04:25:15.913	2025-02-07 04:32:08.514	\N	\N	\N	\N	\N	\N	f	\N	\N
1437711172743726910	1433174649205687643	1433192440268850553	1430525186381186093	\N	127.998046875	RECAP REEL - Cerezo Cherry-OT #5	Final Drive: https://drive.google.com/drive/u/0/folders/1qd_8B36-ZzlH5OLJjtXV5vD_SBkF0Kkr\n\nAssets: https://drive.google.com/drive/folders/1apHw_vMrjyZNjl4QTYPcX7HInhQqahWe?role=writer	\N	\N	2025-02-03 10:55:27.478	2025-02-07 03:45:40.14	\N	\N	\N	\N	\N	\N	f	\N	\N
1433241292510332304	1433174649205687643	1433192440268850553	1430525186381186093	\N	31.99951171875	10 Days To Go Until 2025 J1 League	Final Drive: https://drive.google.com/drive/folders/1M2-LOUoStWRl47R7xujG2yTPFUKk40wQ?role=writer	2025-02-04 05:00:00	\N	2025-01-28 06:54:36.232	2025-02-07 04:56:06.355	t	\N	\N	\N	\N	\N	f	\N	\N
1442592812120934273	1442584975609169775	1442585390165788529	1430480385812202497	\N	131070	Planka custom view with filter	\N	\N	\N	2025-02-10 04:34:24.239	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1442647951951267739	1433174649205687643	1433192158453564789	1430525186381186093	\N	81918.75	Team's captain Shunta Tanaka on Cerezo's 2025 goal	Final Drive: https://drive.google.com/drive/folders/1skMOTQz4FQ6PQzBRjZI-beASG-tr09vz?role=writer	\N	\N	2025-02-10 06:23:57.421	2025-02-10 06:24:20.662	\N	\N	\N	\N	\N	\N	f	\N	\N
1438221738298050461	1430501369143362568	1430532224431686727	1430480385812202497	\N	262140	ChatFootball new AI model	\N	\N	\N	2025-02-04 03:49:51.635	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438986240270533869	1434703208386660040	1434704734609999566	1433172244418266454	\N	720885	Summit Room 5 Photobooth / Brand Book	\N	\N	\N	2025-02-05 05:08:47.373	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438218124980651878	1430501369143362568	1430532224431686727	1430480385812202497	\N	327675	Get familiar with Redux	\N	\N	\N	2025-02-04 03:42:40.895	2025-02-11 03:25:22.41	\N	\N	\N	\N	\N	\N	f	\N	\N
1439067056858203586	1434703208386660040	1434703542295201484	1433172478670144855	\N	159741.5625	Check list	Pre-production \nTest shoot\nProduction\nPost-production\nDelivery #1 -- \nDelivery #2	\N	\N	2025-02-05 07:49:21.46	2025-02-11 03:53:31.179	\N	\N	\N	\N	\N	\N	f	\N	\N
1432136214110012584	1430501369143362568	1430532616615887950	1430480385812202497	\N	65535	RAG insert UI	Admin Panel already have the form and page called `Source` which exported from prototype.	\N	\N	2025-01-26 18:19:00.621	2025-02-11 05:55:30.362	\N	\N	\N	\N	\N	\N	t	\N	\N
1438219109073422219	1430501369143362568	1430532330472080457	1430480385812202497	\N	32767.5	Custom Planka	\N	\N	\N	2025-02-04 03:44:38.208	2025-02-11 05:55:50.926	\N	\N	\N	\N	\N	\N	f	\N	\N
1438219017729869704	1442584975609169775	1442585734761416565	1430480385812202497	\N	65535	Turfmapp AI	\N	\N	\N	2025-02-04 03:44:27.318	2025-02-12 03:26:15.93	\N	\N	\N	\N	\N	\N	f	\N	\N
1433323812958504456	1433174649205687643	1433174831095874911	1430525186381186093	\N	1179630	RECAP PHOTOS vs G-OS (MW1)	Final Drive: https://drive.google.com/drive/folders/1O4EKofzt8Mf247swe4ke_IhWzE2VAuUx?role=writer	2025-02-14 17:00:00	\N	2025-01-28 09:38:33.436	2025-01-28 09:40:29.548	f	\N	\N	\N	\N	\N	f	\N	\N
1433326151408813580	1433174649205687643	1433174831095874911	1430525186381186093	\N	1245165	Jaroensak's THIS or THAT 🇹🇭	Final Drive: https://drive.google.com/drive/folders/18VWMJHAIGtUkjAyl_lfkoEmb8Qs_sREc?role=writer	\N	\N	2025-01-28 09:43:12.201	2025-01-28 09:43:26.633	\N	\N	\N	\N	\N	\N	f	\N	\N
1433317255122257385	1433174649205687643	1433174831095874911	1430525186381186093	\N	720885	FIRST MATCH of 2025 J1 League	Final Drive: https://drive.google.com/drive/folders/1GW0rOSBX5psiMuxiPdQmfJFtIGtttDH9?role=writer	2025-02-07 05:00:00	\N	2025-01-28 09:25:31.679	2025-01-28 10:42:15.56	f	\N	\N	\N	\N	\N	f	\N	\N
1433259305485731246	1433174649205687643	1433192440268850553	1430525186381186093	\N	4095.9375	Lucas Fernandes' Interview	Final Drive: https://drive.google.com/drive/folders/1TUIOodrVj5yyjgYbzZwhzCsD_0NDuYF1?role=writer	\N	\N	2025-01-28 07:30:23.545	2025-02-04 10:28:51.749	\N	\N	\N	\N	\N	\N	f	\N	\N
1433228368576251259	1433174649205687643	1433192440268850553	1430525186381186093	\N	8191.875	Discovering Cerezo - The Club	Final Drive: https://drive.google.com/drive/folders/1EzSzE8c7azOXVgCMhhxXq0KmB_pCb6IC?role=writer\n\nOld Post on Facebook: https://www.facebook.com/officialcerezoosakaenglish/posts/pfbid024zG8mbGcgNL7JvCCLX7JHMADNCLxSskvLEmDiJWBNDFhLNjsje4MSzwFzaiJ2JA7l?rdid=nI5OEmc3iICgEFNx#\n\nReference: https://www.cerezo.jp/en/club/	2025-01-31 05:00:00	\N	2025-01-28 06:28:55.578	2025-02-04 10:25:06.285	t	\N	\N	\N	\N	\N	f	\N	\N
1433320073308669432	1433174649205687643	1433174865606608225	1430525186381186093	\N	6271.904296875	TOP FACTS About This Osaka Derby	Final Drive: https://drive.google.com/drive/folders/1c77HkYi6RWNb9iL5IHxHDmVV9hXxmcpX?role=writer\n\n- 2nd time played on Friday night of the opening matchweek\n- 4th (?) Osaka Derby in the opening matchweek\n- 49th Osaka Derby in J1 League\n- Hiroaki Morishima is Cerezo's top scorer in Osaka Derby\n- Arthur Papas's 1st Osaka Derby / Jareonsak's (in Thai version)	2025-02-11 05:00:00	\N	2025-01-28 09:31:07.635	2025-02-06 04:15:38.267	f	\N	\N	\N	\N	\N	f	\N	\N
1434109361990403733	1433174649205687643	1433192440268850553	1430525186381186093	\N	15.999755859375	Cerezo Osaka Merchandise Collection II	Final Drive: https://drive.google.com/drive/u/0/folders/1KPp6-u96o8ZgbGHwNzfEOs5M-CL1E6wL	\N	\N	2025-01-29 11:39:18.178	2025-02-07 05:07:59.028	\N	\N	\N	\N	\N	\N	f	\N	\N
1433320514390066684	1433174649205687643	1433192321335166328	1430525186381186093	\N	32767.5	H2H Osaka Derby	Final Drive: https://drive.google.com/drive/folders/1bMl-W4Dmv5yY30GsVUigWqvvJV3ppv3v?role=writer	\N	\N	2025-01-28 09:32:00.216	2025-02-04 10:30:48.827	\N	\N	\N	\N	\N	\N	f	\N	\N
1438322455239198641	1433174649205687643	1438421969388177351	1430525186381186093	\N	262140	2D Motion for Jaroensak	Reference link: https://www.instagram.com/reel/CubvMPDPMBd/\n\nFinal Drive: https://drive.google.com/drive/u/0/folders/1RbzfnWnTXCUWQ6PCaZSHYXgIgoX1tXpt\n\nUse Jaroensak's studio photos to create motion (optional: with paper-like die cut style, can be something else cool), similar to the reference link attached above.	\N	\N	2025-02-04 07:09:58.032	2025-02-04 10:53:20.592	\N	\N	\N	\N	\N	\N	f	\N	\N
1438931347761530876	1438929169743349745	1438929933786154997	1433172478670144855	\N	65535	Review the remaining interviews, and we’ll discuss the feelings of each part of the book on Friday.	\N	\N	\N	2025-02-05 03:19:43.675	2025-02-05 03:20:27.695	\N	\N	\N	\N	\N	\N	f	\N	\N
1439758144677873231	1434703208386660040	1434703542295201484	1433172244418266454	\N	917490	Prop Checklist	\N	\N	\N	2025-02-06 06:42:25.549	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1434026103898375761	1433174649205687643	1433192440268850553	1433171377464018261	\N	32767.5	Cerezo Cherry-OT #5\nSchool Announcement	Final Drive :https://drive.google.com/drive/folders/1HZ36HJ24T84g120L9sIYAzC4qMI1hE0W?usp=sharing	2025-01-29 05:00:00	\N	2025-01-29 08:53:53.039	2025-01-30 07:57:09.007	t	\N	\N	\N	\N	\N	f	\N	\N
1442592988768241540	1442584220726724453	1442585953032996727	1430480385812202497	\N	65535	Sale Dashboard	\N	\N	\N	2025-02-10 04:34:45.298	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1433944122544096833	1433174649205687643	1433192440268850553	1433171377464018261	\N	65535	Cerezo Cherry-OT #5 - School Guess Poster 🇹🇭	Final Drive: https://drive.google.com/drive/folders/1VB5jpX-_5UquFwzhN-BLBaKwPzdeb8Dz?role=writer	\N	\N	2025-01-29 06:11:00.099	2025-01-30 08:03:03.234	\N	\N	\N	\N	\N	\N	f	\N	\N
1434038848156862074	1433174649205687643	1433192440268850553	1430525186381186093	1434083557004805775	131070	Happy Lunar New Year	Final Drive: https://drive.google.com/drive/u/0/folders/11aXpuaokR6FB5bMsrbkhWy1wHyDfWqdw	2025-01-29 11:00:00	\N	2025-01-29 09:19:12.276	2025-01-30 08:15:30.471	t	\N	\N	\N	\N	\N	f	\N	\N
1438218506888808303	1433174649205687643	1440417324245976864	1433172478670144855	\N	131070	Cerezo Osaka Truck #5 Report	\N	\N	\N	2025-02-04 03:43:26.425	2025-02-07 04:32:24.748	\N	\N	\N	\N	\N	\N	f	\N	\N
1438218418741315436	1433174649205687643	1440417324245976864	1433172478670144855	\N	196605	Cerezo Osaka SNS Monthly Report (January)	\N	2025-02-06 05:00:00	\N	2025-02-04 03:43:15.916	2025-02-07 04:32:50.838	t	\N	\N	\N	\N	\N	f	\N	\N
1433233702573311364	1433174649205687643	1433192440268850553	1430525186381186093	\N	63.9990234375	February Calendar	Final Drive: https://drive.google.com/drive/folders/1EQtnZWUOqoOnVvWb48pBqVcK58neoxul?role=writer\n\nGamba Osaka vs **Cerezo Osaka**\n*J1 League, Matchweek 1\nFriday, February 14, 19:00 JST\nPanasonic Stadium Suita*\n\n**Cerezo Osaka** vs Shonan Bellmare\n*J1 League, Matchweek 2\nSaturday, February 22, 15:00 JST\nYodoko Sakura Stadium*\n\nKashiwa Reysol vs **Cerezo Osaka**\n*J1 League, Matchweek 3\nWednesday, February 26, 19:00 JST\nSANKYO FRONTIER Kashiwa Stadium*	2025-02-03 07:00:00	\N	2025-01-28 06:39:31.441	2025-02-07 04:41:46.255	t	\N	\N	\N	\N	\N	f	\N	\N
1433317981407938029	1433174649205687643	1433192321335166328	1430525186381186093	\N	16383.75	Vintage Photos From Osaka Derby	Final Drive: https://drive.google.com/drive/folders/1FV5ukTRozg7xisf4YFqtDzdWckDWMEVB?role=writer	\N	\N	2025-01-28 09:26:58.261	2025-02-10 06:26:59.93	\N	\N	\N	\N	\N	\N	f	\N	\N
1435346986613081875	1433174649205687643	1433174865606608225	1430525186381186093	\N	7167.890625	Cerezo Osaka Merch II - Pink Collar Workwear Shirt	Final Drive: https://drive.google.com/drive/u/0/folders/1Pdo_WtjrkNijMjVlOomIRPAhBIup-vlT	\N	\N	2025-01-31 04:38:14.53	2025-01-31 05:05:20.142	\N	\N	\N	\N	\N	\N	f	\N	\N
1438216984859772763	1430501369143362568	1430531972286907461	1430524402960696364	\N	262140	J.League automate matchday data	\N	\N	\N	2025-02-04 03:40:24.982	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438949933292979375	1438940137017836646	1438949766678447278	1433172478670144855	\N	65535	Under Armour x ACSS shooting	\N	\N	\N	2025-02-05 03:56:39.243	2025-02-05 04:09:35.644	\N	\N	\N	\N	\N	\N	f	\N	\N
1438981359895839958	1434703208386660040	1434704734609999566	1433172244418266454	\N	131070	Finalize Venue	\N	\N	\N	2025-02-05 04:59:05.587	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438979442184553672	1434703208386660040	1434703542295201484	1433172478670144855	\N	262140	Select the photo for each section in Brand Book	\N	\N	\N	2025-02-05 04:55:16.975	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438981663898993882	1434703208386660040	1434704734609999566	1433172244418266454	\N	196605	Video Editor	\N	\N	\N	2025-02-05 04:59:41.827	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438322380127602607	1433174649205687643	1438421969388177351	1430525186381186093	\N	196605	2D Motion for Osaka Derby (Next Match)	Reference link: https://youtu.be/sGy7UucSMcs?feature=shared\nRequirements\n2D motion content for\n- Next match ([TEXT](https://docs.google.com/document/d/1BGjLRxEfrgXYszX7ld9Fwrm2pSZ2_YuAZqHN9TSHUkU/edit?tab=t.0https://))\nLink of normal poster: https://www.instagram.com/p/C_QRJxfPQYT/\n\nUse studio photos of players, manager, stadium, atmosphere to create motion with paper-like die cut style, similar to the reference link attached above.\nNeed to have Cerezo emblem on the top left, CAPCOM logo on the top right, and logos of 2 teams Cerezo Osaka and Gamba Osaka.	\N	\N	2025-02-04 07:09:49.076	2025-02-04 10:46:41.151	\N	\N	\N	\N	\N	\N	f	\N	\N
1439058036135036310	1434703208386660040	1434704734609999566	1433172478670144855	\N	1249261	AG (คู่ที่หลุดมาด้วย) -- On and off the pitch	\N	\N	\N	2025-02-05 07:31:26.107	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438431374158596053	1433174649205687643	1438421969388177351	1430525186381186093	\N	229372.5	2D Motion for Osaka Derby (Matchday)	Reference link: https://youtu.be/sGy7UucSMcs?feature=shared\nRequirements\n2D motion contents for\n- Matchday ([Text](https://drive.google.com/drive/u/0/folders/1dY61uP2NCcPK54vTBnJCw2EzdR2jcmhwhttps://))\nLink of normal poster: https://www.instagram.com/p/C_2OoFvRSP0/\n\nUse studio photos of players, manager, stadium, atmosphere to create motion with paper-like die cut style, similar to the reference link attached above.\nNeed to have Cerezo emblem on the top left, CAPCOM logo on the top right, and logos of 2 teams Cerezo Osaka and Gamba Osaka.	\N	\N	2025-02-04 10:46:22.172	2025-02-04 10:47:10.293	\N	\N	\N	\N	\N	\N	f	\N	\N
1438986493950428401	1434703208386660040	1434704734609999566	1433172244418266454	\N	851955	Collector's Stories	\N	\N	\N	2025-02-05 05:09:17.614	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438986650347635955	1434703208386660040	1434704734609999566	1433172244418266454	\N	917490	MyMorelia and UGC	\N	\N	\N	2025-02-05 05:09:36.258	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1433322124021335558	1433174649205687643	1433174865606608225	1430525186381186093	\N	2687.958984375	Next Match MATCHDAY vs G-OS (MW 1)	Final Drive: https://drive.google.com/drive/folders/1dY61uP2NCcPK54vTBnJCw2EzdR2jcmhw?role=writer	2025-02-12 05:00:00	\N	2025-01-28 09:35:12.099	2025-02-11 17:25:26.759	f	\N	\N	\N	\N	\N	f	\N	\N
1438933352294908940	1434703208386660040	1434704734609999566	1433172478670144855	\N	1314796	Review the remaining interviews, and we’ll discuss the feelings of each part of the book on Friday.	**Interview Videos**\n1. Mr.Ito: https://f.io/I1Ohw7P9\n2. Mr.Chin: https://f.io/sXoLxsEV\n3. Mr.Tomita: https://f.io/40iS6hwT\n4. Mr.Yamada: https://f.io/nPaOfq5p\n\n**Interview Documents**\n1.  Mr.Yamada: https://docs.google.com/document/d/1No0MWfJKkV4a7mt3PDolhxzJeJfS53NYghz_hQ7n7F0/edit?usp=sharing\n2. Mr.Tomita: https://docs.google.com/document/d/1znZhW4ayArj8bdIq6rykOWKrA6reQQhsWLDrGteuKcg/edit?usp=sharing\n3. Mr.Chin: https://docs.google.com/document/d/14ln0xq33UR5XiIBuWG2iDw7BNPjmQsqPaqMUnJL_QXI/edit?usp=sharing\n4. Mr.Ito: https://docs.google.com/document/d/17rVZJTzYcrOPF4kmMjJYtQK4YX-uDZ1CwtlBk1P6EQ4/edit?usp=sharing\n\nThen will fill in the feeling of each part of the book in this sheet \nhttps://docs.google.com/spreadsheets/d/1hZNYEXBaoqTKgyIvq3xrAO4hef6TedAfvwNpPRlqOe8/edit?gid=968259847#gid=968259847	\N	\N	2025-02-05 03:23:42.634	2025-02-05 07:33:03.487	\N	\N	\N	\N	\N	\N	f	\N	\N
1439676827013482011	1438940137017836646	1439185921311245818	1433172877045138776	\N	65535	Under Armour	Heat เสื้อ กั๊ก เสื้อแขนสั้น กางเกง เสื้อแขนยาว	\N	\N	2025-02-06 04:00:51.727	2025-02-06 04:01:41.204	\N	\N	\N	\N	\N	\N	f	\N	\N
1439186484346226172	1438940137017836646	1439185921311245818	1433172877045138776	\N	32767.5	CEREZO Kisd Merch Collection 2	ทำเสื้อเด็กจำนวน 95 ตัว \n- เสื้อยืด 60 ตัว สกรีน\n- เสื้อ Jersey 35 ตัว ฮีทเอง	\N	\N	2025-02-05 11:46:38.327	2025-02-06 04:04:06.327	\N	\N	\N	\N	\N	\N	f	\N	\N
1439062157164545460	1434703208386660040	1434703542295201484	1433172478670144855	\N	253948.125	Unity Sky pack	**5 March** KV / **10 March** Tech shot and Supporting\n1. Alpha III\n2. Neo IV Beta \n3. Neo IV\n~~4. Alpha III AG~~\n\n**20 March**\n5. Neo Sala Beta IN\n6. Neo Sala Beta TF\n7. Sala IN\n8. Sala TF\n\n\nPriority\n- KV\n- อันไหนที่เจ๋ง ต้องรีบส่ง Supporting image ไป	\N	\N	2025-02-05 07:39:37.373	2025-02-06 10:36:56.73	\N	\N	\N	\N	\N	\N	f	\N	\N
1439062305089258936	1434703208386660040	1434703542295201484	1433172478670144855	\N	258044.0625	Blazing Flair pack	**5 March** KV / **10 March** Tech shot and Supporting\n\n1. Alpha III\n2. Neo IV Beta \n3. Neo IV\n~~4.  Alpha III AG~~\n\n**20 March** \n\n5. Neo Sala Beta IN\n6. Neo Sala Beta TF\n7. Monarcida Neo III\n8. Monarcida Neo III Wide\n\nPriority\n- KV\n- Tech shot\n- อันไหนที่เจ๋ง ต้องรีบส่ง Supporting image ไป	\N	\N	2025-02-05 07:39:55.008	2025-02-06 10:38:42.243	\N	\N	\N	\N	\N	\N	f	\N	\N
1442593095177734023	1442584220726724453	1442585953032996727	1430480385812202497	\N	131070	Inventory Management System	\N	\N	\N	2025-02-10 04:34:57.984	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1439083705543951836	1434703208386660040	1434704734609999566	1433172244418266454	\N	1511401	Workshop 2 FTW care	Follow up with Kei	\N	\N	2025-02-05 08:22:26.139	2025-02-05 08:23:11.482	\N	\N	\N	\N	\N	\N	f	\N	\N
1439094361030657516	1433174649205687643	1438421969388177351	1430525186381186093	\N	458745	Osaka is Pink	2D Motion Osaka is Pink\n6 sec segment (2-3 loops)\nTotal 12-18 sec\n\nDeadline 2/12	\N	\N	2025-02-05 08:43:36.372	2025-02-05 08:44:51.278	\N	\N	\N	\N	\N	\N	f	\N	\N
1439067435696129477	1434703208386660040	1434703542295201484	1433172478670144855	\N	260092.03125	Stargazer Black	Alpha III Black\n\n* Tech shot \n* Supporting image\n\nDeliver -- March 10	\N	\N	2025-02-05 07:50:06.622	2025-02-06 10:28:20.097	\N	\N	\N	\N	\N	\N	f	\N	\N
1439061787864466865	1434703208386660040	1434703542295201484	1433172478670144855	\N	245756.25	The Bright Road pack	**5 March** KV / **10 March** Tech shot and Supporting\n1. Neo IV Beta \n2. Neo IV\n3. Moralia II\n\n**20 March**\n4. Neo Sala Beta IN\n5. Neo Sala Beta TF\n6. Sala IN\n7. Sala TF\n8. Monarcida Neo III\n9. Monarcida Neo III Wide\n\nPriority\n- KV\n- อันไหนที่เจ๋ง ต้องรีบส่ง Supporting image ไป	\N	\N	2025-02-05 07:38:53.347	2025-02-06 10:30:34.699	\N	\N	\N	\N	\N	\N	f	\N	\N
1439058369607370137	1434703208386660040	1434703542295201484	1433172478670144855	\N	49151.25	Follow up request form	\N	\N	\N	2025-02-05 07:32:05.86	2025-02-05 07:32:53.759	\N	\N	\N	\N	\N	\N	f	\N	\N
1438948922079839401	1434703208386660040	1434703542295201484	1433172244418266454	\N	98302.5	Test shoot for origin	Conduct test shoots to check lighting, angles, and compositions, Adjust camera settings & refine visual direction	2025-02-07 12:00:00	\N	2025-02-05 03:54:38.699	2025-02-05 04:00:04.649	f	\N	\N	\N	\N	\N	f	\N	\N
1438980312225809613	1434703208386660040	1434703542295201484	1433172478670144855	\N	327675	Shot list and storyboard for factory shooting on 20 FEB	\N	\N	\N	2025-02-05 04:57:00.695	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1440389331821790984	1430501369143362568	1430531972286907461	1430524402960696364	\N	655350	Urawa Matchday tool	\N	\N	\N	2025-02-07 03:36:28.921	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1440389283981559558	1430501369143362568	1430531972286907461	1430524402960696364	\N	589815	Cerezo Matchday	\N	\N	\N	2025-02-07 03:36:23.22	2025-02-07 03:36:32.896	\N	\N	\N	\N	\N	\N	f	\N	\N
1434710292574504669	1434703208386660040	1434704734609999566	1433172244418266454	\N	65535	Test shoot for Ruby	test shoot for ruby reds promo video. Conduct test shoots to check lighting, angles, and compositions, Adjust camera settings & refine visual direction, Ensure color accuracy and material details for Ruby Reds, Gather initial feedback from the team and make adjustments	2025-02-06 11:00:00	\N	2025-01-30 07:33:14.686	2025-02-07 03:53:51.522	f	\N	\N	\N	\N	\N	f	\N	\N
1433300241649501641	1433174649205687643	1438421969388177351	1430525186381186093	1433301087372182987	393210	Stadium Tour Guide	Final Drive: https://drive.google.com/drive/folders/1KSJme-z2gdpO-L1cY7IQmtahLjUdybOA?role=writer\n-\n\nSlide 1\nAn infographic showing where can international fans buy ticket at https://quick.pia.jp/cerezo_en/?utm_source=CO&utm_medium=web&utm_campaign=officialsite_en_ticket_dp \n-\nSlide 2:\nWays to get to the stadium:\n- Show map\n- Highlight Nagai station and Tsurugaoka Station\n- Highlight Yodoko Sakura Stadium\n-\nSlide 3 + ...\n- Iconic Lobby statue (photo spot)\n- Activities outside the stadium\n- Food truck + local restaurants\n- Cerezo bar\n- Museum\n- Cerezo store	\N	\N	2025-01-28 08:51:43.517	2025-02-05 08:07:05.028	\N	\N	\N	\N	\N	\N	f	\N	\N
1439086276258039265	1434703208386660040	1434704734609999566	1433172244418266454	\N	1576936	Checklist-Decoration items	\N	\N	\N	2025-02-05 08:27:32.592	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1439129941546370543	1434703208386660040	1434703542295201484	1433172244418266454	\N	786420	Contact Model	\N	\N	\N	2025-02-05 09:54:17.9	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438938542184072287	1434703208386660040	1434705078811363023	1433172244418266454	\N	65535	Scan 3D of FTW for P'Bank [8 hrs]	Each scan estimated to take 30 minutes. Experimental time 2 hrs.\n\n**WHO:**\n- Sira Tu scan 5 hours\n- P Bank consult 30 mins\n- Pol support 2.5 hours\n\nEstimated: **8 hours**	\N	\N	2025-02-05 03:34:01.318	2025-02-07 03:56:37.401	\N	\N	\N	\N	\N	\N	f	\N	\N
1439683812056368680	1438940137017836646	1438949766678447278	1433172877045138776	\N	327675	CEREZO Merch Collection 3	Make Product Merchadise Cerezo Collection 3	\N	\N	2025-02-06 04:14:44.41	2025-02-06 04:15:54.297	\N	\N	\N	\N	\N	\N	f	\N	\N
1438944089067226234	1433174649205687643	1440417324245976864	1430525186381186093	\N	32767.5	Follow up with client	To prepare\n* Best 2D, 3D assets to briefly show summary of past 5 truck events	2025-02-06 04:00:00	\N	2025-02-05 03:45:02.558	2025-02-07 04:33:10.436	t	\N	\N	\N	\N	\N	f	\N	\N
1438952821910144186	1434610219668735665	1438945086774707327	1433172244418266454	\N	65535	Urawa reds Ep.1-6	File : https://docs.google.com/presentation/d/1w1LaFuEZ1NVg6LRUGu5fM8wdkV4RDAv4XYagR52EkNQ/edit?usp=sharing	2025-02-07 05:00:00	\N	2025-02-05 04:02:23.593	2025-02-06 09:06:42.728	f	\N	\N	\N	\N	\N	f	\N	\N
1439188311150167557	1438940137017836646	1438949766678447278	1433172877045138776	\N	98302.5	Drink for Laddderice & ACSS	ทำเครื่องดื่มที่เกี่ยวกับ Ladderice และ ACSS  อย่างละ 1 เมนู	\N	\N	2025-02-05 11:50:16.099	2025-02-07 09:47:01.386	\N	\N	\N	\N	\N	\N	f	\N	\N
1442639409261315978	1433174649205687643	1433174831095874911	1433172478670144855	\N	1310700	Cerezo Osaka Merchandise promo	Drive for assets: https://drive.google.com/drive/folders/1WoNeyXH-9ZmKKZkFd0jD-IiRTl8-fONb	\N	\N	2025-02-10 06:06:59.053	2025-02-10 06:07:49.86	\N	\N	\N	\N	\N	\N	f	\N	\N
1442640975624144786	1434703208386660040	1434704734609999566	1433172478670144855	\N	1363947.25	Translate the Interviews	Interview articles draft from Takashi-san (Not final):\nhttps://drive.google.com/drive/folders/1Tg0AXLxI-TqMrXqgTp8OV6o37FV0d9ZC\n\nSharp -- AI tool translate\n\nGolf -- help correct the AI\n\nTS -- check the overall\n\nZack -- เกลา	2025-02-14 05:00:00	\N	2025-02-10 06:10:05.776	2025-02-10 06:47:10.4	f	\N	\N	\N	\N	\N	f	\N	\N
1438983888423617757	1434703208386660040	1434704734609999566	1433172244418266454	\N	163837.5	Japan Support for Summit	\N	\N	\N	2025-02-05 05:04:07.01	2025-02-05 05:04:14.158	\N	\N	\N	\N	\N	\N	f	\N	\N
1438985509941544163	1434703208386660040	1434704734609999566	1433172244418266454	\N	393210	Summit Room 1 History	\N	\N	\N	2025-02-05 05:07:20.313	2025-02-05 05:07:30.663	\N	\N	\N	\N	\N	\N	f	\N	\N
1438985758336615655	1434703208386660040	1434704734609999566	1433172244418266454	\N	524280	Summit Room 2.2 Workshop	\N	\N	\N	2025-02-05 05:07:49.924	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438985685389280485	1434703208386660040	1434704734609999566	1433172244418266454	\N	458745	Summit Room 2.1 Ruby Red	\N	\N	\N	2025-02-05 05:07:41.226	2025-02-05 05:07:55.663	\N	\N	\N	\N	\N	\N	f	\N	\N
1438985957750605033	1434703208386660040	1434704734609999566	1433172244418266454	\N	589815	Summit Room 3 Private	\N	\N	\N	2025-02-05 05:08:13.694	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438986079402198251	1434703208386660040	1434704734609999566	1433172244418266454	\N	655350	Summit Room 4 Future	\N	\N	\N	2025-02-05 05:08:28.196	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1439036570291144073	1434703208386660040	1434704734609999566	1433172478670144855	\N	1183726	Finalize Storyboard Proto UL	\N	\N	\N	2025-02-05 06:48:47.182	2025-02-05 06:50:26.781	\N	\N	\N	\N	\N	\N	f	\N	\N
1439059687986169262	1434703208386660040	1434703542295201484	1433172478670144855	\N	229372.5	Receive + Inventory	09/02/2025 >> Kei\n16/02/2025 >> Mizuno Thailand	\N	\N	2025-02-05 07:34:43.023	2025-02-05 07:36:58.866	\N	\N	\N	\N	\N	\N	f	\N	\N
1438991493367858438	1434703208386660040	1434704734609999566	1433172244418266454	\N	983025	Reshoot Origin Pack [9 hrs]	estimated to take 9 hrs. Experimental time 3 hrs.\n\nWHO:\n\nP New 6 hours\nP Pu consult and choose photo 1 hr.\nJuno support 30 min\nPhyo GFX 2 hrs.\nEstimated: 9.5 hours\n\n Deliverable :	\N	\N	2025-02-05 05:19:13.591	2025-02-05 05:42:36.391	\N	\N	\N	\N	\N	\N	f	\N	\N
1433303096687068625	1433174649205687643	1433192440268850553	1430525186381186093	1433309758743381461	7.9998779296875	First 5 2025 J1 League Fixtures	Final Drive: https://drive.google.com/drive/folders/1dhwPwc0D5NiinN4aULIOm1tweSd-lC3z?role=writer\n\nGamba Osaka vs **Cerezo Osaka**\n*J1 League, Matchweek 1\nFriday, February 14, 19:00 JST\nPanasonic Stadium Suita*\n\n**Cerezo Osaka** vs Shonan Bellmare\n*J1 League, Matchweek 2\nSaturday, February 22, 15:00 JST\nYodoko Sakura Stadium*\n\nKashiwa Reysol vs **Cerezo Osaka**\n*J1 League, Matchweek 3\nWednesday, February 26, 19:00 JST\nSANKYO FRONTIER Kashiwa Stadium*\n\nAlbirex Niigata vs **Cerezo Osaka**\n*J1 League, Matchweek 4\nSunday, March 2, 14:00 JST\nDENKA BIG SWAN STADIUM*\n\n**Cerezo Osaka** vs Nagoya Grampus\n*J1 League, Matchweek 5\nSaturday, March 8, 16:00 JST\nYodoko Sakura Stadium*	2025-02-07 05:00:00	\N	2025-01-28 08:57:23.864	2025-02-10 06:22:01.955	t	\N	\N	\N	\N	\N	f	\N	\N
1439063386858980795	1433174649205687643	1438421969388177351	1430525186381186093	\N	212988.75	GFX Matchday Template	Final Drive: https://drive.google.com/drive/u/0/folders/13HjfpvmXVSIeghUdPC0RZG1erm4EosUb	\N	\N	2025-02-05 07:42:03.963	2025-02-05 08:07:08.287	\N	\N	\N	\N	\N	\N	f	\N	\N
1439010281844901169	1434703208386660040	1434703542295201484	1433172244418266454	\N	720885	Shoot for UL Proto	\N	\N	\N	2025-02-05 05:56:33.351	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1439010075208320301	1434703208386660040	1434703542295201484	1433172244418266454	\N	589815	Shoot for Shadow + Urban	\N	\N	\N	2025-02-05 05:56:08.719	2025-02-05 06:08:50.474	\N	\N	\N	\N	\N	\N	f	\N	\N
1439079686972900816	1434703208386660040	1434704734609999566	1433172244418266454	\N	1380331	Produce 40th Moralia logo	Contact **helloiamjkstudio**	\N	\N	2025-02-05 08:14:27.087	2025-02-05 08:15:19.832	\N	\N	\N	\N	\N	\N	f	\N	\N
1438934380025218090	1434703208386660040	1434703542295201484	1433172244418266454	\N	196605	Shipping [2 hrs]	estimated to take 2 hrs. Experimental time 1 hr.\n\nWHO:\n\nGate coordinate 1 hr.\nP Kai consult 30 min\n\nEstimated: 2 hrs.	\N	\N	2025-02-05 03:25:45.152	2025-02-05 06:19:26.284	\N	\N	\N	\N	\N	\N	f	\N	\N
1438986407329662191	1434703208386660040	1434704734609999566	1433172244418266454	\N	786420	Commission Artwork	**Artis**\n- Unwanted FC \n- Kevin Concept\n- Mad rabbit studio\n- helloimjkstudio\n- เพาะช่าง\n- ศิลปกร	\N	\N	2025-02-05 05:09:07.288	2025-02-05 08:18:08.772	\N	\N	\N	\N	\N	\N	f	\N	\N
1439009557144667431	1434703208386660040	1434703542295201484	1433172244418266454	\N	114686.25	Shoot for Origin	estimated to take 16 hrs. Experimental time 2 hrs.\n\nWHO:\n- Juno 8 hrs\n- P'Pu consult 4 hrs\n- Gate support 2.5 hrs\n- LC assist 2 hrs\n- Fuse 1 hr\n- sharp 1 hr\n\nEstimated: **16 hours**	\N	\N	2025-02-05 05:55:06.961	2025-02-05 06:40:00.768	\N	\N	\N	\N	\N	\N	f	\N	\N
1439009814079341866	1434703208386660040	1434703542295201484	1433172244418266454	\N	122878.125	Shoot for Ruby Red	\N	\N	\N	2025-02-05 05:55:37.589	2025-02-05 06:40:32.895	\N	\N	\N	\N	\N	\N	f	\N	\N
1439857429213873898	1433174649205687643	1433192158453564789	1433171377464018261	\N	8191.875	Cerezo Cherry-OT #5 - Vlog recap	\N	\N	\N	2025-02-06 09:59:41.188	2025-02-07 03:36:12.562	\N	\N	\N	\N	\N	\N	f	\N	\N
1439086630081136100	1434703208386660040	1434704734609999566	1433172244418266454	\N	1642471	Checklist-Production Equipment	\N	\N	\N	2025-02-05 08:28:14.77	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1439130116532733425	1434703208386660040	1434703542295201484	1433172244418266454	\N	851955	Contact Location	\N	\N	\N	2025-02-05 09:54:38.76	\N	\N	\N	\N	\N	\N	\N	f	\N	\N
1438985479381845217	1434703208386660040	1434704734609999566	1433172244418266454	\N	327675	Summit Entrance & Arrival	**5 senses**\n\n1. sound\n2. scent\n3. taste\n4. look\n5. feel	\N	\N	2025-02-05 05:07:16.668	2025-02-06 06:56:20.703	\N	\N	\N	\N	\N	\N	f	\N	\N
1439000237099189513	1434703208386660040	1434704734609999566	1433172478670144855	\N	1347563.5	Follow up with Takashi about the interview section	\N	\N	\N	2025-02-05 05:36:35.925	2025-02-10 06:41:01.429	\N	\N	\N	\N	\N	\N	f	\N	\N
1438985344543360223	1434703208386660040	1434704734609999566	1433172244418266454	\N	1282028.5	Brand Book feeling	\N	\N	\N	2025-02-05 05:07:00.593	2025-02-10 06:41:11.214	\N	\N	\N	\N	\N	\N	f	\N	\N
1440419188186285877	1433174649205687643	1433192440268850553	1430534043199341650	\N	3.99993896484375	Build The Perfect Player	Final Drive: https://drive.google.com/drive/folders/1amYVOqFEYc6p0sWb6eEhh3fTI8OC15ZH?usp=sharing	\N	\N	2025-02-07 04:35:48.076	2025-02-10 06:22:22.945	\N	\N	\N	\N	\N	\N	f	\N	\N
1443322833382934525	1433174649205687643	1433174865606608225	1430534043199341650	\N	1791.97265625	Cerezo Truck #6 Announcement	\N	\N	\N	2025-02-11 04:44:49.557	2025-02-11 04:45:33.573	\N	\N	\N	\N	\N	\N	\N	2025-02-10 17:00:00	2025-02-10 17:00:00
1443391832913347619	1434609694726424238	1434615722369091251	1434720470833301219	\N	131070	February's content plan	planing for February in Urawa Reds TH page.\n\nhttps://docs.google.com/spreadsheets/d/193zwn75LSzVsVV5QT8EadbSYbvuXwCT9g2YEYgiEFiA/edit?gid=1142410316#gid=1142410316\n\nEstimate time: 1 hour	\N	\N	2025-02-11 07:01:54.944	2025-02-11 07:02:01.514	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443313947582138341	1433174649205687643	1433174850783937888	1430501158790628357	\N	65535	Shot list for Cerezo Cup Event	Develop shot list and equipment list\n\nWorking file: https://www.canva.com/design/DAGexA4l47U/lN7Ms5IWhgE81-_Z6szkPg/edit?ui=eyJBIjp7Ik8iOnsiQiI6dHJ1ZX19fQ\n\nOld photo from Cerezo Bangkok: https://drive.google.com/drive/folders/1D_IeexNZfXKjeMwE8wp8yyHjowFR-xGN\n\nReference:\nhttps://www.canva.com/design/DAGcUxbtv9E/lVUVTgRNAWGeC77Vwz9k4g/edit\n\n**Regular shot and drone shot both photoand video**	2025-02-14 05:00:00	\N	2025-02-11 04:27:10.287	2025-02-11 05:08:15.901	f	2:0	\N	low	medium	\N	\N	2025-02-10 17:00:00	2025-02-15 17:00:00
1443339554034549777	1434703208386660040	1434703542295201484	1433172478670144855	\N	983025	Hyogo Factory shot list + Equipment checklist	**Shot list Working file:** https://www.canva.com/design/DAGexWDnT3w/2ZiSE9i1thZGUf1xPZ-G-A/edit?utm_content=DAGexWDnT3w&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton\n\n\nEquipment Checklist for 20 FEB (Hyogo Factory shoot)\nhttps://docs.google.com/spreadsheets/d/1Nm5zzA306MFF3bFkAkxllhDFJvWTgWl_2UrjfkQc0cY/edit?usp=sharing	\N	\N	2025-02-11 05:18:02.815	2025-02-11 05:23:55.979	\N	\N	\N	\N	\N	\N	\N	\N	\N
1433232704547063170	1433174649205687643	1433192440268850553	1430525186381186093	\N	73726.875	Jaroensak's J.LEAGUE and Cerezo Osaka Dream 🇹🇭	Final Drive: https://drive.google.com/drive/folders/17qOfU9VQ7EEqdY4NN8YR2tnjR2eXnZjz?role=writer	2025-02-03 05:00:00	\N	2025-01-28 06:37:32.465	2025-02-11 02:58:21.244	t	\N	\N	\N	\N	\N	f	\N	\N
1438943393743897719	1434610219668735665	1438945086774707327	1433172244418266454	\N	32767.5	Feb Report	\N	2025-02-10 05:00:00	\N	2025-02-05 03:43:39.668	2025-02-11 03:21:25.383	f	\N	\N	\N	\N	\N	f	\N	\N
1432128251324531818	1430501369143362568	1430531972286907461	1430480385812202497	\N	196605	Demo Questions	5-6 Sample questions that will be displayed on ChatFootball.ai as demo questions	\N	\N	2025-01-26 18:03:11.383	2025-02-11 06:00:00.951	\N	\N	\N	medium	medium	0	f	2025-02-09 17:00:00	2025-02-11 17:00:00
1443272709252319169	1433174649205687643	1433174865606608225	1430534043199341650	\N	416761.890625	Niko Name Challenge	Final Drive Here https://drive.google.com/drive/folders/1VrboWe1vXZYSEhpi5moKShEl1R17WXrP?usp=sharing	\N	\N	2025-02-11 03:05:14.295	2025-02-11 10:29:37.296	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443396623278277691	1434609694726424238	1434615722369091251	1434720470833301219	\N	262140	Matchday poster	Matchday Template 2025 \n\nEstimate time GFX: 5 hours	\N	\N	2025-02-11 07:11:25.996	2025-02-11 09:14:07.163	\N	\N	\N	\N	\N	\N	\N	\N	\N
1433316010454156773	1433174649205687643	1433192440268850553	1430525186381186093	\N	1.999969482421875	2025 New Players Introduction	Final Drive: https://drive.google.com/drive/folders/1aDJOnWPz6Ij3weoGu8hvOxSER1lQE2ve?role=writer	\N	\N	2025-01-28 09:23:03.304	2025-02-11 10:50:37.245	\N	\N	\N	\N	\N	\N	f	\N	\N
1443396872721925182	1434609694726424238	1434619182476953271	1434720470833301219	1443397119061787714	65535	Home-Grown content	Home-grown GFX has already approval by Kei-san \n\nestimate time for GFX: 5 hours	\N	\N	2025-02-11 07:11:55.733	2025-02-11 07:12:25.108	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443397194441819203	1434609694726424238	1434619449494734520	1434720470833301219	1443397375702860869	65535	Cover Page	Cover Page Urawa Reds \n\nEstimate time for GFX: 5 hours	\N	\N	2025-02-11 07:12:34.088	2025-02-11 07:13:46.319	\N	\N	\N	\N	\N	\N	f	\N	\N
1443397437266854982	1434609694726424238	1434619449494734520	1434720470833301219	1443397714460017743	131070	Monthly Calendar: February 2025	Monthly Carlendar approval by Kei-san \n\nEstimate time for GFX 5 hours	\N	\N	2025-02-11 07:13:03.032	2025-02-11 07:13:36.084	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443392055991600171	1434609694726424238	1434615722369091251	1434720470833301219	1443395356120319025	196605	HBD: Hirokazu Ishihara	Player's Birthday on 26th FEB (Use old template)\n\nEstimate time for GFX: 30 minutes	\N	\N	2025-02-11 07:02:21.536	2025-02-11 09:06:51.3	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443283231083333589	1442584975609169775	1442585624451221364	1430524402960696364	\N	65535	Cookie acceptance popup	\N	\N	\N	2025-02-11 03:26:08.594	2025-02-12 03:19:14.681	\N	8:0	2:0	medium	high	\N	\N	2025-02-10 17:00:00	2025-02-10 17:00:00
1443410876563457116	1434609694726424238	1434619082375694006	1434720470833301219	1443410923631936606	65535	H2H	GFX for Head-to-Head content (use old Template)\n\nEstimate time 1 hour	\N	\N	2025-02-11 07:39:45.12	2025-02-11 09:04:16.552	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443457772355060837	1434609694726424238	1434615722369091251	1434720470833301219	1443457807209727079	327675	Full-Time GFX (for approve)	use for 2025 season tmplate (need QC & sent to approve) \n\nEstimate time : 5 hours to create	\N	\N	2025-02-11 09:12:55.536	2025-02-11 09:13:53.841	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443458771580879980	1434609694726424238	1434615722369091251	1434720470833301219	1443458794414670958	393210	Next Match (for approve)	use for 2025 template (need QC & sent to approve)\n\nEstimate time 4 hours	\N	\N	2025-02-11 09:14:54.653	2025-02-11 09:15:47.097	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443459936733365363	1434609694726424238	1434615722369091251	1434720470833301219	1443459980622562421	458745	interview template for 2025	use for 2025 interview contents (need QC & sent to approve)\n\nEstimate time 5 hour	\N	\N	2025-02-11 09:17:13.55	2025-02-11 09:17:56.725	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443460766970676346	1434609694726424238	1434615722369091251	1434720470833301219	1443460794183320700	524280	Line-up for 2025 GFX	use for template Line-up in 2025 season (need QC & send to approve)\n\nEstimate time 5 hours	\N	\N	2025-02-11 09:18:52.522	2025-02-11 09:19:37.599	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443463685484840066	1434609694726424238	1434615722369091251	1434720470833301219	1443463714693973124	589815	Matchday Template for 2025	use for 2025 season (need QC & sent to approve)\n\nEstimate time 5 hours	\N	\N	2025-02-11 09:24:40.435	2025-02-11 09:25:26.95	\N	\N	\N	\N	\N	\N	\N	\N	\N
1443497754255950990	1433174649205687643	1433174865606608225	1430534043199341650	\N	482296.890625	Niko Interview	Drive: https://drive.google.com/drive/folders/133ADfi65V18aJzvldW1DPE56HQP-l7zW?usp=sharing	\N	\N	2025-02-11 10:32:21.749	2025-02-11 10:34:06.87	\N	\N	\N	\N	\N	\N	\N	\N	\N
1433321620511917572	1433174649205687643	1433174831095874911	1430525186381186093	\N	1048560	Osaka Derby Promo	Final Drive: https://drive.google.com/drive/folders/16DvsDhBYTSRoXZRaDB2ipOiiP5kVLMxR?role=writer	\N	\N	2025-01-28 09:34:12.075	2025-02-11 11:07:37.438	\N	\N	\N	\N	\N	\N	f	\N	\N
1439823527275398849	1442584975609169775	1442585764046047094	1430480385812202497	\N	65535	[Planka] Add card's task member tagging	\N	\N	\N	2025-02-06 08:52:19.761	2025-02-12 03:26:03.152	\N	\N	\N	\N	\N	\N	f	\N	\N
1444008228986815648	1442584975609169775	1442585552250472307	1430480385812202497	\N	65535	Turfmapp AI integrate with Planka	\N	\N	\N	2025-02-12 03:26:35.08	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1692095657243837637	1692048962560722096	1692095336203420865	1430525186381186093	1692106007863362759	65535	10 things to know about MEIJI YASUDA J.LEAGUE 100 YEAR VISION LEAGUE	Drive: \nhttps://drive.google.com/drive/folders/1YevHilUC78FERiDBUD2ioQGDRPntEdtQ\n\nWhat to check\n* Spelling English, Thai in all slides\n* Slide 2\n\t* Date: https://www.jleague.co/special/2026specialseason/j1/\n* Slide 3\n\t* Information of regulation (link https://www.jleague.co/special/2026specialseason/j1/)\n\t* New faces -> are they still the player in their current team? (Rion Ichihara, Alex Kouto Horio Pisano, Taiga Nishiyama)\n* Slide 5\n\t* Information accuracy (link https://www.jleague.co/special/2026specialseason/j1/)\n* Slide 7\n\t* Information accuracy (link https://www.jleague.co/fixtures/)\n\t\t* Logo\n\t\t* Time, date\n\t\t* Stadium\n* Slide 8\n\t* Validate if it's the first time since 2005 or not? (link https://en.wikipedia.org/wiki/JEF_United_Chiba, section "Record as J.League member")\n\t* Is there any other year after 2005 that these 9 teams play together in J1?\n* Slide 10\n\t* Is it Kazu's 41st season as a professional footballer?\n\t* Is this the first time he's back to J.League since 2021?\n\t\t* Link\n\t\t\t* https://en.wikipedia.org/wiki/Kazuyoshi_Miura\n\t\t\t* https://data.j-league.or.jp/SFIX04/?player_id=124\n* Slide 11\n\t* Validation of "JFA Declaration, 2005" (link https://www.jfa.jp/eng/about_jfa/dream/)	\N	\N	2026-01-20 10:32:01.148	2026-01-20 10:52:35.049	\N	\N	\N	\N	\N	\N	f	\N	\N
1692563975067141338	1692048962560722096	1692095336203420865	1430534043199341650	\N	131070	Get to know Mito Hollyhock (Carousel)	Drive: https://drive.google.com/drive/folders/1MivDDkxkRTg0x95JGqFFtmdaUU9sHmPB\n\nWhat to check:\n- All Slide - Spelling, alignment\n- Slide 2: Information is correct or not?\n\tSource: https://www.mito-hollyhock.net/club/\n\n- Slide 3: Information for each element of the emblem correct or not?\n  Source: https://www.mito-hollyhock.net/club/\n\n- Slide 4: Information of Mascot is correct or not?\n  Source: https://www.mito-hollyhock.net/club/\n\n- Slide 5: Are they played in J2 League for 26 Years? before go to J1\n                 Are they played in J2 League since 2000?\n                 Are 3 players used to play for MITO?\n   Source: https://en.wikipedia.org/wiki/Mito_HollyHock\n   Source: Daizen: https://data.j-league.or.jp/SFIX04/?player_id=19175\n                 Ryotaro Ito: https://data.j-league.or.jp/SFIX04/?player_id=19203\n                 Shunsuke Saito: https://data.j-league.or.jp/SFIX04/?player_id=54795\n\n- Slide 6: Are MITO go to top division for the first time in history?\n  Source: https://en.wikipedia.org/wiki/Mito_HollyHock\n\n- Slide 7: Naoki Mori still the MITO manager?\n                 - > Change to Daisuke Kimori\n\n                3 Players is correct name and photo and still in the club?\n   Source: https://www.jleague.jp/player/1503340/#attack\n                 https://www.jleague.jp/player/1647012/#attack\n                 https://www.jleague.jp/player/1636260/#attack\n                 https://www.mito-hollyhock.net/news/p=48241/\n                 https://www.jleague.co/clubs/Mito-Hollyhock/\n- Slide 8: Club in EAST side is correct?\n                 Taishi Semba (No.47) still in the club?\n  Source: https://www.jleague.jp/player/1605464/#attack\n                https://www.jleague.jp/standings/j1/	\N	\N	2026-01-21 02:02:28.973	2026-01-21 03:11:42.154	\N	\N	\N	\N	\N	\N	f	\N	\N
\.


--
-- Data for Name: card_label; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.card_label (id, card_id, label_id, created_at, updated_at) FROM stdin;
1430521885094839339	1430519898227868700	1430521857034945578	2025-01-24 12:51:37.608	\N
1432134987242538143	1432128678245958769	1432127948789384294	2025-01-26 18:16:34.367	\N
1432135049477620896	1432128251324531818	1432134540909872285	2025-01-26 18:16:41.788	\N
1432135110521521313	1432128234438263911	1432127948789384294	2025-01-26 18:16:49.065	\N
1432135165550789794	1432126863186068574	1432127948789384294	2025-01-26 18:16:55.625	\N
1432135223323133091	1432133309344777364	1432134540909872285	2025-01-26 18:17:02.512	\N
1432135287663756452	1432133249383007377	1432134540909872285	2025-01-26 18:17:10.182	\N
1432135357524083877	1432133165018776718	1432134540909872285	2025-01-26 18:17:18.51	\N
1432135537627497638	1432132167101580422	1432134540909872285	2025-01-26 18:17:39.978	\N
1432135612051227815	1432131205364450429	1432134540909872285	2025-01-26 18:17:48.852	\N
1432137550616593581	1432136214110012584	1432134710787572894	2025-01-26 18:21:39.948	\N
1432140066838283448	1432138030939899056	1432134710787572894	2025-01-26 18:26:39.902	\N
1432143874461009088	1432143088423273660	1432143823156282559	2025-01-26 18:34:13.809	\N
1432671734992995642	1432671734758114616	1432127948789384294	2025-01-27 12:02:59.688	\N
1438933068214699019	1438931347761530876	1438932922672350218	2025-02-05 03:23:08.77	\N
1438933489146659855	1438933352294908940	1438933479910802446	2025-02-05 03:23:58.951	\N
1438933789802759190	1434710292574504669	1434738218804184840	2025-02-05 03:24:34.784	\N
1438934497054688302	1438934380025218090	1438933965258884120	2025-02-05 03:25:59.101	\N
1438938614326101089	1438938542184072287	1434738218804184840	2025-02-05 03:34:09.921	\N
1438943507367593081	1438943393743897719	1438940409093948527	2025-02-05 03:43:53.214	\N
1438947511157916812	1433271312972776888	1438947501511017611	2025-02-05 03:51:50.506	\N
1438947551934940301	1433316010454156773	1438947501511017611	2025-02-05 03:51:55.364	\N
1438947681622819983	1433303096687068625	1438947501511017611	2025-02-05 03:52:10.826	\N
1438947751634142352	1433317255122257385	1438947501511017611	2025-02-05 03:52:19.172	\N
1438947784299381905	1433317981407938029	1438947501511017611	2025-02-05 03:52:23.066	\N
1438947835369227410	1433318486083372529	1438947501511017611	2025-02-05 03:52:29.154	\N
1438947887496037523	1433320073308669432	1438947501511017611	2025-02-05 03:52:35.369	\N
1438947917116212372	1433321620511917572	1438947501511017611	2025-02-05 03:52:38.899	\N
1438947960325932181	1433322124021335558	1438947501511017611	2025-02-05 03:52:44.051	\N
1438947997084812438	1433323812958504456	1438947501511017611	2025-02-05 03:52:48.432	\N
1438948040395195543	1433326151408813580	1438947501511017611	2025-02-05 03:52:53.595	\N
1438948335581922463	1438944089067226234	1438948326689997982	2025-02-05 03:53:28.784	\N
1438948815938782376	1438948712406582432	1438948326689997982	2025-02-05 03:54:26.048	\N
1438948998802048171	1438948922079839401	1434738218804184840	2025-02-05 03:54:47.845	\N
1438952883004376252	1438952821910144186	1438940658101388401	2025-02-05 04:02:30.879	\N
1438979510375548108	1438979442184553672	1438933479910802446	2025-02-05 04:55:25.109	\N
1438980367833892047	1438980312225809613	1434738218804184840	2025-02-05 04:57:07.326	\N
1438988597427438838	1438981359895839958	1438934154874979353	2025-02-05 05:13:28.368	\N
1438988655040398583	1438983888423617757	1438934154874979353	2025-02-05 05:13:35.238	\N
1438988770761245944	1438981663898993882	1434738218804184840	2025-02-05 05:13:49.031	\N
1438988870518572282	1438985344543360223	1438933479910802446	2025-02-05 05:14:00.925	\N
1438988922494387451	1438985479381845217	1438934154874979353	2025-02-05 05:14:07.122	\N
1438988962122171644	1438985509941544163	1438934154874979353	2025-02-05 05:14:11.846	\N
1438989002655925501	1438985685389280485	1438934154874979353	2025-02-05 05:14:16.677	\N
1438989034289366270	1438985758336615655	1438934154874979353	2025-02-05 05:14:20.448	\N
1438989077155153151	1438985957750605033	1438934154874979353	2025-02-05 05:14:25.558	\N
1438989135992849664	1438986079402198251	1438934154874979353	2025-02-05 05:14:32.572	\N
1438989188933354753	1438986240270533869	1438934154874979353	2025-02-05 05:14:38.883	\N
1438989277844210946	1438986407329662191	1438933479910802446	2025-02-05 05:14:49.48	\N
1438989283196142851	1438986407329662191	1438934154874979353	2025-02-05 05:14:50.12	\N
1438989335020963076	1438986493950428401	1438933479910802446	2025-02-05 05:14:56.298	\N
1438989374623581445	1438986650347635955	1438933479910802446	2025-02-05 05:15:01.02	\N
1438991538565678344	1438991493367858438	1434738218804184840	2025-02-05 05:19:18.979	\N
1439000402598036751	1439000237099189513	1438933479910802446	2025-02-05 05:36:55.656	\N
1439009604750017833	1439009557144667431	1434738218804184840	2025-02-05 05:55:12.636	\N
1439009847138845996	1439009814079341866	1434738218804184840	2025-02-05 05:55:41.532	\N
1439010312345879859	1439010075208320301	1434738218804184840	2025-02-05 05:56:36.987	\N
1439010343039796532	1439010168246371631	1434738218804184840	2025-02-05 05:56:40.649	\N
1439010371972105525	1439010281844901169	1434738218804184840	2025-02-05 05:56:44.098	\N
1439036001803568511	1439035918395639165	1434738218804184840	2025-02-05 06:47:39.41	\N
1439036085370881409	1439036085295383936	1434738218804184840	2025-02-05 06:47:49.373	\N
1439036648623965581	1439036397678757251	1434738218804184840	2025-02-05 06:48:56.52	\N
1439036676381869454	1439036641913079179	1434738218804184840	2025-02-05 06:48:59.827	\N
1439036720556279183	1439036570291144073	1434738218804184840	2025-02-05 06:49:05.094	\N
1439036824868619664	1439036465827808647	1434738218804184840	2025-02-05 06:49:17.527	\N
1439058115566765464	1439058036135036310	1434738218804184840	2025-02-05 07:31:35.578	\N
1439058397809870235	1439058369607370137	1434738218804184840	2025-02-05 07:32:09.221	\N
1439059720626242992	1439059687986169262	1438933965258884120	2025-02-05 07:34:46.914	\N
1439062128894936499	1439061787864466865	1438933965258884120	2025-02-05 07:39:34.002	\N
1439062284184847799	1439062157164545460	1438933965258884120	2025-02-05 07:39:52.514	\N
1439062305147979193	1439062305089258936	1438933965258884120	2025-02-05 07:39:55.015	\N
1439067160558175684	1439067056858203586	1438933965258884120	2025-02-05 07:49:33.823	\N
1439067656576566728	1439067435696129477	1438933965258884120	2025-02-05 07:50:32.952	\N
1439075740627764685	1439075740552267212	1438933965258884120	2025-02-05 08:06:36.649	\N
1439079735844931026	1439079686972900816	1438934154874979353	2025-02-05 08:14:32.916	\N
1439083540741359067	1439082514009294291	1438934154874979353	2025-02-05 08:22:06.493	\N
1439083943637812702	1439083705543951836	1438934154874979353	2025-02-05 08:22:54.523	\N
1439086316951176675	1439086276258039265	1438934154874979353	2025-02-05 08:27:37.443	\N
1439086677292221926	1439086630081136100	1438934154874979353	2025-02-05 08:28:20.4	\N
1439088193818330601	1439088141725074919	1438934154874979353	2025-02-05 08:31:21.185	\N
1439130161210459635	1439129941546370543	1434738218804184840	2025-02-05 09:54:44.085	\N
1439130217783231988	1439130116532733425	1434738218804184840	2025-02-05 09:54:50.832	\N
1439182936401249782	1438949933292979375	1439182914045609461	2025-02-05 11:39:35.381	\N
1439183271928792568	1438959873944454336	1439183260277016055	2025-02-05 11:40:15.378	\N
1439186589656811008	1439186484346226172	1439183260277016055	2025-02-05 11:46:50.883	\N
1439677161047852573	1439676827013482011	1439183260277016055	2025-02-06 04:01:31.548	\N
1439684425079064110	1439683812056368680	1439183260277016055	2025-02-06 04:15:57.487	\N
1439689137891313201	1439689109495875119	1438948326689997982	2025-02-06 04:25:19.3	\N
1439758183315801681	1439758144677873231	1434738218804184840	2025-02-06 06:42:30.155	\N
1442639685707892620	1442639409261315978	1438947501511017611	2025-02-10 06:07:32.007	\N
1442653575724402605	1442640975624144786	1438933479910802446	2025-02-10 06:35:07.827	\N
1443286271593023456	1443283231083333589	1443286233391302623	2025-02-11 03:32:11.054	\N
1443314471903692789	1443313947582138341	1438947622474744974	2025-02-11 04:28:12.791	\N
1443315288534681590	1440389283981559558	1432134540909872285	2025-02-11 04:29:50.141	\N
1443315320612718583	1440389331821790984	1432134540909872285	2025-02-11 04:29:53.967	\N
1443332343136781323	1443317461578418171	1438947622474744974	2025-02-11 05:03:43.21	\N
1443339611077084179	1443339554034549777	1438933479910802446	2025-02-11 05:18:09.617	\N
1443339623282508820	1443339554034549777	1434738218804184840	2025-02-11 05:18:11.071	\N
1692123328476611799	1692095657243837637	1692123320792646870	2026-01-20 11:26:59.82	\N
1692573684369196258	1692563975067141338	1692123320792646870	2026-01-21 02:21:46.423	\N
\.


--
-- Data for Name: card_membership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.card_membership (id, card_id, user_id, created_at, updated_at) FROM stdin;
1430505615364457490	1430502957912163342	1430501158790628357	2025-01-24 12:19:18.105	\N
1430519925239186464	1430519898227868700	1430501158790628357	2025-01-24 12:47:43.975	\N
1430525439314494514	1430519898227868700	1430525186381186093	2025-01-24 12:58:41.303	\N
1432128363572495471	1432128251324531818	1430525186381186093	2025-01-26 18:03:24.766	\N
1432375338502980843	1432375308748588264	1430501158790628357	2025-01-27 02:14:06.472	\N
1432468538739655970	1432466460956951829	1430534043199341650	2025-01-27 05:19:16.805	\N
1432468570079495460	1432467553304708380	1430534043199341650	2025-01-27 05:19:20.542	\N
1433096881751196996	1432131205364450429	1430534043199341650	2025-01-28 02:07:41.13	\N
1433096986994672966	1432132167101580422	1432141375276582075	2025-01-28 02:07:53.676	\N
1433097037124994376	1432133165018776718	1432141375276582075	2025-01-28 02:07:59.653	\N
1433097092061988170	1432133249383007377	1432141375276582075	2025-01-28 02:08:06.197	\N
1433097146235618636	1432133309344777364	1432141375276582075	2025-01-28 02:08:12.658	\N
1433097271016162638	1432143088423273660	1430525186381186093	2025-01-28 02:08:27.531	\N
1433097280134579536	1432143088423273660	1430534043199341650	2025-01-28 02:08:28.621	\N
1433179341574899048	1432128234438263911	1430525186381186093	2025-01-28 04:51:31.105	\N
1433268880150627764	1433259305485731246	1430534043199341650	2025-01-28 07:49:24.934	\N
1433268920206230966	1433261051297662384	1430534043199341650	2025-01-28 07:49:29.712	\N
1433304217866470867	1433303096687068625	1433261799410501042	2025-01-28 08:59:37.518	\N
1433313705709274587	1433233702573311364	1433261799410501042	2025-01-28 09:18:28.558	\N
1433314041530418653	1433241292510332304	1433261799410501042	2025-01-28 09:19:08.591	\N
1433314513565779425	1433314479944238559	1433261799410501042	2025-01-28 09:20:04.865	\N
1433317338060424683	1433317255122257385	1433261799410501042	2025-01-28 09:25:41.569	\N
1433318009669158383	1433317981407938029	1430525186381186093	2025-01-28 09:27:01.631	\N
1433320151834428922	1433320073308669432	1433261799410501042	2025-01-28 09:31:16.997	\N
1433320540763850238	1433320514390066684	1430534043199341650	2025-01-28 09:32:03.362	\N
1433323841597212170	1433323812958504456	1430525186381186093	2025-01-28 09:38:36.852	\N
1433944433132308035	1433944122544096833	1430534043199341650	2025-01-29 06:11:37.126	\N
1434026227085084243	1434026103898375761	1430534043199341650	2025-01-29 08:54:07.725	\N
1434030414703363677	1434028784092186199	1430534043199341650	2025-01-29 09:02:26.928	\N
1434038600541931126	1434037967428519538	1430534043199341650	2025-01-29 09:18:42.756	\N
1434038909964125820	1434038848156862074	1433261799410501042	2025-01-29 09:19:19.641	\N
1434635457173391035	1434038162799199860	1430534043199341650	2025-01-30 05:04:33.611	\N
1434737567000954622	1434729164375590648	1433172244418266454	2025-01-30 08:27:26.053	\N
1434737578803726082	1434729164375590648	1433172478670144855	2025-01-30 08:27:27.46	\N
1434737584474425092	1434729164375590648	1430525186381186093	2025-01-30 08:27:28.136	\N
1434737590765881094	1434729164375590648	1433297069220562376	2025-01-30 08:27:28.886	\N
1435347276741478165	1435346986613081875	1433261799410501042	2025-01-31 04:38:49.115	\N
1435347680074139423	1435346986613081875	1433172478670144855	2025-01-31 04:39:37.195	\N
1435352907468769061	1434109361990403733	1435352068222093091	2025-01-31 04:50:00.35	\N
1437713118053533519	1433316010454156773	1430534043199341650	2025-02-03 10:59:19.38	\N
1438216876881610583	1433254977265993112	1433261799410501042	2025-02-04 03:40:12.111	\N
1438216895453988697	1433254977265993112	1435352068222093091	2025-02-04 03:40:14.326	\N
1438218588182808434	1438218418741315436	1430525186381186093	2025-02-04 03:43:36.116	\N
1438218592318392180	1438218418741315436	1430534043199341650	2025-02-04 03:43:36.607	\N
1438218606763575158	1438218418741315436	1433171377464018261	2025-02-04 03:43:38.33	\N
1438218704683796354	1438218506888808303	1430525186381186093	2025-02-04 03:43:50.002	\N
1438218724422190980	1438218506888808303	1433171377464018261	2025-02-04 03:43:52.356	\N
1438218733154731910	1438218506888808303	1430534043199341650	2025-02-04 03:43:53.397	\N
1438934235313341466	1438933352294908940	1433172244418266454	2025-02-05 03:25:27.901	\N
1438934252526765086	1438933352294908940	1430525186381186093	2025-02-05 03:25:29.953	\N
1438934257786422304	1438933352294908940	1433172478670144855	2025-02-05 03:25:30.58	\N
1438934262836364322	1438933352294908940	1430501158790628357	2025-02-05 03:25:31.183	\N
1438934268104410148	1438933352294908940	1433297069220562376	2025-02-05 03:25:31.81	\N
1438934744409572402	1438933352294908940	1433261799410501042	2025-02-05 03:26:28.59	\N
1438934760834466870	1438933352294908940	1432141375276582075	2025-02-05 03:26:30.548	\N
1438934774474343480	1438933352294908940	1435352068222093091	2025-02-05 03:26:32.174	\N
1438934887259178044	1434710292574504669	1433172244418266454	2025-02-05 03:26:45.618	\N
1438934894431437886	1434710292574504669	1433172478670144855	2025-02-05 03:26:46.474	\N
1438934914580874304	1434710292574504669	1430525186381186093	2025-02-05 03:26:48.876	\N
1438934937959924804	1434710292574504669	1433297069220562376	2025-02-05 03:26:51.663	\N
1438935254579545160	1438934380025218090	1433172244418266454	2025-02-05 03:27:29.408	\N
1438935298191918158	1438934380025218090	1430525186381186093	2025-02-05 03:27:34.606	\N
1438935334556533842	1438934380025218090	1433297069220562376	2025-02-05 03:27:38.941	\N
1438939760008627300	1438938542184072287	1430501158790628357	2025-02-05 03:36:26.494	\N
1438945453725975682	1434041555689145990	1433297069220562376	2025-02-05 03:47:45.237	\N
1438948118627353752	1438944089067226234	1433172478670144855	2025-02-05 03:53:02.921	\N
1438948127099847834	1438944089067226234	1430525186381186093	2025-02-05 03:53:03.931	\N
1438948131294151836	1438944089067226234	1433297069220562376	2025-02-05 03:53:04.43	\N
1438948742362301602	1438948712406582432	1433171377464018261	2025-02-05 03:54:17.273	\N
1438948750692189348	1438948712406582432	1433172478670144855	2025-02-05 03:54:18.269	\N
1438948757755397286	1438948712406582432	1430525186381186093	2025-02-05 03:54:19.111	\N
1438950059482809525	1438949933292979375	1433297069220562376	2025-02-05 03:56:54.289	\N
1438950085453939895	1438949933292979375	1433172478670144855	2025-02-05 03:56:57.385	\N
1438979471192360138	1438979442184553672	1433172478670144855	2025-02-05 04:55:20.438	\N
1438980437174125776	1438980312225809613	1433172478670144855	2025-02-05 04:57:15.592	\N
1438980465066247378	1438980312225809613	1433297069220562376	2025-02-05 04:57:18.917	\N
1438980482179007700	1438980312225809613	1433172244418266454	2025-02-05 04:57:20.958	\N
1439000289527989515	1439000237099189513	1433297069220562376	2025-02-05 05:36:42.175	\N
1439000322671379725	1439000237099189513	1433172478670144855	2025-02-05 05:36:46.128	\N
1439002012573238546	1438991493367858438	1433172244418266454	2025-02-05 05:40:07.578	\N
1439002028268324118	1438991493367858438	1433261799410501042	2025-02-05 05:40:09.451	\N
1439002049365673240	1438991493367858438	1433297069220562376	2025-02-05 05:40:11.966	\N
1439019781456921913	1439009557144667431	1433172244418266454	2025-02-05 06:15:25.796	\N
1439019805943268669	1439009557144667431	1433172478670144855	2025-02-05 06:15:28.715	\N
1439019819826414911	1439009557144667431	1430525186381186093	2025-02-05 06:15:30.37	\N
1439019830882600257	1439009557144667431	1433297069220562376	2025-02-05 06:15:31.688	\N
1439019943214449989	1439009814079341866	1433172244418266454	2025-02-05 06:15:45.079	\N
1439019967440749899	1439009814079341866	1433172478670144855	2025-02-05 06:15:47.968	\N
1439019979964941645	1439009814079341866	1433297069220562376	2025-02-05 06:15:49.46	\N
1439019992388470095	1439009814079341866	1430525186381186093	2025-02-05 06:15:50.94	\N
1439020094419109203	1439010075208320301	1433172244418266454	2025-02-05 06:16:03.105	\N
1439020153684624727	1439010075208320301	1433172478670144855	2025-02-05 06:16:10.169	\N
1439020186433750361	1439010075208320301	1430525186381186093	2025-02-05 06:16:14.068	\N
1439020194218378587	1439010075208320301	1433297069220562376	2025-02-05 06:16:15	\N
1439020269346751841	1439010281844901169	1433172244418266454	2025-02-05 06:16:23.957	\N
1439020280629429605	1439010281844901169	1433172478670144855	2025-02-05 06:16:25.302	\N
1439020298715268455	1439010281844901169	1433297069220562376	2025-02-05 06:16:27.458	\N
1439020313722488169	1439010281844901169	1430525186381186093	2025-02-05 06:16:29.247	\N
1439058453107574174	1439058369607370137	1433297069220562376	2025-02-05 07:32:15.816	\N
1439058463316510112	1439058369607370137	1433172244418266454	2025-02-05 07:32:17.034	\N
1439058473995208098	1439058369607370137	1433172478670144855	2025-02-05 07:32:18.307	\N
1439083116512675285	1439082514009294291	1435352068222093091	2025-02-05 08:21:15.921	\N
1439083129724732887	1439082514009294291	1433261799410501042	2025-02-05 08:21:17.498	\N
1439094156491228650	1438431374158596053	1433261799410501042	2025-02-05 08:43:11.989	\N
1439644536333665805	1439644478963975691	1430534043199341650	2025-02-06 02:56:42.379	\N
1439672723608438290	1438952821910144186	1433172244418266454	2025-02-06 03:52:42.564	\N
1439672739764897300	1438952821910144186	1430501158790628357	2025-02-06 03:52:44.492	\N
1439672746207348246	1438952821910144186	1430534043199341650	2025-02-06 03:52:45.261	\N
1439689165758268978	1439689109495875119	1433172478670144855	2025-02-06 04:25:22.623	\N
1439689173240907316	1439689109495875119	1433171377464018261	2025-02-06 04:25:23.514	\N
1439689179104544310	1439689109495875119	1430525186381186093	2025-02-06 04:25:24.214	\N
1439689184171263544	1439689109495875119	1433297069220562376	2025-02-06 04:25:24.818	\N
1439694642764318266	1438943393743897719	1433172244418266454	2025-02-06 04:36:15.53	\N
1439694712658200126	1438943393743897719	1430534043199341650	2025-02-06 04:36:23.866	\N
1439758261178861140	1439758144677873231	1433172244418266454	2025-02-06 06:42:39.439	\N
1439758295194666584	1439758144677873231	1430525186381186093	2025-02-06 06:42:43.494	\N
1439758383023392348	1439130116532733425	1433172244418266454	2025-02-06 06:42:53.964	\N
1439758462530618974	1439129941546370543	1433172478670144855	2025-02-06 06:43:03.442	\N
1439760265393473124	1438948922079839401	1433172478670144855	2025-02-06 06:46:38.359	\N
1439760295768622694	1438948922079839401	1433297069220562376	2025-02-06 06:46:41.981	\N
1439760331235657320	1438948922079839401	1433172244418266454	2025-02-06 06:46:46.193	\N
1439761113582405228	1438985509941544163	1433172478670144855	2025-02-06 06:48:19.472	\N
1439761163511400048	1438985509941544163	1432141375276582075	2025-02-06 06:48:25.425	\N
1439761229773014642	1438985685389280485	1433172244418266454	2025-02-06 06:48:33.323	\N
1439761238472001140	1438985685389280485	1433172478670144855	2025-02-06 06:48:34.361	\N
1439761413231871608	1438985758336615655	1435352068222093091	2025-02-06 06:48:55.194	\N
1439761487034844794	1438985957750605033	1433172244418266454	2025-02-06 06:49:03.991	\N
1439761493485684348	1438985957750605033	1433172478670144855	2025-02-06 06:49:04.76	\N
1439761719432840830	1438986079402198251	1435352068222093091	2025-02-06 06:49:31.693	\N
1439761744137291394	1438986079402198251	1433172478670144855	2025-02-06 06:49:34.638	\N
1439761778849351300	1438986079402198251	1432141375276582075	2025-02-06 06:49:38.779	\N
1439761836974016134	1438986079402198251	1430501158790628357	2025-02-06 06:49:45.708	\N
1439762109511501448	1438985479381845217	1433172244418266454	2025-02-06 06:50:18.194	\N
1439762117791057548	1438985479381845217	1435352068222093091	2025-02-06 06:50:19.183	\N
1439762125911230094	1438985479381845217	1433172478670144855	2025-02-06 06:50:20.151	\N
1439762623590565520	1439079686972900816	1435352068222093091	2025-02-06 06:51:19.477	\N
1439762646717957780	1439079686972900816	1433172478670144855	2025-02-06 06:51:22.237	\N
1439762677269268118	1439079686972900816	1433297069220562376	2025-02-06 06:51:25.878	\N
1439762769946609304	1439083705543951836	1433297069220562376	2025-02-06 06:51:36.919	\N
1439762865694181018	1439086276258039265	1433172244418266454	2025-02-06 06:51:48.338	\N
1439762886028166812	1439086276258039265	1433172478670144855	2025-02-06 06:51:50.764	\N
1439762957834651294	1439086630081136100	1430501158790628357	2025-02-06 06:51:59.324	\N
1439762963522127520	1439086630081136100	1432141375276582075	2025-02-06 06:52:00.002	\N
1439763099031701156	1439088141725074919	1433172478670144855	2025-02-06 06:52:16.156	\N
1439763110398264998	1439088141725074919	1433297069220562376	2025-02-06 06:52:17.511	\N
1439763358961108648	1438986240270533869	1433172478670144855	2025-02-06 06:52:47.14	\N
1439834371321235150	1438218418741315436	1430501158790628357	2025-02-06 09:13:52.473	\N
1439856243148588771	1438218506888808303	1430501158790628357	2025-02-06 09:57:19.8	\N
1439857479704905452	1439857429213873898	1433171377464018261	2025-02-06 09:59:47.209	\N
1440419232209700663	1440419188186285877	1430534043199341650	2025-02-07 04:35:53.327	\N
1440419245732136761	1440419188186285877	1433261799410501042	2025-02-07 04:35:54.938	\N
1440554066030626650	1438943393743897719	1430501158790628357	2025-02-07 09:03:46.768	\N
1440554491173668701	1438943393743897719	1430525186381186093	2025-02-07 09:04:37.451	\N
1440554607381055327	1438952821910144186	1430525186381186093	2025-02-07 09:04:51.302	\N
1442647978920642461	1442647951951267739	1430534043199341650	2025-02-10 06:24:00.636	\N
1442651917338544033	1442640975624144786	1433172478670144855	2025-02-10 06:31:50.132	\N
1442651924871514019	1442640975624144786	1430525186381186093	2025-02-10 06:31:51.032	\N
1442651932412872613	1442640975624144786	1433297069220562376	2025-02-10 06:31:51.931	\N
1443297201655646179	1439067056858203586	1433172244418266454	2025-02-11 03:53:54.019	\N
1443314050325809128	1443313947582138341	1430534043199341650	2025-02-11 04:27:22.535	\N
1443314119229835242	1443313947582138341	1430501158790628357	2025-02-11 04:27:30.751	\N
1443322909325001728	1443322833382934525	1430534043199341650	2025-02-11 04:44:58.612	\N
1443331611029406722	1443317461578418171	1433171377464018261	2025-02-11 05:02:15.934	\N
1443331620399481860	1443317461578418171	1430525186381186093	2025-02-11 05:02:17.047	\N
1443331624467956742	1443317461578418171	1430501158790628357	2025-02-11 05:02:17.539	\N
1443331629081691144	1443317461578418171	1430534043199341650	2025-02-11 05:02:18.088	\N
1443333122530739215	1443313947582138341	1433172478670144855	2025-02-11 05:05:16.119	\N
1443359783204684822	1438221738298050461	1430534043199341650	2025-02-11 05:58:14.32	\N
1443359805568713752	1438221738298050461	1430525186381186093	2025-02-11 05:58:16.987	\N
1443391757810140191	1443391480080106525	1433172244418266454	2025-02-11 07:01:45.989	\N
1443391932091860005	1443391832913347619	1433172244418266454	2025-02-11 07:02:06.767	\N
1443391951561819177	1443391832913347619	1430525186381186093	2025-02-11 07:02:09.088	\N
1443396380344190007	1443392055991600171	1433172244418266454	2025-02-11 07:10:57.038	\N
1443397506271544392	1443397437266854982	1433172244418266454	2025-02-11 07:13:11.261	\N
1443397815567909968	1443397194441819203	1433172244418266454	2025-02-11 07:13:48.13	\N
1443397853224371284	1443396872721925182	1433172244418266454	2025-02-11 07:13:52.621	\N
1443397945968821336	1443396623278277691	1433172244418266454	2025-02-11 07:14:03.677	\N
1443411115714282591	1443410876563457116	1433172244418266454	2025-02-11 07:40:13.631	\N
1443458272190268520	1443457772355060837	1433172244418266454	2025-02-11 09:13:55.121	\N
1443459222971876463	1443458771580879980	1433172244418266454	2025-02-11 09:15:48.463	\N
1443460306461262966	1443459936733365363	1433172244418266454	2025-02-11 09:17:57.625	\N
1443461157527487613	1443460766970676346	1433172244418266454	2025-02-11 09:19:39.08	\N
1443463731345360005	1443463685484840066	1433172244418266454	2025-02-11 09:24:45.904	\N
1443705159451411606	1433322124021335558	1430525186381186093	2025-02-11 17:24:26.375	\N
1443705169274471576	1433322124021335558	1430534043199341650	2025-02-11 17:24:27.549	\N
1692106060099224776	1692095657243837637	1430525186381186093	2026-01-20 10:52:41.268	\N
1692106073755878602	1692095657243837637	1430534043199341650	2026-01-20 10:52:42.896	\N
1692106079426577612	1692095657243837637	1433261799410501042	2026-01-20 10:52:43.571	\N
1692564079312372956	1692563975067141338	1430534043199341650	2026-01-21 02:02:41.41	\N
1692564085687715038	1692563975067141338	1430525186381186093	2026-01-21 02:02:42.174	\N
1692564090209174752	1692563975067141338	1433261799410501042	2026-01-21 02:02:42.712	\N
\.


--
-- Data for Name: card_subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.card_subscription (id, card_id, user_id, is_permanent, created_at, updated_at) FROM stdin;
1430505615406400531	1430502957912163342	1430501158790628357	f	2025-01-24 12:19:18.109	\N
1430519925272740897	1430519898227868700	1430501158790628357	f	2025-01-24 12:47:43.978	\N
1430525439348048947	1430519898227868700	1430525186381186093	f	2025-01-24 12:58:41.307	\N
1432128363597661296	1432128251324531818	1430525186381186093	f	2025-01-26 18:03:24.769	\N
1432375308790531305	1432375308748588264	1430501158790628357	t	2025-01-27 02:14:02.93	\N
1432376915670336755	1432376915628393714	1430501158790628357	t	2025-01-27 02:17:14.484	\N
1432377073627825398	1432377073594270965	1430501158790628357	t	2025-01-27 02:17:33.315	\N
1432377136055846137	1432377136022291704	1430501158790628357	t	2025-01-27 02:17:40.757	\N
1432379457804436736	1432379457754105087	1430501158790628357	t	2025-01-27 02:22:17.531	\N
1432413910715073797	1432413910664742148	1430501158790628357	t	2025-01-27 03:30:44.637	\N
1432466461007283478	1432466460956951829	1430501158790628357	t	2025-01-27 05:15:09.121	\N
1432467553346651421	1432467553304708380	1430501158790628357	t	2025-01-27 05:17:19.338	\N
1432468538764821795	1432466460956951829	1430534043199341650	f	2025-01-27 05:19:16.809	\N
1432468570113049893	1432467553304708380	1430534043199341650	f	2025-01-27 05:19:20.546	\N
1433096881767974213	1432131205364450429	1430534043199341650	f	2025-01-28 02:07:41.132	\N
1433096987019838791	1432132167101580422	1432141375276582075	f	2025-01-28 02:07:53.679	\N
1433097037166937417	1432133165018776718	1432141375276582075	f	2025-01-28 02:07:59.656	\N
1433097092095542603	1432133249383007377	1432141375276582075	f	2025-01-28 02:08:06.205	\N
1433097146260784461	1432133309344777364	1432141375276582075	f	2025-01-28 02:08:12.662	\N
1433097271041328463	1432143088423273660	1430525186381186093	f	2025-01-28 02:08:27.538	\N
1433097280176522577	1432143088423273660	1430534043199341650	f	2025-01-28 02:08:28.626	\N
1433179341616842089	1432128234438263911	1430525186381186093	f	2025-01-28 04:51:31.112	\N
1433268880192570805	1433259305485731246	1430534043199341650	f	2025-01-28 07:49:24.942	\N
1433268920231396791	1433261051297662384	1430534043199341650	f	2025-01-28 07:49:29.715	\N
1433304217900025300	1433303096687068625	1433261799410501042	f	2025-01-28 08:59:37.526	\N
1433313705751217628	1433233702573311364	1433261799410501042	f	2025-01-28 09:18:28.565	\N
1433314041605916126	1433241292510332304	1433261799410501042	f	2025-01-28 09:19:08.598	\N
1433314513590945250	1433314479944238559	1433261799410501042	f	2025-01-28 09:20:04.867	\N
1433317338093979116	1433317255122257385	1433261799410501042	f	2025-01-28 09:25:41.574	\N
1433318009694324208	1433317981407938029	1430525186381186093	f	2025-01-28 09:27:01.635	\N
1433320152002201083	1433320073308669432	1433261799410501042	f	2025-01-28 09:31:17.017	\N
1433320540789016063	1433320514390066684	1430534043199341650	f	2025-01-28 09:32:03.365	\N
1433323841655932427	1433323812958504456	1430525186381186093	f	2025-01-28 09:38:36.859	\N
1433944433174251076	1433944122544096833	1430534043199341650	f	2025-01-29 06:11:37.133	\N
1434026227143804500	1434026103898375761	1430534043199341650	f	2025-01-29 08:54:07.734	\N
1434030414753695326	1434028784092186199	1430534043199341650	f	2025-01-29 09:02:26.936	\N
1434038600583874167	1434037967428519538	1430534043199341650	f	2025-01-29 09:18:42.763	\N
1434038910031234685	1434038848156862074	1433261799410501042	f	2025-01-29 09:19:19.649	\N
1434635457215334076	1434038162799199860	1430534043199341650	f	2025-01-30 05:04:33.618	\N
1434737567026120447	1434729164375590648	1433172244418266454	f	2025-01-30 08:27:26.056	\N
1434737578828891907	1434729164375590648	1433172478670144855	f	2025-01-30 08:27:27.463	\N
1434737584499590917	1434729164375590648	1430525186381186093	f	2025-01-30 08:27:28.139	\N
1434737590791046919	1434729164375590648	1433297069220562376	f	2025-01-30 08:27:28.89	\N
1435347276775032598	1435346986613081875	1433261799410501042	f	2025-01-31 04:38:49.122	\N
1435347680107693856	1435346986613081875	1433172478670144855	f	2025-01-31 04:39:37.203	\N
1435352907502323494	1434109361990403733	1435352068222093091	f	2025-01-31 04:50:00.357	\N
1437713118087087952	1433316010454156773	1430534043199341650	f	2025-02-03 10:59:19.384	\N
1438216876923553624	1433254977265993112	1433261799410501042	f	2025-02-04 03:40:12.117	\N
1438216895479154522	1433254977265993112	1435352068222093091	f	2025-02-04 03:40:14.329	\N
1438218588207974259	1438218418741315436	1430525186381186093	f	2025-02-04 03:43:36.119	\N
1438218592351946613	1438218418741315436	1430534043199341650	f	2025-02-04 03:43:36.612	\N
1438218606805518199	1438218418741315436	1433171377464018261	f	2025-02-04 03:43:38.333	\N
1438218704708962179	1438218506888808303	1430525186381186093	f	2025-02-04 03:43:50.006	\N
1438218724447356805	1438218506888808303	1433171377464018261	f	2025-02-04 03:43:52.359	\N
1438218733179897735	1438218506888808303	1430534043199341650	f	2025-02-04 03:43:53.4	\N
1438934235346895899	1438933352294908940	1433172244418266454	f	2025-02-05 03:25:27.905	\N
1438934252551930911	1438933352294908940	1430525186381186093	f	2025-02-05 03:25:29.956	\N
1438934257811588129	1438933352294908940	1433172478670144855	f	2025-02-05 03:25:30.583	\N
1438934262861530147	1438933352294908940	1430501158790628357	f	2025-02-05 03:25:31.186	\N
1438934268205073445	1438933352294908940	1433297069220562376	f	2025-02-05 03:25:31.823	\N
1438934744459904051	1438933352294908940	1433261799410501042	f	2025-02-05 03:26:28.596	\N
1438934760859632695	1438933352294908940	1432141375276582075	f	2025-02-05 03:26:30.552	\N
1438934774499509305	1438933352294908940	1435352068222093091	f	2025-02-05 03:26:32.177	\N
1438934887284343869	1434710292574504669	1433172244418266454	f	2025-02-05 03:26:45.622	\N
1438934894456603711	1434710292574504669	1433172478670144855	f	2025-02-05 03:26:46.477	\N
1438934914631205953	1434710292574504669	1430525186381186093	f	2025-02-05 03:26:48.883	\N
1438934937993479237	1434710292574504669	1433297069220562376	f	2025-02-05 03:26:51.667	\N
1438935254613099593	1438934380025218090	1433172244418266454	f	2025-02-05 03:27:29.412	\N
1438935298259027023	1438934380025218090	1430525186381186093	f	2025-02-05 03:27:34.614	\N
1438935334581699667	1438934380025218090	1433297069220562376	f	2025-02-05 03:27:38.944	\N
1438939760058958949	1438938542184072287	1430501158790628357	f	2025-02-05 03:36:26.502	\N
1438945453767918723	1434041555689145990	1433297069220562376	f	2025-02-05 03:47:45.244	\N
1438948118669296793	1438944089067226234	1433172478670144855	f	2025-02-05 03:53:02.926	\N
1438948127141790875	1438944089067226234	1430525186381186093	f	2025-02-05 03:53:03.936	\N
1438948131319317661	1438944089067226234	1433297069220562376	f	2025-02-05 03:53:04.434	\N
1438948742395856035	1438948712406582432	1433171377464018261	f	2025-02-05 03:54:17.28	\N
1438948750734132389	1438948712406582432	1433172478670144855	f	2025-02-05 03:54:18.274	\N
1438948757780563111	1438948712406582432	1430525186381186093	f	2025-02-05 03:54:19.114	\N
1438950059516363958	1438949933292979375	1433297069220562376	f	2025-02-05 03:56:54.293	\N
1438950085479105720	1438949933292979375	1433172478670144855	f	2025-02-05 03:56:57.388	\N
1438979471225914571	1438979442184553672	1433172478670144855	f	2025-02-05 04:55:20.442	\N
1438980437216068817	1438980312225809613	1433172478670144855	f	2025-02-05 04:57:15.597	\N
1438980465091413203	1438980312225809613	1433297069220562376	f	2025-02-05 04:57:18.92	\N
1438980482212562133	1438980312225809613	1433172244418266454	f	2025-02-05 04:57:20.961	\N
1439000289569932556	1439000237099189513	1433297069220562376	f	2025-02-05 05:36:42.182	\N
1439000322696545550	1439000237099189513	1433172478670144855	f	2025-02-05 05:36:46.131	\N
1439002012631958803	1438991493367858438	1433172244418266454	f	2025-02-05 05:40:07.587	\N
1439002028293489943	1438991493367858438	1433261799410501042	f	2025-02-05 05:40:09.455	\N
1439002049407616281	1438991493367858438	1433297069220562376	f	2025-02-05 05:40:11.971	\N
1439019781490476346	1439009557144667431	1433172244418266454	f	2025-02-05 06:15:25.8	\N
1439019805985211710	1439009557144667431	1433172478670144855	f	2025-02-05 06:15:28.72	\N
1439019819859969344	1439009557144667431	1430525186381186093	f	2025-02-05 06:15:30.373	\N
1439019830907766082	1439009557144667431	1433297069220562376	f	2025-02-05 06:15:31.691	\N
1439019943239615814	1439009814079341866	1433172244418266454	f	2025-02-05 06:15:45.082	\N
1439019967465915724	1439009814079341866	1433172478670144855	f	2025-02-05 06:15:47.971	\N
1439019979998496078	1439009814079341866	1433297069220562376	f	2025-02-05 06:15:49.464	\N
1439019992422024528	1439009814079341866	1430525186381186093	f	2025-02-05 06:15:50.945	\N
1439020094452663636	1439010075208320301	1433172244418266454	f	2025-02-05 06:16:03.108	\N
1439020153709790552	1439010075208320301	1433172478670144855	f	2025-02-05 06:16:10.172	\N
1439020186576356698	1439010075208320301	1430525186381186093	f	2025-02-05 06:16:14.09	\N
1439020194251933020	1439010075208320301	1433297069220562376	f	2025-02-05 06:16:15.005	\N
1439020269371917666	1439010281844901169	1433172244418266454	f	2025-02-05 06:16:23.961	\N
1439020280654595430	1439010281844901169	1433172478670144855	f	2025-02-05 06:16:25.305	\N
1439020298740434280	1439010281844901169	1433297069220562376	f	2025-02-05 06:16:27.462	\N
1439020313747653994	1439010281844901169	1430525186381186093	f	2025-02-05 06:16:29.25	\N
1439058453132739999	1439058369607370137	1433297069220562376	f	2025-02-05 07:32:15.82	\N
1439058463341675937	1439058369607370137	1433172244418266454	f	2025-02-05 07:32:17.037	\N
1439058474037151139	1439058369607370137	1433172478670144855	f	2025-02-05 07:32:18.311	\N
1439083116554618326	1439082514009294291	1435352068222093091	f	2025-02-05 08:21:15.928	\N
1439083129758287320	1439082514009294291	1433261799410501042	f	2025-02-05 08:21:17.501	\N
1439094156533171691	1438431374158596053	1433261799410501042	f	2025-02-05 08:43:11.996	\N
1439644536375608846	1439644478963975691	1430534043199341650	f	2025-02-06 02:56:42.386	\N
1439672723667158547	1438952821910144186	1433172244418266454	f	2025-02-06 03:52:42.573	\N
1439672739781674517	1438952821910144186	1430501158790628357	f	2025-02-06 03:52:44.495	\N
1439672746232514071	1438952821910144186	1430534043199341650	f	2025-02-06 03:52:45.264	\N
1439689165791823411	1439689109495875119	1433172478670144855	f	2025-02-06 04:25:22.628	\N
1439689173266073141	1439689109495875119	1433171377464018261	f	2025-02-06 04:25:23.518	\N
1439689179129710135	1439689109495875119	1430525186381186093	f	2025-02-06 04:25:24.217	\N
1439689184196429369	1439689109495875119	1433297069220562376	f	2025-02-06 04:25:24.821	\N
1439694642814649915	1438943393743897719	1433172244418266454	f	2025-02-06 04:36:15.539	\N
1439694712691754559	1438943393743897719	1430534043199341650	f	2025-02-06 04:36:23.87	\N
1439758261212415573	1439758144677873231	1433172244418266454	f	2025-02-06 06:42:39.442	\N
1439758295219832409	1439758144677873231	1430525186381186093	f	2025-02-06 06:42:43.497	\N
1439758383056946781	1439130116532733425	1433172244418266454	f	2025-02-06 06:42:53.968	\N
1439758462555784799	1439129941546370543	1433172478670144855	f	2025-02-06 06:43:03.445	\N
1439760265468970597	1438948922079839401	1433172478670144855	f	2025-02-06 06:46:38.364	\N
1439760295802177127	1438948922079839401	1433297069220562376	f	2025-02-06 06:46:41.985	\N
1439760331319543401	1438948922079839401	1433172244418266454	f	2025-02-06 06:46:46.219	\N
1439761113607571053	1438985509941544163	1433172478670144855	f	2025-02-06 06:48:19.475	\N
1439761163544954481	1438985509941544163	1432141375276582075	f	2025-02-06 06:48:25.428	\N
1439761229806569075	1438985685389280485	1433172244418266454	f	2025-02-06 06:48:33.327	\N
1439761238497166965	1438985685389280485	1433172478670144855	f	2025-02-06 06:48:34.364	\N
1439761413257037433	1438985758336615655	1435352068222093091	f	2025-02-06 06:48:55.197	\N
1439761487060010619	1438985957750605033	1433172244418266454	f	2025-02-06 06:49:03.994	\N
1439761493519238781	1438985957750605033	1433172478670144855	f	2025-02-06 06:49:04.764	\N
1439761719466395263	1438986079402198251	1435352068222093091	f	2025-02-06 06:49:31.7	\N
1439761744162457219	1438986079402198251	1433172478670144855	f	2025-02-06 06:49:34.643	\N
1439761778874517125	1438986079402198251	1432141375276582075	f	2025-02-06 06:49:38.782	\N
1439761836999181959	1438986079402198251	1430501158790628357	f	2025-02-06 06:49:45.71	\N
1439762109561833097	1438985479381845217	1433172244418266454	f	2025-02-06 06:50:18.202	\N
1439762117816223373	1438985479381845217	1435352068222093091	f	2025-02-06 06:50:19.186	\N
1439762125961561743	1438985479381845217	1433172478670144855	f	2025-02-06 06:50:20.155	\N
1439762623624119953	1439079686972900816	1435352068222093091	f	2025-02-06 06:51:19.483	\N
1439762646751512213	1439079686972900816	1433172478670144855	f	2025-02-06 06:51:22.24	\N
1439762677294433943	1439079686972900816	1433297069220562376	f	2025-02-06 06:51:25.881	\N
1439762770013718169	1439083705543951836	1433297069220562376	f	2025-02-06 06:51:36.934	\N
1439762865727735451	1439086276258039265	1433172244418266454	f	2025-02-06 06:51:48.344	\N
1439762886053332637	1439086276258039265	1433172478670144855	f	2025-02-06 06:51:50.767	\N
1439762957901760159	1439086630081136100	1430501158790628357	f	2025-02-06 06:51:59.332	\N
1439762963538904737	1439086630081136100	1432141375276582075	f	2025-02-06 06:52:00.005	\N
1439763099056866981	1439088141725074919	1433172478670144855	f	2025-02-06 06:52:16.16	\N
1439763110423430823	1439088141725074919	1433297069220562376	f	2025-02-06 06:52:17.514	\N
1439763359003051689	1438986240270533869	1433172478670144855	f	2025-02-06 06:52:47.147	\N
1439834371363178191	1438218418741315436	1430501158790628357	f	2025-02-06 09:13:52.48	\N
1439856243182143204	1438218506888808303	1430501158790628357	f	2025-02-06 09:57:19.804	\N
1439857479738459885	1439857429213873898	1433171377464018261	f	2025-02-06 09:59:47.213	\N
1440419232260032312	1440419188186285877	1430534043199341650	f	2025-02-07 04:35:53.332	\N
1440419245757302586	1440419188186285877	1433261799410501042	f	2025-02-07 04:35:54.941	\N
1440554066080958299	1438943393743897719	1430501158790628357	f	2025-02-07 09:03:46.776	\N
1440554491198834526	1438943393743897719	1430525186381186093	f	2025-02-07 09:04:37.454	\N
1440554607431386976	1438952821910144186	1430525186381186093	f	2025-02-07 09:04:51.309	\N
1442647978954196894	1442647951951267739	1430534043199341650	f	2025-02-10 06:24:00.643	\N
1442651917372098466	1442640975624144786	1433172478670144855	f	2025-02-10 06:31:50.138	\N
1442651924896679844	1442640975624144786	1430525186381186093	f	2025-02-10 06:31:51.035	\N
1442651932446427046	1442640975624144786	1433297069220562376	f	2025-02-10 06:31:51.935	\N
1443297201680812004	1439067056858203586	1433172244418266454	f	2025-02-11 03:53:54.022	\N
1443313947624081382	1443313947582138341	1430501158790628357	t	2025-02-11 04:27:10.294	\N
1443314050359363561	1443313947582138341	1430534043199341650	f	2025-02-11 04:27:22.541	\N
1443322909375333377	1443322833382934525	1430534043199341650	f	2025-02-11 04:44:58.618	\N
1443331611062961155	1443317461578418171	1433171377464018261	f	2025-02-11 05:02:15.94	\N
1443331620424647685	1443317461578418171	1430525186381186093	f	2025-02-11 05:02:17.056	\N
1443331624493122567	1443317461578418171	1430501158790628357	f	2025-02-11 05:02:17.542	\N
1443331629098468361	1443317461578418171	1430534043199341650	f	2025-02-11 05:02:18.091	\N
1443333122564293648	1443313947582138341	1433172478670144855	f	2025-02-11 05:05:16.125	\N
1443359783246627863	1438221738298050461	1430534043199341650	f	2025-02-11 05:58:14.326	\N
1443359805602268185	1438221738298050461	1430525186381186093	f	2025-02-11 05:58:16.991	\N
1443391757835306016	1443391480080106525	1433172244418266454	f	2025-02-11 07:01:45.994	\N
1443391932133803046	1443391832913347619	1433172244418266454	f	2025-02-11 07:02:06.772	\N
1443391951586985002	1443391832913347619	1430525186381186093	f	2025-02-11 07:02:09.091	\N
1443396380377744440	1443392055991600171	1433172244418266454	f	2025-02-11 07:10:57.044	\N
1443397506296710217	1443397437266854982	1433172244418266454	f	2025-02-11 07:13:11.264	\N
1443397815593075793	1443397194441819203	1433172244418266454	f	2025-02-11 07:13:48.135	\N
1443397853257925717	1443396872721925182	1433172244418266454	f	2025-02-11 07:13:52.625	\N
1443397946111427673	1443396623278277691	1433172244418266454	f	2025-02-11 07:14:03.694	\N
1443411115756225632	1443410876563457116	1433172244418266454	f	2025-02-11 07:40:13.638	\N
1443458272232211561	1443457772355060837	1433172244418266454	f	2025-02-11 09:13:55.127	\N
1443459223013819504	1443458771580879980	1433172244418266454	f	2025-02-11 09:15:48.47	\N
1443460306503206007	1443459936733365363	1433172244418266454	f	2025-02-11 09:17:57.631	\N
1443461157561042046	1443460766970676346	1433172244418266454	f	2025-02-11 09:19:39.086	\N
1443463731387303046	1443463685484840066	1433172244418266454	f	2025-02-11 09:24:45.91	\N
1443705159510131863	1433322124021335558	1430525186381186093	f	2025-02-11 17:24:26.384	\N
1443705169308026009	1433322124021335558	1430534043199341650	f	2025-02-11 17:24:27.554	\N
1692106060141167817	1692095657243837637	1430525186381186093	f	2026-01-20 10:52:41.273	\N
1692106073781044427	1692095657243837637	1430534043199341650	f	2026-01-20 10:52:42.899	\N
1692106079493686477	1692095657243837637	1433261799410501042	f	2026-01-20 10:52:43.579	\N
1692564079505310941	1692563975067141338	1430534043199341650	f	2026-01-21 02:02:41.424	\N
1692564085721269471	1692563975067141338	1430525186381186093	f	2026-01-21 02:02:42.177	\N
1692564090234340577	1692563975067141338	1433261799410501042	f	2026-01-21 02:02:42.715	\N
\.


--
-- Data for Name: identity_provider_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.identity_provider_user (id, user_id, issuer, sub, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: label; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.label (id, board_id, name, color, created_at, updated_at, "position") FROM stdin;
1430521857034945578	1430501369143362568	BUG	berry-red	2025-01-24 12:51:34.261	\N	65535
1430534691303195731	1430501369143362568	URGENT	apricot-red	2025-01-24 13:17:04.225	\N	131070
1432127948789384294	1430501369143362568	Backend	navy-blue	2025-01-26 18:02:35.318	\N	196605
1432134540909872285	1430501369143362568	Frontend	sunny-grass	2025-01-26 18:15:41.16	\N	262140
1432134710787572894	1430501369143362568	Admin Panel	light-orange	2025-01-26 18:16:01.411	\N	327675
1432143823156282559	1430501369143362568	Report	morning-sky	2025-01-26 18:34:07.69	\N	393210
1438932922672350218	1438929169743349745	Mizuno Morelia Brand Book	bright-moss	2025-02-05 03:22:51.42	\N	65535
1438933479910802446	1434703208386660040	Mizuno Morelia Brand Book	bright-moss	2025-02-05 03:23:57.848	\N	131070
1434738218804184840	1434703208386660040	AW25 Sell-out	berry-red	2025-01-30 08:28:43.75	2025-02-05 03:24:38.473	65535
1438933965258884120	1434703208386660040	SS26 Sell-in	lagoon-blue	2025-02-05 03:24:55.707	\N	196605
1438934154874979353	1434703208386660040	Mizuno Morelia Summit	coral-green	2025-02-05 03:25:18.31	\N	262140
1438940409093948527	1434610219668735665	Monthly Report	berry-red	2025-02-05 03:37:43.873	\N	65535
1438940658101388401	1434610219668735665	Documentary Report	pumpkin-orange	2025-02-05 03:38:13.555	\N	131070
1438947501511017611	1433174649205687643	Cerezo SNS	pink-tulip	2025-02-05 03:51:49.353	\N	65535
1438947622474744974	1433174649205687643	Cerezo Cup	berry-red	2025-02-05 03:52:03.775	\N	131070
1438948326689997982	1433174649205687643	Client	sunny-grass	2025-02-05 03:53:27.722	\N	196605
1439182914045609461	1438940137017836646	SHOOTING	pumpkin-orange	2025-02-05 11:39:32.714	\N	65535
1439183260277016055	1438940137017836646	Make Product	lagoon-blue	2025-02-05 11:40:13.989	2025-02-05 11:40:21.702	131070
1439677686770304545	1438940137017836646	Contenet	pink-tulip	2025-02-06 04:02:34.219	2025-02-06 04:02:45.532	196605
1443286233391302623	1442584975609169775	Impekable	berry-red	2025-02-11 03:32:06.498	\N	65535
1692123320792646870	1692048962560722096	Need to be fixed	berry-red	2026-01-20 11:26:58.901	\N	65535
\.


--
-- Data for Name: list; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.list (id, board_id, "position", name, created_at, updated_at) FROM stdin;
1430502915348366349	1430501369143362568	65535	Backlog	2025-01-24 12:13:56.235	2025-01-24 13:11:15.16
1430532224431686727	1430501369143362568	196605	Review / Test	2025-01-24 13:12:10.153	\N
1430532303922136136	1430501369143362568	262140	Wait for release	2025-01-24 13:12:19.628	\N
1430532330472080457	1430501369143362568	327675	Released	2025-01-24 13:12:22.795	\N
1430532616615887950	1430501369143362568	98302.5	Blocked	2025-01-24 13:12:56.903	2025-01-24 13:12:59.918
1430531972286907461	1430501369143362568	131070	In Progress	2025-01-24 13:11:40.092	2025-01-24 13:13:05.747
1432374767146501348	1432374743171859682	65535	Design	2025-01-27 02:12:58.361	\N
1432374918888031461	1432374743171859682	131070	QC Alignments	2025-01-27 02:13:16.448	\N
1432374954464117990	1432374743171859682	196605	QC Facts	2025-01-27 02:13:20.69	\N
1432375629638010094	1432374743171859682	262140	Submit to client	2025-01-27 02:14:41.176	\N
1432376741665441009	1432374743171859682	114686.25	ISSUES	2025-01-27 02:16:53.74	2025-01-27 04:20:30.195
1442585764046047094	1442584975609169775	393210	Released	2025-02-10 04:20:24.047	\N
1432375112018953447	1432374743171859682	122878.125	Upwork Fixing the pptx File	2025-01-27 02:13:39.47	2025-01-27 04:21:13.419
1442585953032996727	1442584220726724453	65535	Backlog	2025-02-10 04:20:46.575	\N
1433174850783937888	1433174649205687643	131070	Get Assets	2025-01-28 04:42:35.764	2025-01-28 05:16:03.574
1433174831095874911	1433174649205687643	65535	Content Backlog	2025-01-28 04:42:33.414	2025-01-28 05:16:05.885
1433174865606608225	1433174649205687643	196605	In Progress	2025-01-28 04:42:37.53	2025-01-28 05:16:21.942
1433192158453564789	1433174649205687643	262140	Internal QC	2025-01-28 05:16:58.996	\N
1433192294869108087	1433174649205687643	327675	Cerezo JP QC	2025-01-28 05:17:15.26	\N
1433192321335166328	1433174649205687643	393210	Approved	2025-01-28 05:17:18.415	\N
1433192440268850553	1433174649205687643	458745	Scheduled / Posted	2025-01-28 05:17:32.591	\N
1433255711814452638	1433174649205687643	163837.5	Blocked	2025-01-28 07:23:15.147	2025-01-28 07:23:20.377
1434615722369091251	1434609694726424238	65535	Content	2025-01-30 04:25:21.039	\N
1434615989680473780	1434609694726424238	131070	Get Assest	2025-01-30 04:25:52.904	\N
1434618422737503925	1434609694726424238	196605	In Progress	2025-01-30 04:30:42.948	2025-01-30 04:31:49.447
1434619182476953271	1434609694726424238	327675	Approved	2025-01-30 04:32:13.516	\N
1434619449494734520	1434609694726424238	393210	Posted	2025-01-30 04:32:45.346	\N
1434620820553991865	1434609694726424238	294907.5	External QC	2025-01-30 04:35:28.789	2025-01-30 04:35:35.241
1434619082375694006	1434609694726424238	262140	Internal QC	2025-01-30 04:32:01.582	2025-01-30 04:35:46.673
1434703542295201484	1434703208386660040	65535	To-do Task	2025-01-30 07:19:49.99	\N
1434704734609999566	1434703208386660040	196605	In Progress	2025-01-30 07:22:12.124	\N
1434705078811363023	1434703208386660040	262140	Post-Production	2025-01-30 07:22:53.157	\N
1442585988416145272	1442584220726724453	131070	Blocked	2025-02-10 04:20:50.793	\N
1442586170725762937	1442584220726724453	196605	In Progress	2025-02-10 04:21:12.525	\N
1434705378695710416	1434703208386660040	327675	Review Work / Internal QC	2025-01-30 07:23:28.906	2025-01-30 07:23:58.739
1434706095107999441	1434703208386660040	393210	Deliverables	2025-01-30 07:24:54.309	\N
1434706364726249171	1434703208386660040	360442.5	Mizuno JP QC	2025-01-30 07:25:26.449	2025-01-30 07:25:30.225
1434706150573475538	1434703208386660040	376826.25	Approved / Done	2025-01-30 07:25:00.923	2025-01-30 07:25:32.142
1438421969388177351	1433174649205687643	180221.25	Outsource	2025-02-04 10:27:41.042	2025-02-04 10:27:48.881
1438927743671601128	1438927712809912294	65535	เ	2025-02-05 03:12:34.037	\N
1438928891317061613	1433174703312209245	65535	Content Backlog	2025-02-05 03:14:50.847	\N
1438928962880276463	1433174703312209245	131070	Get Assets	2025-02-05 03:14:59.378	\N
1438929026977630192	1433174703312209245	196605	Blocked	2025-02-05 03:15:07.019	\N
1438929933786154997	1438929169743349745	65535	To-do Task	2025-02-05 03:16:55.118	\N
1438930058046605302	1438929169743349745	131070	Discuss / Brainstorm	2025-02-05 03:17:09.93	\N
1438930156503697399	1438929169743349745	196605	In Progress	2025-02-05 03:17:21.668	\N
1438930265077450744	1438929169743349745	262140	Review Work / Internal QC	2025-02-05 03:17:34.61	\N
1438930346228844537	1438929169743349745	327675	Mizuno JP QC	2025-02-05 03:17:44.286	\N
1438930408472315898	1438929169743349745	393210	Approved / Done	2025-02-05 03:17:51.706	\N
1438930467964323835	1438929169743349745	458745	Deliverables	2025-02-05 03:17:58.797	\N
1438931679346427902	1434708514550318811	65535	To-do Task	2025-02-05 03:20:23.203	2025-02-05 03:20:37.767
1438943147529864310	1434610219668735665	65535	To-do Task	2025-02-05 03:43:10.318	\N
1438944836827743356	1434610219668735665	131070	Get Assest	2025-02-05 03:46:31.698	\N
1438944971691394174	1434610219668735665	196605	In Progress	2025-02-05 03:46:47.777	\N
1438945086774707327	1434610219668735665	262140	Internal QC	2025-02-05 03:47:01.494	\N
1438945540606788740	1434610219668735665	327675	Approved	2025-02-05 03:47:55.597	\N
1438949766678447278	1438940137017836646	65535	To-do list / Task	2025-02-05 03:56:19.382	\N
1439184983741695481	1438940137017836646	131070	Block	2025-02-05 11:43:39.44	\N
1439185921311245818	1438940137017836646	196605	Imposed	2025-02-05 11:45:31.208	\N
1439186122411345403	1438940137017836646	262140	Approved / Done	2025-02-05 11:45:55.181	\N
1434704207083996877	1434703208386660040	131070	Block	2025-01-30 07:21:09.239	2025-02-06 04:05:51.605
1440417324245976864	1433174649205687643	524280	Meeting / Report	2025-02-07 04:32:05.877	2025-02-07 04:32:19.077
1442585390165788529	1442584975609169775	65535	Backlog	2025-02-10 04:19:39.475	\N
1442585446637897586	1442584975609169775	131070	Blocked	2025-02-10 04:19:46.209	2025-02-10 04:19:49.39
1442585552250472307	1442584975609169775	196605	InProgress	2025-02-10 04:19:58.798	\N
1442585624451221364	1442584975609169775	262140	Review / Test	2025-02-10 04:20:07.406	\N
1442585734761416565	1442584975609169775	327675	Wait for release	2025-02-10 04:20:20.554	\N
1442586235645200250	1442584220726724453	262140	Review / Test	2025-02-10 04:21:20.267	\N
1442586286111065979	1442584220726724453	327675	Wait for release	2025-02-10 04:21:26.282	\N
1442586306931591036	1442584220726724453	393210	Released	2025-02-10 04:21:28.765	\N
1692095067222705340	1692048962560722096	65535	Content Backlog	2026-01-20 10:30:50.813	\N
1692095121488610493	1692048962560722096	131070	Get Assets	2026-01-20 10:30:57.284	\N
1692095197967549630	1692048962560722096	196605	Blocked	2026-01-20 10:31:06.401	\N
1692095239918978239	1692048962560722096	262140	Outsource	2026-01-20 10:31:11.402	\N
1692095280813442240	1692048962560722096	327675	In Progress	2026-01-20 10:31:16.278	\N
1692095336203420865	1692048962560722096	393210	Internal QC	2026-01-20 10:31:22.88	\N
1692095364238148802	1692048962560722096	458745	J.LEAGUE QC	2026-01-20 10:31:26.202	\N
1692095426540340419	1692048962560722096	524280	Approved	2026-01-20 10:31:33.649	\N
1692095507297469636	1692048962560722096	589815	Scheduled/Posted	2026-01-20 10:31:43.275	\N
\.


--
-- Data for Name: migration; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.migration (id, name, batch, migration_time) FROM stdin;
1	20180721020022_create_next_id_function.js	1	2025-01-24 11:29:10.115+00
2	20180721021044_create_archive_table.js	1	2025-01-24 11:29:10.136+00
3	20180721220409_create_user_account_table.js	1	2025-01-24 11:29:10.152+00
4	20180721233450_create_project_table.js	1	2025-01-24 11:29:10.16+00
5	20180721234154_create_project_manager_table.js	1	2025-01-24 11:29:10.172+00
6	20180722000627_create_board_table.js	1	2025-01-24 11:29:10.19+00
7	20180722001747_create_board_membership_table.js	1	2025-01-24 11:29:10.201+00
8	20180722003437_create_label_table.js	1	2025-01-24 11:29:10.212+00
9	20180722003502_create_list_table.js	1	2025-01-24 11:29:10.228+00
10	20180722003614_create_card_table.js	1	2025-01-24 11:29:10.249+00
11	20180722005122_create_card_subscription_table.js	1	2025-01-24 11:29:10.264+00
12	20180722005359_create_card_membership_table.js	1	2025-01-24 11:29:10.28+00
13	20180722005928_create_card_label_table.js	1	2025-01-24 11:29:10.296+00
14	20180722006570_create_task_table.js	1	2025-01-24 11:29:10.314+00
15	20180722006688_create_attachment_table.js	1	2025-01-24 11:29:10.326+00
16	20181024220134_create_action_table.js	1	2025-01-24 11:29:10.341+00
17	20181112104653_create_notification_table.js	1	2025-01-24 11:29:10.361+00
18	20220523131229_add_image_to_attachment_table.js	1	2025-01-24 11:29:10.365+00
19	20220713145452_add_position_to_task_table.js	1	2025-01-24 11:29:10.371+00
20	20220725150723_add_language_to_user_account_table.js	1	2025-01-24 11:29:10.372+00
21	20220729142434_add_index_on_type_to_action_table.js	1	2025-01-24 11:29:10.376+00
22	20220803221221_add_password_changed_at_to_user_account_table.js	1	2025-01-24 11:29:10.377+00
23	20220815155645_add_permissions_to_board_membership_table.js	1	2025-01-24 11:29:10.384+00
24	20220906094517_create_session_table.js	1	2025-01-24 11:29:10.401+00
25	20221003140000_@.js	1	2025-01-24 11:29:10.402+00
26	20221223131625_preserve_original_format_of_images.js	1	2025-01-24 11:29:10.408+00
27	20221225224651_remove_board_types.js.js	1	2025-01-24 11:29:10.41+00
28	20221226210239_improve_quality_of_resized_images.js	1	2025-01-24 11:29:10.413+00
29	20230108213138_labels_reordering.js	1	2025-01-24 11:29:10.419+00
30	20230227170557_rename_timer_to_stopwatch.js	1	2025-01-24 11:29:10.42+00
31	20230809022050_oidc_with_pkce_flow.js	1	2025-01-24 11:29:10.439+00
32	20240721171239_languages_with_country_codes.js	1	2025-01-24 11:29:10.441+00
33	20240812065305_make_due_date_toggleable.js	1	2025-01-24 11:29:10.443+00
34	20240831195806_additional_http_only_token_for_enhanced_security_in_browsers.js	1	2025-01-24 11:29:10.444+00
\.


--
-- Data for Name: migration_lock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.migration_lock (index, is_locked) FROM stdin;
1	0
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.notification (id, user_id, action_id, card_id, is_read, created_at, updated_at) FROM stdin;
1438218653421012863	1430534043199341650	1438218653144188796	1438218418741315436	t	2025-02-04 03:43:43.866	2025-02-05 03:28:07.692
1438937409260618846	1433330078485317156	1438937409193509981	1433316650974709223	f	2025-02-05 03:31:46.265	\N
1438945626279642246	1433297069220562376	1438945626220921989	1434041555689145990	f	2025-02-05 03:48:05.81	\N
1438945706852222088	1433297069220562376	1438945706810279047	1434041555689145990	f	2025-02-05 03:48:15.415	\N
1438218653370681214	1433171377464018261	1438218653144188796	1438218418741315436	t	2025-02-04 03:43:43.867	2025-02-05 03:54:34.734
1439004132122821916	1434714317982271199	1439004132013770011	1434710292574504669	f	2025-02-05 05:44:20.246	\N
1439004132349314335	1433297069220562376	1439004132013770011	1434710292574504669	f	2025-02-05 05:44:20.25	\N
1430528319727600697	1430524402960696364	1430528319534662711	1430519898227868700	t	2025-01-24 13:04:24.663	2025-01-24 13:12:09.309
1430530140198143038	1430524402960696364	1430530139845821500	1430519898227868700	t	2025-01-24 13:08:01.662	2025-01-24 13:12:09.309
1430530453185496130	1430524402960696364	1430530452816397376	1430519898227868700	t	2025-01-24 13:08:38.981	2025-01-24 13:12:09.309
1439004132466754846	1430525186381186093	1439004132013770011	1434710292574504669	t	2025-02-05 05:44:20.248	2025-02-05 06:47:05.883
1438422116734076876	1433261799410501042	1438422116608247755	1433300241649501641	t	2025-02-04 10:27:58.602	2025-02-05 07:13:20.843
1438422717970778066	1430534043199341650	1438422717912057809	1433261051297662384	t	2025-02-04 10:29:10.282	2025-02-05 11:56:26.597
1430532340110591051	1430480385812202497	1430532340035093578	1430519898227868700	t	2025-01-24 13:12:23.942	2025-01-24 13:16:49.562
1430520866029962276	1430501158790628357	1430520865954464803	1430519898227868700	t	2025-01-24 12:49:36.126	2025-01-25 02:52:29.473
1430520943616197670	1430501158790628357	1430520943221933093	1430519898227868700	t	2025-01-24 12:49:45.374	2025-01-25 02:52:29.473
1430528319626937400	1430501158790628357	1430528319534662711	1430519898227868700	t	2025-01-24 13:04:24.663	2025-01-25 02:52:29.473
1430530139946484797	1430501158790628357	1430530139845821500	1430519898227868700	t	2025-01-24 13:08:01.661	2025-01-25 02:52:29.473
1430530453017723969	1430501158790628357	1430530452816397376	1430519898227868700	t	2025-01-24 13:08:38.979	2025-01-25 02:52:29.473
1430532340295140429	1430501158790628357	1430532340035093578	1430519898227868700	t	2025-01-24 13:12:23.942	2025-01-25 02:52:29.473
1438218607896037241	1430524402960696364	1438218607862482808	1438218124980651878	t	2025-02-04 03:43:38.466	2025-02-06 04:59:52.968
1430945234157569113	1430524402960696364	1430945233931076695	1430519898227868700	f	2025-01-25 02:52:44.731	\N
1438422562613757904	1430534043199341650	1438422562555037647	1433259305485731246	t	2025-02-04 10:28:51.762	2025-02-06 11:41:20.444
1430945234014962776	1430480385812202497	1430945233931076695	1430519898227868700	t	2025-01-25 02:52:44.73	2025-01-26 17:59:35.065
1435347538491213596	1433172478670144855	1435347538331830042	1434109361990403733	t	2025-01-31 04:39:20.31	2025-02-07 03:43:00.483
1438931810359706624	1433330078485317156	1438931810292598783	1437711172743726910	t	2025-02-05 03:20:38.824	2025-02-07 04:59:53.013
1435360556109268780	1433330078485317156	1435360556042159915	1433232704547063170	t	2025-01-31 05:05:12.142	2025-02-07 12:26:37.431
1432586914749220140	1430480385812202497	1432586914690499883	1432136214110012584	t	2025-01-27 09:14:28.326	2025-01-28 02:04:44.105
1432637826922448176	1430480385812202497	1432637826855339311	1432136214110012584	t	2025-01-27 10:55:37.53	2025-01-28 02:04:44.105
1432670858031138098	1430480385812202497	1432670857980806449	1432136214110012584	t	2025-01-27 12:01:15.145	2025-01-28 02:04:44.105
1432586952380515630	1430480385812202497	1432586952338572589	1432138030939899056	t	2025-01-27 09:14:32.812	2025-01-28 02:05:22.323
1432671689627403575	1430480385812202497	1432671689577071926	1432128234438263911	t	2025-01-27 12:02:54.279	2025-01-28 02:06:28.288
1432440506704463122	1430480385812202497	1432440506620577041	1432128678245958769	t	2025-01-27 04:23:35.127	2025-01-28 02:06:33.73
1432671851468817726	1430480385812202497	1432671851426874685	1432128678245958769	t	2025-01-27 12:03:13.573	2025-01-28 02:06:33.73
1432545395174540586	1430534043199341650	1432545395132597545	1432467553304708380	t	2025-01-27 07:51:58.807	2025-01-28 04:34:27.735
1432545381157176616	1430534043199341650	1432545381056513319	1432466460956951829	t	2025-01-27 07:51:57.136	2025-01-28 04:34:30.608
1433179415595976044	1430524402960696364	1433179415377872234	1432128234438263911	t	2025-01-28 04:51:39.917	2025-01-28 04:56:51.857
1433179522760443248	1430524402960696364	1433179522609448302	1432128234438263911	t	2025-01-28 04:51:52.695	2025-01-28 04:56:51.857
1430945234182734938	1430525186381186093	1430945233931076695	1430519898227868700	t	2025-01-25 02:52:44.732	2025-01-28 05:22:48.979
1430532340253197388	1430525186381186093	1430532340035093578	1430519898227868700	t	2025-01-24 13:12:23.943	2025-01-28 05:22:49.387
1430530453227439171	1430525186381186093	1430530452816397376	1430519898227868700	t	2025-01-24 13:08:38.983	2025-01-28 05:22:49.632
1430530140214920255	1430525186381186093	1430530139845821500	1430519898227868700	t	2025-01-24 13:08:01.663	2025-01-28 05:22:49.818
1430528319845041210	1430525186381186093	1430528319534662711	1430519898227868700	t	2025-01-24 13:04:24.664	2025-01-28 05:22:50.189
1433357514048538170	1433330078485317156	1433357513973040697	1433235122395547021	f	2025-01-28 10:45:30.921	\N
1433941633660880448	1433330078485317156	1433941633576994367	1433235122395547021	f	2025-01-29 06:06:03.405	\N
1433947356386035274	1430534043199341650	1433947356302149193	1433944122544096833	t	2025-01-29 06:17:25.606	2025-01-29 06:24:34.045
1433947392264111692	1430534043199341650	1433947392188614219	1433944122544096833	t	2025-01-29 06:17:29.883	2025-01-29 06:24:34.045
1434038741520877177	1433261799410501042	1434038741478934136	1433233702573311364	t	2025-01-29 09:18:59.564	2025-01-29 09:18:59.76
1433357613654869564	1433261799410501042	1433357613579372091	1433314479944238559	t	2025-01-28 10:45:42.795	2025-01-29 09:21:28.764
1434074427816937102	1433261799410501042	1434074427749828237	1434038848156862074	t	2025-01-29 10:29:53.702	2025-01-29 10:49:51.752
1434084870149113489	1433261799410501042	1434084870082004624	1434038848156862074	t	2025-01-29 10:50:38.525	2025-01-29 10:50:38.615
1434085040312026771	1433261799410501042	1434085040244917906	1434038848156862074	t	2025-01-29 10:50:58.81	2025-01-29 10:50:59.041
1433179415486924139	1430480385812202497	1433179415377872234	1432128234438263911	t	2025-01-28 04:51:39.916	2025-01-30 03:31:24.537
1433179522668168559	1430480385812202497	1433179522609448302	1432128234438263911	t	2025-01-28 04:51:52.694	2025-01-30 03:31:24.537
1433130033949443411	1430480385812202497	1433130033899111762	1432138030939899056	t	2025-01-28 03:13:33.18	2025-01-30 03:31:27.662
1434027746261993046	1430534043199341650	1434027746203272789	1434026103898375761	t	2025-01-29 08:57:08.828	2025-01-30 03:31:43.721
1434570298845300380	1433330078485317156	1434570298744637083	1433228368576251259	t	2025-01-30 02:55:06.132	2025-01-30 05:53:19.913
1434570373512300190	1433330078485317156	1434570373461968541	1433228368576251259	t	2025-01-30 02:55:15.036	2025-01-30 05:53:19.913
1434565850265814682	1433261799410501042	1434565850207094425	1434038848156862074	t	2025-01-30 02:46:15.823	2025-01-30 08:08:13.694
1434727989869807349	1434714317982271199	1434727989802698484	1434710292574504669	f	2025-01-30 08:08:24.37	\N
1434728025554945783	1434714317982271199	1434728025496225526	1434710292574504669	f	2025-01-30 08:08:28.624	\N
1434726176688965352	1433261799410501042	1434726176630245095	1434109361990403733	t	2025-01-30 08:04:48.222	2025-01-30 08:09:52.9
1434742760161675019	1434714317982271199	1434742760069400330	1434710292574504669	f	2025-01-30 08:37:45.126	\N
1434742916307224333	1434714317982271199	1434742916265281292	1434710292574504669	f	2025-01-30 08:38:03.741	\N
1435347538407327515	1433261799410501042	1435347538331830042	1434109361990403733	t	2025-01-31 04:39:20.309	2025-01-31 04:51:16.545
1435342468986963729	1430480385812202497	1435342468919854864	1432136214110012584	t	2025-01-31 04:29:15.989	2025-01-31 11:53:30.278
1435347448011687705	1433261799410501042	1435347447952967448	1435346986613081875	t	2025-01-31 04:39:09.535	2025-02-02 07:42:32.687
1435347571055789854	1433261799410501042	1435347571005458205	1435346986613081875	t	2025-01-31 04:39:24.203	2025-02-02 07:42:32.687
1437710588208744253	1435352068222093091	1437710588049360699	1434109361990403733	f	2025-02-03 10:54:17.787	\N
1437712713059927880	1430534043199341650	1437712713001207623	1434037967428519538	t	2025-02-03 10:58:31.101	2025-02-03 10:58:45.997
1437713113674680141	1430534043199341650	1437713113582405452	1434041555689145990	f	2025-02-03 10:59:18.857	\N
1437713113766954830	1433330078485317156	1437713113582405452	1434041555689145990	f	2025-02-03 10:59:18.858	\N
1438215221557593939	1433261799410501042	1438215221498873682	1433314479944238559	f	2025-02-04 03:36:54.782	\N
1438217313718372194	1435352068222093091	1438217313550600032	1433254977265993112	f	2025-02-04 03:41:04.176	\N
1438218653429401472	1433330078485317156	1438218653144188796	1438218418741315436	f	2025-02-04 03:43:43.867	\N
1438218653211297661	1430525186381186093	1438218653144188796	1438218418741315436	t	2025-02-04 03:43:43.865	2025-02-04 07:09:19.347
1438405192230897590	1430534043199341650	1438405192163788725	1433259305485731246	t	2025-02-04 09:54:21.051	2025-02-04 10:01:24.684
1438217313626097505	1433261799410501042	1438217313550600032	1433254977265993112	t	2025-02-04 03:41:04.175	2025-02-04 10:04:41.106
1437710491471316790	1433261799410501042	1437710491379042101	1433233702573311364	t	2025-02-03 10:54:06.266	2025-02-04 10:05:24.265
1438405249818691512	1433261799410501042	1438405249768359863	1433233702573311364	t	2025-02-04 09:54:27.916	2025-02-04 10:05:24.265
1437712149026703172	1433261799410501042	1437712148967982915	1433241292510332304	t	2025-02-03 10:57:23.863	2025-02-04 10:08:25.796
1437712248649811782	1433261799410501042	1437712248607868741	1433241292510332304	t	2025-02-03 10:57:35.739	2025-02-04 10:08:25.796
1438405422967949246	1433261799410501042	1438405422892451773	1433241292510332304	t	2025-02-04 09:54:48.557	2025-02-04 10:08:25.796
1435350748048131874	1430534043199341650	1435350747981023009	1433261051297662384	t	2025-01-31 04:45:42.93	2025-02-04 10:12:14.239
1437710509313886008	1430534043199341650	1437710509271942967	1433261051297662384	t	2025-02-03 10:54:08.394	2025-02-04 10:12:14.239
1438405268491732922	1430534043199341650	1438405268449789881	1433261051297662384	t	2025-02-04 09:54:30.143	2025-02-04 10:12:14.239
1438422084756703177	1430534043199341650	1438422084689594312	1434041555689145990	f	2025-02-04 10:27:54.797	\N
1438422084874143690	1433330078485317156	1438422084689594312	1434041555689145990	f	2025-02-04 10:27:54.797	\N
1438423544777148372	1430534043199341650	1438423544684873683	1433320514390066684	t	2025-02-04 10:30:48.845	2025-02-04 10:34:28.584
1435360247207167784	1433330078485317156	1435360247148447527	1433228368576251259	t	2025-01-31 05:04:35.318	2025-02-04 11:20:52.57
1435360273455122218	1433330078485317156	1435360273421567785	1433228368576251259	t	2025-01-31 05:04:38.447	2025-02-04 11:20:52.57
1437710352690186036	1433330078485317156	1437710352623077171	1433228368576251259	t	2025-02-03 10:53:49.723	2025-02-04 11:20:52.57
1439004132542252322	1433261799410501042	1439004132013770011	1434710292574504669	f	2025-02-05 05:44:20.25	\N
1438941080165811317	1430501158790628357	1438941080107091060	1438938542184072287	t	2025-02-05 03:39:03.872	2025-02-05 06:04:47.502
1439004132533863713	1430501158790628357	1439004132013770011	1434710292574504669	t	2025-02-05 05:44:20.249	2025-02-05 06:10:38.122
1439058853562942889	1433297069220562376	1439058853051237796	1438933352294908940	f	2025-02-05 07:33:03.505	\N
1439058853688772008	1434714317982271199	1439058853051237796	1438933352294908940	f	2025-02-05 07:33:03.503	\N
1439058853739103659	1435352068222093091	1439058853051237796	1438933352294908940	f	2025-02-05 07:33:03.508	\N
1439058853680383402	1433261799410501042	1439058853051237796	1438933352294908940	f	2025-02-05 07:33:03.506	\N
1439058853848155564	1432141375276582075	1439058853051237796	1438933352294908940	f	2025-02-05 07:33:03.507	\N
1439058853596497318	1430525186381186093	1439058853051237796	1438933352294908940	t	2025-02-05 07:33:03.504	2025-02-05 08:07:27.53
1439004132441589024	1433172877045138776	1439004132013770011	1434710292574504669	t	2025-02-05 05:44:20.246	2025-02-06 03:58:02.605
1439684263891961389	1433261799410501042	1439684263850018348	1433320073308669432	t	2025-02-06 04:15:38.275	2025-02-06 04:48:07.211
1439684182270805547	1433261799410501042	1439684182212085290	1433303096687068625	t	2025-02-06 04:15:28.545	2025-02-06 04:51:10.29
1439058853428725159	1430501158790628357	1439058853051237796	1438933352294908940	t	2025-02-05 07:33:03.504	2025-02-06 06:08:48.095
1439058853177066917	1433172244418266454	1439058853051237796	1438933352294908940	t	2025-02-05 07:33:03.503	2025-02-06 06:28:15.461
1439820526175389363	1430480385812202497	1439820526099891890	1439819756243781290	t	2025-02-06 08:46:22.005	2025-02-06 08:47:45.283
1439821519663400633	1430524402960696364	1439821519596291768	1439819756243781290	t	2025-02-06 08:48:20.438	2025-02-06 08:48:20.491
1439821530979632827	1430480385812202497	1439821530920912570	1439819756243781290	t	2025-02-06 08:48:21.787	2025-02-06 08:48:21.844
1439850137584142035	1433297069220562376	1439850137416369873	1438944089067226234	f	2025-02-06 09:45:11.95	\N
1439856097623017174	1433171377464018261	1439856097388136148	1438218418741315436	f	2025-02-06 09:57:02.434	\N
1439856097639794391	1433330078485317156	1439856097388136148	1438218418741315436	f	2025-02-06 09:57:02.435	\N
1439856150848734940	1433171377464018261	1439856150764848857	1438218418741315436	f	2025-02-06 09:57:08.796	\N
1439856150857123549	1433330078485317156	1439856150764848857	1438218418741315436	f	2025-02-06 09:57:08.797	\N
1439856173648971489	1433171377464018261	1439856173565085406	1438218418741315436	f	2025-02-06 09:57:11.514	\N
1439856173657360098	1433330078485317156	1439856173565085406	1438218418741315436	f	2025-02-06 09:57:11.514	\N
1439856504957044456	1433330078485317156	1439856504579557093	1438218418741315436	f	2025-02-06 09:57:50.98	\N
1439856504982210281	1433171377464018261	1439856504579557093	1438218418741315436	f	2025-02-06 09:57:50.979	\N
1440388881554867956	1434714317982271199	1440388881470981875	1434710292574504669	f	2025-02-07 03:35:35.243	\N
1440388881814914808	1433297069220562376	1440388881470981875	1434710292574504669	f	2025-02-07 03:35:35.246	\N
1440388892007073530	1433330078485317156	1440388891965130489	1433316650974709223	f	2025-02-07 03:35:36.493	\N
1440388972218943229	1433171377464018261	1440388971942119163	1438218506888808303	f	2025-02-07 03:35:46.033	\N
1440389587808552721	1433171377464018261	1440389587733055248	1439689109495875119	f	2025-02-07 03:36:59.437	\N
1440389587917604626	1433297069220562376	1440389587733055248	1439689109495875119	f	2025-02-07 03:36:59.438	\N
1440389625834112789	1433171377464018261	1440389625783781140	1439689109495875119	f	2025-02-07 03:37:03.971	\N
1440389625850890007	1433297069220562376	1440389625783781140	1439689109495875119	f	2025-02-07 03:37:03.972	\N
1440388860658845426	1433261799410501042	1440388860600125169	1433303096687068625	t	2025-02-07 03:35:32.755	2025-02-07 03:39:52.604
1440389194701604609	1433171377464018261	1440389194626107136	1439857429213873898	t	2025-02-07 03:36:12.576	2025-02-07 03:41:51.768
1439850137500255954	1433172478670144855	1439850137416369873	1438944089067226234	t	2025-02-06 09:45:11.948	2025-02-07 03:42:45.756
1437710588108080956	1433172478670144855	1437710588049360699	1434109361990403733	t	2025-02-03 10:54:17.787	2025-02-07 03:43:00.483
1440398078187144986	1434714317982271199	1440398077910320921	1434710292574504669	f	2025-02-07 03:53:51.567	\N
1440398078623352605	1433297069220562376	1440398077910320921	1434710292574504669	f	2025-02-07 03:53:51.57	\N
1440417346475788066	1433172478670144855	1440417346391901985	1439689109495875119	f	2025-02-07 04:32:08.527	\N
1440417346601617188	1433171377464018261	1440417346391901985	1439689109495875119	f	2025-02-07 04:32:08.528	\N
1440417346601617187	1433297069220562376	1440417346391901985	1439689109495875119	f	2025-02-07 04:32:08.528	\N
1440389587934381843	1430525186381186093	1440389587733055248	1439689109495875119	t	2025-02-07 03:36:59.437	2025-02-07 04:32:08.644
1440389625842501398	1430525186381186093	1440389625783781140	1439689109495875119	t	2025-02-07 03:37:03.971	2025-02-07 04:32:08.644
1440417482664838950	1433171377464018261	1440417482580952869	1438218506888808303	f	2025-02-07 04:32:24.763	\N
1440388972059559676	1430525186381186093	1440388971942119163	1438218506888808303	t	2025-02-07 03:35:46.031	2025-02-07 04:32:24.873
1440417647584872234	1433171377464018261	1440417647500986153	1438218506888808303	f	2025-02-07 04:32:44.424	\N
1440417701490067247	1433171377464018261	1440417701422958381	1438218418741315436	f	2025-02-07 04:32:50.849	\N
1440417701498455856	1433330078485317156	1440417701422958381	1438218418741315436	f	2025-02-07 04:32:50.849	\N
1439856097472022229	1430525186381186093	1439856097388136148	1438218418741315436	t	2025-02-06 09:57:02.433	2025-02-07 04:32:50.955
1439856150840346330	1430525186381186093	1439856150764848857	1438218418741315436	t	2025-02-06 09:57:08.795	2025-02-07 04:32:50.955
1439856173640582879	1430525186381186093	1439856173565085406	1438218418741315436	t	2025-02-06 09:57:11.513	2025-02-07 04:32:50.955
1439856504722163430	1430525186381186093	1439856504579557093	1438218418741315436	t	2025-02-06 09:57:50.977	2025-02-07 04:32:50.955
1440417865923561267	1433172478670144855	1440417865848063794	1438944089067226234	f	2025-02-07 04:33:10.451	\N
1440417866007447348	1433297069220562376	1440417865848063794	1438944089067226234	f	2025-02-07 04:33:10.452	\N
1439058853831378349	1434720470833301219	1439058853051237796	1438933352294908940	t	2025-02-05 07:33:03.507	2025-02-07 04:41:16.045
1440422192918562625	1433261799410501042	1440422192859842368	1433233702573311364	f	2025-02-07 04:41:46.271	\N
1439856097664960216	1430534043199341650	1439856097388136148	1438218418741315436	t	2025-02-06 09:57:02.433	2025-02-07 04:46:48.279
1439856150848734939	1430534043199341650	1439856150764848857	1438218418741315436	t	2025-02-06 09:57:08.796	2025-02-07 04:46:48.279
1439856173648971488	1430534043199341650	1439856173565085406	1438218418741315436	t	2025-02-06 09:57:11.513	2025-02-07 04:46:48.279
1439856504898324199	1430534043199341650	1439856504579557093	1438218418741315436	t	2025-02-06 09:57:50.978	2025-02-07 04:46:48.279
1440417701490067246	1430534043199341650	1440417701422958381	1438218418741315436	t	2025-02-07 04:32:50.848	2025-02-07 04:46:48.279
1440388972235720446	1430534043199341650	1440388971942119163	1438218506888808303	t	2025-02-07 03:35:46.034	2025-02-07 04:46:57.378
1440417482782279463	1430534043199341650	1440417482580952869	1438218506888808303	t	2025-02-07 04:32:24.763	2025-02-07 04:46:57.378
1440417647710701356	1430534043199341650	1440417647500986153	1438218506888808303	t	2025-02-07 04:32:44.424	2025-02-07 04:46:57.378
1440425293801064262	1433261799410501042	1440425293733955397	1440419188186285877	f	2025-02-07 04:47:55.925	\N
1440428167520061264	1433171377464018261	1440428167293568845	1438218418741315436	f	2025-02-07 04:53:38.479	\N
1440428167562004305	1433330078485317156	1440428167293568845	1438218418741315436	f	2025-02-07 04:53:38.481	\N
1440429408035800915	1433261799410501042	1440429407977080658	1433241292510332304	f	2025-02-07 04:56:06.379	\N
1440389236124550915	1433330078485317156	1440389236074219266	1437711172743726910	t	2025-02-07 03:36:17.514	2025-02-07 04:59:53.013
1440389253069539077	1433330078485317156	1440389253027596036	1437711172743726910	t	2025-02-07 03:36:19.534	2025-02-07 04:59:53.013
1440435386311509845	1433172478670144855	1440435386227623764	1434109361990403733	f	2025-02-07 05:07:59.044	\N
1440435386395395926	1435352068222093091	1440435386227623764	1434109361990403733	f	2025-02-07 05:07:59.045	\N
1440428167377454926	1430525186381186093	1440428167293568845	1438218418741315436	t	2025-02-07 04:53:38.479	2025-02-07 05:08:13.429
1440417701632673585	1430501158790628357	1440417701422958381	1438218418741315436	t	2025-02-07 04:32:50.85	2025-02-07 09:18:28.51
1440428167545227087	1430501158790628357	1440428167293568845	1438218418741315436	t	2025-02-07 04:53:38.481	2025-02-07 09:18:28.51
1440388972294440703	1430501158790628357	1440388971942119163	1438218506888808303	t	2025-02-07 03:35:46.035	2025-02-07 09:18:36.109
1440417482807445288	1430501158790628357	1440417482580952869	1438218506888808303	t	2025-02-07 04:32:24.764	2025-02-07 09:18:36.109
1440417647710701355	1430501158790628357	1440417647500986153	1438218506888808303	t	2025-02-07 04:32:44.425	2025-02-07 09:18:36.109
1437710533330470714	1433330078485317156	1437710533288527673	1433232704547063170	t	2025-02-03 10:54:11.257	2025-02-07 12:26:37.431
1438405299764463548	1433330078485317156	1438405299688966075	1433232704547063170	t	2025-02-04 09:54:33.871	2025-02-07 12:26:37.431
1440388881705862901	1433172877045138776	1440388881470981875	1434710292574504669	t	2025-02-07 03:35:35.243	2025-02-08 02:01:56.22
1440398078539466524	1433172877045138776	1440398077910320921	1434710292574504669	t	2025-02-07 03:53:51.568	2025-02-08 02:01:56.22
1440398078656907038	1430525186381186093	1440398077910320921	1434710292574504669	t	2025-02-07 03:53:51.569	2025-02-10 04:22:32.798
1440388881747805943	1430525186381186093	1440388881470981875	1434710292574504669	t	2025-02-07 03:35:35.245	2025-02-10 04:22:34.054
1442646983452919703	1433261799410501042	1442646983394199446	1433303096687068625	f	2025-02-10 06:22:01.969	\N
1442647159538190233	1430534043199341650	1442647159462692760	1440419188186285877	f	2025-02-10 06:22:22.959	\N
1442647159622076314	1433261799410501042	1442647159462692760	1440419188186285877	f	2025-02-10 06:22:22.96	\N
1442653687720708016	1433297069220562376	1442653687544547246	1442640975624144786	f	2025-02-10 06:35:21.165	\N
1442653687594878895	1430525186381186093	1442653687544547246	1442640975624144786	t	2025-02-10 06:35:21.164	2025-02-10 06:36:57.538
1442656542062020531	1433297069220562376	1442656542003300274	1439000237099189513	f	2025-02-10 06:41:01.444	\N
1442656998083528629	1433297069220562376	1442656998008031156	1439000237099189513	f	2025-02-10 06:41:55.805	\N
1442653687737485233	1434720470833301219	1442653687544547246	1442640975624144786	t	2025-02-10 06:35:21.165	2025-02-10 07:28:23.224
1443269244446836672	1433330078485317156	1443269244396505023	1433232704547063170	f	2025-02-11 02:58:21.26	\N
1443280855697983440	1430534043199341650	1443280855354050510	1438943393743897719	f	2025-02-11 03:21:25.396	\N
1443280855429547983	1434720470833301219	1443280855354050510	1438943393743897719	t	2025-02-11 03:21:25.395	2025-02-11 03:22:36.16
1443282843781302228	1430480385812202497	1443282843705804755	1438218124980651878	t	2025-02-11 03:25:22.427	2025-02-11 03:47:19.43
1439004132307371293	1433172478670144855	1439004132013770011	1434710292574504669	t	2025-02-05 05:44:20.247	2025-02-11 04:33:16.363
1443314315875583982	1430534043199341650	1443314315825252333	1443313947582138341	t	2025-02-11 04:27:54.193	2025-02-11 04:45:10.798
1443314341561501681	1430534043199341650	1443314341511170032	1443313947582138341	t	2025-02-11 04:27:57.255	2025-02-11 04:45:10.798
1443280855706372049	1430501158790628357	1443280855354050510	1438943393743897719	t	2025-02-11 03:21:25.396	2025-02-11 10:30:56.481
1443280855731537874	1430525186381186093	1443280855354050510	1438943393743897719	t	2025-02-11 03:21:25.397	2025-02-11 10:51:55.789
1442899438015088571	1430525186381186093	1442899437964756922	1432128251324531818	t	2025-02-10 14:43:36.897	2025-02-11 10:51:55.838
1442899437864093625	1430525186381186093	1442899437805373368	1432128251324531818	t	2025-02-10 14:43:36.88	2025-02-11 10:51:55.882
1440388881722640118	1433172478670144855	1440388881470981875	1434710292574504669	t	2025-02-07 03:35:35.245	2025-02-11 04:33:16.363
1440398078514300699	1433172478670144855	1440398077910320921	1434710292574504669	t	2025-02-07 03:53:51.569	2025-02-11 04:33:16.363
1443314381424166900	1430534043199341650	1443314381373835251	1443313947582138341	t	2025-02-11 04:28:02.008	2025-02-11 04:45:10.798
1443397543894451278	1433172244418266454	1443397543860896845	1443397437266854982	f	2025-02-11 07:13:15.747	\N
1443453418910778468	1434720470833301219	1443453418860446819	1443410876563457116	f	2025-02-11 09:04:16.567	\N
1443506919699383441	1430534043199341650	1443506919632274576	1433316010454156773	f	2025-02-11 10:50:34.358	\N
1443506943992792211	1430534043199341650	1443506943942460562	1433316010454156773	f	2025-02-11 10:50:37.255	\N
1443705666114946203	1430525186381186093	1443705666022671514	1433322124021335558	t	2025-02-11 17:25:26.776	2026-01-20 08:59:02.426
1692664574668440812	1430525186381186093	1692664574576166123	1692095657243837637	f	2026-01-21 05:22:21.39	\N
1692664574718772462	1433261799410501042	1692664574576166123	1692095657243837637	t	2026-01-21 05:22:21.393	2026-01-21 05:27:50.611
1692664574701995245	1430534043199341650	1692664574576166123	1692095657243837637	t	2026-01-21 05:22:21.391	2026-01-21 06:01:54.22
\.


--
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.project (id, name, background, created_at, updated_at, background_image) FROM stdin;
1433174555865646425	CEREZO OSAKA	{"name": "strawberry-dust", "type": "gradient"}	2025-01-28 04:42:00.604	2025-01-28 05:17:46.467	\N
1434588557086820006	Urawa Reds	{"name": "tzepesch-style", "type": "gradient"}	2025-01-30 03:31:22.685	2025-01-30 04:22:56.982	\N
1434609072862135978	HCS	{"name": "steel-grey", "type": "gradient"}	2025-01-30 04:12:08.356	2025-01-30 04:24:39.759	\N
1434609486756054700	Sponsorship	{"name": "purple-rain", "type": "gradient"}	2025-01-30 04:12:57.696	2025-01-30 04:24:50.771	\N
1430501293201294342	Innovations Lab	{"name": "prism-light", "type": "gradient"}	2025-01-24 12:10:42.86	2025-02-04 04:12:47.725	\N
1438939577170527330	Ladderice	\N	2025-02-05 03:36:04.697	\N	\N
1434589041889642152	MIZUNO	{"name": "blue-xchange", "type": "gradient"}	2025-01-30 03:32:20.478	2025-02-05 05:31:46.622	\N
1692048917312570542	J.LEAGUE	\N	2026-01-20 08:59:09.314	\N	\N
\.


--
-- Data for Name: project_manager; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.project_manager (id, project_id, user_id, created_at, updated_at) FROM stdin;
1433174555915978074	1433174555865646425	1430525186381186093	2025-01-28 04:42:00.611	\N
1434588557128763047	1434588557086820006	1433172244418266454	2025-01-30 03:31:22.692	\N
1434589041923196585	1434589041889642152	1433172244418266454	2025-01-30 03:32:20.485	\N
1434609072912467627	1434609072862135978	1433172244418266454	2025-01-30 04:12:08.364	\N
1434609486797997741	1434609486756054700	1433172244418266454	2025-01-30 04:12:57.703	\N
1438331480148281267	1433174555865646425	1430534043199341650	2025-02-04 07:27:53.884	\N
1438331567616296884	1433174555865646425	1433172478670144855	2025-02-04 07:28:04.311	\N
1438928814267697131	1434589041889642152	1433297069220562376	2025-02-05 03:14:41.66	\N
1438928853467662316	1434589041889642152	1433172478670144855	2025-02-05 03:14:46.333	\N
1438928945708795886	1434589041889642152	1430525186381186093	2025-02-05 03:14:57.331	\N
1438939577195693155	1438939577170527330	1433172478670144855	2025-02-05 03:36:04.703	\N
1438988279566304501	1434589041889642152	1430501158790628357	2025-02-05 05:12:50.476	\N
1692048917346124975	1692048917312570542	1430525186381186093	2026-01-20 08:59:09.321	\N
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.session (id, user_id, access_token, remote_address, user_agent, created_at, updated_at, deleted_at, http_only_token) FROM stdin;
1430500794297222148	1430480385812202497	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjJjMDExZTMyLTEyOTAtNGQ1ZC05MzYzLTBmOTk5MjU3Nzk1YiJ9.eyJpYXQiOjE3Mzc3MjA1ODMsImV4cCI6MTc2OTI1NjU4Mywic3ViIjoiMTQzMDQ4MDM4NTgxMjIwMjQ5NyJ9.sK1bF_zRj1jWh5zKc4fvW2XmmCMsFZc6gRQYG9qD1Po	184.22.77.202	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-24 12:09:43.382	2025-01-24 12:12:33.868	2025-01-24 12:12:33.866	88189721-6d42-4add-bcb1-3774994bd41f
1430502325646001164	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjI4NzNlZmNmLTljZmYtNDllNy1hMGZhLWViNjE1NjhkMjYyYyJ9.eyJpYXQiOjE3Mzc3MjA3NjUsImV4cCI6MTc2OTI1Njc2NSwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.HMup6h-1HTDcakZf7BO3KL0TutzCstJsRHw8cMDs0yk	171.96.191.43	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-24 12:12:45.938	\N	\N	6f119de1-2f4b-409c-9526-a466494b30d4
1430502323121030155	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImQ3YTEzY2YxLTI3MDctNDBhYS1iZWY0LTRmYTg3OGU0YTc3YyJ9.eyJpYXQiOjE3Mzc3MjA3NjUsImV4cCI6MTc2OTI1Njc2NSwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.pd4fVTqkZ2lJ5cJ-rfjVov3ajQWCCM2Yy1QUOxKInow	184.22.77.202	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-24 12:12:45.636	2025-01-24 12:13:19.807	2025-01-24 12:13:19.804	1f08230e-07cd-4ea2-b80e-5fb5f57d7205
1430505417275868176	1430480385812202497	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImM1MTkxYWE0LWFhMDEtNGI2Zi05ZjIwLWExMTQ4MDRmOTcwYiJ9.eyJpYXQiOjE3Mzc3MjExMzQsImV4cCI6MTc2OTI1NzEzNCwic3ViIjoiMTQzMDQ4MDM4NTgxMjIwMjQ5NyJ9.PvKKSJfZAEXvsqN05pXmO9QLn183QB5ae7542VnL_gM	184.22.77.202	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-24 12:18:54.488	\N	\N	9b87f8df-4e2d-41ef-a10c-6f0be543ca6a
1430519791482831899	1430480385812202497	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImQzOTc0OWQxLWM5ZjctNDAxMy05MmI4LWNlMTY5MDU3NjE4MiJ9.eyJpYXQiOjE3Mzc3MjI4NDgsImV4cCI6MTc2OTI1ODg0OCwic3ViIjoiMTQzMDQ4MDM4NTgxMjIwMjQ5NyJ9.DjNVXArCZuiwG_XPOff8ib1tB-1FU72xCTXxsuDn2hM	172.19.0.3	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-24 12:47:28.022	\N	\N	84c44839-81d4-4bdb-bbfe-3ee3f90e216e
1430531811879945284	1430524402960696364	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjFjMzFjM2JiLTg1M2UtNDQwNi1iNjhmLWFmZTAzMzBiZTk4ZSJ9.eyJpYXQiOjE3Mzc3MjQyODAsImV4cCI6MTc2OTI2MDI4MCwic3ViIjoiMTQzMDUyNDQwMjk2MDY5NjM2NCJ9.IPAPTG4mOC6J7XnDSs2UcZgBrH79yE4n5T9Sz8jfEjc	172.19.0.3	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-01-24 13:11:20.97	2025-01-24 13:11:28.831	2025-01-24 13:11:28.829	3640992b-c050-487e-8b70-192501527c4e
1430532194568242246	1430524402960696364	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ijk1MWZmODdjLTUzZWUtNDU3Ny1hMTQyLWMxNDMzYmY0M2IxZCJ9.eyJpYXQiOjE3Mzc3MjQzMjYsImV4cCI6MTc2OTI2MDMyNiwic3ViIjoiMTQzMDUyNDQwMjk2MDY5NjM2NCJ9.Xct2q5bWfi0J4C4jrt0ddGWDG-ROi-VPAif_BM806v0	172.19.0.3	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-01-24 13:12:06.59	\N	\N	400ef021-1674-4fbc-aa37-ec01194f0ae0
1430560044520309844	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjAwODU0YWY1LWVmOWMtNDc5Zi1hZmNiLTlkMDAzODJjZTgwYyJ9.eyJpYXQiOjE3Mzc3Mjc2NDYsImV4cCI6MTc2OTI2MzY0Niwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.bZIMb8FCnbud-7D8eIRGKBs2CTMS5AWmYMS3CoUg-nU	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-01-24 14:07:26.563	2025-01-24 14:07:49.285	2025-01-24 14:07:49.281	221c4d7b-bd42-439e-9d6a-efc21c393bf4
1430560308291699797	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjFkMzEyYzM4LTk3ZGQtNGNhOS04MmU4LTZhNzUyNjM0Njc3ZiJ9.eyJpYXQiOjE3Mzc3Mjc2NzgsImV4cCI6MTc2OTI2MzY3OCwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.ZoUwDve_HcPgJF1_33f1YyuB6J-Ny9TgC9KH1PhxTDo	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-01-24 14:07:58.006	\N	\N	b1a7de2f-b6ab-438e-8e71-8544a696d0fc
1430944915029754966	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImJkMzk1NWIwLTY0NDctNDlkNC1hNDY5LTUzZTYzYWEwYWMzNiJ9.eyJpYXQiOjE3Mzc3NzM1MjYsImV4cCI6MTc2OTMwOTUyNiwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.lwvQrxfxeZjRZYnyZR7vDzX83P7qEWQQzMi1JzS0dMU	172.19.0.3	Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/132.0.6834.100 Mobile/15E148 Safari/604.1	2025-01-25 02:52:06.703	\N	\N	dc77b97d-f553-4d99-bee4-2fd2c1a66dfa
1430947114640213083	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjVjM2YyNjUyLTA3ODAtNGJkMC1iNTM4LTU3ZGMzM2QxZmYwOSJ9.eyJpYXQiOjE3Mzc3NzM3ODgsImV4cCI6MTc2OTMwOTc4OCwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.42bw4H6l_-yBCGc00Vl_MFPh_fB2I06w9l-QErETSQA	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-25 02:56:28.917	\N	\N	06f93349-6f5c-4cc0-b02c-55efa3621521
1430947453716137052	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjZkZjYyNjBhLTE4NzAtNGNiNS1hM2E4LTllOTgxYjQwMGQxZSJ9.eyJpYXQiOjE3Mzc3NzM4MjksImV4cCI6MTc2OTMwOTgyOSwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.u65GRU0nsfGoVJBYb4WJD1OyPXwBNDBdluwi45IFkic	172.19.0.3	\N	2025-01-25 02:57:09.339	\N	\N	06f93349-6f5c-4cc0-b02c-55efa3621521
1433192222995514742	1433172244418266454	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ijc3ZDY0YWEyLWI1NmEtNGEwMy1iNGFmLTlmNGZlZTNlNGM4OCJ9.eyJpYXQiOjE3MzgwNDE0MjYsImV4cCI6MTc2OTU3NzQyNiwic3ViIjoiMTQzMzE3MjI0NDQxODI2NjQ1NCJ9.8FaRjSWsJj8X41B2D0z31TCGaVULkZfb8eHzT7T7fKA	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15	2025-01-28 05:17:06.691	\N	\N	058f6a06-48e8-436d-88a2-0cf34ef511be
1433261864506099123	1433261799410501042	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjE3NWI2YWFlLWI5OTItNDYyZS05NDc5LTdiODUyNzAxZWQ1NyJ9.eyJpYXQiOjE3MzgwNDk3MjgsImV4cCI6MTc2OTU4NTcyOCwic3ViIjoiMTQzMzI2MTc5OTQxMDUwMTA0MiJ9.HVPlTpoQnQtDrkhbbF4fEZJyEyNueX7g3UdhEPZIM9k	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-28 07:35:28.607	\N	\N	204ee767-d8a4-4cdd-ada8-9143c824bc50
1432439418173523216	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFjNDUyODM2LTRmMGQtNDMzNy04MzFiLWM4ZGE5ODA2YzhmYyJ9.eyJpYXQiOjE3Mzc5NTE2ODUsImV4cCI6MTc2OTQ4NzY4NSwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.W5ZVZuuaBj3U0C1t_9nww__ntBlHBu9ow9IFcetqYvg	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-27 04:21:25.361	2025-01-28 07:54:39.301	2025-01-28 07:54:39.299	20470678-5054-4dda-ae49-c2be73769958
1432469097479669030	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjVmN2UzZjkzLTI2ZWUtNGU0NS1iMzhmLTQyY2ZlMDYwNDgzZCJ9.eyJpYXQiOjE3Mzc5NTUyMjMsImV4cCI6MTc2OTQ5MTIyMywic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.UVWp58SEkuIfEh9at7bbnRdrMtb_C8Yfo3NjaDObIKo	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-27 05:20:23.411	2025-01-28 08:09:19.981	2025-01-28 08:09:19.976	982590f7-1149-46c8-8d81-9e0f26a52c01
1433279088214148538	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjY2YWM1MWExLTIwOWEtNDEyYy05MzcwLWE0MTc0MDBkYzFjYSJ9.eyJpYXQiOjE3MzgwNTE3ODEsImV4cCI6MTc2OTU4Nzc4MSwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.rtn4baYbrT_3PowdDjwBeXXnJ-g0HPFCbxa-vZPgJWs	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-28 08:09:41.831	\N	\N	222cb2b0-d0d8-48a3-92fa-00fdb454b31b
1433279763706807739	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjZiZjFiY2I3LTEzMjMtNDlmNi04NDYxLWVmN2M0NmY5YjBlNCJ9.eyJpYXQiOjE3MzgwNTE4NjIsImV4cCI6MTc2OTU4Nzg2Miwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.DiXdxbrX-QkK0ukTdVgHGkJIoLFiMf4ULBTNGLV1i98	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-28 08:11:02.355	\N	\N	46b31de0-8f99-41c2-93ab-f2fe87423e9f
1433285417586656707	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjM2YjM2YThjLTljNTEtNGQwMy1hODJjLTk4MzI5ZDY4MGE0YiJ9.eyJpYXQiOjE3MzgwNTI1MzYsImV4cCI6MTc2OTU4ODUzNiwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.0B2V04fBFKC46ntCnj1efS-i0MVL2_ZmpJ0vd_tkxaE	172.19.0.3	\N	2025-01-28 08:22:16.35	2025-01-28 08:22:20.723	2025-01-28 08:22:20.721	222cb2b0-d0d8-48a3-92fa-00fdb454b31b
1433285530497320388	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjZkMGY1MDZlLWMwYmUtNDUyZC1iMGFjLTdjZDhiNTljZmU5YSJ9.eyJpYXQiOjE3MzgwNTI1NDksImV4cCI6MTc2OTU4ODU0OSwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.I2eFT3vrGXhzPW0wbPdtkEr8vNUjI4mdX69s9cxgOrs	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-28 08:22:29.813	2025-01-28 08:23:12.15	2025-01-28 08:23:12.148	48659c09-0651-4c17-8354-aff15740bcb7
1433286027111302597	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjhjMjEwZDY5LTEzMzUtNGNiOS05ZWZmLTBiOTAyYmExYWZkMCJ9.eyJpYXQiOjE3MzgwNTI2MDksImV4cCI6MTc2OTU4ODYwOSwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.qaNg8lUIXlr_spLULYBs87HpjSzNmA0bPBJV9e5ZOoc	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-28 08:23:29.011	\N	\N	e4c1b82c-983c-4269-8d89-cb5fcb582f56
1433330259981239845	1433330078485317156	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImVjYmNkNjE3LTBhNmYtNDIwZi1hYTgzLTJkN2ZhMTY3MGVmYiJ9.eyJpYXQiOjE3MzgwNTc4ODEsImV4cCI6MTc2OTU5Mzg4MSwic3ViIjoiMTQzMzMzMDA3ODQ4NTMxNzE1NiJ9.8vVJu6x7zu3bWrwYHgANQ-3M8AaFQfR_OOnweRwhpDc	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-28 09:51:21.98	\N	\N	19c083fb-4a8d-41c4-89de-1ef998d45008
1433331645561177653	1433330078485317156	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImE5NGFmOGQ2LWViZTQtNDJkMS1hNmI2LThmZDg1Y2EyN2MyZSJ9.eyJpYXQiOjE3MzgwNTgwNDcsImV4cCI6MTc2OTU5NDA0Nywic3ViIjoiMTQzMzMzMDA3ODQ4NTMxNzE1NiJ9.buXTCxFeAzubi5OUPk1GVSxF2kyQ3Y4lGBTL7bM9BQk	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-28 09:54:07.157	\N	\N	978af8ea-fd62-44b2-b186-9a8339fe37ed
1433940690051532350	1433171377464018261	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImE1ZjMxOTFhLWQyOTItNGI3MS1iZDZiLTUxZTEwOGUzNDRmNyJ9.eyJpYXQiOjE3MzgxMzA2NTAsImV4cCI6MTc2OTY2NjY1MCwic3ViIjoiMTQzMzE3MTM3NzQ2NDAxODI2MSJ9.ptREMeBLCAFCwxS543chiOIf8YmX9A1q54Jsf-edRLU	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 OPR/116.0.0.0	2025-01-29 06:04:10.915	\N	\N	b84f0514-2a7f-4ffa-9e46-3d5447039e4e
1434582250808149669	1433172478670144855	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImVkNjE3NTA1LWRiMzMtNGVjYS04NGI3LWMyZWZmYjIyYWNmNiJ9.eyJpYXQiOjE3MzgyMDcxMzAsImV4cCI6MTc2OTc0MzEzMCwic3ViIjoiMTQzMzE3MjQ3ODY3MDE0NDg1NSJ9.Ul0j8nnnhBmAreE6LIlmJfsC9B-ObcVcBcU4SjeALLY	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-01-30 03:18:50.917	\N	\N	d20a7766-1d38-4477-b1dc-dcfe70a5c72e
1434635734920201919	1433172877045138776	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjJhNjc5NjlhLTA3NmYtNGM5Ni1iZDU3LWMwZmU0ZDY0Zjk2MiJ9.eyJpYXQiOjE3MzgyMTM1MDYsImV4cCI6MTc2OTc0OTUwNiwic3ViIjoiMTQzMzE3Mjg3NzA0NTEzODc3NiJ9.wpkDe01EnHu_KEVzKGkk4O4E32kyVHOjDEUx4Td6zlo	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-30 05:05:06.719	\N	\N	38acb81f-92c9-4814-83bc-0c31019af425
1434708474276611802	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjAxNzM1OTlkLTI3NjAtNDg3OC1hMWQ3LWMyOTdkZmU4YWNjNiJ9.eyJpYXQiOjE3MzgyMjIxNzcsImV4cCI6MTc2OTc1ODE3Nywic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.VZq9n8BEyRYLAq8enrc7P_G-TGUkp99xhtZLfUKf8qU	172.19.0.3	\N	2025-01-30 07:29:37.927	2025-01-30 07:34:44.278	2025-01-30 07:34:44.276	46b31de0-8f99-41c2-93ab-f2fe87423e9f
1434718012627224288	1434714317982271199	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjcyNWUyYTY3LTllYTctNDEzZC1hZGUzLTQ3ZjI4NDNkZDhjMiJ9.eyJpYXQiOjE3MzgyMjMzMTQsImV4cCI6MTc2OTc1OTMxNCwic3ViIjoiMTQzNDcxNDMxNzk4MjI3MTE5OSJ9.9Km1y4xXVFKPuy5yP34h6Y-S6rGgKW73a6ZCFeDdZlE	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-30 07:48:34.988	\N	\N	be90165b-a0a3-44f5-9424-10d96f1d597d
1434718335487968994	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjAxYTdjNzkxLTQ1NGQtNGVmMi04YjYyLTQ5NmVmNWM1ZTQyYiJ9.eyJpYXQiOjE3MzgyMjMzNTMsImV4cCI6MTc2OTc1OTM1Mywic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.xcOIhMNpUT5dADcrtoCHPs94cdJyxfCxa9cyZD7qjgo	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-30 07:49:13.478	\N	\N	4839efd9-2502-466f-97eb-c06f8517d667
1434720714824353508	1434720470833301219	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImE5N2E4NDUyLTVjNTUtNGZlZS1hNWI4LWRlNzg2NmQzNWY0MSJ9.eyJpYXQiOjE3MzgyMjM2MzcsImV4cCI6MTc2OTc1OTYzNywic3ViIjoiMTQzNDcyMDQ3MDgzMzMwMTIxOSJ9.9G2iEG7yRKeeBOq9adFbd1x4ezRaCHTCGQ-6kWu5wy8	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-30 07:53:57.114	\N	\N	6631566e-847e-4aaa-9ea6-7ac0b1ba6c13
1434729552675866363	1434720470833301219	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY2OWI1NzQwLWE1NWMtNDhkZC04MmJlLThiMDNmOGQ2ZGRiOSJ9.eyJpYXQiOjE3MzgyMjQ2OTAsImV4cCI6MTc2OTc2MDY5MCwic3ViIjoiMTQzNDcyMDQ3MDgzMzMwMTIxOSJ9._biN9PrI4_hAUqUx4P0t6Lkiuc5czec4k8CskAGDJJA	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-30 08:11:30.669	\N	\N	3791be68-96cc-454d-bc60-8b42e1411ad0
1434801876703905551	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjVkYTdjNWQ1LTFhYjQtNGZlYi1iOGY5LTRlNTc5ZjVlMTIzOSJ9.eyJpYXQiOjE3MzgyMzMzMTIsImV4cCI6MTc2OTc2OTMxMiwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.mzNDGm9oYiLGh2XBPfMPzCPs4YAUpJ-cqWtQqeqrY9U	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-30 10:35:12.363	\N	\N	e85b616e-7672-4409-b084-856e651a3ea5
1435346019087812370	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjE5MjcyZjgzLTgwOTItNDlhYS1iODI1LTAyYTAwMWZiZTcyNyJ9.eyJpYXQiOjE3MzgyOTgxNzksImV4cCI6MTc2OTgzNDE3OSwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.UfKrx03mFqeyBEyAhGtEiyjXYsRF2CEL_WWTX2NiuuA	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-01-31 04:36:19.191	\N	\N	9d02dc8a-60cd-4f34-b0cc-4bdd5dcd41f4
1437687250916738861	1430480385812202497	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFmNjI0ZGVkLTk1ZjAtNDNjZi1hMmM3LWJmNGU1ZmM3OGJlMSJ9.eyJpYXQiOjE3Mzg1NzcyNzUsImV4cCI6MTc3MDExMzI3NSwic3ViIjoiMTQzMDQ4MDM4NTgxMjIwMjQ5NyJ9.AZs3ytsvtb09tHCFJpzEsAFbArpgaVA7BYPvN9WxpSM	172.19.0.3	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-03 10:07:55.761	\N	\N	3ca394b9-d655-4e83-9ed1-2f175dd9e39c
1437710186117596978	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjdkMTA3NTVkLWIyYzgtNGNjMC1iMjE2LTJhOThjZDk1OGM1NSJ9.eyJpYXQiOjE3Mzg1ODAwMDksImV4cCI6MTc3MDExNjAwOSwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.uIif9DmGwAz6s_JCSNyo5dAtZnZ2duo6eEXjVfl2mRw	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-03 10:53:29.863	\N	\N	e666f726-f6f8-4942-a702-0ae57e0fb300
1437712717598164809	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImQ4ZDRkYTczLTU0NzktNDBjNy05OGYyLTFlNzA4MDA5YTMzNCJ9.eyJpYXQiOjE3Mzg1ODAzMTEsImV4cCI6MTc3MDExNjMxMSwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.iM3bJmoDNIITkW0G1Jtzra3ExWKZF1P8Wu5kLB3ubRs	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-03 10:58:31.642	\N	\N	9f75944b-0657-48db-9969-3b2af49c6a11
1438198475270391633	1433172478670144855	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjE5N2FkNjJkLTE4MmItNDk5Mi04OTZjLWY3MDI2MWQ1ZmFiZSJ9.eyJpYXQiOjE3Mzg2MzgyMTgsImV4cCI6MTc3MDE3NDIxOCwic3ViIjoiMTQzMzE3MjQ3ODY3MDE0NDg1NSJ9.MUlv9SlFm6mOTbR_MocBa7_o2GVRGG267OJUz71jI74	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-04 03:03:38.46	\N	\N	e39df9ab-b20e-42ca-86d3-05858f257f44
1438215270622562132	1433172877045138776	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImM5MzI5YjA1LTk3ZjQtNGExNi04Y2JmLWJlOGE0ZjhkMDA3YSJ9.eyJpYXQiOjE3Mzg2NDAyMjAsImV4cCI6MTc3MDE3NjIyMCwic3ViIjoiMTQzMzE3Mjg3NzA0NTEzODc3NiJ9.rgZpkMaf2vwwBv-EsigPRekrlIGpldTg-eLB_HdbTJU	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-04 03:37:00.631	\N	\N	088ae294-c332-4cb7-9110-5f68bd74c571
1438216591626995541	1430524402960696364	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImQ0MmI3NWI1LWFjOGItNGI5YS1iMDk2LWY0NjYyYjJhZTdkOSJ9.eyJpYXQiOjE3Mzg2NDAzNzgsImV4cCI6MTc3MDE3NjM3OCwic3ViIjoiMTQzMDUyNDQwMjk2MDY5NjM2NCJ9.P62zp0V3iXp8L9mHa97caK17Jc3Yo2gVyqoOV2UUG-g	172.19.0.3	Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) GSA/353.1.720279278 Mobile/15E148 Safari/604.1	2025-02-04 03:39:38.105	\N	\N	50a633d5-37d9-44d7-a2ec-8a768b6b75be
1438313033565734830	1433171377464018261	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImU3OTgxYmI1LTcwODgtNDEwNi04YmQ2LTlhMjg0MGEyOWEwNiJ9.eyJpYXQiOjE3Mzg2NTE4NzQsImV4cCI6MTc3MDE4Nzg3NCwic3ViIjoiMTQzMzE3MTM3NzQ2NDAxODI2MSJ9.woPvU3H9OZbyV7OoRe835c0uRrCPQmSTmnH1zyT13UQ	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 OPR/116.0.0.0	2025-02-04 06:51:14.879	\N	\N	cf4fdfe8-60ab-46f2-b8cf-f10007acbf44
1438409556429375423	1433261799410501042	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjQ3M2U3NzIxLTdmMjMtNDBhZS05NGVjLTY4NmQ2YTVkMGE5MCJ9.eyJpYXQiOjE3Mzg2NjMzODEsImV4cCI6MTc3MDE5OTM4MSwic3ViIjoiMTQzMzI2MTc5OTQxMDUwMTA0MiJ9.cb20y-DEWY-6JqZQ0Kmh3tzgxoIp2CE3-AgFKLlpJLM	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-04 10:03:01.301	\N	\N	3e59a6fa-464d-4741-860d-0f0d6c11e94f
1438448358422218725	1433330078485317156	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjBlMTM3NzMxLTIwOGEtNDhiNi1hZDVkLTFlNjFkZjViYjIyMCJ9.eyJpYXQiOjE3Mzg2NjgwMDYsImV4cCI6MTc3MDIwNDAwNiwic3ViIjoiMTQzMzMzMDA3ODQ4NTMxNzE1NiJ9.16F9G0jIjzXPkVjms1n7qi9ipriHCf8ktgijpj3b2F8	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-04 11:20:06.859	\N	\N	4c01492b-0d68-462c-aa69-49ba8ca89552
1438928076019861482	1433172244418266454	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImYxZjY3OTc2LTcwYjgtNDlhNC1iYjI3LTU2NWMzNGY5MDEyOCJ9.eyJpYXQiOjE3Mzg3MjUxOTMsImV4cCI6MTc3MDI2MTE5Mywic3ViIjoiMTQzMzE3MjI0NDQxODI2NjQ1NCJ9.w2FDsMS2W096xkupf_50tOcmR_2b1na_69lHSQ_FZRA	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15	2025-02-05 03:13:13.654	\N	\N	52a6d4c6-090e-4636-a830-f83b5c28a8cc
1438941019717502067	1433172877045138776	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjM2ZmU1N2FjLWRmNzgtNDhlMy04ZDkwLTJiMmM0OTY2NWYzOSJ9.eyJpYXQiOjE3Mzg3MjY3MzYsImV4cCI6MTc3MDI2MjczNiwic3ViIjoiMTQzMzE3Mjg3NzA0NTEzODc3NiJ9.dGVdjHz_7Ti5JphecCTnTfXlld6nEc6NhOp8XkOeYXU	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15	2025-02-05 03:38:56.657	\N	\N	35361cec-6f99-4154-acce-5bf274c88daa
1439675120862889497	1433172877045138776	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjI0YmY1NjA0LWE4ODQtNDUwMi04MjYzLWZkNWQxYThlNTI0MyJ9.eyJpYXQiOjE3Mzg4MTQyNDgsImV4cCI6MTc3MDM1MDI0OCwic3ViIjoiMTQzMzE3Mjg3NzA0NTEzODc3NiJ9.RJU4KM2gL8NDhmSCNnnqPoLeKx7fuhIRb9SwaDkmDBg	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15	2025-02-06 03:57:28.338	\N	\N	ef1cdbda-f625-470c-a6c6-51dbef0db265
1439706318431585861	1430524402960696364	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjFkMDY5ZDdlLWMxOTItNDVjMC04ZDdjLWM0YmViMDM0MWI4NSJ9.eyJpYXQiOjE3Mzg4MTc5NjcsImV4cCI6MTc3MDM1Mzk2Nywic3ViIjoiMTQzMDUyNDQwMjk2MDY5NjM2NCJ9.fFZZ9mAQzYqjzjVSZxGutrpp7LLCWPsULcngMQWZxyw	172.19.0.3	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-02-06 04:59:27.378	\N	\N	b94440a1-9656-47aa-9ac1-fcef51638bc3
1440392013584271128	1434714317982271199	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImViZWU3ZGQ2LWE3MmMtNGM1Yi1iMjcyLWVhYzgzNGNjYTI4ZSJ9.eyJpYXQiOjE3Mzg4OTk3MDgsImV4cCI6MTc3MDQzNTcwOCwic3ViIjoiMTQzNDcxNDMxNzk4MjI3MTE5OSJ9.6HMclgZSjr9-sA1ZjGrQSD5w8_bwJafd8f1D15Yo5ew	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-07 03:41:48.611	\N	\N	27376ed5-d77a-4928-add2-98c000cf3218
1437697013830387502	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjJkNGQ1MmY4LTY3YTQtNDQ3NS1iMmEyLWFmNTYyYzk2NjBjMSJ9.eyJpYXQiOjE3Mzg1Nzg0MzksImV4cCI6MTc3MDExNDQzOSwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.JKLj0Bsxi5ln_YR5bZWh2Ut8awjaU-B4MIDpu8sIFYY	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-03 10:27:19.602	2025-02-07 07:54:41.827	2025-02-07 07:54:41.825	fc043b59-9d40-48c9-a0c5-bd02b99aea4c
1440536007639304025	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjdhYWZiNGUyLTM5NTQtNDg1NS05ZDNhLTg1NmM3NjA3MzY0MCJ9.eyJpYXQiOjE3Mzg5MTY4NzQsImV4cCI6MTc3MDQ1Mjg3NCwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.MYg4bjDIEg59Tz49yj1Ej4V8zswct9aWCHpI7T7ehuA	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-07 08:27:54.039	\N	\N	018c7d4c-0ec2-4a56-a5f6-69d07b25f694
1440591519747671907	1439748730579322441	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjM4Y2E3NGFkLWQ2MjItNDVlMC1iNzNhLTA4ODg5MDhjZGIzNyJ9.eyJpYXQiOjE3Mzg5MjM0OTEsImV4cCI6MTc3MDQ1OTQ5MSwic3ViIjoiMTQzOTc0ODczMDU3OTMyMjQ0MSJ9.Kz_SyMFi0YvmGTBH4Wy-bIeweyxh4Dhnioc1un2Tggg	172.19.0.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-07 10:18:11.599	\N	\N	20ab79b7-c3eb-4dca-bacd-36aa1250db4b
1440636072458454884	1433330078485317156	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjlkM2M0NTcxLTJlMTYtNDM4OS1hNzhlLWI1NjM1ZWNjOWFhYyJ9.eyJpYXQiOjE3Mzg5Mjg4MDIsImV4cCI6MTc3MDQ2NDgwMiwic3ViIjoiMTQzMzMzMDA3ODQ4NTMxNzE1NiJ9.9iBR9yDBhAxi55KXCTNnrk8P2agXkvzOwxndLs7YXrk	172.19.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-02-07 11:46:42.695	\N	\N	6b44e120-3a09-40ff-bdfe-fb7ea1946452
1442953660895070140	1434720470833301219	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjIyMGU2NGNiLTZjZGUtNDZlZC04YjgwLTlmYmViOWRmNjIxZSJ9.eyJpYXQiOjE3MzkyMDUwODAsImV4cCI6MTc3MDc0MTA4MCwic3ViIjoiMTQzNDcyMDQ3MDgzMzMwMTIxOSJ9.JiskYVLkJY8tD-XYwglWSrtaaAGHH1d48pXNwuHxeXQ	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-10 16:31:20.767	2025-02-10 16:31:47.476	2025-02-10 16:31:47.474	8eef7384-adc8-4a69-b7c3-b8e607118136
1442954016806930365	1434720470833301219	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjE2YTRhOGIyLTg2NWItNDJmYS04YjQ4LWFjMjExNjI3MDIwZiJ9.eyJpYXQiOjE3MzkyMDUxMjMsImV4cCI6MTc3MDc0MTEyMywic3ViIjoiMTQzNDcyMDQ3MDgzMzMwMTIxOSJ9.jWxKS384MvvFZHNab3wr0klKMufG5KIuuJmzNC8euHg	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-10 16:32:03.195	\N	\N	950fcb5f-048a-4d76-b398-584387ca2ac5
1443263833794676670	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ijg3MGJiNjU1LWU2MzctNGQyMS1iM2RiLWYwMDY4Yjc2MDVkYSJ9.eyJpYXQiOjE3MzkyNDIwNTYsImV4cCI6MTc3MDc3ODA1Niwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.EIQzMNU9bFRa-fOsUe2n-7a3hg375-y-09vR8Ffq6eo	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-11 02:47:36.258	\N	\N	e51fcd50-817d-4364-8050-4108442c7412
1443276099667625928	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjQ5YjVkYzdlLWNlY2EtNGM0Ny05Yzc4LTBlZTAwMzNlZTI2YiJ9.eyJpYXQiOjE3MzkyNDM1MTgsImV4cCI6MTc3MDc3OTUxOCwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.R7rA7_nFjCQDIfHZLyTz0tZZ7CmQBVl0SELpIVzuWec	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-11 03:11:58.464	\N	\N	0f5b27f9-e627-41ac-96e4-eedb7a4ea870
1443276420523493321	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImM0Y2IyM2I0LWU4MjUtNDQwZC1iYzVhLTVmMGI0MzJlZjk4ZSJ9.eyJpYXQiOjE3MzkyNDM1NTYsImV4cCI6MTc3MDc3OTU1Niwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.KpjjiobAeyaDokH3tVJjEcA9W5RY3V_WzlFuaqX7rYU	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-11 03:12:36.713	\N	\N	f7c30475-a602-47d5-a482-a2e301f7a9d6
1443278106818250698	1430524402960696364	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImU3NTIxYjVkLWNhZmItNGIxNS04ZDVkLWIxMmE2N2ZkZTU3MSJ9.eyJpYXQiOjE3MzkyNDM3NTcsImV4cCI6MTc3MDc3OTc1Nywic3ViIjoiMTQzMDUyNDQwMjk2MDY5NjM2NCJ9.GeZYipNrofd9G9N5DN5rccYPn3fgCNdsduG8cuwRMNI	172.19.0.2	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0	2025-02-11 03:15:57.735	\N	\N	59303709-7e99-4e32-8573-832895c6d775
1443280750764885965	1433172244418266454	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjAwMTgzNTkyLWJiZWEtNDY1My1iMDc0LWU3ZGZhYzRlMzFmNyJ9.eyJpYXQiOjE3MzkyNDQwNzIsImV4cCI6MTc3MDc4MDA3Miwic3ViIjoiMTQzMzE3MjI0NDQxODI2NjQ1NCJ9.ODZOGy9jD2SQYvYSJOErhswbgZOjcxvxntQusDZ49Bc	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15	2025-02-11 03:21:12.916	\N	\N	d158a86b-502d-4494-8795-ce52fdec082c
1443316795069958138	1433172478670144855	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjZiM2E0YTFjLTA2M2QtNGEzNy1iMDVkLTJhNGIyYWJiOTVhMyJ9.eyJpYXQiOjE3MzkyNDgzNjksImV4cCI6MTc3MDc4NDM2OSwic3ViIjoiMTQzMzE3MjQ3ODY3MDE0NDg1NSJ9.2qxHFMEjiis7wmikAJbgurAeIcN7vLl-wvySFc-1Rck	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-11 04:32:49.734	\N	\N	78ea0520-3cae-4f1e-9427-5fdc37c513f0
1442898088715880374	1430480385812202497	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImU0Y2M0MTRkLTg2ZjktNDU0NC1hMTJhLTk0MGI4YzUxNDRjNiJ9.eyJpYXQiOjE3MzkxOTg0NTUsImV4cCI6MTc3MDczNDQ1NSwic3ViIjoiMTQzMDQ4MDM4NTgxMjIwMjQ5NyJ9.rEStLGPAeqd__3mAL8koexlRqUXOvi1uaZjrqjaxQnU	172.19.0.2	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-10 14:40:56.001	2025-02-11 06:53:12.774	2025-02-11 06:53:12.773	98149323-b5ef-49fe-a986-7cf73dcc7d06
1443387517528179740	1434720470833301219	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImUxY2EzOGFmLTQ2YzAtNGVlZi1iMjVmLTk3NjQxNGU2MDA1YiJ9.eyJpYXQiOjE3MzkyNTY4MDAsImV4cCI6MTc3MDc5MjgwMCwic3ViIjoiMTQzNDcyMDQ3MDgzMzMwMTIxOSJ9.OJI2bth0hPQsI1jk5iNUI5bxuq9zzPknLwH3CqiGoaA	172.19.0.2	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-11 06:53:20.508	2025-02-11 07:15:08.858	2025-02-11 07:15:08.855	ffb38262-7523-4552-b73c-67f1275901b0
1443496270344750220	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFmMzQ4NTMwLWUwOWEtNDU1Yi04Zjg4LWRjZmEzOGU1ZmI1YSJ9.eyJpYXQiOjE3MzkyNjk3NjQsImV4cCI6MTc3MDgwNTc2NCwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.lusmBwwq0794rnzAc4ZBM9Z7EtyVGD8pXYNNIDuSj4U	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-11 10:29:24.853	\N	\N	2f0ab8b5-6a2b-40ad-93ba-470877952821
1443497678330659981	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY3OTE0ZDE2LTUzYmUtNDZiYS04ZjI1LTIwYTgwMzk1NWRhMCJ9.eyJpYXQiOjE3MzkyNjk5MzIsImV4cCI6MTc3MDgwNTkzMiwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.1MfNd0CY9rWP92VpZrCB4tnWE-d3CYGpyVnnn_Gay7Q	172.19.0.2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36	2025-02-11 10:32:12.699	\N	\N	4bff54cc-5451-4b16-b8ca-f6729b41e513
1444002197309228188	1430480385812202497	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImM4ZWI3OGYxLWM5ZGEtNDM0Mi1hYjk4LTg5MzgwMmU0MTE4MCJ9.eyJpYXQiOjE3MzkzMzAwNzYsImV4cCI6MTc3MDg2NjA3Niwic3ViIjoiMTQzMDQ4MDM4NTgxMjIwMjQ5NyJ9.tnNNN6cx9I6kC7zmbpD4crvkehNoPTVjCM1hOj-imRY	172.19.0.2	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36	2025-02-12 03:14:36.043	\N	\N	1a1c26ff-a658-42eb-8a58-c73759751c9e
1692048293493736620	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjUzNGNiNTI4LTY2MzYtNDg0Yy1hMGNiLTllZjUwMWM3NGYzOCJ9.eyJpYXQiOjE3Njg4OTk0NzQsImV4cCI6MTgwMDQzNTQ3NCwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.q0aRl0z0ySRBJYcOuhUADKziWA2jKQ4nSsuERqvlr9I	184.82.125.31	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	2026-01-20 08:57:54.945	\N	\N	dd369782-e6ca-4388-8e55-1d173f348c86
1692048811867767981	1430525186381186093	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjRlMjMyOGQzLWQwNGQtNGM1Yi04NjFhLTlhMDNjMzI4NzU3MCJ9.eyJpYXQiOjE3Njg4OTk1MzYsImV4cCI6MTgwMDQzNTUzNiwic3ViIjoiMTQzMDUyNTE4NjM4MTE4NjA5MyJ9.2fNNq6Lqb33d1ADP1Er2KqAk9tJa_FIvbcs7Aff7e20	184.82.125.31	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	2026-01-20 08:58:56.743	\N	\N	137f7346-b242-4775-94eb-49f9ee898d11
1692058394753500347	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImQ4YmE5NWZiLTYwYjgtNDI2MS05YjVhLTYxMGZjYjY1MTk5OSJ9.eyJpYXQiOjE3Njg5MDA2NzksImV4cCI6MTgwMDQzNjY3OSwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.PccbDPKcXiyIw28_3ukrVbd18O13Jh9vXyuRaD3Uf7A	184.82.125.31	Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/144.0.7559.85 Mobile/15E148 Safari/604.1	2026-01-20 09:17:59.112	\N	\N	1925f88e-d331-442d-afbe-fe69658c79a6
1692109865918399694	1433172478670144855	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjlhNTM4ZjY0LTc1ODItNDNjNC05MTliLWY0NDFjNWQzYTA0MiJ9.eyJpYXQiOjE3Njg5MDY4MTQsImV4cCI6MTgwMDQ0MjgxNCwic3ViIjoiMTQzMzE3MjQ3ODY3MDE0NDg1NSJ9.NgVx_RYLbgzUrTesPOVltKWo2X_yEEU0xIigYQ0dB8w	49.228.106.161	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	2026-01-20 11:00:14.954	\N	\N	e8da2c1f-7b80-411b-8431-84b16df9fb68
1692109875036816591	1430501158790628357	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjA5YzhiMWZjLWRhOWYtNGViYy1iYzNmLTAzNDY0NDFmOTU1NSJ9.eyJpYXQiOjE3Njg5MDY4MTYsImV4cCI6MTgwMDQ0MjgxNiwic3ViIjoiMTQzMDUwMTE1ODc5MDYyODM1NyJ9.P8FT94yw12X6FF8l53VhKCC6k9qQSXOcrcVu3jbVVL4	49.228.106.161	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	2026-01-20 11:00:16.044	\N	\N	2783af1c-fefb-479c-9c2d-ee600bcf0500
1692144453248091352	1433172244418266454	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImU0NWYwMTI5LWZiMmQtNDI2YS1hNTMwLTk3MmQwZmFjYWY1MyJ9.eyJpYXQiOjE3Njg5MTA5MzgsImV4cCI6MTgwMDQ0NjkzOCwic3ViIjoiMTQzMzE3MjI0NDQxODI2NjQ1NCJ9.KhCZd3YZuhQYjr_9lPv-LSwJJAYzXxIq6NARrsJA3nM	49.228.106.161	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15	2026-01-20 12:08:58.085	\N	\N	ded9adcc-73db-4cfb-a60c-0585e302dd3d
1692190442407331033	1430534043199341650	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjY4YTg1NDhjLTFiNzctNGEzNS05ZDgwLTMzZGE0OTZmNGNhMCJ9.eyJpYXQiOjE3Njg5MTY0MjAsImV4cCI6MTgwMDQ1MjQyMCwic3ViIjoiMTQzMDUzNDA0MzE5OTM0MTY1MCJ9.6Hp0GBKnaLbwkWYT60TormOn_GqGfCpjEEIhaGqnv2s	49.228.59.230	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	2026-01-20 13:40:20.42	\N	\N	a7999e52-4255-4177-9ed3-88ca1335703c
1692599214485275882	1433261799410501042	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjE5ZmJlZDFhLTEwOTUtNDI2NS1hOGJlLWQ1ZDZjYTQyMmVmZCJ9.eyJpYXQiOjE3Njg5NjUxNDksImV4cCI6MTgwMDUwMTE0OSwic3ViIjoiMTQzMzI2MTc5OTQxMDUwMTA0MiJ9.owonKnLu5jLkZrJXe4jSqBE7tKIJjQlRaOLQ1085VNo	184.82.125.31	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	2026-01-21 03:12:29.849	\N	\N	1c424075-32cb-4f98-ae2f-a5f4a12a915e
\.


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.task (id, card_id, name, is_completed, created_at, updated_at, "position") FROM stdin;
1430521041427366951	1430519898227868700	read	f	2025-01-24 12:49:57.032	\N	65535
1430521056979846184	1430519898227868700	write	t	2025-01-24 12:49:58.889	2025-01-24 12:52:21.672	131070
1430521078286910505	1430519898227868700	action	t	2025-01-24 12:50:01.428	2025-01-24 13:08:30.405	196605
1432127336362280036	1432126863186068574	Instruction Prompt Adjustment	f	2025-01-26 18:01:22.311	\N	131070
1432127562963747941	1432126863186068574	Research	t	2025-01-26 18:01:49.324	2025-01-26 18:01:54.228	32767.5
1433256013443630497	1433254977265993112	Juno to upload psd file to Final Drive	f	2025-01-28 07:23:51.102	\N	327675
1432139833249105079	1432138030939899056	Python Script to store Contextual RAG data into Vector DB	t	2025-01-26 18:26:12.056	2025-01-27 12:01:29.138	196605
1432139626780296374	1432138030939899056	Python Script for convert data into Contextual RAG with LLM	t	2025-01-26 18:25:47.441	2025-01-27 12:01:34.082	131070
1432131444884374656	1432131205364450429	Draft of Terms	f	2025-01-26 18:09:32.085	2025-01-26 18:09:49.682	65535
1432131505701782657	1432131205364450429	Draft of Policies	f	2025-01-26 18:09:39.337	2025-01-26 18:09:53.374	131070
1432131539180717186	1432131205364450429	Draft of Cookies	f	2025-01-26 18:09:43.328	2025-01-26 18:09:57.796	196605
1432131772090418307	1432131205364450429	Review draft of terms	f	2025-01-26 18:10:11.089	\N	262140
1432131916273812613	1432131205364450429	Review draft of cookies	f	2025-01-26 18:10:28.28	\N	393210
1432131836280046724	1432131205364450429	Review draft of policies	f	2025-01-26 18:10:18.745	2025-01-26 18:10:32.554	327675
1432132468093224073	1432131205364450429	Finalize terms	f	2025-01-26 18:11:34.061	\N	458745
1432132491094787210	1432131205364450429	Finalize policies	f	2025-01-26 18:11:36.804	\N	524280
1432132514289288331	1432131205364450429	Finalize cookies	f	2025-01-26 18:11:39.57	\N	589815
1432132681155478668	1432132167101580422	Design of the page	f	2025-01-26 18:11:59.46	\N	65535
1432132933937792141	1432132167101580422	Implement into the website	f	2025-01-26 18:12:29.593	\N	131070
1432133527649911959	1432133249383007377	Design of UI and Workflow	f	2025-01-26 18:13:40.369	\N	65535
1432133609111684248	1432133249383007377	Implement into the website	f	2025-01-26 18:13:50.083	\N	131070
1432133652011025561	1432133309344777364	Implement into the website	f	2025-01-26 18:13:55.198	\N	65535
1432133704993473690	1432133165018776718	Implement into the website	f	2025-01-26 18:14:01.512	\N	65535
1432133801043035291	1432133165018776718	Design of UI and Workflow	f	2025-01-26 18:14:12.961	2025-01-26 18:14:15.572	32767.5
1432133879652680860	1432133309344777364	Design of UI and Workflow	f	2025-01-26 18:14:22.334	2025-01-26 18:14:24.299	32767.5
1432139356591621301	1432138030939899056	Python Script to pull data from provided source i.e. url, file, youtube	t	2025-01-26 18:25:15.234	2025-01-28 03:13:38.3	65535
1432162161660003548	1432138030939899056	Implement to Backend (make sure it runs as background)	t	2025-01-26 19:10:33.809	2025-01-28 03:13:43.704	262140
1432144996496049350	1432144454029935809	Research on how to make two database be able to sync between each other	f	2025-01-26 18:36:27.562	\N	65535
1432145536932119751	1432143088423273660	Past test (v1.x.x)	f	2025-01-26 18:37:31.988	\N	65535
1432145606607897800	1432143088423273660	Current test (v2.x.x)	f	2025-01-26 18:37:40.296	\N	131070
1432152450982216912	1432144454029935809	Summary report	f	2025-01-26 18:51:16.207	\N	131070
1432154746130531542	1432154072584029393	Docker commands Volume, Network, Firewall	f	2025-01-26 18:55:49.81	\N	65535
1432155161609897176	1432154072584029393	Learn how to write a `dokcer-compose.yml` file	f	2025-01-26 18:56:39.338	\N	196605
1432154913265157335	1432154072584029393	Learn how to write a `Dockerfile` file	f	2025-01-26 18:56:09.733	2025-01-26 18:56:47.669	131070
1432158686570087643	1432151592458519753	Summary report	f	2025-01-26 19:03:39.546	\N	65535
1432672320987596095	1432671734758114616	Pull data from Google Sheet to data_source table	t	2025-01-27 12:04:09.541	2025-01-28 03:13:49.019	65535
1432128781031572597	1432128678245958769	English Premier League automation script	t	2025-01-26 18:04:14.531	2025-01-27 03:01:17.994	131070
1432128863835522166	1432128678245958769	Major League Soccer automation script	t	2025-01-26 18:04:24.402	2025-01-27 03:01:19.294	196605
1432129207676175479	1432128678245958769	Use Flock or similar blocking software to avoid multiple automation scripts run at the same time	t	2025-01-26 18:05:05.388	2025-01-27 04:23:15.985	262140
1432128722051269748	1432128678245958769	J.League automation script	t	2025-01-26 18:04:07.5	2025-01-27 04:23:32.736	65535
1432130969963332732	1432128678245958769	Implement everything above on Lab2 server	t	2025-01-26 18:08:35.47	2025-01-27 04:23:33.366	327675
1432137333544584363	1432136214110012584	Check and Update the current form to support the three leagues and flexible for the upcoming	f	2025-01-26 18:21:14.066	2025-01-27 12:01:12.959	65535
1433240962955478415	1433235122395547021	Peerapat to upload editing files to Final Drive	f	2025-01-28 06:53:56.946	2025-01-28 07:12:38.74	65535
1433255217758995866	1433254977265993112	EN	f	2025-01-28 07:22:16.251	\N	65535
1433255256153654683	1433254977265993112	TH	f	2025-01-28 07:22:20.83	\N	131070
1433255262503830940	1433254977265993112	ID	f	2025-01-28 07:22:21.587	\N	196605
1433255275304846749	1433254977265993112	VN	f	2025-01-28 07:22:23.113	\N	262140
1433283516728083900	1433271312972776888	Change photos to avoid Puma logos as much as possible	f	2025-01-28 08:18:29.751	\N	65535
1433283542070068669	1433271312972776888	EN	f	2025-01-28 08:18:32.774	\N	131070
1433283548512519614	1433271312972776888	TH	f	2025-01-28 08:18:33.542	\N	196605
1433283583476237759	1433271312972776888	ID	f	2025-01-28 08:18:37.71	\N	262140
1433283593299297728	1433271312972776888	VN	f	2025-01-28 08:18:38.88	\N	327675
1433283685456545217	1433271312972776888	Peerapat to upload PSD file to Final Drive	f	2025-01-28 08:18:49.864	\N	393210
1433301740609865164	1433300241649501641	EN	f	2025-01-28 08:54:42.207	\N	65535
1433301745768859085	1433300241649501641	TH	f	2025-01-28 08:54:42.824	\N	131070
1433301751078847950	1433300241649501641	ID	f	2025-01-28 08:54:43.455	\N	196605
1433301758595040719	1433300241649501641	VN	f	2025-01-28 08:54:44.353	\N	262140
1433302015705875920	1433300241649501641	Serewat to upload PSD file to Final Drive	f	2025-01-28 08:55:14.997	\N	327675
1433315052735170020	1433314479944238559	Phyo to upload PSD files to Final Drive	f	2025-01-28 09:21:09.134	\N	65535
1433318722122024435	1433318486083372529	EN	f	2025-01-28 09:28:26.561	\N	65535
1433230401127581054	1433228368576251259	Add 1 slide (2nd page) for team name's origin, club slogan, development slogan	t	2025-01-28 06:32:57.876	2025-01-31 05:02:51.793	65535
1433234158838089094	1433233702573311364	Sharp to provide information	t	2025-01-28 06:40:25.832	2025-01-29 09:16:14.795	65535
1433230722881029503	1433228368576251259	"Why Pink?" Slide: Change background photo	t	2025-01-28 06:33:36.233	2025-01-31 05:02:52.814	131070
1433232200911816065	1433228368576251259	"Mascot" Slide: Lobby & Madam Lobina, find alternative photos to not clearly show Puma logo	t	2025-01-28 06:36:32.429	2025-01-31 05:02:54.312	196605
1433256101926667682	1433228368576251259	EN	t	2025-01-28 07:24:01.651	2025-02-03 10:53:38.335	327675
1433256121262409123	1433228368576251259	TH	t	2025-01-28 07:24:03.959	2025-02-03 10:53:39.761	393210
1433256127318984100	1433228368576251259	ID	t	2025-01-28 07:24:04.681	2025-02-03 10:53:40.61	458745
1432127161568855139	1432126863186068574	Create ReAct Agent from scratch	t	2025-01-26 18:01:01.474	2025-02-04 03:41:46.652	65535
1433256358651626918	1433241292510332304	Sharp to list who to be included in the graphic	t	2025-01-28 07:24:32.255	2025-02-03 10:57:31.229	32767.5
1433234378049193351	1433233702573311364	Phyo to upload .psd file to Final Drive	t	2025-01-28 06:40:51.964	2025-02-04 10:06:11.655	131070
1433241766542181778	1433241292510332304	EN	t	2025-01-28 06:55:32.741	2025-02-04 10:08:32.922	65535
1433241817855296915	1433241292510332304	TH	t	2025-01-28 06:55:38.859	2025-02-04 10:08:33.871	131070
1433241831117686164	1433241292510332304	ID	t	2025-01-28 06:55:40.441	2025-02-04 10:08:34.681	196605
1433241837300090261	1433241292510332304	VN	t	2025-01-28 06:55:41.178	2025-02-04 10:08:35.884	262140
1433241844187137430	1433241292510332304	MM	t	2025-01-28 06:55:41.999	2025-02-04 10:25:53.425	327675
1433241960864286103	1433241292510332304	Phyo to upload .psd file to Final Drive	t	2025-01-28 06:55:55.905	2025-02-04 10:09:50.653	393210
1433256162123318693	1433228368576251259	VN	t	2025-01-28 07:24:08.83	2025-02-05 10:22:17.296	524280
1433313307116176854	1433303096687068625	EN	t	2025-01-28 09:17:41.041	2025-02-10 03:27:48.271	65535
1433313312627492311	1433303096687068625	TH	t	2025-01-28 09:17:41.701	2025-02-10 03:27:49.025	131070
1433313318944114136	1433303096687068625	ID	t	2025-01-28 09:17:42.454	2025-02-10 03:27:49.668	196605
1433313327617934809	1433303096687068625	VN	t	2025-01-28 09:17:43.488	2025-02-10 03:27:50.413	262140
1433318738580473332	1433318486083372529	TH	f	2025-01-28 09:28:28.525	\N	131070
1433318747371734517	1433318486083372529	ID	f	2025-01-28 09:28:29.573	\N	196605
1433318754879538678	1433318486083372529	VN	f	2025-01-28 09:28:30.468	\N	262140
1433318846952900087	1433318486083372529	Peerapat to upload PSD file to Final Drive	f	2025-01-28 09:28:41.442	\N	327675
1433326466283603470	1433326151408813580	Peerapat to upload editing files to Final Drive	f	2025-01-28 09:43:49.737	\N	65535
1433327010083505680	1433320073308669432	EN	f	2025-01-28 09:44:54.563	\N	65535
1433327022439925265	1433320073308669432	TH	f	2025-01-28 09:44:56.037	\N	131070
1433327028202898962	1433320073308669432	ID	f	2025-01-28 09:44:56.725	\N	196605
1433327034653738515	1433320073308669432	VN	f	2025-01-28 09:44:57.494	\N	262140
1433327123480708628	1433320073308669432	Phyo to upload PSD file to Final Drive	f	2025-01-28 09:45:08.08	\N	327675
1433327258017203733	1433317255122257385	EN	f	2025-01-28 09:45:24.119	\N	65535
1433327272974091798	1433317255122257385	TH	f	2025-01-28 09:45:25.904	\N	131070
1433327278535738903	1433317255122257385	ID	f	2025-01-28 09:45:26.567	\N	196605
1433327284575536664	1433317255122257385	VN	f	2025-01-28 09:45:27.288	\N	262140
1433327292972533273	1433317255122257385	MM	f	2025-01-28 09:45:28.289	\N	327675
1433327366272189978	1433317255122257385	Phyo to upload PSD file to Final Drive	f	2025-01-28 09:45:37.026	\N	393210
1433327474728502813	1433322124021335558	EN	f	2025-01-28 09:45:49.955	\N	65535
1433327479912662558	1433322124021335558	TH	f	2025-01-28 09:45:50.574	\N	131070
1433327484803221023	1433322124021335558	ID	f	2025-01-28 09:45:51.156	\N	196605
1433327492789175840	1433322124021335558	VN	f	2025-01-28 09:45:52.108	\N	262140
1433327498375988769	1433322124021335558	MM	f	2025-01-28 09:45:52.773	\N	327675
1433327504768108066	1433322124021335558	Phyo to upload PSD file to Final Drive	f	2025-01-28 09:45:53.536	\N	393210
1433326916584080911	1433320514390066684	Wisuwat to upload editing files to Final Drive	t	2025-01-28 09:44:43.418	2025-01-28 10:47:02.386	327675
1433320824978277888	1433320514390066684	EN	t	2025-01-28 09:32:37.242	2025-01-28 10:47:08.784	65535
1433320847291975169	1433320514390066684	TH	t	2025-01-28 09:32:39.903	2025-01-28 10:47:09.594	131070
1433320857349916162	1433320514390066684	ID	t	2025-01-28 09:32:41.102	2025-01-28 10:47:10.093	196605
1435347380592445207	1435346986613081875	Phyo to upload PSD file to Final Drive	f	2025-01-31 04:39:01.496	\N	65535
1433231762237949312	1433228368576251259	"Logo Elements" Slide: Remove the breakdown photos, use arrow instead, and change jersey photo	t	2025-01-28 06:35:40.134	2025-01-31 05:02:50.649	98302.5
1433234875602699657	1433228368576251259	Peerapat to upload .psd files to Final Drive	f	2025-01-28 06:41:51.277	2025-01-29 07:57:18.435	589815
1433945271976330824	1433944122544096833	Upload load psd file to Final Drive	t	2025-01-29 06:13:17.124	2025-01-29 08:14:45.856	262140
1434032285203564131	1434029186309162585	อัพฟุตให้จูโน่แล้ว	f	2025-01-29 09:06:09.909	\N	65535
1434032736888161895	1434029186309162585	QC ผ่านแล้ว	f	2025-01-29 09:07:03.754	\N	196605
1434032941217875560	1434029186309162585	อัพลงเพจแล้ว	f	2025-01-29 09:07:28.112	\N	262140
1434032572840543846	1434029186309162585	จูโน่ส่งดราฟแรกแล้ว	f	2025-01-29 09:06:44.199	2025-01-29 09:08:20.025	131070
1434033769928459881	1434029700119791195	อัพฟุตให้จูโน่แล้ว	f	2025-01-29 09:09:06.9	\N	65535
1434033858092729962	1434029700119791195	จูโน่ส่งดราฟแรกแล้ว	f	2025-01-29 09:09:17.412	\N	131070
1434033956298163819	1434029700119791195	QC ผ่านแล้ว	f	2025-01-29 09:09:29.119	\N	196605
1434034029765592684	1434029700119791195	อัพลงเพจแล้ว	f	2025-01-29 09:09:37.88	\N	262140
1434031693521487455	1434028784092186199	Upload image file to the final Drive	f	2025-01-29 09:04:59.374	2025-01-29 09:14:44.509	65535
1434726405261756139	1434109361990403733	Lookchin to select the best images	t	2025-01-30 08:05:15.467	2025-02-03 10:54:25.302	65535
1434726499390326508	1434109361990403733	Edit photos	t	2025-01-30 08:05:26.688	2025-02-03 10:54:26.032	131070
1434031781274715744	1434028784092186199	แต่งภาพเสร็จ	f	2025-01-29 09:05:09.837	2025-01-29 09:15:52.568	131070
1434031878112806497	1434028784092186199	ส่ง QC เสร็จ	f	2025-01-29 09:05:21.38	2025-01-29 09:15:53.538	196605
1434031936254248546	1434028784092186199	อัพลงเพจแล้ว	f	2025-01-29 09:05:28.313	2025-01-29 09:15:54.314	262140
1434038971326793342	1434038848156862074	EN	t	2025-01-29 09:19:26.959	2025-01-29 10:29:43.018	65535
1434038982886295167	1434038848156862074	TH	t	2025-01-29 09:19:28.337	2025-01-29 10:29:43.568	131070
1434038988959647360	1434038848156862074	VN	t	2025-01-29 09:19:29.06	2025-01-29 10:29:44.393	196605
1434042405270587018	1434026103898375761	Upload psd file to Final Drive	t	2025-01-29 09:26:16.315	2025-01-30 04:11:04.811	65535
1434726099622823654	1434710292574504669	Shot list & Story board	f	2025-01-30 08:04:39.032	\N	131070
1434039059499452033	1434038848156862074	Phyo to upload PSD file to Final Drive	t	2025-01-29 09:19:37.47	2025-01-30 08:15:26.88	262140
1434039631191475842	1434037967428519538	Edit a photo	t	2025-01-29 09:20:45.619	2025-02-03 10:58:34.624	65535
1434725375291688677	1434710292574504669	Close up detail shot	f	2025-01-30 08:03:12.686	2025-01-30 08:37:58.759	65535
1434040511919818371	1434037967428519538	Upload photo to the final Drive	t	2025-01-29 09:22:30.61	2025-02-03 10:58:36.704	131070
1438217394777491299	1438216984859772763	Scraping match_event data	t	2025-02-04 03:41:13.851	2025-02-04 03:41:15.035	131070
1438217256315127647	1438216984859772763	Scraping lineup data	t	2025-02-04 03:40:57.342	2025-02-04 03:41:15.725	65535
1438217494568372068	1438216984859772763	Scraping standing data	f	2025-02-04 03:41:25.745	\N	196605
1438217557625538405	1438216984859772763	Automate scraping	f	2025-02-04 03:41:33.263	\N	262140
1438218535493961585	1438218124980651878	Redux saga (optional)	f	2025-02-04 03:43:29.834	\N	196605
1438219333183473555	1438219017729869704	Turfmapp ReAct Agent	t	2025-02-04 03:45:04.924	2025-02-04 03:46:04.424	65535
1438219664592209812	1438219017729869704	Test Turfmapp ReAct Agent	t	2025-02-04 03:45:44.431	2025-02-04 03:46:05.094	131070
1438220081657022362	1438219109073422219	Custom DB schema	t	2025-02-04 03:46:34.149	2025-02-04 03:49:29.259	65535
1438222946559592358	1438219198076553102	Turfmapp ReAct can pull Planka data	f	2025-02-04 03:52:15.672	\N	65535
1438223044286875559	1438219198076553102	Use Planka as RAG	f	2025-02-04 03:52:27.316	\N	131070
1438223187010652072	1438219198076553102	Able to answer from Planka data	f	2025-02-04 03:52:44.337	\N	196605
1438413699135047619	1433259305485731246	TH	t	2025-02-04 10:11:15.151	2025-02-04 10:11:59.564	65535
1438413718965716932	1433259305485731246	ID	t	2025-02-04 10:11:17.517	2025-02-04 10:11:59.929	131070
1438413739677190085	1433259305485731246	EN	t	2025-02-04 10:11:19.986	2025-02-04 10:12:00.293	196605
1438413783566387142	1433259305485731246	Uploaded project file	t	2025-02-04 10:11:25.218	2025-02-04 10:12:00.861	262140
1434726807302571758	1433261051297662384	TH	t	2025-01-30 08:06:03.395	2025-02-04 10:15:03.98	65535
1434726813031991023	1433261051297662384	ID	t	2025-01-30 08:06:04.08	2025-02-04 10:15:04.853	131070
1434726824817985264	1433261051297662384	EN	t	2025-01-30 08:06:05.485	2025-02-04 10:15:05.521	196605
1434726976978945777	1433261051297662384	Wisuwat to upload files to Final Drive	t	2025-01-30 08:06:23.622	2025-02-04 10:15:06.863	262140
1433320871686047235	1433320514390066684	VN	t	2025-01-28 09:32:42.811	2025-02-04 10:25:07.24	262140
1438218413976586091	1438218124980651878	Redux core	t	2025-02-04 03:43:15.345	2025-02-06 04:59:55.987	65535
1438218462102030190	1438218124980651878	Redux thrunk	t	2025-02-04 03:43:21.085	2025-02-07 03:35:27.97	131070
1438432076662573018	1438322455239198641	Upload editing file to Final Drive	f	2025-02-04 10:47:45.922	\N	262140
1438432123982710747	1438322380127602607	EN	f	2025-02-04 10:47:51.567	\N	65535
1438432133562501084	1438322380127602607	TH	f	2025-02-04 10:47:52.708	\N	131070
1438432140315330525	1438322380127602607	ID	f	2025-02-04 10:47:53.512	\N	196605
1438432150708815838	1438322380127602607	VN	f	2025-02-04 10:47:54.752	\N	262140
1438432233445656543	1438322380127602607	Upload editing files to Final Drive	f	2025-02-04 10:48:04.615	\N	327675
1438432270120650720	1438431374158596053	EN	f	2025-02-04 10:48:08.987	\N	65535
1438432276621821921	1438431374158596053	TH	f	2025-02-04 10:48:09.762	\N	131070
1438432282594510818	1438431374158596053	ID	f	2025-02-04 10:48:10.475	\N	196605
1433327639673701923	1433316650974709223	Peerapat to upload editing files to Final Drive	t	2025-01-28 09:46:09.616	2025-02-11 03:03:47.877	65535
1438220290004879259	1438219109073422219	Custom Card UI	t	2025-02-04 03:46:58.986	2025-02-11 05:55:44.561	131070
1438220349371058076	1438219109073422219	Custom Card API	t	2025-02-04 03:47:06.065	2025-02-11 05:55:45.146	196605
1438222038534719393	1438221738298050461	Implement GPT-3o-mini / DeepSeek @[Game](1430480385812202497)	t	2025-02-04 03:50:27.425	2025-02-11 05:58:52.424	131070
1438222256269428643	1438221738298050461	Stable test @[Sharp](1430525186381186093) @[Wisuwat](1430534043199341650)	f	2025-02-04 03:50:53.385	2025-02-11 05:58:33.064	262140
1438222488768087973	1438221738298050461	Release to Dev site @[Game](1430480385812202497)	t	2025-02-04 03:51:21.102	2025-02-11 05:58:55.833	163837.5
1438222454760671140	1438221738298050461	Release to Prod site @[Game](1430480385812202497)	t	2025-02-04 03:51:17.045	2025-02-11 05:58:58.354	180221.25
1438219813297063829	1438219017729869704	Improve/adjust ReAct Agent instruction	t	2025-02-04 03:46:02.157	2025-02-12 03:26:13.79	196605
1438432288944687075	1438431374158596053	VN	f	2025-02-04 10:48:11.231	\N	262140
1438432356019996644	1438431374158596053	Upload editing file to Final Drive	f	2025-02-04 10:48:19.228	\N	327675
1438935643257308244	1438218418741315436	FB - TH	t	2025-02-05 03:28:15.739	2025-02-05 03:28:40.279	65535
1438935672793597013	1438218418741315436	FB - ID	t	2025-02-05 03:28:19.262	2025-02-05 03:28:40.85	131070
1438935826800051290	1438218418741315436	IG - ID	t	2025-02-05 03:28:37.621	2025-02-05 03:28:43.695	458745
1438946113817150601	1438944089067226234	Truck Recap (Contract)	t	2025-02-05 03:49:03.927	2025-02-10 04:22:10.315	196605
1438951146075980985	1438948922079839401	Reshoot shot	f	2025-02-05 03:59:03.819	\N	65535
1438981385514648792	1438979442184553672	Upload all the photos in the drive @LC	f	2025-02-05 04:59:08.643	\N	65535
1438983759876588764	1438979442184553672	Select Factory photos	f	2025-02-05 05:03:51.687	\N	196605
1438981535888835801	1438979442184553672	Select Rare Morelia photos	f	2025-02-05 04:59:26.567	2025-02-05 05:06:19.642	131070
1439000932196025617	1438991493367858438	GFX	f	2025-02-05 05:37:58.789	\N	131070
1439003675606385946	1434710292574504669	B-roll shot	f	2025-02-05 05:43:25.825	2025-02-05 05:43:33.639	196605
1439005820581840163	1438948712406582432	@PIN >> Fill in the info and correct all the info -- 06/02/2025 -- 10:00 am	f	2025-02-05 05:47:41.527	\N	65535
1439006439862437157	1438948712406582432	@SHARP >> data of the SNS -- 07/02/2025 -- 10:00 am	f	2025-02-05 05:48:55.352	2025-02-05 05:49:21.881	196605
1439006023544210724	1438948712406582432	@LOOKCHIN >> QC and help PIN with all the pages -- 07/02/2025 -- 10:00 am	f	2025-02-05 05:48:05.723	2025-02-05 05:49:26.404	131070
1439008831077090598	1438949933292979375	Shot list and storyboard	f	2025-02-05 05:53:40.407	\N	65535
1439000861899490576	1438991493367858438	Select the photo	f	2025-02-05 05:37:50.405	2025-02-05 05:53:49.11	65535
1439022600096318828	1439009557144667431	Off the pitch	f	2025-02-05 06:21:01.802	\N	131070
1439022694241666413	1439009557144667431	Tech video	f	2025-02-05 06:21:13.025	\N	196605
1439022488787879275	1439009557144667431	Beauty action shot	f	2025-02-05 06:20:48.533	2025-02-05 06:22:03.376	65535
1439025986946467184	1439009557144667431	Factory	f	2025-02-05 06:27:45.545	\N	262140
1439026302483957105	1439009557144667431	Contact Locatin (pitch)	f	2025-02-05 06:28:23.16	\N	327675
1439026644051297650	1439009557144667431	Contact Model	f	2025-02-05 06:29:03.879	\N	393210
1439026771281315187	1439009557144667431	Prop set up	f	2025-02-05 06:29:19.045	2025-02-05 06:29:23.732	458745
1439026963145557364	1439009814079341866	Beauty action shot	f	2025-02-05 06:29:41.918	2025-02-05 06:30:00.898	65535
1439027184881632629	1439009814079341866	Off the pitch	f	2025-02-05 06:30:08.352	\N	131070
1439027281895884150	1439009814079341866	Factory	f	2025-02-05 06:30:19.916	\N	196605
1439027351110288759	1439009814079341866	Promo video	f	2025-02-05 06:30:28.17	\N	262140
1439027405518800248	1439009814079341866	Contact Locatin (pitch)	f	2025-02-05 06:30:34.655	\N	327675
1439027450313966969	1439009814079341866	Contact Model	f	2025-02-05 06:30:39.995	\N	393210
1439027469481936250	1439009814079341866	Prop set up	f	2025-02-05 06:30:42.28	\N	458745
1439027789113066875	1439009814079341866	Shotlist and storyboard	f	2025-02-05 06:31:20.381	\N	524280
1439029054677190012	1439009557144667431	3D Rendering	f	2025-02-05 06:33:51.228	\N	524280
1439063455729452477	1439063386858980795	Next Match	f	2025-02-05 07:42:12.173	\N	65535
1439063479259497918	1439063386858980795	Matchday	f	2025-02-05 07:42:14.98	\N	131070
1439063519348655551	1439063386858980795	Line-ups	f	2025-02-05 07:42:19.759	\N	196605
1439071454023910858	1439063386858980795	Jaroensak's Substitution (In/Out)	f	2025-02-05 07:58:05.644	\N	458745
1439071349468300745	1439063386858980795	Jaroensak's Starting XI	f	2025-02-05 07:57:53.18	2025-02-05 07:58:08.702	393210
1438431942428067801	1438322455239198641	DEBUT 2/11	f	2025-02-04 10:47:29.923	2025-02-05 08:42:17.136	32767.5
1438431922538678232	1438322455239198641	ASSIST 2/11	f	2025-02-04 10:47:27.55	2025-02-05 08:42:21.546	49151.25
1439063539523257792	1439063386858980795	Half-time	f	2025-02-05 07:42:22.164	2025-02-05 08:25:57.46	262140
1439085493726741983	1439063386858980795	Full-time	f	2025-02-05 08:25:59.307	2025-02-05 08:26:01.467	327675
1439085776808707552	1439063386858980795	Jaroensak is in substitution list	f	2025-02-05 08:26:33.053	2025-02-05 08:26:47.47	425977.5
1438431897146361815	1438322455239198641	GOAL 2/12	f	2025-02-04 10:47:24.523	2025-02-05 08:42:32.25	65535
1439094470954976750	1439094361030657516	2D Motion Osaka is Pink	f	2025-02-05 08:43:49.476	\N	65535
1438935755933090904	1438218418741315436	FB - EN	t	2025-02-05 03:28:29.173	2025-02-05 09:15:53.205	327675
1438935786635396185	1438218418741315436	IG - TH	t	2025-02-05 03:28:32.833	2025-02-05 09:15:54.003	393210
1439187826372511235	1439186484346226172	เสื้อ Jersey	f	2025-02-05 11:49:18.309	\N	196605
1439187922195580420	1439186484346226172	Heat flex	f	2025-02-05 11:49:29.731	\N	262140
1438978554644661444	1438938542184072287	Origin Black Flap-Tongue	t	2025-02-05 04:53:31.175	2025-02-05 13:00:43.737	65535
1438978602770105541	1438938542184072287	Proto UL	t	2025-02-05 04:53:36.914	2025-02-05 13:00:45.877	131070
1438978896723707078	1438938542184072287	Ruby Red Morelia II Short Tongue	t	2025-02-05 04:54:11.954	2025-02-05 13:00:47.084	196605
1438979115741873351	1438938542184072287	Origin White Cross-Stitch	t	2025-02-05 04:54:38.064	2025-02-05 13:00:47.65	262140
1439187544917935617	1439186484346226172	เสื้อยทดคอกลมเปล่า	t	2025-02-05 11:48:44.756	2025-02-06 04:03:35.839	65535
1439187615935890946	1439186484346226172	ส่งสกรีน	t	2025-02-05 11:48:53.225	2025-02-06 04:03:36.561	131070
1439679142537725478	1438959873944454336	Heat	f	2025-02-06 04:05:27.762	\N	131070
1439679079883212325	1438959873944454336	Flex	t	2025-02-06 04:05:20.29	2025-02-06 04:05:31.106	65535
1439679670726428199	1439188311150167557	propose	f	2025-02-06 04:06:30.724	\N	65535
1439820639748753076	1439819756243781290	test task 1	t	2025-02-06 08:46:35.542	2025-02-06 08:47:06.657	65535
1439705052129265220	1433316010454156773	Wisuwat uploaded final and psd in drive	f	2025-02-06 04:56:56.424	\N	262140
1439704835602515521	1433316010454156773	TH	t	2025-02-06 04:56:30.612	2025-02-06 04:56:58.808	65535
1439704857505171010	1433316010454156773	ID	t	2025-02-06 04:56:33.226	2025-02-06 04:56:59.612	131070
1439704877964985923	1433316010454156773	EN	t	2025-02-06 04:56:35.664	2025-02-06 04:57:00.344	196605
1439695370643834432	1438943393743897719	review structure	t	2025-02-06 04:37:42.301	2025-02-06 06:27:39.727	65535
1439821727205951164	1439819756243781290	task 3	f	2025-02-06 08:48:45.178	\N	196605
1439820673731004085	1439819756243781290	test task 2 @game	t	2025-02-06 08:46:39.595	2025-02-06 08:47:31.78	131070
1439821804817352381	1439819756243781290	hey	f	2025-02-06 08:48:54.431	\N	262140
1439823643776386760	1439823527275398849	UI	t	2025-02-06 08:52:33.652	2025-02-06 08:53:10.544	65535
1438935698102027350	1438218418741315436	FB - VN	t	2025-02-05 03:28:22.279	2025-02-06 09:13:56.218	196605
1438935724568085591	1438218418741315436	FB - MM	t	2025-02-05 03:28:25.434	2025-02-06 09:14:00.931	262140
1439834860385470160	1433316010454156773	VN	t	2025-02-06 09:14:50.774	2025-02-07 03:40:09.792	229372.5
1440419355488683837	1440419188186285877	ID	t	2025-02-07 04:36:08.022	2025-02-07 04:36:22.457	196605
1440419327948883772	1440419188186285877	TH	t	2025-02-07 04:36:04.74	2025-02-07 04:36:23.039	131070
1439858673940694767	1439857429213873898	First Draft	t	2025-02-06 10:02:09.571	2025-02-10 03:32:12.136	65535
1438946579963708554	1438944089067226234	IG INTL	t	2025-02-05 03:49:59.496	2025-02-10 04:22:08.639	32767.5
1438944946575901821	1438944089067226234	QC Process	t	2025-02-05 03:46:44.782	2025-02-10 04:22:09.114	65535
1438945206580806784	1438944089067226234	2D Source (matchday, training, activities)	t	2025-02-05 03:47:15.776	2025-02-10 04:22:09.804	131070
1440419316750092091	1440419188186285877	EN	t	2025-02-07 04:36:03.404	2025-02-07 04:36:21.43	65535
1440419370604955454	1440419188186285877	VN	t	2025-02-07 04:36:09.824	2025-02-07 04:36:23.834	262140
1440419459104769855	1440419188186285877	Upload psd file	t	2025-02-07 04:36:20.372	2025-02-07 04:46:42.782	327675
1434726574820689645	1434109361990403733	Bam to upload all files to Final Drive	t	2025-01-30 08:05:35.683	2025-02-07 05:07:52.326	196605
1439678419531990563	1439186484346226172	ได้เสื้อที่สกรีนแล้วคืน	t	2025-02-06 04:04:01.57	2025-02-07 09:46:43.776	327675
1433313424036595162	1433303096687068625	Phyo to upload PSD files to Final Drive	t	2025-01-28 09:17:54.98	2025-02-10 03:27:53.007	327675
1442640131050702733	1442639409261315978	Cherry Blossom “Bloom” Jersey	f	2025-02-10 06:08:25.097	\N	65535
1442640200994916238	1442639409261315978	Sakura Press-Work Tee	f	2025-02-10 06:08:33.437	\N	131070
1442640262567298959	1442639409261315978	“Day Wolf” Crew Tee	f	2025-02-10 06:08:40.777	\N	196605
1442640354967816080	1442639409261315978	“Night Wolf” Jersey	f	2025-02-10 06:08:51.79	\N	262140
1439750701935756878	1438943393743897719	review draft 1	t	2025-02-06 06:27:38.305	2025-02-11 03:21:39.969	131070
1439823670343108297	1439823527275398849	API	t	2025-02-06 08:52:36.819	2025-02-12 03:25:51.15	131070
1439823707462698698	1439823527275398849	Send Email	t	2025-02-06 08:52:41.244	2025-02-12 03:25:52.548	196605
1439823768917640907	1439823527275398849	Send in-app notification	t	2025-02-06 08:52:48.571	2025-02-12 03:25:54.239	262140
1442640782912653201	1442639409261315978	“Pink Collar” Workwear Shirt	f	2025-02-10 06:09:42.804	\N	327675
1442652002046707623	1442640975624144786	@sharp AI tool translate for all 4 articals	f	2025-02-10 06:32:00.232	2025-02-10 06:32:16.81	65535
1442652307182323624	1442640975624144786	@TS check the overall after Sahrp finish	f	2025-02-10 06:32:36.604	\N	131070
1442652459653662633	1442640975624144786	@Zack check the language	f	2025-02-10 06:32:54.781	\N	196605
1442652784468953002	1442640975624144786	@Golf helps correct the Ai	f	2025-02-10 06:33:33.502	2025-02-10 06:33:35.964	98302.5
1442899437755041719	1432128251324531818	Test @[Sharp](1430525186381186093)	f	2025-02-10 14:43:36.865	\N	65535
1433234534287017352	1433232704547063170	Peerapat to upload editing files to Final Drive	t	2025-01-28 06:41:10.588	2025-02-11 02:58:23.578	65535
1437712022450997058	1437711172743726910	Peerapat to upload editing files to Final Drive	t	2025-02-03 10:57:08.771	2025-02-11 03:03:40.945	65535
1443272815812806596	1443272709252319169	Upload working file	f	2025-02-11 03:05:27	\N	65535
1439675289943672346	1438952821910144186	Review draft 1	t	2025-02-06 03:57:48.495	2025-02-11 03:21:28.71	65535
1443314315783309292	1443313947582138341	Equipment List	f	2025-02-11 04:27:54.181	\N	65535
1443314341486004207	1443313947582138341	Shot list	f	2025-02-11 04:27:57.246	\N	131070
1443314381331892210	1443313947582138341	References	f	2025-02-11 04:28:01.996	\N	196605
1438222192163686306	1438221738298050461	Accuracy test @[Wisuwat](1430534043199341650)  @[Sharp](1430525186381186093)	f	2025-02-04 03:50:45.739	2025-02-11 05:58:28.607	196605
1438221850797672352	1438221738298050461	Implement Turfmapp ReAct Agent @[Game](1430480385812202497)	t	2025-02-04 03:50:05.046	2025-02-11 05:58:45.776	65535
1443283529868773337	1443283231083333589	@[Chaowalit](1430524402960696364) Research Cookie Plugin	t	2025-02-11 03:26:44.213	2025-02-11 06:21:38.167	65535
1443283765907425245	1443283231083333589	@[Chaowalit](1430524402960696364) Test the Plugin After Implement	t	2025-02-11 03:27:12.353	2025-02-11 06:21:46.187	196605
1443283591734757339	1443283231083333589	@[Chaowalit](1430524402960696364) Implement Cookie Plugin	t	2025-02-11 03:26:51.59	2025-02-11 06:21:52.755	131070
1443392137554035757	1443392055991600171	Posting in Urawa REDS page	f	2025-02-11 07:02:31.259	\N	65535
1443392172148655151	1443392055991600171	Need QC	f	2025-02-11 07:02:35.384	2025-02-11 07:08:01.441	32767.5
1443396957102933056	1443396872721925182	posting on Wednesday 12th in Urawa Reds TH page	f	2025-02-11 07:12:05.795	\N	65535
1443397543827342412	1443397437266854982	posted in Urawa Reds TH page on 7 FEB	t	2025-02-11 07:13:15.738	2025-02-11 07:13:16.413	65535
1444008646907266213	1444008228986815648	Implement into ReAct Agent	f	2025-02-12 03:27:24.9	\N	131070
1444008360125924515	1444008228986815648	Create a Planka tool	f	2025-02-12 03:26:50.714	2025-02-12 03:27:29.482	65535
1444008812968150183	1444008228986815648	Testing	f	2025-02-12 03:27:44.696	\N	196605
1692573968071918819	1692563975067141338	Slide 2	f	2026-01-21 02:22:20.243	\N	65535
1692573989278319844	1692563975067141338	Slide 3	f	2026-01-21 02:22:22.768	\N	131070
1692574011927561445	1692563975067141338	Slide 4	f	2026-01-21 02:22:25.473	\N	196605
1692574029837239526	1692563975067141338	Slide 5	f	2026-01-21 02:22:27.608	\N	262140
1692574048585778407	1692563975067141338	Slide 6	f	2026-01-21 02:22:29.843	\N	327675
1692574068508722408	1692563975067141338	Slide 7	f	2026-01-21 02:22:32.218	\N	393210
1692574086191908073	1692563975067141338	Slide 8	f	2026-01-21 02:22:34.325	\N	458745
\.


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project_management_tool.user_account (id, email, password, is_admin, name, username, phone, organization, subscribe_to_own_cards, created_at, updated_at, deleted_at, language, password_changed_at, avatar, is_sso) FROM stdin;
1433297069220562376	trisikh@turfmapp.com	$2b$10$Faa0XpKZJvKO0ciUGCpnrO2ISYqKmGJ9U.l6CeGkOSJME/kLE8qh.	t	Trisikh	\N	\N	\N	f	2025-01-28 08:45:25.332	2025-01-28 08:45:28.391	\N	\N	\N	\N	f
1430525186381186093	apiwat@turfmapp.com	$2b$10$/9iTfl4oMjTHCVcbcEVEuOtD4bHh1GatVZpB4.JKOhB5p8v/o4HaO	t	Sharp	\N	\N	\N	f	2025-01-24 12:58:11.148	2025-01-30 07:29:37.919	\N	en-US	2025-01-30 07:29:37	\N	f
1435352068222093091	bam@turfmapp.com	$2b$10$V1.c46PiLBBm4QXZoHGJnORf.W3qn9GT51.ANaDHL4n7KTXWgGtxm	f	Bam	\N	\N	\N	f	2025-01-31 04:48:20.304	\N	\N	\N	\N	\N	f
1430501158790628357	sira@turfmapp.com	$2b$10$wF9.Hqo9V5/KFAjBThFFyels2tWyClQIbdUZXI6s6apfQDWU/rExW	t	Sira (Tu)	\N	\N	\N	t	2025-01-24 12:10:26.837	2025-01-25 02:57:25.741	\N	\N	2025-01-25 02:57:09	\N	f
1433172478670144855	chanyanut@turfmapp.com	$2b$10$V6Ahzn3Bu060ffV5VeK7.O66ZV6QA82coHJMpNvLFKE/aBa9wbifO	t	Lookchin	\N	\N	\N	f	2025-01-28 04:37:52.983	2025-01-28 04:48:59.24	\N	\N	\N	\N	f
1433171377464018261	pattarawadee@turfmapp.com	$2b$10$Ts8g3SWbIc8LUA9jJSZWyeAmYpsw.Q5saK119TXhH3.SEJlraViPi	t	Pin	\N	\N	\N	f	2025-01-28 04:35:41.708	2025-01-28 04:49:11.932	\N	\N	\N	\N	f
1432141375276582075	tri@turfmapp.com	$2b$10$sHz/4GIVUP/YzTRYwQ.ABO2Pf/qF1AefFTIisY54.oJ7re0DtrTAe	t	Tri	\N	\N	\N	f	2025-01-26 18:29:15.879	2025-01-28 07:34:38.145	\N	\N	\N	\N	f
1433261799410501042	phyopyae@turfmapp.com	$2b$10$YEgWGOckQmJ7bN4c5L930exQvUNWbUMZ.z76G3.sMiEMwSGMpLRle	f	Phyo	\N	\N	\N	f	2025-01-28 07:35:20.843	\N	\N	\N	\N	\N	f
1430534043199341650	wisuwat@turfmapp.com	$2b$10$2qbhWeXitOkj86skOadTC.JJe6KOmMID3PiCee63LFGV9qjW9nBPy	t	Wisuwat	\N	\N	\N	f	2025-01-24 13:15:46.964	2025-01-28 08:22:16.343	\N	\N	2025-01-28 08:22:16	\N	f
1440527451150092120	natthawut@turfmapp.com	$2b$10$PozMgG6FjP4vVOrpWf/ZlunHE/PAJ0SEWqm25XfUoHOANbWAGDFO.	f	Natthawut	\N	\N	\N	f	2025-02-07 08:10:54.026	\N	\N	\N	\N	\N	f
1433330078485317156	peerapat@turfmapp.com	$2b$10$jKA/ojY3mOhIjV9VoeC.oOEkYW6CceP/I7W7OsQWtAQ9s4oYivram	f	Peerapat	\N	\N	\N	f	2025-01-28 09:51:00.344	2025-02-11 04:29:37.602	2025-02-11 04:29:37.601	\N	\N	\N	f
1692047903306024107	admin@turfmapp.com	$2b$10$p5OPBbyZGrcXphbIxVmIB.TxD/eSh7lrhpQvnlqUfap9zlawWMIpS	t	Admin User	admin	\N	\N	f	2026-01-20 08:57:08.431	\N	\N	\N	\N	\N	f
1430480385812202497	gamekitisak@turfmapp.com	$2b$10$3aXTeevMAStbPR5m8nvw/u76YThyDhY5dvJm9QjBSm0kdG5BJVI8u	f	Game	game	0610232488	Turfmapp	t	2025-01-24 11:29:10.507	2026-01-20 11:00:41.295	2026-01-20 11:00:41.29	en-US	\N	\N	f
1434714317982271199	phonpiboonsrimak@turfmapp.com	$2b$10$Xb7raPpquEPfVTnJsdhAVuUVdy.t/0gQjSsFgLKBGN0D5PlEu2HBe	f	Juno	\N	\N	\N	f	2025-01-30 07:41:14.551	2026-01-20 11:00:47.79	2026-01-20 11:00:47.789	\N	\N	\N	f
1433172244418266454	gate@groundwrk.io	$2b$10$zCGKxOFg6oVBmam8J7uI/.ao4gpEHMIDlatciXLblGbgQ4G3Uvpmm	t	Gate	\N	\N	\N	f	2025-01-28 04:37:25.057	2026-01-20 12:08:38.842	\N	\N	2026-01-20 12:08:38	\N	f
1443315729842571257	pakanaphat.h@ladderice.co	$2b$10$ilhnat9mzZt3hxUoT764x.gSZxtl0wsAjq/2RLE.Yg/31iLliHZrO	f	Jasmine	\N	\N	\N	f	2025-02-11 04:30:42.749	2026-01-21 03:23:34.167	2026-01-21 03:23:34.163	\N	\N	\N	f
1443315445871413240	natouchchawat@turfmapp.com	$2b$10$XXWTsf4Fn5rX12BRhDLkpuHlq9TOFgggWT63uoZeiUwrgVt0lYGHy	f	Arm	\N	\N	\N	f	2025-02-11 04:30:08.896	2026-01-21 03:23:45.752	2026-01-21 03:23:45.751	\N	\N	\N	f
1430524402960696364	chaowalit@turfmapp.com	$2b$10$KhUCarlG3xTH0IG7/NYYvunlP3jJTVmRbTOj5KFfQ975Szg4WZbTu	f	Chaowalit	\N	0654169146	Turfmapp	f	2025-01-24 12:56:37.758	2026-01-21 03:24:04.135	2026-01-21 03:24:04.134	\N	\N	{"dirname": "ddc1b5ba-d80b-43aa-99ed-a29980d54c63", "extension": "jpg"}	f
1433172877045138776	chanchira@turfmapp.com	$2b$10$LHeFTaMHueP.ybCqNXz.NuJ1tAeNhJanQSf5CCJIzbLZuiMJJak.G	f	Fuse	\N	\N	\N	f	2025-01-28 04:38:40.472	2026-01-21 03:24:08.644	2026-01-21 03:24:08.642	\N	\N	\N	f
1434720470833301219	rattapoom@groundwrk.io	$2b$10$IVyEeOeyrrw.VswfLbBpbeMJyBQZsRZiPHny3y6YEw9cGexSL.qiy	f	rattapoom	\N	\N	\N	f	2025-01-30 07:53:28.028	2026-01-21 03:24:17.525	2026-01-21 03:24:17.523	\N	\N	\N	f
1439748730579322441	thanavich@turfmapp.com	$2b$10$p.t5U9fQvRP8mMMUarr/ieCjiM/lb0b9i5.9yT882W4kYHjXiDxfK	f	Bank	\N	\N	\N	f	2025-02-06 06:23:43.3	2026-01-21 03:24:26.74	2026-01-21 03:24:26.737	\N	\N	\N	f
\.


--
-- Name: migration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_management_tool.migration_id_seq', 35, true);


--
-- Name: migration_lock_index_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_management_tool.migration_lock_index_seq', 1, true);


--
-- Name: next_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_management_tool.next_id_seq', 2286, true);


--
-- Name: action action_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.action
    ADD CONSTRAINT action_pkey PRIMARY KEY (id);


--
-- Name: archive archive_from_model_original_record_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.archive
    ADD CONSTRAINT archive_from_model_original_record_id_unique UNIQUE (from_model, original_record_id);


--
-- Name: archive archive_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.archive
    ADD CONSTRAINT archive_pkey PRIMARY KEY (id);


--
-- Name: attachment attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.attachment
    ADD CONSTRAINT attachment_pkey PRIMARY KEY (id);


--
-- Name: board_membership board_membership_board_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.board_membership
    ADD CONSTRAINT board_membership_board_id_user_id_unique UNIQUE (board_id, user_id);


--
-- Name: board_membership board_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.board_membership
    ADD CONSTRAINT board_membership_pkey PRIMARY KEY (id);


--
-- Name: board board_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.board
    ADD CONSTRAINT board_pkey PRIMARY KEY (id);


--
-- Name: card_label card_label_card_id_label_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_label
    ADD CONSTRAINT card_label_card_id_label_id_unique UNIQUE (card_id, label_id);


--
-- Name: card_label card_label_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_label
    ADD CONSTRAINT card_label_pkey PRIMARY KEY (id);


--
-- Name: card_membership card_membership_card_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_membership
    ADD CONSTRAINT card_membership_card_id_user_id_unique UNIQUE (card_id, user_id);


--
-- Name: card_membership card_membership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_membership
    ADD CONSTRAINT card_membership_pkey PRIMARY KEY (id);


--
-- Name: card card_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card
    ADD CONSTRAINT card_pkey PRIMARY KEY (id);


--
-- Name: card_subscription card_subscription_card_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_subscription
    ADD CONSTRAINT card_subscription_card_id_user_id_unique UNIQUE (card_id, user_id);


--
-- Name: card_subscription card_subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.card_subscription
    ADD CONSTRAINT card_subscription_pkey PRIMARY KEY (id);


--
-- Name: identity_provider_user identity_provider_user_issuer_sub_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.identity_provider_user
    ADD CONSTRAINT identity_provider_user_issuer_sub_unique UNIQUE (issuer, sub);


--
-- Name: identity_provider_user identity_provider_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.identity_provider_user
    ADD CONSTRAINT identity_provider_user_pkey PRIMARY KEY (id);


--
-- Name: label label_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.label
    ADD CONSTRAINT label_pkey PRIMARY KEY (id);


--
-- Name: list list_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.list
    ADD CONSTRAINT list_pkey PRIMARY KEY (id);


--
-- Name: migration_lock migration_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration_lock
    ADD CONSTRAINT migration_lock_pkey PRIMARY KEY (index);


--
-- Name: migration migration_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.migration
    ADD CONSTRAINT migration_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: project_manager project_manager_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.project_manager
    ADD CONSTRAINT project_manager_pkey PRIMARY KEY (id);


--
-- Name: project_manager project_manager_project_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.project_manager
    ADD CONSTRAINT project_manager_project_id_user_id_unique UNIQUE (project_id, user_id);


--
-- Name: project project_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (id);


--
-- Name: session session_access_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.session
    ADD CONSTRAINT session_access_token_unique UNIQUE (access_token);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: user_account user_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.user_account
    ADD CONSTRAINT user_email_unique EXCLUDE USING btree (email WITH =) WHERE ((deleted_at IS NULL));


--
-- Name: user_account user_username_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_management_tool.user_account
    ADD CONSTRAINT user_username_unique EXCLUDE USING btree (username WITH =) WHERE (((username IS NOT NULL) AND (deleted_at IS NULL)));


--
-- Name: action_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX action_card_id_index ON project_management_tool.action USING btree (card_id);


--
-- Name: action_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX action_type_index ON project_management_tool.action USING btree (type);


--
-- Name: attachment_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX attachment_card_id_index ON project_management_tool.attachment USING btree (card_id);


--
-- Name: board_membership_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_membership_user_id_index ON project_management_tool.board_membership USING btree (user_id);


--
-- Name: board_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_position_index ON project_management_tool.board USING btree ("position");


--
-- Name: board_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX board_project_id_index ON project_management_tool.board USING btree (project_id);


--
-- Name: card_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_board_id_index ON project_management_tool.card USING btree (board_id);


--
-- Name: card_label_label_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_label_label_id_index ON project_management_tool.card_label USING btree (label_id);


--
-- Name: card_list_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_list_id_index ON project_management_tool.card USING btree (list_id);


--
-- Name: card_membership_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_membership_user_id_index ON project_management_tool.card_membership USING btree (user_id);


--
-- Name: card_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_position_index ON project_management_tool.card USING btree ("position");


--
-- Name: card_subscription_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX card_subscription_user_id_index ON project_management_tool.card_subscription USING btree (user_id);


--
-- Name: identity_provider_user_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX identity_provider_user_user_id_index ON project_management_tool.identity_provider_user USING btree (user_id);


--
-- Name: label_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX label_board_id_index ON project_management_tool.label USING btree (board_id);


--
-- Name: label_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX label_position_index ON project_management_tool.label USING btree ("position");


--
-- Name: list_board_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX list_board_id_index ON project_management_tool.list USING btree (board_id);


--
-- Name: list_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX list_position_index ON project_management_tool.list USING btree ("position");


--
-- Name: notification_action_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_action_id_index ON project_management_tool.notification USING btree (action_id);


--
-- Name: notification_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_card_id_index ON project_management_tool.notification USING btree (card_id);


--
-- Name: notification_is_read_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_is_read_index ON project_management_tool.notification USING btree (is_read);


--
-- Name: notification_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notification_user_id_index ON project_management_tool.notification USING btree (user_id);


--
-- Name: project_manager_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX project_manager_user_id_index ON project_management_tool.project_manager USING btree (user_id);


--
-- Name: session_remote_address_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX session_remote_address_index ON project_management_tool.session USING btree (remote_address);


--
-- Name: session_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX session_user_id_index ON project_management_tool.session USING btree (user_id);


--
-- Name: task_card_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_card_id_index ON project_management_tool.task USING btree (card_id);


--
-- Name: task_position_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_position_index ON project_management_tool.task USING btree ("position");


--
-- Name: SCHEMA project_management_tool; Type: ACL; Schema: -; Owner: pg_database_owner
--

REVOKE USAGE ON SCHEMA project_management_tool FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict q3plIBKbVECEjJcZJEQYk7NEsSo6azaKQltxaFcFn6kLhrKF11y9m72hwQ7NR2b

