function portName = crsFindSerialPort(deviceName)
% crsFindSerialPort
% Searches for a USB CDC virtual serial port connected to deviceName
%
% Usage:
% portName = crsFindSerialPort(deviceName)
%
% deviceName must be one: Bits#, BlueGain, BOLDscreen, ColorCAL,
% SpectroCAL, Display++ or LiveTrack
%
% Example:
% portName = crsFindSerialPort('Bits#');
%
% History:
% 02/14 JT
% 07/14 SRE

if nargin==0,
    error('Please specify deviceName input parameter');
elseif nargin==1,
    if strcmpi(deviceName,'Bits#'),
        command = ['$ProductType' 13];
        response = 'Bits';
        deviceName = 'Bits#';
    elseif strcmpi(deviceName,'BlueGain'),
        command = [192 'S' 192];        % command to send to the device
        response = 'Formatted status';  % response to look for
        deviceName = 'BlueGain';
    elseif strcmpi(deviceName,'BOLDscreen'),
        command = ['$ProductType' 13];
        response = 'BOLDscreen';
        deviceName = 'BOLDscreen';
    elseif strcmpi(deviceName,'ColorCal') || strcmpi(deviceName,'ColourCal')  || strcmpi(deviceName,'ColorCAL'),
        command = ['?' 13];
        response = 'ColorCal';
        deviceName = 'ColorCal';
    elseif strcmpi(deviceName,'Display++'),
        command = ['$ProductType' 13];
        response = 'Display++';
        deviceName = 'Display++';
    elseif strcmpi(deviceName,'LiveTrack'),
        command = ['$ProductType' 13];
        response = 'LiveTrack';
        deviceName = 'LiveTrack';
    elseif strcmpi(deviceName,'LM1'),
        command = ['$ProductType' 13];
        response = 'Light Meter 1';
        deviceName = 'LM1';
    elseif strcmpi(deviceName,'SpectroCAL'),
        command = ['*PARA:WAVBEG?' 13];
        response = 'Predefined start wave:';
        deviceName = 'SpectroCal';
    elseif strcmpi(deviceName,'Visage'),
        command = ['$ProductType' 13];
        response = 'Visage';
        deviceName = 'Visage';
    else
        error('Please specify correct input parameter: BlueGain, LiveTrack, LM1 or Bits#');
    end
end

% initialise the port name to empty
portName = [];

% Check if a port object with the tag deviceName has already been created.
% If true, close all ports of that device. Safe the name of the last found.
portlist = instrfindall('Type', 'serial');
if ~isempty(portlist),
    for i=1:length(portlist),
        if strcmp(portlist(i).Tag,deviceName),
            portName = portlist(i).Port;
            try
                fclose(portlist(i));
                fopen(portlist(i));
                fclose(portlist(i));
            catch ME
                disp(['Found a port object tagged ',deviceName,' on']);
                disp(['port ',portName,' but could not open it.']);
                disp('Is it still connected and turned on?');
                portName = [];
                rethrow(ME);
            end
            delete(portlist(i));
        end
    end
end

% Return the port name if found.
if ~isempty(portName),
    disp(['Found ',deviceName,' on port ',portName,' (previously created object).']);
    return
end

% Try all avaiable serial ports and check if any responds to the command.
% The way to get the avaialble ports is system dependant so do this
% differently for Windows, Mac and UNIX

% If system is Windows
if ispc
    % provoke an error to get a message that tells which ports are available
    try
        s1 = serial(' ');
        fopen(s1);
    catch ME
        delete(s1);
        errmsg = ME.message;
    end
    
    % check if any ports are available
    if isempty(strfind(errmsg,'COM')),
        % if not try all ports
        portName = tryAllCOMports(command, response, deviceName);
        return
    end
    
    % find first index of each port name in the string
    tmp = strfind(errmsg,',');
    tmp2 = strfind(errmsg,':');
    I = [tmp2(end) tmp]+2;
    
    % find the last index of each port name
    tmp3 = strfind(errmsg,'.');
    I2 = [tmp tmp3(2)]-1;
    
    % generate a cell array with the port names
    for i=1:length(I),
        portNames{i} = errmsg(I(i):I2(i)); %#ok<AGROW>
    end
    
    % If system is Mac OS X or UNIX
