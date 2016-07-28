function handles = initializeCalibration_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function prompts user to select and load a calibration file, and sets
%the normalization value correctly in the RPVds circuit
%
%
%Written by ML Caras 7.24.2016


global CONFIG RUNTIME AX



%Load in calibration file
try
    calfile = CONFIG.PROTOCOL.MODULES.Stim.calibrations{2}.filename;
    fidx = 1;
catch
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select speaker calibration file');
    calfile = fullfile(pn,fn);
end

if ~fidx
    error('Error: No calibration file was found')
else
    
    disp(['Calibration file is: ' calfile])
    handles.C = load(calfile,'-mat');
    
    calfiletype = ~feval('isempty',strfind(func2str(handles.C.hdr.calfunc),'Tone'));
    parametertype = any(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,'Freq'));
    
    
    %If one of the parameter tags in the RPVds circuit controls frequency,
    %let's make sure that we've loaded in the correct calibration file
    if calfiletype ~= parametertype
        beep
        error('Error: Wrong calibration file loaded')
    else
        handles = updateSoundLevelandFreq_SanesLab(handles);
        RUNTIME.TRIALS.Subject.CalibrationFile = calfile;
    end
    
end

%Set normalization value for calibation
v = TDTpartag(AX,[handles.module,'.~Freq_Norm'],handles.C.hdr.cfg.ref.norm);


