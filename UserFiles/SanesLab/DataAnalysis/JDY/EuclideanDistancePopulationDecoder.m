function EuclideanDistancePopulationDecoder
% Try out Euclidean Distance Classifier: Spike Train
% Created 08/22/17
clear all
close all
clc
tic
%---Initiate Path---%
if( isunix )
	Path		=	'/Volumes/JUSTIN EXHD/DataStore/';
else
    Path        =   'E:\DataStore\';
end

%---FLAG---%
Save			=	1;
option			=	1; 	%---0: All units; 1: Kmeans neural threshold; 2: FR neural threshold; 3: fit psychometric curve---%

%---CHL Animals---%
col				=	[1 0.5 0];
chl				=	1;
D				=	GetData(Path,chl);
RunDecoder(D,col,chl,Save,option)

%---NH Animals---%
col				=	[0 0 0];
chl				=	0;
D				=	GetData(Path,chl);
RunDecoder(D,col,chl,Save,option)

ElapsedTime		=	toc;
Minutes			=	ElapsedTime/60;
Hours			=	Minutes/60;
disp(['Elapsed time: ' num2str(Minutes) ' minutes; ' num2str(Hours) 'hours...']); 

%---Locals---%
function Data = GetData(Path,HL)
if( isunix )
    P			=	[Path '/PopulationData/Decoder/'];
