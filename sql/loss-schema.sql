--
-- Loss Database Schema
-- Intended to store results of risk analyses: loss maps and loss curves
--

--
-- NOTE please execute commands in common.sql before executing this file
--

--
-- Use transaction to prevent partial execution
--
START TRANSACTION;

-- Usual settings copied from pg_dump output
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;
SET default_with_oids = false;

SET search_path = loss, pg_catalog, public;

-----------------------------------------------------------------------------

--
-- Schema for Challenge Fund loss database elements
--
CREATE SCHEMA IF NOT EXISTS loss;
ALTER SCHEMA loss OWNER TO losscontrib; 
COMMENT ON SCHEMA loss IS
	'Schema for Challenge Fund loss database elements';

-- NOTE If you want to use a tablespace, configure it here
-- SET default_tablespace = loss_ts; 

--
-- Enumerated type for loss metrics
--
CREATE TYPE loss.metric_enum AS ENUM (
	'AAL',			-- Average Annual Loss
	'AALR',			-- AAL Ratio
	'PML'			-- Probable Maximal Loss aka 'Return Period Loss',
);
COMMENT ON TYPE loss.metric_enum IS 'Types of loss metric';

--
-- Enumerated type for loss type
--
CREATE TYPE loss.loss_type_enum AS ENUM (
	'Ground Up',	-- Ground Up losses considering 
	'Insured'		-- Insured losses considering insurance policy criteria 
					-- such as deductibles
);
COMMENT ON TYPE loss.loss_type_enum IS 'Types of loss';

--
-- Enumerated type for loss frequency
--
CREATE TYPE loss.frequency_enum AS ENUM (
	'Rate of Exceedence',			-- for a given investigation time 
	'Probability of Exceedence',	-- for a given investigation time
	'Return Period'					-- in years
);
COMMENT ON TYPE loss.frequency_enum IS 'Types of loss frequency';

--
-- Enumerated type for loss component
--
CREATE TYPE loss.component_enum AS ENUM (
	'Buildings',
	'Direct Damage to other Asset',
	'Contents',
	'Business Interruption'
);
COMMENT ON TYPE loss.component_enum IS 'Types of loss component';

--
-- Enumerated type for occupancy (or use)
--
DROP TYPE IF EXISTS loss.occupancy_enum;

--
-- Loss model
--
CREATE TABLE IF NOT EXISTS loss_model (
	id					SERIAL PRIMARY KEY,
	name				VARCHAR NOT NULL,
	description			TEXT,
	--
	-- Optional hazard and process types
	--
	hazard_type			VARCHAR REFERENCES cf_common.hazard_type(code),
	process_type		VARCHAR REFERENCES cf_common.process_type(code),
	--
	-- Optional links to hazard, exposure and vulnerability models
	--
	hazard_link			VARCHAR,
	exposure_link		VARCHAR,
	vulnerability_link	VARCHAR
);
COMMENT ON TABLE loss.loss_model 
	IS 'Loss model meta-data and optional links to hazard, exposure and vulnerability models';                                               

-----------------------------------------------------------------------------

--
-- Loss Map
--
CREATE TABLE IF NOT EXISTS loss_map (
	id					SERIAL PRIMARY KEY,
	loss_model_id		INTEGER NOT NULL
							REFERENCES loss_model(id) ON DELETE CASCADE,
	occupancy			cf_common.occupancy_enum NOT NULL,
	component			component_enum NOT NULL,
	loss_type			loss_type_enum NOT NULL,

	return_period		INTEGER, 
	
	-- e.g. USD, persons, buildings...
	units				VARCHAR NOT NULL,
	metric				metric_enum NOT NULL,

	CONSTRAINT pml_implies_return_period CHECK (
		-- If metric = PML then return_period must be NOT NULL
		NOT (metric = 'PML' AND return_period IS NULL)
	)
);
COMMENT ON TABLE loss.loss_map 
	IS 'Meta-data for a single loss map for a given loss model'; 

-- Index for FOREIGN KEY
CREATE INDEX ON loss_map(loss_model_id);

