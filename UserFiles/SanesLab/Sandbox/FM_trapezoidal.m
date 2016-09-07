
%function FM_sweep_testing()
% close all;

% handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\KP\FM_sweep_to_tone.rcx';
handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Sandbox\KP\FM_trapezoidal.rcx';

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

% pause(5) 

%Set desired sound level (dB SPL)
level = 65; 
handles.RP.SetTagVal('dBSPL',level);

%Set desired sound dynamics (all in ms)
sweep_delay       = 200;%ms
handles.RP.SetTagVal('SweepDelay',sweep_delay);
sweep_duration    = 100;%ms
handles.RP.SetTagVal('SweepDur',sweep_duration);
stimulus_duration = 600;%ms
handles.RP.SetTagVal('StimDur',stimulus_duration);

%Set up buffer
bdur = stimulus_duration/1000; %ms to sec
fs = handles.RP.GetSFreq;
buffersize = floor(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');

plot_colors = {'k' 'b' 'g' 'r'};


FMdepths = [-0.5 -0.1 -0.05 0]; % 0.05 0.1 0.2 0.5];
% FMdepths = [0];
endFq = [1000 2000];
idx=0;  
for ifq = 1:numel(endFq)
%     figure(fq); hold on
    
    %set start fq in rpvds
    handles.RP.SetTagVal('Freq',endFq(ifq));
    
    %Apply the voltage adjustment for level calibration in RPVds circuit
    CalAmp = Calibrate(endFq(ifq),handles.C);
    handles.RP.SetTagVal('Freq0_Amp',CalAmp);
    handles.RP.SetTagVal('Freq0_norm',handles.C.hdr.cfg.ref.norm); %read norm value from cal file
    
    for id = 1:numel(FMdepths)
        %Check that frequency won't go out of speaker range
        if ((endFq(ifq)*FMdepths(id) + endFq(ifq)) < 200) || ((endFq(ifq)*FMdepths(id) + endFq(ifq)) > 20000)
            warning('Skipped stimulus with end frequency out of range')
            sprintf('end fq %i',endFq(ifq)*FMdepths(id) + endFq(ifq))
            continue
        end
        idx = idx+1;
        
        %Select harmonics, set relative weights, and silence those out of range
%         weight_handles = {'weight_1' 'weight_2' 'weight_3' 'weight_4'};
%         for ih = 1:4
%             handles.RP.SetTagVal(weight_handles{ih},0);
%             if ih <= n_harmonics && (startFq*(2^ih)) < 30000
%                 handles.RP.SetTagVal(weight_handles{ih},1/(2^ih));
%             end
%         end
        handles.RP.SetTagVal('weight_F0', 1);
        handles.RP.SetTagVal('weight_F1', 0);
        handles.RP.SetTagVal('weight_F2', 0);
        handles.RP.SetTagVal('weight_F3', 0);
        handles.RP.SetTagVal('weight_F4', 0);

        
        %Set stim params
        handles.RP.SetTagVal('FMdepth',FMdepths(id));
        
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
        Sound(idx).Freq1    = endFq(ifq);
        Sound(idx).FMdepth  = FMdepths(id);
        Sound(idx).duration = stimulus_duration;
        Sound(idx).signal   = buffer;
        Sound(idx).fs       = fs;
        
        figure;
        plot(buffer)
        
        %Convert signal to frequency domain
        fft_buffer = fft(buffer);
        P2 = abs(fft_buffer/size(buffer,2));
        P1 = P2(1:size(buffer,2)/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        frequency = fs*(0:(size(buffer,2)/2))/size(buffer,2);
        
        %Plot fft of buffer signal
        figure;
        plot(frequency,P1)
        title('Single-Sided Amplitude Spectrum of X(t)')
        xlabel('f (Hz)')
        ylabel('|P1(f)|')
        
        %Plot spectrogram of signal
        figure;
        spectrogram(buffer,kaiser(256,5),220,512,fs,'yaxis')
%         figure;
%         spectrogram(buffer./mean(buffer),kaiser(256,5),220,512,fs,'yaxis')
        
        
        pause(1)
        
    end %for it ... depths
    hold off
end % for ifq ... start fqs


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
