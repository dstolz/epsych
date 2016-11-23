function RUNTIME = ep_TimerFcn_RunTime_SanesLab_v2(RUNTIME, AX)
%RUNTIME = ep_TimerFcn_RunTime_SanesLab_v2(RUNTIME, AX)
%
%Custom function for SanesLab epsych 
% 
%Controls the timer box figure during runtime.Currently supports aversive 
%and appetitive go-nogo GUIs (Aversive_detection_GUI.m and 
%Appetitive_detection_GUI.m)
%
%Inputs: 
%   RUNTIME: epsych RUNTIME structure (global var)
%   AX: handle to active X control for RPVds circuit (global var)
%
%Outputs:
%   RUNTIME: epsych RUNTIME structure (global var)
%
%
% Daniel.Stolzberg@gmail.com 2014.
% Updated by ML Caras Aug 9 2016.
% Updated by KP Nov 6 2016. 

global GUI_HANDLES CONSEC_NOGOS FUNCS CURRENT_FA_STATUS CURRENT_EXPEC_STATUS


%Fixd RZ6 device
h = findModuleIndex_SanesLab('RZ6', []);


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
    % Retrieve parameter data from RPvds circuits and remove proprietary
    % TDT/OpenEx Tags
    tags = RUNTIME.TDT(i).devinfo(h.dev).tags;
    tags = rmTags_SanesLab(tags);
    
    %Initialize data structure
    for j = 1:length(tags)
        if ~isempty(strfind(tags{j},'_ID'))
            data.(tags{j}) = TDTpartag(AX,[h.module,'.',['~' tags{j}]]);
        else
            data.(tags{j}) = TDTpartag(AX,[h.module,'.',tags{j}]);
        end
    end
    
    %Append response, trial and timing information to data structure
    data.ResponseCode = RCtag;
    data.TrialID = TrialNum;
    data.ComputerTimestamp = clock;
    data.PumpRate = GUI_HANDLES.rate; %ml/min
    
    %Append information from GUI into data structure
    switch lower(FUNCS.BoxFig)
        case {'aversive_detection_gui','h2opassive_gui'}
            data.Nogo_lim = getval(GUI_HANDLES.Nogo_lim);
            data.Nogo_min = getval(GUI_HANDLES.Nogo_min);
            
        case {'appetitive_detection_gui','appetitive_detection_gui_v2'}
            data.Go_prob = getval(GUI_HANDLES.go_prob);
            data.NogoLim = getval(GUI_HANDLES.Nogo_lim);
            data.Expected_prob = getval(GUI_HANDLES.expected_prob);
            data.RepeatNOGOcheckbox = GUI_HANDLES.RepeatNOGO.Value;
            data.RewardVol = GUI_HANDLES.vol; %ml
    end

    
    %Make sure fields of structure are in the same order
    ordereddata = orderfields(data,RUNTIME.TRIALS(i).DATA(1));
    
    %Append data to runtime structure
    RUNTIME.TRIALS(i).DATA(RUNTIME.TRIALS(i).TrialIndex) = ordereddata;
    
    
    % Save runtime data in case of crash
    data = RUNTIME.TRIALS(i).DATA;  
    save(RUNTIME.DataFile{i},'data','-append','-v6'); % -v6 is much faster because it doesn't use compression
    
    
    %-----------------------------------------------------------------
    %-----------------------------------------------------------------
    %Trial is complete and response code has been recorded. Update some
    %parameters before selecting next trial.
    
    switch lower(FUNCS.BoxFig)
        case {'aversive_detection_gui','h2opassive_gui'}
            
            %Update number of consecutive nogos
            trial_list = [data(:).TrialType]';
            switch trial_list(end)
                case 1
                    CONSEC_NOGOS = CONSEC_NOGOS +1;
                case 0
                    CONSEC_NOGOS = 0;
            end
            
            
        case {'appetitive_detection_gui','appetitive_detection_gui_v2'}
            
            %Update number of consecutive nogos
            trial_list = [data(:).TrialType]';
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
            
            
    end
    
    
    %-----------------------------------------------------------------
    %Now select the next trial
    [RUNTIME,AX] = updateRUNTIME_SanesLab(RUNTIME,AX);


end




function val = getval(s)

ind =  s.Value;
val = str2num(s.String{ind});









