function hist = updateHist_SanesLab(TTLstr,hist,handles)
%hist = updateHist_SanesLab(TTLstr,hist,handles)
%
%Custom function for SanesLab epsych
%
%This function updates the TTL history for plotting purposes
%
%Inputs: 
%   TTLstr: String identifying the TTL 
%   hist: vector containing TTL high/low history
%   handles: GUI handles structure
%
%Example usage: spout_hist = updateHist_SanesLab('Spout_TTL',spout_hist)
%
%Written by ML Caras 7.24.2016

global RUNTIME AX

goodstr = [];

%Is the tag in the circuit?
if ~isempty(cell2mat(strfind(RUNTIME.TDT.devinfo(handles.dev).tags,TTLstr)))
    
    goodstr = TTLstr;
    
%Backwards compatability: older circuits may lack the '~' for TTLs    
elseif strcmp(TTLstr(1),'~') && ~isempty(cell2mat(strfind(RUNTIME.TDT.devinfo(handles.dev).tags,TTLstr(2:end))))
    
    goodstr = TTLstr(2:end);
end


%Abort if tag is not in circuit
if isempty(goodstr)
    return
end


%Update the history
if RUNTIME.UseOpenEx
    goodstr = [handles.module,'.',goodstr];
    TTL = AX.GetTargetVal(goodstr);
else
    TTL = AX.GetTagVal(goodstr);
end

hist = [hist;TTL];