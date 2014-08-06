function [RP,C] = SetupRPexpt(C)
% [RP,C] = SetupRPexpt(C)
% 
% Used by ep_RunExpt when not using OpenEx
% 
% Where C is an Nx1 structure array with atleast the subfields:
% C.OPTIONS
% C.MODULES
% 
% RP is an array of ActiveX objects pointing to specific TDT modules whose
% indices are mapped in C.RPmap.
% 
% Daniel.Stolzberg@gmail.com 2014

tdtf = findobj('Type','figure','-and','Name','TDTFIG');
if isempty(tdtf), tdtf = figure('Visible','off','Name','TDTFIG'); end

ConnType = C(1).OPTIONS.ConnectionType; % this will be the same for all protocols

% find unique modules across protocols
k = 1;
for i = 1:length(C)
    mfn = fieldnames(C(i).MODULES{1});
    for j = 1:length(mfn)
        S{k} = sprintf('%s_%d',C(i).MODULES{1}.(mfn{j}).ModType,C(i).MODULES{1}.(mfn{j}).ModIDX); %#ok<AGROW>
        C(i).modmap(j) = S(k);
        RPfile{i,j} = C(i).MODULES{1}.(mfn{j}).RPfile; %#ok<AGROW>
        k = k + 1;
    end
    C(i).RPmap = [];
end
S = unique(S);

fprintf('Connecting %d modules, please wait ...\n',length(S));

% make a map between RP array and MODULES on C
k = 1;
for i = 1:length(S)
    fprintf('\n%s ...',S{i})
    hm = 0;
    for j = 1:length(C)
        for m = 1:length(C(j).modmap)
            if strcmp(C(j).modmap{m},S{i})
                C(j).RPmap(m) = i;
                if ~hm, hm = [j i]; end
            end
        end
    end
    
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
        RP(k) = TDT_SetupRP(module,modid,ConnType,RPfile{hm(1),hm(2)}); %#ok<AGROW>
    end
    fprintf(' Connected\n')
end


