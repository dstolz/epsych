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
%               handles = findModuleInex_SanesLab('Phys',handles);
%
%If 'Phys' is given for moduletype, then the program first looks for an
%RZ5. If no RZ5 is found, the program looks for an RZ2.
%
%Written by ML Caras 7.24.2016. 
%Updated by KP 2016-12. 
%Updated ML Caras 2.20.18

global RUNTIME

switch moduletype
    case 'Phys'
        %Default to RZ5
        moduletype = 'RZ5';
        modules = strfind(RUNTIME.TDT.Module,moduletype);
        handles.dev = find(~cellfun('isempty',modules) == 1);
        
        %If RZ5 is not found, try RZ2
        if isempty(handles.dev)
            moduletype = 'RZ2';
            modules = strfind(RUNTIME.TDT.Module,moduletype);
            handles.dev = find(~cellfun('isempty',modules) == 1);
        end
        
    otherwise
        modules = strfind(RUNTIME.TDT.Module,moduletype);
        handles.dev = find(~cellfun('isempty',modules) == 1);
end

if isfield(RUNTIME.TDT,'name')
    handles.module = RUNTIME.TDT.name{handles.dev};
else
    mod = fieldnames(RUNTIME.TRIALS.MODULES);
    handles.module = mod{1};
end

end

