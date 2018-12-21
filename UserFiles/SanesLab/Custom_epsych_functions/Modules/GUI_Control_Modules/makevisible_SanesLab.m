function makevisible_SanesLab(h,dev,module,param)
%makevisible_SanesLab(h,dev,module,param)
%
%Custom function for SanesLab epsych
%
%This function makes certain GUI text and dropdown menus visible if the 
%correct parameter tags are available in the circuit.
%
%Inputs:
%   h: handles of dropdown menu or text
%   dev: index of RZ6 TDT module
%   module: name of RZ6 TDT module
%   param: parameter tag string
%
%Example usage: makevisible_SanesLab(handles.freq,handles.dev,handles.module,'Freq')
%
%Written by ML Caras 3.15.2018


global RUNTIME

%Tag name in RPVds
tag = param;

% %Rename parameter for OpenEx Compatibility
% if RUNTIME.UseOpenEx
%     param = [module,'.',param];
% end

%Is the tag in the cicuit?
circuit_tags = RUNTIME.TDT.devinfo(dev).tags;

if ~isempty(find(ismember(circuit_tags,tag),1))
    set(h,'visible','on');
end