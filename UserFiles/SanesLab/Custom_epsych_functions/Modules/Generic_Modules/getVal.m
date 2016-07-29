function output = getVal(handle)
%Custom function for SanesLab epsych
%
%This function retreives the user-selected value of a GUI handle
%
%Input:
%   handle: GUI handle
%
%Example: To obtain the user-selected dBSPL value-  getVal(handle.dBSPL)
%
%Written by ML Caras 7.28.2016

str = get(handle,'String');
val = get(handle,'Value');

output = str2num(str{val});