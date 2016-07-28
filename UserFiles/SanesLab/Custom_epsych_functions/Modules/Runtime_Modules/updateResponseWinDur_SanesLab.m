function updateResponseWinDur_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function sets the response window duration in the RPVds circuit
%
%Inputs:
%   handles: GUI handles structure
%
%
%Written by ML Caras 7.25.2016

global AX RUNTIME

switch get(handles.respwin_dur,'enable')
    
    case 'on'
        %Get response window duration from GUI
        str = get(handles.respwin_dur,'String');
        val = get(handles.respwin_dur,'Value');
        dur = str2num(str{val})*1000; %msec
        
        %Use Active X controls to set duration directly in RPVds circuit
        if RUNTIME.UseOpenEx
            AX.SetTargetVal('Behavior.RespWinDur',dur);
        else
            AX.SetTagVal('RespWinDur',dur);
        end
        
        set(handles.respwin_dur,'ForegroundColor',[0 0 1]);
end
