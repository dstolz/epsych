function ep_SaveDataFcn_SanesLab(RUNTIME)
% ep_SaveDataFcn_SanesLab(RUNTIME)
% 
% Sanes Lab function for saving behavioral data
%
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2015.



%For each subject...
for i = 1:RUNTIME.NSubjects
    
    %Let user decide where to save file
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
    
    
    %Save all relevant information
    Data = RUNTIME.TRIALS(i).DATA;
    
    Info = RUNTIME.TRIALS(i).Subject;
    Info.RPVdsCircuit = RUNTIME.TDT(i).RPfile{1};
    Info.TrialSelectionFcn = RUNTIME.TRIALS(i).trialfunc;
    Info.StartTime = RUNTIME.StartTime;
    
    save(fileloc,'Data','Info')
    
end











