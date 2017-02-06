function [x, fixedPoint] = Left_Right_Choice(FASTRAK, tolerance)


x = 0;
fixedPoint = 0;
if abs(FASTRAK(5)) < 7
    return
end

x = 1;
if abs(FASTRAK(6)) < 15 
    if FASTRAK(5) > 0
        fixedPoint = 20;
    else
        fixedPoint = -20;
    end
else
    fixedPoint = 0;
end