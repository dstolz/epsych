function handles = initializeTrialDelivery_SanesLab(handles)
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

global RUNTIME AX


%Pause Trial Delivery
if RUNTIME.UseOpenEx
    AX.SetTargetVal('Behavior.TrialDelivery',0);
else
    AX.SetTagVal('TrialDelivery',0);
end

%Enable deliver trials button and disable pause trial button
set(handles.DeliverTrials,'enable','on');
set(handles.PauseTrials,'enable','off');

%Disable apply button
set(handles.apply,'enable','off');