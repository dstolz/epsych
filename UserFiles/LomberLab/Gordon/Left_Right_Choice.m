function [x, fixedPoint] = Left_Right_Choice(FASTRAK, tolerance)


x = 0;
fixedPoint = 0;
if abs(FASTRAK(5)) < 8
    return
end

x = 1;

if FASTRAK(5) > 0
    fixedPoint = 20;
else
    fixedPoint = -20;
end