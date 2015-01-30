function out = S_general(N,b0,b1)
%S = S_general(N,b0,b1)
%This is the three point filter matrix.
%Returns matrix of size (N-2)x(N),
%which represents a three point "spatial noise" filter with mid
%coeffescient b0 (will be normalized by the function) and neighbouring
%coeffescients b1 (will also be normalized).
%Default filter has b0 = 2 and b1 = 1 and number_of_electrodes = 20.
%
%The Hamming-filter has b0 = 0.54 and b1 = 0.23.

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

if nargin < 1, N = 20; end
if nargin < 3, b1 = 1; b0 = 2; end;

c = b0 + 2*b1;

out = zeros(N-2,N);
for i=1:N-2
    for j=1:N
        if (i == j-1)
            out(i,j) = b0/c;
        elseif (abs(i-j+1) == 1)
            out(i,j) = b1/c;
        end;
    end;
end;