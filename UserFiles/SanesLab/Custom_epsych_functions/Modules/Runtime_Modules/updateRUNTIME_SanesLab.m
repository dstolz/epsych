function varargout = updateRUNTIME_SanesLab(varargin)
%Custom function for SanesLab epsych
%
%This function updates the RUNTIME structure and parameters for next trial
%delivery.
%
%Inputs:
%varargin{1}: RUNTIME structure. If not passed as input, RUNTIME is called
%               as a global variable.
%varargin{2}: handle to activeX control. If not passed as input, AX is
%               called as a gloval variable.
%
%Written by ML Caras 7.28.2016



if nargin == 0
    global RUNTIME AX %#ok<TLEV>
    
    for i = 1:RUNTIME.NSubjects
        
        %Reduce TRIALS.TrialCount for the currently selected trial index
        RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = ...
            RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) - 1;
        
        %Re-select the next trial using trial selection function
        RUNTIME.TRIALS(i).NextTrialID = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
        
        %Increment TRIALS.TrialCount for the selected trial index
        RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = ...
            RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) + 1;
        
        %Send trigger to reset components before updating parameters
        if RUNTIME.UseOpenEx
            TrigDATrial(AX,RUNTIME.ResetTrigStr{i});
        else
            TrigRPTrial(AX(RUNTIME.ResetTrigIdx(i)),RUNTIME.ResetTrigStr{i});
        end
        
        %Update parameters for next trial
        feval(sprintf('Update%stags_SanesLab',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
        
        %Send trigger to indicate ready for a new trial
        if RUNTIME.UseOpenEx
            TrigDATrial(AX,RUNTIME.NewTrialStr{i});
        else
            TrigRPTrial(AX(RUNTIME.NewTrialIdx(i)),RUNTIME.NewTrialStr{i});
        end
        
    end
    
else
    RUNTIME = varargin{1};
    AX = varargin{2};
    
    for i = 1:RUNTIME.NSubjects
        
        %Increment trial index
        RUNTIME.TRIALS(i).TrialIndex = RUNTIME.TRIALS(i).TrialIndex + 1;
        
        %Select next trial with custom function
        try
            n = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
            if isstruct(n)
                RUNTIME.TRIALS(i).trials = n.trials;
                RUNTIME.TRIALS(i).NextTrialID = n.NextTrialID;
            elseif isscalar(n)
                RUNTIME.TRIALS(i).NextTrialID = n;
            else
                error('Invalid output from custom trial selection function ''%s''',RUNTIME.TRIALS(i).trialfunc)
            end
        catch me
           vprintf(0,me);
        end
        
        %Increment TRIALS.TrialCount for the selected trial index
        RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = ...
            RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) + 1;
        
        %Send trigger to reset components before updating parameters
        if RUNTIME.UseOpenEx
            TrigDATrial(AX,RUNTIME.ResetTrigStr{i});
        else
            TrigRPTrial(AX(RUNTIME.ResetTrigIdx(i)),RUNTIME.ResetTrigStr{i});
        end
        
        %Update parameters for next trial
        feval(sprintf('Update%stags_SanesLab',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
        
        %Send trigger to indicate ready for a new trial
        if RUNTIME.UseOpenEx
            TrigDATrial(AX,RUNTIME.NewTrialStr{i});
        else
            TrigRPTrial(AX(RUNTIME.NewTrialIdx(i)),RUNTIME.NewTrialStr{i});
        end
        
    end
    
    
end


%Update outputs
if nargout >0
    varargout{1} = RUNTIME;
    varargout{2} = AX;
end
