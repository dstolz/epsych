function NextTrialID = TrialFcn_aversive_SanesLab(TRIALS)
%Custom function for SanesLab epsych
%For use with: Aversive GO-NOGO tasks
%
% NextTrialID is the index of a row in TRIALS.trials. This row contains all
% of the information for the next trial.
%
% Updated by ML Caras Jul 22 2016

global USERDATA ROVED_PARAMS PUMPHANDLE RUNTIME FUNCS
global CONSEC_NOGOS CURRENT_FA_STATUS CURRENT_EXPEC_STATUS
persistent LastTrialID ok remind_row repeat_flag


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
    CURRENT_FA_STATUS = [];
    CURRENT_EXPEC_STATUS = [];
    LastTrialID = [];

    %If the pump has not yet been initialized
    if isempty(PUMPHANDLE)
        
        %Close all serial ports, open a new one and initialize pump
        PUMPHANDLE = TrialFcn_PumpControl_SanesLab;
        
    end
    
    %Identify all roved parameters. Note: we discard the reminder trial row
    findRovedPARAMS_SanesLab(TRIALS,remind_row)
    
    %Set repeat flag to zero
    repeat_flag = 0;
end


%Find the column index for Trial Type
trial_type_ind =  findTrialTypeColumn_SanesLab(TRIALS.writeparams);


%If we're running an appetitive GO-NOGO paradigm,
%determine if expectation is a roved parameter
switch lower(FUNCS.BoxFig)
    
    case {'appetitive_detection_gui','appetitive_detection_gui_v2'}
        
        %Find name of RZ6 module
        h = findModuleIndex_SanesLab('RZ6', []);
        
        %Define name of expected parameter tag
        if RUNTIME.UseOpenEx
            expect_paramtag = [h.module,'.Expected'];
        else
            expect_paramtag = 'Expected';
        end
        
        %Determine whether expectation is roved
        expectation_roved = cell2mat(strfind(ROVED_PARAMS,expect_paramtag));
        
        if expectation_roved
            expected_ind = find(ismember(TRIALS.writeparams,expect_paramtag));
        else
            expected_ind = [];
        end
        
        %Select the next trial for an appetitive paradigm
        [NextTrialID,LastTrialID,Next_trial_type] = ...
            appetitive_trialselect_SanesLab(TRIALS,remind_row,...
            trial_type_ind,LastTrialID,expectation_roved,expected_ind);
        
    case 'aversive_detection_gui'
        
        %Select the next trial for an aversive paradigm
        [NextTrialID,LastTrialID,Next_trial_type] = ...
            aversive_trialselect_SanesLab(TRIALS,remind_row,...
            trial_type_ind,LastTrialID);
end


%Update USERDATA Structure
update_USERDATA_SanesLab(Next_trial_type,NextTrialID,TRIALS)









