function TRIALS = TrialFcn_IncrementReward_EXAMPLE(TRIALS)
% TRIALS = TrialFcn_IncrementReward_EXAMPLE(TRIALS)
%
% Increases reward size (within bounds) with consecutive hits.
%
% A miss resets the reward size to a minimum specified value.
%
% See inline comments for more details.
%
% Daniel.Stolzberg@gmail.com 11/2015


% persistent variables are maintained in memory the next time the function
% is called.  This allows us to increment the rewardSize variable after
% each trial where there was a hit.
persistent rewardSize

% define a range for the reward size
minRewardSize = 1;
maxRewardSize = 5;

if TRIALS.TrialIndex == 1 % runs just prior to the first trial of session
    
    wasHit = 0; % initialize before any trials have run
    
    rewardSize = minRewardSize; % begin session with the minimum reward size
    
else
    
    % Response code of the most recent trial. The bitmask of the response
    % code was defined using ep_BitmaskGen GUI and stored in the data table
    % in the RPvds circuit.
    lastTrialIndex = TRIALS.TrialIndex - 1;
    respCode = TRIALS.DATA(lastTrialIndex).ResponseCode; 
	
	% If we want to look at the entire history of Response Codes, use:
	%    respCodes = [TRIALS.DATA.ResponseCode];
    
    % In the bitmask, bit 3 was defined to indicate whether or not there
    % was a hit
    wasHit = bitget(respCode,3); 

end


if wasHit % recent trial was hit, increment reward size
    rewardSize = rewardSize + 1;
    
else % recent trial was a miss, reset reward to minimum size
    rewardSize = minRewardSize;
    
end

% Keep reward size within bounds
if rewardSize > maxRewardSize
    rewardSize = maxRewardSize;
end


% Update TRIALS structure with new reward value
%   - If the TRIALS structure is not updated here, then the next time there
%   is a trial, the original value for the reward size will be used.
%
% 1. locate the index of the parameter that needs to be updated
tind = ismember(TRIALS.writeparams,'Behavior.Water_Npls');
%
% 2. update all trials with the new rewardSize structure (note that
% TRIALS.trials is a cell matrix)
TRIALS.trials(:,tind) = {rewardSize};


% Makes sure there is an inter-trial interval long enough so that the next
% trial can not be initiated until the entire reward has been delivered.
tind = ismember(TRIALS.writeparams,'Behavior.RewardITI');
TRIALS.trials(:,tind) = {rewardSize*750+rewardSize*200+500};



% find the least used trials for the next trial index
m   = min(TRIALS.TrialCount);
idx = find(TRIALS.TrialCount == m);

% randomly select the next trial 
TRIALS.NextTrialID = idx(randsample(length(idx),1)); 

% Note that the entire TRIALS structure is returned here.  This ensures
% that ep_RunExpt maintains whatever changes we make here







