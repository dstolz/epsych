%% TANK ANALYSIS TEST: SANESLAB

tank = 'C:\TANKS\PhysTest'; % Specify tank name
block = 'Block-2'; % Specify block name

%Retrieve stimulus epochs (2) and stream data (4) from tank
data = TDT2mat(tank,block,'type',[2 4]);


%data.streams.Wave.data contains the raw physiology data. 
    %Each column = 1 channel
    %Each row = 1 timestamp
    samples = size(data.streams.Wave.data,1);
    secs = samples/data.streams.Wave.fs;
    
%[Trial onset time, Trial offset time, trial type]
ttyp = [data.epocs.TTyp.onset,data.epocs.TTyp.offset,data.epocs.TTyp.data];


%[Trial offset time, response code]
rcod = [data.epocs.RCod.onset,data.epocs.RCod.data];

