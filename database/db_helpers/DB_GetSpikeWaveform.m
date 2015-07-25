function varargout = DB_GetSpikeWaveform(unit_id,conn)
% waveform = DB_GetSpikeWaveform(unit_id)
% [waveform,tvec] = DB_GetSpikeWaveform(unit_id)
% [waveform,tvec,stddev] = DB_GetSpikeWaveform(unit_id)
% [waveform,...] = DB_GetSpikeWaveform(unit_id,conn)
%
% Retrieve mean spike waveform from database.
%
% tvec is a time vector for the x-axis for plotting the pool waveform.  
% 
% Optionally return standard deviation around the mean.
%
% ex:
%   [waveform,tvec] = DB_GetSpikeWaveform(unit_id);
%   figure
%   plot(tvec,waveform);
% 
% Now works with Database Toolbox by supplying the database connection
% object as a second input parameter.
%
% DJS 2015

if nargin == 1, conn = []; end

if nargout == 1
    U = myms(sprintf(['SELECT pool_waveform ', ...
        'FROM units WHERE id = %d'],unit_id),conn,'structure');
    varargout{1} = str2num(char(U.pool_waveform{1})'); %#ok<ST2NM>
    
elseif nargout == 2
    U = myms(sprintf(['SELECT u.pool_waveform, t.spike_fs ', ...
        'FROM units u ', ...
        'JOIN v_ids v ON v.unit = u.id ', ...
        'JOIN tanks t ON v.tank = t.id ', ...
        'WHERE u.id = %d'],unit_id),conn,'structure');
    varargout{1} = str2num(char(U.pool_waveform{1})'); %#ok<ST2NM>
    varargout{2} = 0:1/U.spike_fs:(length(varargout{1})-1)/U.spike_fs;
    
else
    U = myms(sprintf(['SELECT u.pool_waveform, u.pool_stddev, ', ...
        't.spike_fs FROM units u ', ...
        'JOIN v_ids v ON v.unit = u.id ', ...
        'JOIN tanks t ON v.tank = t.id ', ...
        'WHERE u.id = %d'],unit_id),conn,'structure');
    varargout{1} = str2num(char(U.pool_waveform{1}(:)')); %#ok<ST2NM>
    varargout{2} = 0:1/U.spike_fs:(length(varargout{1})-1)/U.spike_fs;
    varargout{3} = str2num(char(U.pool_stddev{1}(:)')); %#ok<ST2NM>
end




