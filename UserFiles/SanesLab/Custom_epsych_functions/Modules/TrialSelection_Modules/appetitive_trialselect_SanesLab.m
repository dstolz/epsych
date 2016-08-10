function [NextTrialID,LastTrialID,Next_trial_type,repeat_flag] = ...
    appetitive_trialselect_SanesLab(TRIALS,remind_row,...
    trial_type_ind,LastTrialID,repeat_flag,varargin)
%[NextTrialID,LastTrialID,Next_trial_type,repeat_flag] = ...
%    appetitive_trialselect_SanesLab(TRIALS,remind_row,trial_type_ind,...
%    LastTrialID,repeat_flag,varargin)
%
%Custom function for SanesLab epsych
%
%Selects the next trial for an appetitive paradigm
%
%Inputs: 
%   TRIALS: RUNTIME.TRIALS structure
%   remind_row: the index of the reminder trial row in TRIALS.trials
%   trial_type_ind: index of the trial type column in TRIALS.writeparams
%   LastTrialID: scalar value indicating which trial was last
%       presented. Value points to a single row in the TRIALS.trials array
%   repeat_flag: scalar value (0 or 1) indicating whether we are currently
%       repeating a NOGO because of a previous FA
%   
%   varargin{1}: scalar value(0 or 1) indicating whether expectation 
%       is a roved parameter
%   varargin{2}: index of expected trial column in TRIALS.writeparams
%
%Outputs:
%   NextTrialID:scalar value indicating which trial will be
%       presented. Value points to a single row in the TRIALS.trials array
%   LastTrialID: scalar value indicating which trial was last
%       presented. Value points to a single row in the TRIALS.trials array
%   Next_trial_type: String indicating the type ('GO', 'NOGO', 'REMINDER')
%       of the next trial. Used for GUI display purposes.
%    repeat_flag:scalar value (0 or 1) indicating whether we are currently
%       repeating a NOGO because of a previous FA
%
%Written by ML Caras 8.8.2016

global CONSEC_NOGOS GUI_HANDLES CURRENT_FA_STATUS


%Set the first N trials to be reminder trials. N is determined by GUI
if ~isempty(GUI_HANDLES)
    num_reminds_ind =  GUI_HANDLES.num_reminds.Value;
    num_reminds = str2num(GUI_HANDLES.num_reminds.String{num_reminds_ind});
else
    num_reminds = 5; %default value
end


%If we haven't yet presented the required number of reminder trials, keep
%presenting reminders, and abort the function.
if TRIALS.TrialIndex <= num_reminds
    NextTrialID = remind_row;
    Next_trial_type = 'REMIND';
    return;
end


%Get indices for different trials and determine some probabilities
[go_indices,nogo_indices,repeat_checkbox,Go_prob,Nogo_lim,...
    expect_indices,unexpect_indices,Expected_prob] = ...
    getIndices_SanesLab(TRIALS,remind_row,trial_type_ind,varargin{2});


%Make our initial random pick (for GO or NOGO trial type)
initial_random_pick = sum(rand >= cumsum([0, 1-Go_prob, Go_prob]));

%-----------------------------------------------------------------
%Special case overrides
%-----------------------------------------------------------------
%Override initial pick and force a NOGOtrial if the last trial was a
%FA, and if the "Repeat if FA" checkbox is activated
if CURRENT_FA_STATUS == 1 && repeat_checkbox == 1
    initial_random_pick = 1;
    repeat_flag = 1;
end

%Override initial pick or NOGO repeat and force a GO trial
%if we've reached our consecutive nogo limit
if CONSEC_NOGOS >= Nogo_lim && Go_prob > 0
    initial_random_pick = 2;
end

%Override initial pick and force a GO trial if the animal got a
%repeated FA trial correct
if repeat_flag == 1 && CURRENT_FA_STATUS == 0 && Go_prob > 0
    initial_random_pick = 2;
end
%-----------------------------------------------------------------
%-----------------------------------------------------------------

%Make the specific pick here
[NextTrialID,LastTrialID,Next_trial_type,repeat_flag] = ...
    select_trial_SanesLab(initial_random_pick,...
    nogo_indices,go_indices,LastTrialID,remind_row,trial_type_ind,TRIALS,...
    varargin{1},Expected_prob,expect_indices,unexpect_indices,repeat_flag);



