function collectGUIHANDLES_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function collects GUI parameters for the selection of the next trial,
%and for pump setting
%
%Inputs:
%   handles: handles structure for GUI
%   cols: cell array of column names for GUI table
%
%Written by ML Caras 7.24.2016


global GUI_HANDLES

%For next trial selection
GUI_HANDLES.remind = 0;
GUI_HANDLES.Nogo_lim = get(handles.nogo_max);
GUI_HANDLES.Nogo_min = get(handles.nogo_min);
GUI_HANDLES.trial_filter = get(handles.TrialFilter);
GUI_HANDLES.trial_order = get(handles.trial_order);


%For pump settings
ratestr = get(handles.Pumprate,'String');
rateval = get(handles.Pumprate,'Value');
GUI_HANDLES.rate = str2num(ratestr{rateval})/1000; %ml