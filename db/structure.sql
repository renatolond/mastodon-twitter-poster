SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: block_or_allow; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.block_or_allow AS ENUM (
    'BLOCK_WITH_WORDS',
    'ALLOW_WITH_WORDS'
);


--
-- Name: boost_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.boost_options AS ENUM (
    'MASTO_BOOST_DO_NOT_POST',
    'MASTO_BOOST_POST_AS_LINK'
);


--
-- Name: masto_cw_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.masto_cw_options AS ENUM (
    'CW_AND_CONTENT',
    'CW_ONLY',
    'CONTENT_ONLY'
);


--
-- Name: masto_mention_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.masto_mention_options AS ENUM (
    'MASTO_MENTION_DO_NOT_POST'
);


--
-- Name: masto_reply_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.masto_reply_options AS ENUM (
    'MASTO_REPLY_DO_NOT_POST',
    'MASTO_REPLY_POST_SELF'
);


--
-- Name: masto_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.masto_visibility AS ENUM (
    'MASTO_PUBLIC',
    'MASTO_UNLISTED',
    'MASTO_PRIVATE'
);


--
-- Name: quote_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.quote_options AS ENUM (
    'QUOTE_DO_NOT_POST',
    'QUOTE_POST_AS_LINK',
    'QUOTE_POST_AS_OLD_RT',
    'QUOTE_POST_AS_OLD_RT_WITH_LINK'
);


--
-- Name: retweet_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.retweet_options AS ENUM (
    'RETWEET_DO_NOT_POST',
    'RETWEET_POST_AS_LINK',
    'RETWEET_POST_AS_OLD_RT',
    'RETWEET_POST_AS_OLD_RT_WITH_LINK'
);


--
-- Name: twitter_reply_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.twitter_reply_options AS ENUM (
    'TWITTER_REPLY_DO_NOT_POST',
    'TWITTER_REPLY_POST_SELF'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorizations (
    id bigint NOT NULL,
    provider character varying,
    uid character varying,
    user_id integer,
    token character varying,
    secret character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mastodon_client_id bigint,
    mastodon_user_id character varying
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.authorizations_id_seq OWNED BY public.authorizations.id;


--
-- Name: mastodon_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mastodon_clients (
    id integer NOT NULL,
    domain character varying,
    client_id character varying,
    client_secret character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mastodon_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mastodon_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mastodon_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mastodon_clients_id_seq OWNED BY public.mastodon_clients.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statuses (
    id bigint NOT NULL,
    mastodon_client_id bigint NOT NULL,
    masto_id character varying NOT NULL,
    tweet_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statuses_id_seq OWNED BY public.statuses.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_toot character varying,
    last_tweet bigint,
    twitter_last_check timestamp without time zone DEFAULT now(),
    mastodon_last_check timestamp without time zone DEFAULT now(),
    boost_options public.boost_options DEFAULT 'MASTO_BOOST_DO_NOT_POST'::public.boost_options,
    masto_reply_options public.masto_reply_options DEFAULT 'MASTO_REPLY_POST_SELF'::public.masto_reply_options,
    masto_mention_options public.masto_mention_options DEFAULT 'MASTO_MENTION_DO_NOT_POST'::public.masto_mention_options,
    masto_should_post_private boolean DEFAULT false,
    masto_should_post_unlisted boolean DEFAULT false,
    posting_from_mastodon boolean DEFAULT false,
    posting_from_twitter boolean DEFAULT false,
    masto_fix_cross_mention boolean DEFAULT false,
    retweet_options public.retweet_options DEFAULT 'RETWEET_POST_AS_OLD_RT_WITH_LINK'::public.retweet_options,
    quote_options public.quote_options DEFAULT 'QUOTE_POST_AS_OLD_RT_WITH_LINK'::public.quote_options,
    twitter_reply_options public.twitter_reply_options DEFAULT 'TWITTER_REPLY_POST_SELF'::public.twitter_reply_options,
    twitter_content_warning character varying,
    locked boolean DEFAULT false NOT NULL,
    twitter_original_visibility public.masto_visibility,
    twitter_retweet_visibility public.masto_visibility DEFAULT 'MASTO_UNLISTED'::public.masto_visibility,
    twitter_quote_visibility public.masto_visibility DEFAULT 'MASTO_UNLISTED'::public.masto_visibility,
    twitter_word_list character varying[] DEFAULT '{}'::character varying[],
    twitter_block_or_allow_list public.block_or_allow,
    masto_word_list character varying[] DEFAULT '{}'::character varying[],
    masto_block_or_allow_list public.block_or_allow,
    admin boolean DEFAULT false NOT NULL,
    masto_cw_options public.masto_cw_options DEFAULT 'CW_ONLY'::public.masto_cw_options NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: authorizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorizations ALTER COLUMN id SET DEFAULT nextval('public.authorizations_id_seq'::regclass);


--
-- Name: mastodon_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastodon_clients ALTER COLUMN id SET DEFAULT nextval('public.mastodon_clients_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses ALTER COLUMN id SET DEFAULT nextval('public.statuses_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: authorizations authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: mastodon_clients mastodon_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastodon_clients
    ADD CONSTRAINT mastodon_clients_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_authorizations_on_mastodon_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authorizations_on_mastodon_client_id ON public.authorizations USING btree (mastodon_client_id);


--
-- Name: index_authorizations_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_authorizations_on_provider_and_uid ON public.authorizations USING btree (provider, uid);


--
-- Name: index_mastodon_clients_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mastodon_clients_on_domain ON public.mastodon_clients USING btree (domain);


--
-- Name: index_statuses_on_mastodon_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_mastodon_client_id ON public.statuses USING btree (mastodon_client_id);


--
-- Name: index_statuses_on_mastodon_client_id_and_masto_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_statuses_on_mastodon_client_id_and_masto_id ON public.statuses USING btree (mastodon_client_id, masto_id);


--
-- Name: index_statuses_on_tweet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_statuses_on_tweet_id ON public.statuses USING btree (tweet_id);


--
-- Name: statuses fk_rails_68a10127d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT fk_rails_68a10127d4 FOREIGN KEY (mastodon_client_id) REFERENCES public.mastodon_clients(id);


--
-- Name: authorizations fk_rails_7cfd93d6c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorizations
    ADD CONSTRAINT fk_rails_7cfd93d6c7 FOREIGN KEY (mastodon_client_id) REFERENCES public.mastodon_clients(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20170808112347'),
('20170808113938'),
('20170808114609'),
('20170809135336'),
('20170809151828'),
('20170810091710'),
('20170810094031'),
('20170810103418'),
('20170810105204'),
('20170810105214'),
('20170812195419'),
('20170817073406'),
('20171012093059'),
('20171025115156'),
('20171025125328'),
('20171102154204'),
('20171103102943'),
('20171103132222'),
('20171123155339'),
('20171123191320'),
('20180103212954'),
('20180304150232'),
('20180412164151'),
('20180503105007'),
('20180503110516'),
('20180701100749'),
('20180821172252'),
('20190131082017'),
('20190202145018'),
('20190226132236'),
('20200328180158'),
('20210109000000');


