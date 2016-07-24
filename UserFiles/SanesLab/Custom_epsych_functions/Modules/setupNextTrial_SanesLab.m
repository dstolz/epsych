function handles = setupNextTrial_SanesLab(handles)
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
    rp =  cellfun(@(x) x(10:end), ROVED_PARAMS, 'UniformOutput',false);
    set(handles.NextTrial,'Data',empty_cell,'ColumnName',rp);
else
    set(handles.NextTrial,'Data',empty_cell,'ColumnName',ROVED_PARAMS);
end
