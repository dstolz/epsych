function [X,fixedPoint] = checkDuration3(currentValue, Target, initBuffSize)
% [X,fixedPoint] = checkDuration3(currentValue, Target [initBuffSize])
%
%Takes in the current region number and adds it to a list of default size
%20. When the standard deviation of the list of values is < 1 then X = 1,
%otherwise X = 0.
% 
%
%Stephen Gordon 2016



persistent P i

if isnan(currentValue)
    X = 0;
    fixedPoint = 0;
    return
end

if isempty(P) || length(P) ~= initBuffSize
    P = randi(99,initBuffSize,1);
    i = 1;
end

if i > initBuffSize, i = 1; end

P(i) = currentValue(1);

fixedPoint = mean2(P);

i = i + 1;

if std2(P) < 1
    if abs(currentValue(2)) < 15
        if abs(fixedPoint - Target) < currentValue(3)
            X = 2;
        else
            X = 1;
        end
    else
        X = 0;
        P = randi(99,initBuffSize,1);
    end
else
    X = 0;
end