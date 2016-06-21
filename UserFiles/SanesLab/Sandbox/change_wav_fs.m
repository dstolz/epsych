
function change_wav_fs()


% Select the folder containing sound stimulus files

[pnst] = uigetdir('D:\stim\','Select folder of stimulus files');
soundfiles = dir([pnst '\*.wav']);
soundfiles = {soundfiles.name};


for iWAV = 1:numel(soundfiles)

% Select sound file(s)

wavfilename = soundfiles{iWAV};
wavfile = importdata(fullfile(pnst,wavfilename));
wavstim = wavfile.data;


% Resample stimuli to match Fs of TDT

fs_TDT = 48828.125;
fs_wav = wavfile.fs;

[P,Q] = rat(fs_TDT/fs_wav);
    % abs((P/Q)*fs_wav - fs_TDT)
wav_resampled = resample(wavstim,P,Q);

buffer = wav_resampled;
Fs     = fs_TDT;


% Save as wav file
newwavfilename = sprintf('%s_resampled.wav',strtok(wavfilename,'.'));
newpathfilename = fullfile(pnst,newwavfilename);
audiowrite(newpathfilename, wav_resampled, round(fs_TDT));

% Save as mat file
newmatfilename = sprintf('%s_resampled.mat',strtok(wavfilename,'.'));
newpathfilename = fullfile(pnst,newmatfilename);
save(newpathfilename, 'buffer', 'Fs', '-mat')


end


end




