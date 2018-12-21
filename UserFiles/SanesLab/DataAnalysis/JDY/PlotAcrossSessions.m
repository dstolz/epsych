function PlotAcrossSessions
close all
clc
figure(1)
%%%%%%%%%%%%%%%%%%%%%%%%
%---FLAGS---%
Xlabel = 'Absolute Day';
Ylabel = 'Lapse Rate';
xmin    =   0;
xmax    =   50;
ymin    =   0;
ymax    =   0.41;

%Lapse Rate%
HLavg = [0.35 0.21 0.13 0.07 0.05 0.04 0.07 0.16 0.02 0.05 0.03 0.04 0.03 0.05 0.04 0.03 0.04 0.03 0.24 0.04 0.04 0.02 0.03 0.05 0.07 0.08 0.07 0.06 0.04 0.07 0.06 0.08 0.05 0.05 0.04 0.09 0 0.03 0.02];
HLse = [0.05 0.04 0.06 0.03 0.01 0.01 0.03 0.11 0.01 0.02 0.02 0.01 0.01 0.02 0.01 0.01 0.01 0.01 0.14 0.01 0.01 0.01 0.02 0.03 0.02 0.04 0.03 0.03 0.01 0.03 0.02 0.02 0.03 0.01 0.01 0.02 0 0 0];
plotaverages(HLavg,HLse,[1 0.5 0])
hold on

Ctlavg = [0.12 0.1 0.06 0.07 0.05 0.04 0.05 0.05 0.05 0.04 0.03 0.02 0.03 0.04 0.06 0.04 0.02 0.05 0.05 0.06 0.08 0.07 0.03 0.04 0.05 0.06 0.02 0.03 0.06 0.02 0.02 0.03 0.01 0.03 0.03 0.04 0.05 0.02 0.09 0.13 0.06 0.12 0.07 0.04 0.12 0.03 0.05];
Ctlse = [0.04 0.04 0.02 0.02 0.02 0.02 0.02 0.02 0.02 0.01 0.01 0.01 0.01 0.01 0.02 0.01 0.01 0.02 0.02 0.02 0.03 0.02 0.01 0.01 0.02 0.03 0.01 0.01 0.03 0.01 0.01 0.01 0.01 0.02 0.02 0.02 0.03 0.01 0.05 0.08 0.04 0.07 0.04 0.03 0 0 0];
plotaverages(Ctlavg,Ctlse,'k')
hold on

%%%%%%%%%%%%%%%%%%%%%%%%
xlim([xmin xmax])
ylim([ymin ymax])
set(gca,'FontSize',20)
set(gca,'XTick',0:5:xmax,'XTickLabel',0:5:xmax);
xlabel(Xlabel)
ylabel(Ylabel)
set(gca,'YTick',0:0.1:ymax,'YTickLabel',0:0.1:ymax);
axis square

%---Locals---%
function plotaverages(Avg,SEM,color)
NDays = length(Avg);
Days = 1:1:NDays;
smoA = smooth(Avg);
smoS = smooth(SEM);

plot(Days,smoA,'-','Color',color,'LineWidth',2)
hold on
plot(Days,smoA-smoS,'--','Color',color,'LineWidth',1)
plot(Days,smoA+smoS,'--','Color',color,'LineWidth',1)
