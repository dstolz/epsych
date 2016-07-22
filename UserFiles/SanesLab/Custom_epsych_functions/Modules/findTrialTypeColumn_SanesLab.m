function trial_type_ind =  findTrialTypeColumn_SanesLab(TRIALS)
%Custom function for SanesLab epsych
%Input is TRIALS structure
%Output is the index of the trial type column
%
%Written by ML Caras 7.22.2016

global RUNTIME


if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(TRIALS.writeparams,'Behavior.TrialType'));
else
    trial_type_ind = find(ismember(TRIALS.writeparams,'TrialType'));
end





end