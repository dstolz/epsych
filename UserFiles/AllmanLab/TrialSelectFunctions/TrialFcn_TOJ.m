function NextTrialID = TrialFcn_TOJ(TRIALS)
% NextTrialID = TrialFcn_TOJ(TRIALS)
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
% DJS 04/2015
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
% Daniel.Stolzberg@gmail.com 2014


persistent num_stds num_stds_presented num_postdev_stds ...
    crit_num_stds std_trials dev_trials


% Gather info from the protocol file
Tstds(1) = SelectTrial(TRIALS,'*MIN_STANDARDS');
Tstds(2) = SelectTrial(TRIALS,'*MAX_STANDARDS');
Tpdstds(1) = SelectTrial(TRIALS,'*MIN_STANDARDS_POSTDEVMISS');
Tpdstds(2) = SelectTrial(TRIALS,'*MAX_STANDARDS_POSTDEVMISS');



if TRIALS.TrialIndex == 1
    % THIS INDICATES THAT WE ARE ABOUT TO BEGIN THE FIRST TRIAL.
    % THIS IS A GOOD PLACE TO TAKE CARE OF ANY SETUP TASKS LIKE PROMPTING
    % THE USER FOR CUSTOM PARAMETERS, ETC.

    num_stds = Tstds;
    num_postdev_stds = Tpdstds;
    
    
    % Determine which trials are standards and which are devieants.
    % TrialType == 0 is defined as a standard stimulus
    % TrialType == 1 is defined as a deviant stimulus
    [~,i] = SelectTrial(TRIALS,'TrialType');
    t = cell2mat(TRIALS.trials(:,i));
    std_trials = find(t == 0);
    dev_trials = find(t == 1 | t == 2);
    
    % initialize some parameters for first trials
    num_stds_presented = 0;
    crit_num_stds = randi(num_stds,1);

    % so first trial runs without error
    LastWasDeviant = 0;
    WasDetected = 1; 
    FalseAlarm  = 0;
    
    
else
    
    % Response code of the most recent trial. bitmask defined using
    % ep_DisplayPrefs.
    RespCode = TRIALS.DATA(TRIALS.TrialIndex-1).ResponseCode; 
    LastWasDeviant = bitget(RespCode,12);
    WasDetected = bitget(RespCode,3); 
    FalseAlarm  = bitget(RespCode,7);
end
    



% Detect update from TOJ_Monitor
if ~all(Tstds==num_stds) || ~all(Tpdstds==num_postdev_stds)
    num_stds = Tstds;
    num_postdev_stds = Tpdstds;
    
    % reinitialize for updated parameters
    num_stds_presented = 0;
    crit_num_stds = randi(num_stds,1);
end





% vvvvvvvvvvvv  Stimulus presentation control  vvvvvvvvvvvv

if LastWasDeviant
    
        
        
        
    if WasDetected
        % The previous trial was a deviant and was detected by the subject.
        % Reset num_stds_presented to 0 and choose next number of standards to
        % present (crit_num_stds)
        
        idx = std_trials;
        num_stds_presented = 0;
        crit_num_stds = randi(num_stds,1);
        
        
        
        
    else
        % The previous trial was a deviant, but was not detected by the
        % subject.  Use another (probably smaller) range of the number
        % standards to present so that the next deviant will come more quickly.
        %
        % The range used here is determined by the *MIN_STANDARDS_POSTDEVMISS
        % and *MAX_STANDARDS_POSTDEVMISS parameters in the protocol.
        
        idx = std_trials;
        num_stds_presented = 0;
        crit_num_stds = randi(num_postdev_stds,1);
        
    end
else
        
    if TRIALS.TrialIndex == 1
%         % Give them a rewarded trial (deviant) on the first trial
%         idx = dev_trials;
%         num_stds_presented = 0;
        num_stds_presented = 0;
        idx = std_trials;
        
    elseif FalseAlarm
        % There was a False Alarm to the previous standard stimulus.  Reset the
        % number of standards presented in this block to 1 so the wily bastard
        % can't just keep guessing until the deviant stimulus comes.
        
        idx = std_trials;
        num_stds_presented = 0;
        
    elseif num_stds_presented == crit_num_stds - 1
        % The number of standards has reached criterion, select next trial as
        % one of the deviants.
        
        % find the least used trials for the next trial index
        m   = min(TRIALS.TrialCount(dev_trials));
        idx = dev_trials(TRIALS.TrialCount(dev_trials) == m);
        
        %     fprintf(2,'\n**** THIS NEXT TRIAL SHOULD BE A DEVIANT ****\n')
        
    else
        % Set the next trial to a standard stimulus
        idx = std_trials;
        num_stds_presented = num_stds_presented + 1;
    end
    
    
end

if crit_num_stds == 0
    % special case where there no standards are to be presented
    m   = min(TRIALS.TrialCount(dev_trials));
    idx = dev_trials(TRIALS.TrialCount(dev_trials) == m);
    
    %     fprintf(2,'\n**** THIS NEXT TRIAL SHOULD BE A DEVIANT ****\n')
end

% Select NextTrialID
r = randperm(numel(idx),1);
NextTrialID = idx(r);

% fprintf('\n\t--> TRIALS.TrialIndex:\t %d\n',TRIALS.TrialIndex)
% fprintf('\t\t    NextTrialID:\t\t %d\n',NextTrialID)
% fprintf('\t\t    num_stds_presented:\t %d\n',num_stds_presented)
% fprintf('\t\t    crit_num_stds:\t\t %d\n',crit_num_stds)










































