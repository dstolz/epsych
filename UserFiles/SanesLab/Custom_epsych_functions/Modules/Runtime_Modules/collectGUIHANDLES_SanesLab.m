function collectGUIHANDLES_SanesLab(handles)
%collectGUIHANDLES_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function collects GUI parameters for the selection of the next trial,
%and for pump setting
%
%Inputs:
%   handles: handles structure for GUI
%
%Written by ML Caras 7.24.2016
%kp 11.06.2016


global GUI_HANDLES FUNCS

%Collect generic GUI parameters for selecting next trial
GUI_HANDLES.remind = 0;
GUI_HANDLES.trial_filter = get(handles.TrialFilter);
GUI_HANDLES.trial_order = get(handles.trial_order);
set(handles.trial_order,'ForegroundColor',[0 0 1]);

switch lower(FUNCS.BoxFig)
    case {'aversive_detection_gui','h2opassive_gui'}  %kp
        
        %Collect GUI parameters for selecting next trial
        GUI_HANDLES.Nogo_lim = get(handles.nogo_max);
        GUI_HANDLES.Nogo_min = get(handles.nogo_min);
        
        %For pump settings
        ratestr = get(handles.Pumprate,'String');
        rateval = get(handles.Pumprate,'Value');
        GUI_HANDLES.rate = str2num(ratestr{rateval})/1000; %ml
        
    case {'appetitive_detection_gui','appetitive_detection_gui_v2'}
        
        %Collect GUI parameters for selecting next trial
        GUI_HANDLES.go_prob = get(handles.GoProb);
        GUI_HANDLES.Nogo_lim = get(handles.NOGOlimit);

        GUI_HANDLES.expected_prob = get(handles.ExpectedProb);
        GUI_HANDLES.RepeatNOGO = get(handles.RepeatNOGO);
        GUI_HANDLES.num_reminds = get(handles.num_reminds);
        
        %Get reward volume from GUI
        GUI_HANDLES.vol = getVal(handles.reward_vol)/1000; %ml
        
        %Get reward rate from GUI
        GUI_HANDLES.rate = getVal(handles.Pumprate)/1000; %ml
        
    %Default
    otherwise
        vprintf(0,'Box Figure not defined in collectGUIHANDLES_SanesLab.m. GUI_HANDLES not set.');
end



