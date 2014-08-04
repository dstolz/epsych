function ds = DB2dataset(dbquery)
% ds = DB2dataset(dbquery)
% 
% Converts the results of a mysql search query to dataset format.
% 
% Requires Statistics toolbox
% 
% Daniel.Stolzberg@gmail.com 2014

narginchk(1,1);
assert(ischar(dbquery),'Input must be a string.');

t = mym(dbquery);
if isempty(t), ds = []; return; end

for f = fieldnames(t)'
    f = char(f); %#ok<FXSET>
    n = length(t.(f));
    for i = 1:n
        data(i,1).(f) = t.(f)(i); %#ok<AGROW>
    end
end

ds = struct2dataset(data);

