function [HITind,MISSind,CRind,FAind,GOind,NOGOind,REMINDind,...
    reminders,variables,TrialTypeInd,TrialType,waterupdate,handles,bits,varargout] = ...
    update_params_runtime_SanesLab(waterupdate,ntrials,handles,bits)
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

%Retreive response code bits
if isempty(bits)
    bits = getBits_SanesLab;
end

bitmask = [DATA.ResponseCode]';
HITind  = logical(bitget(bitmask,bits.hit));
MISSind = logical(bitget(bitmask,bits.miss));
CRind   = logical(bitget(bitmask,bits.cr));
FAind   = logical(bitget(bitmask,bits.fa));


%If the water volume text is not up to date...
if waterupdate < ntrials
    
    %Update the water text
    handles = updatewater_SanesLab(handles);
    waterupdate = ntrials;
    
end


%Update roved parameter variables
for i = 1:numel(ROVED_PARAMS)
    
    if RUNTIME.UseOpenEx
        eval(['variables(:,i) = [DATA.' ROVED_PARAMS{i}(10:end) ']'';'])
    else
        eval(['variables(:,i) = [DATA.' ROVED_PARAMS{i} ']'';'])
    end
    
end


%Update reminder status
try
    reminders = [DATA.Reminder]';
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



%Special case: if 'Expected' is a parameter tag in the circuit
if sum(~cellfun('isempty',strfind(RUNTIME.TDT.devinfo(handles.dev).tags,'Expected')))
    
    if RUNTIME.UseOpenEx
        expectInd = find(strcmpi([handles.module,'.Expected'],ROVED_PARAMS));
    else
        expectInd = find(strcmpi('Expected',ROVED_PARAMS));
    end
    
    expected = variables(:,expectInd);
    
    varargout{1} = expectInd;
    varargout{2} = find(expected == 1); %YESind
    varargout{3} = find(expected == 0); %NOind
    
    
end


end