function [new_pos, new_CSD] = new_CSD_range(pos,CSD,pstart,pstop)
%[new_pos, new_CSD] = new_CSD_range(pos,CSD,pstart,pstop)
%
% This procedure deminshes the CSD window with respect to positions,
% keeping the resolution constant.
%
% pos:      old CSD positions
% pstart:   starting position of the new CSD window
% pstop:    end position of the new CSD window
% new_pos:  new positions (of smaller (or same) size than the old)
% new_CSD:  new CSD (smaller window than the old)

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html
nstart = 1;
nstop = 1;
for i=1:length(pos)
    if pos(i)<pstart; nstart = nstart+1;end; % counts number of instances below start pos.
    if pos(i)<pstop; nstop = nstop+1;end;    % counts number of instances below end pos.
end;
new_pos = pos(nstart:nstop);
new_CSD = CSD(nstart:nstop,:);