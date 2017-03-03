function [NextTrialID,LastTrialID,Next_trial_type] = ...
    passive_trialselect_SanesLab(TRIALS,remind_row,...
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
%Written by KP, 2017-03. Adapted from MLC trial functions.
%

global GUI_HANDLES

%Get indices for different trials and determine some probabilities
[go_indices,nogo_indices] = getIndices_SanesLab(TRIALS,remind_row,trial_type_ind);

%%%
%Make the specific pick here
% [NextTrialID,LastTrialID,Next_trial_type] = ...
%     select_trial_SanesLab(initial_random_pick,...
%     nogo_indices,go_indices,LastTrialID,remind_row,...
%     trial_type_ind,TRIALS);
%%%

% For passive presentation, we don't care about go and nogo designation
NextTrialID = sort([go_indices; nogo_indices]);

% Pieces of code lifted from select_trial_SanesLab.m and adapted for
% passive protocol



%If multiple indices are valid (i.e. there are >1 GO
%indices), and the user can determine the trial order from the
%GUI dropdown menu...
if ~isempty(GUI_HANDLES) &&...
        numel(NextTrialID) > 1 ...
        && isfield(GUI_HANDLES,'trial_order')
    
    switch GUI_HANDLES.trial_order.String{GUI_HANDLES.trial_order.Value}
        
        case 'Shuffled'
            
            if TRIALS.TrialIndex < (2*numel(NextTrialID))
                
                % Select with uniform probability in the beginning
                r = randi(numel(NextTrialID),1);
                NextTrialID = NextTrialID(r);
                
            else
                % After several trials, select next trial with probability
                % inversely proportional to current number of trials.
                ntrials = TRIALS.TrialCount(NextTrialID);
                
                adjusted_pick_prob = 2*(mean(ntrials) - ntrials)./sum(ntrials) + (1/numel(ntrials));
                
                adjusted_TrialID_vec = [];
                for istim = 1:numel(NextTrialID)
                    adjusted_TrialID_vec = [adjusted_TrialID_vec; repmat(NextTrialID(istim),[round(adjusted_pick_prob(istim)*100),1])];
                end
                
                r = randi(numel(adjusted_TrialID_vec),1);
                NextTrialID = adjusted_TrialID_vec(r);
                
            end
            
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
    
    
    %If the user does not have control over the trial order from the
    %GUI, but multiple indices are valid....
elseif numel(NextTrialID) > 1
    
    
    %Randomly select one of them
    r = randi(numel(NextTrialID),1);
    NextTrialID = NextTrialID(r);
    
    
end



%Update last trial ID
LastTrialID = NextTrialID;


%Override initial pick and force a reminder trial if the remind buttom
%was pressed by the end user
if ~isempty(GUI_HANDLES) && GUI_HANDLES.remind == 1
    NextTrialID = remind_row;
    GUI_HANDLES.remind = 0;
end


%Determine the next trial type for display
if NextTrialID == remind_row;
    Next_trial_type = 'REMIND';
elseif TRIALS.trials{NextTrialID,trial_type_ind} == 0
    Next_trial_type = 'GO';
elseif TRIALS.trials{NextTrialID,trial_type_ind} == 1;
    Next_trial_type = 'NOGO';
end











