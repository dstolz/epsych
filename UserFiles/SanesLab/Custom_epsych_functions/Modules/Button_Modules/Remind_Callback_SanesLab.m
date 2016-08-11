function handles = Remind_Callback_SanesLab(handles)
%handles = Remind_Callback_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function forces a reminder trial when the REMIND button is pressed
%Input:
%   handles: GUI handles structure
%
%Written by ML Caras 7.27.2016


global GUI_HANDLES AX FUNCS

%Determine if we're currently in the middle of a trial
trial_TTL = TDTpartag(AX,[handles.module,'.InTrial_TTL']);

%In the aversive paradigm, the user is allowed to apply changes during safe
%trials because trials are completed so quickly. In the appetitive
%paradigm, the user can only apply changes if we're not in the middle of a
%trial.
switch lower(FUNCS.BoxFig)
    
    case 'aversive_detection_gui'
        %Determine if we're in a safe trial
        trial_type = TDTpartag(AX,[handles.module,'.TrialType']);
        
    otherwise
        trial_type = 0;
        
end


%If we're not in the middle of a trial, or we're in the middle of a safe
%trial
if trial_TTL == 0 || trial_type == 1
    
    %Force a reminder for the next trial
    GUI_HANDLES.remind = 1;
    
    %Update RUNTIME structure and parameters for next trial delivery
    updateRUNTIME_SanesLab
    
    %Update Next trial information in gui
    handles = updateNextTrial_SanesLab(handles);
end

