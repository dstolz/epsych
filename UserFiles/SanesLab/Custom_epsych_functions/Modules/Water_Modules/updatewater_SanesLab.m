function handles = updatewater_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function updates the GUI text displaying the water volume delivered
%
%Inputs:
%   handles: GUI handles structure
%
%
%Written by ML Caras 7.25.2016

global PUMPHANDLE

%Wait for pump to finish water delivery
pause(0.06)
    
%Flush the pump's input buffer
flushinput(PUMPHANDLE);

%Query the total dispensed volume
fprintf(PUMPHANDLE,'DIS');
[V,count] = fscanf(PUMPHANDLE,'%s',10); %very very slow

%Pull out the digits and display in GUI
ind = regexp(V,'\.');
V = num2str(V(ind-1:ind+3));
set(handles.watervol,'String',V);
