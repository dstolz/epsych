function dbadd(dbname)
% dbadd    Create MySQL database          [mym utilities]
% Example  dbadd('newdb')
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect.')
else  
   try
      mym(sprintf('create database if not exists %s',dbname))
   catch
      error('Database %s could not be created',dbname)
   end
end   