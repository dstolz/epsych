function [hObject,handles] = select_change_SanesLab(hObject,handles)
%Custom function for SanesLab epsych
%
%This function updates the dropdown menu color and enables the APPLY button
%when the user selects a new dropdown menu option.
%
%Input:
%   hObject: handle to the GUI dropdown menu
%   handles: GUI handles structure
%
%Written by ML Caras 7.28.2016

%Change the menu color
set(hObject,'ForegroundColor','r');

%Enable the apply button
set(handles.apply,'enable','on');

%If the dropdown menu controls the low and highpass filter options, make
%sure that the values make sense
switch get(hObject,'Tag')
    
    case {'Highpass', 'Lowpass'}
        Highpass_str =  get(handles.Highpass,'String');
        Highpass_val =  get(handles.Highpass,'Value');
        
        Highpass_val = str2num(Highpass_str{Highpass_val}); %Hz
        
        Lowpass_str =  get(handles.Lowpass,'String');
        Lowpass_val =  get(handles.Lowpass,'Value');
        
        Lowpass_val = 1000*str2num(Lowpass_str{Lowpass_val}); %Hz
        
        if Lowpass_val < Highpass_val
            beep
            set(handles.apply,'enable','off');
            errortext = 'Lowpass filter cutoff must be larger than highpass filter cutoff';
            e = errordlg(errortext);
        end
        
end