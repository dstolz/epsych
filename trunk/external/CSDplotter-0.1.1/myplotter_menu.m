function myplotter_menu

h = figure('Name','CSD menu');


% % uicontrol('style','text','units','normalized','position',[0.1 0.1 0.1 0.1],'string','Filter:');
% % uicontrol('style','text','units','normalized','position',[0.2 0.1 0.1 0.1],'string','File');
% % uicontrol('style','edit','tag','x_var','units','normalized','position',[0.8 0.85 0.05 0.05],'string','2');
% 
% 
% uicontrol('style','text','units','normalized','position',[0.88 0.85 0.03 0.05],'string','b =');
% uicontrol('style','edit','tag','y_var','units','normalized','position',[0.93 0.85 0.05 0.05],'string','1');

uicontrol('style','text','units','normalized','position',[0.2 0.88 0.24 0.05],'string','Choose CSD method(s):');
uicontrol('style','checkbox','tag','x_var','units','normalized','position',[0.2 0.81 0.3 0.05],'string','Cubic spline iCSD method');
uicontrol('style','checkbox','tag','x_var','units','normalized','position',[0.2 0.74 0.3 0.05],'string','Step iCSD method');
uicontrol('style','checkbox','tag','x_var','units','normalized','position',[0.2 0.67 0.3 0.05],'string','Delta iCSD method');
uicontrol('style','checkbox','tag','x_var','units','normalized','position',[0.2 0.60 0.3 0.05],'string','Standard CSD method');

uicontrol('style','text','units','normalized','position',[0.2 0.45 0.04 0.05],'string','File:');
uicontrol('style','edit','tag','x_var','units','normalized','position',[0.25 0.45 0.5 0.05],'string','my_file.m');
uicontrol('style','pushbutton','tag','plot_button','callback',@browse_file,'units','normalized','position',[0.75 0.45 0.1 0.05],'string','Browse');
uicontrol('style','pushbutton','tag','plot_button','callback',@run,'units','normalized','position',[0.2 0.3 0.1 0.05],'string','OK');



% uicontrol('style','pushbutton','tag','plot_button','callback',@plotcurve,'units','normalized','position',[0.75 0.35 0.1 0.05],'string','Plot');
% uicontrol('style','pushbutton','tag','plot_button','callback',@clearaxes,'units','normalized','position',[0.75 0.25 0.1 0.05],'string','Clear');
% 
% 
% function [filename,pathname]=browse_file
%     [filename, pathname] = uigetfile('*.m', 'Pick an M-file');
%     if isequal(filename,0)
%         disp('User selected Cancel')
%     end;
%     uicontrol('style','edit','tag','y_var','units','normalized','position',[0.93 0.85 0.05 0.05],'string',filename);
% %     disp(['User selected', fullfile(pathname, filename)])
% %     end
% return
% 
% %Callback function for plotting a curve
% function plotcurve(obj,eventdata)
% 
% x_tag = findobj('tag','x_var');
% y_tag = findobj('tag','y_var');
% 
% try
%     x_var = get(x_tag,'string');
%     y_var = get(y_tag,'string');
%     
%     x = evalin('base',x_var);
%     y = evalin('base',y_var);
%     
%     plot(x,y)
% catch
%     errordlg('Sorry, could not read and plot data','My plotter');
% end
% return
% 
% %Callback function for clearing the axes
% function clearaxes(obj,eventdata)
% cla
% return;
