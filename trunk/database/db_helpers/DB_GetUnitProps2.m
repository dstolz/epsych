function P = DB_GetUnitProps2(unit_id,group_id,regexp)
% P = DB_GetUnitProps2(unit_id)
% P = DB_GetUnitProps2(unit_id,group_id)
% P = DB_GetUnitProps2(unit_id,group_id,regexp)
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

narginchk(1,3);

if nargin < 3 || ~islogical(regexp), regexp = false; end

P = [];


assert(isscalar(unit_id),'First input must be scalar.')

if nargin == 1
    dbP = mym(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
               'WHERE unit_id = {Si} ORDER BY group_id,param'],unit_id);
elseif nargin >= 2
    assert(ischar(group_id),'Second input must be a string.')
    
    if regexp, sstr = 'REGEXP'; else sstr = '='; end
    
    dbP = mym(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
               'WHERE unit_id = {Si} AND group_id {S} "{S}" ', ...
               'ORDER BY group_id,param'],unit_id,sstr,group_id);
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










