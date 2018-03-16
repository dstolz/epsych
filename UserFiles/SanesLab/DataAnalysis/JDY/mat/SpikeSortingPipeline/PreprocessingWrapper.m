function PreprocessingWrapper
clear all
close all
clc
%  Run full processing workflow. Take data from raw (epData) format,
%  through automatic spike sorting steps.
%  
%  Note: user input is required in the middle, to select clean trials.
%%%%%%%%%%%%%%%%%%%%%%%%

%---FLAGS---%
Subject			=	'255183';
Session			=	'GA';
BLOCKS			=	18; %can combine file sessions [File1 File2]%

%%%%%%%%%%%%%%%%%%%%%%%%
if( isunix )
    Path			=	'/Volumes/AM DISCRIM/PROJECTS/AM Discrimination/Ephys/';
    datadir			=	'/Volumes/AM DISCRIM/PROJECTS/AM Discrimination/Ephys/processed_data';
else
    Path			=	'E:\AM Discrimination\Ephys\';
    datadir			=	'E:\AM Discrimination\Ephys\processed_data';
end
%%%%%%%%%%%%%%%%%%%%%%%%

Threshold		=	4;
Behavior		=	1;			%1=Phys + Behavior; 0=Idle%

time            =   [-299 3000];    % ms time window %

ConditionFolder	=	['ID_' Subject];
Block		=	BLOCKS;
session		=	Session;

pp_prepare_format( Block, Subject, session , ConditionFolder, Behavior, Path, datadir, time );
Spikes		=	pp_sort_session( Subject, session, Block, datadir, Threshold );

%%%%%%%%%%%%%%%%%%%%%%%%
