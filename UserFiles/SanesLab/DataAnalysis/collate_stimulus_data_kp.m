
function collate_wav_stim_info()

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

figure;
spectrogram(wavstim,kaiser(256,5),50,1000,fs_TDT,'yaxis')
set(gca, 'YLim',[0 5000], 'YScale', 'linear', 'XLim', [0 size(wav_resampled,1)/fs])
title(wavfilename)

savepath = 'C:\Users\sanesadmin\Google Drive\kp_data\Barascud_soundfiles\stim_spectrograms';
save()

%Plot buffer
% figure;
% plot(([1:buffersize]/fs_TDT),buffer)%,'Color',plot_colors{id})
% set(gca,'xlim', [0 bdur]);

%Save signal from buffer
Stimuli(iWAV).filename = wavfilename;
Stimuli(iWAV).buffer   = buffer;
Stimuli(iWAV).fs       = fs;


end

save(fullfile(savepath,'Stimuli'),'stimuli','-mat','-v7.3')

