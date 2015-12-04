function C = TrialFcn_BarSweep(C)
% C = TrialFcn_BarSweep(C)
% 
% For use with EPhysController experiments
% 
% Uses Psychtoolbox to generate light bar sweeps across a monitor
% 
% 

persistent PresWin ScreenRect ifi

% angle; rate; contrast; barwidth; monitorID

ind = strcmp('Stim.angle',     C.writeparams);
angle = C.trials{C.tidx,ind};
ind = strcmp('Stim.rate',      C.writeparams);
rate = C.trials{C.tidx,ind};
ind = strcmp('Stim.*contrast',  C.writeparams);
contrast = C.trials{C.tidx,ind};
ind = strcmp('Stim.*barwidth',  C.writeparams);
barwidth = C.trials{C.tidx,ind};


if C.tidx == 1
    %     Screen('Preference', 'SkipSyncTests', 1)
    %     ScreenNum=2; %Assigns screen number for stim presentation
    ind = strcmp('Stim.*monitorid', C.writeparams);
    ScreenNum = C.trials{C.tidx,ind};
    %Screen('CloseAll');
    [PresWin, ScreenRect]=Screen('OpenWindow',ScreenNum, 128); %Opens a grey(128) window
    ifi=Screen('GetFlipInterval', PresWin);%Query duration of one monitor refresh interval:
    priorityLevel=MaxPriority(PresWin);
    Priority(priorityLevel);
    Screen('BlendFunction', PresWin, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    pause(5);
end

if C.FINISHED || C.HALTED
    %h = msgbox('Please wait ... Closing Psychtoolbox Screen','EPhys','help','modal');
    %pause(3);
    %Screen('CloseAll');
    %clear Screen
    %close(h);
    return
end





Bar=ones(ScreenRect(3))*(127*contrast/100 + 128);%Creates a white bar
BarTex=Screen('MakeTexture', PresWin, Bar); %Creates a texture from Bar

ShiftPerFrame= rate * ifi;% Translate bar speed into a shift value in "pixels per frame"


xplaneshift=cosd(angle)*ShiftPerFrame;%Calculates the horizontal shift
yplaneshift=sind(angle)*ShiftPerFrame;%Calculates the vertical shift

PresDiam=ScreenRect(4);
barlength=ScreenRect(3);

MaskDiam=ScreenRect(3);
MaskRad=(MaskDiam)/2;
mask=ones(MaskDiam+1, MaskDiam+1, 2) * 128;
[x,y]=meshgrid(-1*MaskRad:MaskRad,-1*MaskRad:MaskRad);
gausswidth=PresDiam/3;
mask(:, :, 2)=255 * (1 - exp(-((x/gausswidth).^2)-((y/gausswidth).^2)));
matrixmid=ceil(size(mask,1)/2);
maskcutoff=mask(matrixmid,matrixmid-0.5*PresDiam,2);
mask2 = mask(:,:,2);
mask2(mask2>maskcutoff) = 255;
mask(:,:,2) = mask2;

MaskTex=Screen('MakeTexture', PresWin, mask);

xstart=(ScreenRect(3)/2-barwidth)-ceil(cosd(angle)*PresDiam/2);
xend=xstart+barwidth;
ystart=(ScreenRect(4)/2-barlength/2)-ceil(sind(angle)*PresDiam/2);
yend=ystart+barlength;
PresDur=(PresDiam+barwidth)/rate;


% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp as timing baseline for our redraw loop:
vbl=Screen('Flip', PresWin);
vblendtime = vbl + PresDur;


i=0;
while(vbl<vblendtime)
    xoffset =(i*xplaneshift);%Indexes the horizontal shift across the screen
    yoffset =(i*yplaneshift);%Indexes the vertical shift down the screen
    
    Screen('DrawTexture', PresWin, BarTex,[0 0 barwidth barlength], ...
        [xstart+xoffset ystart+yoffset xend+xoffset yend+yoffset],angle);
    Screen('DrawTexture', PresWin, MaskTex,[],[]);
    i=i+1;
    PhotodiodeMarker(PresWin,true);
    vbl=Screen('Flip', PresWin, vbl+(0.5)*ifi);
end
PhotodiodeMarker(PresWin,false);
Screen('Flip',PresWin);





