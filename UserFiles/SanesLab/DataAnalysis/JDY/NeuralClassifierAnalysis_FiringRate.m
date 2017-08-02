function NeuralClassifierAnalysis_FiringRate
%-Stores Data for Classifier Analysis-%
%Metric: Firing Rate
%-Created 07/22/2017 JDY-%
clear all
close all force
clc
tic
if( isunix )
	Path	=	'/Volumes/JUSTIN EXHD/DataStore/';
else
%     Path    =   'E:\DataStore\';
    Path    =   'C:\Users\sanesadmin\Desktop\JDYDataStore\';
end
Gerbil		=   GetGerbilIDs(Path);

%---Run Analysis---%
N			=	size(Gerbil,1);
for a=3:4%N
	gerbil	=	Gerbil(a,:);
	files	=	getfiles(Path,gerbil);
	Nfiles	=	length(files);
	%---Waitbar---%
	h=waitbar(0,'Please wait...');
	titleHandle = get(findobj(h,'Type','axes'),'Title');
	set(titleHandle,'FontSize',18)
	for b=1:Nfiles
		%---update waitbar---%
		waitbar(b/Nfiles,h,['Gerbil:  ' gerbil  ' (' num2str(a) '/' num2str(N)...
			';  File: ' num2str(b) '/' num2str(Nfiles) ')'])
		file	=	files{b};
		RunAnalysis(Path,gerbil,file)
	end
end
clc
disp('Done!')
stopclock = toc;
clockMin = stopclock/60;
clockHr = clockMin/60;
disp(['Time Elapsed: ' num2str(clockMin) ' minutes; ' num2str(clockHr) ' hours...'])
close all force

%---Local---%
function Gerbil = GetGerbilIDs(Path)
listing			=	dir(Path);
N				=	length(listing);
cnt				=	1;
for i=1:N
	temp		=	listing(i).name;
	tmp			=	temp(1);
	if( strcmp(tmp,'2') )
		id		=	temp;
		Gerbil(cnt,:)	=	id;
		cnt		=	cnt + 1;
	end
end

function Files = getfiles(Path,gerbil)
Pname			=	[Path gerbil '/'];
listing			=	dir(Pname);
N				=	length(listing);
cnt				=	1;
Files			=	{};
for i=1:N
	temp		=	listing(i).name;
	tmp			=	temp(1);
	if( strcmp(tmp,'D') )
		file	=	temp;
		Files(cnt,1)	=	{file};
		cnt		=	cnt + 1;
	end
end

function RunAnalysis(Path,Gerbil,File)
Fpath			=	[Path Gerbil];
Dfile			=	[Fpath '/' File];

load(Dfile)

Nunits			=	length(Data);
Behavior		=	Data.Behavior;

for i=1:Nunits
	Dat			=	Data(i).D;
	ClassFR(i)	=	RunClassifier(Dat,Behavior);
end

%---Save Data to File---%
if( isunix )
	SavePath	=	['/Volumes/JUSTIN EXHD/DataStore/' num2str(Gerbil) '/Classifier/FR/'];
