function s = startFastrak()

s = instrfind('Type','serial','Port','COM3','Tag','');
s = serial('COM3','BaudRate',115200);


fopen(s);

fprintf(s,'F');

end