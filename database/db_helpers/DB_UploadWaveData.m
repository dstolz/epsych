function result = DB_UploadWaveData(tankname,blockname,eventname,data)
% result = DB_UploadWaveData(tankname,blockname,eventname)
% result = DB_UploadWaveData(tankname,blockname,eventname,data)
%
% Upload waveform data to a database.  A connection to the database should
% already be established.
%
% data = data.streams.(eventname).data ... where data is a NxC matrix with
% N samples and C channels.
%
% DJS 2013

result = 0; %#ok<NASGU>

if nargin == 3
    % get Wave Data from tank
    data = TDT2mat(tankname,blockname,'silent',1,'type',4);
end

stream = data.streams.(eventname).data;
clear data

% Split WaveData according to size of blob datatype (2^16-1 bytes)
a = stream(1); %#ok<NASGU>
w = whos('a');
splits = 1:2^16/w.bytes-2*w.bytes:size(stream,1);
if splits(end) < size(stream,1)
    splits(end+1) = size(stream,1)+1;
end

blocknum = str2num(blockname(find(blockname=='-',1,'last')+1:end)); %#ok<ST2NM>
block_id = myms(sprintf([ ...
    'SELECT b.id FROM blocks b ', ...
    'INNER JOIN tanks t ON b.tank_id = t.id ', ...
    'WHERE t.name = "%s" AND block = %d'], ...
    tankname,blocknum));

% get corresponding channel_id
[chans,cids] = myms(sprintf([ ...
    'SELECT channel,id ', ...
    'FROM channels WHERE block_id = %d ', ...
    'ORDER by channel'],block_id)); %#ok<ASGLU>

fprintf('\tUploading Stream Data ''%s'' on Block ''%s'' ... ', ...
    eventname,blockname)
for k = 1:length(cids)
    for j = 1:length(splits)-1
        mym([ ...
            'REPLACE INTO wave_data ', ...
            'VALUES ({Si},{Si},"{M}")'], ...
            cids(k),j,stream(splits(j):splits(j+1)-1,k));
    end
end
fprintf('done\n')

result = 1;

