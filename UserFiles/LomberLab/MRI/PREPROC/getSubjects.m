function subjs = getSubjects(niipath)
% subjs = getSubjects([niipath])
%
% Return cell array of strings with subject names; i.e. subdirectories
% under the 'NII' path.
%
% Daniel.Stolzberg@gmail.com 2016

if nargin == 0, niipath = fullfile(pwd,'NII'); end

D = dir(niipath);
D(~[D.isdir]) = [];
subjs = {D(3:end).name}';


