function handles = updateFArate_SanesLab(handles,variables,FAind,NOGOind,f)
%handles = updateFArate_SanesLab(handles,variables,FAind,NOGOind,f)
%
%Custom function for SanesLab epsych
%
%This function calculates and displays the FA rate. FA rate can be
%calculated for individual NOGO trial types separately, or as an aggregate,
%as determined by the GUI "grouping variable" option.
%
%Inputs:
%   handles: GUI handles structure
%   variables: matrix containing roved parameter information for each trial
%   FAind: logical index vector for FAs
%   NOGOind: numerical indices (non logical) for NOGO trials
%   f: handle for the gui figure
%
%Written by ML Caras 7.27.2016

global ROVED_PARAMS

%Find the current handles containing FA text data
FA_handles = [];
flds = fieldnames(handles);
idx = ~cellfun('isempty',strfind(flds,'FArate'));
flds = flds(idx);

for i = 1:numel(flds)
    FA_handles = [FA_handles,handles.(flds{i})]; %#ok<*AGROW>
end


%Compile data into a matrix
currentdata = [variables,FAind];

%Select out just the NOGO trials
NOGOtrials = currentdata(NOGOind,:);

%Determine if the user is plotting the data as a whole, or grouped by
%variables
grpstr = get(handles.group_plot,'String');
grpval = get(handles.group_plot,'Value');

%If plotting as a whole...
switch grpstr{grpval}
    case 'None'
        
        %If at least one NOGO trial has been completed...
        if ~isempty(NOGOtrials)
            
            %Calculate the overall FA rate
            FArate = 100*(sum(NOGOtrials(:,end))/numel(NOGOtrials(:,end)));
            
            %Scroll through each FA text handle
            for i = 1:numel(FA_handles)
                
                %If it's the first one...
                if i == 1
                    
                    %Set the text and color
                    set(FA_handles(i),'String', sprintf( '%0.2f',FArate));
                    set(FA_handles(i),'ForegroundColor',[1 0 0]);
                
                %Otherwise...
                else
                    
                    %Empty the text
                    set(FA_handles(i),'String','');
                    
                end
            end
            
        %If no NOGO trials have been completed...    
        else
            %Collect the FA rate from the GUI (it's just 0.00).
            FArate = str2num(get(FA_handles(1),'String')); %#ok<ST2NM,*NASGU>
        end
        
   
    %If plotting is grouped by a variable, calculate a separate FA rate for
    %each NOGO type, if applicable.
    otherwise
        
        %Find the column index for the grouping variable of interest
        grp_ind = SanesLab_findCol(ROVED_PARAMS,grpstr(grpval),handles);
      
        %Find the groups
        grps = unique(NOGOtrials(:,grp_ind));
        
        %Set the starting text position and color map
        x = 0.095; y = 0.5; width = 0.821; height = 0.362;
        clrmap = jet(numel(grps));
        
        %For each group...
        for i = 1:numel(grps)
            
            %Define our target
            if i == 1
                target = 'FArate';
            else
                target = ['FArate' num2str(i)];
            end
            
            %If text handle has not already been created for the group
            if ~isfield(handles,target)
                
                %Adjust y position
                y = y-0.5;
                
                %Create new text handle
                p = uicontrol(f,'Style','text','String','','FontName','Arial',...
                    'FontSize',[16],'FontWeight','bold',...
                    'Units','normalized','SelectionHighlight','off',...
                    'Tag',target);
                handles.(target) = p;
                set(handles.(target),'Parent',handles.FApanel,...
                    'Position',[x y width height]);
                
                %Update the FA handle vector
                FA_handles = [FA_handles, handles.(target)];
            end
            
        end
        
     
        %Now that we have all of our FA handles...
        for i = 1:numel(FA_handles)
            
            %Let's format them:
            %If there is more than one group, each FA is colored separately
            if numel(grps)>1
                clr = clrmap(i,:);
                set(FA_handles(i),'ForegroundColor',clr);
                
            %If there is only one group...
            else
                %The first handle gets colored red...
                if i == 1
                    set(FA_handles(i),'ForegroundColor',[1 0 0]);
                    
                %Remaining handle texts are emptied
                else
                    set(FA_handles(i),'String','');
                end
            end
        end
        
        %Finally, let's calculate the FA rates and display them
        for i = 1:numel(grps)
            %Pull out the group data
            grp_data = NOGOtrials(NOGOtrials(:,grp_ind) == grps(i),:);
            
            %Calculate each FA rate separately
            if ~isempty(grp_data)
                FArate = 100*(sum(grp_data(:,end))/numel(grp_data(:,end)));
                set(FA_handles(i),'String', sprintf( '%0.2f',FArate));
            else
                FArate = str2num(get(FA_handles(i),'String')); %#ok<ST2NM>
            end

        end
        
end

%Update GUI handles
guidata(f,handles)

