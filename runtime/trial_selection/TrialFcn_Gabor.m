function C = TrialFcn_Gabor(C)
% Create a parameterised Gabor grating using the function "Gabor" and
% Psychtoolbox

persistent win w

if C.tidx == 1
%     Screen('Preference','SkipSyncTests', true);
    
    win = 3;
    w=Screen('OpenWindow',win, 128);
    
end


if C.FINISHED || C.HALTED
    Screen('CloseAll');
    return
end


Ang         = SelectTrial(C,'Stim.Angle');
Rate        = SelectTrial(C,'Stim.Rate');
Freq        = SelectTrial(C,'Stim.Frequency');
Contrast    = SelectTrial(C,'Stim.Contrast');
xPos        = SelectTrial(C,'Stim.xPosition');
yPos        = SelectTrial(C,'Stim.yPosition');
Gausswidth  = SelectTrial(C,'Stim.GaussWidth');
Dur         = SelectTrial(C,'Stim.Duration');

Gabor(Ang,Rate,Freq,Contrast,xPos,yPos,Gausswidth,Dur);

PhotodiodeMarker(w,false);
Screen('Flip',w);
