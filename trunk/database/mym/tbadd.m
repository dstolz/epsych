function tbadd(table,names,types,varargin)
% tbadd    Create MySQL table             [mym utilities]
% Inputs   table - table name, string
%          names - column-name list, (m*1) cell array
%          types - column-type list, (m*1) cell array
%          over  - string 'replace' to allow overwrites (optional)
% Notes    Use 'mym('create table ..'' for tables with few columns
% Example  names = {'customer'   ,'date','price'};
%          types = {'varchar(30)','date','double'}
%          tbadd('orders',names,types,'replace')

checkInputs(table,names,types,varargin)
s = sprintf('create table %s (',table);
for i = 1:length(names)
  s = [s names{i} ' ' types{i} ', '];
end
s = [s(1:length(s)-2) ')'];
try
  mym(s)
catch
  error('Error in submitted SQL statement: %s',s)
end

function checkInputs(table,names,types,varargin)
if nargin > 3 
   if ~strcmpi(varargin{1},'replace')
       error('''over'' not recognized')
   else
       if istable(table)
          tbdrop(table)
       end   
   end    
else
   if istable(table)
      error('Table %s already exists',table)
   end   
end
if ~(iscellstr(names) && isvector(names))
   error('''names'' must be a cell vector of strings')
end
if ~(iscellstr(types) && isvector(types))
   error('''types'' must be a cell vector of strings')
end
if length(names) ~= length(types)
   error('''names'' and ''types'' must have the same length')
end
if isempty(dbcurr) && isempty(strfind(table,'.'))
   error('No database selected; use ''dbopen'' to open a database')
end
end