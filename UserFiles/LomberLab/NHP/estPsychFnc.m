function res = estPsychFnc(Data)
% res = estPsychFnc(Data)
% 
% Fit Psychometric function and plot using the psignifit toolbox
% https://github.com/wichmann-lab/psignifit.git
%
% Input:
%   Data    ...     Structure of Data from running the NHP joystick sound
%                   localization task.
%
% Output:
%   res     ...     Structure result of fitting Data
%                   res.Fit = [threshold,width,lambda,gamma,eta]
%
% Daniel.Stolzberg@gmail.com 8/2016

addpath C:\gits\psignifit

if nargin == 1 || isempty(adjust), adjust = false; end

% Use Response Code bitmask to compute performance
RCode = [Data.ResponseCode]';

assert(length(RCode) > 10,'Insufficient trials to generate psychometric function');

Angle = [Data.Behavior_Speaker_Angle];
uAngle = unique(Angle);

% Decode bitmask generated using ep_BitmaskGen
IND = NHP_decodeResponseCode(RCode);

RRcount = uAngle;
nTrials  = uAngle;
for i = 1:length(uAngle)
    ind = Angle == uAngle(i);
    RRcount(i) = sum(IND.RespRight(ind) & ~IND.Abort(ind) & ~IND.NoResponse(ind));
    nTrials(i)  = sum(~IND.Abort(ind) & ~IND.NoResponse(ind));
end

dat = [uAngle(:) RRcount(:) nTrials(:)];

f = findFigure('PsychFcn','color','w');
clf(f)
figure(f);

options             = struct;   
% options.sigmoidName = 'logistic';
options.sigmoidName = 'norm';
options.expType     = 'equalAsymptote';
% This setting is essentially a special case of Yes/No experiments. Here
% the asymptotes are "yoked", i. e. they are assumed to be equally far from
% 0 or 1. This corresponds to the assumption that stimulus independent
% errors are equally likely for clear "Yes" answers as for clear "No" answers.
% https://github.com/wichmann-lab/psignifit/wiki/Experiment-Types

% options.useGPU      = 1;
% options.instantPlot = 1;


res = psignifit(dat,options);
% res = psignifitFast(dat,options);

poptions.xLabel = 'Speaker Angle';
poptions.CIthresh = false;
plotPsych(res,poptions);
if adjust, astr = '; adjusted'; else astr = ''; end
title(sprintf('Threshold = %0.2f%c (\\lambda=%0.2f%s)',res.Fit(1),char(176),res.Fit(3),astr))



