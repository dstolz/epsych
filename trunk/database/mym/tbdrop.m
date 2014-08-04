function tbdrop(table)
% tbdrop   Delete MySQL table             [mym utilities]
% Example  tbdrop('project.junk')
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else
   try 
     mym(['drop table if exists ' table])
   catch
     error('Table %s could not be deleted; use ''tblist'' to list available tables',table)
   end
end   
   