function subpath = getSubpath(loc,subj,niipath)
% structpath = getPath2Structurals(loc [,subj] [,niipath])
%
% ** NEEDS IMPROVEMENT AND ERROR HANDLING
%
% Daniel.Stolzberg@gmail.com 2016

narginchk(1,3);

assert(ischar(loc));

loc = upper(loc);

if nargin < 3, niipath = fullfile(pwd,'NII'); end
if nargin < 2 || isempty(subj),    subj = getSubjects(niipath);   end

subj = cellstr(subj);
subpath = cell(size(subj));
for i = 1:length(subj)
    subpath{i} = fullfile(niipath,subj{i},loc);
end
subpath = char(subpath);