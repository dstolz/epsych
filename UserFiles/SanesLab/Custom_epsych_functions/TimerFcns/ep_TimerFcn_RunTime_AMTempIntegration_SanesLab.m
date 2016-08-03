function RUNTIME = ep_TimerFcn_RunTime_AMTempIntegration_SanesLab(RUNTIME, AX)
% RUNTIME = ep_TimerFcn_RunTime_SanesLab(RUNTIME, RP)
% RUNTIME = ep_TimerFcn_RunTime_SanesLab(RUNTIME, DA)
% 
% SanesLab RunTime timer function
% 
% Daniel.Stolzberg@gmail.com 2014. Updated by ML Caras 2015

global GUI_HANDLES CONSEC_NOGOS CURRENT_FA_STATUS CURRENT_EXPEC_STATUS


%If we're using OpenEx, the RZ6 is device 2.  Otherwise, it's device 1.
if RUNTIME.UseOpenEx
    dev = 2;
else
    dev = 1;
end

for i = 1:RUNTIME.NSubjects
    
    % Check #RespCode parameter for non-zero value or if #TrigState is true
    if RUNTIME.UseOpenEx
        RCtag = AX.GetTargetVal(RUNTIME.RespCodeStr{i});
        TStag = AX.GetTargetVal(RUNTIME.TrigStateStr{i});
    else
        RCtag = AX(RUNTIME.RespCodeIdx(i)).GetTagVal(RUNTIME.RespCodeStr{i});
        TStag = AX(RUNTIME.TrigStateIdx(i)).GetTagVal(RUNTIME.TrigStateStr{i});
    end
    
    if ~RCtag || TStag, continue; end
  
    
    if RUNTIME.UseOpenEx
        TrialNum = AX.GetTargetVal(RUNTIME.TrialNumStr{i}) - 1;
    else
        TrialNum = AX(RUNTIME.TrialNumIdx(i)).GetTagVal(RUNTIME.TrialNumStr{i}) - 1;
    end
    
    % There was a response and the trial is over.
    % Retrieve parameter data from RPvds circuits
    data = feval(sprintf('Read%sTags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    
    if RUNTIME.UseOpenEx
        data.Freq = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.Freq'); %Hz
        data.dBSPL = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.dBSPL');
        data.Expected = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.Expected'); %Logical
        data.MinPokeDur = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.MinPokeDur'); %msec
        data.RespWinDelay = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.RespWinDelay'); %msec
        data.RespWinDur = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.RespWinDur'); %msec
        data.Silent_delay = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.Silent_delay'); %msec
        data.to_duration = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.to_duration'); %msec
        data.fs =   RUNTIME.TDT.Fs(dev); %Samples/sec
        data.FMdepth = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.FMdepth'); %percent
        data.FMrate = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.FMrate'); %Hz
        data.AMdepth = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.AMdepth'); %percent
        data.AMrate = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.AMrate'); %Hz
        Stim_Duration = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.Stim_Duration'); %samples
        data.Stim_Duration = Stim_Duration/data.fs; %msec
        AM_Duration = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Behavior.AM_Duration')*data.fs; %samples
        data.AM_Duration = AM_Duration/data.fs; %msec
        data.Optostim = feval(sprintf('GetTargetVal',RUNTIME.TYPE),AX,'Optostim'); %Logical
    else
        data.Freq = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Freq'); %Hz
        data.dBSPL = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'dBSPL');
        data.Expected = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Expected'); %Logical
        data.MinPokeDur = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'MinPokeDur'); %msec
        data.RespWinDelay = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'RespWinDelay'); %msec
        data.RespWinDur = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'RespWinDur'); %msec
        data.Silent_delay = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Silent_delay'); %msec
        data.to_duration = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'to_duration'); %msec
        data.fs =  AX.GetSFreq; %Samples/sec; %Samples/sec
        data.FMdepth = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'FMdepth'); %percent
        data.FMrate = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'FMrate'); %Hz
        data.AMdepth = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'AMdepth'); %percent
        data.AMrate = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'AMrate'); %Hz
        Stim_Duration = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Stim_Duration'); %samples
        data.Stim_Duration = Stim_Duration/data.fs; %msec
        AM_Duration = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'AM_Duration')*data.fs; %samples
        data.AM_Duration = AM_Duration/data.fs; %msec        
        data.Optostim = feval(sprintf('GetTagVal',RUNTIME.TYPE),AX,'Optostim'); %Logical
    end
    
    
    %Append response, trial and timing information to data structure
    data.ResponseCode = RCtag;
    data.TrialID = TrialNum;
    data.ComputerTimestamp = clock;
   
    %Append information from GUI into data structure
    if ~isempty(GUI_HANDLES)
        data.Go_prob = getval(GUI_HANDLES.go_prob);
        data.NogoLim = getval(GUI_HANDLES.Nogo_lim);
        data.Expected_prob = getval(GUI_HANDLES.expected_prob);
        data.RepeatNOGOcheckbox = GUI_HANDLES.RepeatNOGO.Value;
        data.RewardVol = GUI_HANDLES.vol; %ml
        data.PumpRate = GUI_HANDLES.rate; %ml/min
    end
    
    %Make sure fields of structure are in the same order
    ordereddata = orderfields(data,RUNTIME.TRIALS(i).DATA(1));
    
    %Append data to runtime structure
    RUNTIME.TRIALS(i).DATA(RUNTIME.TRIALS(i).TrialIndex) = ordereddata;
    
    
    % Save runtime data in case of crash
    data = RUNTIME.TRIALS(i).DATA;  %#ok<NASGU>
    save(RUNTIME.DataFile{i},'data','-append','-v6'); % -v6 is much faster because it doesn't use compression  

