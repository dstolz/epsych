function handles = updateIOPlot_SanesLab(handles,variables,HITind,GOind,REMINDind)
%handles = updateIOPlot_SanesLab(handles,variables,HITind,GOind,REMINDind)
%
%Custom function for SanesLab epsych
%
%This function creates an xy plot of either hit rates or d'
%values (y) as a function of the value of a user-specified variable (x).
%
%Inputs:
%
%   handles: GUI handles structure
%   variables: matrix of trial information
%   HITind: logical index vector for HIT responses
%   GOind: numerical (non-logical) index vector for GO trials
%   REMINDind: numerical (non-logical) index vector for REMINDER trials
%
%Written by ML Caras 7.28.2016

global ROVED_PARAMS

%Only continue if at least one GO trial has been completed
if isempty(GOind)
    return
end

%Compile data into a matrix.
currentdata = [variables,HITind];

%If user wants to exclude reminder trials...
if get(handles.PlotRemind,'Value') == 0
    currentdata(REMINDind,:) = [];
    TrialTypeInd = SanesLab_findCol(ROVED_PARAMS,'TrialType',handles);
    TrialType = currentdata(:,TrialTypeInd);
    GOind = find(TrialType == 0);
end

%Only continue if there are data to analyze
if isempty(currentdata)
    return
end

%Select out just the GO trials
GOtrials = currentdata(GOind,:);

%Determine the variable to plot on the x axis
x_ind = get(handles.Xaxis,'Value');
x_strings = get(handles.Xaxis,'String');


%Find the column index for the xaxis variable of interest
col_ind = SanesLab_findCol(ROVED_PARAMS,x_strings{x_ind},handles);

%Does the user want to group the data by a particular variable?
grpstr = get(handles.group_plot,'String');
grpval = get(handles.group_plot,'Value');

switch grpstr{grpval}
    
    %If user does not want grouping...
    case 'None'
        
        %Calculate hit rate for each value of the parameter of interest
        vals = unique(GOtrials(:,col_ind));
        plotting_data = [];
        
        for i = 1: numel(vals)
            val_data = GOtrials(GOtrials(:,col_ind) == vals(i),:);
            hit_rate = 100*(sum(val_data(:,end))/numel(val_data(:,end)));
            plotting_data = [plotting_data;vals(i),hit_rate,str2num(get(handles.FArate,'String'))];
        end
        
        %If the user does want grouping...
    otherwise
        
        %Find the column index for the grouping variable of interest
        grp_ind = SanesLab_findCol(ROVED_PARAMS,grpstr(grpval),handles);
        
        %Find the groups
        grps = unique(GOtrials(:,grp_ind));
        
        %Find the FA values for each group separately
        flds = fieldnames(handles);
        idx = ~cellfun('isempty',strfind(flds,'FArate'));
        flds = flds(idx);
        FAs = [];
        
        for i = 1:numel(flds)
            FArate = str2num(get(handles.(flds{i}),'String')); %#ok<*ST2NM>
            
            if isempty(FArate)
                FArate = 0;
            end
            FAs = [FAs,FArate];
            
        end
        
        plotting_data = [];
        
        %For each group
        for i = 1:numel(grps)
            
            %Pull out the group data
            grp_data = GOtrials(GOtrials(:,grp_ind) == grps(i),:);
            vals = unique(grp_data(:,col_ind));
            
            
            for j = 1:numel(vals)
                val_data = grp_data(grp_data(:,col_ind) == vals(j),:);
                hit_rate = 100*(sum(val_data(:,end))/numel(val_data(:,end)));
                plotting_data = [plotting_data;vals(j),hit_rate,FAs(i),grps(i)];
            end
                %kp: if grouping requested before all types of nogos
                %called, line 110 throws error. 
            
            
        end
end

%Only continue if there are data to plot
if isempty(plotting_data)
    return
end

%Get values again, to make sure x axis shows all datapoints
vals = unique(GOtrials(:,col_ind));

%Set up the x text
switch x_strings{x_ind}
    case 'dB SPL'
        xtext = 'Sound Level (dB SPL)';
    case {'Freq','Freq1','Freq2'}
        xtext = 'Sound Frequency (Hz)';
    case 'Stim_duration'
        xtext = 'Sound duration (s)';
    case 'FMdepth'
        xtext = 'FM depth (%)';
        plotting_data(:,1) = plotting_data(:,1)*100; %percent
        vals = vals*100; %percent
    case 'FMrate'
        xtext = 'FM rate (Hz)';
    case 'AMdepth'
        xtext = 'AM depth (%)';
        plotting_data(:,1) = plotting_data(:,1)*100; %percent
        vals = vals*100; %percent
    case 'AMrate'
        xtext = 'AM rate (Hz)';
    otherwise
        xtext = '';
