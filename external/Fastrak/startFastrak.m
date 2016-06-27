function s = startFastrak(port)

if nargin == 0, port = 'COM3'; end

s = instrfind('Type','serial','Port',port,'Tag','');
s = serial(port,'BaudRate',115200);


fopen(s);

fprintf(s,'F');

end