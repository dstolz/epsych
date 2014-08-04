function dbdrop(name)
% dbdrop   Delete MySQL database          [mym utilities]
% Example  dbdrop('junk')
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else
   try 
     mym(sprintf('drop database if exists %s',name))
   catch
     error('Database %s could not be deleted',name)
   end
end   