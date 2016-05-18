function DB_DeleteTankData(TankID,Warn)
% DB_DeleteTankData(TankID)
% DB_DeleteTankData(TankID,Warn)
% 
% Deletes all data associated with some tank id from the database.
%
% By default, a warning is displayed to confirm data deletion.  This can be
% overrided by setting Warn = false.
% 
% Included tables in deletion:
%   tanks
%   blocks
%   channels
%   units
%   spike_data
%   wave_data
%   protocols
% 
% Daniel.Stolzberg@gmail.com June 1, 2015

if nargin == 1 || Warn
    b = questdlg(sprintf(['Are you certain you would like to delete all data associated with tank id %d? ', ...
        'This action cannot be undone.'],TankID),'Delete Tank Data','Delete','Cancel','Cancel');
   
    if strcmp(b,'Cancel')
        disp('Action cancelled.  No data was deleted.')
        return
    end
end

IDs.unit    = myms(sprintf('SELECT unit FROM v_ids WHERE tank = %d',TankID));
IDs.block   = myms(sprintf('SELECT block FROM v_ids WHERE tank = %d',TankID));
IDs.channel = myms(sprintf('SELECT channel FROM v_ids WHERE tank = %d',TankID));

IDs = structfun(@unique,IDs,'uniformoutput',false);

if isempty(IDs.unit)
    fprintf('No units to delete\n')
else
    try
        fprintf('Deleting %d units\t',length(IDs.unit))
        for i = IDs.unit(:)'
            fprintf('.')
            myms(sprintf('DELETE FROM units WHERE id = %d',i));
            myms(sprintf('DELETE FROM spike_data WHERE unit_id = %d',i));
        end
        fprintf(' done\n');
    catch
        fprintf(' action failed\n')
    end
end

if isempty(IDs.channel)
    fprintf('No channels to delete\n')
else
    try
        fprintf('Deleting %d channels\t',length(IDs.channel))
        for i = IDs.channel(:)'
            fprintf('.')
            myms(sprintf('DELETE FROM channels WHERE id = %d',i));
            myms(sprintf('DELETE FROM wave_data WHERE channel_id = %d',i));
        end
        fprintf(' done\n');
    catch
        fprintf(' action failed\n')
    end
end

if isempty(IDs.block)
    fprintf('No blocks to delete\n')
else
    try
        fprintf('Deleting %d blocks\t...',length(IDs.block))
        for i = IDs.block(:)'
            fprintf('.')
            myms(sprintf('DELETE FROM blocks WHERE id = %d',i));
            myms(sprintf('DELETE FROM protocols WHERE block_id = %d',i));
        end
        fprintf(' done\n');
    catch
        fprintf(' action failed\n')
    end
end

try
    fprintf('Deleting tank id %d\t...',TankID)
    myms(sprintf('DELETE FROM tanks WHERE id = %d',TankID));
    fprintf(' done\n');
catch
    fprintf(' action failed\n')
end






