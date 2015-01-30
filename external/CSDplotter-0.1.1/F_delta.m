function out = F_delta(el_pos,d,cond,cond_top)
%function out = F_delta(el_pos,d,cond,cond_top)
%
%Computes the F-matrix from infinitesimally thin current source density
%sheets with diameter d and homogenous activity throughout the sheet.
%
%el_pos:    the z-positions of the electrode contacts, default:
%100e-6:100e-6:2300e-6 
%d:         activity diameter, default: 500e-6
%cond:      cortical conductivity, default: 0.3
%cond_top:  conductivity on top of cortex, default: cond
%
%out is a (number_of_electrodes)x(number_of_electrodes) matrix. 

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

%addpath('fCSD_matrixes');

if nargin < 1, el_pos = 100e-6:100e-6:2300e-6; end
if nargin < 2, d = 500e-6; end;
if nargin < 3, cond = 0.3; end;
if nargin < 4, cond_top = cond; end;

%DEFINE FILENAME
N = length(el_pos);
r_off = 0;
z1 = el_pos(1);
h = el_pos(2)-z1;
full_filename = [matrix_folder() filesep 'Fd' make_filename(d,r_off,N,h,z1,cond,cond_top) '.mat'];

try,
  load(full_filename,'Fd');
  out = Fd;
catch,
  msgstr = lasterr;
  out = zeros(N);
  for j=1:N                     %zj is position of CSD-plane
    zj = z1 + (j-1)*h;
    for i=1:N                   %zi is position of electrode
        zi = z1 + (i-1)*h;
        out(j,i) = h/(2*cond)*((sqrt((zj-zi)^2+(d/2)^2)-abs(zj-zi))+ ...
            (cond-cond_top)/(cond+cond_top)*(sqrt((zj+zi)^2+(d/2)^2)-abs(zj+zi)));
    end; %for i
  end; %for j
  Fd = out;
  save(full_filename, 'Fd');
end;  %catch