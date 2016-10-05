function foodRemain = checkSyringe(motorBox)
%Pot value at which the syringe is empty
noFood = 550;
%Pot value at which the syringe is at 60mL
fullSyringe = 280;
%Range of pot values that covers 0-60mL
syringeRange = 270;

fwrite(motorBox,1);
readIn = fscanf(motorBox);
%potValue = str2int(readIn(1))*100 + str2int(readIn(2))*10 + str2int(readIn(3))
potValue = str2num(readIn);
foodRemain = 60 - (potValue - fullSyringe)/(syringeRange/60);

