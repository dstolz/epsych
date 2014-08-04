function tbread(table,cols,vecs,sql)
% tbread   Read from MySQL table          [mym utilities]
% Inputs   table - table name, string
%          cols  - list of input columns,  (m*1) cell array of strings 
%          vecs  - list of output vectors, (m*1) cell array of strings
%          sql   - SQL 'select' statement clause(s), string
% Example  cols = {'order','date','price'};
%          tbread('orders',cols,cols,'where date > ''1995-01-31''')
% Notes    1. Use 'mym('select ..'' for queries with few columns
%          2. vecs elements are case-sensitive, cols elements are not 
% Author   Dimitri Shvorob, dimitri.shvorob@vanderbilt.edu, 7/12/07

checkInputs(table,cols,vecs)
for i = 1:length(cols)
    try
       s = sprintf('select %s from %s %s',cols{i},table,sql);
       evalin('base',sprintf('%s = mym(''%s'');',vecs{i},s))
    catch
       error('Error in submitted SQL statement: %s',s)   %#ok
    end     
end

function checkInputs(table,cols,vecs)
if ~istable(table)
   error('Table %s not found; use ''tblist'' to list available tables',table)
end
if ~(iscellstr(cols) && isvector(cols))
   error('''cols'' must be a cell vector of strings')
end
if ~(iscellstr(vecs) && isvector(vecs))
   error('''vecs'' must be a cell vector of strings')
end
if length(cols) ~= length(vecs)
   error('''cols'' and ''vecs'' must have the same length')
end
n = tbattr(table);
for i = 1:length(cols)
    if ~any(strcmpi(n,cols{i}))
       error('Column %s not found in table %s',cols{i},table)
    end
end 