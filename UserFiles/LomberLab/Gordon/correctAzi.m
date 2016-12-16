function x = correctAzi(FASTRAK)
% x = correctAzi(FASTRAK)
%
% 
% See also pollFastrak2, pollFastrak_InTrial2
%
% Stephen Gordon 2016


x = FASTRAK;

x(5) = FASTRAK(5) + (atand(FASTRAK(9)/39.37)*cosd(x(5))) - (atand(FASTRAK(8)/39.37)*sind(x(5)));