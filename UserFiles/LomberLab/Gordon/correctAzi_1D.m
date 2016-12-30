function x = correctAzi_1D(FASTRAK)
% x = correctAzi(FASTRAK)
%Corrects azimuth based on translations of the head
% 
% See also pollFastrak2, pollFastrak_InTrial2
%
% Stephen Gordon 2016


x = FASTRAK;

sideA = FASTRAK(9);

if sideA < 1
    return
end

if FASTRAK(5) >= 0
    angleB = 90 + FASTRAK(5);
    angleA = asind(sideA*sind(angleB)/39.37);
else
    angleB = 90 - FASTRAK(5);
    angleA = -1*asind(sideA*sind(angleB)/39.37);
end

x(5) = FASTRAK(5) + angleA;