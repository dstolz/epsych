function tags = rmTags_SanesLab(tags)
%Custom function for SanesLab epsych
%
%This function removes OpenEx/TDT proprietary parameter tags from a cell
%array of tag names
%
%Written by ML Caras 8.1.2016
%Updated by KP 11.05.2016 (keep fileID tags associated with buffers)


%Find any tags the refer to the File ID of a buffer parameter, and save
%them from being removed from the DATA structure.
ibuf = find(~cellfun('isempty',regexp(tags,'~.+_ID')));     %kp
if sum(ibuf)>1
    for ib=ibuf
        tags{ib} = tags{ib}(2:end);
    end
end
tags(~cellfun('isempty',strfind(tags,'~'))) = [];
tags(~cellfun('isempty',strfind(tags,'%'))) = [];
tags(~cellfun('isempty',strfind(tags,'\'))) = [];
tags(~cellfun('isempty',strfind(tags,'/'))) = [];
tags(~cellfun('isempty',strfind(tags,'|'))) = [];
tags(~cellfun('isempty',strfind(tags,'#'))) = [];
tags(~cellfun('isempty',strfind(tags,'!'))) = [];

tags(cellfun(@(x) x(1) == 'z', tags)) = [];


