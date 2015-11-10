%% Calibration Testing

clear all

%handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Cal_wave_test.rcx';
handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\FM_sweep_test.rcx';

%Load in speaker calibration file
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
fidx=1;
pn = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\';
fn = '983Floor_PureToneCalibration_Oct27_2015.cal';
calfile = fullfile(pn,fn);

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

%Set up buffer
bdur = 5; %sec
fs = handles.RP.GetSFreq;

buffersize = floor(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');

%Set desired sound parameters
fq = 1000;
dB = 10;
FMDepth = 0;
FMRate = 0;
handles.RP.SetTagVal('Freq',fq);
handles.RP.SetTagVal('dBSPL',dB);
handles.RP.SetTagVal('FMdepth',FMDepth);
handles.RP.SetTagVal('FMrate',FMRate);

%% RUN CIRCUIT 
figure(2); clf;

%Trigger buffer
handles.RP.SoftTrg(1);

%Wait for buffer to be filled
pause(bdur+0.01);

%Retrieve buffer
buffer = handles.RP.ReadTagV('buffer',0,buffersize);

%Normalize baseline
buffernorm = buffer - mean(buffer);

%Plot buffer
figure(2);
xmax = size(buffer,2)/fs;
x = linspace(0,xmax,size(buffer,2));
hold on
plot(x,buffer,'Color','r')
set(gca,'xlim',[0 1]);