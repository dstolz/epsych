function [HITind,MISSind,CRind,FAind,GOind,NOGOind,REMINDind,...
    reminders,variables,TrialTypeInd,TrialType,waterupdate,handles] = ...
    update_params_runtime_SanesLab(waterupdate,ntrials,handles)
%Custom function for SanesLab epsych
%
%This function updates parameters during GUI runtime
%
%Inputs:
%   waterupdate: persistent variable to track whether text for water is
%   updates
%
%   handles: GUI handles structure
%
%Written by ML Caras 7.25.2016


global RUNTIME ROVED_PARAMS

%DATA structure
DATA = RUNTIME.TRIALS.DATA;

%Response codes
bitmask = [DATA.ResponseCode]';
HITind  = logical(bitget(bitmask,1));
MISSind = logical(bitget(bitmask,2));
CRind   = logical(bitget(bitmask,3));
FAind   = logical(bitget(bitmask,4));


%If the water volume text is not up to date...
if waterupdate < ntrials
    
    %Update the water text
    handles = updatewater_SanesLab(handles);
    waterupdate = ntrials;
    
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

%Find indices for different trial types
TrialTypeInd =  findTrialTypeColumn_SanesLab(ROVED_PARAMS);
TrialType = variables(:,TrialTypeInd);

GOind = find(TrialType == 0);
NOGOind = find(TrialType == 1);
REMINDind = find(reminders == 1);


end