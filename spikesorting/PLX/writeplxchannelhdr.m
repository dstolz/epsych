function writeplxchannelhdr(plx_id,ch,npw)
% now the single PL_ChanHeader
pad256(1:256) = uint8(0);

% assume simple channel names
DSPname = sprintf('DSP%03d',ch);
SIGname = sprintf('SIG%03d',ch);

fwrite(plx_id, DSPname, 'char');
fwrite(plx_id, pad256(1:32-length(DSPname)));
fwrite(plx_id, SIGname, 'char');
fwrite(plx_id, pad256(1:32-length(SIGname)));
fwrite(plx_id, ch, 'integer*4');            % DSP channel number
fwrite(plx_id, 0, 'integer*4');             % waveform rate limit (not used)
fwrite(plx_id, ch, 'integer*4');            % SIG associated channel number
fwrite(plx_id, ch, 'integer*4');            % SIG reference  channel number
fwrite(plx_id, 1, 'integer*4');             % dummy for gain
fwrite(plx_id, 0, 'integer*4');             % filter off
fwrite(plx_id, -12, 'integer*4');           % (fake) detection threshold value
fwrite(plx_id, 0, 'integer*4');             % sorting method (dummy)
fwrite(plx_id, 0, 'integer*4');             % number of sorted units
for i = 1:10
    fwrite(plx_id, pad256(1:64), 'char');     % filler for templates (5 * 64 * short)
end
fwrite(plx_id, pad256(1:20), 'char');       % template fit (5 * int)
fwrite(plx_id, npw, 'integer*4');           % sort width (template only)
fwrite(plx_id, pad256(1:80), 'char');       % boxes (5 * 2 * 4 * short)
fwrite(plx_id, 0, 'integer*4');             % beginning of sorting window
fwrite(plx_id, pad256(1:128), 'char');      % comment
fwrite(plx_id, pad256(1:44), 'char');       % padding

