START TRANSACTION;

ALTER TABLE loss.loss_curve_map 
 DROP CONSTRAINT either_return_period_or_inv_time,
 DROP COLUMN return_period;

COMMIT;
