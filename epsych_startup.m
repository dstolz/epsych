function subdirs = epsych_startup(rootdir,showsplash)
% epsych_startup;
% epsych_startup(rootdir [,showsplash])
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
%    addpath('C:\gits\epsych');
%    epsych_startup;
% 
% Alternatively, call this function only after retrieving software updates
% using SVN.
%
% Use a period '.' as the first character in a directory name to hide it
% from being added to the Matlab path.  Ex: C:\MATLAB\work\epsych\.RPvds
% 
% Default rootdir is wherever this function lives.  
% 
% Daniel.Stolzberg@gmail.com 2014

%     EPsych  
%     Copyright (C) 2016  Daniel Stolzberg, PhD
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

if nargin < 2 || isempty(showsplash), showsplash = true; end

if showsplash, epsych_printBanner; end

fprintf('\nSetting Paths for EPsych Toolbox ...')

if ~nargin || isempty(rootdir)
    [rootdir,~] = fileparts(which('epsych_startup'));
end

assert(isdir(rootdir),'Default directory "%s" not found. See help epsych_startup',rootdir)

oldpath = genpath(rootdir);
c = textscan(oldpath,'%s','Delimiter',';');
warning('off','MATLAB:rmpath:DirNotFound');
cellfun(@rmpath,c{1});
warning('on','MATLAB:rmpath:DirNotFound');

addpath(rootdir);

p = genpath(rootdir);

t = textscan(p,'%s','delimiter',';');
i = cellfun(@(x) (strfind(x,'\.')),t{1},'UniformOutput',false);
ind = cell2mat(cellfun(@isempty,i,'UniformOutput',false));
subdirs = cellfun(@(x) ([x ';']),t{1}(ind),'UniformOutput',false);
subdirs = cell2mat(subdirs');

addpath(subdirs);
path(path)
fprintf(' done\n')



