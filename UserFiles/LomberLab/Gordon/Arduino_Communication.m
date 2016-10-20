s = serial('COM5');
set(s,'BaudRate',9600);
fopen(s);
fwrite(s,1);
foodPot = fscanf(s);
fclose(s)
delete(s)
clear s