%-----------------------------------------------------------------
%Trial is complete and response code has been recorded. Now update some
%parameters before selecting the next trial.


     %Update number of consecutive nogos
    if RUNTIME.UseOpenEx
        trial_list = [data(:).Behavior_TrialType]';
    else
        trial_list = [data(:).TrialType]';
    end
    
    switch trial_list(end)
        case 1
            CONSEC_NOGOS = CONSEC_NOGOS +1;
        case 0
            CONSEC_NOGOS = 0;
    end
    
    %Determine if the last response was a FA
    response_list = bitget([data(:).ResponseCode]',4);
    
    switch response_list(end)
        case 1
            CURRENT_FA_STATUS = 1;
        case 0
            CURRENT_FA_STATUS = 0;
    end
    
    %Determine if last presentation was an unexpected GO
    expected_list = [data(:).Expected]';
    
    switch expected_list(end)
        case 1
            CURRENT_EXPEC_STATUS = 0;
        case 0
            CURRENT_EXPEC_STATUS = 1;
    end
    
    
    
%-----------------------------------------------------------------
%Now select the next trial
    
    %Increment trial index
    RUNTIME.TRIALS(i).TrialIndex = RUNTIME.TRIALS(i).TrialIndex + 1;
    
    
    % Select next trial with default or custom function
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
    
    
    
    % Increment TRIALS.TrialCount for the selected trial index
    RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) = ...
        RUNTIME.TRIALS(i).TrialCount(RUNTIME.TRIALS(i).NextTrialID) + 1;
    
    
    % Send trigger to reset components before updating parameters
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.ResetTrigStr{i});
    else
        TrigRPTrial(AX(RUNTIME.ResetTrigIdx(i)),RUNTIME.ResetTrigStr{i});
    end
    
    
    % Update parameters for next trial
    feval(sprintf('Update%stags',RUNTIME.TYPE),AX,RUNTIME.TRIALS(i));
    
    
    % Send trigger to indicate ready for a new trial
    if RUNTIME.UseOpenEx
        TrigDATrial(AX,RUNTIME.NewTrialStr{i});
    else
        TrigRPTrial(AX(RUNTIME.NewTrialIdx(i)),RUNTIME.NewTrialStr{i});
    end
    
    
    
end




function val = getval(s)

ind =  s.Value;
val = str2num(s.String{ind});









