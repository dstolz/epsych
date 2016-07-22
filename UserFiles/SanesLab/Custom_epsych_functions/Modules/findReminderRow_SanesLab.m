function remind_row = findReminderRow_SanesLab(TRIALS)
%Custom function for SanesLab epsych
%Input is TRIALS structure
%Output is the index of the reminder trial row
%
%Written by ML Caras 7.22.2016


global RUNTIME


%Find the row that contains the reminder trial
try
    if RUNTIME.UseOpenEx
        remind_col = find(ismember(TRIALS.writeparams,'Behavior.Reminder'));
    else
        remind_col = find(ismember(TRIALS.writeparams,'Reminder'));
    end
    
    remind_row = find([TRIALS.trials{:,remind_col}] == 1);
    
catch me
    
    errordlg('Error: No reminder trial specified. Edit protocol.')
    rethrow(me)
end


end
