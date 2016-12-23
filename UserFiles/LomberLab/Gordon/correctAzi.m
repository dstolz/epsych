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



angleB = 90 + atand(FASTRAK(8)/FASTRAK(9)) + FASTRAK(5);
sideB = 39.37;
sideA = sqrt(FASTRAK(9)^2 + FASTRAK(8)^2);
angleA = asind(sideA*sind(angleB)/sideB);
if sideA < 0.5
    return
else
    %x(5) = 90 - atand(FASTRAK(8)/FASTRAK(9)) + (180 - angleA - angleB);
    %x(5) = 90 - atand(FASTRAK(8)/FASTRAK(9)) - angleA - angleB;
    if FASTRAK(9) >= 0
        x(5) = FASTRAK(5) + angleA;
    else
        x(5) = FASTRAK(5) - angleA;
    end
end