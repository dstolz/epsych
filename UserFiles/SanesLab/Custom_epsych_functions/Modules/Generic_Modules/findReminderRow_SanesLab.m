function [remind_row,varargout] = findReminderRow_SanesLab(colnames,trials)
%[remind_row,varargout] = findReminderRow_SanesLab(colnames,trials)
%
%Custom function for SanesLab epsych
%
%This function finds the row and column index for the reminder trial
%
%Inputs:
%   colnames: cellstring array of column names
%   trials: cell array of trial parameters 
%
%Written by ML Caras 7.22.2016


global RUNTIME

%Find the name of the RZ6 module
h = findModuleIndex_SanesLab('RZ6',[]);
 
%Find the column that specifies whether a trial (row) is a reminder trials
if RUNTIME.UseOpenEx
    remind_col = find(ismember(colnames,[h.module,'.Reminder']));
else
    remind_col = find(ismember(colnames,'Reminder'));
end

if isempty(remind_col)
    warning('Warning: No reminder trial specified in protocol.')
end

%Find the trial (row) that is a reminder trial
remind_row = find([trials{:,remind_col}] == 1);



%If asked for, also return the column
if nargout>1
    varargout{1} = remind_col;
end


end
