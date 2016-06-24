
%function FM_sweep_testing()
close all;

handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\circuit_wav_stim_wav.rcx';

% handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\FM_sweep_test_manualcircuit.rcx';


%Load in speaker calibration file
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
fidx=1;
pn = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\';
% fn = 'Ceiling_PureToneCalibration_Dec92015.cal';
% fn = '983Booth_FloorSpeaker_PureToneCalibration_Jul06_2015_new.cal';
fn = 'rig1012-CeilingB_PureTone_limited7mV_iv_Mar072016.cal';
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select tone calibration file');
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

% pause(5) 



%Set desired sound level (dB SPL)
level = 65; 
handles.RP.SetTagVal('dBSPL',level);

%Set desired sound dynamics (in ms)
% stimulus_duration = 600;%ms
% handles.RP.SetTagVal('StimDur',stimulus_duration);

for iWAV=0:2
%Select sound file(s)
handles.RP.SetTagVal('chooseWAV',iWAV);


%Set up buffer
bdur = 5; %ms to sec
fs = handles.RP.GetSFreq;
buffersize = floor(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');


%Trigger buffer
handles.RP.SoftTrg(1);

%Wait for buffer to be filled
pause(bdur+0.1);

%Retrieve buffer
buffer = [];
buffer = handles.RP.ReadTagV('buffer',0,buffersize);

%Normalize baseline
buffer = buffer - mean(buffer(1:60));

%Plot buffer
%         plot(buffer,'Color',plot_colors{id})
%         set(gca,'xlim',[0 5000]);

%Save signal from buffer
%         Sound(idx).Freq1    = StartFreq(ifq);
%         Sound(idx).FMdepth  = FMdepths(id);
%         Sound(idx).duration = stimulus_duration;
%         Sound(idx).signal   = buffer;
%         Sound(idx).fs       = fs;
%
%         figure;
%         plot(buffer)
%
%         %Convert signal to frequency domain
%         fft_buffer = fft(buffer);
%         P2 = abs(fft_buffer/size(buffer,2));
%         P1 = P2(1:size(buffer,2)/2+1);
%         P1(2:end-1) = 2*P1(2:end-1);
%
%         frequency = fs*(0:(size(buffer,2)/2))/size(buffer,2);
%
%         %Plot fft of buffer signal
%         figure;
%         plot(frequency,P1)
%         title('Single-Sided Amplitude Spectrum of X(t)')
%         xlabel('f (Hz)')
%         ylabel('|P1(f)|')
%

%Plot spectrogram of signal
figure;
spectrogram(buffer,kaiser(256,5),220,512,fs,'yaxis')
set(gca, 'YLim',[0 6000], 'YScale', 'linear')

%         figure;
%         spectrogram(buffer./mean(buffer),kaiser(256,5),220,512,fs,'yaxis')


end


%function disconnect_RZ6()
%% Clear active X controls and stop processing chain

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);

disp('Disconnected from RZ6')
%end
