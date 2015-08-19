function i = findincell(m,n)
% i = findincell(m)
% i = findincell(m,n)
% 
% Helper function finds first n indicies of values in cell array m where
% there may be empty cells. CELL2MAT is ineffective in this case because it
% can not translate the empty cells to a numerical (logical) matrix.
% 
% 
% Daniel.Stolzberg@gmail.com  2014

if nargin == 1, n = []; end

assert(iscell(m));

nm = ~cellfun(@isempty,m);

if isempty(n)
    i = find(nm);
else
    i = find(nm,n);
end
