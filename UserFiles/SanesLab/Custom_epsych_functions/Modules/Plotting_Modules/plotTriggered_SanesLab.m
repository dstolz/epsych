function plotTriggered_SanesLab(timestamps,TTL,trigger_TTL,ax,clr,varargin)
%plotTriggered_SanesLab(timestamps,TTL,trigger_TTL,ax,clr,varargin)
%
%Custom function for SanesLab epsych
%
%This function plots TTL data in realtime as a triggered plot.
%Using the MATLAB plot feature each time the graph must update is very slow
%and will cause a visible lag when running the GUI. To speed up plotting,
%we create the plot once, at the beginning of the experiment, and then
%simply update the X and Y data as needed. This approach is much faster,and
%greatly reduces (or even eliminates) visible lag.
%
%Inputs:
%   timestamps: [n x 1]vector of timestamps
%   TTL: [m x 1]vector of TTL values
%   trigger_TTL: [m x 1] vector of TTL values to trigger the plot
%   ax: handle of plotting axis
%   clr: [1 x 3] vector of RGB values or color identifier string (e.g. 'r')
%
%   varargin{1}: x label text (string)
%   varargin{2}: [n x 1] vector of trial types (same length as timestamps)
%
%Example usage:
%   plotTriggered_SanesLab(timestamps,spout_hist,trial_hist,...
%               handles.trialAx,'k');
%
%Written by ML Caras 7.28.2016

%Initialize x text
if nargin >= 6
    xtext = varargin{1};
else
    xtext = '';
end


%Find the trigger onset
d = diff(trigger_TTL);
onset = find(d == 1,1,'last')+1;

%Find end of the most recent action
action_end = find(TTL == 1,1,'last');



%Limit time and TTLs to the trigger onset and the end of
%the most recent action
if isempty(onset) || isempty(action_end)
    return
end

timestamps = timestamps(onset:action_end);
TTL = TTL(onset:action_end);

%Create x and y values for plotting
ind = logical(TTL);
xvals = timestamps(ind);
yvals = ones(size(xvals));


%If the user has provided trial type values
if nargin == 7
    %Pull out the trial type values
    trial_history = varargin{2};
    trial_history = trial_history(onset:action_end);
    trial_history = trial_history(ind);
    
    %If the trial was a go (0)
    if trial_history(1) == 0
        clr = 'g';
    end
    
end

%Find existing plots
current_plot = get(ax,'children');


%If the plot already exists
if ~isempty(current_plot)
    
    %Update the data
    %if ~isempty(xvals)
        warning('off','MATLAB:hg:line:XDataAndYDataLengthsMustBeEqual')
        set(current_plot,'Xdata',xvals);
        set(current_plot,'Ydata',yvals);
        set(current_plot,'color',clr);
        warning('on','MATLAB:hg:line:XDataAndYDataLengthsMustBeEqual')
    %end
    
    
%If the plot does not yet exist
else
    
    %Create it for the first time
    if ~isempty(xvals)
        plot(ax,xvals,yvals,'s','color',clr,'linewidth',20)
        format_once(ax,nargin,xtext)
    end
    
    
end

%Update x limits
if ~isempty(xvals)
    xmin = timestamps(1) - 2; %start 2 sec before trial onset
    xmax = timestamps(1) + 5; %end 5 sec after trial onset
    set(ax,'xlim',[xmin xmax]);
end








%FORMAT PLOT
function format_once(ax,n,xtext)
%This function formats the realtime plots. Use once, at the moment of plot
%creation, to optimize speed.

set(ax,'ylim',[0.9 1.1]);
set(ax,'YTickLabel','');
set(ax,'XGrid','on');
set(ax,'XMinorGrid','on');

%Enable zooming and panning
dragzoom(ax);

if n >= 6
    xlabel(ax,xtext,'Fontname','Arial','FontSize',12)
    
    if isempty(regexp(xtext,'\w','once'))
        set(ax,'XTickLabel','');
    end
else
    set(ax,'XTickLabel','');
end

