function plotContinuous_SanesLab(timestamps,TTL,ax,clr,xmin,xmax,varargin)
%plotContinuous_SanesLab(timestamps,TTL,ax,clr,xmin,xmax,varargin)
%
%Custom function for SanesLab epsych
%
%This function plots TTL data in realtime as a continuous, scrolling plot.
%Using the MATLAB plot feature each time the graph must update is very slow
%and will cause a visible lag when running the GUI. To speed up plotting,
%we create the plot once, at the beginning of the experiment, and then
%simply update the X and Y data as needed. This approach is much faster,and
%greatly reduces (or even eliminates) visible lag.
%
%Inputs: 
%   timestamps: [n x 1]vector of timestamps 
%   TTL: [m x 1]vector of TTL values
%   ax: handle of plotting axis
%   clr: [1 x 3] vector of RGB values or color identifier string (e.g. 'r')
%   xmin: minimum x axis value for plot
%   xmax: maximum x axis value for plot
%
%   varargin{1}: x label text (string)
%   varargin{2}: [n x 1] vector of trial types (same length as timestamps)
%
%Example usage: 
%   plotContinuous_SanesLab(timestamps,spout_hist,...
%               handles.trialAx,'k',xmin,xmax,'Time (s)',type_hist);
%
%Written by ML Caras 7.28.2016

%Initialize x text
if nargin >= 7
    xtext = varargin{1};
else
    xtext = '';
end



%Create x and y values for plotting
ind = logical(TTL);

if isempty(ind)
    return
end

xvals = timestamps(ind);
yvals = ones(size(xvals));


%Find existing plots
current_plots = get(ax,'children');

%If the user has provided the trial type information
if nargin == 8
    
    %Pull out the trial type values
    trial_history = varargin{2};
    trial_history = trial_history(ind);
    
    %Find nogos (trial type 1)
    nogo_ind = find(trial_history == 1);
    xnogo = xvals(nogo_ind);
    ynogo = yvals(nogo_ind);
    
    %Find gos (trial type 0)
    go_ind = find(trial_history == 0);
    xgo = xvals(go_ind);
    ygo = yvals(go_ind);
    
    %If the nogo and go plots already exist
    if numel(current_plots) >1
        
        h_nogo= current_plots(1);
        h_go = current_plots(2);
        
        %Update the nogo data
        if ~isempty(xnogo)
            set(h_nogo,'Xdata',xnogo);
            set(h_nogo,'Ydata',ynogo);
            set(h_nogo,'color',[0.5, 0.5, 0.5]);
        end
        
        %Update the go data
        if ~isempty(xgo)
            set(h_go,'Xdata',xgo);
            set(h_go,'Ydata',ygo);
            set(h_go,'color','g');
        end
        
    %If the nogo and go plots do not already exist
    else
        %Create nogo plot for first time
        if ~isempty(xnogo)
            h_nogo = plot(ax,xnogo,ynogo,'s','color',clr,'linewidth',20);
            format_once(ax,nargin,xtext)
            hold(ax,'all');
            
            
        end
        
        %Create go plot for first time
        if ~isempty(xgo)
            h_go = plot(ax,xgo,ygo,'s','color','g','linewidth',20);
            format_once(ax,nargin,xtext)
            hold(ax,'all');
            
        end
    end
    
    
%If the user has not provided trial type information...    
else
    
    %If the plot already exists
    if ~isempty(current_plots)
        
        %Update plot
        if ~isempty(xvals)
            set(current_plots(1),'xdata',xvals);
            set(current_plots(1),'ydata',yvals);
        end
        
        
    else
        
        %Create the plot for first time
        if ~isempty(xvals)
            plot(ax,xvals,yvals,'s','color',clr,'linewidth',20)
            format_once(ax,nargin,xtext)
            
            
        end
        
    end
    
    
end


%Update x limits
set(ax,'xlim',[xmin xmax]);
hold(ax,'off');




    
%FORMAT THE PLOT
function format_once(ax,n,xtext)
%This function formats the realtime plots. Use once, at the moment of plot
%creation, to optimize speed.

%Format plot once
set(ax,'ylim',[0.9 1.1]);
set(ax,'YTickLabel','');
set(ax,'XGrid','on');
set(ax,'XMinorGrid','on');

if n >= 7
    xlabel(ax,xtext,'Fontname','Arial','FontSize',12)
    
    if isempty(regexp(xtext,'\w','once'))
        set(ax,'XTickLabel','');
    end
    
else
    set(ax,'XTickLabel','');
    
end




