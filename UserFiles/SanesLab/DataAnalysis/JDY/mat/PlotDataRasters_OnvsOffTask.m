function PlotDataRasters_OnvsOffTask
% Created 29 Nov 2017 JDY
% Edited 22 Jan 2018 JDY
close all
clc

%---FLAGS---%
subject			=	'253888';
% subject			=	'255183';
% subject			=	'255184';
session			=	'WA';
OnBlock			=	'51';
OffBlock        =	'52';
Chans			=	[6];
Path            =	'/Volumes/YAO EXHD 2/PROJECTS/AM Discrimination/Ephys/processed_data/';

%-Plot Off-Task Data-%
plotdata(subject,session,OffBlock,Chans,Path,'Off-Task')
%-Plot On-Task Data-%
plotdata(subject,session,OnBlock,Chans,Path,'On-Task')

%---Locals---%
function plotdata(subject,session,Block,Chans,Path,Condition)
DataFile		=	[Path subject '/' subject '_sess-' session '-' Block '_Spikes.mat'];

load(DataFile)
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
                                
                figure(clus(2))
                
                %---Plotting---%
                if( strcmp(Condition,'On-Task') )
                    Don     =   pp_plot_rasters_AMBehavior_OnTask(Path, subject, session, Block, channel, clus);
                else
                    Doff    =   pp_plot_rasters_AMBehavior_OffTask(Path, subject, session, Block, channel, clus);
                end
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