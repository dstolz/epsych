function F = F_cubic_spline(el_pos,d,cond,cond_top,this_tol)
%function F = F_cubic_spline(el_pos,d,cond,cond_top,this_tol)
%
%Modified from general_spline_method_v3
%
%Creates the F matrix of the cubic spline method.
%
%el_pos:    the z-positions of the electrode contacts, default:
%100e-6:100e-6:2300e-6 
%d:         activity diameter, default: 500e-6
%cond:      cortical conductivity, default: 0.3
%cond_top:  conductivity on top of cortex, default: cond
%this_tol: tolerance of integral, default: 1e-6

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

if nargin<1; el_pos = 100e-6:100e-6:2300e-6;end;
if nargin<2; d = 500e-6; end;
if nargin<3; cond = 0.3; end;
if nargin<4; cond_top = cond; end;
if nargin<5; this_tol=1e-6; end;

tfilename = make_filename(d,0,length(el_pos),el_pos(2)-el_pos(1),el_pos(1),cond,cond_top); %part of Fd filename
full_filename = [matrix_folder() filesep 'Fcs' tfilename '.mat'];

try,
  load(full_filename,'Fcs','tol');
  if tol<=this_tol
    F = Fcs;
  else
    F = compute_F_cubic_spline(full_filename,el_pos,d,cond,cond_top,this_tol);
  end;
catch,
  msgstr = lasterr;
  F = compute_F_cubic_spline(full_filename,el_pos,d,cond,cond_top,this_tol);
end;

function F = compute_F_cubic_spline(full_filename,el_pos,d,cond,cond_top,tol)
  % Define positions and constants
  N = length(el_pos);     %number of electrodes
  z_js = zeros(1,N+2);            %declare electrode positions included
  z_js(1,2:N+1) = el_pos(1,:);    %two imaginary, first electrode in z = 0
  h_av = sum(diff(el_pos))/(N-1); %average inter-contact distance
  z_js(1,N+2) = z_js(1,N+1)+h_av; %last imaginary electrode position

  [E0,E1,E2,E3] = compute_Ematrixes(el_pos);

  %   Define integration matrixes
  F0  = zeros(N,N+1);
  F1  = zeros(N,N+1);
  F2  = zeros(N,N+1);
  F3  = zeros(N,N+1);

  for j = 1:N            %rows
 %   progress = [num2str(j) ' of ' num2str(N) ': int. tolereance: ' num2str(tol)]
    for i = 1:N+1           %columns
      F0(j,i) = quad(@f0,z_js(i),z_js(i+1),tol,[],z_js(j+1),d,cond);
      F1(j,i) = quad(@f1,z_js(i),z_js(i+1),tol,[],z_js(j+1),z_js(i),d,cond);
      F2(j,i) = quad(@f2,z_js(i),z_js(i+1),tol,[],z_js(j+1),z_js(i),d,cond);
      F3(j,i) = quad(@f3,z_js(i),z_js(i+1),tol,[],z_js(j+1),z_js(i),d,cond);
      if cond ~= cond_top     %image technique if conductivity not constant
        F0(j,i) = F0(j,i) + (cond-cond_top)/(cond+cond_top) ...
            *quad(@f0,z_js(i),z_js(i+1),tol,[],-z_js(j+1),d,cond);
        F1(j,i) = F1(j,i) + (cond-cond_top)/(cond+cond_top) ...
            *quad(@f1,z_js(i),z_js(i+1),tol,[],-z_js(j+1),z_js(i),d,cond);
        F2(j,i) = F2(j,i) + (cond-cond_top)/(cond+cond_top) ...
            *quad(@f2,z_js(i),z_js(i+1),tol,[],-z_js(j+1),z_js(i),d,cond);
        F3(j,i) = F3(j,i) + (cond-cond_top)/(cond+cond_top) ...
            *quad(@f3,z_js(i),z_js(i+1),tol,[],-z_js(j+1),z_js(i),d,cond);
      end;
    end;
  end;

  temp_F = F0*E0+F1*E1+F2*E2+F3*E3;  %the F matrix, (N x N+2)

  %   Convert to (N+2xN+2) matrixes by applying the boundary I_0 = I_N+1 = 0.
  F = zeros(N+2);
  F(2:N+1,:) = temp_F(:,:);
  F(1,1) = 1;          %implies I_N+1 = Phi_N+1
  F(N+2,N+2) = 1;      %implies I_N+2 = Phi_N+2
  Fcs = F;
  save(full_filename, 'Fcs','tol');
return;

%Potential functions:
function out0 = f0(zeta,zj,diam,cond)
  out0 = 1./(2.*cond).*(sqrt((diam/2)^2+((zj-zeta)).^2)-abs(zj-zeta));
return;

function out1 = f1(zeta,zj,zi,diam,cond)
  out1 = (zeta-zi).*f0(zeta,zj,diam,cond);
return;

function out2 = f2(zeta,zj,zi,diam,cond)
  out2 = (zeta-zi).^2.*f0(zeta,zj,diam,cond);
return;

function out3 = f3(zeta,zj,zi,diam,cond)
  out3 = (zeta-zi).^3.*f0(zeta,zj,diam,cond);
return;