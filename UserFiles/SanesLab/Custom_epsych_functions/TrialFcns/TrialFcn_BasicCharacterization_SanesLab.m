function TRIALS = TrialFcn_BasicCharacterization_SanesLab(TRIALS)
global TONE_CAL NOISE_CAL

%If it's the start
if TRIALS.tidx == 1
% if TRIALS.TrialIndex == 1
    
    %Load tone calibration file
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select tone calibration file');
    tone_calfile = fullfile(pn,fn);
    
    disp(['Tone calibration file is: ' tone_calfile])
    TONE_CAL = load(tone_calfile,'-mat');
    
    %Load noise calibration file
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select noise calibration file');
    noise_calfile = fullfile(pn,fn);
    
    disp(['Noise calibration file is: ' noise_calfile])
    NOISE_CAL = load(noise_calfile,'-mat');
    
    %Launch basic characterization gui
    basic_characterization
    
end