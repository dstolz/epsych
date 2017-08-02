function PlotBehaviorEphysFunctions
clear all
close all
clc
% Created 20 June 2017 JDY

%---FLAGS---%
NH				=	[{'236397'}];
CHL				=	[{'239151'}];
if( isunix )
	Path		=	'/Volumes/JUSTIN EXHD/DataStore/';
else
    Path        =   'E:\PROJECTS\DataStore\';
end

%---Plot Control Data---%
nh				=	getdata(Path,NH);
plotdata(nh,'k')

%---Plot HL Data---%
hl				=	getdata(Path,CHL);
plotdata(hl,[1 0.50 0])

%---Locals---%
function data = getdata(Path,IDs)
N			=	length(IDs);
data		=	cell(N,1);
for i=1:N
	id		=	IDs{i};
	pname	=	[Path id '/'];
	files	=	getfiles(pname);
	dat		=	gatherdata(files);
	data(i,1)	=	{dat};
end

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

function d = gatherdata(files)
N			=	length(files);
cnt			=	1;
for i=1:N
	file	=	files{i};
	load(file)
	Nunits	=	length(Data);
	for j=1:Nunits
		temp	=	Data(j);
		ephys	=	temp.D;
		
		d(cnt,1)	=	{ephys.AMRate};
		d(cnt,2)	=	{ephys.AMDepth};
		d(cnt,3)	=	{ephys.DPrime};
		
		cnt			=	cnt + 1;
	end
end

%---Plotting---%
function plotdata(data,col)
N			=	length(data);
Rates		=	[64 128 256 512];
NRates		=	length(Rates);
for i=1:N
	d		=	data{i};
	rates	=	cell2mat(d(:,1));
	
	for j=1:NRates
		subplot(2,2,j)
		rate	=	Rates(j);
		sel		=	rates == rate;
		dd		=	d(sel,2:3);
		plotfunctions(dd,col,rate)
		
	end
end

function plotfunctions(data,col,rate)
N			=	length(data);
for i=1:N
	X		=	cell2mat(data(i,1));
	X		=	X(2:end);
	X		=	mag2db(X);
	Y		=	cell2mat(data(i,2));
	
	plot(X,Y,'-','Color',col,'LineWidth',1)
	hold on
end
plot([-100 100],[1 1],'k--')
xlim([-20 1])
ylim([0 3])
set(gca,'FontSize',16)
title(['Neural Performance: ' num2str(rate) ' Hz'])
xlabel( 'AM Depth (dB rel 100%)')
set(gca,'XTick',-21:3:0,'XTickLabel',-21:3:0);
ylabel(' d-prime')
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
axis square
