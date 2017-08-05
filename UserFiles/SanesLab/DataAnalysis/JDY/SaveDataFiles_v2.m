function SaveDataFiles_v2
clear all
close all force
clc
% Created 07 Apr 2017 JDY

%---FLAGS---%
CHL				=	0;
% Rates			=	[64 128 256];
Rates			=	512;
% Gerbil			=   ['236397';'243027'];

% Gerbil			=   '236397';
% Gerbil			=	'243027';
Gerbil			=	'247026';

% Gerbil			=	'239151';
% Gerbil			=   '240130';
% Gerbil			=	'243415';
Classifier		=	0;
SpikeDistance	=	0;	%Spike Distance Metric%

if( isunix )
	Path		=	'/Volumes/JUSTIN EXHD/PROJECTS/AM RATE/';
else
    Path        =   'E:\PROJECTS\AM RATE\';
end
%---Run Analysis---%
N				=	size(Gerbil,1);
NRates          =   length(Rates);
for aa=1:N
	gerbil		=	Gerbil(aa,:);
	for a=1:NRates
		RunAnalysis(Path,CHL,Rates(a),gerbil,Classifier,SpikeDistance)
	end
end
clc
disp('Done!')
close all force

%---Locals---%
function RunAnalysis(Path,CHL,Rate,Gerbil,Classifier,SpikeDistance)
%---Get Behavior Data Path---%
bPath			=	getBehaviorPath(Path,CHL,Gerbil,Rate);
%---Get Behavior Data Files & Dates for Ephys Data---%
[Files,Dates]	=	getfiles(bPath);
Nfiles			=	length(Files);
%---Get Ephys Data Path---%
[ePath,eData]	=	getEphysPathData(Path,Gerbil,Dates);
%---Waitbar---%
h=waitbar(0,'Please wait...');

