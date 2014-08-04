function subdirs = epsych_startup(rootdir)
% epsych_startup;
% epsych_startup(rootdir);
% newp = epsych_startup(...)
%
% Finds all subdirectories in a given root directory, removes any
% directories with 'svn', and adds them to the Matlab path.
%
% Typically, it is a good idea to call this function in the startup.m file 
% which should be located somewhere along the default Matlab path. 
% ex: ..\My Documents\MATLAB\startup.m
% 
% Here's an example of what to include in startup.m:
%    addpath('C:\MATLAB\work\epsych');
%    epsych_startup('C:\MATLAB\work\epsych');
% 
% Alternatively, call this function only after retrieving software updates
% using SVN.
%
% Use a period '.' as the first character in a directory name to hide it
% from being added to the Matlab path.  Ex: C:\MATLAB\work\epsych\.RPvds
% 
% Default rootdir is 'C:\MATLAB\work\epsych'.  If this directory does not
% exist, then an error is thrown.
% 
% Daniel.Stolzberg@gmail.com 2014

fprintf('Setting Paths for EPsych Toolbox ...')

if ~nargin || isempty(rootdir)
    rootdir = 'C:\MATLAB\work\epsych'; 
    assert(isdir(rootdir),'Default directory "%s" not found. See help epsych_startup',rootdir)
end

addpath(rootdir);

p = genpath(rootdir);

t = textscan(p,'%s','delimiter',';');
i = cellfun(@(x) (strfind(x,'\.')),t{1},'UniformOutput',false);
ind = cell2mat(cellfun(@isempty,i,'UniformOutput',false));
subdirs = cellfun(@(x) ([x ';']),t{1}(ind),'UniformOutput',false);
subdirs = cell2mat(subdirs');

addpath(subdirs);

fprintf(' done\n')


