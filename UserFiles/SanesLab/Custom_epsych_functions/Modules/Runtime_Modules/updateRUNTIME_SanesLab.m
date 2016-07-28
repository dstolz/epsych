function updateRUNTIME_SanesLab
%Custom function for SanesLab epsych
%
%This function updates the RUNTIME structure and parameters for next trial
%delivery
%
%
%Written by ML Caras 7.28.2016

global RUNTIME AX


%Reduce TRIALS.TrialCount for the currently selected trial index
RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) = ...
    RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) - 1;

%Re-select the next trial using trial selection function
RUNTIME.TRIALS.NextTrialID = feval(RUNTIME.TRIALS.trialfunc,RUNTIME.TRIALS);


%Increment TRIALS.TrialCount for the selected trial index
RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) = ...
    RUNTIME.TRIALS.TrialCount(RUNTIME.TRIALS.NextTrialID) + 1;

%Send trigger to reset components before updating parameters
if RUNTIME.UseOpenEx
    TrigDATrial(AX,RUNTIME.ResetTrigStr{1});
else
    TrigRPTrial(AX(RUNTIME.ResetTrigIdx),RUNTIME.ResetTrigStr{1});
end

%Update parameters for next trial
feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS);

%Send trigger to indicate ready for a new trial
if RUNTIME.UseOpenEx
    TrigDATrial(AX,RUNTIME.NewTrialStr{1});
else
    TrigRPTrial(AX(RUNTIME.NewTrialIdx),RUNTIME.NewTrialStr{1});
end


