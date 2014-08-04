function Spiketimes = DB_GetSpiketimes(unit_id,epoch)
% Spiketimes = DB_GetSpiketimes(unit_id)
% Spiketimes = DB_GetSpiketimes(unit_id,epoch)
%
% Daniel.Stolzberg at gmail dot com 2013
%
% See also shapedata_spikes, DB_GetParams, DB_GetWave


% Check input
if nargin<1
    error('Not enough input arguments.');
elseif nargin == 1
    epoch = [];
elseif length(epoch) ~= 2
    error('epoch must be two numeric values')
end


database = dbcurr;
if isempty(database)
    error('No Database has been selected.')
end

if isempty(epoch)
    % retrieve all spike times
    s = mym(['SELECT spike_time FROM spike_data ', ...
             'WHERE unit_id = {Si}'],unit_id);
else
    % retrieve spike times within an epoch
    if numel(epoch) ~= 2
        error('DB_GetSpiketimes: epoch parameter requires two scalars');
    end
    s = mym(['SELECT spike_time FROM spike_data ', ...
             'WHERE unit_id = {Si} AND ', ...
             'spike_time >= {S} AND spike_time <= {S}'], ...
        unit_id,num2str(epoch(1),'%0.6f'),num2str(epoch(2),'%0.6f'));
end

Spiketimes = s.spike_time;




















