function[size] = tbsize(table,varargin)
% tbsize   Size of MySQL table            [mym utilities]
% Inputs   table - table name, string
%          dim   - dimension, 1 or 2 (optional)
% Example  [n,k] = tbsize('junk')
if ~istable(table)
   error('Table %s not found; use ''tblist'' to list available tables',table)
else
   if nargin > 1
      switch varargin{1}
          case 1,    size = rows(table);
          case 2,    size = cols(table); 
          otherwise, error('Invalid dimension') 
      end         
   else
      size = [rows(table) cols(table)]; 
   end
end   

function[r] = rows(table)
r = mym(['select count(*) from ' table]);

function[c] = cols(table)
[a,b,c,d,e,f] = mym(['describe ' table]);    %#ok
c = length(a);