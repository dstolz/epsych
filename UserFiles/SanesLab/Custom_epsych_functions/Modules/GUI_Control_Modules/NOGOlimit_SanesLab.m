function Nogo_lim = NOGOlimit_SanesLab
%Custom function for SanesLab epsych
%This function returns the maximum number of consecutive NOGOs. 
%The value is drawn from a random distribution based on the user-defined
%parameters in the global variable GUI_HANDLES.
%Default distribution is 3 (min) to 5 (max).
%
%
%Written by ML Caras 7.22.2016


global GUI_HANDLES

if ~isempty(GUI_HANDLES)
    lowerbound =  str2num(GUI_HANDLES.Nogo_min.String{GUI_HANDLES.Nogo_min.Value});
    if strcmp('Inf',GUI_HANDLES.Nogo_lim.String{GUI_HANDLES.Nogo_lim.Value})
        upperbound = 2^50; %if Inf is selected in GUI
    else
        upperbound =  str2num(GUI_HANDLES.Nogo_lim.String{GUI_HANDLES.Nogo_lim.Value});
    end
    Nogo_lim = randi([lowerbound upperbound],1);
else
    Nogo_lim = randi([3 5],1); %default
end




end