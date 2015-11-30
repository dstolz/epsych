function C = TrialFcn_Gabor(C)
% Create a parameterised Gabor grating using the function "Gabor" and
% Psychtoolbox

persistent win w vbl

if C.tidx == 1
%     Screen('Preference','SkipSyncTests', true);
    
    win = 3;
    w=Screen('OpenWindow',win, 128);
    
    vbl = [];
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




if numel(C.OPTIONS.ISI) == 2
    ISI = round(C.OPTIONS.ISI(1)+diff(C.OPTIONS.ISI)*rand(1))/1000;
else
    ISI = C.OPTIONS.ISI/1000;
end

startvbl = vbl+ISI-0.007; % -0.007 is an emperically derived value
vbl = Gabor(Ang,Rate,Freq,Contrast,xPos,yPos,Gausswidth,Dur,startvbl);

PhotodiodeMarker(w,false);
Screen('Flip',w);
