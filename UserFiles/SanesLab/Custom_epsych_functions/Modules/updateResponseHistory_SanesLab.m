function handles = updateResponseHistory_SanesLab(handles,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,variables,...
    ntrials,TrialTypeInd,TrialType,...
    REMINDind)
%Custom function for SanesLab epsych
%
%This function updates the GUI Response History Table
%
%Inputs:
%   handles: GUI handles structure
%   HITind: logical index vector for HITs
%   MISSind:logical index vector for MISSes
%   FAind: logical index vector for FAs
%   CRind: logical index vector for CRs
%   GOind: numerical indices (non logical) for GO trials
%   NOGOind: numerical indices (non logical) for NOGO trials
%   variables: matrix containing roved parameter information for each trial
%   ntrials: number of completed trials
%   TrialTypeInd: column containing trial type info
%   TrialType: vector of trial types
%   REMINDind: numerical indices (non logical) for REMINDER trials
%   
%
%Written by ML Caras 7.27.2016



%Establish data table
numvars = size(variables,2);
D = cell(ntrials,numvars+1);

%Set up roved parameter arrays
D(:,1:numvars) = num2cell(variables);

%Set up response cell array
Responses = cell(size(HITind));
Responses(HITind)  = {'Hit'};
Responses(MISSind) = {'Miss'};
Responses(FAind)   = {'FA'};
Responses(CRind)   = {'CR'};
D(:,end) = Responses;

%Set up trial type cell array
TrialTypeArray = cell(size(TrialType));
TrialTypeArray(GOind) = {'GO'};
TrialTypeArray(NOGOind) = {'NOGO'};
TrialTypeArray(REMINDind) = {'REMIND'};
D(:,TrialTypeInd) = TrialTypeArray;

%Flip so the recent trials are on top
D = flipud(D);

%Number the rows with the correct trial number (i.e. reverse order)
r = length(Responses):-1:1;
r = cellstr(num2str(r'));

set(handles.DataTable,'Data',D,'RowName',r)


end
