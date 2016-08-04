function bits = getBits_SanesLab
%Custom function for SanesLab epsych
%
%This function retreives the bit information for hits, misses, correct
%rejects, and false alarms for each paradigm.
%
%
%Written by ML Caras 7.25.2016

global FUNCS

%Find the name of the GUI box figure
boxfig = FUNCS.BoxFig;

switch lower(boxfig)
    case {'aversive_detection_gui','appetitive_detection_gui','appetitive_detection_gui_v2'}
        bits.hit = 1;
        bits.miss = 2;
        bits.cr = 3;
        bits.fa = 4;
   
    
    %Default
    otherwise
        warning('Box Figure not defined in getBits_SanesLab.m. Response code bits set to default.');
        bits.hit = 1;
        bits.miss = 2;
        bits.cr = 3;
        bits.fa = 4;
end
