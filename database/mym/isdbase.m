function[i] = isdbase(name)
% isdbase  True if MySQL database exists  [mym utilities]
% Example  if isdbase('junk'), dbdrop('junk'), end
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else
    % new compilation of mym returns structure. DJS 1/2013
    dbs = mym('show databases');
    i = any(strcmp(name,dbs.Database));
end   
