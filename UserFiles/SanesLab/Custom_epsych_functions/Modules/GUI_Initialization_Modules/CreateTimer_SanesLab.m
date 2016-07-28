function T = CreateTimer_SanesLab(hO,fs)
%Custom function for SanesLab epsych
%
%This function creates a new timer for RPVds control of experiment
%
%Inputs: 
%   f: GUI Output function hObject
%   fs: period of timer (seconds)
%
%Written by ML Caras 7.24.2016

%Stop and close existing timers
T = timerfind('Name','BoxTimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

%All values in seconds
T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',fs, ...
    'StartFcn',{@BoxTimerSetup_SanesLab,hO}, ...
    'TimerFcn',{@BoxTimerRunTime_SanesLab,hO}, ...
    'ErrorFcn',{@BoxTimerError_SanesLab}, ...
    'StopFcn', {@BoxTimerStop_SanesLab}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2); 







