function handles = setupNextTrial_SanesLab(handles)
%handles = setupNextTrial_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function sets up the GUI next trial table 
%
%Inputs:
%   handles: handles structure for GUI
%
%
%Written by ML Caras 7.24.2016

global RUNTIME ROVED_PARAMS


empty_cell = cell(1,numel(ROVED_PARAMS));



if RUNTIME.UseOpenEx
    strstart = length(handles.module)+2;
    rp =  cellfun(@(x) x(strstart:end), ROVED_PARAMS, 'UniformOutput',false);
    set(handles.NextTrial,'Data',empty_cell,'ColumnName',rp);
else
    set(handles.NextTrial,'Data',empty_cell,'ColumnName',ROVED_PARAMS);
end
