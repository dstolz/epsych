function dbopen(name)
% dbopen   Make MySQL database current    [mym utilities]
% Example  dbopen('new')
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else 
   try 
     a = mym(['use ' name]);   %#ok
   catch
     error('Database %s not found; use ''dblist'' to list available databases',name)
   end 
end   
  