function trial_type_ind =  findTrialTypeColumn_SanesLab(colnames)
%trial_type_ind =  findTrialTypeColumn_SanesLab(colnames)
%
%Custom function for SanesLab epsych
%
%This function finds the column index for the trial type
%
%Input:
%   cellstring array of column names
%
%Output: 
%   index specifying the TrialType Column
%
%Written by ML Caras 7.22.2016

global RUNTIME

%Find the name of the RZ6 module
h = findModuleIndex_SanesLab('RZ6',[]);

%Find the trial type column
if RUNTIME.UseOpenEx
    trial_type_ind = find(ismember(colnames,[h.module,'.TrialType']));
else
    trial_type_ind = find(ismember(colnames,'TrialType'));
end





end