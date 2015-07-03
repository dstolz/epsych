%% AFFECTS ALL UNITS OF ALL TANKS
%
% Update units table so that units with low spike counts are marked as not
% "in_use".  This is useful to hide relatively unresponsive units from the
% DB_Browser GUI and also from custom batch processing scripts.
%
% DJS 2015

units = mym('SELECT id,unit_count FROM units');

ind = units.unit_count < 500;

duid = units.id(ind);

for i = 1:length(duid)
    fprintf('Updating %d of %d ...',i,length(duid))
    mym('UPDATE units SET in_use = 0 WHERE id = {Si}',duid(i));
    fprintf(' done\n')
end

