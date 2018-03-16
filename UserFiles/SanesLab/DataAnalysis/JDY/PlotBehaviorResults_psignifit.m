function PlotBehaviorResults_psignifit
%---Script that analyzes behavior data from AM Rate Discrimination Task with psignifit.
%Created 02/04/2018 JDY.

%1) Click Run ("Play" button)

clear all
close all
clc

%---Load Data---%
[f,p]		=	uigetfile;
file		=	[p f];
load(file)
D			=	extractfields(Data);
%---Organize Data---%
DATA		=	GetData(D,Info);
PlotFunctions(DATA);

%---Locals---%
function d = extractfields(Data)
N				=	length(Data);
for i=1:N
	d(i).Reminder		=	Data(i).Reminder;
	d(i).ResponseCode	=	Data(i).ResponseCode;
	d(i).AMrate			=	Data(i).AMrate;
	d(i).AMdepth		=	Data(i).AMdepth;
	d(i).TrialType		=	Data(i).TrialType;
	d(i).RespLatency	=	Data(i).RespLatency;
end

function DATA = GetData(Data,Info)
D						=	Data;
N						=	length(D);
RespLegend				=	Info.Bits;
Resp					=	nan(N,1);			%---1:Hit; 2:Miss; 3:CR; 4:FA---%
Rate					=	nan(N,1);		
Trial					=	nan(N,1);			%---0:Go; 1:Nogo---%
Lat						=	nan(N,1);
Depth					=	nan(N,1);

for a=1:N
	dat					=	D(1,a);
	idx					=	nan(4,1);
% 	if( Ephys )
% 		remind(a,1)		=	dat.Behavior_Reminder;
% 	else
		remind(a,1)		=	dat.Reminder;
% 	end
	for b=1:4
		if( b == 1 )
			if( isfield(RespLegend, 'hit') )
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.hit);
			else
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.Hit);
			end
		end
		if( b == 2 )
			if( isfield(RespLegend, 'miss') )
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.miss);
			else
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.Miss);
			end
		end
		if( b == 3 )
			if( isfield(RespLegend, 'cr') )
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.cr);
			else
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.CR);
			end
		end
		if( b == 4 )
			if( isfield(RespLegend, 'fa') )
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.fa);
			else
				idx(b,1)	=	bitget(dat.ResponseCode,RespLegend.FA);
			end
		end		
	end
	Resp(a,1)			=	find(idx,1);
	Rate(a,1)			=	dat.AMrate;
	Depth(a,1)			=	dat.AMdepth;
% if( Ephys )
% 	Trial(a,1)			=	dat.Behavior_TrialType;
% 	Lat(a,1)			=	dat.Behavior_RespLatency;
% else
	Trial(a,1)			=	dat.TrialType;
	Lat(a,1)			=	dat.RespLatency;
% end
end

DATA					=	[Trial Rate Resp Lat Depth];
rel						=	remind == 0;
DATA					=	DATA(rel,:);

function PlotFunctions(DATA)
gel				=	DATA(:,1) == 0;
Go				=	DATA(gel,:);
Rates			=	unique(Go(:,2));
% Depths			=	unique(Go(:,end));
NRates			=	length(Rates);

dp				=	nan(NRates,1);
pHits			=	nan(NRates,1);
Ngo				=	nan(NRates,1);
N				=	nan(NRates,1);
%---For Nogo stimuli---%
nel				=	DATA(:,1) == 1;
Nogo			=	DATA(nel,:);
fel				=	Nogo(:,3) == 4; %Search for FAs for Nogo trials%
% pfa				=	sum(fel)/(length(fel)+0.50);
pfa				=	sum(fel)/(length(fel));
FAtrial			=	getFAacrosstrial(fel);
Nnogo			=	length(fel);
% if( pfa == 0 )
% % 	pfa			=	0.01;
% 	pfa			=	1/(2*length(fel));
% end
if( pfa < 0.05 )
	pfa			=	0.05;
end
pFA				=	repmat(pfa,NRates,1);

%---For Go stimuli---%
for i=1:NRates
	rate		=	Rates(i);
	nel			=	DATA(:,2) == rate;
	N(i,1)		=	sum(nel);
	sel			=	Go(:,2) == rate;
	Ngo(i,1)	=	sum(sel);
	data		=	Go(sel,:);
	hel			=	data(:,3) == 1; %Hit on Go trial%
% 	phits		=	sum(hel)/(length(hel)+0.50);
	phits		=	sum(hel)/length(hel);
	pH(i,1)		=	phits;
	if( phits > 0.95  )
		phits	=	0.95;
	end
	if( phits < 0.05  )
		phits	=	0.05;
	end
	pHits(i,1)	=	phits;

