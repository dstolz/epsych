function AMRate_Depth_v2
%---Script that analyzes behavior data from AM Rate Detection Task.
%Created 06/23/16 JDY. Initially looking at test data from running myself.
%Updated the scripte do plot psychometric functions on data (03/16/16 JDY).
clear all
close all
clc

%---FLAG---%
Save		=	1;
Ephys		=	0;
CHL			=	0;
CHLEphys	=	1;

%---Animal ID and Date---%
% Gerbil		=	'243027';
Gerbil		=	'239151';
% Gerbil		=	'240130';
% Gerbil		=	'236397';
% Gerbil		=	'241218';
% Gerbil		=	'243415';
% Gerbil		=	'247026';
% Date		=	[{'24-Mar-2017'};{'25-Mar-2017'};{'28-Mar-2017'};{'30-Mar-2017'};...
% 				{'31-Mar-2017'};{'05-Apr-2017'};{'06-Apr-2017'};{'08-Apr-2017'};{'26-Apr-2017'};...
% 				{'28-Apr-2017'};{'01-May-2017'}];
Date		=	[{'24-Apr-2017'}];
% Date		=	[{'28-Apr-2017'};{'01-May-2017'}];

NDate		=	length(Date);
for a=1:NDate
	date	=	Date{a};
	if( Ephys )
		Pname		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys Behavior/';
		File		=	[Pname Gerbil '/Depth/' Gerbil '_' date '.mat'];
	elseif( CHL )
		Pname		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/BehaviorCHL/';
		File		=	[Pname Gerbil '/Depth/' Gerbil '_' date '.mat'];
	elseif( CHLEphys )
		Pname		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys Behavior/CHL/';
		File		=	[Pname Gerbil '/Depth/' Gerbil '_' date '.mat'];
	else
		Pname		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Behavior/';
		File		=	[Pname Gerbil '/Depth/' Gerbil '_' date '.mat'];
	end
	%---Load Data---%
	load(File)
	Data			=	extractfields(Data);

	%---Organize Data---%
	ID			=	getID(File);
	DATA		=	GetData(Data,Info,Ephys);
	figure(a)
	LatencyPlots(DATA,ID)
	
	figure(a)
	Data		=	PlotFunctions(DATA,ID);
	id			=	[Gerbil '-' Date{a}];
	
	RATE		=	Data.Rates;
	%---Save Data---%
	if( Save )
		save([ Pname Gerbil '/Depth/Saved/' num2str(RATE) 'Hz/' id],'Data')
		disp('Saved Data!')
	end
% 	pause
% 	close all
end
disp('Done')

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

function ID = getID(File)
idx			=	strfind(File,'/');
idx			=	idx(end);
idx2		=	strfind(File,'.');
ID			=	File(idx+1:idx2-1);
sel			=	strfind(ID,'_');
ID(sel)		=	';';

function DATA = GetData(Data,Info,Ephys)
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
% uDepth					=	unique(Depth);
% idx						=	find(Depth == uDepth(end-2));
% sel						=	Resp(idx) == 1;
% iidx					=	idx(sel);
% for i=1:2
% 	ran					=	randi(length(iidx));
% 	Resp(iidx(ran))		=	2;
% end
% idx						=	find(Depth == uDepth(2));
% sel						=	Resp(idx) == 2;
% iidx					=	idx(sel);
% for i=1:2
% 	ran					=	randi(length(iidx));
% 	Resp(idx(ran))		=	1;
% end
% Resp(idx)				=	1;

% idx						=	find(Rate == 256 & Resp == 2 );
% Resp(idx(end-1:end))				=	1;
% Lat(idx(end-1:end))			=	Lat(idx(end-1:end))*2;
% idx						=	find(Rate == 4 & Resp == 2 );
% Resp(idx(end-2:end))			=	1;
% Lat(idx(end-2:end))			=	Lat(idx(end-2:end))*2;

% idx							=	find(Depth == 0.50 & Resp == 1 );
% Resp(idx(end-3:end))		=	2;
% Lat(idx(end-3:end))			=	Lat(idx(end-3:end))/2;

% idx						=	find(Resp == 4);
% Resp(idx(end-1:end))=3;
DATA					=	[Trial Rate Resp Lat Depth];
rel						=	remind == 0;
DATA					=	DATA(rel,:);

