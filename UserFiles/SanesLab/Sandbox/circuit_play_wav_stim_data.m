
%function FM_sweep_testing()
close all;

handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\circuit_wav_stim_data.rcx';

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
level = 60; 
handles.RP.SetTagVal('dBSPL',level);


% Import wav files
searchpath  = 'D:\stim\Barascud_wav_files\';
searchhname = fullfile(searchpath,'*resampled.wav');
soundfiles  = dir(searchhname);
soundfiles  = {soundfiles.name};

% rng('shuffle')
% wav_seq = randperm(numel(soundfiles));
wav_seq = 1:numel(soundfiles);

for iWAV = wav_seq

%Select sound file(s)
wavfilename = soundfiles{iWAV};
% wavfile = importdata(fullfile('D:\stim\Barascud_wav_files',wavfilename));
% wavstim = wavfile.data;

[wavstim, fs_wav, stimsize] = wavread(fullfile(searchpath,wavfilename));


%Resample stimuli to match Fs of TDT
fs_TDT = handles.RP.GetSFreq;
% fs_wav = wavfile.fs;

if abs(fs_TDT-fs_wav) > 1
    [P,Q] = rat(fs_TDT/fs_wav);
    % abs((P/Q)*fs_wav - fs_TDT)
    wav_resampled = resample(wavstim,P,Q);
else
    wav_resampled = wavstim;
end

%Reshape to match desired format of TDT
if size(wav_resampled,1)>size(wav_resampled,2)
    wav_resampled = wav_resampled' ;
end


%Set up rec buffer
bdur = 5; %ms to sec
buffersize = floor(bdur*fs_TDT); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');



stimdur  = length(wav_resampled)/fs_TDT *1000; %ms
handles.RP.SetTagVal('stimDur',stimdur);

% wav_resampled(1,length(wav_resampled)+1:buffersize) = 0;

% wavAttr = whos('wav_resampled');
% stimsize = wavAttr.bytes; %bytes
% stimsize = length(wav_resampled); %samples
handles.RP.SetTagVal('stimSize',stimsize);

%Write data to buffer in circuit
% DataType = char(handles.RP.GetTagType('stim'));
handles.RP.ZeroTag('stim');
handles.RP.WriteTagV('stim',0,wav_resampled);


%%% why is buffer showing data throughout empty seconds at end??!



%Trigger circuit
handles.RP.SoftTrg(1);

%Wait for buffer to be filled
pause(bdur+0.1);

%Retrieve buffer
buffer = [];
buffer = handles.RP.ReadTagV('buffer',0,buffersize);

%Normalize baseline
buffer = buffer - mean(buffer(1:60));


%Plot spectrogram of signal
figure;
spectrogram(buffer,kaiser(256,5),50,1000,fs_TDT,'yaxis')
set(gca, 'YLim',[0 5000], 'YScale', 'linear', 'XLim', [0 size(wav_resampled,2)/fs_TDT])
title(wavfilename)

% savepath = 'C:\Users\sanesadmin\Google Drive\kp_data\Barascud_soundfiles\stim_spectrograms';
% save(fullfile())


%Plot buffer
% figure;
% plot(([1:buffersize]/fs_TDT),buffer)%,'Color',plot_colors{id})
% set(gca,'xlim', [0 bdur]);

%Save signal from buffer
% Stimuli(iWAV).filename = wavfilename;
% Stimuli(iWAV).buffer   = buffer;
% Stimuli(iWAV).fs       = fs_TDT;

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
