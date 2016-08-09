function [NextTrialID,LastTrialID,Next_trial_type,varargout] = ...
    select_trial_SanesLab(initial_random_pick,nogo_indices,go_indices,...
    LastTrialID,remind_row,trial_type_ind,TRIALS,varargin)
%[NextTrialID,LastTrialID,Next_trial_type,varargout] = ...
%   select_trial_SanesLab(initial_random_pick,nogo_indices,go_indices,...
%  LastTrialID,remind_row,trial_type_ind,TRIALS,varargin)
%
%Custom function for SanesLab epsych
%
%This function selects the row index (in TRIALS.trials array of the next
%trial, and updates the index of the last trial.
%
%Inputs:
%   initial_random_pick: (1 or 2: NOGO or GO, respectively)
%   nogo_indices: the row indices of the nogo trials in TRIALS.trials array
%   go_indices: the row indices of the go trials in TRIALS.trials array
%   LastTrialID: scalar value indicating the index of the last
%          trial presented. Value points to a row in TRIALS.trials array.
%   remind_row: index of the reminder trial row in TRIALS.trials array
%   trial_type_ind: index of the trial type column in TRIALS.writeparams
%   TRIALS: RUNTIME.TRIALS structure
%
%   varargin{1}: scalar value (0 or 1) indicating whether expectation is a
%       roved parameter
%   varargin{2}: scalar value between 0 and 1 indicating the
%       probability of an "expected" trial
%   varargin{3}: row indices of the "expected" trials in TRIALS.trials
%          array
%   varargin{4}: row indices of the "unexpected" trials in TRIALS.trials
%           array
%   varargin{5}: repeat_flag (scalar value of 0 or 1 indicating whether we
%       are currently repeating a NOGO trial because of a previous FA)
%
%Outputs:
%   NextTrialID: scalar value indicating the row index
%       (in TRIALS.trials array) of the next trial to be delivered
%   LastTrialID: scalar value indicating the row index
%       (in TRIALS.trials array) of the last trial presented
%   Next_trial_type: String indicating the type ('GO, 'NOGO', or 'REMIND')
%       of trial coming up (for GUI display purposes.
%
%   varargout{1}: repeat_flag (scalar value of 0 or 1 indicating whether we
%       are currently repeating a NOGO trial because of a previous FA)
%
%
%Written by ML Caras 7.22.2016


global GUI_HANDLES CURRENT_EXPEC_STATUS


%Which trial type did we pick?
switch initial_random_pick
    
    %NOGO selected
    case 1
        NextTrialID = nogo_indices;
        
        %If multiple indices are valid (i.e. there are >1 NOGO indices)
        %then we shuffle the order
        r = randi(numel(NextTrialID),1);
        NextTrialID = NextTrialID(r);
        
        %Pass repeat flag out
        if nargout >3
            varargout{1} = varargin{5};
        end
        
        
        %GO selected
    case 2
        
        NextTrialID = go_indices;
        
        %Reset repeat NOGO flag
        if nargout >3
            varargout{1} = 0;
        end
        
        %-----------------------------------------------------
        %Special case: expected vs. unexpected trial selection
        %------------------------------------------------------
        
        if nargin>7 && ~isempty(varargin{1}) && varargin{1} == 1
            next_random_pick = sum(rand >= cumsum([0, 1-varargin{2}, varargin{2}]));
            
            %Override initial pick and force an expected GO value if
            %the last trial was unexpected
            if  CURRENT_EXPEC_STATUS == 1
                next_random_pick = 2;
            end
            
            %If the next randomly picked number is 2, we picked an expected GO trial
            if next_random_pick == 2
                NextTrialID = varargin{3};
                
                %If the next randomly picked number is 1, we picked an unexpected GO trial
            elseif next_random_pick == 1
                NextTrialID = varargin{4};
            end
            
        end
        
        
        
        %If multiple indices are valid (i.e. there are >1 GO
        %indices), and the user can determine the trial order from the
        %GUI dropdown menu...
        if ~isempty(GUI_HANDLES) &&...
                numel(NextTrialID) > 1 ...
                && isfield(GUI_HANDLES,'trial_order')
            
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
            
            
            %If the user does not have control over the trial order from the
            %GUI, but multiple indices are valid....
        elseif numel(NextTrialID) > 1
            
            
            %Randomly select one of them
            r = randi(numel(NextTrialID),1);
            NextTrialID = NextTrialID(r);
            
            
        end
        
        %Update last trial ID
        LastTrialID = NextTrialID;
        
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
