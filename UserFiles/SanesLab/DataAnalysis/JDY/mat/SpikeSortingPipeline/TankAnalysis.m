%% TANK ANALYSIS TEST: SANESLAB

% tank = 'C:\TDT\OpenEx\MyProjects\MLC\ID_223649\ID_223649'; % Specify tank name
% tank = 'D:\data\KP\III_226106\III_226106'; % Specify tank name
tank = 'D:\data\JDY\Tanks\AMRate\AMRate';
block = 'Block-3'; % Specify block name

%Retrieve data
data = TDT2mat(tank,block)';

ch = 11;

%data.streams.Wave.data contains the raw physiology data.
%Each column = 1 channel
%Each row = 1 timestamp
samples = size(data.streams.Wave.data,2);
x = 1:samples;
x = x/data.streams.Wave.fs;

figure
plot(x,data.streams.Wave.data(ch,:))







%[Trial onset time, Trial offset time, trial type]
ttyp = [data.epocs.TTyp.onset,data.epocs.TTyp.offset,data.epocs.TTyp.data];

%[Trial offset time, response code]
rcod = [data.epocs.RCod.onset,data.epocs.RCod.data];

