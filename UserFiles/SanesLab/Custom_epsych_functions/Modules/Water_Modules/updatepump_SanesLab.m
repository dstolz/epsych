function updatepump_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function sets the pump rate using flow rate specified in the GUI
%
%Inputs:
%   handles: GUI handles structure
%
%
%Written by ML Caras 7.25.2016


global PUMPHANDLE GUI_HANDLES

%Get reward rate from GUI
ratestr = get(handles.Pumprate,'String');
rateval = get(handles.Pumprate,'Value');
GUI_HANDLES.rate = str2num(ratestr{rateval}); %ml/min

%Set pump rate directly (ml/min)
fprintf(PUMPHANDLE,'RAT%0.1f\n',GUI_HANDLES.rate)


set(handles.Pumprate,'ForegroundColor',[0 0 1]);
