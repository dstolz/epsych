function Fc = F_const(el_pos,d, cond, cond_top,this_tol)
%function Fc = F_const(el_pos,d, cond, cond_top,this_tol)
%
%Gives the transformation matrix F from CSDs to potential for the constant
%iCSD method.
%
%el_pos: electrode positions, default: 100e-6:100e-6:2300e-6
%d: activity diameter, default: 500e-6
%cond: extracellular conductivity, default: 0.3
%cond_top: conductivity above cortex, default: cond
%this_tol: tolerance of the integral, default: 1e-6


%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

%DEFAULT VALUES
if nargin<1, el_pos = 100e-6:100e-6:2300e-6;end;
if nargin<2, d = 500e-6; end;
if nargin<3, cond = 0.3; end;
if nargin<4, cond_top = cond; end;
if nargin<5, this_tol = 1e-6; end;

%DEFINE FILENAME
N = length(el_pos);
r_off = 0;
z1 = el_pos(1);
h = el_pos(2)-z1;
full_filename = [matrix_folder() filesep 'Fc' make_filename(d,r_off,N,h,z1,cond,cond_top) '.mat'];

%GET/COMUTE Fc
try, %see if Fc exists
  load(full_filename,'Fc','tol');
  if tol>this_tol
    Fc = compute_F_constant(full_filename,el_pos,d,cond,cond_top,this_tol); %local
  end;
catch, %compute Fc
  msgstr_Fc = lasterr;
  Fc = compute_F_constant(full_filename,el_pos,d,cond,cond_top,this_tol);
end;

function out = compute_F_constant(full_filename,el_pos,d,cond,cond_top,tol);
  N = length(el_pos);
  h = el_pos(2)-el_pos(1);
  out = zeros(N);        %define matrix
  for j = 1:N            %rows
    zj = el_pos(j);   %electrode positions
    for i = 1:N %columns
        if i~=1 %define lower integral limit
          lower_int = el_pos(i)-(el_pos(i)-el_pos(i-1))/2;
        else
          lower_int = max(0,el_pos(i)-h/2);
        end;
        if i~=N %define upper integral limit
          upper_int = el_pos(i)+(el_pos(i+1)-el_pos(i))/2;
        else
          upper_int = el_pos(i)+h/2;
        end;
  %      zi = el_pos(i);   %mid CSD position    
        out(j,i) = quad(@f_cylinder,lower_int,upper_int,tol,[],zj,d,cond) ...
            +(cond-cond_top)/(cond+cond_top) ...
            *quad(@f_cylinder,lower_int,upper_int,tol,[],-zj,d,cond);
    end; %for i
  end; %for j
  Fc = out;
  save(full_filename, 'Fc','tol');
return;

function out1 = f_cylinder(zeta,z,diam,cond)
  out1 = 1./(2.*cond).*(sqrt((diam/2)^2+((z-zeta)).^2)-abs(z-zeta));
return;