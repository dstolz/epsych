function TRIALS = TrialFcn_StimDetect_LOMBER(TRIALS)
% TRIALS = TrialFcn_StimDetect_LOMBER(TRIALS)
% 
% Custom trial selection function for time order judgement (TOJ) stimulus
% detection task.
%
% TrialTypes:
%   Standard trial = 0
%   Deviant trial  = 1
% 
% Parameters from protocol file used in this function
%   TrialType
%   *MIN_STANDARDS
%   *MAX_STANDARDS
%   *MIN_STANDARDS_POSTDEVMISS
%   *MAX_STANDARDS_POSTDEVMISS
%
%
% DJS 05/2015
%

% 
% NextTrialID is the next schedule index, that is the row selected 
%             from the TRIALS.trials matrix
% 
%
% Custom trial selection functions can be written to add more complex,
% dynamic programming to the behavior paradigm.  For example, a custom
% trial selection function can be used to create an adaptive threshold
% tracking paradigm to efficiently track audibility of tones across sound
% level.
% 
% The goal of any trial selection function is to return an integer pointing
% to a row in the TRIALS.trials matrix which is generated using the
% ep_ExperimentDesign GUI (or by some other method).
% 
% The function must have the same call syntax as this default function. 
%       ex:
%           function NextTrialID = MyCustomFunction(TRIALS)
% 
% TRIALS is a structure which has many subfields used during an experiment.
% Below are some important subfields:
% 
% TRIALS.TrialIndex  ... Keeps track of each completed trial
% TRIALS.trials      ... A cell matrix in which each column is a different
%                        parameter and each row is a unique set of
%                        parameters (called a "trial")
% TRIALS.readparams  ... Parameter tag names for reading values from a
%                        running TDT circuit. The position of the parameter
%                        tag name in this array is the same as the position
%                        of its corresponding parameters (column) in
%                        TRRIALS.trials.
% TRIALS.writeparams ... Parameter tag names writing values from a
%                        running TDT circuit. The position of the parameter
%                        tag name in this array is the same as the position
%                        of its corresponding parameters (column) in
%                        TRIALS.trials.
% 
% See also, SelectTrial
% 
% Daniel.Stolzberg@gmail.com 2015




persistent num_stds num_stds_presented num_postdev_stds ...
    crit_num_stds std_trials dev_trials amb_trials start_spkrs SpkrAngles



if TRIALS.TrialIndex == 1
    % THIS INDICATES THAT WE ARE ABOUT TO BEGIN THE FIRST TRIAL.
    % THIS IS A GOOD PLACE TO TAKE CARE OF ANY SETUP TASKS LIKE PROMPTING
    % THE USER FOR CUSTOM PARAMETERS, ETC.
    
    % Gather info from the protocol file
    num_stds(1) = SelectTrial(TRIALS,'Behavior.*MIN_STANDARDS');
    num_stds(2) = SelectTrial(TRIALS,'Behavior.*MAX_STANDARDS');
    num_postdev_stds(1) = SelectTrial(TRIALS,'Behavior.*MIN_STANDARDS_POSTDEVMISS');
    num_postdev_stds(2) = SelectTrial(TRIALS,'Behavior.*MAX_STANDARDS_POSTDEVMISS');
    
    i = ismember(TRIALS.writeparams,'Behavior.Speaker_Angle');
    SpkrAngles = cell2mat(TRIALS.trials(:,i));
    
    
    % initialize some parameters for first trials
    num_stds_presented = 0;
    crit_num_stds = randi(num_stds,1);
    
%     start_spkrs = SelectTrial(TRIALS,'Behavior.*START_SPKRS');
    start_spkrs = [-90 90];

    % so first trial runs without error
    LastWasDeviant = 0;
    WasDetected = 1; 
    FalseAlarm  = 0;
    
    
else
    
    % Response code of the most recent trial. bitmask defined using
    % ep_BitmaskGen.
    RespCode = TRIALS.DATA(TRIALS.TrialIndex-1).ResponseCode; 
    LastWasDeviant = bitget(RespCode,15);
    WasDetected    = bitget(RespCode,3); 
    FalseAlarm     = bitget(RespCode,7);
end
    




% vvvvvvvvvvvv  Stimulus presentation control  vvvvvvvvvvvv



if LastWasDeviant || TRIALS.TrialIndex == 1

    
    % Randomize which speakers are standard and which are deviant
    [~,tidx] = SelectTrial(TRIALS,'Behavior.TrialType');
    t = cell2mat(TRIALS.trials(:,tidx));    
    i = round(rand(1));
    std_trials = find(t == i);
    dev_trials = find(t == ~i);
    amb_trials = find(t == 2);
    
    TRIALS.trials(std_trials,tidx) = {0};
    TRIALS.trials(dev_trials,tidx) = {1};
    
    % Determine first standard
    r = randperm(length(start_spkrs));
    n = start_spkrs(r(1));
    FirstStdIdx = find(SpkrAngles == n);

    
    
else
    FirstStdIdx = [];
    
end







if ~LastWasDeviant && num_stds_presented == crit_num_stds - 1
    % The number of standards has reached criterion, select next trial as
    % one of the deviants.
        
    % find the least used trials for the next trial index
    m   = min(TRIALS.TrialCount(dev_trials));
    idx = dev_trials(TRIALS.TrialCount(dev_trials) == m);

%     fprintf(2,'\n**** THIS NEXT TRIAL SHOULD BE A DEVIANT ****\n')
    
    
elseif FalseAlarm
    % There was a False Alarm to the previous standard stimulus.  Reset the
    % number of standards presented in this block to 1 so the wily bastard 
    % can't just keep guessing until the deviant stimulus comes. 
    
    idx = std_trials;
    num_stds_presented = 0;

    
    
    
elseif LastWasDeviant && WasDetected
    % The previous trial was a deviant and was detected by the subject.
    % Reset num_stds_presented to 0 and choose next number of standards to
    % present (crit_num_stds)
    
    idx = std_trials;
    num_stds_presented = 0;
    crit_num_stds = randi(num_stds,1);
    
    
    
    
elseif LastWasDeviant && ~WasDetected
    % The previous trial was a deviant, but was not detected by the
    % subject.  Use another (probably smaller) range of the number of
    % standards to present so that the next deviant will come more quickly.
    %
    % The range used here is determined by the *MIN_STANDARDS_POSTDEVMISS
    % and *MAX_STANDARDS_POSTDEVMISS parameters in the protocol.
    
    idx = std_trials;
    num_stds_presented = 0;
    crit_num_stds = randi(num_postdev_stds,1);

    
    
    
else
    % Set the next trial to a standard stimulus
    idx = std_trials;
    num_stds_presented = num_stds_presented + 1;
end



% Select NextTrialID
if FirstStdIdx
    TRIALS.NextTrialID = FirstStdIdx;
else
    r = randperm(numel(idx),1);
    TRIALS.NextTrialID = idx(r);
end
% 
% 
% fprintf('\n\t--> TRIALS.TrialIndex:\t %d\n',TRIALS.TrialIndex)
% fprintf('\t\t    NextTrialID:\t\t %d\n',TRIALS.NextTrialID)
% fprintf('\t\t    num_stds_presented:\t %d\n',num_stds_presented)
% fprintf('\t\t    crit_num_stds:\t\t %d\n',crit_num_stds)
% 









































