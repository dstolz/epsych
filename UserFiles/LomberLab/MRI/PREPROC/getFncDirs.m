function fncdirs = getFncDirs(niipath)
% fncdirs = getFncDirs([niipath])
%
% Returns valid functional directories
%
% Daniel.Stolzberg@gmail.com 2016

if ~nargin
    niipath = pwd; 
    if ~strcmpi(niipath(end-2:end),'NII')
        niipath = fullfile(niipath,'NII');
        assert(isdir(niipath),'Unable to find NII path.')
    end
end

S = getSubjects(niipath);


f = [];
for s = S'
    d = dir(fullfile(niipath,char(s)));
    f = [f; {d([d.isdir]).name}'];
end

f(ismember(f,{'.','..','STRUCTURALS','FIELDMAPS'})) = [];
fncdirs = unique(f);