
function FMdepth_detection()
clear all; clc; close all;

handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\FM_sweep_test.rcx';

%Load in speaker calibration file
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
fidx=1;
pn = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\';
fn = 'rig1012-CeilingA-Cal_c_Jan062016.cal';
% fn = '983Booth_FloorSpeaker_PureToneCalibration_Jul06_2015_new.cal';
calfile = fullfile(pn,fn);

if ~fidx
    error('Error: No calibration file was found')
else
    handles.C = load(calfile,'-mat');
    calfiletype_tone = strfind(func2str(handles.C.hdr.calfunc),'Tone');
    
end

%We want tone calibration file
if isempty(calfiletype_tone)
    error('Error: Incorrect calibration file loaded')
end
handles.freq_flag = 1;


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

pause(9);

%Set desired sound level (dB SPL)
level = 65; 
handles.RP.SetTagVal('dBSPL',level);

%Set desired sound duration (ms)
duration = 300;%ms
handles.RP.SetTagVal('Duration',duration);

%Set up buffer
bdur = 0.6; %sec
fs = handles.RP.GetSFreq;
buffersize = floor(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');


FMdepths = -1*[0 0 0 0:0.0035:0.0595];
% FMdepths = [0.04 0.025 0.02 0.015];

startFq = [6000];

stim_idx = randperm(numel(FMdepths));

plot_colors = jet(numel(FMdepths)*numel(startFq));
idx=0;
for ifq = 1:numel(startFq)
%     figure(ifq); hold on
    
    %set start fq in rpvds
    handles.RP.SetTagVal('Freq',startFq(ifq));

    for id = stim_idx
        %Check that frequency won't go out of speaker range
        if ((startFq(ifq)*FMdepths(id) + startFq(ifq)) < 100) || ((startFq(ifq)*FMdepths(id) + startFq(ifq)) > 20000)
            warning('Skipped stimulus with end frequency out of range')
            continue
        end
        idx = idx+1;
        
        %Set stim params
        handles.RP.SetTagVal('FMdepth',FMdepths(id));
        
        %Trigger buffer
        handles.RP.SoftTrg(1);
        
        %Wait for buffer to be filled
        pause(bdur+0.1);
        
        %Retrieve buffer
        buffer = handles.RP.ReadTagV('buffer',0,buffersize);
        
        %Normalize baseline
        buffer = buffer - mean(buffer(1:60));
        
        %Plot buffer
%         plot(buffer,'Color',plot_colors{id})
%         set(gca,'xlim',[0 5000]);
        
        %Save signal from buffer
        Sound(idx).Freq1    = startFq(ifq);
        Sound(idx).FMdepth  = FMdepths(id);
        Sound(idx).duration = duration;
        Sound(idx).signal   = buffer;
        Sound(idx).fs       = fs;
        
        buffer = [];
        pause(1)
        
    end %for it ... depths
    hold off
end % for ifq ... start fqs

FMdepths(stim_idx)



%% Clear active X controls and stop processing chain

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);

disp('Disconnected from RZ6')

end %function



