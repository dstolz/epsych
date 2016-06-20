%% Simple Whole-Screen Flash
% 
% Daniel.Stolzberg@gmail.com 2016

% Modifiable Parameters
FlashDur      = [0.5]; % flash duration (seconds)
ITI           = [2 5]; % inter-trigger interval (seconds)
FlashOnColor  = 1;   % flash intensity [0 1]
FlashOffColor = 0;   % flash intensity [0 1]
NFlashes      = 100; % number of flashes


allFlashDurs = repmat(FlashDur(:),1,NFlashes);
allFlashDurs = allFlashDurs(randperm(numel(allFlashDurs)));



rITI = ITI(1)+rand(length(allFlashDurs),1)*diff(ITI);

% Run basic startup
[window,ScreenRect,frameRate] = PTB_NormalExpt_Startup(0,1);

fprintf(2,'\n\n**********\nStarting Whole Screen Flash at %s\n',datestr(now))


% Blank out screen to off color
Screen('FillRect',window,FlashOffColor);
vbl = Screen('Flip', window);

% Wait some period before begining stimulus presentation
WaitSecs(30);

% Create first timestamp
vbl = Screen('Flip', window);

for i = 1:length(allFlashDurs)
    
    % Prepare Flash onset trigger
    BitsTrigger(window,vbl+rITI(i));
    
    % Turn Flash on
    Screen('FillRect',window,FlashOnColor);
    vbl = Screen('Flip',window,vbl+rITI(i));
    
    % Prepare Flash offset trigger
    BitsTrigger(window,vbl+allFlashDurs(i));
    
    % Turn Flash off
    Screen('FillRect',window,FlashOffColor);
    Screen('Flip',window,vbl+allFlashDurs(i));
    
end

fprintf(2,'Finished at %s\n**********\n\n',datestr(now))
sca










