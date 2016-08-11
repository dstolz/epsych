function create_logfile_SanesLab
%Custom function for SanesLab epsych
%
%This function creates an log file for documenting errors and other
%important information.
%
%Written by ML Caras 7.28.2016


global GLogFID GVerbosity CONFIG

GVerbosity = 2; %see vprintf.m for more info

%Close any existing log files
if ~isempty(GLogFID) && GLogFID >2
    fclose(GLogFID);
end

%Set the path for log file storage
logpath = 'C:\\gits\\epsych\\UserFiles\\SanesLab\\Logs\\';
subject = CONFIG.SUBJECT.Name;

GLogFID = fopen(sprintf([logpath,subject,'_%s.log'],datestr(now,'ddmmmyyyy')),'at');
