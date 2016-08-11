function handles = saveGUISettings_SanesLab(handles)
%handles = saveGUISettings_SanesLab(handles)
%
%Custom function for SanesLab epsych
%
%This function saves GUI settings to a file (*.GUIset) 
%that can be re-loaded at a later date.
%
%Inputs: 
%   handles: GUI handles structure
%
%Written by ML Caras 8.3.2016. 



%Get the prefered directory
pn = getpref('PSYCH','ProtDir',cd);

%If the preferred directory doesn't exist, use the current directory
if ~ischar(pn)
    pn = cd;
end

%Prompt user to select file name and storage location
[fn,pn] = uiputfile({'*.GUIset','GUI Settings File File (*.GUIset)'}, ...
    'Save GUI Settings File',pn);

%If the user cancelled, abort the function
if ~fn
    return;
end

%Create the file name
fn = fullfile(pn,fn);

%Update the directory preferences
setpref('PSYCH','ProtDir',pn);




%Find the fieldnames for all dropdown menu options and checkboxes
flds = fieldnames(handles);

for i = 1:length(flds)
   
    if ~isstruct(handles.(flds{i}))
        
        subflds = get(handles.(flds{i}));
        if ~isfield(subflds,'Style')|| any(strcmp(subflds.Style,{'pushbutton','text'}))
            flds{i} = [];
        end
    else
        flds{i} = [];
    end
    
end

flds = flds(~cellfun('isempty',flds));

%Now save some values
saveStructure.flds = flds;

for i = 1:length(flds)
    property(i).Value = get(handles.(flds{i}),'Value'); %#ok<*AGROW>
    property(i).String = get(handles.(flds{i}),'String');
end

saveStructure.property = property; %#ok<*STRNU>

save(fn,'saveStructure','-mat');

%Update the user
vprintf('Saved GUI settings\nFile Location: ''%s''\n',fn')

