function [out_zs,my_CSD] = make_cubic_splines(contact_positions,pot,Fcs,my_E0,my_E1,my_E2,my_E3,num_out_zs)
%[out_zs,my_CSD] = make_cubic_splines(contact_positions,pot,Fcs,...
%my_E0,my_E1,my_E2,my_E3,num_out_zs)
%
%Makes the cubic spline function(s).
%
%contact_positions: contact positions
%pot: measured potentials
%Fcs: the cubic spline transformation matrix corresponding to the given
%contact positions
%my_E0,...,my_E3: the matrixes containing the "recursive rules", see paper
%appendix
%num_out_zs: number of out-parameters
%
%Arguments 4 to 8 are optional:
% if nargin<8; num_out_zs = 200; end;
% if nargin<4; %compute E matrixes
%     [my_E0,my_E1,my_E2,my_E3] = compute_Ematrixes(contact_positions);
% end;

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

if nargin<8; num_out_zs = 200; end;
if nargin<4; %compute E matrixes
    [my_E0,my_E1,my_E2,my_E3] = compute_Ematrixes(contact_positions);
end;

%Cubic spline method
[N,num_of_timesteps] = size(pot);
cs_pot = zeros(N+2,num_of_timesteps);
cs_pot(2:N+1,:) = pot(:,:);    % Phi_1 = Phi_N+2 = 0

CSD_coeff = Fcs^(-1)*cs_pot;

%The cubic spline polynomial coeffescients
A0 = my_E0*CSD_coeff;
A1 = my_E1*CSD_coeff;
A2 = my_E2*CSD_coeff;
A3 = my_E3*CSD_coeff;

h = mean(diff(contact_positions));
el_pos_with_ends = zeros(1,length(contact_positions));
el_pos_with_ends(1,1) = 0;
el_pos_with_ends(2:N+1) = contact_positions(1:N);
el_pos_with_ends(1,N+2) = contact_positions(N)+h;

out_zs = el_pos_with_ends(1):(el_pos_with_ends(N+2)-el_pos_with_ends(1))/(num_out_zs-1):el_pos_with_ends(N+2);
i = 1;
for j=1:length(out_zs)
  if out_zs(j)>el_pos_with_ends(i+1)
      i=i+1;
  end;
   my_CSD(j,:) = A0(i,:) + A1(i,:).*(out_zs(j)-el_pos_with_ends(i)) + ...
        A2(i,:)*(out_zs(j)-el_pos_with_ends(i)).^2 + A3(i,:)*(out_zs(j)-el_pos_with_ends(i)).^3;
end;