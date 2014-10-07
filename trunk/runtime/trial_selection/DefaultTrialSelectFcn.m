function TRIALS = DefaultTrialSelectFcn(TRIALS)
% TRIALS = DefaultTrialSelectFcn(TRIALS)
% 
% This is the default function for selecting the next trial and is
% overrided by specifying a custom function name in ep_ExperimentDesign.
% 
% TRIALS is updated and returned.  
% The subfields added or updated:
% TRIALS.NextIndex is the next schedule index, that is the row selected from the
%             TRIALS.COMPILED.trials
% 
% TRIALS.TRIALS.TrialCount is a running count of the number of times each trial has
%              been presented.
% 
% 
% Custom trial selection functions can be written to add more complex,
% dynamic programming to the behavior paradigm.  For example, a custom
% trial selection function can be used to create an adaptive threshold
% tracking paradigm to efficiently track auditbility of tones across sound
% level.
% 
% There are a few basic requirements for custom trial selection functions.
% 1) The function must have the same call syntax as this defualt function. ex:
%   function TRIALS = MyCustomFunction(TRIALS)
% 
% 2) The field TRIALS.TrialCount 
% 
% Daniel.Stolzberg@gmail.com 2014




if ~any(TRIALS.TrialCount)
    % THIS INDICATES THAT WE ARE ABOUT TO BEGIN THE FIRST TRIAL.
    % THIS IS A GOOD PLACE TO TAKE CARE OF ANY SETUP TASKS LIKE PROMPTING
    % THE USER FOR CUSTOM PARAMETERS, ETC.
end



% find the lowest trial count and use it for the next trial index
m   = min(TRIALS.TrialCount);
idx = find(TRIALS.TrialCount == m);
idx = idx(randperm(length(idx)));

TRIALS.NextIndex = idx(1);





% Increment C.TRIALS.TrialCount for the selected trial index
TRIALS.TrialCount(TRIALS.NextIndex) = TRIALS.TrialCount(TRIALS.NextIndex) + 1;









