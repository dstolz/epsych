function ep_SaveDataFcn_GORDON(RUNTIME)
% ep_SaveDataFcn_GORDON(RUNTIME)
% 
% Modified default function for saving behavioral data to include recorded
% HeadTracker data.
%
% Stephen Gordon, 2016



for i = 1:RUNTIME.NSubjects
    
    h = msgbox(sprintf('Save Data for ''%s'' in Box ID %d',RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID), ...
        'Save Behavioural Data','help','modal');
    
    uiwait(h);
    
    [fn,pn] = uiputfile({'*.mat','MATLAB File'}, ...
        sprintf('Save ''%s (%d)'' Data',RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID));
    
    if fn == 0
        fprintf(2,'NOT SAVING DATA FOR SUBJECT ''%s'' IN BOX ID %d\n', ...
            RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID);
        continue
    end
    
    fileloc = fullfile(pn,fn);
    
    Data = RUNTIME.TRIALS(i).DATA;
    HeadTracker = RUNTIME.TRIALS(i).HeadTracker;
    
    save(fileloc,'Data','HeadTracker')
    
end