elseif ismac || isunix,
    if ismac
        % list of possible candidates
        names = dir('/dev/cu.usb*');
    elseif isunix,
        % list of possible candidates
        names = dir('/dev/ttyACM*');
    end
    
    % check if any ports are available
    if size(names,1)==0,
        error(['Could not find any serial ports/n',...
            'Is it connected?'])
    end
    
    % generate a cell array with the port names
    for i=1:length(names),
        portNames{i} = ['/dev/' names(i).name]; %#ok<AGROW>
    end
    
else
    error('Could not determine the operating system.')
end

% check all the ports if any responds to the command
portName = checkPorts(portNames, command, response, deviceName);

% if not found give an error message
if isempty(portName),
    if ispc,
        % if the device was connected after opening MATLAB it does not
        % appear as avaiable but can nevertheless be accessed. Run
        % through all possible ports in this case. This only applies to
        % Windows since for Mac and Linux the port list is found in the
        % /dev directory.
        portName = tryAllCOMports(command, response, deviceName);
        return
    end
    error(['Could not find any serial ports which responds to deviceType ',deviceName,'. Is it connected?'])
end

end

function portName = tryAllCOMports(command, response, deviceName)
disp('Could not find an easy way to find the port. Will now try all');
disp('possible port addresses...');
for i=1:256, % use 256 here for all possible ports
    portNames{i} = (['COM',num2str(i)]); %#ok<AGROW>
end
portName = checkPorts(portNames, command, response, deviceName);
if isempty(portName),
    error(['Could not find any serial ports which responds to deviceType ',deviceName,'. Is it connected?'])
end
end

function portName = checkPorts(portNames, command, response, deviceName)
portName = [];

for u=1:length(portNames)
    fprintf(['Trying to open port ',portNames{u},'...']);
    
    % create a serial port object
    if strcmpi(deviceName,'SpectroCal'),
        s1 = serial(portNames{u}, 'BaudRate', 921600, 'Terminator', 'CR'); %#ok<TNMLP>
    else
        s1 = serial(portNames{u});  %#ok<TNMLP>
    end
    
    
    try
        fclose(s1);
        fopen(s1);
    catch ME  %#ok<NASGU>
        fprintf('Could not open.\n');
        delete(s1);
        continue % restart loop
    end
    
    pause(0.1);
    
    try
        % if the device is Bits#, BOLDscreen, Display++ or LiveTrack
        % make sure data streaming is stopped
        if s1.BytesAvailable>0 &&...
                (strcmp(deviceName,'Bits#') || strcmp(deviceName,'BOLDscreen')) ||...
                (strcmp(deviceName,'Display++') || strcmp(deviceName,'LiveTrack')),
            fprintf(s1, ['#Stop' 13]);
        end
        
        % flush the serial port buffer
        while s1.BytesAvailable>0
            fread(s1,s1.BytesAvailable);
            pause(0.01);
        end
        
        % send command
        fprintf(s1,command);
        
        % wait for a response
        pause(0.5);
        
        if s1.BytesAvailable > 0
            string1 = char(fread(s1,s1.BytesAvailable)');
            if ~isempty(strfind(string1,response))
                portName = portNames{u};
                fprintf(['Found ',deviceName,' on port ',portName,'\n']);
                fclose(s1);
                delete(s1);
                if strcmp(deviceName,'BlueGain'),
                    tmp = strfind(string1,'Battery voltage');
                    BatteryVoltage = str2double(string1(tmp+18:tmp+21));
                    fprintf(['BlueGain battery voltage is ',num2str(BatteryVoltage),'mV\n']);
                    if BatteryVoltage<2900,
                        warndlg(sprintf(['BlueGain battery is low (',num2str(BatteryVoltage),'mV)\nConsider replacing the batteries before use\nto avoid interupt in experiment.']))
                    end
                end
                break;
            end
            fprintf([string1,' - wrong response\n']);
            fclose(s1);
            delete(s1);
        else
            fprintf('no response.\n');
            fclose(s1);
            delete(s1);
        end
    catch
        fprintf('failed.\n');
        fclose(s1);
        delete(s1);
        continue
        
    end
end

end