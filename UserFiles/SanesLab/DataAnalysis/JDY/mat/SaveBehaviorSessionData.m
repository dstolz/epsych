function SaveBehaviorSessionData
%---Script that analyzes behavior data from AM Rate Discrimination Task.
%Created 12/01/2017 JDY.

%1) Click Run ("Play" button)

clear all
close all
clc

%---Load Data---%
[f,p]           =	uigetfile;
file            =	[p f];
session         =   inputdlg('Session #');
Session         =   str2double(session);
[SavePath,ID]    =   getsavepath(p,f);

load(file)
D			=	extractfields(Data);
%---Organize Data---%
DATA		=	GetData(D,Info);
figure(1)
LatencyPlots(DATA,ID)

%---Plot Data Overview---%
Data = PlotFunctions(DATA);

%---Save File---%
Fname			=	[SavePath num2str(ID) '-Session-' num2str(Session) '.mat' ];
save( Fname ,'Data')
disp('Saved Data!')

%---Locals---%
function [SavePath,ID]    =   getsavepath(p,f)
idx          =   strfind(p,'/');
idx          =   idx(end-1);
S            =   p(1:idx);
id           =   strfind(f,'_');
ID           =   f(1:id-1);
SavePath     =   [S 'Saved/' ID '/'];

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

function Data = PlotFunctions(DATA)
gel				=	DATA(:,1) == 0;
Go				=	DATA(gel,:);
Rates			=	unique(Go(:,2));
NRates			=	length(Rates);

dp				=	nan(NRates,1);
pHits			=	nan(NRates,1);
Ngo				=	nan(NRates,1);
N				=	nan(NRates,1);

%---For Nogo stimuli---%
nel				=	DATA(:,1) == 1;
Nogo			=	DATA(nel,:);
fel				=	Nogo(:,3) == 4;
pfa				=	sum(fel)/(length(fel));
FAtrial			=	getFAacrosstrial(fel);
Nnogo			=	length(fel);

Lat				=	cell(NRates,1);

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
	hel			=	data(:,3) == 1;
	phits		=	sum(hel)/length(hel);
    Lat(i,1)	=	{data(hel,end-1)};
	if( phits > 0.95  )
		phits	=	0.95;
	end
	if( phits < 0.05  )
		phits	=	0.05;
	end
	pHits(i,1)	=	phits;
	dp(i,1)		=	calculatedprime(phits,pFA(i));
end
pfa				=	dround(pfa);
zel				=	dp < 0;
dp(zel)			=	0;

subplot(2,4,6)
psychometricfunction(Rates,pHits,'ko','Hit Rate')
%---psignifit---%
[x,fitHits]		=	getpsignfit(Rates,Ngo,pHits,N,Nnogo,pfa);
fa				=	repmat(pfa,length(fitHits),1);
dpFit			=	calculatedprime2(fitHits,fa,x);
plot(x,fitHits,'k-','LineWidth',2)

