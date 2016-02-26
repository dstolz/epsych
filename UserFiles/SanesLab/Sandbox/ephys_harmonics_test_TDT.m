
%function FM_sweep_testing()
close all;

handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\ephys_harmonics_test_TDT.rcx';
% handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\OpenExProjects\KP\FreqTuning_FM_harmonics\RCOCircuits\FreqTuning_FM_harmonics_lite_buffer.rcx';

% handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\FM_sweep_test_manualcircuit.rcx';


%Load in speaker calibration file
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
% fidx=1;
% pn = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\';
% fn = 'Ceiling_PureToneCalibration_Dec92015.cal';
% fn = '983Booth_FloorSpeaker_PureToneCalibration_Jul06_2015_new.cal';
[fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select tone calibration file');
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


%----------------------------------------
harmWts  = [1 0 0 0 0];  %0 to 1
FMdepths = [-0.2 0 0.2]; %proportion of start Fq
startFq  = [100 300 500];     %Hz

duration = 300;           %ms
level    = 60;             %dBSPL
%----------------------------------------



%Set parameters
handles.RP.SetTagVal('dBSPL',level);
handles.RP.SetTagVal('Duration',duration);

%Set up buffer
bdur = duration/1000; %sec
fs = handles.RP.GetSFreq;
buffersize = floor(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');


pause(4)

idx=0;  plot_colors = {'k' 'b' 'g' 'r' 'c'};

for ifq = 1:numel(startFq)
    figure(ifq); hold on

%set start fq in rpvds
    handles.RP.SetTagVal('Freq',startFq(ifq));
    
    for id = 1:numel(FMdepths)
        %Check that frequency won't go out of speaker range
        if ((startFq(ifq)*FMdepths(id) + startFq(ifq)) < 50) || ((startFq(ifq)*FMdepths(id) + startFq(ifq)) > 20000)
            warning('Skipped stimulus with end frequency out of range')
            sprintf('end fq %i',startFq(ifq)*FMdepths(id) + startFq(ifq))
            continue
        end
        idx = idx+1;
                
        %Set FM depth
        handles.RP.SetTagVal('FMdepth',FMdepths(id));
        
        %----------------------------------------------------
        %Select harmonics, set relative weights, and silence those out of range
        for ih = 0:4
            
            %%%% set frequency limits
            
            %Create strings for parameter tags
            Tag_weight = sprintf('weight_F%i',ih);
            Tag_calAmp = sprintf('Freq%i_amp',ih);
            Tag_calNorm = sprintf('Freq%i_norm',ih);
            
            %Set weight of current harmonic. if 0, skip the rest
            handles.RP.SetTagVal(Tag_weight, harmWts(ih+1));
            
            if harmWts(ih+1)==0
                continue
            end

            %Apply the voltage adjustment for level calibration in RPVds circuit
            CalAmp = Calibrate(startFq(ifq)*(ih+1),handles.C);
            handles.RP.SetTagVal(Tag_calAmp,CalAmp);
            handles.RP.SetTagVal(Tag_calNorm,handles.C.hdr.cfg.ref.norm); %read norm value from cal file
            
        end
        
        %----------------------------------------------------
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
        plot(buffer,'Color',plot_colors{id})
        set(gca,'xlim',[0 5000]);
        
        %Save signal from buffer
        Sound(idx).Freq1    = startFq(ifq);
        Sound(idx).FMdepth  = FMdepths(id);
        Sound(idx).duration = duration;
        Sound(idx).signal   = buffer;
        Sound(idx).fs       = fs;
        
        %---------------------------------------------------
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
        
        %---------------------------------------------
        pause(0.5)
        
    end %for it ... depths
    hold off
end % for ifq ... start fqs


%---------------------------------------------
%       PLOTS
%---------------------------------------------
plot_signal = Sound(1).signal;

%function plot_FM_sweeep_test()
figure;
plot(plot_signal)

%Convert signal to frequency domain
fft_buffer = fft(plot_signal);
P2 = abs(fft_buffer/size(plot_signal,2));
P1 = P2(1:size(plot_signal,2)/2+1);
P1(2:end-1) = 2*P1(2:end-1);

frequency = fs*(0:(size(plot_signal,2)/2))/size(plot_signal,2);

%Plot fft of buffer signal
figure;
plot(frequency,P1)
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

%%
%Plot spectrogram of signal
figure;
spectrogram(buffer,kaiser(256,5),220,512,fs,'yaxis')
figure;
spectrogram(buffer./mean(buffer),kaiser(256,5),220,512,fs,'yaxis')

%end

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
