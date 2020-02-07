--
-- PostgreSQL database dump
--

-- Dumped from database version 11.6 (Debian 11.6-1.pgdg100+1)
-- Dumped by pg_dump version 11.6 (Debian 11.6-1.pgdg100+1)

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
-- Name: loss; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA loss;


--
-- Name: SCHEMA loss; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA loss IS 'Schema for Challenge Fund loss database elements';


--
-- Name: component_enum; Type: TYPE; Schema: loss; Owner: -
--

CREATE TYPE loss.component_enum AS ENUM (
    'Buildings',
    'Direct Damage to other Asset',
    'Contents',
    'Business Interruption'
);


--
-- Name: TYPE component_enum; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TYPE loss.component_enum IS 'Types of loss component';


--
-- Name: frequency_enum; Type: TYPE; Schema: loss; Owner: -
--

CREATE TYPE loss.frequency_enum AS ENUM (
    'Rate of Exceedence',
    'Probability of Exceedence',
    'Return Period'
);


--
-- Name: TYPE frequency_enum; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TYPE loss.frequency_enum IS 'Types of loss frequency';


--
-- Name: loss_type_enum; Type: TYPE; Schema: loss; Owner: -
--

CREATE TYPE loss.loss_type_enum AS ENUM (
    'Ground Up',
    'Insured'
);


--
-- Name: TYPE loss_type_enum; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TYPE loss.loss_type_enum IS 'Types of loss';


--
-- Name: metric_enum; Type: TYPE; Schema: loss; Owner: -
--

CREATE TYPE loss.metric_enum AS ENUM (
    'AAL',
    'AALR',
    'PML'
);


--
-- Name: TYPE metric_enum; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TYPE loss.metric_enum IS 'Types of loss metric';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: loss_map; Type: TABLE; Schema: loss; Owner: -
--

CREATE TABLE loss.loss_map (
    id integer NOT NULL,
    loss_model_id integer NOT NULL,
    occupancy cf_common.occupancy_enum NOT NULL,
    component loss.component_enum NOT NULL,
    loss_type loss.loss_type_enum NOT NULL,
    return_period integer,
    units character varying NOT NULL,
    metric loss.metric_enum NOT NULL,
    CONSTRAINT pml_implies_return_period CHECK ((NOT ((metric = 'PML'::loss.metric_enum) AND (return_period IS NULL))))
);


--
-- Name: TABLE loss_map; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TABLE loss.loss_map IS 'Meta-data for a single loss map for a given loss model';


--
-- Name: loss_map_values; Type: TABLE; Schema: loss; Owner: -
--

CREATE TABLE loss.loss_map_values (
    id bigint NOT NULL,
    loss_map_id integer NOT NULL,
    asset_ref character varying,
    the_geom public.geometry(Geometry,4326) NOT NULL,
    loss double precision NOT NULL
);


--
-- Name: TABLE loss_map_values; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TABLE loss.loss_map_values IS 'Loss values for the specified loss map';


--
-- Name: loss_model; Type: TABLE; Schema: loss; Owner: -
--

CREATE TABLE loss.loss_model (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    hazard_type character varying,
    process_type character varying,
    hazard_link character varying,
    exposure_link character varying,
    vulnerability_link character varying
);


--
-- Name: TABLE loss_model; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TABLE loss.loss_model IS 'Loss model meta-data and optional links to hazard, exposure and vulnerability models';


--
-- Name: all_loss_map_values; Type: VIEW; Schema: loss; Owner: -
--

CREATE VIEW loss.all_loss_map_values AS
 SELECT lmv.id AS uid,
    lmv.loss_map_id,
    public.st_astext(lmv.the_geom) AS geom,
    lmv.asset_ref,
    lmv.loss,
    lm.occupancy,
    lm.component,
    lm.loss_type,
    lm.return_period,
    lm.units,
    lm.metric,
    mod.name,
    mod.hazard_type,
    mod.process_type
   FROM ((loss.loss_map_values lmv
     JOIN loss.loss_map lm ON ((lm.id = lmv.loss_map_id)))
     JOIN loss.loss_model mod ON ((mod.id = lm.loss_model_id)))
  ORDER BY lmv.id;


