
%function FM_sweep_testing()
% close all;
clear all
clc

%---FLAGS---%
sub = 2;
% Setup sound parameters
AMdepth = 1;
AMrate = 32;
AMphase = 0;
StimulusDur = 1000;
NumCycles = 3;
dBSPL = 50;


% Define RCX file
handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Sandbox\JDY\AMRate_TemporalIntegration_buffer.rcx';


%Load in speaker calibration file
pn = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\';
fn = 'rig1012-CeilingB_Noise_Mar072016.cal';
fidx=1;
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select tone calibration file');
calfile = fullfile(pn,fn);

if ~fidx
    error('Error: No calibration file was found')
else
    handles.C = load(calfile,'-mat');
    calfiletype = strfind(func2str(handles.C.hdr.calfunc),'Noise');
end
if isempty(calfiletype)
    error('Error: Incorrect calibration file loaded')
end


%Open a figure for ActiveX control
handles.f1 = figure('Visible','off','Name','RPfig');

%Connect to the first module of the RZ6 ('GB' = optical gigabit connector)
handles.RP = actxcontrol('RPco.x','parent',handles.f1);

if handles.RP.ConnectRZ6('GB',1);
    disp 'Connected to RZ6'
else
    error('Error: Unable to connect to RZ6')
end

%Load the RPVds file (*.rco or *.rcx)
if handles.RP.LoadCOF(handles.RPfile);
    disp 'Circuit loaded successfully';
else
    error('Error: Unable to load RPVds circuit')
end


%Start the processing chain
if handles.RP.Run;
    disp 'Circuit is running'
else
    error('Error: circuit will not run')
end


%% RUN CIRCUIT

fs = handles.RP.GetSFreq;
% handles.RP.SetTagVal('fs', fs);

% % % 
% % % % Set param tags in circuit
handles.RP.SetTagVal('AMrate', AMrate);

handles.RP.SetTagVal('AMdepth',AMdepth);
handles.RP.SetTagVal('AMphase',AMphase);
% % % 
handles.RP.SetTagVal('dBSPL',dBSPL);
handles.RP.SetTagVal('StimulusDur',StimulusDur);
handles.RP.SetTagVal('Num_Cycles',NumCycles);

% Apply the voltage adjustment for level calibration in RPVds circuit
handles.RP.SetTagVal('~Cal_Amp',handles.C.data(1,4));
handles.RP.SetTagVal('~Cal_Norm',handles.C.hdr.cfg.ref.norm); %read norm value from cal file


% Set up buffer
bdur = 800/1000; %ms to sec
buffersize = ceil(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');
handles.RP.ZeroTag('rateBuf');


% !!! Trigger circuit !!!
handles.RP.SoftTrg(1);


pause(bdur+0.5); % wait for buffer to be filled

% Retrieve buffers
buffer = [];
buffer = handles.RP.ReadTagV('buffer',0,buffersize);
rateBuf = [];
rateBuf = handles.RP.ReadTagV('rateBuf',0,buffersize);

% Normalize baseline
buffer = buffer - mean(buffer);

% Plot buffers
figure(1)
subplot(2,1,sub)
[ax,h1,h2] = plotyy(1:buffersize,buffer,1:buffersize,rateBuf);
xlabel('Time (samples)')
set(h1,'Color','k');  set(ax(1),'YColor','k')
set(get(ax(1),'YLabel'),'String','Stimulus signal (V)')
ylim([-0.10 0.10])



%% Clear active X controls and stop processing chain

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
% close(handles.f1);

disp('Disconnected from RZ6')
%end
