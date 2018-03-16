function Temporal_expectation_analysis_SanesLab


directoryname = uigetdir('D:\data','Select an animal');
files = ls(directoryname);

SilentDelay = [];
TrialType = [];
ResponseCode = [];
Reminders = [];
RespLatency = [];

%For each file...
for i = 1:size(files,1)
    
    datafile = files(i,:);
    
    if ~strcmp(datafile(1),'.')
       
       %Load in data 
       load([directoryname,'\',datafile]); 
        
       %Add data to existing matrices
       SilentDelay = [SilentDelay;([Data(:).Silent_delay]')];
       TrialType = [TrialType;([Data(:).TrialType]')];
       ResponseCode = [ResponseCode;([Data(:).ResponseCode]')];
       Reminders = [Reminders;([Data(:).Reminders]')];
       RespLatency = [RespLatency;([Data(:).RespLatency]')];
       
    end
    
end



%Remove reminder trials



















end
