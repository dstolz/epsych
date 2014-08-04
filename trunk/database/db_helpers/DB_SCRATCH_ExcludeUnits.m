%% "Exclude" units on database with fewer than minspikecnt spikes

minspikecnt = 200; % "exclude" units with spikes fewer than this

updatestr = sprintf(['UPDATE units AS ua INNER JOIN units AS ub ', ...
    'ON ua.id = ub.id SET ua.in_use = FALSE ', ...
    'WHERE ub.unit_count < %d'],minspikecnt);

mym(updatestr);
