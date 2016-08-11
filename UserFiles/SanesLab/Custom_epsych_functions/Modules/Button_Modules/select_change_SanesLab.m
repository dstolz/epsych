function [hObject,handles] = select_change_SanesLab(hObject,handles)
%[hObject,handles] = select_change_SanesLab(hObject,handles)
%
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

%Take care of some special cases here
switch get(hObject,'Tag')
    
    
    %Make sure the low and highpass filter settings make sense
    case {'Highpass', 'Lowpass'}
        Highpass_str =  get(handles.Highpass,'String');
        Highpass_val =  get(handles.Highpass,'Value');
        
        Highpass_val = str2num(Highpass_str{Highpass_val}); %#ok<*ST2NM> %Hz
        
        Lowpass_str =  get(handles.Lowpass,'String');
        Lowpass_val =  get(handles.Lowpass,'Value');
        
        Lowpass_val = 1000*str2num(Lowpass_str{Lowpass_val}); %Hz
        
        if Lowpass_val < Highpass_val
            beep
            set(handles.apply,'enable','off');
            errortext = 'Lowpass filter cutoff must be larger than highpass filter cutoff';
            errordlg(errortext);
        end
        
    %Make sure the response window doesn't open before the sound onset    
    case {'silent_delay', ' respwin_delay'}
        silent_delay_str =  get(handles.silent_delay,'String');
        silent_delay_val =  get(handles.silent_delay,'Value');
        
        silent_delay_val = str2num(silent_delay_str{silent_delay_val});
        
        
        respwin_delay_str =  get(handles.respwin_delay,'String');
        respwin_delay_val =  get(handles.respwin_delay,'Value');
        
        respwin_delay_val = str2num(respwin_delay_str{respwin_delay_val});
        
        if respwin_delay_val < silent_delay_val
            beep
            set(handles.apply,'enable','off');
            question = 'Are you sure you want the response window to open before the sound onset?';
            handles.choice = questdlg(question,'Value check','Yes','No','No');
            
            switch handles.choice
                case 'Yes'
                    set(handles.apply,'enable','on')
            end
            
        end
        
end