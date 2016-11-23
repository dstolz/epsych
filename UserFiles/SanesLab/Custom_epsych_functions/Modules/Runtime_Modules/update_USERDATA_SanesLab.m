function update_USERDATA_SanesLab(Next_trial_type,NextTrialID,TRIALS)
%update_USERDATA_SanesLab(Next_trial_type,NextTrialID,TRIALS)
%
%Custom function for SanesLab epsych
%
%This function updates the global variable USERDATA. 
%
%Inputs:
%   Next_trial_type: String indicating the type ('GO', 'NOGO' or 'REMIND") of
%       the next trial. Used for GUI display purposes. 
%   NextTrialID: row index in TRIALS.trials array of the next trial
%   TRIALS: RUNTIME.TRIALS structure.
%
%
%Written by ML Caras 7.22.2016.
%Updated by KP 11.4.2016. (param WAV/MAT compatibility)

global ROVED_PARAMS USERDATA RUNTIME

%Find name of RZ6 module
h = findModuleIndex_SanesLab('RZ6', []);


%Update USERDATA Structure
for i = 1:numel(ROVED_PARAMS)
    
    variable = ROVED_PARAMS{i};
    
    switch variable
        case {'TrialType',[h.module,'.TrialType']}
            USERDATA.TrialType = Next_trial_type;
            
        case {'Reminder',[h.module,'.Reminder']'}
            if RUNTIME.UseOpenEx
                ind = find(ismember(TRIALS.writeparams,[h.module,'.Reminder']));
            else
                ind = find(ismember(TRIALS.writeparams,'Reminder'));
            end
            
            USERDATA.Reminder = TRIALS.trials{NextTrialID,ind};
            
        otherwise
            ind = find(ismember(TRIALS.writeparams,variable));
            
            %Update USERDATA
            if RUNTIME.UseOpenEx
                %Make sure param name compatible           %kp
                strstart = length(h.module)+2;
                variableStr = variable(strstart:end);
                variableStr(strncmp(variableStr,'~',1))='';
                
                eval(['USERDATA.' variableStr '= TRIALS.trials{NextTrialID,ind};'])
            else
                %Make sure param name compatible           %kp
                variable(strncmp(variable,'~',1))='';
                
                eval(['USERDATA.' variable '= TRIALS.trials{NextTrialID,ind};'])
            end
    end
    
end


end