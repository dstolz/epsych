function subdirs = epsych_startup(rootdir)
% epsych_startup;
% epsych_startup(rootdir);
% newp = epsych_startup(...)
%
% Finds all subdirectories in a given root directory, removes any
% directories with 'svn', and adds them to the Matlab path.
%
% Default rootdir is 'C:\MATLAB\work\epsych'.  If this directory does not
% exist, then an error is thrown.
% 
% DJS 2013

fprintf('** Setting Paths for EPsych Toolbox **\n')

if ~nargin || isempty(rootdir)
    rootdir = 'C:\MATLAB\work\epsych'; 
    assert(isdir(rootdir),'Default directory "%s" not found. See help epsych_startup',rootdir)
end

p = genpath(rootdir);

t = textscan(p,'%s','delimiter',';');
i = cellfun(@(x) (strfind(x,'\.')),t{1},'UniformOutput',false);
ind = cell2mat(cellfun(@isempty,i,'UniformOutput',false));
subdirs = cellfun(@(x) ([x ';']),t{1}(ind),'UniformOutput',false);
subdirs = cell2mat(subdirs');

addpath(subdirs);