--
-- Name: contribution; Type: TABLE; Schema: loss; Owner: -
--

CREATE TABLE loss.contribution (
    id integer NOT NULL,
    loss_model_id integer NOT NULL,
    model_source character varying NOT NULL,
    model_date date NOT NULL,
    notes text,
    version character varying,
    purpose text,
    project character varying,
    contributed_at timestamp without time zone DEFAULT now() NOT NULL,
    license_code character varying NOT NULL
);


--
-- Name: TABLE contribution; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TABLE loss.contribution IS 'Meta-data for contributed model, license, source etc.';


--
-- Name: contribution_id_seq; Type: SEQUENCE; Schema: loss; Owner: -
--

CREATE SEQUENCE loss.contribution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contribution_id_seq; Type: SEQUENCE OWNED BY; Schema: loss; Owner: -
--

ALTER SEQUENCE loss.contribution_id_seq OWNED BY loss.contribution.id;


--
-- Name: loss_curve_map; Type: TABLE; Schema: loss; Owner: -
--

CREATE TABLE loss.loss_curve_map (
    id integer NOT NULL,
    loss_model_id integer NOT NULL,
    occupancy cf_common.occupancy_enum NOT NULL,
    component loss.component_enum NOT NULL,
    loss_type loss.loss_type_enum NOT NULL,
    frequency loss.frequency_enum NOT NULL,
    investigation_time integer,
    units character varying NOT NULL
);


--
-- Name: TABLE loss_curve_map; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TABLE loss.loss_curve_map IS 'Meta-data for a map of (PML) loss curves for a given loss model';


--
-- Name: loss_curve_map_id_seq; Type: SEQUENCE; Schema: loss; Owner: -
--

CREATE SEQUENCE loss.loss_curve_map_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loss_curve_map_id_seq; Type: SEQUENCE OWNED BY; Schema: loss; Owner: -
--

ALTER SEQUENCE loss.loss_curve_map_id_seq OWNED BY loss.loss_curve_map.id;


--
-- Name: loss_curve_map_values; Type: TABLE; Schema: loss; Owner: -
--

CREATE TABLE loss.loss_curve_map_values (
    id bigint NOT NULL,
    loss_curve_map_id integer NOT NULL,
    asset_ref character varying,
    the_geom public.geometry(Geometry,4326) NOT NULL,
    losses double precision[] NOT NULL,
    rates double precision[] NOT NULL,
    CONSTRAINT loss_curve_array_lengths_equal CHECK ((array_length(losses, 1) = array_length(rates, 1)))
);


--
-- Name: TABLE loss_curve_map_values; Type: COMMENT; Schema: loss; Owner: -
--

COMMENT ON TABLE loss.loss_curve_map_values IS 'Loss curve values for the specified loss curve map';


--
-- Name: loss_curve_map_values_id_seq; Type: SEQUENCE; Schema: loss; Owner: -
--

CREATE SEQUENCE loss.loss_curve_map_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loss_curve_map_values_id_seq; Type: SEQUENCE OWNED BY; Schema: loss; Owner: -
--

ALTER SEQUENCE loss.loss_curve_map_values_id_seq OWNED BY loss.loss_curve_map_values.id;


--
-- Name: loss_map_id_seq; Type: SEQUENCE; Schema: loss; Owner: -
--

CREATE SEQUENCE loss.loss_map_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loss_map_id_seq; Type: SEQUENCE OWNED BY; Schema: loss; Owner: -
--

ALTER SEQUENCE loss.loss_map_id_seq OWNED BY loss.loss_map.id;


--
-- Name: loss_map_values_id_seq; Type: SEQUENCE; Schema: loss; Owner: -
--

CREATE SEQUENCE loss.loss_map_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loss_map_values_id_seq; Type: SEQUENCE OWNED BY; Schema: loss; Owner: -
--

ALTER SEQUENCE loss.loss_map_values_id_seq OWNED BY loss.loss_map_values.id;


--
-- Name: loss_model_id_seq; Type: SEQUENCE; Schema: loss; Owner: -
--

