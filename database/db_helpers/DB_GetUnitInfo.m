function info = DB_GetUnitInfo(unit_id)
% info = DB_GetUnitInfo(unit_id)
%
% Retrieve lots of info about a unit's channel, block, tank, and experiment
%
% Daniel.Stolzberg@gmail.com 2016

narginchk(1,1);
nargoutchk(1,1);

assert(isscalar(unit_id),'DB_GetUnitInfo:unit_id must be a scalar value')

info = mymprintf( ...
    ['SELECT * FROM experiments e ', ...
    'JOIN tanks t ON t.exp_id = e.id ', ...
    'JOIN blocks b ON b.tank_id = t.id ', ...
    'JOIN channels c ON c.block_id = b.id ', ...
    'JOIN units u ON u.channel_id = c.id ', ...
    'JOIN db_util.pool_class d ON d.id = u.pool ', ...
    'WHERE u.id = %d'],unit_id);