function A = ArduinoConnect(varargin)
% A = ArduinoConnect
% 
% Connect to a USB Arduino microcontroller.
% 
% This function waits for the Arduino to print the character "R" to the
% serial bus.
% 
% BaudRate      ...     Connection baud rate (default = 57600)
% aName         ...     Connection name (default = 'Arduino-comPort', where
%                           comPort is an integer)
% comPort       ...     Set com port. If empty, or not specified, then
%                           a the Arduino board will be searched for and
%                           selected if available. (default = [])
%
% See also, ArduinoCom
% 
% Daniel.Stolzberg@gmail.com 2015



BaudRate = 57600;
comPort = [];
aName = [];
for i = 1:2:length(varargin)
    eval(sprintf('%s = %d;',varargin{i},varargin{i+1}));
end


if isempty(comPort)
    comPort = scanports;
end


if isempty(comPort)
    % no arduinos found
    A = [];
    return
end


if numel(comPort) > 1
    [s,ok] = listdlg('ListString',comPort,'SelectionMode','single', ...
        'PromptString','Select Arduino COM Port','ListSize',[160 150]);
    if ~ok, return; end
    comPort = comPort(s);
end
comPort = char(comPort);

fprintf('Connecting to Arduino on port: %s ...',comPort);

if isempty(aName), aName = sprintf('Arduino-%s',comPort); end

A = serial(comPort);
set(A,'DataBits',8,'StopBits',1,'BaudRate',BaudRate, ...
    'Parity','none','TimeOut',5,'Name',aName, ...
    'Tag','Arduino');

fopen(A);

timeout = 5;
t = tic;
while (fread(A,1,'uchar')~='R')
    pause(0.001);
    if toc(t) > timeout
        error('Unable to communicate with Arduino.')
    end
end

fprintf(' Connected\n');
