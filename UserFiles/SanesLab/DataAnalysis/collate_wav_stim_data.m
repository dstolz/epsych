
function collate_wav_stim_data()

close all;
set(0, 'DefaultTextInterpreter', 'none')
set(0,'DefaultAxesFontSize',12)

% Import wav files
searchpath  = 'D:\stim\Barascud_wav_files\';
searchhname = fullfile(searchpath,'*resampled.wav');
soundfiles  = dir(searchhname);
soundfiles  = {soundfiles.name};

% rng('shuffle')
% wav_seq = randperm(numel(soundfiles));
wav_seq = 1:numel(soundfiles);

for iWAV = wav_seq

%Select and load sound file
wavfilename = soundfiles{iWAV};
[wavstim, fs, stimsize] = wavread(fullfile(searchpath,wavfilename));

%Plot spectrogram of sound stim 
wF(iWAV) = figure;
spectrogram(wavstim,kaiser(256,5),50,1000,fs,'yaxis')
set(gca, 'YLim',[0 5000], 'YScale', 'linear', 'XLim', [0 size(wavstim,1)/fs])
title(wavfilename)
xlabel('Time (s)')
ylabel('Frequency (Hz)')

%Save spectrgram
savepath = 'C:\Users\sanesadmin\Google Drive\kp_data\Barascud_soundfiles\stim_spectrograms';
saveas(wF(iWAV), fullfile(savepath,strtok(wavfilename,'.')) ,'epsc')
saveas(wF(iWAV), fullfile(savepath,strtok(wavfilename,'.')) ,'fig')

%Plot rms

end
end
