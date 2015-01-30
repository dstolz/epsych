function [CSD,el_pos_plot,handles.dt,1,0] = compute_CSD(hObject,handles)
% filter parameters:
b0 = str2num(get(handles.filter_b0,'String'));
b1 = str2num(get(handles.filter_b1,'String'));
% electrical parameters:
cond = str2num(get(handles.ex_cond,'String'));
% electrode parameters:
el_pos = str2num(get(handles.electrode_pos,'String'))*1e-3; % mm -> m
el_pos_plot = el_pos(2:length(el_pos)-1); % if not Vaknin electrodes
N = length(el_pos);
h = mean(diff(el_pos));
pot = handles.pot;

[m1,m2] = size(handles.pot);


% compute standard CSD with vaknin el.
if get(handles.Vaknin,'Value')
  el_pos_plot = el_pos;
  pot(1,:) = handles.pot(1,:);
  pot(2:m1+1,:)=handles.pot;
  pot(m1+2,:)=handles.pot(m1,:);
end;

CSD = -cond*D1(length(pot(:,1)),h)*pot;

if b1~=0 %filter iCSD (does not change size of CSD matrix)
  [n1,n2]=size(CSD);            
  CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
  CSD_add(n1+2,:)=zeros(1,n2);
  CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
  CSD = S_general(n1+2,b0,b1)*CSD_add; % CSD has n1 rows
end;
