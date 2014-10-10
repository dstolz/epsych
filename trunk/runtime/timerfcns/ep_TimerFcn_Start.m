function RUNTIME = ep_TimerFcn_Start(CONFIG, RUNTIME, AX)
% RUNTIME = ep_TimerFcn_Start(CONFIG, RUNTIME, RP)
% RUNTIME = ep_TimerFcn_Start(CONFIG, RUNTIME, DA)
% 
% Default Start timer function
% 
% Initialize parameters and take care of some other things just before
% beginning experiment
% 
% Use ep_PsychConfig GUI to specify custom timer function.
% 
% Daniel.Stolzberg@gmail.com 2014



% make temporary directory in current folder for storing data during
% runtime in case of a computer crash or Matlab error
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
        
        
        else
            lut  = RUNTIME.TRIALS(i).RPread_lut(j);
            RUNTIME.TRIALS(i).datatype{j} = char(AX(lut).GetTagType(ptag));    
        end
    end
    
    RUNTIME.TRIALS(i).Subject = C.SUBJECT;    
    
    % Initialze required parameters genereated by behavior macros
    RUNTIME.RespCodeStr{i}  = sprintf('#RespCode~%d', RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.TrigStateStr{i} = sprintf('#TrigState~%d',RUNTIME.TRIALS(i).Subject.BoxID);
    RUNTIME.TrigTrialStr{i} = sprintf('#TrigTrial~%d',RUNTIME.TRIALS(i).Subject.BoxID);
    
    
    % Create data file for saving data during runtime in case there is a problem
    % * this file will automatically be overwritten
    
    % Create data file info structure
    info.Subject = RUNTIME.TRIALS(i).Subject;
    info.Date = strtrim(datestr(now,'mmm-dd-yyyy'));
    info.StartTime = strtrim(datestr(now,'HH:MM PM'));
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
    
    
    
    
    
    % Initialize data structure
    for j = 1:length(RUNTIME.TRIALS(i).Mreadparams)
        RUNTIME.TRIALS(i).DATA.(RUNTIME.TRIALS(i).Mreadparams{j}) = [];
    end    
    RUNTIME.TRIALS(i).DATA.ResponseCode = [];
    RUNTIME.TRIALS(i).DATA.TrialID = [];
    RUNTIME.TRIALS(i).DATA.ComputerTimestamp = [];
end

RUNTIME.RespCodeIdx  = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigStateIdx = zeros(1,RUNTIME.NSubjects);
RUNTIME.TrigTrialIdx = zeros(1,RUNTIME.NSubjects);
for i = 1:RUNTIME.TDT.NumMods
    
    ind = find(ismember(RUNTIME.RespCodeStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind), RUNTIME.RespCodeIdx(ind) = i; end
    
    ind = find(ismember(RUNTIME.TrigStateStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind), RUNTIME.TrigStateIdx(ind) = i; end
    
    ind = find(ismember(RUNTIME.TrigTrialStr,RUNTIME.TDT.devinfo(i).tags));
    if ~isempty(ind), RUNTIME.TrigTrialIdx(ind) = i; end
    
end


for i = 1:RUNTIME.NSubjects
    % Initialize first trial
    RUNTIME.TRIALS(i).TrialIndex = 1;
    RUNTIME.TRIALS(i).NextTrialID = feval(RUNTIME.TRIALS(i).trialfunc,RUNTIME.TRIALS(i));
    RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = 1;
    
    % Update parameter tags
    feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    
    % Trigger first new trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.TrigTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.TrigTrialIdx(i)),RUNTIME.TrigTrialStr{i});
    end
end











