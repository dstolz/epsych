%% Simple Whole-Screen Flash
% 
% Daniel.Stolzberg@gmail.com 2016


FlashDur = 0.1; % flash duration (seconds)
ITI = 2; % inter-trigger interval (seconds)
FlashOnColor = 1;   % flash intensity [0 1]
FlashOffColor = 0;   % flash intensity [0 1]
NFlashes = 20; % number of flashes

[window,ScreenRect,frameRate] = PTB_NormalExpt_Startup(0,1);

fprintf(2,'\n\n**********\nStarting Whole Screen Flash at %s\n',datestr(now))

Screen('FillRect',window,FlashOffColor);
vbl = Screen('Flip', window);

for i = 1:NFlashes
    BitsTrigger(window,vbl+ITI);
    
    Screen('FillRect',window,FlashOnColor);
    vbl = Screen('Flip',window,vbl+ITI);
    
    Screen('FillRect',window,FlashOffColor);
    Screen('Flip',window,vbl+FlashDur);
    
end

fprintf(2,'Finished at %s\n**********\n\n',datestr(now))
sca