function TRIALS = TrialFcn_IncrReward_LOMBER(TRIALS)
% TRIALS = TrialFcn_IncrReward_LOMBER(TRIALS)
%
% Increases reward size (within bounds) with consecutive hits.
%
% A miss resets the reward size to a minimum specified value.
%
% See inline comments for more details.
%
% Daniel.Stolzberg@gmail.com 11/2015


% persistent variables are maintained in memory the next time the function
% is called.  This allows us to increment the RewardSize variable after
% each trial where there was a hit.
persistent RewardSize

% define a range for the reward size
MinRewardSize = 3;
MaxRewardSize = 6;

if TRIALS.TrialIndex == 1 || isempty(RewardSize) % runs just prior to the first trial of session
    
    WasHit = 0; % initialize before any trials have run
    WasAbort = 0;
    
    RewardSize = MinRewardSize; % begin session with the minimum reward size
    
else
    
    % Response code of the most recent trial. The bitmask of the response
    % code was defined using ep_BitmaskGen GUI and stored in the data table
    % in the RPvds circuit.
    LastTrialIndex = TRIALS.TrialIndex - 1;
    RespCode = TRIALS.DATA(LastTrialIndex).ResponseCode; 
    
    % In the bitmask, bit 3 was defined to indicate whether or not there
    % was a hit
    WasHit = bitget(RespCode,3); 

    % In the bitmask, bit 5 was defined to indicate whether or not the
    % trial was aborted (there was a response that occured before the
    % beginning of the response window)
    WasAbort = bitget(RespCode,5);
end


if WasHit % recent trial was hit, increment reward size
    RewardSize = RewardSize + 1;

else % recent trial was a miss, reset reward to minimum size
    RewardSize = MinRewardSize;
    
end

% Keep reward size within bounds
if RewardSize > MaxRewardSize
    RewardSize = MaxRewardSize;
end


% Update TRIALS structure with new reward value
%   - If the TRIALS structure is not updated here, then the next time there
%   is a trial, the original value for the reward size will be used.
%
% 1. locate the index of the parameter that needs to be updated
tind = ismember(TRIALS.writeparams,'Behavior.Water_Npls');
%
% 2. update all trials with the new RewardSize structure (note that
% TRIALS.trials is a cell matrix)
TRIALS.trials(:,tind) = {RewardSize};


% Makes sure there is an inter-trial interval long enough so that the next
% trial can not be initiated until the entire reward has been delivered.
tind = ismember(TRIALS.writeparams,'Behavior.RewardITI');
TRIALS.trials(:,tind) = {RewardSize*750+RewardSize*200+500};





% If this last trial was aborted, keep the next stimulus the same as the
% last (that is, don't change the value of TRIALS.NextTrialID)

if ~WasAbort
    % The last trial was not aborted (either hit or miss) so randomly
    % select the next trial ID.
    
    % find the least used trials for the next trial index
    m   = min(TRIALS.TrialCount);
    idx = find(TRIALS.TrialCount == m);
    
    % randomly select the next trial
    TRIALS.NextTrialID = idx(randsample(length(idx),1));
end

% Note that the entire TRIALS structure is returned here.  This ensures
% that ep_RunExpt maintains whatever changes we make here







