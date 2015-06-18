function event = ft_read_event_tdt_2BitM(tank,block,blockroot,eventname,eventvalue,Fs)
% EVENT = ft_read_event_tdt
% EVENT = ft_read_event_tdt(TANK)
% EVENT = ft_read_event_tdt(TANK,BLOCK)
% EVENT = ft_read_event_tdt(TANK,BLOCK,BLOCKROOT)
% EVENT = ft_read_event_tdt(TANK,BLOCK,BLOCKROOT,EVENTNAME)
% EVENT = ft_read_event_tdt(TANK,BLOCK,BLOCKROOT,EVENTNAME,EVENTVALUE)
% EVENT = ft_read_event_tdt(TANK,BLOCK,BLOCKROOT,EVENTNAME,EVENTVALUE,Fs)
%
% Read events from TDT tank for use with FieldTrip.
%
% If TANK is not specified, a list box will appear with registered tanks.
%
% If BLOCK is not specified, a list box will appear with blocks of the tank.
%
% BLOCKROOT can be specified if the blocks begin with something other than
% 'Block-' (must include '-' if it's there).
%
% The event to which the data should be organized is determined either by
% EVENTNAME (if specified) or a single event name from the tank.  If
% EVENTNAME is not specified and there is more than one event found in the
% tank, then a prompt will appear for the user to select the correct event.
% 
% EVENTVALUE can be specified to limit the returned events to some value(s)
% 
% See also, ft_read_event, trialfun_tdt, ft_read_lfp_tdt TankReg
%
% DJS 2013


% check inputs
if nargin == 0 || isempty(tank),  tank = char(TDT_TankSelect); end
cfg.tank     = tank;
cfg.datatype = 'BlockInfo';
cfg.usemym   = false;
if nargin < 2
    tinfo = getTankData(cfg);
    if isempty(tinfo)
        error('No blocks found in ''%s''',tank)
    end
    [sel,ok] = listdlg('PromptString','Select one block', ...
                       'SelectionMode','single', ...
                       'ListString',num2cell([tinfo.block]));
    if ~ok, return; end
    block = tinfo(sel).block;
end
if nargin < 3 || isempty(blockroot), blockroot = 'Block-'; end

% get tank info
cfg.blocks      = block;
cfg.blockroot   = blockroot;
cfg.datatype    = 'BlockInfo';
cfg.usemym      = false;
tinfo           = getTankData(cfg);


% lookup table for old stimulus codes
% oldcodes  = [1 2 3 4 5 7]; % <- original codese
newcodes  = [0 1 2 3 4 5] + 1; % <- bits for bitmask

oldparams = tinfo.paramspec(1:end-1); % <- tank parameters
newparams = {'STM1' 'STM2' 'STM3' 'STM4' 'VISU' 'NOI1'}; 

ind = strcmp('NOI2',oldparams); % get rid of redundant coding of noise.  It was always bilateral
oldparams(ind) = [];


% find code mapping from old parameters
for i = 1:length(oldparams)
    x = find(strcmp(oldparams{i},newparams));
    if ~isempty(x), remap(i) = x; end %#ok<AGROW>
end
newcodes = newcodes(remap(remap>0));

% now go into the tank events and generate new bitmask for each trial
oldevents = tinfo.epochs(:,[~ind false]); % last parameter is always onsets of trigger
rvalues = zeros(size(oldevents,1),1);
for i = 1:size(oldevents,1)
    ind = oldevents(i,:) ~= 0;
    rvalues(i) = sum(bitset(zeros(1,sum(ind),'uint64'),newcodes(ind)));
end



if nargin >= 5 % eventvalue was specified
    rind = rvalues == eventvalue;
else
    rind = true(size(rvalues));
end

% generate event structure
rvalues = rvalues(rind);
ronsets = tinfo.epochs(rind,end);
ronsamp = round(ronsets*Fs);
event = [];
for j = 1:length(rvalues)
    event(j).type       = 'BitM'; %#ok<AGROW>
    event(j).sample     = ronsamp(j); %#ok<AGROW>
    event(j).value      = rvalues(j); %#ok<AGROW>
    event(j).timestamp  = ronsets(j); %#ok<AGROW>
end










