function [tanks,islegacy] = CheckForTanks(parentdir)
% tanks = CheckForTanks(parentdir)
% [tanks,islegacy] = CheckForTanks(parentdir)
%
% Check some directory (parentdir) for TDT tanks
% 
% islegacy can be returned as a logical vector the same size as tanks
% indicating whether or not the tank is actually a legacy tank.
%
% DJS 2013

tanks = []; islegacy = [];
posstanks = dir(parentdir);

posstanks(ismember({posstanks.name},{'.','..'})) = [];

if isempty(posstanks), return; end

istank   = false(size(posstanks));
islegacy = false(size(posstanks));
for i = 1:length(posstanks)
    % look in a block (subdirectory)
    bstr = fullfile(parentdir,posstanks(i).name);
    blockdir = dir(bstr);
    blockdir(ismember({blockdir.name},{'.','..','TempBlk'})) = [];
    
    if isempty(blockdir), continue; end
    
    % check if legacy tank
    islegacy(i) = ~isempty(findincell(strfind({blockdir.name},'.Tbk')));
    istank(i)   = islegacy(i);
    if islegacy(i) || ~any([blockdir.isdir]), continue; end
    
    ff = fullfile(parentdir,posstanks(i).name,blockdir(1).name);
    blockcont = dir(ff);
    istank(i) = ~isempty(findincell(strfind({blockcont.name},'.Tbk')));
end

islegacy(~istank) = [];
tanks = {posstanks(istank).name};









