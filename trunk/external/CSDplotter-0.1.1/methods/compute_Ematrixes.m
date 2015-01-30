function [E0,E1,E2,E3] = compute_Ematrixes(el_pos)
%function [E0,E1,E2,E3] = compute_Ematrixes(el_pos)
%
%Computes the E0, E1, E2 and E3 matrixes used in the cubic spline iCSD
%method. These matrixes contains the recursive formulas for finding the F
%matrix (see paper appendix).

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

  N = length(el_pos);
  z_js = zeros(1,N+2);            %declare electrode positions included ...
  z_js(1,2:N+1) = el_pos(1,:);    %two imaginary, first electrode in z = 0.
  h_av = sum(diff(el_pos))/(N-1); %average inter-contact distance
  z_js(1,N+2) = z_js(1,N+1)+h_av; %last imaginary electrode position

  C_vec = 1./diff(z_js);          %length: N+1
  % Define transformation matrixes
  C_jm1 = zeros(N+2);
  C_j0 = zeros(N+2);
  C_jall = zeros(N+2);
  C_mat3 = zeros(N+1);

  for i=1:N+1
    for j=1:N+1
      if i == j
        C_jm1(i+1,j+1) = C_vec(i);
        C_j0(i,j) = C_jm1(i+1,j+1);
        C_mat3(i,j) = C_vec(i);
      end;
    end;
  end;
  C_jm1(N+2,N+2) = 0;

  C_jall = C_j0;
  C_jall(1,1) = 1;
  C_jall(N+2,N+2) = 1;

  C_j0(1,1) = 0;

  Tjp1 = zeros(N+2);         %converting an element k_j to k_j+1
  Tjm1 = zeros(N+2);         %converting an element k_j to k_j-1
  Tj0  = eye(N+2);
  Tj0(1,1) = 0;
  Tj0(N+2,N+2) = 0;

  %C to K
  for i=2:N+2
    for j=1:N+2
      if i==j-1
        Tjp1(i,j) = 1;
      end;
      if i==j+1
        Tjm1(i,j) = 1;
      end;
    end;
  end;


  % C to K transformation matrix
  K = (C_jm1*Tjm1+2*C_jm1*Tj0+2*C_jall+C_j0*Tjp1)^(-1)*3*...
    (C_jm1^2*Tj0-C_jm1^2*Tjm1+C_j0^2*Tjp1-C_j0^2*Tj0);

  %   Define matrixes for C to A transformation
  Tja  = zeros(N+1,N+2);      %identity matrix except that it cuts off last elenent
  Tjp1a  = zeros(N+1,N+2);    %converting k_j to k_j+1 and cutting off last element


  %C to A
  for i=1:N+1
    for j=1:N+2
      if i==j-1
        Tjp1a(i,j) = 1;
      end;
      if i==j
        Tja(i,j) = 1;
      end;
    end;
  end;


  %   Define spline coeffiscients
  E0  = Tja;    
  E1  = Tja*K; 
  E2  = 3*C_mat3^2*(Tjp1a-Tja)-C_mat3*(Tjp1a+2*Tja)*K;
  E3  = 2*C_mat3^3*(Tja-Tjp1a)+C_mat3^2*(Tjp1a+Tja)*K;
