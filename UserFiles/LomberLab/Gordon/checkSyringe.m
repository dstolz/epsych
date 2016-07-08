function foodRemain = checkSyringe(motorBox)

fwrite(motorBox,1);
readIn = fscanf(motorBox);
%potValue = str2int(readIn(1))*100 + str2int(readIn(2))*10 + str2int(readIn(3))
potValue = str2num(readIn);
%if potValue < 212
%    foodRemain = sprintf('%0.2f', 60);
%else
    foodRemain = 60 - ((potValue - 212)/5.8);
%end
