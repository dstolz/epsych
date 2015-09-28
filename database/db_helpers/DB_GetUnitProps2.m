function P = DB_GetUnitProps2(unit_id,group_id,regexp,conn)
% P = DB_GetUnitProps2(unit_id)
% P = DB_GetUnitProps2(unit_id,group_id)
% P = DB_GetUnitProps2(unit_id,group_id,regexp)
% P = DB_GetUnitProps2(unit_id,...,conn)
% 
% Retrieve and sort unit properties.
% 
% This function is updated and provides a better structure as an output
% than the original version.  The original version is being kept for now
% for compatibility with existing functions/GUIs.
% 
%
% group_id should be a string and is used in the database query to narrow
% what is returned from the database.  The actual search query uses 'REGEXP'
% syntax with group_id string as the comparison.
%   .... WHERE unit_id = 4123 AND group_id REGEXP "dB$" ....
% (see MySQL documentation for REGEXP syntax: http://dev.mysql.com/doc/refman/5.0/en/pattern-matching.html)
%
% If group_id is not specified or empty, then all parameters will be
% returned for the unit.
%
% See also, DB_UpdateUnitProps, DB_CheckAnalysisParams
% 
% DJS 2013 daniel.stolzberg@gmail.com

% use mym by default
if nargin < 4, conn = []; end

if nargin == 1, group_id = []; end
if nargin < 3 || ~islogical(regexp), regexp = false; end

P = [];


assert(isscalar(unit_id),'First input must be scalar.')

if isempty(group_id)
    sql = sprintf(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
               'WHERE unit_id = %d ORDER BY group_id,param'],unit_id);
else
    assert(ischar(group_id),'Second input must be a string.')
    
    if regexp, sstr = 'REGEXP'; else sstr = '='; end
    
    sql = sprintf(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
               'WHERE unit_id = %d AND group_id %s "%s" ', ...
               'ORDER BY group_id,param'],unit_id,sstr,group_id);
end

dbP = myms(sql,conn,'structure');

if isempty(dbP)
    error('No Data found for Unit ID %d\n\tSQL: %s',unit_id,sql);
end

upar = unique(dbP.param);
ugrp = unique(dbP.group_id);

for i = 1:length(upar)
    for j = 1:length(ugrp)
        iind = ismember(dbP.param,upar{i});
        if all(cellfun(@(x) (isempty(x)),dbP.paramS(iind))) || any(ismember(dbP.paramS(iind),'NULL'))
            v = dbP.paramF(iind);
        else
            v = dbP.paramS{iind};
        end
        if isnan(v), continue; end
        ns = strfind(ugrp{j},'.');
        if ~isempty(ns)
            ugrp{j}(ns) = '_';
        end
        P.(ugrp{j}).(upar{i}) = v;
    end
end










