function C = TrialFcn_TemporalSlewingPTB(C)
% C = TrialFcn_TemporalSlewingPTB(C)
%
% Noise/Flash temporal slewing.  Uses the PhotodiodeMarker to initiate a
% 'trial'.  TDT generates noise stimulus with some specified delay
% following photodiode onset.  PTB generates a screen flash at a specified
% delay.
%
% Should test thoroughly for consistency in timing.
%
% Uses the Psychtoolbox
%
% Daniel.Stolzberg@gmail.com 2015


persistent win w ScreenRect black white




if C.tidx == 1
%     Screen('Preference','SkipSyncTests', true);
    
    win = 3;
    w = Screen('OpenWindow',win, 0);
    ScreenRect=Screen('Rect',w);
    
    black = BlackIndex(w);
    white = WhiteIndex(w);
end

if C.FINISHED || C.HALTED
    Screen('CloseAll');
    return
end



FlashOnset     = SelectTrial(C,'Stim.FlashOnset'); % in milliseconds
FlashDuration  = SelectTrial(C,'Stim.FlashDuration'); % in milliseconds
FlashLuminance = SelectTrial(C,'Stim.Luminance'); % between 0 and 1


% indicates the beginning of a trial
PhotodiodeMarker(w,true);
vbl1 = Screen('Flip',w);



% full screen flash at specified delay
FlashTex = Screen('MakeTexture',w,FlashLuminance*white*ones(ScreenRect([4 3]),'uint8'));
Screen('DrawTexture',w,FlashTex);
vbl = Screen('Flip',w,vbl1+FlashOnset/1000);


% set screen to black
FlashTex = Screen('MakeTexture',w,black*ones(ScreenRect([4 3]),'uint8'));
Screen('DrawTexture',w,FlashTex);
Screen('Flip',w,vbl+FlashDuration/1000);


% turn off photodiode after completing the trial
Screen('DrawTexture',w,FlashTex);
PhotodiodeMarker(w,false);
Screen('Flip',w,vbl1+0.5); % 





