else
% 	SavePath    =   ['E:\DataStore\' num2str(Gerbil) '\Classifier\FR\'];
    dPath       =   'C:\Users\sanesadmin\Desktop\JDYDataStore\';
    SavePath    =   [dPath num2str(Gerbil) '\Classifier\FR\'];
end
Fname			=	[SavePath 'ClassFR-' File];

save( Fname ,'ClassFR')
disp('Saved Data!')

function Class = RunClassifier(Data,Behavior)
if( isfield(Data.Local,'AMRate') )
	Time	=	450:50:1400;
	start	=	400;
else
	Time	=	50:50:1000;
	start	=	0;
end

Rasters			=	Data.Rasters;
Trial			=	Data.SpikeTrial;
Ntime			=	length(Time);

GOs				=	[Rasters(2:end) Trial(2:end)];
NOGO			=	[Rasters(1) Trial(1)];
Ngos			=	length(GOs);
Nogotrials		=	cell2mat(NOGO(:,2));
NogoSpktimes	=	cell2mat(NOGO(:,1));
depth			=	Data.AMDepth(2:end);
rate			=	Data.AMRate;
dp				=	nan(Ngos,Ntime);

for i=Ngos
	for j=1:Ntime
		Gos			=	GOs(i,:);
		Gotrials	=	cell2mat(Gos(:,2));
		GoSpktimes	=	cell2mat(Gos(:,1));
		tWin		=	[start Time(j)];
		dp(i,j)		=	RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,tWin);
	end
end

mx				=	nanmax(dp(end,:));
sel				=	dp(end,:) == mx;
time			=	nanmin(Time(sel));
tWin2			=	[start time];
idx				=	find(Time(sel));
idx				=	idx(1);

for i=1:Ngos-1
	Gos			=	GOs(i,:);
	Gotrials	=	cell2mat(Gos(:,2));
	GoSpktimes	=	cell2mat(Gos(:,1));
	dp(i,idx)	=	RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,tWin2);
end

[xfit,yfit,threshold,MSE]	=	getthreshold(depth,dp(:,idx));

Class.dp		=	dp;
Class.xTime		=	Time;
Class.depth		=	depth;
Class.rate		=	rate;
Class.BestMS	=	time;
Class.BestDP	=	dp;
Class.threshold	=	threshold;
Class.MSE		=	MSE;
Class.xfit		=	xfit;
Class.yfit		=	yfit;
Class.Behavior	=	Behavior;

function dp = RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,tWin)
Iterations		=	1000;

start			=	tWin(1);
stop			=	tWin(2);

mxgT			=	max(unique(Gotrials));
mxnT			=	max(unique(Nogotrials));

binw			=	1;

for i=1:Iterations
	%---GO Template---%
	for ii=1:round(mxgT/2)
		Gidx		=	randi(mxgT);
		gel			=	Gotrials == Gidx;
		Gtemplate	=	GoSpktimes(gel);
		sel			=	Gtemplate > start & Gtemplate <= stop;
		gtemp		=	Gtemplate(sel);
		Gpsth(ii,:)	=	hist(gtemp,start:binw:stop);
	end
	GtempPSTH		=	nanmean(Gpsth);
	
	%---NOGO Template---%
	for ii=1:round(mxnT/2)
		Nidx		=	randi(mxnT);
		nel			=	Nogotrials == Nidx;
		Ntemplate	=	NogoSpktimes(nel);
		zel			=	Ntemplate > start & Ntemplate < stop;
		ntemp		=	Ntemplate(zel);
		Npsth(ii,:)	=	hist(ntemp,start:binw:stop);
	end
	NtempPSTH		=	nanmean(Npsth);
	
	FR			=	nan(mxgT,2);
% 	Nn			=	nan(mxgT,2);
	
	%---Don't grab GO template spike train---%
	ugT			=	unique(Gotrials);
	tel			=	ugT == Gidx;
	ugTT		=	ugT(~tel);
	mxxgT       =   length(ugTT);
	
	for j=1:mxxgT
		ssel	=	Gotrials == ugTT(j);
		Spks	=	GoSpktimes(ssel);
		testSR	=	Spks > start & Spks < stop;
		Ttemp	=	Spks(testSR);		
		Tpsth	=	hist(Ttemp,start:binw:stop);
		
		fr		=	FRClassifier(GtempPSTH,NtempPSTH,Tpsth);
		FR(j,:)	=	fr;
	end
	
	Prob		=	nansum(FR)/length(FR);

