function [remind_row,varargout] = findReminderRow_SanesLab(colnames,trials)
%Custom function for SanesLab epsych
%
%This function finds the column index for the reminder row and column
%Inputs:
%   colnames: cell array of column names
%   trials: cell array of trial parameters 
%
%Written by ML Caras 7.22.2016


global RUNTIME


%Find the row that contains the reminder trial
try
    if RUNTIME.UseOpenEx
        remind_col = find(ismember(colnames,'Behavior.Reminder'));
    else
        remind_col = find(ismember(colnames,'Reminder'));
    end
    
    remind_row = find([trials{:,remind_col}] == 1);
    
catch me
    
    errordlg('Error: No reminder trial specified. Edit protocol.')
    rethrow(me)
end



if nargout>1
    varargout{1} = remind_col;
end


end
