
-- ALTER TYPE loss.component_enum
-- ADD VALUE 'Direct Damage to other Asset' AFTER 'Buildings';

START TRANSACTION;

ALTER TABLE cf_common.hazard_type ADD PRIMARY KEY(code);
ALTER TABLE cf_common.process_type ADD PRIMARY KEY(code);

ALTER TABLE loss.loss_model 
 ADD COLUMN 	hazard_type			VARCHAR REFERENCES cf_common.hazard_type(code),
 ADD COLUMN 	process_type		VARCHAR REFERENCES cf_common.process_type(code),
 ADD COLUMN		hazard_link			VARCHAR,
 ADD COLUMN 	exposure_link		VARCHAR,
 ADD COLUMN		vulnerability_link	VARCHAR;


COMMIT;
