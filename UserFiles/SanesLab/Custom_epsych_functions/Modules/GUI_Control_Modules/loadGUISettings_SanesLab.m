function handles = loadGUISettings_SanesLab(handles)
%handles = loadGUISettings_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function loads GUI settings from a *.GUIset file
%
%Inputs:
%   handles: GUI handles structure
%
%Written by ML Caras 8.3.2016



%Get the path name from the preferred directory
pn = getpref('PSYCH','ProtDir',cd);

%If the preferred directory doesn't exist, use the current directory
if isequal(pn,0)
    pn = cd;
end

%Prompt the user to select the settings file
[fn,pn] = uigetfile({'*.GUIset','GUI Settings File (*.GUIset)'},...
    'Locate GUI Settings File',pn);

%If the user cancelled, abort the function
if ~fn,
    return
end

%Create the file name
ffn = fullfile(pn,fn);


%Update the directory preferences
setpref('PSYCH','ProtDir',pn);


%Load the GUI settings
load(ffn,'-mat');


%Restore the GUI
flds = saveStructure.flds;
property = saveStructure.property;

for i = 1:length(flds)
    set(handles.(flds{i}),'Value',property(i).Value);
    set(handles.(flds{i}),'String',property(i).String);
end


%Update the user
vprintf(0,'Loaded GUI settings\nFile Location: ''%s''\n',ffn')