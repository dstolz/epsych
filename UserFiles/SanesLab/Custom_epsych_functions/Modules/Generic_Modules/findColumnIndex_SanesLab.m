function ind =  findColumnIndex_SanesLab(handles,colnames,colstr)
%Custom function for SanesLab epsych
%
%This function finds the index of colstr in colnames
%Inputs:
%   colnames: cell array of column names
%   colstr: string containing column name of interest
%
%
%Written by ML Caras 8.4.2016

global RUNTIME


if RUNTIME.UseOpenEx
    ind = find(ismember(colnames,[handles.module,'.',colstr]));
else
    ind = find(ismember(colnames,colstr));
end





end