for i=1:Nfiles

	%---update waitbar---%
	waitbar(i/Nfiles,h,['Rate: ' num2str(Rate) ' Hz (' num2str(i) '/' num2str(Nfiles) ')'])

    %---Get Behavior Data---%
    file		=	Files{i};
	
	date		=	Dates{i};
	disp(date)
	
    bData		=	getBehaviorData(file);
    eFile		=	[ePath eData{i}];
    Data		=	getEphysData(ePath,eFile,Classifier,SpikeDistance,CHL,bData);
    %---Save Data to File---%
    if( isunix )
        Path		=	['/Volumes/JUSTIN EXHD/DataStore/' num2str(Gerbil) '/'];
    else
        Path        =   ['E:\DataStore\' num2str(Gerbil) '\'];
    end
    idxx			=	strfind(eFile,'-');
    session			=	eFile(idxx(1)+1:idxx(1)+2);
    idxxx			=	strfind(eFile,'_');
    block			=	eFile(idxx(2)+1:idxxx(end)-1);
    Fname           =	[Path 'Data-' session '-' block '-'  num2str(num2str(Rate))];
    
    SavePath	=	Fname;
    save( SavePath ,'Data')
    disp('Saved Data!')
end

function bPath = getBehaviorPath(Path,CHL,Gerbil,Rate)
if( isunix )
    if( CHL )
        bPath		=	[Path 'Ephys Behavior/CHL/' num2str(Gerbil) '/Depth/Saved/' num2str(Rate) 'Hz/'];
    else
        bPath		=	[Path 'Ephys Behavior/' num2str(Gerbil) '/Depth/Saved/' num2str(Rate) 'Hz/'];
    end
else
    if( CHL )
        bPath		=	[Path 'Ephys Behavior\CHL\' num2str(Gerbil) '\Depth\Saved\' num2str(Rate) 'Hz\'];
    else
        bPath		=	[Path 'Ephys Behavior\' num2str(Gerbil) '\Depth\Saved\' num2str(Rate) 'Hz\'];
    end
end

function [ePath,eData] = getEphysPathData(Path,Gerbil,Dates)
N			=	length(Dates);
if( isunix )
    ePath		=	[Path 'Ephys/processed_data/' num2str(Gerbil) '/'];
else
    ePath		=	[Path 'Ephys\processed_data\' num2str(Gerbil) '\'];
end
eData		=	cell(N,1);
for i=1:N
	date		=	Dates{i};
	eFile		=	getephysfile(ePath,date);
	eData(i,1)	=	{eFile};
end

function eFile = getephysfile(Path,date)
listing			=	dir(Path);
N				=	length(listing);
eFile			=	[];
for i=1:N
	temp		=	listing(i).name;
	tmp			=	temp(1);
	if( strcmp(tmp,'2') )
		%---Check if Info file---%
		f		=	temp(end-7);
		if( strcmp(f,'I') )
			F	=	[Path temp];
			load(F)
			d	=	Info.date;
			dd	=	[d(end-1:end) '-' d(6:8) '-' d(1:4)];
			if( strcmp(date,dd) )
				idx		=	strfind(temp,'I');
                if( length(idx) > 1 )
                    idx =   idx(end);
                end
				eFile	=	[temp(1:idx-1) 'Spikes.mat'];
				continue
			end
		end
	end
end
if( isempty(eFile) )
	keyboard
end

function [List,Dates] = getfiles(Path)
listing			=	dir(Path);
N				=	length(listing);
cnt				=	1;
List			=	{};
for i=1:N
	temp		=	listing(i).name;
	tmp			=	temp(1);
	if( strcmp(tmp,'2') )
		id		=	temp;
		date	=	id(8:end-4);
		List(cnt,1)	=	{[Path temp]};
		Dates(cnt,1)	=	{date};
		cnt		=	cnt + 1;
	end
end

function bData = getBehaviorData(BFile)
load(BFile)
bData			=	Data;

function Data =	getEphysData(Path,File,Classifier,SpikeDistance,CHL,bData)
DataFile		=	File;
load(DataFile)
NChan			=	16;
Chans			=	1:1:NChan;
% NChan			=	1;
% Chans			=	1;
cnt				=	1;
cntt			=	1;

if( isunix )
    idx			=	strfind(Path,'/');
else
    idx			=	strfind(Path,'\');
end

Gerbil			=	Path(idx(end-1)+1:end-1);
idxx			=	strfind(File,'-');
session			=	File(idxx(1)+1:idxx(1)+2);
idxxx			=	strfind(File,'_');
Block			=	File(idxx(2)+1:idxxx(end)-1);

IDX				=	strfind(Path,Gerbil);
path			=	Path(1:IDX-1);

%-Set criteria for IF no initial unmodulated fringe-%
if( CHL )
	crit		=	strcmp(Gerbil,'243415') & str2double(Block) > 22 & str2double(Block) < 28;
else
	crit		=	strcmp(Gerbil,'247026') & str2double(Block) > 18 & str2double(Block) < 23;
end

for i=1:NChan
	channel			=	Chans(i);
	temp			=	Spikes.sorted(channel).labels;
	if( ~isempty(temp) )
		sel				=	temp(:,2) > 1 & temp(:,2) < 4;
		cluster			=	temp(sel,1);
		Utype			=	temp(sel,2);
		if( ~isempty(cluster) )
			for j=1:length(cluster)
				clus	=	[cluster(j) Utype(j)];
				% 				xel		=	clus(:,end) == 2;
				% 				NSU(cntt,1)	=	sum(xel);
				cntt	=	cntt + 1;
				%---Make Plots---%
				figure(1)
				%---Get Data metrics---%
				% 				D		=	SaveAMDepthData_v2(Path,Gerbil,session,Block,channel,clus);
				% 				D		=	SaveAMDepthDataEphys(Path,Gerbil,session,Block,channel,clus);
				
				% 				D		=	SaveAMDepthDataEphys_v3_LocalStrategy(path,Gerbil,session,Block,channel,clus,bData);
				
				% 				D		=	SaveAMDepthDataEphys_v4(path,Gerbil,session,Block,channel,clus,bData);
				%
				% 				D		=	SaveAMDepthDataEphys_vNoFringe_v2(path,Gerbil,session,Block,channel,clus,bData); 
				
				if( crit )
					D			=	SaveAMDepthDataEphys_vNoFringe(path,Gerbil,session,Block,channel,clus,bData);
					D.Local		=	NaN;
				else
					D			=	SaveAMDepthDataEphys_v2(path,Gerbil,session,Block,channel,clus,bData);
					D.Local		=	SaveAMDepthDataEphys_v4_Local(path,Gerbil,session,Block,channel,clus,bData);
				end
				
				%---Plot Behavior Data---%
				subplot(2,3,3)
				plotPsychDPrime(bData)
				
				%---Run Classifier---%
				if( Classifier )
					Class					=	RunClassifier(D);
					Data(cnt).classifier	=	Class;
				end
                
				%---Euclidean Distance Metrics---%
				ED							=	EuclideanDistanceMetric(D,crit);
				Data(cnt).ED				=	ED;
				
				%---Spike Distance Metric---%
				if( SpikeDistance )
					SD						=	CalculateSpikeDistance(D,crit);
					Data(cnt).SpkDis		=	SD;
% 					sdm						=	CalculateSpikeDistance_v2(D);
% 					sdmclass				=	CalculateSpikeDistanceClassifier_v2(D,crit);
% 					Data(cnt).SpkDisClass	=	sdmclass;
% 					tel						=	SD.xTime == D.Time;
% 					subplot(2,3,6)
% 					plot(mag2db(D.AMDepth(2:end)),SD.dprimes(2:end,tel),'bo-','MarkerFaceColor','b','MarkerSize',12)
				end

				%---Store Values---%
				Data(cnt).channel		=	channel;
				Data(cnt).cluster		=	clus(1,2);
				Data(cnt).D				=	D;
				Data(cnt).Behavior		=	bData;
				
				%---Save Figure---%
				if( isunix )
					Pfig	=	'/Volumes/JUSTIN EXHD/Figs/';
                else
                    Pfig    =   'E:\Figs\';
				end
				Pname		=	[Pfig num2str(Gerbil) '/'];
				Fname		=	[Pname session '-' Block '-'  num2str(num2str(bData.Rates)) '-Ch' num2str(channel) '-' num2str(cnt)];
				set(gcf, 'Position', get(0, 'Screensize'));
				saveas(gcf,[Fname,'.eps'],'epsc')
% 				saveas(gcf,[Fname,'.tif'],'tif')
				
				cnt		=	cnt + 1;
                
% 				pause(1)
% 				pause
				close all
			end
		end
	else
		disp('NO GOOD UNITS')
	end
end

function plotPsychDPrime(bData)
plot([mag2db(bData.threshold) mag2db(bData.threshold)],[0 5],'Color',[0.8 0.8 0.8],'LineWidth',15)
hold on
dBDepth	=	mag2db(bData.Depths);
dpFit	=	bData.dpFit;
plot(dBDepth,bData.dp,'ko','MarkerSize',10,'MarkerFaceColor','w','LineWidth',2)
hold on
plot(mag2db(dpFit(:,1)),dpFit(:,2),'k-','LineWidth',2)
plot([-100 100],[1 1],'k--')
xlim([-20 1])
ylim([0 3])
set(gca,'FontSize',16)
title(['Behavior Performance: ' num2str(bData.Rates) ' Hz'])
xlabel( 'AM Depth (dB rel 100%)')
set(gca,'XTick',-21:3:0,'XTickLabel',-21:3:0);
ylabel(' d-prime')
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
axis square

% subplot(2,2,3)
% plot([mag2db(bData.threshold) mag2db(bData.threshold)],[0 5],'Color',[0.8 0.8 0.8],'LineWidth',10)

function Class = RunClassifier(Data)
Rasters			=	Data.Rasters;
Trial			=	Data.SpikeTrial;
bestms			=	Data.Time;
GOs				=	[Rasters(2:end) Trial(2:end)];
NOGO			=	[Rasters(1) Trial(1)];
Ngos			=	length(GOs);
Nogotrials		=	cell2mat(NOGO(:,2));
NogoSpktimes	=	cell2mat(NOGO(:,1));
depth			=	Data.AMDepth(2:end);
dp				=	nan(Ngos,1);

for i=1:Ngos
	Gos			=	GOs(i,:);
	Gotrials	=	cell2mat(Gos(:,2));
	GoSpktimes	=	cell2mat(Gos(:,1));
	
	dp(i,1)		=	RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,bestms);
end
[xfit,yfit,threshold,MSE]	=	PlotDPrimes(depth,dp);

Class.dp		=	dp;
Class.xfit		=	xfit;
Class.yfit		=	yfit;
Class.threshold	=	threshold;
Class.MSE		=	MSE;

function dp = RunIterations(Gotrials,GoSpktimes,Nogotrials,NogoSpktimes,bestms)
Iterations		=	1000;
mxgT			=	max(unique(Gotrials));
mxnT			=	max(unique(Nogotrials));
start			=	400;
stop			=	bestms;
binw			=	10;

for i=1:Iterations
	%---GO Template---%
	for ii=1:round(mxgT/2)
		Gidx		=	randi(mxgT);
		gel			=	Gotrials == Gidx;
		Gtemplate	=	GoSpktimes(gel);
		sel			=	Gtemplate > start & Gtemplate <= stop;
		Gtemp		=	Gtemplate(sel);
		Gpsth		=	hist(Gtemp,start:binw:stop);
		GtempSR(ii,1)	=	sum(sel);
	end
	GtempSR			=	nanmean(GtempSR);
	
	%---NOGO Template---%
	for ii=1:round(mxnT/2)
		Nidx		=	randi(mxnT);
		nel			=	Nogotrials == Nidx;
		Ntemplate	=	NogoSpktimes(nel);
		zel			=	Ntemplate > start & Ntemplate < stop;
		Ntemp		=	Ntemplate(zel);
		Npsth		=	hist(Ntemp,start:binw:stop);
		NtempSR(ii,1)		=	sum(zel);
	end
	NtempSR			=	nanmean(NtempSR);
	
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
		testSR	=	sum(testSR);

% % % 		%---Compare with Templates---%
% % % 		gComp	=	pdist([Tpsth;Gpsth]);
% % % 		nComp	=	pdist([Tpsth;Npsth]);
% % % 		GComp	=	gComp./(gComp+nComp);
% % % 		NComp	=	nComp./(gComp+nComp);
% % % 		Comp	=	[GComp NComp];
% % % 		mn(j,:)	=	Comp == nanmin(Comp);
		
		%---Compare with Templates---%
		gComp	=	abs(testSR - GtempSR);
		nComp	=	abs(testSR - NtempSR);
		Comp	=	[gComp nComp];
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
		testSR	=	sum(testSR);
		
% % % 		%---Compare with Templates---%
% % % 		gComp	=	pdist([Tpsth;Gpsth]);
% % % 		nComp	=	pdist([Tpsth;Npsth]);
% % % 		GComp	=	gComp./(gComp+nComp);
% % % 		NComp	=	nComp./(gComp+nComp);
% % % 		Comp	=	[GComp NComp];
% % % 		Nn(j,:)	=	Comp == nanmin(Comp);

		%---Compare with Templates---%
		gComp	=	abs(testSR - GtempSR);
		nComp	=	abs(testSR - NtempSR);
		Comp	=	[gComp nComp];
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
% sel			=	MN > 0.95;
% MN(sel)		=	0.95;
% ssel		=	MN < 0.05;
% MN(ssel)	=	0.02;
% sel			=	NN > 0.95;
% NN(sel)		=	0.95;
% ssel		=	NN < 0.05;
% NN(ssel)	=	0.05;
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

function [xFit,yFit,Threshold,MSE] = PlotDPrimes(Depth,dprimes)
dp				=	dprimes;
depth			=	mag2db(Depth);

[xfit,yfit,threshold,mse,idx]	=	getthreshold(depth,dp);

xFit			=	xfit;
yFit			=	yfit;
Threshold		=	threshold;
if( isunix )
	MSE			=	dround(mse);
else
	MSE			=	round(mse,3);
end

%---Plot Classifier d-prime---%s
subplot(2,3,6)
plot([Threshold Threshold],[0 3],'b','Color',[0.5 0.5 1],'LineWidth',12)
hold on
plot(depth,dp,'b-','MarkerSize',10,'MarkerFaceColor','b','LineWidth',1)
plot(depth,dp,'bo','MarkerSize',10,'MarkerFaceColor','b','LineWidth',1)
hold on
% plot(xfit,yfit,'b-','LineWidth',2)
plot([-100 100],[1 1],'k--')
xlim([-20 1])
ylim([0 3])

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
