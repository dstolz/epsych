function Spiketimes = DB_GetSpiketimes(unit_id,epoch,conn)
% Spiketimes = DB_GetSpiketimes(unit_id)
% Spiketimes = DB_GetSpiketimes(unit_id,epoch)
% Spiketimes = DB_GetSpiketimes(unit_id,epoch,conn)
%
% Retrieves Nx1 vector of spike times or unit_id on a database.
% 
% Optionally, the spike times returned from the database can be restricted
% to some time period as specified by epoch which should be a 2-element
% numeric matrix, in seconds from the onset of the recording block (ex:
% epoch = [12.0 13.5]).  If empty or ommitted, then all spike times from
% the entire block will be returned.
%
% If using the Matlab Database Toolbox, a third input parameter can be
% specified as an connected database object (see DATABASE)
% 
% 
% Daniel.Stolzberg at gmail dot com 2013
%
% See also shapedata_spikes, DB_GetParams, DB_GetWave


% Check input
if nargin<1
    error('Not enough input arguments.');
elseif nargin == 1
    epoch = [];
elseif ~isempty(epoch) && length(epoch) ~= 2
    error('epoch must be two numeric values')
end

if nargin == 3
    % Use Database Toolbox
    assert(isa(conn,'database'),'conn should be a database object');
    assert(isempty(conn.Message),conn.Message);
    assert(~isempty(conn.Instance),'Not connected to a database');
    
    %Set preferences with setdbprefs.
    setdbprefs('DataReturnFormat', 'numeric');
    setdbprefs('NullNumberRead', 'NaN');
    setdbprefs('NullStringRead', 'null');


    if isempty(epoch)
        % retrieve all spike times for this unit
        curs = exec(conn, sprintf(['SELECT spike_time FROM spike_data '...
            'WHERE unit_id = %d'],unit_id));
    else
        % retrieve spike times within an epoch
        curs = exec(conn,spritnf(['SELECT spike_time FROM spike_data ', ...
            'WHERE unit_id = %d AND ', ...
            'spike_time >= %0.6f AND spike_time <= %0.6f'], ...
            unit_id,epoch(1),epoch(2)));
    end
    
    curs = fetch(curs);
    close(curs);
    Spiketimes = curs.Data;
    
    clear curs
else
    
    % Use MYM
    
    
    database = dbcurr;
    if isempty(database)
        error('No Database has been selected.')
    end
    
    if isempty(epoch)
        % retrieve all spike times for this unit
        s = myms(sprintf(['SELECT spike_time FROM spike_data ', ...
            'WHERE unit_id = %d'],unit_id));
    else
        % retrieve spike times within an epoch
        s = myms(sprintf(['SELECT spike_time FROM spike_data ', ...
            'WHERE unit_id = %d AND ', ...
            'spike_time >= %0.6f AND spike_time <= %0.6f'], ...
            unit_id,epoch(1),epoch(2)));
    end
    
    Spiketimes = s;
end





















