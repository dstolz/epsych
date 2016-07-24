function handles = setupIOplot_SanesLab(handles)
%Custom function for SanesLab epsych
%
%This function sets up the input-output plot axes and options
%
%Inputs:
%   handles: handles structure for GUI
%   cols: cell array of column names for GUI table
%
%Written by ML Caras 7.24.2016



global RUNTIME ROVED_PARAMS


%Setup X-axis options for I/O plot
if RUNTIME.UseOpenEx
    ind = ~strcmpi(ROVED_PARAMS,'Behavior.TrialType');
    rp =  cellfun(@(x) x(10:end), ROVED_PARAMS, 'UniformOutput',false);
    xaxis_opts = rp(ind);
else
    ind = ~strcmpi(ROVED_PARAMS,'TrialType');
    xaxis_opts = ROVED_PARAMS(ind);
end

if ~isempty(xaxis_opts)
    set(handles.Xaxis,'String',xaxis_opts)
    set(handles.group_plot,'String', ['None', xaxis_opts]);
else
    set(handles.Xaxis,'String',{'TrialType'})
    set(handles.group_plot,'String',{'None'})
end

%Establish predetermined yaxis options
yaxis_opts = {'Hit Rate', 'd'''};
set(handles.Yaxis,'String',yaxis_opts);


%Link x axes for realtime plotting
realtimeAx = [handles.trialAx,handles.spoutAx,];
linkaxes(realtimeAx,'x');