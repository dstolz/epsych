function [HITind,MISSind,CRind,FAind,DATA,waterupdate,handles] = ...
    update_params_runtime_SanesLab(waterupdate,handles)
%Custom function for SanesLab epsych
%
%This function updates parameters during GUI runtime
%
%Inputs:
%   waterupdate: persistent variable to track whether text for water is
%   updates
%
%   handles: GUI handles structure
%
%Written by ML Caras 7.25.2016


global RUNTIME

%DATA structure
DATA = RUNTIME.TRIALS.DATA;
ntrials = length(DATA);

%Response codes
bitmask = [DATA.ResponseCode]';
HITind  = logical(bitget(bitmask,1));
MISSind = logical(bitget(bitmask,2));
CRind   = logical(bitget(bitmask,3));
FAind   = logical(bitget(bitmask,4));

%If the water volume text is not up to date...
if waterupdate < ntrials
    
    %Update the water text
    handles = updatewater_SanesLab(handles);
    waterupdate = ntrials;
    
end