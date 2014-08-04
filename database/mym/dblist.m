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
    ind = false(size(names));
    for i = 1:length(names)
        ind(i) = ~istable([names{i} '.protocols']);
    end
    names(ind) = [];
end   
