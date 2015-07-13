function ep_SaveDataFcn_SanesLab(RUNTIME)
% ep_SaveDataFcn_SanesLab(RUNTIME)
% 
% Sanes Lab function for saving behavioral data
%
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2015.
global PUMPHANDLE

datestr = date;

%For each subject...
for i = 1:RUNTIME.NSubjects
    
    %Get total water volume dispensed (ml)
    fprintf(PUMPHANDLE,'DIS\n');
    V = fscanf(PUMPHANDLE,'%s');
    startind = regexp(V,'I')+1;
    finalind = regexp(V,'W')-1;
    V = V(startind:finalind);
    ind = regexp(V,'[^I]');
    vol = V(ind);
    
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
    
    Info.TDT.RPVdsCircuit = RUNTIME.TDT(i).RPfile{1};
    Info.TDT.fs = Data(1).fs;
    Info.TrialSelectionFcn = RUNTIME.TRIALS(i).trialfunc;
    Info.Date = datestr;
    Info.StartTime = RUNTIME.StartTime;
    Info = RUNTIME.TRIALS(i).Subject;
    Info.Water = str2num(vol);
    Info.Bits.Hit = 1;
    Info.Bits.Miss = 2;
    Info.Bits.CR = 3;
    Info.Bits.FA = 4;
    
    Data = rmfield(Data,'fs');
    
    %Fix Trial Numbers (corrects for multiple calls of trial selection
    %function during session)
    for j = 1:numel(Data)
        Data(j).TrialID = j;
    end
    
    
    save(fileloc,'Data','Info')
    
end











