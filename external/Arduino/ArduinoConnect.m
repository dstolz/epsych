function A = ArduinoConnect
% A = ArduinoConnect
% 
% Connect to a USB Arduino microcontroller.
% 
% This function waits for the Arduino to print the character "R" to the
% serial bus.
% 
% See also, ArduinoCom
% 
% Daniel.Stolzberg@gmail.com 2015

comPort = scanports;

if isempty(comPort)
    % no arduinos found
    A = [];
    return

elseif numel(comPort) > 1
    [s,ok] = listdlg('ListString',comPort,'SelectionMode','single', ...
        'PromptString','Select Arduino COM Port','ListSize',[160 150]);
    if ~ok, return; end
    comPort = comPort(s);
end
comPort = char(comPort);

fprintf('Connecting to Arduino on port: %s ...',comPort);

A = serial(comPort);
set(A,'DataBits',8,'StopBits',1,'BaudRate',115200, ...
    'Parity','none','TimeOut',5,'Name',sprintf('Arduino-%s',comPort), ...
    'Tag','Arduino');

fopen(A);

timeout = 5;
start_time = clock;
while (fread(A,1,'uchar')~='R')
    pause(0.001);
    if etime(clock,start_time) > timeout
        error('Unable to communicate with Arduino.')
    end
end

fprintf(' Connected\n');
