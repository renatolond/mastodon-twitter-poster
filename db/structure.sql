SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
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

SET search_path = public, pg_catalog;

--
-- Name: boost_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE boost_options AS ENUM (
    'MASTO_BOOST_DO_NOT_POST',
    'MASTO_BOOST_POST_AS_LINK'
);


--
-- Name: masto_mention_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE masto_mention_options AS ENUM (
    'MASTO_MENTION_DO_NOT_POST'
);


--
-- Name: masto_reply_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE masto_reply_options AS ENUM (
    'MASTO_REPLY_DO_NOT_POST',
    'MASTO_REPLY_POST_SELF'
);


--
-- Name: masto_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE masto_visibility AS ENUM (
    'MASTO_PUBLIC',
    'MASTO_UNLISTED',
    'MASTO_PRIVATE'
);


--
-- Name: quote_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE quote_options AS ENUM (
    'QUOTE_DO_NOT_POST',
    'QUOTE_POST_AS_LINK',
    'QUOTE_POST_AS_OLD_RT',
    'QUOTE_POST_AS_OLD_RT_WITH_LINK'
);


--
-- Name: retweet_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE retweet_options AS ENUM (
    'RETWEET_DO_NOT_POST',
    'RETWEET_POST_AS_LINK',
    'RETWEET_POST_AS_OLD_RT',
    'RETWEET_POST_AS_OLD_RT_WITH_LINK'
);


--
-- Name: twitter_reply_options; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE twitter_reply_options AS ENUM (
    'TWITTER_REPLY_DO_NOT_POST',
    'TWITTER_REPLY_POST_SELF'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE authorizations (
    id bigint NOT NULL,
    provider character varying,
    uid character varying,
    user_id integer,
    token character varying,
    secret character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    mastodon_client_id bigint
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;


--
-- Name: mastodon_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mastodon_clients (
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

CREATE SEQUENCE mastodon_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mastodon_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mastodon_clients_id_seq OWNED BY mastodon_clients.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE statuses (
    id bigint NOT NULL,
    mastodon_client_id bigint NOT NULL,
    masto_id bigint NOT NULL,
    tweet_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE statuses_id_seq OWNED BY statuses.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_toot bigint,
    last_tweet bigint,
    twitter_last_check timestamp without time zone DEFAULT now(),
    mastodon_last_check timestamp without time zone DEFAULT now(),
    boost_options boost_options DEFAULT 'MASTO_BOOST_DO_NOT_POST'::boost_options,
    masto_reply_options masto_reply_options DEFAULT 'MASTO_REPLY_POST_SELF'::masto_reply_options,
    masto_mention_options masto_mention_options DEFAULT 'MASTO_MENTION_DO_NOT_POST'::masto_mention_options,
    masto_should_post_private boolean DEFAULT false,
    masto_should_post_unlisted boolean DEFAULT false,
    posting_from_mastodon boolean DEFAULT false,
    posting_from_twitter boolean DEFAULT false,
    masto_fix_cross_mention boolean DEFAULT false,
    retweet_options retweet_options DEFAULT 'RETWEET_POST_AS_OLD_RT_WITH_LINK'::retweet_options,
    quote_options quote_options DEFAULT 'QUOTE_POST_AS_OLD_RT_WITH_LINK'::quote_options,
    twitter_reply_options twitter_reply_options DEFAULT 'TWITTER_REPLY_POST_SELF'::twitter_reply_options,
    twitter_content_warning character varying,
    locked boolean DEFAULT false NOT NULL,
    twitter_original_visibility masto_visibility,
    twitter_retweet_visibility masto_visibility DEFAULT 'MASTO_UNLISTED'::masto_visibility,
    twitter_quote_visibility masto_visibility DEFAULT 'MASTO_UNLISTED'::masto_visibility
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: authorizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);


--
-- Name: mastodon_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mastodon_clients ALTER COLUMN id SET DEFAULT nextval('mastodon_clients_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses ALTER COLUMN id SET DEFAULT nextval('statuses_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: authorizations authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: mastodon_clients mastodon_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mastodon_clients
    ADD CONSTRAINT mastodon_clients_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_authorizations_on_mastodon_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authorizations_on_mastodon_client_id ON authorizations USING btree (mastodon_client_id);


--
-- Name: index_authorizations_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_authorizations_on_provider_and_uid ON authorizations USING btree (provider, uid);


--
-- Name: index_mastodon_clients_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mastodon_clients_on_domain ON mastodon_clients USING btree (domain);


--
-- Name: index_statuses_on_mastodon_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_mastodon_client_id ON statuses USING btree (mastodon_client_id);


--
-- Name: index_statuses_on_mastodon_client_id_and_masto_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_statuses_on_mastodon_client_id_and_masto_id ON statuses USING btree (mastodon_client_id, masto_id);


--
-- Name: index_statuses_on_tweet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_statuses_on_tweet_id ON statuses USING btree (tweet_id);


--
-- Name: statuses fk_rails_68a10127d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses
    ADD CONSTRAINT fk_rails_68a10127d4 FOREIGN KEY (mastodon_client_id) REFERENCES mastodon_clients(id);


--
-- Name: authorizations fk_rails_7cfd93d6c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_rails_7cfd93d6c7 FOREIGN KEY (mastodon_client_id) REFERENCES mastodon_clients(id);


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
('20180701100749');


