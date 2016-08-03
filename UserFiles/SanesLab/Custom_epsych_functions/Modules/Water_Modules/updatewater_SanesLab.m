function output = updatewater_SanesLab(varargin)
%Custom function for SanesLab epsych
%
%This function queries the pump to obtain the delivered water volume, and 
%updates the GUI text, if appropriate
%
%Inputs:
%   varargin{1}: GUI handles structure
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

%Return volume as string embedded in handles structure (online runtime, 
%or as a double (for final saving).
if nargin == 1
    handles = varargin{1};
    V = V(ind-1:ind+3);
    set(handles.watervol,'String',V);
    output = handles;
else
    output = str2num((V(ind-1:ind+3)));
end
