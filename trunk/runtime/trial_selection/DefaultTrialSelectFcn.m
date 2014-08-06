function C = DefaultTrialSelectFcn(C,FirstTrial)
% C = DefaultTrialSelectFcn(C,FirstTrial)
% 
% This is the default function for selecting the next trial and is
% overrided by specifying a custom function name in ep_ExperimentDesign.
% 
% C is the config structure from ep_RunExpt.LoadConfig
% 
% C is updated and returned.  
% The subfields added or updated:
% C.NextIndex is the next schedule index, that is the row selected from the
%             C.COMPILED.trials
% 
% C.TrialCount is a running count of the number of times each trial has
%              been presented.
% 
% FirstTrial should be specified as logical TRUE on the first trial.
% Otherwise it should be FALSE.
% 
% See also, ep_ExperimentDesign
% 
% Daniel.Stolzberg@gmail.com 2014


% On the first call, initialize C.TrialCount with an array of zeros the
% the same number of trials specified in ep_ExperimentDesign
if FirstTrial
    C.TrialCount = zeros(size(C.COMPILED.trials,1),1);
end


% find the lowest trial count
m = min(C.TrialCount);
idx = find(C.TrialCount == m);
idx = idx(randperm(length(idx)));

% Select the next trial index
C.NextIndex = idx(1);

% Increment C.TrialCount for the selected trial index
C.TrialCount(C.NextIndex) = C.TrialCount(C.NextIndex) + 1;









