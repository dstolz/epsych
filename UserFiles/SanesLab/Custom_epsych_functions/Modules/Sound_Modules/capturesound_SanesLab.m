function handles = capturesound_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function captures sound from a live microphone and plots the voltage
%
%Inputs: GUI handles structure
%
%Written by ML Caras 7.25.2016


global AX RUNTIME

%Set up buffer
bdur = 0.05; %sec

if RUNTIME.UseOpenEx
    fs = RUNTIME.TDT.Fs(handles.dev);
else
    fs = AX.GetSFreq;
end

%Set buffer size
buffersize = floor(bdur*fs); %samples
v = TDTpartag(AX,[handles.module,'.bufferSize'],buffersize);


if RUNTIME.UseOpenEx
    AX.ZeroTarget([handles.module,'.buffer']);
    
    %Trigger Buffer
    AX.SetTargetVal([handles.module,'.BuffTrig'],1);
    
    %Reset trigger
    AX.SetTargetVal([handles.module,'.BuffTrig'],0);
    
else

    AX.ZeroTag('buffer');
    
    %Trigger buffer
    AX.SoftTrg(1);
end



%Wait for buffer to be filled
pause(bdur+0.01);

%Retrieve buffer
if RUNTIME.UseOpenEx
    buffer = AX.ReadTargetV([handles.module,'.buffer'],0,buffersize);
else
    buffer = AX.ReadTagV('buffer',0,buffersize);
end

mic_rms = sqrt(mean(buffer.^2)); % signal RMS

%Plot microphone voltage
cla(handles.micAx)
b = bar(handles.micAx,mic_rms,'y');

%Format plot
set(handles.micAx,'ylim',[0 10]);
set(handles.micAx,'xlim',[0 2]);
set(handles.micAx,'XTickLabel','');
ylabel(handles.micAx,'RMS voltage','fontname','arial','fontsize',12)