CREATE SEQUENCE loss.loss_model_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loss_model_id_seq; Type: SEQUENCE OWNED BY; Schema: loss; Owner: -
--

ALTER SEQUENCE loss.loss_model_id_seq OWNED BY loss.loss_model.id;


--
-- Name: contribution id; Type: DEFAULT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.contribution ALTER COLUMN id SET DEFAULT nextval('loss.contribution_id_seq'::regclass);


--
-- Name: loss_curve_map id; Type: DEFAULT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_curve_map ALTER COLUMN id SET DEFAULT nextval('loss.loss_curve_map_id_seq'::regclass);


--
-- Name: loss_curve_map_values id; Type: DEFAULT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_curve_map_values ALTER COLUMN id SET DEFAULT nextval('loss.loss_curve_map_values_id_seq'::regclass);


--
-- Name: loss_map id; Type: DEFAULT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_map ALTER COLUMN id SET DEFAULT nextval('loss.loss_map_id_seq'::regclass);


--
-- Name: loss_map_values id; Type: DEFAULT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_map_values ALTER COLUMN id SET DEFAULT nextval('loss.loss_map_values_id_seq'::regclass);


--
-- Name: loss_model id; Type: DEFAULT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_model ALTER COLUMN id SET DEFAULT nextval('loss.loss_model_id_seq'::regclass);


--
-- Name: contribution contribution_pkey; Type: CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.contribution
    ADD CONSTRAINT contribution_pkey PRIMARY KEY (id);


--
-- Name: loss_curve_map loss_curve_map_pkey; Type: CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_curve_map
    ADD CONSTRAINT loss_curve_map_pkey PRIMARY KEY (id);


--
-- Name: loss_curve_map_values loss_curve_map_values_pkey; Type: CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_curve_map_values
    ADD CONSTRAINT loss_curve_map_values_pkey PRIMARY KEY (id);


--
-- Name: loss_map loss_map_pkey; Type: CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_map
    ADD CONSTRAINT loss_map_pkey PRIMARY KEY (id);


--
-- Name: loss_map_values loss_map_values_pkey; Type: CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_map_values
    ADD CONSTRAINT loss_map_values_pkey PRIMARY KEY (id);


--
-- Name: loss_model loss_model_pkey; Type: CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_model
    ADD CONSTRAINT loss_model_pkey PRIMARY KEY (id);


--
-- Name: contribution_loss_model_id_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX contribution_loss_model_id_idx ON loss.contribution USING btree (loss_model_id);


--
-- Name: loss_curve_map_loss_model_id_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX loss_curve_map_loss_model_id_idx ON loss.loss_curve_map USING btree (loss_model_id);


--
-- Name: loss_curve_map_values_loss_curve_map_id_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX loss_curve_map_values_loss_curve_map_id_idx ON loss.loss_curve_map_values USING btree (loss_curve_map_id);


--
-- Name: loss_curve_map_values_the_geom_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX loss_curve_map_values_the_geom_idx ON loss.loss_curve_map_values USING gist (the_geom);


--
-- Name: loss_map_loss_model_id_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX loss_map_loss_model_id_idx ON loss.loss_map USING btree (loss_model_id);


--
-- Name: loss_map_values_loss_map_id_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX loss_map_values_loss_map_id_idx ON loss.loss_map_values USING btree (loss_map_id);


--
-- Name: loss_map_values_the_geom_idx; Type: INDEX; Schema: loss; Owner: -
--

CREATE INDEX loss_map_values_the_geom_idx ON loss.loss_map_values USING gist (the_geom);


--
-- Name: contribution contribution_license_code_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.contribution
    ADD CONSTRAINT contribution_license_code_fkey FOREIGN KEY (license_code) REFERENCES cf_common.license(code);


--
-- Name: contribution contribution_loss_model_id_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.contribution
    ADD CONSTRAINT contribution_loss_model_id_fkey FOREIGN KEY (loss_model_id) REFERENCES loss.loss_model(id) ON DELETE CASCADE;


--
-- Name: loss_curve_map loss_curve_map_loss_model_id_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_curve_map
    ADD CONSTRAINT loss_curve_map_loss_model_id_fkey FOREIGN KEY (loss_model_id) REFERENCES loss.loss_model(id) ON DELETE CASCADE;


