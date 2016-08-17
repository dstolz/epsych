function TRIALS = TrialFcn_externalStim_SanesLab(TRIALS)
global TONE_CAL NOISE_CAL STIM_FILES

%If it's the start
if TRIALS.tidx == 1
    
    %Load tone calibration file
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select tone calibration file');
    noise_calfile = fullfile(pn,fn);
    
    disp(['Tone calibration file is: ' noise_calfile])
    TONE_CAL = load(noise_calfile,'-mat');
    
    
%     %Select the folder containing sound stimulus files
%     [pnst] = uigetdir('D:\stim\','Select folder of stimulus files');
%     STIM_FILES = dir([pnst '\*.wav']);
%     
    
    %Launch frequency tuning gui
    external_stim_gui
    
end