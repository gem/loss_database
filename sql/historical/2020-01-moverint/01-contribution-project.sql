-- SQL statements to be applied to the CF loss database 

-- Add a project field
ALTER TABLE loss.contribution ADD COLUMN IF NOT EXISTS project VARCHAR;
-- All loss contributions with id<=90 come from the SWIO RAFI project
UPDATE loss.contribution SET project = 'SWIO RAFI' WHERE loss_model_id<=90;

-- Add a contributed_at timestamp (with time zone)
ALTER TABLE loss.contribution ADD COLUMN IF NOT EXISTS 
	contributed_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW();
UPDATE loss.contribution SET contributed_at = '2019-04-01 00:00:00+0' WHERE loss_model_id<=90;
