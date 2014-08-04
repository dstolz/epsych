function[name] = dbcurr
% dbcurr   Current MySQL database         [mym utilities]
% Example  dbname = dbcurr
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect') 
else
    % new compilation of mym returns structure DJS 1/2013
    d = mym('select database() as db');
    name = char(d.db);
end   