subplot(2,4,7)
psychometricfunction(Rates,dp,'ko','dprime')
xel				=	dpFit >=1;
xthresh			=	x(xel);
threshold		=	nanmin(xthresh);
Data.dpFit		=	[x' dpFit];
Data.threshold	=	threshold;
plot(x,dpFit,'k-','LineWidth',2)

subplot(2,4,8)
xFA				=	1:1:length(FAtrial);
xFA				=	xFA/max(xFA);
plot(xFA,FAtrial,'k-','LineWidth',2)
hold on
set(gca,'FontSize',20)
set(gca,'XTick',0:0.25:1,'XTickLabel',0:0.25:1);
title(['FA = ' num2str(pfa)])
xlabel('Prop. of Trials')
xlim([0 1])
ylabel('FA Rate')
ylim([-0.005 1.005])
set(gca,'YTick',0:0.25:1,'YTickLabel',0:0.25:1);
axis square

Data.Rates		=	Rates;
Data.dp			=	dp;
Data.FAtrial	=	FAtrial;
Data.Lat		=	Lat;
Data.Raw        =   DATA;
nogo            =   unique(Nogo(:,2));
jnd             =   (threshold-nogo)/nogo;
Data.JND        =   jnd;


function dprime = calculatedprime(pHit,pFA)
zHit	=	sqrt(2)*erfinv(2*pHit-1);
zFA		=	sqrt(2)*erfinv(2*pFA-1);
% zHit	=	norminv(pHit,0,1);
% zFA		=	norminv(pFA,0,1);
%-- Calculate d-prime
dprime = zHit - zFA;

function dprime = calculatedprime2(pHit,pFA,x)
sel			=	pHit > 0.95;
pHit(sel)	=	0.95;
ssel		=	pHit < 0.05;
pHit(ssel)	=	0.05;
dprime		=	nan(length(pHit),1);

for i=1:length(pHit)
	phit	=	pHit(i);
	pfa		=	pFA(i);
	zHit	=	sqrt(2)*erfinv(2*phit-1);
	zFA		=	sqrt(2)*erfinv(2*pfa-1);
% 	zHit	=	norminv(pHit,0,1);
% 	zFA		=	norminv(pFA,0,1);
	%-- Calculate d-prime --%
	dp		=	zHit - zFA;
% 	if( dp < 0 )
% 		dp	=	0;
% 	end
	dprime(i,1) = dp;
end

function FAtrial = getFAacrosstrial(fel)
N			=	length(fel);
FAtrial		=	nan(N,1);
for i=1:N
	fa		=	fel(1:i);
	pfa		=	sum(fa)/length(fa);
	FAtrial(i,1)	=	pfa;
end

%---Plotting Functions---%
function LatencyPlots(DATA,ID)
N			=	length(DATA);
subplot(2,1,1)
for i=1:N
	lat		=	DATA(i,4);
	type	=	DATA(i,3);			%---1:Hit; 2:Miss; 3:CR; 4:FA---%
	if( type == 1 )
		plot(i,lat,'ko','MarkerSize',10)
	elseif( type == 2 )
		plot(i,lat,'ko','MarkerSize',10,'MarkerFaceColor','k')
	elseif( type == 3 )
		plot(i,lat,'ks','MarkerSize',10)
	elseif( type == 4 )
		plot(i,lat,'ks','MarkerSize',10,'MarkerFaceColor','k')
	end
	hold on
end
set(gca,'FontSize',20)
% maxy		=	max(DATA(:,4))*1.1;
maxy		=	3000;
set(gca,'YTick',0:500:maxy,'YTickLabel',0:500:maxy);
xlabel('Trial #')
ylabel('Response Latency (ms)')
xlim([-5 N+5])
ylim([0 maxy])

for j=1:4
	if( j == 1 )
		pp(j)=plot(nan,nan,'ko','MarkerSize',10);
	elseif( j == 2 )
		pp(j)=plot(nan,nan,'ko','MarkerSize',10,'MarkerFaceColor','k');
	elseif( j == 3 )
		pp(j)=plot(nan,nan,'ks','MarkerSize',10);
	elseif( j == 4 )
		pp(j)=plot(nan,nan,'ks','MarkerSize',10,'MarkerFaceColor','k');
	end
	
	sel		=	DATA(:,3) == j;
	
	if( j == 2 )
		zel	=	DATA(:,2) == 512 & DATA(:,3) == 2;
		lat	=	DATA(zel,4);
	end
	
	d		=	DATA(sel,4);
	subplot(2,4,5)
	plotbox(j,d)
end

subplot(2,1,1)
title(ID)
legend(pp,'Hit','Miss','CR','FA')
legend('boxoff')

subplot(2,4,5)
set(gca,'FontSize',20)
% title(ID)
% maxy		=	max(DATA(:,4))*1.1;
set(gca,'YTick',0:500:maxy,'YTickLabel',0:500:maxy);
ylabel('Response Latency (ms)')
xlim([0 5])
ylim([0 maxy])
set(gca,'XTick',1:1:4,'XTickLabel',[{'Hit'},{'Miss'},{'CR'},{'FA'}]);
axis square;

function psychometricfunction(X,Y,mark,yLabel)
plot(X,Y,mark,'MarkerSize',12,'MarkerFaceColor','k','LineWidth',2)
hold on
if( strcmp(yLabel,'Hit Rate') )
	maxy	=	1.05;
	ylim([0 maxy])
	set(gca,'YTick',0:0.50:1,'YTickLabel',0:0.50:1);
	ylim([0 1])
else
	maxy	=	3.1;
	ylim([0 maxy])
	plot([-100 100],[1 1],'k--','Color',[0.50 0.50 0.50])
	set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
	ylim([-0.10 3.1])
end
set(gca,'FontSize',20)
set(gca,'XTick',X,'XTickLabel',X)
set(gca,'XScale','log')
xlabel('AM Rate (Hz)')
ylabel(yLabel)
axis square
xlim([0 17])

function plotbox(x,y)
p25		=	prctile(y,25);
p75		=	prctile(y,75);
med		=	nanmedian(y);
%---Make box---%
plot([x-0.3 x+0.3],[p25 p25],'k-')
hold on
plot([x-0.3 x+0.3],[p75 p75],'k-')
plot([x-0.3 x-0.3],[p25 p75],'k-')
plot([x+0.3 x+0.3],[p25 p75],'k-')
plot([x-0.3 x+0.3],[med med],'k-')
%---Plot individual data points---%
range	=	x-0.30:0.05:x+0.30;
N		=	length(y);
for i=1:N
	idx		=	randi(length(range));
	tempx	=	range(idx);
	if( x == 1 )
		plot(tempx,y(i),'ko');
	elseif( x == 2 )
		plot(tempx,y(i),'ko','MarkerFaceColor','k');
	elseif( x == 3 )
		plot(tempx,y(i),'ks');
	elseif( x == 4 )
		plot(tempx,y(i),'ks','MarkerFaceColor','k');
	end
end

function plotbox2(x,y)
p25		=	prctile(y,25);
p75		=	prctile(y,75);
med		=	nanmedian(y);
%---Make box---%
plot([x-0.3 x+0.3],[p25 p25],'k-')
hold on
plot([x-0.3 x+0.3],[p75 p75],'k-')
plot([x-0.3 x-0.3],[p25 p75],'k-')
plot([x+0.3 x+0.3],[p25 p75],'k-')
plot([x-0.3 x+0.3],[med med],'k-')
%---Plot individual data points---%
range	=	x-0.30:0.05:x+0.30;
N		=	length(y);
for i=1:N
	idx		=	randi(length(range));
	tempx	=	range(idx);
	plot(tempx,y(i),'ko');
	hold on
end

function [x,fitHits] = getpsignfit(X,Ngo,pHits,N,Nnogo,pFA)
D		=	[X (Ngo.*pHits) N];

Results	=	psignifit(D);

xlength = max(Results.data(:,1))-min(Results.data(:,1));
plotOptions.extrapolLength	=	0.20;
xLow = min(Results.data(:,1))- plotOptions.extrapolLength*xlength;
xHigh = max(Results.data(:,1))+ plotOptions.extrapolLength*xlength;

x  = linspace(xLow,xHigh,1000);

fitHits =	(1-Results.Fit(3)-Results.Fit(4))*arrayfun(@(x)...
	Results.options.sigmoidHandle(x,Results.Fit(1),...
	Results.Fit(2)),x)+Results.Fit(4);

zFA		=	sqrt(2)*erfinv(2*pFA-1);
dpFit  = sqrt(2)*erfinv(2*fitHits-1)- zFA;
dp		=	sqrt(2)*erfinv(2*pHits-1)- zFA;

