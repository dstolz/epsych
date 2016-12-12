function [X,fixedPoint] = checkDuration(currentValue, initBuffSize)
% [X,fixedPoint] = checkDuration(currentValue, [initBuffSize])
%
%Takes in the current region number and adds it to a list of default size
%20. When the list fills up with identical values X = 1.
% 
%
%Stephen Gordon 2016



persistent P i


if isnan(currentValue)
    currentValue = 99;
end

if nargin == 1
    initBuffSize = 15;
end

if isempty(P)
    P = zeros(initBuffSize,1);
    i = 1;
end
    
if i > initBuffSize, i = 1; end

P(i) = currentValue;
fixedPoint = P(i);
i = i + 1;
if currentValue > 0 && currentValue ~= 8 && currentValue ~= 99
    X = all(P==P(1));
else
    if currentValue == 99
        X = 1;
    else
        X = 0;
    end
end



