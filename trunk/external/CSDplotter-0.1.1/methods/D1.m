function out = D1(N,h)
%function out = D1(N,h)
%
%The matrix form of the standard double derivative formula, called D1 in
%Freeman and Nicholson (1975).
%
%N: number of electrodes
%h: inter-contact distance.
%
%out is a (N-2)x(N) matrix.

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

if nargin < 2, h = 100e-6 ;end;
if nargin < 1, N = 20 ;end;

for i=1:N-2
    for j=1:N
        if (i == j-1)
            out(i,j) = -2/h^2;
        elseif (abs(i-j+1) == 1)
            out(i,j) = 1/h^2;
        else
            out(i,j) = 0;
        end;
    end;
end;