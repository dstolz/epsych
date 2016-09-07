function TRIALS = TrialFcn_AMRate_jitter_SanesLab(TRIALS)
global NOISE_CAL 

% if it's the start
if TRIALS.tidx == 1
    
    % Load noise calibration file
    [fn,pn,fidx] = uigetfile('C:\gits\epsych\UserFiles\SanesLab\SpeakerCalibrations\*.cal','Select noise calibration file');
    noise_calfile = fullfile(pn,fn);
    
    disp(['Noise calibration file is: ' noise_calfile])
    NOISE_CAL = load(noise_calfile,'-mat');
    
    
    % Check if a folder containing mat files corresponding to the rate and
    % stds chosen in the protocol, and if not, make one.
    
%     savefilename = [fullfile(savedir,tank) '\' this_block '.mat'];
%     if ~exist(savefilename,'file')
%         create_AM_jitter_matfiles(AMrate, AMstd, Duration)
%     end
%     
%     
%     
    
    
    % Adjust trial durations
    
    
    
    
    
    % Launch frequency tuning gui
    AMRate_jitter_gui
    
end