function X = checkFixate3(x, initBuffSize, Tol)

persistent P i

if abs(x(1)) < Tol && abs(x(2)) < 5
    currentValue = 8;
else
    currentValue = 0;
end

if isempty(P) || length(P) ~= initBuffSize
    P = randi(99,initBuffSize,1);
    i = 1;
end

if i > initBuffSize, i = 1; end

P(i) = currentValue;
i = i + 1;
if currentValue == 8
    X = all(P==P(1));
else
    X = 0;
end