% 	if( phits == 1 )
% % 		phits	=	0.99;
% 		phits	=	1 - (1/(2*length(hel)));
% 	end
	dp(i,1)		=	calculatedprime(phits,pFA(i));
    
end
pfa				=	dround(pfa)*100;
zel				=	dp < 0;
dp(zel)			=	0;

subplot(1,2,1)
psychometricfunction(Rates,pHits,'ko','Hit Rate')

subplot(1,2,2)
psychometricfunction(Rates,dp,'ko','dprime')

%---psignifit---%
[x,fitHits,dpFit]		=	getpsignfit(Rates,Ngo,pHits,N,Nnogo,pfa);
fa				=	repmat(pfa,length(fitHits),1);

%Plot psignifit data%
subplot(1,2,1)
plot(x,fitHits,'k-','LineWidth',2)
subplot(1,2,2)
plot(x,dpFit,'k-','LineWidth',2)
xel				=	dpFit >=1;
xthresh			=	x(xel);
threshold		=	nanmin(xthresh);
JND             =   (threshold-4)/4;
FIT             =	[x' fitHits' dpFit'];
subplot(1,2,2)
title(['Thresh = ' num2str(threshold) '; JND = ' num2str(JND)])

function dprime = calculatedprime(pHit,pFA)
zHit	=	sqrt(2)*erfinv(2*pHit-1);
zFA		=	sqrt(2)*erfinv(2*pFA-1);
% zHit	=	norminv(pHit,0,1);
% zFA		=	norminv(pFA,0,1);
%-- Calculate d-prime
dprime = zHit - zFA;

function FAtrial = getFAacrosstrial(fel)
N			=	length(fel);
FAtrial		=	nan(N,1);
for i=1:N
	fa		=	fel(1:i);
	pfa		=	sum(fa)/length(fa);
	FAtrial(i,1)	=	pfa;
end

function [x,fitHits,dpFit] = getpsignfit(X,Ngo,pHits,N,Nnogo,pFA)
D		=	[X (Ngo.*pHits) N];
% D		=	[0 0 Nnogo;D];
% options.sigmoidName    = 'norm';
% options.expType        = 'nAFC';
% options.expN           = 1/pFA;
% options.sigmoidName    = 'logn';
% options.sigmoidName    = 'weibull';
% options.expType        = '4AFC';
% options.sigmoidName    = 'weibull';
% options.expType = 'equalAsymptote';
% Results	=	psignifit(D,options);

Results	=	psignifit(D);
xlength = max(Results.data(:,1))-min(Results.data(:,1));
plotOptions.extrapolLength	=	0.20;
xLow = min(Results.data(:,1))- plotOptions.extrapolLength*xlength;
xHigh = max(Results.data(:,1))+ plotOptions.extrapolLength*xlength;
% xLow	=	X(1);
% xHigh	=	X(end);
x  = linspace(xLow,xHigh,1000);

% x       =	linspace(min(Results.data(:,1)),max(Results.data(:,1)),1000);
fitHits =	(1-Results.Fit(3)-Results.Fit(4))*arrayfun(@(x)...
	Results.options.sigmoidHandle(x,Results.Fit(1),...
	Results.Fit(2)),x)+Results.Fit(4);
pfa     =   pFA/100;
zFA		=	sqrt(2)*erfinv(2*pfa-1);
dpFit  = sqrt(2)*erfinv(2*fitHits-1)- zFA;
% dp		=	sqrt(2)*erfinv(2*pHits-1)- zFA;
% dpFit			=	calculatedprime2(fitHits,fa,x);

%---Plotting Functions---%
function psychometricfunction(X,Y,mark,yLabel)
% plot(X,Y,'k-','LineWidth',2)
hold on
plot(X,Y,mark,'MarkerSize',12,'MarkerFaceColor','k','LineWidth',2)
if( strcmp(yLabel,'Hit Rate') )
	maxy	=	1.05;
	ylim([0 maxy])
	set(gca,'YTick',0:0.50:1,'YTickLabel',0:0.50:1);
	ylim([0 1])
else
	maxy	=	3.1;
	ylim([0 maxy])
	plot([0 50],[1 1],'k--','Color',[0.50 0.50 0.50])
	set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
	ylim([-0.10 3.1])
end
set(gca,'FontSize',20)
set(gca,'XTick',X,'XTickLabel',X)
xlabel('AM Rate (Hz)')
ylabel(yLabel)
axis square
xlim([3 max(X)*1.1])
