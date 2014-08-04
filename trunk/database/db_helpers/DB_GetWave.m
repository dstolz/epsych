function varargout = DB_GetWave(channel_id,epoch)
% W = DB_GetWave(channel_id)
% W = DB_GetWave(channel_id,epoch)
% [W,T] = DB_GetWave(...)
% [W,T,P] = DB_GetWave(...)
%
% Retrieve wave data for channel_id bounded by the values in epoch.  Epoch
% two scalar values in seconds (ex: [10 100]) restricting the data analyzed
% to some epoch.  All data will be returned if epoch is empty.
%
% Optional output T is a time vector corresponding to samples of W.
%
% Optional output P is the parameters from the current block (call to
% DB_GetParams).
%
% DJS (c) 2013
%
% See also, DB_GetWaves, DB_GetParams, DB_GetSpiketimes

% Check input
if nargin<1
    error('DB_GetWave: Not enough input arguments.');
elseif nargin == 1
    epoch = [];
end

if ~isempty(epoch) && numel(epoch) ~= 2
    error('DB_GetWave: epoch parameter requires two scalars');
end

database = dbcurr;
if isempty(database)
    error('No Database has been selected.')
end

b = mym('SELECT block_id FROM channels WHERE id = {Si}',channel_id);
block_id = b.block_id;
p = DB_GetParams(block_id);

Fs = p.wave_fs;

if isempty(epoch)
    % retrieve all waveform data
    w = mym(['SELECT waveform FROM wave_data ', ...
        'WHERE channel_id = {Si} ORDER BY param_id'],channel_id);
    w = cell2mat(w.waveform);
    t = (0:length(w)-1)' / Fs;
    
else
    % retrieve an epoch of waveform data
    pid(1) = find(epoch(1) >= p.VALS.onset,1,'last');
    pid(2) = find(epoch(2) <= p.VALS.onset,1,'first');
    w = mym(['SELECT waveform FROM wave_data ', ...
        'WHERE channel_id = {Si} ', ...
        'AND param_id >= {Si} AND param_id <= {Si} ', ...
        'ORDER BY param_id'],channel_id,pid(1),pid(2));
    w = cell2mat(w.waveform);
    ons  = p.VALS.onset(pid);
    t = linspace(ons(1),ons(2),length(w));
    ind = t >= epoch(1) & t <= epoch(2);
    w = w(ind);
    t = t(ind);
    
end

varargout{1} = w(:);
varargout{2} = t(:);
varargout{3} = p;
















