function P = DB_GetUnitProps(unit_id,group_id)
% P = DB_GetUnitProps(unit_id)
% P = DB_GetUnitProps(unit_id,group_id)
% 
% Retrieve and sort unit properties.
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

narginchk(1,2);

P = [];


assert(isscalar(unit_id),'First input must be scalar.')

if nargin == 1
    dbP = mym(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
               'WHERE unit_id = {Si} ORDER BY group_id,param'],unit_id);
elseif nargin == 2
    assert(ischar(group_id),'Second input must be a string.')
    
    dbP = mym(['SELECT param,group_id,paramS,paramF FROM v_unit_props ', ...
               'WHERE unit_id = {Si} AND group_id REGEXP "{S}" ', ...
               'ORDER BY group_id,param'],unit_id,group_id);
end

upar = unique(dbP.param);
ugrp = unique(dbP.group_id);

for i = 1:length(upar)
    iind = ismember(dbP.param,upar{i});
    P.(upar{i}) = nan(1,length(ugrp));
    for j = 1:length(ugrp)
        ind = iind & ismember(dbP.group_id,ugrp{j});
        if ~any(ind), continue; end
        
        if ~iscell(P.(upar{i})) && ~isnan(dbP.paramF(ind)) && ~any(isnan(dbP.paramS{ind}))
            P.(upar{i})(j) = dbP.paramF(ind);
        
        else
            S = dbP.paramS(ind);
            if strcmpi(S,'NULL'), P.(upar{i})(j) = nan; continue; end
            if isnumeric(P.(upar{i}))
                P.(upar{i}) = cell(1,length(ugrp));
            end
            if ~iscell(S) && isnan(S), S = {nan}; end
            P.(upar{i})(j) = S;
        end
            
%         if isnan(dbP.paramF(ind))
%             S = dbP.paramS(ind);
%             if strcmpi(S,'NULL'), S = nan; end
%             if isnumeric(P.(upar{i}))
%                 P.(upar{i}) = cell(1,length(ugrp));
%             end
%             P.(upar{i})(j) = S;
%         else
%             P.(upar{i})(j) = dbP.paramF(ind);
%         end
    end
end
if ~isempty(P), P.group_id = ugrp'; end







