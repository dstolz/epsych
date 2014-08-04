SELECT COUNT(id) FROM units WHERE in_use = FALSE;

UPDATE units AS ua INNER JOIN units AS ub ON ua.id = ub.id 
SET ua.in_use = FALSE WHERE ub.unit_count < 200;