function varargout = DB_GetSpikeWaveform(unit_id)
% waveform = DB_GetSpikeWaveform(unit_id)
% [waveform,tvec] = DB_GetSpikeWaveform(unit_id)
% [waveform,tvec,stddev] = DB_GetSpikeWaveform(unit_id)
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
% DJS 2015

if nargout == 1
    U = mym(['SELECT pool_waveform AS waveform ', ...
        'FROM units WHERE id = {Si}'],unit_id);
    varargout{1} = str2num(char(U.waveform{1})'); %#ok<ST2NM>
    
elseif nargout == 2
    U = mym(['SELECT u.pool_waveform AS waveform, t.spike_fs ', ...
        'FROM units u ', ...
        'JOIN v_ids v ON v.unit = u.id ', ...
        'JOIN tanks t ON v.tank = t.id ', ...
        'WHERE u.id = {Si}'],unit_id);
    varargout{1} = str2num(char(U.waveform{1})'); %#ok<ST2NM>
    varargout{2} = 0:1/U.spike_fs:(length(varargout{1})-1)/U.spike_fs;
    
else
    U = mym(['SELECT u.pool_waveform AS waveform, u.pool_stddev AS stddev, ', ...
        't.spike_fs FROM units u ', ...
        'JOIN v_ids v ON v.unit = u.id ', ...
        'JOIN tanks t ON v.tank = t.id ', ...
        'WHERE u.id = {Si}'],unit_id);
    varargout{1} = str2num(char(U.waveform{1})'); %#ok<ST2NM>
    varargout{2} = 0:1/U.spike_fs:(length(varargout{1})-1)/U.spike_fs;
    varargout{3} = str2num(char(U.stddev{1})'); %#ok<ST2NM>
end