function Data = PlotFunctions(DATA,ID)
gel				=	DATA(:,1) == 0;
Go				=	DATA(gel,:);
Rates			=	unique(Go(:,2));
Depths			=	unique(Go(:,end));
sel				=	Depths > 0;
Depths			=	Depths(sel);

NDepths			=	length(Depths);
dp				=	nan(NDepths,1);
pHits			=	nan(NDepths,1);
Ngo				=	nan(NDepths,1);
N				=	nan(NDepths,1);
%---For Nogo stimuli---%
nel				=	DATA(:,1) == 1;
Nogo			=	DATA(nel,:);
fel				=	Nogo(:,3) == 4;
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
pFA				=	repmat(pfa,NDepths,1);

Lat				=	cell(NDepths,1);
%---For Go stimuli---%
for i=1:NDepths
	depth		=	Depths(i);
	nel			=	DATA(:,end) == depth;
	N(i,1)		=	sum(nel);
	sel			=	Go(:,end) == depth;
	Ngo(i,1)	=	sum(sel);
	data		=	Go(sel,:);
	hel			=	data(:,3) == 1;
% 	phits		=	sum(hel)/(length(hel)+0.50);
	phits		=	sum(hel)/length(hel);
	Lat(i,1)	=	{data(hel,end-1)};
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
pfa				=	dround(pfa);
zel				=	dp < 0;
dp(zel)			=	0;
subplot(2,4,6)
boxplotlatency(Lat,Depths)

% psychometricfunction(Rates,pHits,'ko-','Hit Rate',Rates,pfa,Ngo,ID)

% data			=	[Depths Ngo.*pHits N];
% options				=	struct;   % initialize as an empty struct
% options.sigmoidName	=	'logistic';
% options.sigmoidName	=	'logn';
% options.expType		=	'YesNo';
% result					=	psignifit(data,options);

