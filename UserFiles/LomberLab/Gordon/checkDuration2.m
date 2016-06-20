function [X,fixedPoint] = checkDuration2(currentValue, init)

persistent counter pastValue
X = 0;

if isempty(pastValue)
    counter = 0;
    pastValue = -1;
end

if pastValue == currentValue
    counter = counter + 1;
end

if counter > 20
    X = 1;
end

fixedPoint = currentValue;

end