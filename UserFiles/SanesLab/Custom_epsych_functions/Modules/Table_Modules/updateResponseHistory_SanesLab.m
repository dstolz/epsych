function handles = updateResponseHistory_SanesLab(handles,HITind,MISSind,...
    FAind,CRind,GOind,NOGOind,variables,...
    ntrials,TrialTypeInd,TrialType,...
    REMINDind,varargin)
%handles = updateResponseHistory_SanesLab(handles,HITind,MISSind,...
%       FAind,CRind,GOind,NOGOind,variables,ntrials,TrialTypeInd,...
%       TrialType, REMINDind,varargin)
%
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
%   TrialTypeInd: index of column containing trial type info
%   TrialType: vector of trial types
%   REMINDind: numerical indices (non logical) for REMINDER trials
%   
%   varargin{1}: index of column containing "expected" info
%   varargin{2}: numerical indices (non logical) for "expected" trials
%   varargin{3}: numerical indices (non logical) for "unexpected" trials
%
%Written by ML Caras 7.27.2016

global RUNTIME

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


%Special case: If "expected" is a parameter tag in the circuit
if sum(~cellfun('isempty',strfind(RUNTIME.TDT.devinfo(handles.dev).tags,'Expected')))
   
    expectInd = varargin{1};
    YESind = varargin{2};
    NOind = varargin{3};
    
    if ~isempty(expectInd)
        ExpectedArray = cell(size(TrialTypeArray));
        ExpectedArray(YESind) = {'Yes'};
        ExpectedArray(NOind) = {'No'};
        D(:,expectInd) = ExpectedArray;
    end
    
end



%Flip so the recent trials are on top
D = flipud(D);

%Number the rows with the correct trial number (i.e. reverse order)
r = length(Responses):-1:1;
r = cellstr(num2str(r'));

set(handles.DataTable,'Data',D,'RowName',r)


end
