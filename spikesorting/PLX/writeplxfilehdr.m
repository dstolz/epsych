function plx_id = writeplxfilehdr(filename,freq,nch,npw,maxts)
pad256(1:256) = uint8(0);

% create the file and write the file header

plx_id = fopen(filename, 'w');
if plx_id == -1
    error('Unable to open file "%s".  Maybe it''s open in another program?',filename)
end
fwrite(plx_id, 1480936528, 'integer*4');    % 'PLEX' magic code
fwrite(plx_id, 101, 'integer*4');           % the version no.
fwrite(plx_id, pad256(1:128), 'char');      % placeholder for comment
fwrite(plx_id, freq, 'integer*4');          % timestamp frequency
fwrite(plx_id, nch, 'integer*4');           % no. of DSP channels
fwrite(plx_id, 0, 'integer*4');             % no. of event channels
fwrite(plx_id, 0, 'integer*4');             % no. of A/D (slow-wave) channels
fwrite(plx_id, npw, 'integer*4');           % no. points per waveform
fwrite(plx_id, npw/4, 'integer*4');         % (fake) no. pre-threshold points
[YR, MO, DA, HR, MI, SC] = datevec(now);    % current date & time
fwrite(plx_id, YR, 'integer*4');            % year
fwrite(plx_id, MO, 'integer*4');            % month
fwrite(plx_id, DA, 'integer*4');            % day
fwrite(plx_id, HR, 'integer*4');            % hour
fwrite(plx_id, MI, 'integer*4');            % minute
fwrite(plx_id, SC, 'integer*4');            % second
fwrite(plx_id, 0, 'integer*4');             % fast read (reserved)
fwrite(plx_id, freq, 'integer*4');          % waveform frequency
fwrite(plx_id, maxts*freq, 'double');       % last timestamp
fwrite(plx_id, pad256(1:56), 'char');       % should make 256 bytes

% now the count arrays (with counts of zero)
for i = 1:40
    fwrite(plx_id, pad256(1:130), 'char');    % first 20 are TSCounts, next 20 are WFCounts
end
for i = 1:8
    fwrite(plx_id, pad256(1:256), 'char');    % all of these make up EVCounts
end
