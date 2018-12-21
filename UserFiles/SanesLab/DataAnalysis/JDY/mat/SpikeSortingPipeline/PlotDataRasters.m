function PlotDataRasters
clear all
close all
clc
% Created 22 April 2016 JDY

%---FLAGS---%
Behavior		=	1;
subject			=	'230115';
% subject			=	'235107';
session			=	'CA';
Block			=	'126';
Path			=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/processed_data/';
DataFile		=	[Path subject '/' subject '_sess-' session '-' Block '_Spikes.mat'];
load(DataFile)
% Chans			=	[1 2 4 5 6 9 10 11 12 13 14 16];
% Chans			=	[1 2 5 9 15 16];
% Chans			=	[1 2 3 5 6 11 14 15 16];
Chans			=	11;
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
				cnt			=	cnt + 1;
				%---Plotting---%
				%---Frequency Tuning---%
% 				pp_plot_rasters_Freq(subject, session, channel, clus)
				if( Behavior )
					pp_plot_rasters_AMBehavior(Path, subject, session, Block, channel, clus)
% 					pp_plot_rasters_AMBehavior_ver2(Path, subject, session, Block, channel, clus)
				else
					pp_plot_rasters_AM(Path, subject, session, Block, channel, clus)
				end
				pause
				close all
			end
			% 			close all
		end
	else
		disp('NO GOOD UNITS')
	end
end
disp(['Number of Single-Units: ' num2str(sum(NSU))])

% pp_plot_rasters(subject, session, channel, cluster)
