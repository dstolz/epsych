
%function FM_sweep_testing()
% close all;


% Define RCX file
handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Sandbox\KP\AM_jitter.rcx';


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
handles.RP.SetTagVal('fs', fs);

% Setup sound parameters
AMrate = 4;
AMrateSTD = [0.2 0.1 0.06 0.04 0.02 0] .* AMrate; % proportion of rate  0.1 0.06 0.04 0.02
AMdepth = 0.5;
%~~~~~~~~~~~~~~~~
  AMphase = -80;
 % also note: cue that varies with STD is phase at offset
%~~~~~~~~~~~~~~~~
HP = 100;
LP = 25000;
dBSPL = 60;
Duration = 2000; %ms

n_periods = Duration/1000 / (1/AMrate) + 5;
fn_AMrate_textfile = 'D:\stim\AMrate_files\AMrate_vector_input_test.txt';

for ii = 1:numel(AMrateSTD)
    
    % Randomly select period lengths from defined distribution for this trial
    rateVector = [AMrate AMrate + AMrateSTD(ii).*randn(1,n_periods-1)];
    
    % Correct duration so signal ends at the end of a period
    pdVector = 1./ rateVector;
    runningDur = cumsum(pdVector) - pdVector(1);
    distDur = abs(runningDur - Duration/1000);
    rateVector = rateVector(1:find(distDur==min(distDur)));
    Duration = 1000* sum(pdVector(2:find(distDur==min(distDur))));
    
    
    % Save rate vector for each trial
    fid = fopen(fn_AMrate_textfile,'wt');
    fprintf(fid,'%4.3f\n',rateVector);
    fclose(fid);
    
    handles.RP.WriteTagV('rateVec',0,rateVector);
    rateAttr = whos('rateVector');
    rateVec_size = rateAttr.bytes; %bytes
%     handles.RP.SetTagVal('rateVec_size', rateVec_size);
    handles.RP.SetTagVal('rateVec_size', numel(rateVector));
    
    
    % Set param tags in circuit
    handles.RP.SetTagVal('AMrate', AMrate);
    handles.RP.SetTagVal('AMdepth',AMdepth);
    handles.RP.SetTagVal('AMphase',AMphase);
    handles.RP.SetTagVal('HP',HP);
    handles.RP.SetTagVal('LP',LP);
    handles.RP.SetTagVal('dBSPL',dBSPL);
    handles.RP.SetTagVal('Duration',Duration);
    
    
    %Apply the voltage adjustment for level calibration in RPVds circuit
%     CalAmp = Calibrate(endFq(ifq),handles.C);
    handles.RP.SetTagVal('~Freq_Amp',handles.C.data(1,4));
    handles.RP.SetTagVal('~Freq_Norm',handles.C.hdr.cfg.ref.norm); %read norm value from cal file
    
    
    %Set up buffer
    bdur = Duration/1000; %ms to sec
    buffersize = ceil(bdur*fs); %samples
    handles.RP.SetTagVal('bufferSize',buffersize);
    handles.RP.ZeroTag('buffer');
    handles.RP.ZeroTag('rateBuf');
    
    
    %Trigger buffer
    handles.RP.SoftTrg(1);
    
    %Wait for buffer to be filled
    pause(bdur+0.5);
    
    %Retrieve buffer
    buffer = [];
    buffer = handles.RP.ReadTagV('buffer',0,buffersize);
    rateBuf = [];
    rateBuf = handles.RP.ReadTagV('rateBuf',0,buffersize);
    
    %Normalize baseline
    buffer = buffer - mean(buffer);
    
    %Plot buffer
    figure; 
    [ax,h1,h2] = plotyy(1:buffersize,buffer,1:buffersize,rateBuf);
    xlabel('Time (samples)')
    set(h1,'Color','k');  set(ax(1),'YColor','k')
    set(get(ax(1),'YLabel'),'String','Stimulus signal (V)')
    set(h2,'Color','r');  set(ax(2),'YColor','r')
    set(get(ax(2),'YLabel'),'String','instantaneous AM rate (Hz)')
    
    
    %Convert signal to frequency domain
% %     fft_buffer = fft(buffer);
% %     P2 = abs(fft_buffer/size(buffer,2));
% %     P1 = P2(1:size(buffer,2)/2+1);
% %     P1(2:end-1) = 2*P1(2:end-1);
% %     
% %     frequency = fs*(0:(size(buffer,2)/2))/size(buffer,2);
% %     
% %     %Plot fft of buffer signal
% %     figure;
% %     plot(frequency,P1)
% %     title('Single-Sided Amplitude Spectrum of X(t)')
% %     xlabel('f (Hz)')
% %     ylabel('|P1(f)|')
    
    %Plot spectrogram of signal
%     figure;
%     spectrogram(buffer,kaiser(256,5),220,512,fs,'yaxis')
    
%     figure;
%     pwelch(buffer,[],[],[],fs,'onesided');
%     psd(buffer,'welch','Fs',fs)
    
    pause(1)
    
    hold off
end 


%% Clear active X controls and stop processing chain

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);

disp('Disconnected from RZ6')
%end
