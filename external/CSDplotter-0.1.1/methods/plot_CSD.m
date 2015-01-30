function plot_CSD(CSD_matrix,el_pos,dt,scale_plot,max_plot)
%plot_CSD(CSD_matrix,scale_plot,max_plot,figure_label)
%
%Used to plot the color-plots of the CSD. The colormap_redblackblue goes
%from limit -clim to clim, decided by: clim = max_plot*scale_plot
%
%CSD_matrix: the matrix to plot [A/m^3]
%scale_plot: if one wants to focus the plot this should be from 0 to 1.
%max_plot: the maximum value to plot
%figure_label: text string, e.g. 'a)'


%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

unit_scale = 1e-3; % A/m^3 -> muA/mm^3
CSD_matrix = CSD_matrix*unit_scale;
%if nargin<3; max_plot=max(abs(CSD_matrix(:))); else; max_plot = max_plot*unit_scale; end;
%if nargin<2; scale_plot = 1; end;
if max_plot==0; max_plot=max(abs(CSD_matrix(:))); end;

%figure();
clim=max_plot*scale_plot;

npoints = 200; % number of points to plot in the vertical direction
le = length(el_pos);
first_z = el_pos(1)-(el_pos(2)-el_pos(1))/2; %plot starts at z1-h/2;
last_z = el_pos(le)+(el_pos(le)-el_pos(le-1))/2; %ends at zN+h/2;
zs = first_z:(last_z-first_z)/npoints:last_z;
el_pos(le+1) = el_pos(le)+(el_pos(le)-el_pos(le-1)); % need this in for loop
j=1; %counter
for i=1:length(zs) % all new positions
    if zs(i)>(el_pos(j)+(el_pos(j+1)-el_pos(j))/2) % > el_pos(j) + h/2
        j = min(j+1,le);
    end;
    new_CSD_matrix(i,:)=CSD_matrix(j,:);
end;

% %increase z-resolution:
% inc_factor = 10; % 10 times the resolution
% for i = 1:length(CSD_matrix(:,1))*inc_factor
%     new_CSD_matrix(i,:) = CSD_matrix(round((i-1)/inc_factor+0.5),:);
% end;

imagesc(new_CSD_matrix,[-clim clim]);
colormap(colormap_redblackblue);colorbar();
set(gca,'FontSize',10)

[nel,ntime] = size(CSD_matrix);
time = dt:dt:dt*ntime;
xlabel('Time [ms]')
ylabel('z [mm]')

time_ticks = get(gca,'XTick');
for i=1:length(time_ticks)
  new_ticks{i} = num2str(time(time_ticks(i)));
end;

z_ticks = get(gca,'YTick');
for i=1:length(z_ticks)
  new_zticks{i} = num2str(round(zs(z_ticks(i))*1e5)*1e-2); % [m] -> [mm] with two decimals
end;


set(gca,'XTick',time_ticks)
set(gca,'XTickLabel',new_ticks)

set(gca,'YTick',z_ticks)
set(gca,'YTickLabel',new_zticks)