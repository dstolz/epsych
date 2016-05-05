%% Batch offlineSpikeDetect

tank = 'D:\Data Tanks\CHRONIC_EPHYS_TANKS\HANSOLO_20160426';
blocks = TDT2mat(tank);

%%
for b = blocks
    offlineSpikeDetect(tank,char(b),'D:\DataProcessing\HANSOLO\plxTEST');
end
