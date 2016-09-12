function X = checkFixate(FASTRAK, initBuffSize)
% [X,fixedPoint] = checkDuration(currentValue, [initBuffSize])
%
%Takes in the current region number and adds it to a list of default size
%20. When the list fills up with identical values X = 1.
% 
%
%Stephen Gordon 2016



persistent P i

X = 0;

if nargin == 1
    initBuffSize = 10;
end

if isempty(P)
    P = zeros(initBuffSize,1);
    i = 1;
end


if ((abs(FASTRAK(5)) < 5) && (abs(FASTRAK(6)) < 5))
    P(i) = 1;
else
    P(i) = 0;
end


if i > initBuffSize, i = 1; end


if P(i) == 1
    X = all(P==P(1));
else
    X = 0;
end
i = i + 1;