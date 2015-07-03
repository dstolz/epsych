function C = findConsecutive(ind,N,g)
% C = findConsecutive(y)
% C = findConsecutive(y,N)
% C = findConsecutive(y,N,g)
% 
% Find consecutive values in a vector.
% 
% Inputs:
%   ind     logical vector
%   N       minimum number of consecutive ones to find in y (default = 2)
%   g       forgive a maximum of g consecutive zeros in y (optional)
%
% Outputs:
%   C       2xM matrix of the first and last indices of consecutive runs
%               of length N or greater of val
% 
% 
% ex:
%   ind = [1 0 0 1 1 1 1 0 0 1 1 0 1];
%   C = findConsecutive(ind,2);
%   C =
%       4    10
%       7    11
% 
% ex:
%   ind = [1 0 0 1 1 1 1 0 0 1 1 0 1];
%   C = findConsecutive(ind,2,1);
%   C =
%       4    10
%       7    13
% 
% ex:
%   % Find 3 or more consecutive values greater than 0
%   ind = randn(100,1) > 0;
%   C = findConsecutive(ind, 3)
% 
% ex:
%   % Find 3 or more consecutive values greater than 0 forgiving 1
%   % intervening 0
%   ind = randn(100,1) > 0;
%   C = findConsecutive(ind, 3,1)
% 
% Daniel.Stolzberg@gmail.com 2015


% narginchk(1,3);
if nargin < 2 || isempty(N), N = 2; end

C = [];
if ~any(ind), return; end

ind = ind(:);

if nargin == 3
    dind = diff([false; ~ind; false]);
    Cg = findC(dind,g);
    iCg = diff(Cg) >= g;
    Cg(:,iCg) = [];
    for i = 1:size(Cg,2)
        ind(Cg(1,i):Cg(2,i)) = true;
    end
end

dind = diff([false; ind; false]);
C = findC(dind,N);


function C = findC(dind,N)
dpos = find(dind ==  1);
dneg = find(dind == -1);

d = dneg - dpos;
dind = d >= N;
C = [dpos(dind) dneg(dind)-1]';












