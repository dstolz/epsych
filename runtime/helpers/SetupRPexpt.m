function [RP,RUNTIME] = SetupRPexpt(C)
% [RP,RUNTIME] = SetupRPexpt(C)
% 
% Used by ep_RunExpt when not using OpenEx
% 
% Where C is an Nx1 structure array with atleast the subfields:
% C.OPTIONS
% C.MODULES
% C.COMPILED
% 
% 
% RUNTIME.RPread_lut is a lookup table indicating which RP array index
% corresponds to which C.COMPILED.readparams.
% 
% RUNTIME.RPwrite_lut is a lookup table indicating which RP array index
% corresponds to which C.COMPILED.writeparams.
% 
% RUNTIME.Mreadparams is a cell array of modified parameter tags which
% are useful for storing acquired data into a structure in the ReadRPtags
% function.
% 
% 
% See also, ReadRPtags, UpdateRPtags
% 
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

% Programmer's note: There is a lot of kludge in this function.  The reason
% for this is so that the same protocol files can be used for both OpenEx
% and non-OpenEx experiments.  This function is for setting up non-OpenEx
% experiments and makes the protocol conform to OpenEx protocols. DJS

tdtf = findobj('Type','figure','-and','Name','TDTFIG');
if isempty(tdtf), tdtf = figure('Visible','off','Name','TDTFIG'); end

ConnType = C(1).PROTOCOL.OPTIONS.ConnectionType; % this will be the same for all protocols

% find unique modules across protocols
k = 1;
for i = 1:length(C)
    MODS = C(i).PROTOCOL.MODULES;
    mfn = fieldnames(MODS);
    for j = 1:length(mfn)
        S{k} = sprintf('%s_%d',MODS.(mfn{j}).ModType,MODS.(mfn{j}).ModIDX); %#ok<AGROW>
        M{k} = mfn{j}; %#ok<AGROW>
        if isfield(MODS.(mfn{j}),'RPfile')
            RPfile{k} = MODS.(mfn{j}).RPfile; %#ok<AGROW>
        else
            RPfile{k} = []; %#ok<AGROW>
        end
        k = k + 1;
    end
end
% [S,i] = unique(S,'stable');
[S,i] = unique(S); % Backwards compatability with older versions of matlab DJS 01-06-2015
M = M(i);
RPfile = RPfile(i);


% make a map between RP array and MODULES
for i = 1:length(C)
    COMP = C(i).PROTOCOL.COMPILED;
    if isfield(COMP,'randparams')
        RUNTIME.TRIALS(i).randparams = COMP.randparams;
    else
        RUNTIME.TRIALS(i).randparams = false(size(COMP.writeparams));
    end
    for j = 1:length(M)
        t = ismember(strtok(COMP.readparams,'.'),M{j});
        RUNTIME.TRIALS(i).RPread_lut(t) = j;
        t = ismember(strtok(COMP.writeparams,'.'),M{j});
        RUNTIME.TRIALS(i).RPwrite_lut(t) = j;
    end
    
    
    for k = 1:length(COMP.readparams)
        ptag = COMP.readparams{k};
        ptag(1:find(ptag=='.')) = [];
        RUNTIME.TRIALS(i).readparams{k}  = ptag;
        RUNTIME.TRIALS(i).Mreadparams{k} = ModifyParamTag(ptag);
    end
    
    
    for k = 1:length(COMP.writeparams)
        ptag = COMP.writeparams{k};
        ptag(1:find(ptag=='.')) = [];
        RUNTIME.TRIALS(i).writeparams{k}  = ptag;
        RUNTIME.TRIALS(i).Mwriteparams{k} = ModifyParamTag(ptag);
    end
        
end

fprintf('Connecting %d modules, please wait ...\n',length(S));
% connect TDT modules

for i = 1:length(S)   
    j = find(S{i}=='_',1);
    module = S{i}(1:j-1);
    modid  = str2double(S{i}(j+1:end));
    
    RUNTIME.TDT.Module{i} = module;
    RUNTIME.TDT.Modidx(i) = modid;
    RUNTIME.TDT.RPidx(i)  = i;
    
    if strcmp(module,'PA5')
        fprintf('% -10s\t%s_%d',M{i},module,modid)
        RP(i) = actxcontrol('PA5.x',[1 1 1 1],tdtf); %#ok<AGROW>
        RP(i).ConnectPA5(ConnType,modid);
        RP(i).SetAtten(120);
        RP(i).Display(sprintf('PA5 %d :)',modid),0);
        fprintf(' connected ... loaded ...running\n')
    else
        fprintf('% -10s\t',M{i})
        RP(i) = TDT_SetupRP(module,modid,ConnType,RPfile{i}); %#ok<AGROW>
    end
    
end

RUNTIME.TDT.RPfile = RPfile;

















