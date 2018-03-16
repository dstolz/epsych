function SpikeSorting
clear all
close all
clc
% Run spike sorting functions. This is for after preprocessing steps.
% Created 22 April 2016 JDY

%---CANNOT RUN THIS IN DEBUG MODE---%
%---FLAGS---%
subject			=	'231516';
session			=	'AA';
Path			=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/processed_data/';
DataFile		=	[Path subject '/' subject '_sess-' session '_Spikes.mat'];
load(DataFile)

channel			=	16;

%---MANUAL SORTING---%
[subject, session, channel, Spikes]	=	pp_launch_manual_sort( subject, session, channel, Spikes )
%---CANNOT RUN THIS IN DEBUG MODE---%
keyboard
%---WILL HAVE TO CALL THIS NEXT FUNCTION MANUALLY---%
Spikes	=	pp_save_manual_sort( subject, session, Spikes, channel, spikes );
