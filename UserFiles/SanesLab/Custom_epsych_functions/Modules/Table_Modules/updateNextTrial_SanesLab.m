function handles = updateNextTrial_SanesLab(handles)
%handles = updateNextTrial_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function updates the GUI Next Trial Table
%Input:
%   handles: GUI handles structure
%
%Written by ML Caras 7.27.2016


global USERDATA

%Create a cell array containing the information for the next trial
NextTrialData = struct2cell(USERDATA)';


%Update the table handle
set(handles.NextTrial,'Data',NextTrialData);