function C = TrialFcn_CheckerFlip(C)
% C = TrialFcn_CheckerFlip(C)
%
% Flip checkerboard pattern.
%
% Uses the Psychtoolbox
%
% Daniel.Stolzberg@gmail.com 2015


persistent win w ScreenRect black white




if C.tidx == 1
%     Screen('Preference','SkipSyncTests', true);
    
    win = 3;
    w = Screen('OpenWindow',win, 128);
    ScreenRect=Screen('Rect',w);

    black = BlackIndex(w);
    white = WhiteIndex(w);
end

if C.FINISHED || C.HALTED
    Screen('CloseAll');
    return
end



% Create a new chckerboard based on the current stimulus parameters
numChks = SelectTrial(C,'Stim.NumCheckers');

chksize = round(ScreenRect(3)/(numChks*2));

% Reverse the checkerboard on each presentation
if mod(C.tidx,2)
    chk = [ones(chksize,'uint8') zeros(chksize,'uint8')];
else
    chk = [zeros(chksize,'uint8') ones(chksize,'uint8')];
end

Check = repmat([chk; fliplr(chk)],numChks,numChks);

Check = Check * white;
Check(~Check) = Check(~Check) * black;

CheckTex = Screen('MakeTexture',w,Check);





% Show the checker board with a photodiode marker
Screen('DrawTexture',w,CheckTex);
PhotodiodeMarker(w,true);
vbl = Screen('Flip',w);



% Maintain the checkerboard and turn off photodiode marker
% ... for some reason, the 'dontclear' flag is not working in
% Screen('Flip', ...), so just redraw the same checker board
Screen('DrawTexture',w,CheckTex);
PhotodiodeMarker(w,false);
Screen('Flip',w,vbl+0.1);














