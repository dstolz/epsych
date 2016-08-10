function handles = findModuleIndex_SanesLab(moduletype, handles)
%handles = findModuleIndex_SanesLab(moduletype, handles)
%
%Custom function for SanesLab epsych
%
%Inputs:
%   moduletype: a string containing the desired TDT device
%   handles: GUI handles structure
%
%Example usage: handles = findModuleIndex_SanesLab('RZ6',handles);
%
%Written by ML Caras 7.24.2016

global RUNTIME

modules = strfind(RUNTIME.TDT.Module,moduletype);

handles.dev = find(~cellfun('isempty',modules) == 1);

if isfield(RUNTIME.TDT,'name')
    handles.module = RUNTIME.TDT.name{handles.dev};
else
    handles.module = '';
end



end

