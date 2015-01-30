function myplotter

h = figure('Name','My plotter');

axes('position',[0.1 0.1 0.6 0.8]);
grid on;
hold on;

uicontrol('style','text','units','normalized','position',[0.75 0.9 0.1 0.05],'string','Filter:');
uicontrol('style','text','units','normalized','position',[0.75 0.85 0.03 0.05],'string','a =');
uicontrol('style','edit','tag','x_var','units','normalized','position',[0.8 0.85 0.05 0.05],'string','2');

uicontrol('style','text','units','normalized','position',[0.88 0.85 0.03 0.05],'string','b =');
uicontrol('style','edit','tag','y_var','units','normalized','position',[0.93 0.85 0.05 0.05],'string','1');

uicontrol('style','pushbutton','tag','plot_button','callback',@plotcurve,'units','normalized','position',[0.75 0.35 0.1 0.05],'string','Plot');

uicontrol('style','pushbutton','tag','plot_button','callback',@clearaxes,'units','normalized','position',[0.75 0.25 0.1 0.05],'string','Clear');

%Callback function for plotting a curve
function plotcurve(obj,eventdata)

x_tag = findobj('tag','x_var');
y_tag = findobj('tag','y_var');

try
    x_var = get(x_tag,'string');
    y_var = get(y_tag,'string');
    
    x = evalin('base',x_var);
    y = evalin('base',y_var);
    
    plot(x,y)
catch
    errordlg('Sorry, could not read and plot data','My plotter');
end
return

%Callback function for clearing the axes
function clearaxes(obj,eventdata)
cla
return;
