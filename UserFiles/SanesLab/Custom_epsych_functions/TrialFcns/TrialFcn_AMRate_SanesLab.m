function TRIALS = TrialFcn_AMRate_SanesLab(TRIALS)
global NOISE_CAL

%If it's the start
if TRIALS.tidx == 1
    
    %Load noise calibration file
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select noise calibration file');
    noise_calfile = fullfile(pn,fn);
    
    disp(['Noise calibration file is: ' noise_calfile])
    NOISE_CAL = load(noise_calfile,'-mat');

    %Launch frequency tuning gui
    AMRate_tuning_gui
    
end