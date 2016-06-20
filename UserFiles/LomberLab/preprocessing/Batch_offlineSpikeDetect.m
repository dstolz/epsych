%% Batch offlineSpikeDetect

tank = 'D:\KingKong_Cloud (HIDEME)\BIG_DATA\ChronicEphys\HANSOLO\HANSOLO_20160519';
blocks = TDT2mat(tank);
minSpikesPerSecond = 1;


%%
for b = blocks
    fprintf('Processing ''%s'' of tank ''%s''\n',char(b),tank)
    d = TDT2mat(tank,char(b),'NODATA',true,'VERBOSE',false);
    d = datevec(d.info.duration,'HH:MM:SS');
    minSpikes = (d(4)*3600+d(5)*60+d(6))*minSpikesPerSecond;
    fprintf('Minimum Spikes: %d\n',minSpikes)
    
    offlineSpikeDetect(tank,char(b),'D:\DataProcessing\HANSOLO\HANSOLO_20160519\plx', ...
        [],[],[],[],minSpikes);
end
