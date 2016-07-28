function [NextTrialID,LastTrialID,Next_trial_type] = ...
    select_trial_SanesLab(initial_random_pick,...
    nogo_indices,go_indices,LastTrialID,...
    remind_row,trial_type_ind,TRIALS)
%Custom function for SanesLab epsych
%This function selects the index of the next trial, and updates the index
%of the last trial. Inputs are the initial_random_pick (1 or 2: NOGO or GO,
%respectively), the row indices of the nogo and go trials, and the index of
%the last trial (LastTrialID). Outputs are the NextTrialID (index) the
%LastTrialID(index) and the Next_trial_type (char).
%
%
%Written by ML Caras 7.22.2016


global GUI_HANDLES

%Which trial type did we pick?
switch initial_random_pick
    
    %NOGO selected
    case 1
        NextTrialID = nogo_indices;
        
        %If multiple indices are valid (i.e. there are >1 NOGO indices)
        %then we shuffle the order
        r = randi(numel(NextTrialID),1);
        NextTrialID = NextTrialID(r);
        
        
        %GO selected
    case 2
        NextTrialID = go_indices;
        
        
        %If multiple indices are valid (i.e. there are >1 GO
        %indices), then we need to know the desired trial order
        if ~isempty(GUI_HANDLES) && numel(NextTrialID) > 1
            
            switch GUI_HANDLES.trial_order.String{GUI_HANDLES.trial_order.Value}
                
                case 'Shuffled'
                    r = randi(numel(NextTrialID),1);
                    NextTrialID = NextTrialID(r);
                    
                case 'Ascending'
                    
                    %If this is the first GO trial, or we've cycled through all
                    %trials, start from the beginning
                    if isempty(LastTrialID) || LastTrialID == NextTrialID(end)
                        NextTrialID = NextTrialID(1);
                        
                        %Otherwise, present the next GO trial
                    elseif LastTrialID < NextTrialID(end)
                        ind =  find(NextTrialID == LastTrialID) + 1;
                        NextTrialID = NextTrialID(ind);
                        
                    end
                    
                    
                case 'Descending'
                    
                    %If this is the first GO trial, or we've cycled through all
                    %trials, start from the beginning
                    if isempty(LastTrialID) || LastTrialID == NextTrialID(1)
                        NextTrialID = NextTrialID(end);
                        
                    elseif LastTrialID > NextTrialID(1)
                        ind =  find(NextTrialID == LastTrialID) - 1;
                        NextTrialID = NextTrialID(ind);
                    end
                    
            end
            
            %Update last trial ID
            LastTrialID = NextTrialID;
            
        end
        
end


%Override initial pick and force a reminder trial if the remind buttom
%was pressed by the end user
if ~isempty(GUI_HANDLES)
    if GUI_HANDLES.remind == 1;
        NextTrialID = remind_row;
        GUI_HANDLES.remind = 0;
    end
end


%Determine the next trial type for display
if NextTrialID == remind_row;
    Next_trial_type = 'REMIND';
elseif TRIALS.trials{NextTrialID,trial_type_ind} == 0
    Next_trial_type = 'GO';
elseif TRIALS.trials{NextTrialID,trial_type_ind} == 1;
    Next_trial_type = 'NOGO';
end


end
