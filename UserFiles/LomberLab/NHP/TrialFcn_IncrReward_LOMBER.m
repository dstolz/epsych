function TRIALS = TrialFcn_IncrReward_LOMBER(TRIALS)
% TRIALS = TrialFcn_IncrReward_LOMBER(TRIALS)
% 
% Custom trial selection function for increasing reward size for
% consecutive hits on a 2AFC task.  Misses reset the reward size to minimum
% specified amount.
%
% Strategy: Count the number of recent hits and update the reward duration
% parameter tag (in RZ6_Joystick2AFC_TRAINING_Phase2.rcx, this is
% Behavior.Water_Thi) by some increment.  Reset if the last trial was a
% miss or a 'no response'.
%
% DJS 4/2016
%

% 
% 
%
% Custom trial selection functions can be written to add more complex,
% dynamic programming to the behavior paradigm.  For example, a custom
% trial selection function can be used to create an adaptive threshold
% tracking paradigm to efficiently track audibility of tones across sound
% level or to adjust reward contingencies as the subject improves.
% 
% The goal of any trial selection function is to return an integer pointing
% to a row in the TRIALS.trials matrix which is generated using the
% ep_ExperimentDesign GUI.  Alternatively, the entire TRIALS structure can
% be updated and returned as long as the field "TRIALS.NextTrialID" is
% updated as well.
% 
% The function must have the same call syntax as this default function. 
%       ex:
%           function NextTrialID = MyCustomFunction(TRIALS)
% 
% TRIALS is a structure which has many subfields used during an experiment.
% Below are some important subfields:
% 
% TRIALS.NextTrialID is the next schedule index, that is the row selected 
%             from the TRIALS.trials matrix
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




% These values can be updated during the experiment.  Alternatively, you
% could set these values in the ep_ExperimentDesign GUI by preceding the
% name with an astersik (*) which hides it from being updated.  You can
% read that value using:
%  ind = ismember(TRIALS.writeparams,'ModuleAlias.*Parameter_Name');
%  parameterValues = cell2mat(TRIALS.trials(:,ind));

START_REWARDDURATION = 1000; % ms
MIN_REWARDDURATION   = 500;  % ms
MAX_REWARDDURATION   = 2500; % ms
REWARD_STEPSIZE      = 500;  % ms




% All custom Trial Select Functions need to update this field to select
% which TRIAL.trials row to present next.

% find the least used trials for the next trial index
idx = find(TRIALS.TrialCount == min(TRIALS.TrialCount));

% randomly select the next trial
TRIALS.NextTrialID = idx(randsample(length(idx),1));





% Locate the index of the Water_Thi parameter within the TRIALS.writeparams
% structure.  The TRIALS.writeparams field contains all parameters defined
% in the ep_ExperimentDesign GUI with the parameter functions set to
% 'Write' or 'Read/Write'.  Since the Water_Thi parameter is located on the
% hardware module with the alias 'Behavior', then it is refered to as
% Behavior.Water_Thi.
% tind = ismember(TRIALS.writeparams,'Behavior.Water_Thi');
tind = wParamIdx(TRIALS,'Behavior.Water_Thi'); % use a helper function to do this




% first trial, so there is no performance data to look at yet
if TRIALS.TrialIndex == 1
    TRIALS.trials(:,tind) = { START_REWARDDURATION };
    return % exit early
end



% fprintf('Trial Index:  %d\t',TRIALS.TrialIndex)



% The value of the previous reward duration was stored in the
% TRIALS.DATA structured array.  The module is called 'Behavior'
% and the parameter tag is called 'Water_Thi'.  EPsych automatically
% renames the DATA subfield for this parameter so that it is a valid
% subfield name.  Subfield name is: Behavior_Water_Thi
prevRewardDuration = TRIALS.DATA(end).Behavior_Water_Thi;

% fprintf('prevRewardDuration:  %d\t',prevRewardDuration)







% Use Response Code bitmask to compute performance
RCode = TRIALS.DATA(end).ResponseCode;
Hit = bitget(RCode,3); % Bit 3 was coded as a 'hit' in the ep_BitmaskGen GUI

if Hit % increment  Reward size
    nextRewardDuration = prevRewardDuration + REWARD_STEPSIZE;
    
else % reset reward size to minimum
    nextRewardDuration = MIN_REWARDDURATION;
end






% stay within maximum reward size
if nextRewardDuration > MAX_REWARDDURATION
    nextRewardDuration = MAX_REWARDDURATION;
end

% fprintf('nextRewardDuration:  %d\n',nextRewardDuration)





% Update the trials structure with the nextRewardDuration.  This
% TRIALS.trials structure is used to update the parameters running on the
% hardwaer modules.
TRIALS.trials(:,tind) = { nextRewardDuration };









