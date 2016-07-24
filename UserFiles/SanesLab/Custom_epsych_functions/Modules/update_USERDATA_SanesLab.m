function update_USERDATA_SanesLab(Next_trial_type,NextTrialID,TRIALS)
%Custom function for SanesLab epsych
%This function updates the global variable USERDATA. Inputs are the
%Next_trial_type (char) and the TRIALS structure.
%
%
%Written by ML Caras 7.22.2016

global ROVED_PARAMS USERDATA RUNTIME

%Update USERDATA Structure
for i = 1:numel(ROVED_PARAMS)
    
    variable = ROVED_PARAMS{i};
    
    
    switch variable
        case {'TrialType','Behavior.TrialType'}
            USERDATA.TrialType = Next_trial_type;
            
        case {'Reminder','Behavior.Reminder'}
            if RUNTIME.UseOpenEx
                ind = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
            else
                ind = find(ismember(TRIALS.writeparams,'Reminder'));
            end
            
            USERDATA.Reminder = TRIALS.trials{NextTrialID,ind};
            
        otherwise
            ind = find(ismember(TRIALS.writeparams,variable));
            
            %Update USERDATA
            if RUNTIME.UseOpenEx
                eval(['USERDATA.' variable(10:end) '= TRIALS.trials{NextTrialID,ind};'])
            else
                eval(['USERDATA.' variable '= TRIALS.trials{NextTrialID,ind};'])
            end
    end
    
end


end