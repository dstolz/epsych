function NextTrialID = DefaultTrialSelectFcn(TRIALS)
% NextTrialID = DefaultTrialSelectFcn(TRIALS)
% 
% This is the default function for selecting the next trial and is
% overrided by specifying a custom function name in ep_ExperimentDesign.
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
% The function must have the same call syntax as this default function. 
%       ex:
%           function NextTrialID = MyCustomFunction(TRIALS)
% 
% Daniel.Stolzberg@gmail.com 2014




if TRIALS.TrialIndex == 1
    % THIS INDICATES THAT WE ARE ABOUT TO BEGIN THE FIRST TRIAL.
    % THIS IS A GOOD PLACE TO TAKE CARE OF ANY SETUP TASKS LIKE PROMPTING
    % THE USER FOR CUSTOM PARAMETERS, ETC.
end



% find the least used trials for the next trial index
m   = min(TRIALS.TrialCount);
idx = find(TRIALS.TrialCount == m);

NextTrialID = idx(randi(length(idx),1));














