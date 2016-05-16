function[names] = dblist
% dblist   List MySQL databases           [mym utilities]
% Example  dbs = dblist
if ~myisopen
   error('No MySQL connection active; use ''myopen'' to connect')
else
    % new compilation of mym returns structure DJS 1/2013
    dbs = mym('show databases');
    names = dbs.Database;
    % remove non-data databases from list DJS 1/2013
    % updated to mymistable DJS 5/2016
    ind = cellfun(@(a) (~mymistable([a '.protocols'])),names);
    names(ind) = [];
end   
