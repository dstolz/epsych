function [NextTrialID,LastTrialID,Next_trial_type] = ...
    aversive_trialselect_SanesLab(TRIALS,remind_row,...
    trial_type_ind,LastTrialID)
%[NextTrialID,LastTrialID,Next_trial_type] = 
%   aversive_trialselect_SanesLab(TRIALS,remind_row,...
%   trial_type_ind,LastTrialID)
%
%Custom function for SanesLab epsych
%
%Selects the next trial for an aversive paradigm
%
%Inputs: 
%   TRIALS: RUNTIME.TRIALS structure
%   remind_row: the index of the reminder trial row in TRIALS.trials array
%   trial_type_ind: index of the trial type column in TRIALS.writeparams
%   LastTrialID: scalar value indicating which trial was last
%       presented. Value points to a single row in the TRIALS.trials array
%
%Outputs:
%   NextTrialID:scalar value indicating which trial will be presented next. 
%       Value points to a single row in the TRIALS.trials array
%   LastTrialID: scalar value indicating which trial was last
%       presented. Value points to a single row in the TRIALS.trials array
%   Next_trial_type: String indicating the type ('GO', 'NOGO', 'REMINDER')
%       of the next trial. Used for GUI display purposes.
%
%
%Written by ML Caras 8.8.2016

global CONSEC_NOGOS


%Get indices for different trials and determine some probabilities
[go_indices,nogo_indices] = getIndices_SanesLab(TRIALS,remind_row,trial_type_ind);

%Determine our NOGOlimit (drawn from a uniform distribution)
Nogo_lim = NOGOlimit_SanesLab;

%Always make our initial pick a NOGO (1)
initial_random_pick = 1;

%Override initial pick and force a GO trial
%if we've reached our consecutive nogo limit
if CONSEC_NOGOS >= Nogo_lim
    initial_random_pick = 2;
end


%Make the specific pick here
[NextTrialID,LastTrialID,Next_trial_type] = ...
    select_trial_SanesLab(initial_random_pick,...
    nogo_indices,go_indices,LastTrialID,remind_row,...
    trial_type_ind,TRIALS);




