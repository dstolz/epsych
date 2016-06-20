function [X,fixedPoint] = checkDuration(currentValue, init)

persistent P i

X = 0;

if nargin == 1
    init = 20;
end

if isempty(P)
    P = zeros(init,1);
    i = 0;
end

i = i + 1;
if i > 20, i = 1; end

P(i) = currentValue;

X = all(P==P(1));
fixedPoint = P(i);
end
