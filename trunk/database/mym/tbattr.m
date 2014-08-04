function[varargout] = tbattr(table)
% tbattr   List columns of MySQL table    [mym utilities]
% Inputs   table - table name, string
% Outputs  names - column names, (m*1) cell array 
%          types - column types, (m*1) cell array (optional) 
% Example  [names,types] = tbattr('project.orders')
if ~istable(table)
   error('Table %s not found; use ''tblist'' to list available tables',table)
end
[a,b,c,d,e,f] = mym(['describe ' table]);    %#ok
varargout{1} = a;  
if nargout == 2
   x = a;
   for k = 1:length(a)
       x{k} = char(cell2mat(b(k))');
   end 
   varargout{2} = x;  
end  
  