function PlotDataRasters
% Created 29 Nov 2017 JDY
% Edited 22 Jan 2018 JDY
% close all
clc

%---FLAGS---%
Behavior		=	1;
subject			=	'253888';
% subject			=	'255183';
% subject			=	'255184';
session			=	'WA';
Block			=	'51';
Path            =	'/Volumes/YAO EXHD 2/PROJECTS/AM Discrimination/Ephys/processed_data/';

DataFile		=	[Path subject '/' subject '_sess-' session '-' Block '_Spikes.mat'];
load(DataFile)
Chans			=	[2];
NChan			=	length(Chans);
cnt				=	1;

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
                
                xel		=	clus(:,end) == 2;
                NSU(cnt,1)	=	sum(xel);
                
                figure
                
                %---Plotting---%
                if( Behavior )
                    Don = pp_plot_rasters_AMBehavior_v2(Path, subject, session, Block, channel, clus);
                else
                    %-Off-Task-%
                    Doff = pp_plot_rasters_AMBehavior_vOFFTask(Path, subject, session, Block, channel, clus)
                end
                %                 keyboard
%                 pause
%                 close all
                
%                 keyboard
                
%                 %---Store Values---%
% 				Data(cnt).channel		=	channel;
% 				Data(cnt).cluster		=	clus(1,2);
% 				Data(cnt).D				=	D;
% 				Data(cnt).Behavior		=	bData;
                
                cnt			=	cnt + 1;
            end
        end
    else
        disp('NO GOOD UNITS')
    end
end
%     keyboard
disp(['Number of Single-Units: ' num2str(sum(NSU))])
