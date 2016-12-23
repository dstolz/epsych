function x = correctAzi(FASTRAK)
% x = correctAzi(FASTRAK)
%Corrects azimuth based on translations of the head
% 
% See also pollFastrak2, pollFastrak_InTrial2
%
% Stephen Gordon 2016


x = FASTRAK;

%x(5) = FASTRAK(5) + (atand(FASTRAK(9)/39.37));



%angle2 = asind((FASTRAK(9)*sind(90+FASTRAK(5)))/39.37);
%x(5) = 90 - (180 - FASTRAK(5) - angle2);

sideB = 100;
sideA = sqrt(FASTRAK(9)^2 + FASTRAK(8)^2);

if sideA < 0.5
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