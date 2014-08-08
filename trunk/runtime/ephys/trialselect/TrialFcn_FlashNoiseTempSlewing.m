function C = TrialFcn_FlashNoiseTempSlewing(C)
% EPhys Trial-Select Function for Flash/Noise Temporal Slewing
%
% Daniel.Stolzberg@gmail.com 2014

persistent win w winRect

if C.tidx == 1
    win = 2;
    w=Screen('OpenWindow',win, 0);
    winRect = Screen('Rect',w);
end


if C.FINISHED || C.HALTED
    h = msgbox('Please wait ... Closing Psychtoolbox Screen','EPhys','help','modal');
    pause(3);
    Screen('CloseAll');
    clear Screen
    close(h);
    return
end



timing_adjustment = -0.01;



ind = strcmp('Stim.*FlashDur',C.writeparams);
FlashDur = C.trials{C.tidx,ind} / 1000; % ms -> s

ind = strcmp('Stim.*FlashDelay',C.writeparams);
FlashDelay = C.trials{C.tidx,ind} / 1000; % ms -> s

ind = strcmp('Stim.Flash_Level',C.writeparams);
FlashLevel = C.trials{C.tidx,ind};

% Flash on
Screen('FillRect',w,FlashLevel,winRect);
PhotodiodeMarker(w,true);
Screen('Flip',w,C.EXPT.NextTriggerTime+FlashDelay);

% Flash off
Screen('FillRect',w,0,winRect);
PhotodiodeMarker(w,false);
Screen('Flip',w,C.EXPT.NextTriggerTime+FlashDelay+FlashDur);




