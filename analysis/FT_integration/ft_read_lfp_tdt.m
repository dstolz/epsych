function data = ft_read_lfp_tdt(tank,block)
% data = ft_read_lfp_tdt(tank,block)
%
% Read continuous (LFP) data from TDT Tank and convert for use with
% FieldTrip toolbox
% 
% See also, trialfun_tdt
%
% DJS 2013

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

% Read in continuous 'Wave' data from the tank
cfg = [];
cfg.tank        = tank;
cfg.blocks      = block;
cfg.usemym      = false;
cfg.datatype    = 'Waves';
cfg.downfs      = 600; % if real sampling rate is lower, this field will be ignored
                       % Note: final sampling rate will be the one in the
                       % structure returned from the call to getTankData
W = getTankData(cfg);

for i = 1:length(W.channels)
    data.label{i,1} = num2str(W.channels(i));
end

data.fsample    = W.fsample;
data.trial      = {W.waves'};
L               = size(data.trial{1},2);
data.time       = {linspace(0,(L-1)/data.fsample,L)};
data.sampleinfo = [1 L];

data = ft_preprocessing([],data);







