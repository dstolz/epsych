%% Noise-Flash Temporal Slewing
% 
% Daniel.Stolzberg@gmail.com 2016

sca



FlashDur     = 0.1; % flash duration (seconds)
ITI          = 2; % inter-trigger interval (seconds)
FlashOnColor = 1;   % flash intensity [0 1]
FlashOffColor = 0;   % flash intensity [0 1]
NFlashes      = 425; % number of flashes
FlashDelay    = 0.2;


[window,ScreenRect,frameRate] = PTB_NormalExpt_Startup(0,1);

IFI = 1/frameRate;

fprintf(2,'\n\n**********\nStarting Noise-Flash Temporal Slewing at %s\n',datestr(now))

Screen('FillRect',window,FlashOffColor);
vbl = Screen('Flip', window);

WaitSecs(5);

for i = 1:NFlashes
    BitsTrigger(window,vbl+ITI);
    tvbl = Screen('Flip',window); % trigger indicates start of trial
    
    
    
    Screen('FillRect',window,FlashOnColor);
    
     % NOTE: I had to subtract one frame from the actual intended flip time
     % for this to line up.  Otherwise, the timing was ~1 frame off every
     % time.  DJS
    BitsTrigger(window,tvbl+FlashDelay-IFI);   
    vbl = Screen('Flip',window,tvbl+FlashDelay-IFI);
    

    Screen('FillRect',window,FlashOffColor);
    BitsTrigger(window,vbl+FlashDur-IFI);
    Screen('Flip',window,vbl+FlashDur-IFI);
    
end

fprintf(2,'Finished at %s\n**********\n\n',datestr(now))
sca























