function tags = rmTags_SanesLab(tags)
%Custom function for SanesLab epsych
%
%This function removes OpenEx/TDT proprietary parameter tags from a cell
%array of tag names
%
%Written by ML Caras 8.1.2016

tags(~cellfun('isempty',strfind(tags,'~'))) = [];
tags(~cellfun('isempty',strfind(tags,'%'))) = [];
tags(~cellfun('isempty',strfind(tags,'\'))) = [];
tags(~cellfun('isempty',strfind(tags,'/'))) = [];
tags(~cellfun('isempty',strfind(tags,'|'))) = [];
tags(~cellfun('isempty',strfind(tags,'z'))) = [];
tags(~cellfun('isempty',strfind(tags,'Z'))) = [];
tags(~cellfun('isempty',strfind(tags,'#'))) = [];
tags(~cellfun('isempty',strfind(tags,'!'))) = [];