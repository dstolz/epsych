function C = TrialFcn_TemporalSlewingPTB(C)
% C = TrialFcn_TemporalSlewingPTB(C)
%
% Noise/Flash temporal slewing.  Uses the PhotodiodeMarker to initiate a
% 'trial'.  TDT generates noise stimulus with some specified delay
% following photodiode onset.  PTB generates a screen flash at a specified
% delay.
%
% Stim.FlashOnset     -  in milliseconds
% Stim.FlashDuration  -  in milliseconds
% Stim.FlashLuminance -  percentage between 0 and 1
% 
% Should test thoroughly for consistency in timing.
%
% Uses the Psychtoolbox
%
% Daniel.Stolzberg@gmail.com 2015


persistent win w ScreenRect black white vbl




if C.tidx == 1
%     Screen('Preference','SkipSyncTests', true);
    
    win = 3;
    w = Screen('OpenWindow',win, 0);
    ScreenRect=Screen('Rect',w);
    
    black = BlackIndex(w);
    white = WhiteIndex(w);
    
    vbl = [];
end

if C.FINISHED || C.HALTED
    Screen('close');
    Screen('CloseAll');
    return
end



FlashOnset     = SelectTrial(C,'Stim.FlashOnset');    % in milliseconds
FlashDuration  = SelectTrial(C,'Stim.FlashDuration'); % in milliseconds
FlashLuminance = SelectTrial(C,'Stim.Luminance');     % between 0 and 1




if numel(C.OPTIONS.ISI) == 2
    ISI = round(C.OPTIONS.ISI(1)+diff(C.OPTIONS.ISI)*rand(1))/1000;
else
    ISI = C.OPTIONS.ISI/1000;
end

% indicates the beginning of a trial
PhotodiodeMarker(w,true);
vbl = Screen('Flip',w,vbl + ISI - 0.007);  % -0.007 is an empirically derived offset value


% full screen flash at specified delay
FlashTex = Screen('MakeTexture',w,FlashLuminance*white*ones(ScreenRect([4 3]),'uint8'));
Screen('DrawTexture',w,FlashTex);
vbl1 = Screen('Flip',w,vbl+FlashOnset/1000);


% set screen to black
BlackTex = Screen('MakeTexture',w,black*ones(ScreenRect([4 3]),'uint8'));
Screen('DrawTexture',w,BlackTex);
Screen('Flip',w,vbl1+FlashDuration/1000);


% turn off photodiode after completing the trial
Screen('DrawTexture',w,BlackTex);
PhotodiodeMarker(w,false);
Screen('Flip',w);





