end


%Determine if we need to plot hit rate or d prime
y_ind = get(handles.Yaxis,'Value');
y_strings = get(handles.Yaxis,'String');

switch y_strings{y_ind}
    
    %If we want to plot hit rate, we just need to format the plot
    case 'Hit Rate'
        
        ylimits = [0 100];
        ytext = 'Hit rate (%)';
        
        %If we want to plot d', we need to do some calculations and format the plot
    case 'd'''
        
        ylimits = [0 3.5];
        ytext = 'd''';
        
        %Convert back to proportions
        plotting_data(:,2) = plotting_data(:,2)/100;
        plotting_data(:,3) = plotting_data(:,3)/100;
        
        %Set bounds for hit rate and FA rate (5-95%)
        %Setting bounds prevents d' values of -Inf and Inf from occurring
        plotting_data(plotting_data(:,2) < 0.05,2) = 0.05;
        plotting_data(plotting_data(:,2) > 0.95,2) = 0.95;
        plotting_data(plotting_data(:,3) < 0.05,3) = 0.05;
        plotting_data(plotting_data(:,3) > 0.95,3) = 0.95;
        
        %Covert proportions into z scores
        z_fa = sqrt(2)*erfinv(2*plotting_data(:,3)-1);
        z_hit = sqrt(2)*erfinv(2*plotting_data(:,2)- 1);
        
        %Calculate d prime
        plotting_data(:,2) = z_hit - z_fa;
end


%Clear and reset scale
ax = handles.IOPlot;
hold(ax,'off');
cla(ax)
legend(ax,'hide');

xmin = min(vals)-(0.1*(min(vals)));
xmax = max(vals)+(0.1*(max(vals)));

if xmin == xmax
    xmin = min(vals) - 1;
    xmax = max(vals) + 1;
end

%If no grouping variable is applied
switch grpstr{grpval}
    case 'None'
        
        plot(ax,plotting_data(:,1),plotting_data(:,2),'rs-','linewidth',2,...
            'markerfacecolor','r')
        
        %Otherwise, group data and plot accordingly
    otherwise
        legendhandles = [];
        legendtext = {};
        clrmap = jet(numel(grps));
        
        for i = 1:numel(grps)
            clr = clrmap(i,:);
            
            grouped = plotting_data(plotting_data(:,4) == grps(i),:);
            hp = plot(ax,grouped(:,1),grouped(:,2),'s-','linewidth',2,...
                'markerfacecolor',clr,'color',clr);
            hold(ax,'on');
            
            legendhandles = [legendhandles;hp]; %#ok<*AGROW>
            legendtext{i} = [grpstr{grpval},' ', num2str(grps(i))];
        end
        
        l = legend(legendhandles,legendtext);
        set(l,'location','southeast')
        
        
end


%Format plot
set(ax,'ylim',ylimits,'xlim',[xmin xmax],'xgrid','on','ygrid','on');
xlabel(ax,xtext,'FontSize',12,'FontName','Arial','FontWeight','Bold')
ylabel(ax,ytext,'FontSize',12,'FontName','Arial','FontWeight','Bold')

%Adjust plot formatting for specific cases
switch x_strings{x_ind}
    
    case 'TrialType'
        set(ax,'XLim',[-1 1])
        set(ax,'XTick',0);
        set(ax,'XTickLabel',{'GO Trials'})
        set(ax,'FontSize',12,'FontWeight','Bold')
        
    case 'FMdepth'
        set(ax,'XLim',[-0.2 0.2])
        set(ax,'XTick',-0.2:0.1:0.2);
        
    case {'Freq','Freq1','Freq2'}
        set(ax,'XScale','log')
        set(ax,'XTick',[1000 2000 4000 8000 16000]);
        
    case 'Expected'
        set(ax,'XLim',[-1 2])
        set(ax,'XTick',[0 1]);
        set(ax,'XTickLabel',{'Unexpected' 'Expected'})
        set(ax,'FontSize',12,'FontWeight','Bold')
end







