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

try



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
    
    start_spkrs = [-90 90];
    
        

    % so first trial runs without error
    LastWasDeviant  = 0;
    LastWasAmbiguous = 0;
    WasDetected     = 1; 
    FalseAlarm      = 0;
    TrialAborted    = 0;
    
else
    
    % Response code of the most recent trial. bitmask defined using
    % ep_BitmaskGen.
    RespCode = TRIALS.DATA(TRIALS.TrialIndex-1).ResponseCode; 
    LastWasDeviant      = bitget(RespCode,15);
    LastWasAmbiguous    = bitget(RespCode,16);
    WasDetected         = bitget(RespCode,3); 
    FalseAlarm          = bitget(RespCode,7);
    TrialAborted        = bitget(RespCode,5);
    
end
    




% vvvvvvvvvvvv  Stimulus presentation control  vvvvvvvvvvvv




FirstStdIdx = [];




% Updated by StimDetect_Monitor GUI
ind = ismember(TRIALS.writeparams,'Behavior.*SpkrInUse');
SpkrInUse = cell2mat(TRIALS.trials(:,ind));


%********* THIS MIGHT NOT WORK. MAY NEED TO ALTER STATE MACHINE TABLE TO
% INCLUDE A CODE FOR ABORTED TRIALS ***********************************


% Decision tree
if TrialAborted
    
    % Reset the number of standards presented. crit_num_stds should stay
    % the same.
    idx = std_trials;
    num_stds_presented = 0;
    
    
    
elseif LastWasDeviant || TRIALS.TrialIndex == 1 
    

    if TRIALS.TrialIndex == 1 || WasDetected
        % The previous trial was a deviant and was detected by the subject.
        % Reset num_stds_presented to 0 and choose next number of standards
        % to present (crit_num_stds)
        
        % Randomize which speakers are standard and which are deviant
        tind = ismember(TRIALS.writeparams,'Behavior.TrialType');
        t = cell2mat(TRIALS.trials(:,tind));
        i = round(rand(1));
        
        std_trials = find(t == i  & SpkrInUse);
        dev_trials = find(t == ~i & SpkrInUse);
        amb_trials = find(t == 2  & SpkrInUse);
        
        TRIALS.trials(std_trials,tind) = {0};
        TRIALS.trials(dev_trials,tind) = {1};
        
        % Update sound levels ***************************
        slind = ismember(TRIALS.writeparams,'Behavior.Noise_dB');
        TRIALS.trials(std_trials,slind) = {60};
        TRIALS.trials(dev_trials,slind) = {80};
        
        % Determine first speaker in the sequence of standards
        saidx = find(ismember(SpkrAngles(std_trials),start_spkrs));
        n = saidx(randi(length(saidx),1));
        FirstStdIdx = std_trials(n);
        
        idx = std_trials;
        num_stds_presented = 0;
        crit_num_stds = randi(num_stds,1);
        
        
        
        
    else
        % The previous trial was a deviant, but was not detected by the
        % subject.  Use another (probably smaller) range of the number of
        % standards to present so that the next deviant will come more quickly.
        %
        % The range used here is determined by the *MIN_STANDARDS_POSTDEVMISS
        % and *MAX_STANDARDS_POSTDEVMISS parameters in the protocol.
        
        idx = std_trials;
        num_stds_presented = 0;
        crit_num_stds = randi(num_stds,1);
        
    end
    
    
elseif LastWasAmbiguous && WasDetected
    % The last trial was an ambiguous speaker location (ie, ~0deg) and there
    % was a response by the subject.  Reset the number of standards to
    % present before the next deviant.
    
    idx = std_trials;
    num_stds_presented = 0;
    crit_num_stds = randi(num_postdev_stds,1);
    
    
    
else % Last trial was a standard
    if FalseAlarm
        % There was a False Alarm to the previous standard stimulus.  Reset the
        % number of standards presented in this block to 1 so the wily bastard
        % can't just keep guessing until the deviant stimulus comes.
        
        idx = std_trials;
        num_stds_presented = 0;
        
        
        
        
    elseif num_stds_presented == crit_num_stds-1
        % The number of standards has reached criterion, select next trial as
        % one of the deviants.
        
        % find the least used trials for the next trial index
        m   = min(TRIALS.TrialCount(dev_trials));
        idx = dev_trials(TRIALS.TrialCount(dev_trials) == m);
        %     num_stds_presented = 0;
%         fprintf(2,'\n**** THIS NEXT TRIAL SHOULD BE A DEVIANT ****\n')
        
        
        
    else
        
        % Set the next trial to a standard stimulus
        if LastWasAmbiguous
            % I don't want multiple ambiguous (0deg) speaker locations presented
            % consecutively
            idx = std_trials;
        else
            idx = [std_trials; amb_trials];
        end
        num_stds_presented = num_stds_presented + 1;
    end
end



% Select NextTrialID
if FirstStdIdx
    TRIALS.NextTrialID = FirstStdIdx;
else
    r = randperm(numel(idx),1);
    TRIALS.NextTrialID = idx(r);
end

% 
% fprintf('\n\t--> TRIALS.TrialIndex:\t %d\n',TRIALS.TrialIndex)
% fprintf('\t    NextTrialID:\t\t %d\n',TRIALS.NextTrialID)
% fprintf('\t    num_stds_presented:\t %d\n',num_stds_presented)
% fprintf('\t    crit_num_stds:\t\t %d\n',crit_num_stds)
% 



catch me
    rethrow(me) % put a break point here for debugging
end





































