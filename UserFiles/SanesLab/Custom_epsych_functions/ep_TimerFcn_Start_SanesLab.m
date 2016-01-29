function RUNTIME = ep_TimerFcn_Start_SanesLab(CONFIG, RUNTIME, AX)
% RUNTIME = ep_TimerFcn_Start_SanesLab(CONFIG, RUNTIME, RP)
% RUNTIME = ep_TimerFcn_Start_SanesLab(CONFIG, RUNTIME, DA)
% 
% Sanes Lab Start timer function
% 
% Initialize parameters and take care of some other things just before
% beginning experiment
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2015.



% make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
% TO DO:  Add ability for user to define data directory
if ~isfield(RUNTIME,'DataDir') || ~isdir(RUNTIME.DataDir)
    RUNTIME.DataDir = [cd filesep 'DATA'];
end
if ~isdir(RUNTIME.DataDir), mkdir(RUNTIME.DataDir); end

RUNTIME.NSubjects = length(CONFIG);

for i = 1:RUNTIME.NSubjects
    C = CONFIG(i);
       
    RUNTIME.TRIALS(i).trials     = C.PROTOCOL.COMPILED.trials;
    RUNTIME.TRIALS(i).TrialCount = zeros(size(RUNTIME.TRIALS(i).trials,1),1); 
    RUNTIME.TRIALS(i).trialfunc  = C.PROTOCOL.OPTIONS.trialfunc;
   
    for j = 1:length(RUNTIME.TRIALS(i).readparams)
        ptag = RUNTIME.TRIALS(i).readparams{j};
        if RUNTIME.UseOpenEx
            dt = AX.GetTargetType(ptag);
        else
            lut = RUNTIME.TRIALS(i).RPread_lut(j);
            dt  = AX(lut).GetTagType(ptag);    
        end
        if isempty(deblank(char(dt))), dt = {'S'}; end % PA5
        RUNTIME.TRIALS(i).datatype{j} = char(dt);
        
    end
    
    RUNTIME.TRIALS(i).Subject = C.SUBJECT;    
    
    % Initialze required parameters genereated by behavior macros
    RUNTIME.RespCodeStr{i}  = sprintf('#RespCode~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.TrigStateStr{i} = sprintf('#TrigState~%d',RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.NewTrialStr{i}  = sprintf('#NewTrial~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.ResetTrigStr{i} = sprintf('#ResetTrig~%d',RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.TrialNumStr{i}  = sprintf('#TrialNum~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    
    
    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    
    % Create data file info structure
    info.Subject = RUNTIME.TRIALS(i).Subject;
    info.CompStartTimestamp = now;
    info.StartDate = strtrim(datestr(info.CompStartTimestamp,'mmm-dd-yyyy'));
    info.StartTime = strtrim(datestr(info.CompStartTimestamp,'HH:MM PM'));
    [~, computer] = system('hostname'); info.Computer = strtrim(computer);
    
    dfn = sprintf('RUNTIME_DATA_%s_Box_%02d_%s.mat',genvarname(RUNTIME.TRIALS(i).Subject.Name), ...
        RUNTIME.TRIALS(i).Subject.BoxID,datestr(now,'mmm-dd-yyyy'));
    RUNTIME.DataFile{i} = fullfile(RUNTIME.DataDir,dfn);

    if exist(RUNTIME.DataFile{i},'file')
        oldstate = recycle('on');
        delete(RUNTIME.DataFile{i});
        recycle(oldstate);
    end
    save(RUNTIME.DataFile{i},'info','-v6');
    
%If user enters AM depth as a percent, we need to change it to a proportion
%here to make sure that the RPVds circuit will function properly.
if find(cell2mat(strfind(RUNTIME.TRIALS.writeparams,'AMdepth')))
    
    %Find the column containing AM depth info
    col_ind = find(~cellfun(@isempty,(strfind(RUNTIME.TRIALS.writeparams,'AMdepth'))) == 1 );
    
    %If percent...
    if any(cell2mat(RUNTIME.TRIALS.trials(:,col_ind))> 1)
        
        %Proportion
        RUNTIME.TRIALS.trials(:,col_ind) = cellfun(@(x)x./100, RUNTIME.TRIALS.trials(:,col_ind),'UniformOutput',false);
    end
    
end

    
    
    
    
       
    % Initialize data structure
    for j = 1:length(RUNTIME.TRIALS(i).Mreadparams)
        RUNTIME.TRIALS(i).DATA.(RUNTIME.TRIALS(i).Mreadparams{j}) = [];
    end
    
    RUNTIME.TRIALS(i).DATA.Freq = [];
    RUNTIME.TRIALS(i).DATA.dBSPL = [];
    RUNTIME.TRIALS(i).DATA.Expected = [];
    RUNTIME.TRIALS(i).DATA.MinPokeDur = [];
    RUNTIME.TRIALS(i).DATA.RespWinDelay = [];
    RUNTIME.TRIALS(i).DATA.RespWinDur = [];
    RUNTIME.TRIALS(i).DATA.Silent_delay = [];
    RUNTIME.TRIALS(i).DATA.Stim_Duration = [];
    RUNTIME.TRIALS(i).DATA.to_duration = [];
    
    
    RUNTIME.TRIALS(i).DATA.ResponseCode = [];
    RUNTIME.TRIALS(i).DATA.TrialID = [];
    RUNTIME.TRIALS(i).DATA.ComputerTimestamp = [];
    
    RUNTIME.TRIALS(i).DATA.Go_prob = [];
    RUNTIME.TRIALS(i).DATA.NogoLim = [];
    RUNTIME.TRIALS(i).DATA.Expected_prob = [];
    RUNTIME.TRIALS(i).DATA.RepeatNOGOcheckbox = [];
    RUNTIME.TRIALS(i).DATA.RewardVol= [];
    RUNTIME.TRIALS(i).DATA.PumpRate = [];
    RUNTIME.TRIALS(i).DATA.fs = [];
    RUNTIME.TRIALS(i).DATA.FMdepth = [];
    RUNTIME.TRIALS(i).DATA.FMrate = [];
    RUNTIME.TRIALS(i).DATA.AMdepth = [];
    RUNTIME.TRIALS(i).DATA.AMrate = [];
    RUNTIME.TRIALS(i).DATA.Optostim = [];
end

RUNTIME.RespCodeIdx  = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigStateIdx = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigTrialIdx = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrialNumIdx  = zeros(1,RUNTIME.NSubjects);
for i = 1:RUNTIME.TDT.NumMods
    
    ind = find(ismember(RUNTIME.RespCodeStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.RespCodeStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.RespCodeStr(ind),'UniformOutput',false);
        end
        RUNTIME.RespCodeIdx(ind) = i;
    end
    
    ind = find(ismember(RUNTIME.TrigStateStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.TrigStateStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.TrigStateStr(ind),'UniformOutput',false);
        end
        RUNTIME.TrigStateIdx(ind) = i;
    end
    
    ind = find(ismember(RUNTIME.NewTrialStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.NewTrialStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.NewTrialStr(ind),'UniformOutput',false);
        end
        RUNTIME.NewTrialIdx(ind) = i;
    end
    
    ind = find(ismember(RUNTIME.ResetTrigStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.ResetTrigStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.ResetTrigStr(ind),'UniformOutput',false);
        end
        RUNTIME.ResetTrigIdx(ind) = i;
    end
    
    ind = find(ismember(RUNTIME.TrialNumStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind)
        if RUNTIME.UseOpenEx
            RUNTIME.TrialNumStr(ind) = cellfun(@(s) ([RUNTIME.TDT.name{i} '.' s]),RUNTIME.TrialNumStr(ind),'UniformOutput',false);
        end
        RUNTIME.TrialNumIdx(ind) = i;
    end    
end


for i = 1:RUNTIME.NSubjects
    % Initialize first trial
    RUNTIME.TRIALS(i).TrialIndex = 1;
    try
        n = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
        if isstruct(n)
            RUNTIME.TRIALS(i).trials = n.trials;
            RUNTIME.TRIALS(i).NextTrialID = n.NextTrialID;
        elseif isscalar(n) 
            RUNTIME.TRIALS(i).NextTrialID = n;
        else
            error('Invalid output from custom trial selection function ''%s''',RUNTIME.TRIALS(i).trialfunc)
        end
    catch me
        errordlg('Error in Custom Trial Selection Function');
        rethrow(me)
    end
    RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = 1;
    
    
    
    
        
    
    % Send trigger to reset components before updating parameters
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.ResetTrigStr{i});
    else
        TrigRPTrial(AX(RUNTIME.ResetTrigIdx(i)),RUNTIME.ResetTrigStr{i});
    end
    

    
    
    
    
    % Update parameter tags
    feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    
    
    
    
    
    
    % Trigger first new trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.NewTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.NewTrialIdx(i)),RUNTIME.NewTrialStr{i});
    end
end











