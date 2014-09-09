function C = DefaultTrialSelectFcn(C)
% C = DefaultTrialSelectFcn(C)
% 
% This is the default function for selecting the next trial and is
% overrided by specifying a custom function name in ep_ExperimentDesign.
% 
% C is updated and returned.  
% The subfields added or updated:
% C.NextIndex is the next schedule index, that is the row selected from the
%             C.COMPILED.trials
% 
% C.RUNTIME.TrialCount is a running count of the number of times each trial has
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
%   function C = MyCustomFunction(C)
% 
% 2) The field C.TrialCount 
% 
% See also, ep_ExperimentDesign
% 
% Daniel.Stolzberg@gmail.com 2014


% Programmer's note: C is the CONFIG structure after a call to the
% LoadConfig function in ep_RunExpt DJS


if ~any(C.RUNTIME.TrialCount)
    % THIS INDICATES THAT WE ARE ABOUT TO BEGIN THE FIRST TRIAL.
    % THIS IS A GOOD PLACE TO TAKE CARE OF ANY SETUP TASKS LIKE PROMPTING
    % THE USER FOR CUSTOM PARAMETERS, ETC.
end



% find the lowest trial count and use it for the next trial index
m   = min(C.RUNTIME.TrialCount);
idx = find(C.RUNTIME.TrialCount == m);
idx = idx(randperm(length(idx)));

C.RUNTIME.NextIndex = idx(1);





% Increment C.RUNTIME.TrialCount for the selected trial index
C.RUNTIME.TrialCount(C.RUNTIME.NextIndex) = C.RUNTIME.TrialCount(C.RUNTIME.NextIndex) + 1;