--
-- Name: loss_curve_map_values loss_curve_map_values_loss_curve_map_id_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_curve_map_values
    ADD CONSTRAINT loss_curve_map_values_loss_curve_map_id_fkey FOREIGN KEY (loss_curve_map_id) REFERENCES loss.loss_curve_map(id) ON DELETE CASCADE;


--
-- Name: loss_map loss_map_loss_model_id_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_map
    ADD CONSTRAINT loss_map_loss_model_id_fkey FOREIGN KEY (loss_model_id) REFERENCES loss.loss_model(id) ON DELETE CASCADE;


--
-- Name: loss_map_values loss_map_values_loss_map_id_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_map_values
    ADD CONSTRAINT loss_map_values_loss_map_id_fkey FOREIGN KEY (loss_map_id) REFERENCES loss.loss_map(id) ON DELETE CASCADE;


--
-- Name: loss_model loss_model_hazard_type_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_model
    ADD CONSTRAINT loss_model_hazard_type_fkey FOREIGN KEY (hazard_type) REFERENCES cf_common.hazard_type(code);


--
-- Name: loss_model loss_model_process_type_fkey; Type: FK CONSTRAINT; Schema: loss; Owner: -
--

ALTER TABLE ONLY loss.loss_model
    ADD CONSTRAINT loss_model_process_type_fkey FOREIGN KEY (process_type) REFERENCES cf_common.process_type(code);


--
-- Name: SCHEMA loss; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA loss TO lossusers;


--
-- Name: TABLE loss_map; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.loss_map TO lossusers;
GRANT ALL ON TABLE loss.loss_map TO losscontrib;


--
-- Name: TABLE loss_map_values; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.loss_map_values TO lossusers;
GRANT ALL ON TABLE loss.loss_map_values TO losscontrib;


--
-- Name: TABLE loss_model; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.loss_model TO lossusers;
GRANT ALL ON TABLE loss.loss_model TO losscontrib;


--
-- Name: TABLE all_loss_map_values; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.all_loss_map_values TO lossusers;
GRANT ALL ON TABLE loss.all_loss_map_values TO losscontrib;


--
-- Name: TABLE contribution; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.contribution TO lossusers;
GRANT ALL ON TABLE loss.contribution TO losscontrib;


--
-- Name: SEQUENCE contribution_id_seq; Type: ACL; Schema: loss; Owner: -
--

GRANT ALL ON SEQUENCE loss.contribution_id_seq TO losscontrib;


--
-- Name: TABLE loss_curve_map; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.loss_curve_map TO lossusers;
GRANT ALL ON TABLE loss.loss_curve_map TO losscontrib;


--
-- Name: SEQUENCE loss_curve_map_id_seq; Type: ACL; Schema: loss; Owner: -
--

GRANT ALL ON SEQUENCE loss.loss_curve_map_id_seq TO losscontrib;


--
-- Name: TABLE loss_curve_map_values; Type: ACL; Schema: loss; Owner: -
--

GRANT SELECT ON TABLE loss.loss_curve_map_values TO lossusers;
GRANT ALL ON TABLE loss.loss_curve_map_values TO losscontrib;


--
-- Name: SEQUENCE loss_curve_map_values_id_seq; Type: ACL; Schema: loss; Owner: -
--

GRANT ALL ON SEQUENCE loss.loss_curve_map_values_id_seq TO losscontrib;


--
-- Name: SEQUENCE loss_map_id_seq; Type: ACL; Schema: loss; Owner: -
--

GRANT ALL ON SEQUENCE loss.loss_map_id_seq TO losscontrib;


--
-- Name: SEQUENCE loss_map_values_id_seq; Type: ACL; Schema: loss; Owner: -
--

GRANT ALL ON SEQUENCE loss.loss_map_values_id_seq TO losscontrib;


--
-- Name: SEQUENCE loss_model_id_seq; Type: ACL; Schema: loss; Owner: -
--

GRANT ALL ON SEQUENCE loss.loss_model_id_seq TO losscontrib;


--
-- PostgreSQL database dump complete
--

