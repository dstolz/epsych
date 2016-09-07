function X = checkFixate(currentValue, initBuffSize)
% [X,fixedPoint] = checkDuration(currentValue, [initBuffSize])
%
%Takes in the current region number and adds it to a list of default size
%20. When the list fills up with identical values X = 1.
% 
%
%Stephen Gordon 2016



persistent P i

X = 0;

if isnan(currentValue)
    currentValue = -1*randi(100);
end

if nargin == 1
    initBuffSize = 20;
end

if isempty(P)
    P = zeros(initBuffSize,1);
    i = 1;
end

if i > initBuffSize, i = 1; end

P(i) = currentValue;
i = i + 1;
if currentValue == 7
    X = all(P==P(1));
else
    X = 0;
end