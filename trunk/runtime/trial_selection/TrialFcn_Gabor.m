function C = TrialFcn_Gabor(C)

persistent win w winRect

if C.tidx == 1
    win = 2;
    w=Screen('OpenWindow',win, 128);
    winRect = Screen('Rect',w);
%     Screen('Preference','SkipSyncTests', true);
end


if C.FINISHED || C.HALTED
    Screen('CloseAll');
    return
end


Ang = SelectTrial(C,'Stim.Angle');
Rate = SelectTrial (C, 'Stim.Rate');
Freq = SelectTrial (C, 'Stim.Frequency');
Contrast = SelectTrial (C, 'Stim.Contrast');
xPos = SelectTrial (C, 'Stim.xPosition');
yPos = SelectTrial (C, 'Stim.yPosition');
Gausswidth = SelectTrial (C, 'Stim.GaussWidth');
Dur = SelectTrial(C,'Stim.Duration');

PhotodiodeMarker(w,true);
Gabor(Ang,Rate,Freq,Contrast,xPos,yPos,Gausswidth,Dur);


