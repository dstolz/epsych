function ep_SaveDataFcn(RUNTIME)
% ep_SaveDataFcn(RUNTIME)
% 
% Default function fo saving behavioral data
% 
% Use ep_RunExpt GUI to specify custom function.
% 
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

for i = 1:RUNTIME.NSubjects
    
    h = msgbox(sprintf('Save Data for ''%s'' in Box ID %d',RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID), ...
        'Save Behavioural Data','help','modal');
    
    uiwait(h);
    
    [fn,pn] = uiputfile({'*.mat','MATLAB File'}, ...
        sprintf('Save ''%s (%d)'' Data',RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID));
    
    if fn == 0
        vprintf(0,1,'NOT SAVING DATA FOR SUBJECT ''%s'' IN BOX ID %d\n', ...
            RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID);
        continue
    end
    
    fileloc = fullfile(pn,fn);
    
    Data = RUNTIME.TRIALS(i).DATA;
    
    save(fileloc,'Data')
    
end











