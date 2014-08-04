%% Get spike and stimulus onset vectors for use with NeuroExplorer 
%  from block currently selected in DB_Browser

ids = getpref('DB_BROWSER_SELECTION');

units = mym(['SELECT u.id,c.target,CONCAT(c.target,c.channel,p.class,u.id) AS name ', ...
             'FROM units u ', ...
             'INNER JOIN channels c ', ...
             'ON u.channel_id = c.id ', ...
             'INNER JOIN class_lists.pool_class p ', ...
             'ON u.pool = p.id ', ...
             'WHERE c.block_id = {Si} ', ...
             'AND u.pool > 0 ', ...
             'AND u.isbad = 0 AND u.in_use = 1 ', ...
             'AND c.in_use = 1'],ids.blocks);

for n = unique(units.target)'
    eval(sprintf('clear %s*',char(n)));
end
for i = 1:length(units.id)
    t = DB_GetSpiketimes(units.id(i));
    eval(sprintf('%s = t;',units.name{i}));
end
for n = unique(units.target)'
    eval(sprintf('whos %s*',char(n)));
end



event = 'Levl';

eval(sprintf('clear %s*',event));
p = DB_GetParams(ids.blocks);
for e = p.lists.(event)'
    ind = p.VALS.(event) == e;
    t = p.VALS.onset(ind);
    eval(sprintf('%s_%02d = t;',event,e))
end
eval(sprintf('whos %s*',event))