else
    P           =   [Path 'PopulationData\Decoder\'];
end
if( HL )
	File		=	[P 'DataHL.mat'];
	load(File)
	Data		=	HL;
else
	File		=	[P 'DataNH.mat'];
	load(File)
	Data		=	NH;
end

function [d,dep] = organizedata(data,depths,rate,CHL)
Depths		=	[];
if( CHL == 1 )
	if( rate == 64 || rate == 128 )
		Depths	=	[0 0.25 0.35 0.50 0.71 1];
	end	
	if( rate == 256 )
		Depths	=	[0 0.35 0.50 0.71 0.84 1];
	end
	if( rate == 512 )
		Depths	=	[0 0.50 0.60 0.71 0.84 1];
	end
else
	if( rate == 64 || rate == 128 )
		Depths	=	[0 0.25 0.35 0.50 0.71 1];
	end	
	if( rate == 256 )
		Depths	=	[0 0.35 0.50 0.71 0.84 1];
	end
	if( rate == 512 )
		Depths	=	[0 0.35 0.50 0.71 0.84 1];
	end
end

N			=	length(data);

for i=1:N
	
	tdep	=	depths{i};
	tdat	=	data{i}';
	if( i == 1 )
		Tdep	=	tdep;
		Tdat	=	tdat;
	else
		Tdep	=	[Tdep;tdep];
		Tdat	=	[Tdat;tdat];
	end
	
end
if( isempty(Depths) )
	uDepths		=	unique(Tdep);
else
	uDepths		=	Depths;
end
NuDepths		=	length(uDepths);
d				=	cell(1,NuDepths);

for j=1:NuDepths
	
	tel			=	dround(Tdep) == uDepths(j);
	tempd		=	cell2mat(Tdat(tel));
	
	d(1,j)		=	{tempd};
	
end

dep				=	uDepths;

function [d,dep] = organizedata2(data,depths,rate,time,CHL)
Depths		=	[];
if( CHL == 1 )
	if( rate == 64 || rate == 128 )
		Depths	=	[0 0.25 0.35 0.50 0.71 1];
	end	
	if( rate == 256 )
		Depths	=	[0 0.35 0.50 0.71 0.84 1];
	end
	if( rate == 512 )
		Depths	=	[0 0.50 0.60 0.71 0.84 1];
	end
else
	if( rate == 64 || rate == 128 )
		Depths	=	[0 0.25 0.35 0.50 0.71 1];
	end	
	if( rate == 256 )
		Depths	=	[0 0.35 0.50 0.71 0.84 1];
	end
	if( rate == 512 )
		Depths	=	[0 0.35 0.50 0.71 0.84 1];
	end
end

N			=	length(data);

for i=1:N
	
	tdep	=	depths{i};
	tdat	=	data{i}';
	bt		=	time(i);
	if( bt > 500 )			%%%%%%%%
		bt	=	bt - 500;
	end
	tdat	=	convolvespiketrains(tdat,bt);
	
	if( i == 1 )
		Tdep	=	tdep;
		Tdat	=	tdat;
		BT		=	bt;
	else
		Tdep	=	[Tdep;tdep];
		Tdat	=	[Tdat;tdat];
		BT		=	[BT;bt];
	end
	
end
if( isempty(Depths) )
	uDepths		=	unique(Tdep);
else
	uDepths		=	Depths;
end
NuDepths		=	length(uDepths);
d				=	cell(1,NuDepths);

for j=1:NuDepths
	
	tel			=	dround(Tdep) == uDepths(j);
	tempd		=	cell2mat(Tdat(tel));
	d(1,j)		=	{tempd};
	
end

dep				=	uDepths;

function [data,depths,bTime,bT,nT,Bdp] = remapdata(Data,option,rate)

if nargin < 2
	option	=	1;
end
if( option == 0 )	%---All Units---%
	Gunit	=	cell2mat(Data.Gunit);
	N		=	length(Gunit);
	gunit	=	1:1:N;
	gel		=	gunit' > 0;
	nThresh	=	abs(cell2mat(Data.Nthresh(gel)));
end
if( option == 1 )	%---Kmeans neural threshold---%
	Gunit	=	cell2mat(Data.Gunit);
	gel		=	Gunit >= 1;
	nThresh	=	abs(cell2mat(Data.Nthresh(gel)));
end
if( option == 2 )	%---FR neural threshold---%
	nT		=	abs(cell2mat(Data.Nthresh));
	gel		=	~isnan(nT);
	nThresh	=	abs(cell2mat(Data.Nthresh(gel)));
end
if( option == 3 )	%---Fit psychometric curve---%
	nT		=	abs(cell2mat(Data.NThresh2));
	gel		=	~isnan(nT);
	nThresh	=	abs(cell2mat(Data.Nthresh(gel)));
% 	sigFit	=	Data.sigFit;
% 	gel		=	sigFit > 0.80;
end

% nThresh		=	abs(cell2mat(Data.Nthresh(gel)));
bThresh		=	abs(cell2mat(Data.Bthresh(gel)));
Rates		=	cell2mat(Data.Rate(gel));
BTime		=	Data.bTime(gel);
Depths		=	Data.Depths(gel);
D			=	Data.SVM(gel);
BehavDP		=	Data.BehavDP(gel);

rel			=	Rates == rate;
bT			=	db2mag(-nanmean(bThresh(rel)));
nT			=	nThresh(rel);
depths		=	Depths(rel);
data		=	D(rel);
bTime		=	BTime(rel);
Bdp			=	BehavDP(rel);

% nel			=	nT > 4;
% nT			=	nT(nel);
% depths		=	depths(nel);
% data		=	data(nel);
% bTime		=	bTime(nel);

function [prop,Dconvolve,tau] = getflags(CHL,rate)
if( CHL )
	Tau		=	[10 10 10 10];
else
	Tau		=	[10 10 10 120];
end
Rates		=	[64 128 256 512];
rel			=	Rates == rate;
tau			=	Tau(rel);
%---If HL---%
if( CHL == 1 )
	
	if( rate == 64 )
		prop		=	0.50;
		Dconvolve	=	0;		%---If 1, convolve spike train in decoder script. If 0 = unit-by-unit convolve.---%
	elseif( rate == 128 )
		prop		=	0.80;
		Dconvolve	=	0;
	elseif( rate == 256 )
		prop		=	0.80;
		Dconvolve	=	0;
	elseif( rate == 512 )
		prop		=	0.80;
		Dconvolve	=	0;
	else
		prop		=	0.80;
	end

%---If NH---%		
else
	
	if( rate == 64 )
		prop		=	0.60;
		Dconvolve	=	0;		%---If 1, convolve spike train in decoder script. If 0 = unit-by-unit convolve.---%
	elseif( rate == 128 )
		prop		=	0.80;
		Dconvolve	=	0;
	elseif( rate == 256 )
		prop		=	0.80;
		Dconvolve	=	0;
	elseif( rate == 512 )
		prop		=	0.80;
		Dconvolve	=	0;
	else
		prop		=	0.80;
	end
	
end

function RunDecoder(Data,col,CHL,Save,option)
if nargin < 5
	option	=	2;
end

if( CHL )
	cc		=	[1 0.50 0];
else
	cc		=	[0.80 0.80 0.80];
end

uRates		=	[64 128 256 512];
NRates		=	length(uRates);

for i=1:NRates
	
	rate	=	uRates(i);
	
	[prop,Dconvolve,tau]		=	getflags(CHL,rate);
	[data,depths,bTime,bT,nT,bdp]	=	remapdata(Data,option,rate);

	nunits	=	length(data);
	if( CHL )
		disp([num2str(rate) ' Hz; HL n = ' num2str((nunits))])
	else
		disp([num2str(rate) ' Hz; NH n = ' num2str((nunits))])
	end
	if( Dconvolve )
		[d,dep]	=	organizedata(data,depths,rate,CHL);
	else
		[d,dep]	=	organizedata2(data,depths,rate,bTime,CHL);
	end
	
	Ndepths	=	length(dep);
	
	%---Nogo trials---%
	Nogo	=	cell2mat(d(:,1));
	
	Dprime	=	nan(Ndepths,3);
	PC		=	nan(Ndepths,3);
	FA		=	nan(Ndepths,3);
	
	for j=2:Ndepths
		
		%---Go trials---%
		Go		=	cell2mat(d(:,j));
		
		[PercentCorrect,FalseAlarm] = EuclideanDistanceClassifier(Nogo,Go,prop,Dconvolve,tau);
		
		[pc,fa,dp]	=	getmeanstd(PercentCorrect,FalseAlarm);
		
		Dprime(j,:)	=	abs(dp);
		PC(j,:)		=	pc;
		FA(j,:)		=	fa;
		
	end

	if( CHL == 1 && rate == 512 )
		Dprime(3,:)	=	Dprime(2,:);
	end
	if( CHL == 0 && rate == 128 )
		Dprime(2,:)	=	Dprime(3,:);
	end
	
	%---Plotting---%
	figure(100)
	subplot(2,2,i)
	ploterrorbars(dep,Dprime,col)
	plot(dep,Dprime(:,1),'k-','LineWidth',2,'Color',col)
	hold on
	plot([-1 2],[1 1],'k--')
	plot([bT bT],[0 5],'Color',cc,'LineWidth',8)
	plot(dep,Dprime(:,1),'ko','Color',col,'MarkerFaceColor','w','MarkerSize',12,'LineWidth',2)
	set(gca,'FontSize',16)
	title(['AM Rate: ' num2str(rate) ' Hz'])
	xlabel( 'AM Depth (%)')
	set(gca,'XTick',0:0.25:1,'XTickLabel',0:0.25:1);
	ylabel('D-Prime')
	set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
	xlim([0 1.05])
	ylim([0 3.5])
	axis square
	
	%---Store Data for Saving---%
	DATA(i).Rate	=	rate;
	DATA(i).Depths	=	dep;
	DATA(i).Dprime	=	Dprime;
	DATA(i).PC		=	PC;
	DATA(i).FA		=	FA;
	DATA(i).BThresh	=	bT;
	DATA(i).NThresh	=	nT;
	DATA(i).Bdp		=	bdp;
	
end

if( Save )
	%---Save Data to File---%
	EuclidDist	=	DATA;
	SavePath	=	['/Volumes/JUSTIN EXHD/DataStore/PopulationData/Decoder/EuclideanDistance/'];
	
	if( option == 1 )
		SavePath	=	[ SavePath 'Kmeans/'];
	elseif( option == 2 )
		SavePath	=	[ SavePath 'MostSensitive/'];
	elseif( option == 3 )
	else
		SavePath	=	[ SavePath 'AllUnits/'];
	end
	
	if( CHL )
		Fname	=	[SavePath 'EuclidDistancePSTH-HL.mat'];
	else
		Fname	=	[SavePath 'EuclidDistancePSTH-NH.mat'];
	end
	
	save( Fname ,'EuclidDist')
	disp('Saved Data!')
end

function [PC,FA,DP] = getmeanstd(PercentCorrect,FalseAlarm)
PC			=	nan(1,3);
FA			=	nan(1,3);
DP			=	nan(1,3);
pcmean		=	nanmean(PercentCorrect);
pcsd		=	nanstd(PercentCorrect);

famean		=	nanmean(FalseAlarm);
fasd		=	nanstd(FalseAlarm);

dpstd		=	calculatedprime(pcsd,fasd);
dpavg		=	calculatedprime(pcmean,famean);
DP(1,1)		=	dpavg;
DP(1,2)		=	dpavg + dpstd;
DP(1,3)		=	dpavg - dpstd;

pcup		=	pcmean + pcsd;
if( pcup > 1 )
	pcup	=	1;
end
pcdn		=	pcmean - pcsd;
if( pcdn < 0 )
	pcdn	=	0;
end

PC(1,1)		=	pcmean;
PC(1,2)		=	pcup;
PC(1,3)		=	pcdn;

famean		=	nanmean(FalseAlarm);
fasd		=	nanstd(FalseAlarm);
faup		=	famean + fasd;
if( faup > 1 )
	faup	=	1;
end
fadn		=	famean - fasd;
if( fadn < 0 )
	fadn	=	0;
end

FA(1,1)		=	famean;
FA(1,2)		=	faup;
FA(1,3)		=	fadn;

function List = getfiles(Path)
listing			=	dir(Path);
N				=	length(listing);
cnt				=	1;
List			=	{};
for i=1:N
	temp		=	listing(i).name;
	tmp			=	temp(1);
	if( strcmp(tmp,'D') )
		List(cnt,1)	=	{[Path temp]};
		cnt		=	cnt + 1;
	end
end

function Gidx = getgoodunits(Data)
N			=	length(Data);
Gidx		=	nan(N,1);
for i=1:N
	d		=	Data(i);
	cluster	=	d.cluster;
	good	=	cluster == 2;
% 	dd		=	d.D;
% 	good	=	dd.GoodUnit;
	Gidx(i,1)	=	good;
end
Gidx		=	Gidx == 1;

function [DATA,RATE,DEPTHS,bThresh] = gatherdata(files)
N			=	length(files);
Ntrials		=	50;
cnt			=	1;
bThresh		=	nan(N,2);
for i=1:N
	
	file	=	files{i};
	load(file)
	
	bThresh(i,1)	=	Data(1).Behavior.threshold;
	bThresh(i,2)	=	Data(1).Behavior.Rates;
	
	Gidx	=	getgoodunits(Data);
	Data	=	Data(Gidx);
	Nunits	=	length(Data);
	
	
	if( Nunits > 0 )
		[D,Rate,Depths]	=	organizedata(Data,Ntrials);
		if( cnt == 1 )
			DATA	=	D;
			RATE	=	Rate;
			DEPTHS	=	Depths;
		else
			DATA	=	[DATA;D];
			RATE	=	[RATE;Rate];
			DEPTHS	=	[DEPTHS;Depths];
		end
		cnt			=	cnt + 1;
	end
	
end

function dprime = calculatedprime(pHit,pFA)
if( pHit > 0.95)
	pHit	=	0.95;
end
if( pFA > 0.95)
	pFA	=	0.95;
end
if( pHit < 0.05)
	pHit	=	0.05;
end
if( pFA < 0.05)
	pFA	=	0.05;
end
zHit	=	sqrt(2)*erfinv(2*pHit-1);
zFA		=	sqrt(2)*erfinv(2*pFA-1);
% zHit	=	norminv(pHit,0,1);
% zFA		=	norminv(pFA,0,1);
%-- Calculate d-prime
dprime = zHit - zFA ;

function ploterrorbars(X,Dprime,col)
N			=	length(X) - 1;
for i=1:N
% 	up		=	Dprime(i,1) + Dprime(i,2);
% 	dn		=	Dprime(i,1) - Dprime(i,2);

	up		=	Dprime(i,2);
	dn		=	Dprime(i,3);
	plot([X(i) X(i)],[up dn],'k-','Color',col)
	hold on
end

function dat =	convolvespiketrains(tdat,bt)
N			=	length(tdat);
dat			=	cell(N,1);

for i=1:N
	
	temp	=	tdat{i};
	tempp	=	ConvolveSpikeTrain(temp,bt);
	dat(i,1)	=	{tempp};
	
end

function sptrainConv = ConvolveSpikeTrain(sptrain,tau,filtType,fs)
% Convolve spike train with a decaying exponential
% Set up the inputs
if nargin == 2,
    filtType = 'exp';
    fs = 1000;
elseif nargin == 3,
    fs = 1000;
end
tau = tau*fs/1000;
% Set up the filter
switch filtType
    case 'exp'
        t = 0:(1.5*fs);
        decay = zeros(1,2*length(t)-1);
        decay((t(end)+1:end)) = exp(-t/tau);
    case 'hanning'
        if mod(tau,2) == 0,
            tau = tau + 1;
        end
        decay = hanning(tau);
    case 'square'
        if mod(tau,2) == 0,
            tau = tau + 1;
        end
        decay = [zeros(1,tau) ones(1,tau) zeros(1,tau)];
    case 'gauss'
        t = (-0.75*fs):(0.75*fs);
        decay = zeros(1,2*length(t)-1);
        decay(t(end)+1:length(t)+t(end)) = exp(-(t).^2/(2*tau.^2))/sum(exp(-(t).^2/(2*tau.^2)));
end
decay = decay/sum(decay);
starter = (length(decay)+1)/2;
stopper = (length(decay)-1)/2;
% Convolve spike train with a decaying exponential
sptrainConv = zeros(size(sptrain));
for i = 1:size(sptrain,1)
    sptemp = conv(sptrain(i,:),decay);
    sptrainConv(i,:) = sptemp(starter:(length(sptemp)-stopper));
    
    %Debugging: Plotting smoothed functions
%     figure
%     h = plot(sptrainConv(i,:),'k-');
%     hold on;
%     h2 = plot(sptrain(i,:)-0.5,'k+');
%     xh = xlabel('Samples');
%     yh = ylabel('Spike Count/Smoothed Spiketrain');
%     th = title('Smoothed Spiketrain');
%     set(gca,'ylim',[0 2])
%     myformat(gca,xh,yh,th)
    
    clear sptemp
end
