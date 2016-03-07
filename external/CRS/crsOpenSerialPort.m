function s1 = crsOpenSerialPort(deviceName, mode, portNumber)
% handle = crsOpenSerialPort(deviceName, mode, portNumber)
%
% Opens the USB CDC virtual serial port to deviceName and returns the
% object handle.
%
% Supported deviceName types are: Bits#, BlueGain, BOLDscreen, ColorCAL,
% Display++, LM1, LiveTrack, SpectroCAL, Visage
% 
% If the optional parameter mode is 1 the MATLAB build-in function serial 
% is used (default). If mode is 2 the faster function IOPort from 
% Psychtoolbox (http://psychtoolbox.org/) is used.
%
% The optional parameter portNumber can be specified to avoid a possible
% time consuming process of searching for it.
%
% Example:
%
% s1 = crsOpenSerialPort('Bits#',1)
%
% History:
% 02/14 JT
% 07/14 SRE

if nargin==0,
    error('Please specify deviceName input parameter');
elseif nargin>0,
    if strcmpi(deviceName,'Bits#'),   
        deviceName = 'Bits#';
    elseif strcmpi(deviceName,'BlueGain'),
        deviceName = 'BlueGain';
    elseif strcmpi(deviceName,'BOLDscreen'),
        deviceName = 'BOLDscreen';
    elseif strcmpi(deviceName,'ColorCal') || strcmpi(deviceName,'ColourCal') || strcmpi(deviceName,'ColourCAL'),    
        deviceName = 'ColorCal';
    elseif strcmpi(deviceName,'Display++'),
        deviceName = 'Display++';
    elseif strcmpi(deviceName,'LiveTrack'),         
        deviceName = 'LiveTrack';
    elseif strcmpi(deviceName,'LM1'),         
        deviceName = 'LM1';
    elseif strcmpi(deviceName,'SpectroCAL'),
        deviceName = 'SpectroCal';
    elseif strcmpi(deviceName,'Visage'),   
        deviceName = 'Visage';
    else
        error('Please specify correct input parameter: Bits#, BlueGain, BOLDscreen, ColorCAL, Display++, LM1, LiveTrack, SpectroCAL, Visage');
    end
end

if nargin==1,
    mode = 1; % default to use MATLAB build-in function "serial"
end

% If mode is 1 use the port handle could already have been created. If it 
% was created with this function it will contain a "tag" with the name of
% the device. If it exists use that port.
if mode==1,
    portlist = instrfindall('Type', 'serial');
    if ~isempty(portlist),
        for i=1:length(portlist),
            if strcmp(portlist(i).Tag,deviceName),
                portName = portlist(i).Port;
                try
                    fclose(portlist(i));
                    fopen(portlist(i));
                    disp(['Found ',deviceName,' on port ',portName,' (previously created object).']);
                    s1 = portlist(i);
                    return 
                catch ME
                    disp(['Found a port object tagged ',deviceName,' on']);
                    disp(['port ',portName,' but could not open it.']);
                    disp('Is it still connected and turned on?');
                    rethrow(ME);
                end
            end
        end
    end
end

% Could not find previously created object, so create a new.
if nargin<3,
    disp('portNumber parameter not specified. Will try to search for it.');
    disp('Consider specifying the correct port manually to speed things up.');
    disp('You can find the port in Device Manager in Windows or in the /dev');
    disp('folder on Mac and Unix.');
    portNumber = crsFindSerialPort(deviceName);
end

if mode==1,
    if strcmpi(deviceName,'SpectroCAL'),
        s1 = serial(portNumber,'Tag',deviceName, 'BaudRate', 921600, 'Terminator', 'CR');
        s1.InputBufferSize = 16000;
        disp('Using SpectroCAL');
    else
        s1 = serial(portNumber,'Tag',deviceName);
        s1.InputBufferSize = 4096;
    end
    % serial defaults to a buffer size of 512 so make it bigger so that it
    % can contain a full packet from BlueGain(250 samples)
    fopen(s1);
elseif mode==2,
    [s1 , errmsg] = IOPort('OpenSerialPort', portNumber, 'Lenient');
    disp('Opened port with IOPort');
    % IOPort defaults to a buffer size of 4096
    if ~isempty(errmsg),
        error(errmsg);
    end
end

    