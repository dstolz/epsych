function handles = updateSoundLevelandFreq_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function updates the sound level and frequency in the RPVds circuit
%
%
%Written by ML Caras 7.24.2016




global AX RUNTIME

%If the user has GUI control over the sound frequency, set the frequency in
%the RPVds circuit to the desired value. Otherwise, simply read the
%frequency from the circuit directly.
switch get(handles.freq,'enable')
    case 'on'
        
        %Get sound frequency from GUI
        soundstr = get(handles.freq,'String');
        soundval = get(handles.freq,'Value');
        sound_freq = str2num(soundstr{soundval}); %Hz
        
        if RUNTIME.UseOpenEx
            AX.SetTargetVal('Behavior.Freq',sound_freq)
        else
            AX.SetTagVal('Freq',sound_freq);
        end
        
        set(handles.freq,'ForegroundColor',[0 0 1]);
        
    otherwise
        
        %If Frequency is a parameter tag in the circuit
        if RUNTIME.UseOpenEx
             if ~isempty(find(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,'Freq'),1))
                sound_freq = AX.GetTargetVal('Behavior.Freq');
            end
        else
            if ~isempty(find(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,'Freq'),1))
                sound_freq = AX.GetTagVal('Freq');
            end
        end
end


%Set the voltage adjustment for calibration in RPVds circuit
 %If Frequency is a parameter tag in the circuit
 if ~isempty(find(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,'Freq'),1))
     CalAmp = Calibrate(sound_freq,handles.C);
 else
     CalAmp = handles.C.data(1,4);
 end
 
 if RUNTIME.UseOpenEx
     AX.SetTargetVal('Behavior.~Freq_Amp',CalAmp);
 else
     AX.SetTagVal('~Freq_Amp',CalAmp);
 end


%If the user has GUI control over the sound level, set the level in
%the RPVds circuit to the desired value. Otherwise, do nothing.
switch get(handles.level,'enable')
    case 'on'
        soundstr = get(handles.level,'String');
        soundval = get(handles.level,'Value');
        sound_level = str2num(soundstr{soundval}); %dB SPL
        
        %Use Active X controls to set duration directly in RPVds circuit
        if RUNTIME.UseOpenEx
            AX.SetTargetVal('Behavior.dBSPL',sound_level);
        else
            AX.SetTagVal('dBSPL',sound_level);
        end
        
        set(handles.level,'ForegroundColor',[0 0 1]);
end