% 	%---Don't grab NOGO template spike train---%
% 	unT			=	unique(Nogotrials);
% 	ttel		=	unT == Nidx;
% 	unTT		=	unT(~ttel);
%     mxxnT       =   length(unTT);
% 	%---Compare NOGO Trials with Templates---%
% 	for j=1:mxxnT
% 		ssel	=	Nogotrials == unTT(j);
% 		Spks	=	NogoSpktimes(ssel);
% 		testSR	=	Spks > start & Spks < stop;
% 		Tpsth	=	hist(testSR,start:binw:stop);
% 		
% 		%---Compare with Templates---%
% 		gComp	=	pdist([Tpsth;Gtemp]);
% 		nComp	=	pdist([Tpsth;Ntemp]);
% 		GComp	=	gComp./(gComp+nComp);
% 		NComp	=	nComp./(gComp+nComp);
% 		Comp	=	[GComp NComp];
% 		Nn(j,:)	=	Comp == nanmin(Comp);
% 	end
% 	Prob2		=	nansum(Nn)/length(Nn);
	
	if( i == 1 )
		MN		=	Prob;
% 		NN		=	Prob2;
	else
		MN		=	[MN;Prob];
% 		NN		=	[NN;Prob2];
	end
end

sel			=	MN > 0.95;
MN(sel)		=	0.95;
ssel		=	MN < 0.05;
MN(ssel)	=	0.05;
% sel			=	NN > 0.95;
% NN(sel)		=	0.95;
% ssel		=	NN < 0.05;
% NN(ssel)	=	0.05;
p			=	nanmean(MN(:,1),1);
pp			=	nanmean(MN(:,2),1);
% pp			=	nanmean(NN,1);
pHit		=	p(1);
pFA			=	pp(1);
dp			=	calculatedprime(pHit,pFA);
dp			=	abs(dp);

function fr = FRClassifier(Gpsth,Npsth,Tpsth)
gSR		=	sum(Gpsth);
nSR		=	sum(Npsth);
tSR		=	sum(Tpsth);
Gcomp	=	abs(diff([gSR tSR]));
Ncomp	=	abs(diff([nSR tSR]));
Comp	=	[Gcomp Ncomp];
fr		=	Comp == nanmin(Comp);

function dprime = calculatedprime(pHit,pFA)
zHit	=	sqrt(2)*erfinv(2*pHit-1);
zFA		=	sqrt(2)*erfinv(2*pFA-1);
% zHit	=	norminv(pHit,0,1);
% zFA		=	norminv(pFA,0,1);
%-- Calculate d-prime
dprime = zHit - zFA ;

function [xfit,yfit,threshold,mse,idx] = getthreshold(x,y)
%Create a sigmoidal function:  f = y0 + a/(1 + exp(-(x - x0)/b))
%Parameters (p):
%p(1):  y0 = min
%p(2):   a = max - min
%p(3):   b = slope
%p(4):  x0 = x coordinate at inflection point
f = @(p,x) p(1) + p(2) ./ (1 + exp(-(x-p(3))/p(4)));
%Establish s vector of initial coefficients (beta0)
beta0 = [0 20 50 5];

%Set the maximum number of iterations to 1000
options = statset('MaxIter',1000,'Robust','on');

%Do the fitting
sel		=	isnan(y);
y(sel)	=	0;

zel		=	y == Inf;
y(zel)	=	3;
%---Get contiguious y values---%
if( length(y) > 3 )
	idx		=	diff(y(1:4)) > -0.75;
	idx		=	[idx(:,1);1;1];
	idx		=	idx == 1;

	X		=	x(idx);
	Y		=	y(idx);
	
if( length(X) < 4 )
	[p, r, ~, covb, mse] = nlinfit(x,y,f,beta0,options);
	X	=	x;
	Y	=	y;
else
	try
	[p, r, j, covb, mse] = nlinfit(X,Y,f,beta0,options);
	catch
		keyboard
	end
end

xfit = linspace(X(1),X(end),1000);
yfit = f(p,xfit);
yfit_corr = f(p,X);

%Get threshold
sel			=	yfit >= 1;
MD			=	db2mag(xfit(sel));
threshold	=	nanmin(MD);
threshold	=	mag2db(threshold);
if( isempty(threshold) )
	threshold	=	NaN;
end

else
	threshold	=	NaN;
	xfit		=	NaN;
	yfit		=	NaN;
	mse			=	NaN;
	idx			=	y > 0;
	idx			=	idx == 1;
end
