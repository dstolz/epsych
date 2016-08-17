function handles = Apply_Callback_SanesLab(handles)
%handles = Apply_Callback_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function applies changes made by the user.
%Input:
%   handles: GUI handles structure
%
%Updated by ML Caras 8.17.2016


global  AX FUNCS TRIAL_STATUS

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

%If we're not in the middle of a trial, or we're in the middle of a NOGO
%trial
if trial_TTL == 0 || trial_type == 1
    
    %Collect GUI parameters for selecting next trial
    collectGUIHANDLES_SanesLab(handles);
    
    %Update RUNTIME structure and parameters for next trial delivery
    updateRUNTIME_SanesLab
    
    %Update Next trial information in gui
    handles = updateNextTrial_SanesLab(handles);
    
    %Update pump control
    updatepump_SanesLab(handles)
    
    %-----------------------------------------------------
    %%%%  UPDATE TRIAL HARDWARE AND TIMING PARAMETERS %%%%
    %-----------------------------------------------------
    
    %Update Minimum Poke Duration
    if isfield(handles,'MinPokeDur')
        updatetag_SanesLab(handles.MinPokeDur,handles.module,handles.dev,'MinPokeDur')
    end
    
    %Update Silent Delay Period
    if isfield(handles,'silent_delay')
        updatetag_SanesLab(handles.silent_delay,handles.module,handles.dev,'Silent_delay')
    end
    
    %Update Response Window Delay
    if isfield(handles,'respwin_delay')
        updatetag_SanesLab(handles.respwin_delay,handles.module,handles.dev,'RespWinDelay')
    end
    
    %Update Response Window Duration
    if isfield(handles,'respwin_dur')
        updatetag_SanesLab(handles.respwin_dur,handles.module,handles.dev,'RespWinDur')
    end
        
    %Update intertrial interval
    if isfield(handles,'ITI')
        updatetag_SanesLab(handles.ITI,handles.module,handles.dev,'ITI_dur')
    end
    
    %Update Optogenetic Trigger
    if isfield(handles,'optotrigger')
        updatetag_SanesLab(handles.optotrigger,handles.module,handles.dev,'Optostim')
    end
    
    %Update Shocker Status
    if isfield(handles,'ShockStatus')
        updatetag_SanesLab(handles.ShockStatus,handles.module,handles.dev,'ShockFlag')
    end
    
    if isfield(handles,'Shock_dur')
        updatetag_SanesLab(handles.Shock_dur,handles.module,handles.dev,'ShockDur')
    end
    
    %Update Time Out Duration
    if isfield(handles,'TOduration')
        updatetag_SanesLab(handles.TOduration,handles.module,handles.dev,'to_duration')
    end
    
    
    
    %-------------------------------------
    %%%%  UPDATE SOUND PARAMETERS %%%%
    %-------------------------------------
    
    %Update sound frequency and level
    handles = updateSoundLevelandFreq_SanesLab(handles);
    
    %Update sound duration
    if isfield(handles,'sound_dur')
        updatetag_SanesLab(handles.sound_dur,handles.module,handles.dev,'Stim_Duration')
    end
    
    %Update FM rate
    if isfield(handles,'FMRate')
        updatetag_SanesLab(handles.FMRate,handles.module,handles.dev,'FMrate')
    end
    
    %Update FM depth
    if isfield(handles,'FMDepth')
        updatetag_SanesLab(handles.FMDepth,handles.module,handles.dev,'FMdepth')
    end
    
    %Update AM rate: Important must be called BEFORE update AM depth
    if isfield(handles,'AMRate')
        updatetag_SanesLab(handles.AMRate,handles.module,handles.dev,'AMrate')
    end
    
    %Update AM depth
    if isfield(handles,'AMDepth')
        updatetag_SanesLab(handles.AMDepth,handles.module,handles.dev,'AMdepth')
    end
    
    %Update Highpass cutoff
    if isfield(handles,'Highpass')
        updatetag_SanesLab(handles.Highpass,handles.module,handles.dev,'Highpass')
    end
    
    %Update Lowpass cutoff
    if isfield(handles,'Lowpass')
        updatetag_SanesLab(handles.Lowpass,handles.module,handles.dev,'Lowpass')
    end
    
    
    %Reset foreground colors of remaining drop down menus to blue
    if isfield(handles,'nogo_max')
        set(handles.nogo_max,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'nogo_min')
        set(handles.nogo_min,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'NOGOlimit')
        set(handles.NOGOlimit,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'RepeatNOGO')
        set(handles.RepeatNOGO,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'TrialFilter')
        set(handles.TrialFilter,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'num_reminds')
        set(handles.num_reminds,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'GoProb')
        set(handles.GoProb,'ForegroundColor',[0 0 1]);
    end
    
    if isfield(handles,'ExpectedProb')
        set(handles.ExpectedProb,'ForegroundColor',[0 0 1]);
    end
    
    %Update trial status
    if TRIAL_STATUS == 1 %Indicates user edited trial filter
        TRIAL_STATUS = 2; %Indicates user has applied these changes
    end

    %Disable apply button
    set(handles.apply,'enable','off')
    
end
