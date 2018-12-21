function RunAMDiscrimination
clear all
close all
clc

Path = '/Volumes/JUSTIN EXHD/PROJECTS/AM Discrimination/Data/';
%-NH-%
NH      = [Path 'NH/'];
nh      =   getfiles(NH);
subplot(1,2,1)
plotdata(nh,'NH')
%-HL-%
HL      =   [Path 'HL/'];
hl      =   getfiles(HL);
figure(1)
subplot(1,2,2)
plotdata(hl,'HL')

%---Locals---%
function List = getfiles(path)
listing			=	dir(path);
N				=	length(listing);
cnt				=	1;
List			=	{};
for i=1:N
	temp		=	listing(i).name;
	tmp			=	temp(end);
	if( strcmp(tmp,'t') )
		List(cnt,1)	=	{[path temp]};
		cnt		=	cnt + 1;
	end
end

function plotdata(DataFiles,Title)
Nfiles      =   length(DataFiles);
% col         =   jet(Nfiles);
if( strcmp(Title,'NH') )
    col         =   hsv(Nfiles+2);
else
    col         =   hsv(Nfiles+2);
end
col         =   col(1:Nfiles,:);
for i=1:Nfiles
    
   file     =   DataFiles{i}; 
   load(file)
   
   D        =   [Data(:,2) Data(:,3) Data(:,end)];
   
   x        =   D(:,1);
   xel      =   x == 0;
   x(xel)   =   NaN;
   y        =   D(:,2);
   yel      =   y == 0;
   y(yel)   =   NaN;
   
   sel      =   D(:,end) == 1;
   
%    plot(x,y,'o','Color',col(i,:),'MarkerFaceColor','w','MarkerSize',12)
%    hold on
   plot(x(~sel),y(~sel),'o','Color',col(i,:),'MarkerSize',8)
   hold on
   plot(x(sel),y(sel),'o','Color',col(i,:),'MarkerFaceColor',col(i,:),'MarkerSize',8)
   plot(x,y,'-','Color',col(i,:),'LineWidth',2)

end
% Axis %
set(gca,'FontSize',26)
title(Title)
xlim([0 22])
ylim([0 1.2])
xlabel('Days relative to first testing')
ylabel('JND')
axis square;

