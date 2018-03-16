function RunTtest
close all
clc

%---FLAGS---%
NH        =   [5.06 4.72 3.79 3.34 3.66 3.71 4.61 5.80];
CHL       =   [4.98 4.09 4.41 3.2 3.86 4.81 4.22];

[~,P,~,STATS] = ttest2(NH,CHL);

disp(['p = ' num2str(P)])
disp(['t = ' num2str(STATS.tstat)])
disp(['df = ' num2str(STATS.df)])