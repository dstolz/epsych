function [X,fixedPoint] = checkDuration2(currentValue, Target, initBuffSize)
% [X,fixedPoint] = checkDuration2(currentValue, Target [initBuffSize])
%
%Takes in the current region number and adds it to a list of default size
%20. When the list fills up with identical values X = 1.
% 
%
%Stephen Gordon 2016



persistent P i

if isnan(currentValue)
    X = 0;
    return
end

if isempty(P) || length(P) ~= initBuffSize
    P = zeros(initBuffSize,1);
    i = 1;
end

if i > initBuffSize, i = 1; end

if abs(currentValue(1) - Target) < currentValue(3)
    P(i) = Target;
else
    P(i) = currentValue(1);
end
fixedPoint = P(i);
i = i + 1;


if abs(currentValue(2)) < 10
    X = all(P==P(1));
else
    X = 0;
    P = zeros(initBuffSize,1);
end