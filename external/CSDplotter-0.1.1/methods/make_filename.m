function out_string = make_filename(diameter,off,N,h,z1,cond,cond_top)
%out_string = make_filename(diameter,off,N,h,z1,cond,cond_top)
%
%makes filename (without ending) from parameters used in simulation
%diameter: diameter
%off: off center position of electrode [m]
%N: number of electrodes
%z1: position of first electrode [m]
%cond: extracellular conductivity [S/m]
%cond_top: conductivity above cortex [S/m]

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html
tdiameter=['_d' num2str(diameter*1e6)];
if off=='0'; toff='_off0'; elseif off==0; toff=''; else; toff = ['_off' num2str(off/(diameter/2))];end;
if N==23; tN=''; else; tN=['_N' num2str(N)];end;
if h==100e-6; th=''; else; th=['_h' num2str(h*1e6)];end;
if z1==100e-6; tf=''; else; tf=['_f' num2str(z1*1e6)];end;
if cond==0.05; tcond='';else;tcond=['_s' num2str(cond)];end;
if cond_top==cond; tcond_top='';else;tcond_top = ['_t' num2str(cond_top)];end;

out_string = [tdiameter toff tN th tf tcond tcond_top];