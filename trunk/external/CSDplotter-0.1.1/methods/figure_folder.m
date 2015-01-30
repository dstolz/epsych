function out = figure_folder()
%Creates the figure folder string: this_folder/figs. Creates the folder if
%it does not exist.

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html
[pathstr, name, ext, versn] = fileparts(mfilename('fullpath'));
out = [pathstr filesep 'figs']; %folder in which figures are saved
if exist(out,'dir')==0; mkdir(out); end; %create folder if it doesn't exist