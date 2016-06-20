function [thresh, reject] = calculate_thresholds( Phys, segment_length_s )
%  [thresh, reject] = calculate_thresholds( Phys, trial_length_s )
%    Called by pp_sort_session. Launches a gui in which a random trial is
%    selected and filtered Phys data is displayed for 4 channels at a time.
%    Waits for user input, to designate trial as clean or to skip to next
%    random trial. Once a sufficient amount of data has been designated
%    "clean" for each channel, thresholds for spike event detection and
%    artifact rejection are calculated based on the std of data, for each
%    channel.
%  
%  KP, 2016-04; last updated 2016-04
% 


set(0,'DefaultAxesFontSize',14)

% Button callback function
    function buttonCallback(newVal)
        user_choice = newVal;
    end



%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Set up figure

f=figure;
scrsz = get(0,'ScreenSize');
set(f,'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
ax = axes('Parent',f,'position',[0.05 0.2 0.9 0.75]);

% Create push buttons
cln = uicontrol('Style', 'pushbutton', 'String', 'Clean',...
    'Units', 'normalized', ...
    'Position', [0.25 0.05 0.15 0.1],...
    'BackgroundColor', [0 0.8 0], ...
    'FontSize', 24, ...
    'FontWeight', 'bold', ...
    'Callback', @(src,evnt)buttonCallback(1) ) ;

nxt = uicontrol('Style', 'pushbutton', 'String', 'Next',...
    'Units', 'normalized', ...
    'Position', [0.6 0.05 0.15 0.1],...
    'BackgroundColor', [0.8 0 0], ...
    'FontSize', 24, ...
    'FontWeight', 'bold', ...
    'Callback', @(src,evnt)buttonCallback(2)) ;

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


all_clean=[];
ntrials = floor(16 / segment_length_s);   % need ~16 s of clean data

for channel = [1 5 9 13]
    
    clean_trials = nan(4,ntrials);
    nchosen = 0;
    user_choice = 0;
    
    
    
    % Cycle through trials, user selects clean ones
    
    rng('shuffle')
    for it = randperm(size(Phys,1))
        
        % Plot data from randomly selected trial
        
        cla(ax); hold on
        for isp = 1:4
            plot( Phys(it,:,channel-1+isp) + (isp*8)*10^-4 ,'Color',[0.4 0.4 0.4])
        end
        set(gca, 'XTick',[], 'YTick',[])
        title([ num2str(nchosen) ' / ' num2str(ntrials) ' clean trials chosen so far  (channels ' num2str(channel) ' - ' num2str(channel+3) ')' ])
        
        
        
        % Wait for user to skip to next channel or label it clean
        
        while user_choice==0
            pause(0.5);
        end
        
        switch user_choice
            case 1 %clean
                nchosen = nchosen+1;
                clean_trials(:,nchosen) = it;
                user_choice = 0;
                if nchosen<ntrials
                    continue
                else
                    fprintf('  %i clean trials gathered for chs %i-%i\n',ntrials, channel, channel+3)
                    break
                end
                
            case 2 % next
                user_choice = 0;
                continue
                
        end
        
    end
    
    all_clean = [all_clean; clean_trials];
    
end

% Calculate std and thresholds for each trial
for ich = 1:size(Phys,3)
    std_cln(1,ich) = mean(std(Phys( all_clean(ich,:) ,:,ich),0,2));
        
end

thresh = std_cln .*  -4 ;
reject = std_cln .* -20 ;

close(f);



% Check that thresholds make sense by plotting with clean traces

% for ich = 1:2:15
%     figure;
%     scrsz = get(0,'ScreenSize');
%     set(f,'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
%     for isp = 1:2
%         plot_tr = all_clean(ich,randi(size(all_clean,2)));
%         plot( Phys(plot_tr,:,ich-1+isp) + (isp*8)*10^-4 ,'Color',[0.4 0.4 0.4])
%         hold on
%         plot([0 size(Phys,2)], [(thresh(ich-1+isp) + (isp*8)*10^-4) (thresh(ich-1+isp) + (isp*8)*10^-4)], ':', 'Color', [0 0.7 0], 'LineWidth',3)
%         plot([0 size(Phys,2)], [(reject(ich-1+isp) + (isp*8)*10^-4) (reject(ich-1+isp) + (isp*8)*10^-4)], ':', 'Color', [0.7 0 0], 'LineWidth',3)
% 
%     end    
%     title([ 'Check thresholds for channels ' num2str(ich) ' & ' num2str(ich+1) ])
% end
% 
% keyboard




end









