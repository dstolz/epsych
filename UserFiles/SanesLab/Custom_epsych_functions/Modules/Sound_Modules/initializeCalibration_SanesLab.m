function handles = initializeCalibration_SanesLab(handles)
%handles = initializeCalibration_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function prompts user to select and load a calibration file, and sets
%the normalization value correctly in the RPVds circuit. If an incorrect
%calibration file is loaded (i.e. a noise calibration file was selected
%when we need a tone calibration file), the user is alerted and prompted to
%make a new selection.
%
%
%Written by ML Caras 8.10.2016


global CONFIG RUNTIME AX

calcheck = 0;
loadtype = 0;

while calcheck == 0
    
    fidx = 0;
    
    %Define calibration file
    if isfield(CONFIG.PROTOCOL.MODULES(handles.module),'calibrations')
        calfile = CONFIG.PROTOCOL.MODULES.(handles.module).calibrations{2}.filename; %Check this line
        fidx = 1;
        loadtype = 1; %Prevents endless looping
        
    %If undefined
    else
        
        if fidx == 0
            %Get the path for calibration file storage (preferred or default)
            defaultpath = 'C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\Defaults\';
            calpath = getpref('PSYCH','CalDir',defaultpath);
            
            %Prompt user to select file
            [fn,pn,fidx] = uigetfile([calpath,'*.cal'],'Select speaker calibration file');
            calfile = fullfile(pn,fn);
            
            %If they selected a file, reset the preferred path
            if ischar(pn)
                setpref('PSYCH','CalDir',pn)
            end
            
            %If they selected a file, display file name
            if ischar(fn)
                vprintf(0,['Calibration file is: ' fn])
            end
        end
        
    end
    
    
    %Determine if we are running a circuit with frequency as a parameter
    parametertype = any(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,'Freq'));
    
    
    %If the calibration file is still undefined, set to default
    if fidx == 0
        
        if parametertype == 1 %tones
            fn = 'DefaultTone.cal';
            
        elseif parametertype == 0 %noise
            fn = 'DefaultNoise.cal';
            
        end
        
        calfile = fullfile(defaultpath,fn);
        
        %Alert user and log it
        beep
        vprintf(0,['Calibration file undefined. Set to ',fn])
        
    end
    
    %Load the file
    handles.C = load(calfile,'-mat');
    calfiletype = ~feval('isempty',strfind(func2str(handles.C.hdr.calfunc),'Tone'));
    
    
    %If we loaded in the wrong calibration file type
    if calfiletype ~= parametertype && loadtype == 0;
        
        %Prompt user to reload file.
        beep
        vprintf(0,'Wrong calibration file loaded. Reload file.')
  
    elseif calfiletype ~= parametertype && loadtype == 1;
        
        %Warn user that calibration file might not be correct in protocol
        beep
        vprintf(0,'Warning: calibration file might not be compatible with protocol.')
        
    %Otherwise, we're good to go!
    else
        
        %Update the sound level and frequency
        handles = updateSoundLevelandFreq_SanesLab(handles);
        
        %Store the calibration file name
        RUNTIME.TRIALS.Subject.CalibrationFile = calfile;
        
        
        %Set normalization value for calibation in RPVds circuit
        v = TDTpartag(AX,[handles.module,'.~Freq_Norm'],handles.C.hdr.cfg.ref.norm);
        
        %Break out of while loop
        calcheck = 1;
    end
    
    
    

    
end
