function runspksorter(Pname)
clear all
close all force
clc

% Run spike sorting functions. This is for after preprocessing steps.
% Created 23 April 2016 JDY

if( nargin < 1 )
	subject		=	'231516';
	session		=	'B';
	Pname		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/processed_data/';
end
H				=	SpikeSortGUI;
handles			=	guihandles(H);
Par.Pname		=	Pname;
Par.subject		=	subject;
Par.session		=	session;

StartSpikeSorting('Init',handles,Par);