subplot(2,4,7)
psychometricfunction(Depths,dp,'ko','dprime',Depths,pfa,Ngo,ID)
%---psignifit---%
[x,fitHits]		=	getpsignfit(Depths,Ngo,pHits,N,Nnogo,pfa);
fa				=	repmat(pfa,length(fitHits),1);
dpFit			=	calculatedprime2(fitHits,fa,x);
xel				=	dpFit >=1;
xthresh			=	x(xel);
threshold		=	nanmin(xthresh);
Data.dpFit		=	[x' dpFit];
Data.threshold	=	threshold;
plot(x,dpFit,'k-','LineWidth',2)
title([num2str(Rates) ' Hz'])

[x2,fitHits2]		=	getpsignfit2(Depths,Ngo,pHits,N,Nnogo,pfa);
dpFit2				=	calculatedprime2(fitHits2,fa,x2);
plot(x2,dpFit2,'r--','LineWidth',2)
Data.dpFit2		=	[x2' dpFit2];


% % % Qpre			=	fit_logistic(Depths,dp);
% % % plot(Depths,Qpre,'k:','LineWidth',2)
text(0.10,2.75,['thres = ' num2str(dround(threshold)) '; dB = ' num2str(dround(mag2db(threshold)))]...
	,'FontSize',16,'FontName','Arial','FontWeight','Bold')

Data.Rates		=	Rates;
Data.dp			=	dp;
Data.FAtrial	=	FAtrial;
Data.Lat		=	Lat;
Data.Depths		=	Depths;

subplot(2,4,8)
xFA				=	1:1:length(FAtrial);
xFA				=	xFA/max(xFA);
plot(xFA,FAtrial,'k-','LineWidth',2)
hold on
set(gca,'FontSize',20)
set(gca,'XTick',0:0.25:1,'XTickLabel',0:0.25:1);
% xlabel('Trial # / # Trials')
xlabel('Prop. of Trials')
xlim([0 1])
ylabel('FA Rate')
ylim([-0.005 1.005])
set(gca,'YTick',0:0.25:1,'YTickLabel',0:0.25:1);
axis square

% subplot(1,3,3)
% bar(1,pfa)
% set(gca,'FontSize',20)
% title(ID)
% set(gca,'YTick',0:0.25:1,'YTickLabel',0:0.25:1);
% ylim([0 1])
% xlabel('False Alarm')
% ylabel('proportion')
% axis square;
% set(gca,'XTick',1,'XTickLabel',[])

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

function dprime = calculatedprime(pHit,pFA)
zHit	=	sqrt(2)*erfinv(2*pHit-1);
zFA		=	sqrt(2)*erfinv(2*pFA-1);
% zHit	=	norminv(pHit,0,1);
% zFA		=	norminv(pFA,0,1);
%-- Calculate d-prime
dprime = zHit - zFA ;

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
% sel		=	dprime < 0;
% dprime(sel)	=	0;

function FAtrial = getFAacrosstrial(fel)
N			=	length(fel);
FAtrial		=	nan(N,1);
for i=1:N
	fa		=	fel(1:i);
	pfa		=	sum(fa)/length(fa);
	FAtrial(i,1)	=	pfa;
end

%---Plotting Functions---%
function boxplotlatency(Lat,Rates)
N				=	length(Rates);
avg				=	nan(N,1);
for i=1:N
	dat			=	Lat{i};
% 	x			=	Rates(i);
	avg(i,1)	=	nanmean(dat);
	plotbox2(i,dat)
	xx			=	repmat(i,length(dat),1);
	if( i == 1 )
		d		=	dat;
		X		=	xx;
	else
		d		=	[d;dat];
		X		=	[X;xx];
	end
end
[yfit,stats]	=	fitline(X,d);
set(gca,'FontSize',20)
h(1)=plot(1:1:N,avg,'k-','LineWidth',2);
hold on
h(2)=plot(X,yfit,'r-','Color',[0.50 0.50 0.50],'LineWidth',2);
set(gca,'XTick',1:1:N,'XTickLabel',Rates);
xlabel('AM Depth (%)')
% ylabel('Response Latency for Hits (ms)')
ylim([0 3000])
axis square;
xlim([0 N+1])
leg=legend(h,'Mean',['LinearFit (slope: ' num2str(dround(stats.Coef(1))) ')'],'Location','SouthWest');
legend('boxoff')
LEG = findobj(leg,'type','text');
set(LEG,'FontSize',14)

function psychometricfunction(X,Y,mark,yLabel,AMrate,FA,NumGo,ID)
% dB		=	mag2db(X);
XX			=	[0.053 0.25 0.50 0.71 1];
% dB			=	round(mag2db(XX));
dB			=	[-24 -12 -6 -3 0];
% plot(X,Y,'k-','LineWidth',1)
hold on
plot(X,Y,mark,'MarkerSize',12,'MarkerFaceColor','k','LineWidth',2)
if( strcmp(yLabel,'Hit Rate') )
	maxy	=	1.05;
	ylim([0 maxy])
	set(gca,'YTick',0:0.50:1,'YTickLabel',0:0.50:1);
	text(0.25,2.5,['FA = ' num2str(FA)],'FontSize',16,'FontName','Arial','FontWeight','Bold')
% 	addNumGos(NumGo,AMrate)
else
	maxy	=	3.1;
	ylim([0 maxy])
% 	XX		=	[0 X' 1.10];
	thres	=	ones(1,length(XX));
	plot(XX,thres,'k--','Color',[0.50 0.50 0.50])
	set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
	text(X(1),2.5,['FA = ' num2str(FA)],'FontSize',16,'FontName','Arial','FontWeight','Bold')
end
set(gca,'FontSize',20)
% title(ID)
% set(gca,'XTick',[0;AMrate],'XTickLabel',[0;AMrate]);
set(gca,'XTick',XX,'XTickLabel',dB)
% set(gca,'XScale','log')
xlabel('AM depth (dB re: 100%)')
ylabel(yLabel)
axis square;
xlim([0 1.05])
ylim([-0.10 3.1])

% [yfit,stats]	=	fitsigmoid(X,Y);
% hold on
% plot(X,yfit,'r-','LineWidth',2)
% % % set(gca,'XScale','log')


% D		=	[x y.*NumGo NumGo];
% Results	=	psignifit(D);
% plotpsignifit(Results)

function addNumGos(NumGo,AMrate)
N			=	length(AMrate);
% X			=	[3.75 7 28 110 240 400];
X			=	[3.75 7 28 110 240 350 500 1000];
text(2.1,0.10,'N = ','FontSize',12,'FontName','Arial')
for i=1:N
	x		=	X(i);
	num		=	NumGo(i);
	text(x,0.10,num2str(num),'FontSize',12,'FontName','Arial')
end

function plotpsignifit(result)
if result.options.logspace
    xlength		=	log(max(result.data(:,1)))-log(min(result.data(:,1)));
    x			=	exp(linspace(log(min(result.data(:,1))),log(max(result.data(:,1))),1000));
    xLow		=	exp(linspace(log(min(result.data(:,1)))-plotOptions.extrapolLength*xlength,log(min(result.data(:,1))),100));
    xHigh		=	exp(linspace(log(max(result.data(:,1))),log(max(result.data(:,1)))+plotOptions.extrapolLength*xlength,100));
else
    xlength		=	max(result.data(:,1))-min(result.data(:,1));
    x			=	linspace(min(result.data(:,1)),max(result.data(:,1)),1000);
    xLow		=	linspace(min(result.data(:,1))-plotOptions.extrapolLength*xlength,min(result.data(:,1)),100);
    xHigh		=	linspace(max(result.data(:,1)),max(result.data(:,1))+plotOptions.extrapolLength*xlength,100);
end
fitValuesLow    =	(1-result.Fit(3)-result.Fit(4))*arrayfun(@(x) result.options.sigmoidHandle(x,result.Fit(1),result.Fit(2)),xLow)+result.Fit(4);
fitValuesHigh   =	(1-result.Fit(3)-result.Fit(4))*arrayfun(@(x) result.options.sigmoidHandle(x,result.Fit(1),result.Fit(2)),xHigh)+result.Fit(4);

fitValues = (1-result.Fit(3)-result.Fit(4))*arrayfun(@(x) result.options.sigmoidHandle(x,result.Fit(1),result.Fit(2)),x)+result.Fit(4);
plot(x,     fitValues,          'Color', plotOptions.lineColor,'LineWidth',plotOptions.lineWidth)
plot(xLow,  fitValuesLow,'--',  'Color', plotOptions.lineColor,'LineWidth',plotOptions.lineWidth)
plot(xHigh, fitValuesHigh,'--', 'Color', plotOptions.lineColor,'LineWidth',plotOptions.lineWidth)

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
% pHits(1)	=	0;
% pHits(2)	=	pHits(2)/1.2;
% pHits	=	[0;0.25;0.60;0.95;0.95];
D		=	[X (Ngo.*pHits) N];
D		=	[0 0 Nnogo;D];
options.sigmoidName    = 'norm';
% options.expType        = 'nAFC';
% options.expN           = 1/pFA;
% options.sigmoidName    = 'logn';
% options.sigmoidName    = 'weibull';
% options.expType        = '4AFC';
% options.sigmoidName    = 'weibull';
% options.expType = 'equalAsymptote';
Results	=	psignifit(D,options);
% Results	=	psignifit(D);
x       =	linspace(min(Results.data(:,1)),max(Results.data(:,1)),1000);
fitHits =	(1-Results.Fit(3)-Results.Fit(4))*arrayfun(@(x) Results.options.sigmoidHandle(x,Results.Fit(1),Results.Fit(2)),x)+Results.Fit(4);

function [x,fitHits] = getpsignfit2(X,Ngo,pHits,N,Nnogo,pFA)
% pHits(1)	=	0;
% pHits(2)	=	pHits(2)/1.2;
% pHits	=	[0;0.25;0.60;0.95;0.95];
D		=	[X (Ngo.*pHits) N];
% D		=	[0 0 Nnogo;D];
options.sigmoidName    = 'norm';
% options.expType        = 'nAFC';
% options.expN           = 1/pFA;
% options.sigmoidName    = 'logn';
% options.sigmoidName    = 'weibull';
% options.expType        = '4AFC';
% options.sigmoidName    = 'weibull';
% options.expType = 'equalAsymptote';
Results	=	psignifit(D,options);
% Results	=	psignifit(D);
x       =	linspace(min(Results.data(:,1)),max(Results.data(:,1)),1000);
fitHits =	(1-Results.Fit(3)-Results.Fit(4))*arrayfun(@(x) Results.options.sigmoidHandle(x,Results.Fit(1),Results.Fit(2)),x)+Results.Fit(4);
