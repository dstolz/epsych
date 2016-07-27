function trial_type_ind =  findTrialTypeColumn_SanesLab(colnames)
%Custom function for SanesLab epsych
%
%This function finds the column index for the trial type
%Input is cell array of column names
%
%Written by ML Caras 7.22.2016

global RUNTIME


if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(colnames,'Behavior.TrialType'));
else
    trial_type_ind = find(ismember(colnames,'TrialType'));
end





end