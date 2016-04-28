function writeplxdata(plx_id,ch,freq,ts,units,npw,wave)
% now the spike waveforms, each preceded by a PL_DataBlockHeader
n = length(ts);

for ispike = 1:n
    fwrite(plx_id, 1, 'integer*2');           % type: 1 = spike
    fwrite(plx_id, 0, 'integer*2');           % upper byte of 5-byte timestamp
    fwrite(plx_id, ts(ispike)*freq, 'integer*4');  % lower 4 bytes
    fwrite(plx_id, ch, 'integer*2');          % channel number
    fwrite(plx_id, units(ispike), 'integer*2');  % unit no. (0 = unsorted)
    fwrite(plx_id, 1, 'integer*2');           % no. of waveforms = 1
    fwrite(plx_id, npw, 'integer*2');         % no. of samples per waveform
    
    fwrite(plx_id, wave(ispike, 1:npw), 'integer*2');
end
