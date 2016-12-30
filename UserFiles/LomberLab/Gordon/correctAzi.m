function x = correctAzi(FASTRAK)
% x = correctAzi(FASTRAK)
%Corrects azimuth based on translations of the head
% 
% See also pollFastrak2, pollFastrak_InTrial2
%
% Stephen Gordon 2016


x = FASTRAK;

sideB = 100;
sideA = sqrt(FASTRAK(9)^2 + FASTRAK(8)^2);

if sideA < 0.5 || abs(atand(FASTRAK(9)/FASTRAK(8)) - FASTRAK(5)) < 1
    return
end

if (FASTRAK(5) >= 0 && FASTRAK(9) >= 0) || (FASTRAK(5) < 0 && FASTRAK(9) < 0)
    angleB = 90 + atand(FASTRAK(8)/FASTRAK(9)) + FASTRAK(5);
    angleA = asind(sideA*sind(angleB)/sideB);
else
    angleB = 90 + atand(FASTRAK(8)/FASTRAK(9)) - FASTRAK(5);
    angleA = -1*asind(sideA*sind(angleB)/sideB);
end

x(5) = FASTRAK(5) + angleA;