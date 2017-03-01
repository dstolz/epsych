
%function FM_sweep_testing()
% close all;


% Define RCX file
% handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Sandbox\KP\AM_jitter_Macro_DurTest.rcx';
handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Sandbox\KP\AM_jitter_Macro_DurTest_180shft.rcx';


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

% Setup sound parameters
AMrate = 4;
AMdepth = 0.75;

AMphase = 0;

dBSPL = 50;
HP = 100;
LP = 20000;
Duration = 7500; %ms


%Load desired rateVector MAT file
[fn,pn,fidx] = uigetfile('D:\stim\AMjitter\AM_4Hz_final\*.mat','Select stimulus buffer file');
load(fullfile(pn,fn))
rateVector = buffer;

%%
% Load data to SerSource component
handles.RP.ZeroTag('rateVec');
handles.RP.WriteTagV('rateVec',0,rateVector);
handles.RP.SetTagVal('~rateVec_size', numel(rateVector));

% Set param tags in circuit
handles.RP.SetTagVal('AMrate', AMrate);
handles.RP.SetTagVal('AMdepth',AMdepth);
%     handles.RP.SetTagVal('AMphase',AMphase);
%     handles.RP.SetTagVal('AMdelay',AMdelay);
handles.RP.SetTagVal('HP',HP);
handles.RP.SetTagVal('LP',LP);
handles.RP.SetTagVal('dBSPL',dBSPL);
handles.RP.SetTagVal('Duration',Duration);


% Apply the voltage adjustment for level calibration in RPVds circuit
handles.RP.SetTagVal('~Cal_Amp',handles.C.data(1,4));
handles.RP.SetTagVal('~Cal_Norm',handles.C.hdr.cfg.ref.norm); %read norm value from cal file


% Set up buffer
bdur = Duration/1000; %ms to sec
buffersize = ceil(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');
handles.RP.ZeroTag('rateBuf');


% !!! Trigger circuit !!!
handles.RP.SoftTrg(1);


pause(bdur+0.5); % wait for buffer to be filled


% Retrieve buffers
buffOUT = [];
buffOUT = handles.RP.ReadTagV('buffer',0,buffersize);
rateBuf = [];
rateBuf = handles.RP.ReadTagV('rateBuf',0,buffersize);

% Normalize baseline
buffOUT = buffOUT - mean(buffOUT);

% Plot buffers
figure;
[ax,h1,h2] = plotyy((1:buffersize)/fs*1000,buffOUT,(1:buffersize)/fs*1000,rateBuf);
xlabel('Time (ms)')
set(h1,'Color','k');  set(ax(1),'YColor','k')
set(get(ax(1),'YLabel'),'String','Stimulus signal (V)')
set(h2,'Color','r');  set(ax(2),'YColor','r')
set(get(ax(2),'YLabel'),'String','instantaneous AM rate (Hz)')
title(fn)




%% Clear active X controls and stop processing chain

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);

disp('Disconnected from RZ6')
%end
