clear all

handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\FM_wave_test.rcx';

%Load in speaker calibration file
% [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
fidx=1;
pn = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\';
fn = '983Ceiling_PureToneCalibration_Oct25_2015.cal';
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

%Set up buffer
bdur = 1; %sec
fs = handles.RP.GetSFreq;

buffersize = floor(bdur*fs); %samples
handles.RP.SetTagVal('bufferSize',buffersize);
handles.RP.ZeroTag('buffer');

%Set desired sound parameters
fq = 1000;
FMDepth = 300;
FMRate = 2;
handles.RP.SetTagVal('Freq',fq);
handles.RP.SetTagVal('FMdepth',FMDepth);
handles.RP.SetTagVal('FMrate',FMRate);


plot_colors = {'k' 'b' 'g' 'r'};

%% RUN CIRCUIT 
figure(2); clf;
Sound = struct();
FMdepths = [50 100 200 400];
for it = 1:numel(FMdepths)
    
    %Set stim params
    handles.RP.SetTagVal('FMdepth',FMdepths(it));
        
    %Trigger buffer
    handles.RP.SoftTrg(1);
    
    %Wait for buffer to be filled
    pause(bdur+0.01);
    
    %Retrieve buffer
    buffer = handles.RP.ReadTagV('buffer',0,buffersize);
    
    %Normalize baseline
    buffer = buffer - mean(buffer(1:60));
    
    %Plot buffer
    figure(2);
    hold on
    plot(buffer,'Color',plot_colors{it})
    set(gca,'xlim',[0 5000]);
    
    %Save signal from buffer
    Sound(it).FMdepth = FMdepths(it);
    Sound(it).signal = buffer;
    
    pause(2)
    
end

hold off
%%

%Convert signal to frequency domain
fft_buffer = fft(buffer);
P2 = abs(fft_buffer/size(buffer,2));
P1 = P2(1:size(buffer,2)/2+1);
P1(2:end-1) = 2*P1(2:end-1);

frequency = fs*(0:(size(buffer,2)/2))/size(buffer,2);

%Plot fft of buffer signal
figure(3);
plot(frequency,P1)
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

%Plot spectrogram of signal
figure(4);
spectrogram(buffer,kaiser(256,5),220,512,fs,'yaxis')
figure(5);
spectrogram(buffer./mean(buffer),kaiser(256,5),220,512,fs,'yaxis')

%% Clear active X controls and stop processing chain

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);
