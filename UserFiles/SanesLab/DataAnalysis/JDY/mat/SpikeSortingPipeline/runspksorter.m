function runspksorter(Pname)
clear all
close all force
clc

% Run spike sorting functions. This is for after preprocessing steps.
% Created 23 April 2016 JDY

if( nargin < 1 )
    
    subject     =   '255183';
	session		=	'ZA-54';	%'-#' = Block #%

% 	subject		=	'253888';
% 	session		=	'WA-51';	%'-#' = Block #%

%     subject     =   '255184';
% 	session		=	'KA-28';	%'-#' = Block #%
    Pname		=	'/Volumes/YAO EXHD 2/PROJECTS/AM Discrimination/Ephys/processed_data/';
end
H				=	SpikeSortGUI;
handles			=	guihandles(H);
Par.Pname		=	Pname;
Par.subject		=	subject;
Par.session		=	session;

StartSpikeSorting('Init',handles,Par);
