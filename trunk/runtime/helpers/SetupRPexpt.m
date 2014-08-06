function [RP,C] = SetupRPexpt(C)
% [RP,C] = SetupRPexpt(C)
% 
% Used by ep_RunExpt when not using OpenEx
% 
% Where C is an Nx1 structure array with atleast the subfields:
% C.OPTIONS
% C.MODULES
% C.COMPILED
% 
% RP is an array of ActiveX objects pointing to specific TDT modules whose
% indices are mapped in C.RPmap.
% 
% C.RPread_lut is a lookup table indicating which RP array index
% corresponds to which C.COMPILED.readparams.
% 
% C.RPwrite_lut is a lookup table indicating which RP array index
% corresponds to which C.COMPILED.writeparams.
% 
% Daniel.Stolzberg@gmail.com 2014


% Programmer's note: There is a lot of kludge in this function.  The reason
% for this is so that the same protocol files can be used for both OpenEx
% and non-OpenEx experiments.  This function is for setting up non-OpenEx
% experiments and makes the protocol conform to OpenEx protocols. DJS

tdtf = findobj('Type','figure','-and','Name','TDTFIG');
if isempty(tdtf), tdtf = figure('Visible','off','Name','TDTFIG'); end

ConnType = C(1).OPTIONS.ConnectionType; % this will be the same for all protocols

% find unique modules across protocols
k = 1;
for i = 1:length(C)
    mfn = fieldnames(C(i).MODULES{1});
    for j = 1:length(mfn)
        S{k} = sprintf('%s_%d',C(i).MODULES{1}.(mfn{j}).ModType,C(i).MODULES{1}.(mfn{j}).ModIDX); %#ok<AGROW>
        M{k} = mfn{j}; %#ok<AGROW>
        RPfile{k} = C(i).MODULES{1}.(mfn{j}).RPfile; %#ok<AGROW>
        k = k + 1;
    end
    C(i).RPmap = [];
end
[S,i,~] = unique(S);
M = M(i);
RPfile = RPfile(i);


% make a map between RP array and MODULES on C
for i = 1:length(C)
    for j = 1:length(M)
        t = cellfun(@(x) (strcmp(M{j},x(1:length(M{j})))),C(i).COMPILED.readparams);
        C(i).RPread_lut(t) = j;
        
        t = cellfun(@(x) (strcmp(M{j},x(1:length(M{j})))),C(i).COMPILED.writeparams);
        C(i).RPwrite_lut(t) = j;
    end
end

fprintf('Connecting %d modules, please wait ...\n',length(S));

k = 1;
for i = 1:length(S)
    fprintf('\n%s ...',S{i})
    
    % connect TDT modules 
    j = find(S{i}=='_',1);
    module = S{i}(1:j-1);
    modid  = str2double(S{i}(j+1:end));
    
    if strcmp(module,'PA5')
        RP(k) = actxcontrol('PA5.x',[1 1 1 1],tdtf); %#ok<AGROW>
        RP(k).ConnectPA5(ConnType,modid);
        RP(k).SetAtten(120);
        RP(k).Display(sprintf(' PA5 %d ',modid),0);
    else
        RP(k) = TDT_SetupRP(module,modid,ConnType,RPfile{i}); %#ok<AGROW>
    end
    fprintf(' Connected\n')
end














