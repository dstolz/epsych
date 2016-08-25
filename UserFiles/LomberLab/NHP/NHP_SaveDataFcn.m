function NHP_SaveDataFcn(RUNTIME)
% ep_SaveDataFcn(RUNTIME)
% 
% Default function fo saving behavioral data
% 
% Use ep_RunExpt GUI to specify custom function.
% 
% Daniel.Stolzberg@gmail.com 2014




h = msgbox(sprintf('Save Data for ''%s'' in Box ID %d',RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID), ...
    'Save Behavioural Data','help','modal');

uiwait(h);

[fn,pn] = uiputfile({'*.mat','MATLAB File'}, ...
    sprintf('Save ''%s (%d)'' Data',RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID));

if fn == 0
    fprintf(2,'NOT SAVING DATA FOR SUBJECT ''%s'' IN BOX ID %d\n', ...
        RUNTIME.TRIALS(i).Subject.Name,RUNTIME.TRIALS(i).Subject.BoxID);
    continue
end

fileloc = fullfile(pn,fn);

Data = RUNTIME.TRIALS(i).DATA;

save(fileloc,'Data')

% Fit Psychometric function
% Uses:   https://github.com/wichmann-lab/psignifit.git
addpath C:\gits\psignifit

Angle = [Data.Behavior_Speaker_Angle];

uAngle = unique(Angle);

% Use Response Code bitmask to compute performance
RCode = [Data.ResponseCode]';

if length(RCode) < 10, return; end

% Decode bitmask generated using ep_BitmaskGen
IND.Reward      = bitget(RCode,1);
IND.Hit         = bitget(RCode,3);
IND.Miss        = bitget(RCode,4);
IND.Abort       = bitget(RCode,5);
IND.RespLeft    = bitget(RCode,6);
IND.RespRight   = bitget(RCode,7);
IND.NoRsponse   = bitget(RCode,10);
IND.Left        = bitget(RCode,11);
IND.Right       = bitget(RCode,12);
IND.Ambig       = bitget(RCode,13);
IND.NoResp      = bitget(RCode,14);

HitCount = uAngle;
nTrials  = uAngle;
for i = 1:length(uAngle)
    ind = Angle == uAngle(i);
    HitCount(i) = sum(IND.RespRight(ind) & ~IND.Abort(ind));
    nTrials(i)  = sum(ind);
end

dat = [uAngle(:) HitCount(:) nTrials(:)];

f = findFigure('PsychFcn','color','w');
clf(f)
figure(f);

options             = struct;   
options.sigmoidName = 'logistic';
options.expType     = 'YesNo';  
options.useGPU      = 1;

res = psignifit(dat,options);
% res = psignifitFast(dat,options);

poptions.xLabel = 'Speaker Angle';
poptions.CIthresh = false;
plotPsych(res,poptions);
title(sprintf('Threshold = %0.2f%c (\\lambda=%0.2g)',res.Fit(1),char(176),res.Fit(3)))                   

% res.Fit = [threshold,width,lambda,gamma,eta]














