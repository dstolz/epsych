function tbrename(old,new)
% tbrename Rename MySQL table             [mym utilities]
% Example  tbrename('old',new')
if istable(new)
   error('Table %s already exists',new)
end
if ~istable(old)
   error('Table %s not found',old)
end
try
  mym(['rename table ' old ' to ' new])
catch
  error('Table %s not renamed; check if %s is a valid name',old,new)
end 