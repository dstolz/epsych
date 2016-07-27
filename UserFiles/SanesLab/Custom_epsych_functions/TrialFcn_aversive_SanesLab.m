function NextTrialID = TrialFcn_aversive_SanesLab(TRIALS)
%Custom function for SanesLab epsych
%For use with: Aversive GO-NOGO tasks
%
% NextTrialID is the index of a row in TRIALS.trials. This row contains all
% of the information for the next trial.
%
% Updated by ML Caras Jul 22 2016

global USERDATA ROVED_PARAMS PUMPHANDLE
global CONSEC_NOGOS 
persistent LastTrialID ok remind_row


%Seed the random number generator based on the current time so that we
%don't end up with the same sequence of trials each session
rng('shuffle');

%Find reminder column and row
if isempty(ok)
    remind_row = findReminderRow_SanesLab(TRIALS.writeparams,TRIALS.trials);
end


%If there is more than one reminder trial, prompt user to select which
%reminder trial he/she would like to use.
if numel(remind_row) > 1 && isempty(ok)
    [ok,remind_row] = selectReminder_SanesLab(TRIALS,remind_row); 
end


%If it's the very start of the experiment...
if TRIALS.TrialIndex == 1
    
    %Start fresh
    USERDATA = [];
    ROVED_PARAMS = [];
    CONSEC_NOGOS = [];
    LastTrialID = [];

    %If the pump has not yet been initialized
    if isempty(PUMPHANDLE)
        
        %Close all serial ports, open a new one and initialize pump
        PUMPHANDLE = TrialFcn_PumpControl_SanesLab;
        
    end
    
    %Identify all roved parameters. Note: we discard the reminder trial row
    findRovedPARAMS_SanesLab(TRIALS,remind_row)
end


%Find the column index for Trial Type
trial_type_ind =  findTrialTypeColumn_SanesLab(TRIALS.writeparams);



%-----------------------------------------------------------------
%%%%%%%%%%%%%%%%% TRIAL SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-----------------------------------------------------------------

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

%Update USERDATA Structure
update_USERDATA_SanesLab(Next_trial_type,NextTrialID,TRIALS)









