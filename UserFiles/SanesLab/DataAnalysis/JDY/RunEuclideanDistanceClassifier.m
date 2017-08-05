function RunEuclideanDistanceClassifier
%-Stores Data-%. Created 07/21/2017 JDY-%
clear all
close all
clc

if( isunix )
	Path	=	'/Volumes/JUSTIN EXHD/DataStore/';
else
    Path    =   'E:\PROJECTS\DataStore\';
end
Gerbil		=   GetGerbilIDs(Path);

%---Run Analysis---%
N			=	size(Gerbil,1);
for a=1:N
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

for i=1:Nunits
	
	Dat			=	Data(i).D;
	ED(i)		=	RunClassifier(Dat);
	
end

%---Save Data to File---%
if( isunix )
	SavePath	=	['/Volumes/JUSTIN EXHD/DataStore/' num2str(Gerbil) '/ED/'];
else
	SavePath    =   ['E:\DataStore\' num2str(Gerbil) '\ED\'];
end
Fname			=	[SavePath 'ED-' File];

save( Fname ,'ED')
disp('Saved Data!')

function Class = RunClassifier(Data)
Rasters			=	Data.Rasters;
Trial			=	Data.SpikeTrial;
Time			=	500:100:1000;
Ntime			=	length(Time);

GOs				=	[Rasters(2:end) Trial(2:end)];
NOGO			=	[Rasters(1) Trial(1)];
Ngos			=	length(GOs);
Nogotrials		=	cell2mat(NOGO(:,2));
NogoSpktimes	=	cell2mat(NOGO(:,1));
depth			=	Data.AMDepth(2:end);
rate			=	Data.AMRate;
dp				=	nan(Ngos,Ntime);

for i=1:Ngos
	
	for j=1:Ntime
		
		Gos			=	GOs(i,:);
		Gotrials	=	cell2mat(Gos(:,2));
		GoSpktimes	=	cell2mat(Gos(:,1));
		tWin		=	[400 Time(j)];
		dp(i,j)		=	RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,tWin);
		
	end
	
% 	[xfit,yfit,threshold,MSE]	=	PlotDPrimes(depth,dp);
	
end
Class.dp		=	dp;
Class.xTime		=	Time;
Class.depth		=	depth;
Class.rate		=	rate;

function dp = RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,tWin)
Iterations		=	1000;

start			=	tWin(1);
stop			=	tWin(2);

mxgT			=	max(unique(Gotrials));
mxnT			=	max(unique(Nogotrials));

binw			=	10;

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
	Gtemp			=	nanmean(Gpsth);
	
	%---NOGO Template---%
	for ii=1:round(mxnT/2)
		Nidx		=	randi(mxnT);
		nel			=	Nogotrials == Nidx;
		Ntemplate	=	NogoSpktimes(nel);
		zel			=	Ntemplate > start & Ntemplate < stop;
		ntemp		=	Ntemplate(zel);
		Npsth(ii,:)	=	hist(ntemp,start:binw:stop);
	end
	Ntemp			=	nanmean(Npsth);
	
	mn			=	nan(mxgT,2);
	Nn			=	nan(mxgT,2);
	
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

		%---Compare with Templates---%
		gComp	=	pdist([Tpsth;Gtemp]);
		nComp	=	pdist([Tpsth;Ntemp]);
		GComp	=	gComp./(gComp+nComp);
		NComp	=	nComp./(gComp+nComp);
		Comp	=	[GComp NComp];
		mn(j,:)	=	Comp == nanmin(Comp);
	end
	
	Prob		=	nansum(mn)/length(mn);

	%---Don't grab NOGO template spike train---%
	unT			=	unique(Nogotrials);
	ttel		=	unT == Nidx;
	unTT		=	unT(~ttel);
    mxxnT       =   length(unTT);
	%---Compare NOGO Trials with Templates---%
	for j=1:mxxnT
		ssel	=	Nogotrials == unTT(j);
		Spks	=	NogoSpktimes(ssel);
		testSR	=	Spks > start & Spks < stop;
		Tpsth	=	hist(testSR,start:binw:stop);
		
		%---Compare with Templates---%
		gComp	=	pdist([Tpsth;Gtemp]);
		nComp	=	pdist([Tpsth;Ntemp]);
		GComp	=	gComp./(gComp+nComp);
		NComp	=	nComp./(gComp+nComp);
		Comp	=	[GComp NComp];
		Nn(j,:)	=	Comp == nanmin(Comp);
	end
	
	Prob2		=	nansum(Nn)/length(Nn);
	
	if( i == 1 )
		MN		=	Prob;
		NN		=	Prob2;
	else
		MN		=	[MN;Prob];
		NN		=	[NN;Prob2];
	end
end
sel			=	MN > 0.95;
MN(sel)		=	0.95;
ssel		=	MN < 0.05;
MN(ssel)	=	0.02;
sel			=	NN > 0.95;
NN(sel)		=	0.95;
ssel		=	NN < 0.05;
NN(ssel)	=	0.05;
p			=	nanmean(MN,1);
pp			=	nanmean(NN,1);
pHit		=	p(1);
pFA			=	pp(1);
dp			=	calculatedprime(pHit,pFA);
dp			=	abs(dp);

function dprime = calculatedprime(pHit,pFA)
zHit	=	sqrt(2)*erfinv(2*pHit-1);
zFA		=	sqrt(2)*erfinv(2*pFA-1);
% zHit	=	norminv(pHit,0,1);
% zFA		=	norminv(pFA,0,1);
%-- Calculate d-prime
dprime = zHit - zFA ;