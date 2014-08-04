function E = DB_GetElectrode(tank_id)
% E = DB_GetElectrode(tank_id)
% 
% Returns electrode info for a tank with database index 'tank_id'
% 
% All depths are in microns
% 
% Daniel.Stolzberg@gmai.com 2014


try
    E = mym([...
        'SELECT e.target,e.depth,e.tank_id, ', ...
        't.manufacturer,t.pid,t.product_id,t.map,t.col_space,t.row_space,t.site_area ', ...
        'FROM electrodes e ', ...
        'INNER JOIN db_util.electrode_types t ', ...
        'ON e.type = t.pid ', ...
        'WHERE e.tank_id = {Si}'],tank_id);
    
catch ME
    if isequal(ME.message,'Unknown column ''t.pid'' in ''field list''')
        % this is the old database
        E = mym([...
            'SELECT e.target,e.depth,e.tank_id, ', ...
            't.manufacturer,t.id,t.product_id,t.site_map AS map, ', ...
            't.col_dist AS col_space,t.row_dist AS row_space ', ...
            'FROM electrodes e ', ...
            'INNER JOIN db_util.electrode_types t ', ...
            'ON e.type = t.id ', ...
            'WHERE e.tank_id = {Si}'],tank_id);
    else
        
        rethrow(ME)
    end
end


E.map = str2num(char(E.map));


E.channeldepths = E.depth:-E.col_space:E.depth-E.col_space*(length(E.map)-1);
if isnan(E.channeldepths)
    E.mapdepths = nan;
else
    E.mapdepths = E.channeldepths(E.map);
end


