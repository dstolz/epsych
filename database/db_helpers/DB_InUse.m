function in_use = DB_InUse(table,id,state)
% in_use = DB_InUse(table,id)
% in_use = DB_InUse(table,id,state)
%
% Use to retrieve or alter 'in_use' field of a table.  Always returns
% current value of 'in_use' field before changing the state.
%
% state: 'yes','no','toggle'
%
% DJS 2013

if nargin < 2 || nargin > 3, error('DB_InUse: Invalid number of input arguments.'); end

s = mym('SELECT in_use FROM {S} WHERE id = {Si}',table,id);
in_use = s.in_use;

if nargin == 2, return; end

switch lower(state)
    case 'yes'
        mym('UPDATE {S} SET in_use = TRUE WHERE id = {Si}',table,id);
    case 'no'
        mym('UPDATE {S} SET in_use = FALSE WHERE id = {Si}',table,id);
    case 'toggle'
        mym('UPDATE {S} SET in_use = {Si} WHERE id = {Si}',table,~in_use,id);
    otherwise
        error('DB_InUse: Unknown state ''%s''',state)
end