
-- ALTER TYPE loss.component_enum
-- ADD VALUE 'Direct Damage to other Asset' AFTER 'Buildings';

START TRANSACTION;

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


COMMIT;
