function success = GetThresholds(DA)
% success = GetThresholds(DA)
% 
% Save spike thresholds (hoops) and spike/wave filter settings.
% 
% Hoops location: 'C:\Electrophys\RunTime Files\Thresh.mat'
% 
% See also SetThresholds
% 
% DJS (c) 2012

NCHANS = 32;

if ~DA.CheckServerConnection, DA.ConnectServer('Local'); end

for i = 1:NCHANS
    spike.threshold(i) = DA.GetTargetVal(num2str(i,'Acq.aSnip~%d'));
end

if ~any(spike.threshold)
    fprintf('\n\n***** WARNING: No spike thresholds found! *****\n\n')
end

spike.HP = DA.GetTargetVal('Acq.Spike_HP');
spike.LP = DA.GetTargetVal('Acq.Spike_LP'); %#ok<STRNU>

wave.HP = DA.GetTargetVal('Acq.Wave_HP');
wave.LP = DA.GetTargetVal('Acq.Wave_LP'); %#ok<STRNU>

path = 'C:\Electrophys\RunTime Files\';

if ~isdir(path), mkdir(path); end

filename = fullfile(path,'Thresh.mat');

save(filename,'spike', 'wave');

success = exist(filename,'file');

s = dir(filename);
if success
    disp(['Hoops acquired at ' datestr(s.date,'mmm.dd,yyyy HH:MM:SS PM')]);
else
    disp('SaveHoops:Unable to Save Hoops!');
    beep
end
