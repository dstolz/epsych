function ep_SaveDataFcn_SanesLab(RUNTIME)
% ep_SaveDataFcn_SanesLab(RUNTIME)
% 
% Sanes Lab function for saving behavioral data
%
% 
% Daniel.Stolzberg@gmail.com 2014. 
% Updated by ML Caras 2015.
% Updated by KP 2016. Saves buffer files and associated ephys tank number.

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
    
    %Add fields to Info struct if experiment used stimuli from WAV/MAT files
    if any(~cellfun(@isempty,strfind(fieldnames(Data),'_ID')))          %kp
        stimdir = uigetdir('D:\stim\AMjitter','Select folder of stimuli');
        
        Dfns = fieldnames(Data);
        rvFN = Dfns{(~cellfun(@isempty,strfind(Dfns,'_ID')))};
        nsf = max([Data.(rvFN)]);
        stimfns = cell(1,nsf);
%         for isf=1:numel(dir(fullfile(stimdir,'*.mat')))
        for isf=1:nsf
            
            stimfns{isf} = uigetfile(stimdir,sprintf('Select file number %i of %i',isf,nsf));
            
        end
        Info.StimDirName   = stimdir;
        Info.StimFilenames = stimfns;
    end
    
    %Associate an Block number if ephys also
    if RUNTIME.UseOpenEx
        BLOCK = input('Please enter the ephys BLOCK number associated with this behavior file.\n','s');
        Info.epBLOCK = ['Block-' BLOCK];
    end
    
    %Fix Trial Numbers (corrects for multiple calls of trial selection
    %function during session)
    for j = 1:numel(Data)
        Data(j).TrialID = j;
    end
    
    
    save(fileloc,'Data','Info')
    disp(['Data saved to ' fileloc])
    
end











