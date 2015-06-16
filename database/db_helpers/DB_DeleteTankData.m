function DB_DeleteTankData(TankID,Warn)
% DB_DeleteTankData(TankID)
% DB_DeleteTankData(TankID,NoWarn)
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

IDs = mym('SELECT unit,channel,block FROM v_ids WHERE tank = {Si}',TankID);

IDs = structfun(@unique,IDs,'uniformoutput',false);
delstr = structfun(@mat2str,IDs,'uniformoutput',false);
delstr = structfun(@char,delstr,'uniformoutput',false);
delstr = structfun(@(a) (a(2:end-1)),delstr,'uniformoutput',false);
delstr = structfun(@(a) (strrep(a,';',',')),delstr,'uniformoutput',false);

try
    fprintf('Deleting %d units\t...',length(delstr.unit))
    mym(sprintf('DELETE FROM units WHERE id IN (%s)',delstr.unit));
    mym(sprintf('DELETE FROM spike_data WHERE unit_id IN (%s)',delstr.unit));
    fprintf(' done\n');
catch
    fprintf(' action failed\n')
end

try
    fprintf('Deleting %d channels\t...',length(delstr.channel))
    mym(sprintf('DELETE FROM channels WHERE id IN (%s)',delstr.channel));
    mym(sprintf('DELETE FROM wave_data WHERE channel_id IN (%s)',delstr.channel));
    fprintf(' done\n');
catch
    fprintf(' action failed\n')
end

try
    fprintf('Deleting %d blocks\t...',length(delstr.block))
    mym(sprintf('DELETE FROM blocks WHERE id IN (%s)',delstr.block));
    mym(sprintf('DELETE FROM protocols WHERE block_id IN (%s)',delstr.block));
    fprintf(' done\n');
catch
    fprintf(' action failed\n')
end

try
    fprintf('Deleting tank id %d\t...',TankID)
    mym(sprintf('DELETE FROM tanks WHERE id = %d',TankID));
    fprintf(' done\n');
catch
    fprintf(' action failed\n')
end






