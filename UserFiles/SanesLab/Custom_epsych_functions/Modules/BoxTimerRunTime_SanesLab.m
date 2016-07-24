function BoxTimerRunTime_SanesLab(~,event,f)
%Custom function for SanesLab epsych
%
%This function controls the runtime for the GUI timer
%
%Written by ML Caras 7.24.2016

global RUNTIME ROVED_PARAMS AX 
global PERSIST
persistent lastupdate starttime waterupdate

%Clear persistent variables if it's a fresh run
if PERSIST == 0
   lastupdate = [];
   starttime = clock;
   waterupdate = 0;
   
   PERSIST = 1;
end


h = guidata(f);



%Update Realtime Plot
UpdateAxHistory(h,starttime,event)

%Capture sound level from microphone
capturesound(h);

%Update some parameters
try
    
    %DATA structure
    DATA = RUNTIME.TRIALS.DATA;
    ntrials = length(DATA);
    
    %Response codes
    bitmask = [DATA.ResponseCode]';
    HITind  = logical(bitget(bitmask,1));
    MISSind = logical(bitget(bitmask,2));
    CRind   = logical(bitget(bitmask,3));
    FAind   = logical(bitget(bitmask,4));
    
    %If the water volume text is not up to date...
    if waterupdate < ntrials
       
        if RUNTIME.UseOpenEx
             %And if we're done updating the plots...
            if AX.GetTargetVal('Behavior.InTrial_TTL') == 0 &&...
                    AX.GetTargetVal('Behavior.Spout_TTL') == 0
                
                %Update the water text
                updatewater(h.watervol)
                waterupdate = ntrials;
            end 
            
        else
            %And if we're done updating the plots...
            if AX.GetTagVal('InTrial_TTL') == 0 &&...
                    AX.GetTagVal('Spout_TTL') == 0
                
                %Update the water text
                updatewater(h.watervol)
                waterupdate = ntrials;
                
            end
        end
        
    end
catch
        
end



try
    %Check if a new trial has been completed
    if (RUNTIME.UseOpenEx && isempty(DATA(1).Behavior_TrialType)) ...
            | (~RUNTIME.UseOpenEx && isempty(DATA(1).TrialType)) ...
            | ntrials == lastupdate
        return
    end
    
    %Update roved parameter variables
    for i = 1:numel(ROVED_PARAMS)
        
        if RUNTIME.UseOpenEx
            eval(['variables(:,i) = [DATA.Behavior_' ROVED_PARAMS{i}(10:end) ']'';'])
        else
            eval(['variables(:,i) = [DATA.' ROVED_PARAMS{i} ']'';'])
        end
        
    end
    
    %Update reminder status
    try
        if RUNTIME.UseOpenEx
            reminders = [DATA.Behavior_Reminder]';
        else
            reminders = [DATA.Reminder]';
        end
    catch me
        errordlg('Error: No reminder trial specified. Edit protocol.')
        rethrow(me)
    end
    
    if RUNTIME.UseOpenEx
        TrialTypeInd = find(strcmpi('Behavior.TrialType',ROVED_PARAMS));
    else
        TrialTypeInd = find(strcmpi('TrialType',ROVED_PARAMS));
    end
    
    TrialType = variables(:,TrialTypeInd);
    
    GOind = find(TrialType == 0);
    NOGOind = find(TrialType == 1);
    REMINDind = find(reminders == 1);
   
    %Update next trial table in gui
    updateNextTrial(h.NextTrial);
    
    %Update response history table
   updateResponseHistory(h.DataTable,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,variables,...
    ntrials,TrialTypeInd,TrialType,...
    REMINDind)
    
    %Update FA rate
    FArate = updateFArate(h,variables,FAind,NOGOind);
    
    %Calculate hit rates and update plot
    updateIOPlot(h,variables,HITind,GOind,REMINDind);
    
    %Update trial history table
    updateTrialHistory(h.TrialHistory,variables,reminders,HITind,FAind)
    
    lastupdate = ntrials;
    
    
catch
   % disp('Help3!')
end