--
-- Loss values for the specified loss map
-- With geospatial location and optional asset reference/id
--
CREATE TABLE IF NOT EXISTS loss_map_values (
	id                  BIGSERIAL PRIMARY KEY,
	loss_map_id			INTEGER NOT NULL REFERENCES loss_map(id) 
							ON DELETE CASCADE,
	asset_ref			VARCHAR,
	the_geom			public.geometry(Geometry,4326) NOT NULL,
	loss				DOUBLE PRECISION NOT NULL
);
COMMENT ON TABLE loss.loss_map_values 
	IS 'Loss values for the specified loss map'; 

-- Index for FOREIGN KEY
CREATE INDEX ON loss_map_values USING btree(loss_map_id);
-- Geospatial Index for geometry 
CREATE INDEX ON loss_map_values USING GIST(the_geom);


--
-- Loss Curve Map (for PML only)
--
CREATE TABLE IF NOT EXISTS loss_curve_map (
	id					SERIAL PRIMARY KEY,
	loss_model_id		INTEGER NOT NULL REFERENCES loss_model(id) 
							ON DELETE CASCADE,
	occupancy			cf_common.occupancy_enum NOT NULL,
	component			component_enum NOT NULL,
	loss_type			loss_type_enum NOT NULL,
	frequency			frequency_enum NOT NULL,

	investigation_time	INTEGER,

	-- e.g. USD, persons, buildings...
	units				VARCHAR NOT NULL
);
COMMENT ON TABLE loss.loss_curve_map 
	IS 'Meta-data for a map of (PML) loss curves for a given loss model'; 

-- Index for FOREIGN KEY
CREATE INDEX ON loss_curve_map(loss_model_id);

--
-- Loss curve values for the specified loss map
-- With geospatial location and optional asset reference/id
--
CREATE TABLE IF NOT EXISTS loss_curve_map_values (
	id					BIGSERIAL PRIMARY KEY,
	loss_curve_map_id	INTEGER NOT NULL REFERENCES loss_curve_map(id)
							ON DELETE CASCADE, 
	asset_ref			VARCHAR,
	the_geom			public.geometry(Geometry,4326) NOT NULL, 
	losses				DOUBLE PRECISION ARRAY NOT NULL,
	rates				DOUBLE PRECISION ARRAY NOT NULL,
	CONSTRAINT loss_curve_array_lengths_equal CHECK (
		array_length(losses,1) = array_length(rates,1)
	)
);
COMMENT ON TABLE loss.loss_curve_map_values
    IS 'Loss curve values for the specified loss curve map';

-- Index for FOREIGN KEY                                                        
CREATE INDEX ON loss_curve_map_values USING btree(loss_curve_map_id);
-- Geospatial Index for geometry
CREATE INDEX ON loss_curve_map_values USING GIST(the_geom);

--
-- Contribution metadata
--
CREATE TABLE contribution (
	id					SERIAL PRIMARY KEY,
	loss_model_id		INTEGER NOT NULL 
							REFERENCES loss_model(id) ON DELETE CASCADE,
	model_source		VARCHAR NOT NULL,
	model_date			DATE NOT NULL,
	notes				TEXT,
	license_id			INTEGER NOT NULL
							REFERENCES cf_common.license(id),
	version				VARCHAR,
	purpose				TEXT
);
COMMENT ON TABLE loss.contribution
    IS 'Meta-data for contributed model, license, source etc.';
-- Index for FOREIGN KEY
CREATE INDEX ON contribution USING btree(loss_model_id);


--
-- Convenience VIEW for access to loss map data, use ST_AsText to 
-- make geometry column more suitable for saving to CSV files
-- 
DROP VIEW IF EXISTS loss.all_loss_map_values;
CREATE VIEW loss.all_loss_map_values AS 
SELECT 
	lmv.id AS uid, lmv.loss_map_id, 
	ST_AsText(the_geom) AS geom,
	asset_ref, loss, 
	lm.occupancy, lm.component, lm.loss_type, lm.return_period, lm.units, 
	lm.metric, 
	mod.name, mod.hazard_type, mod.process_type 
  FROM loss.loss_map_values lmv 
  JOIN loss.loss_map lm ON lm.id=lmv.loss_map_id 
  JOIN loss.loss_model mod ON mod.id=lm.loss_model_id 
  ORDER BY lmv.id;
--
-- Commit changes to DB - 
-- NOTE this should be the last command in this file
--
COMMIT;

-- Magic Vim comment to use 4 space tabs 
-- vim: set ts=4:sw=4                                                           
