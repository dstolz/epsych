function handles = initializeTrialDelivery_SanesLab(handles)
%handles = initializeTrialDelivery_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function initializes the GUI with trial delivery paused, and the
%apply button disabled.
%
%Inputs:
%   handles: handles structure for GUI
%
%
%Written by ML Caras 7.24.2016

global AX 


%Pause Trial Delivery
v = TDTpartag(AX,[handles.module,'.~TrialDelivery'],0);

%Enable deliver trials button and disable pause trial button
set(handles.DeliverTrials,'enable','on');
set(handles.PauseTrials,'enable','off');

%Disable apply button
set(handles.apply,'enable','off');