function hist = updateHist_SanesLab(TTLstr,hist,handles)
%Custom function for SanesLab epsych
%
%This function updates the TTL history for plotting purposes
%
%Inputs: 
%   TTLstr: String identifying the TTL 
%   hist: vector containing TTL high/low history
%
%Example usage: spout_hist = updateHist_SanesLab('Spout_TTL',spout_hist)
%
%Written by ML Caras 7.24.2016

global RUNTIME AX

%If the string is a parameter tag in the circuit...
if ~isempty(cell2mat(strfind(RUNTIME.TDT.devinfo(handles.dev).tags,TTLstr)))
    
    %Update the history
    if RUNTIME.UseOpenEx
        TTLstr = ['Behavior.',TTLstr];
        TTL = AX.GetTargetVal(TTLstr);
    else
        TTL = AX.GetTagVal(TTLstr);
    end
    
    hist = [hist;TTL];
    
    
end