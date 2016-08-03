function ep_SaveDataFcn_SanesLab(RUNTIME)
% ep_SaveDataFcn_SanesLab(RUNTIME)
% 
% Sanes Lab function for saving behavioral data
%
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2015.

datestr = date;

%For each subject...
for i = 1:RUNTIME.NSubjects
    
    %Subject ID
    ID = RUNTIME.TRIALS(i).Subject.Name;
    
    %Let user decide where to save file
    h = msgbox(sprintf('Save Data for ''%s''',ID),'Save Behavioural Data','help','modal');
    uiwait(h);
    
    %Default filename
    filename = ['D:\data\', ID,'_', datestr,'.mat'];
    fn = 0;
    
    %Force the user to save the file
    while fn == 0
        [fn,pn] = uiputfile(filename,sprintf('Save ''%s'' Data',ID));
    end
    
    fileloc = fullfile(pn,fn);
    
    
    
    %Save all relevant information
    Data = RUNTIME.TRIALS(i).DATA;
    
    Info = RUNTIME.TRIALS(i).Subject;
    Info.TDT = RUNTIME.TDT(i);
    Info.TrialSelectionFcn = RUNTIME.TRIALS(i).trialfunc;
    Info.Date = datestr;
    Info.StartTime = RUNTIME.StartTime;
    Info.Water = updatewater_SanesLab;
    Info.Bits = getBits_SanesLab;
    
    
    %Fix Trial Numbers (corrects for multiple calls of trial selection
    %function during session)
    for j = 1:numel(Data)
        Data(j).TrialID = j;
    end
    
    
    save(fileloc,'Data','Info')
    disp(['Data saved to ' fileloc])
    
end











