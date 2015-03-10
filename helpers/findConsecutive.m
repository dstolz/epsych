function C = findConsecutive(ind,N)
% C = findConsecutive(y)
% C = findConsecutive(y,N)
% 
% Find consecutive values in a vector.
% 
% Inputs:
%   ind     logical vector
%   N       minimum number of consecutive ones to find in y (default = 2)
% 
% Outputs:
%   C       2xM matrix of the first and last indices of consecutive runs
%               of length N or greater of val
% 
% 
% ex:
%   ind = [1 0 0 1 1 1 1 0 0 1 1 0 1];
%   C = findConsecutive(ind);
% 
% ex:
%   % Find 3 or more consecutive "flips of a coin"
%   y = randi([-1 1],100,1);
%   ind = y == 1;
%   C = findConsecutive(ind, 3)
% 
% Daniel.Stolzberg@gmail.com 2015


narginchk(1,3);
if nargin < 2 || isempty(N), N = 2; end

C = [];
if ~any(ind), return; end

ind = ind(:);

dind = diff([false; ind; false]);

dpos = find(dind ==  1);
dneg = find(dind == -1);

d = dneg - dpos;
dind = d >= N;
C = [dpos(dind) dneg(dind)-1]';

