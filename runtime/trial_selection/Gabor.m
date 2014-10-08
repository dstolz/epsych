function Gabor(angle, rate, freq, contrast, xpos, ypos, gausswidth, PresDur)
%Gabor(angle, rate, freq, contrast, xpos, ypos, gausswidth, PresDur)
% 
%Gabor Function
%This function is designed to present a moving gabor pattern on a display.
%The user can define the angle of motion, the rate, spatial frequency, and
%contrast of the grating as well as the coordinates of the centre and width
%of the gaussian filter.
%
%Optional parameters:
%
% angle = Angle of the grating with respect to the vertical direction (deg)
% rate = Speed of grating in cycles per second. (e.g. 10)
% freq = Frequency of grating in cycles per pixel (e.g. 0.05)
% contrast = Stimulus contrast in %
% xpos = x-axis position of mask centre in %
% ypos = y-axis position of mask centre in %
% gausswidth = width of the gaussian filter in pixels
% PresDur = Duration of presentation in seconds
% 
% Blake Butler 2014

if nargin ~= 8
    error(sprintf(['One or more required inputs are missing.\n'...
    '(angle, rate, freq, contrast, xpos, ypos, gausswidth,PresDur)']))
end
   
%ScreenNum=2; %Assigns screen number for stim presentation
%PresDur=5; %Makes a 5 sec movie
%[PresWin, ScreenRect]=Screen('OpenWindow',ScreenNum, 128); %Opens a grey(128) window
PresWin=Screen('Windows'); PresWin = PresWin(1);
ScreenRect=Screen('Rect',2);
GratingSize=ceil(sqrt(ScreenRect(3)^2+ScreenRect(4)^2)); %Sets GratingSize to the diagonal length of screen
HalfGrating=GratingSize/2;

inc=contrast/100*(255-128); % Contrast 'inc'rement range for given white and gray values:
Screen('BlendFunction', PresWin, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);	

PixSec=ceil(1/freq); %Calculate rate in pixel/sec, rounded to nearest full pixel
FreqRad=freq*2*pi; %Calculate frequency in radians: 

%We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
%define the whole grating! However it does need 2 * HalfGrating + PixSec columns, i.e. the visible size
%of the grating extended by the length of 1 period (repetition) of the sine-wave in pixels 'PixSec':

x = meshgrid(-HalfGrating:HalfGrating + PixSec, 1);
Grating=128 + inc*cos(FreqRad*x); %Compute actual cosine grating:   
GratingTex=Screen('MakeTexture', PresWin, Grating); %Store 1-D single row grating in texture:


% Create a single gaussian transparency mask and store it to a texture:
% We create a  two-layer texture: One unused luminance channel which we
% just fill with the same color as the background color of the screen
% 'gray'. The transparency (aka alpha) channel is filled with a
% gaussian (exp()) aperture mask:

mask=ones(GratingSize+1, GratingSize+1, 2) * 128;
[x,y]=meshgrid(-1*HalfGrating:HalfGrating,-1*HalfGrating:HalfGrating);

mask(:, :, 2)=255 * (1 - exp(-((x/gausswidth).^2)-((y/gausswidth).^2)));
MaskTex=Screen('MakeTexture', PresWin, mask);

priorityLevel=MaxPriority(PresWin);
Priority(priorityLevel);

VisibleSize=GratingSize+1; 
MaskSize=GratingSize+0.5*ScreenRect(3);%Ensures mask will cover grating at screen limits
dstRect=[0 0 MaskSize MaskSize];%Makes rectangle the size of the grating
dstRect=CenterRectOnPoint(dstRect, xpos*ScreenRect(3)/100, ypos*ScreenRect(4)/100);%Centres on a point given by user

ifi=Screen('GetFlipInterval', PresWin);%Query duration of one monitor refresh interval:
PixSec=1/freq;% Recompute p, this time without rounding
ShiftPerFrame= rate * PixSec * ifi;% Translate grating speed into a shift value in "pixels per frame"

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp as timing baseline for our redraw loop:
vbl=Screen('Flip', PresWin);
vblendtime = vbl + PresDur;
i=0;

while(vbl < vblendtime)
        xoffset = mod(i*ShiftPerFrame,PixSec);% Shift the grating by "shiftperframe" pixels per frame:
        i=i+1;
        srcRect=[xoffset 0 xoffset+VisibleSize VisibleSize];% Define shifted srcRect that cuts out the properly shifted rectangular area from the texture
        Screen('DrawTexture', PresWin, GratingTex, srcRect, dstRect, angle);% Draw grating texture, rotated by "angle":
        Screen('DrawTexture', PresWin, MaskTex, [0 0 VisibleSize VisibleSize], dstRect, angle);
        vbl = Screen('Flip', PresWin, vbl + (0.5) * ifi);% Flip 'waitframes' monitor refresh intervals after last redraw.
        if KbCheck %Abort on keypress
            break;
        end;
end;

%Priority(0);%Restore priority settings
%Screen('CloseAll');
end

