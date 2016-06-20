%% Bar Sweeps
% Bars moving across the screen.
%
% Daniel.Stolzberg@gmail.com 2016

barwidth = 50; % pixels (1x1 integer)
angle    = 0:30:340; % starting angle in degrees (1xN)
rate     = 1000*ones(size(angle)); % rate, pixels per flip (1xN)
contrast = 100; % contrast between background and bar


[window,ScreenRect,frameRate] = PTB_NormalExpt_Startup(0,1);


Bar=ones(ScreenRect(3))*(127*contrast/100 + 128);%Creates a white bar
BarTex=Screen('MakeTexture', window, Bar); %Creates a texture from Bar

ifi = 1/frameRate;


PresDiam=ScreenRect(4);
barlength=sqrt(sum(ScreenRect([3 4]).^2));

% Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% MaskDiam=ScreenRect(3);
% MaskRad=(MaskDiam)/2;
% mask=ones(MaskDiam+1, MaskDiam+1, 2) * 128;
% [x,y]=meshgrid(-1*MaskRad:MaskRad,-1*MaskRad:MaskRad);
% gausswidth=PresDiam/1;
% mask(:, :, 2)=255 * (1 - exp(-((x/gausswidth).^2)-((y/gausswidth).^2)));
% matrixmid=ceil(size(mask,1)/2);
% maskcutoff=mask(matrixmid,matrixmid-0.5*PresDiam,2);
% mask2 = mask(:,:,2);
% mask2(mask2>maskcutoff) = 255;
% mask(:,:,2) = mask2;
% 
% MaskTex=Screen('MakeTexture', window, mask);

fprintf(2,'\n\n**********\nStarting Bar Sweeps at %s\n',datestr(now))

for A = 1:length(angle)
    
    ShiftPerFrame= rate(A) * ifi;% Translate bar speed into a shift value in "pixels per frame"
    
    
    xplaneshift=cosd(angle(A))*ShiftPerFrame;%Calculates the horizontal shift
    yplaneshift=sind(angle(A))*ShiftPerFrame;%Calculates the vertical shift
    
    xstart=(ScreenRect(3)/2-barwidth)-ceil(cosd(angle(A))*ScreenRect(4)/2);
    xend=xstart+barwidth;
    ystart=(ScreenRect(4)/2-barlength/2)-ceil(sind(angle(A))*ScreenRect(3)/2);
    yend=ystart+barlength;
    PresDur=3*(ScreenRect(4)+barwidth)/rate(A);
    
    
    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp as timing baseline for our redraw loop:
%     Screen('DrawTexture', window, MaskTex,[],[]);
    vbl=Screen('Flip', window);
    vblendtime = vbl + PresDur + 1;
    
    
    i=0;
    BitsTrigger(window,vbl+1);

    while(vbl<vblendtime)
        xoffset =(i*xplaneshift);%Indexes the horizontal shift across the screen
        yoffset =(i*yplaneshift);%Indexes the vertical shift down the screen
        
        Screen('DrawTexture', window, BarTex,[0 0 barwidth barlength], ...
            [xstart+xoffset ystart+yoffset xend+xoffset yend+yoffset],angle(A));
%         Screen('DrawTexture', window, MaskTex,[],[]);
        vbl = Screen('Flip',window,vbl+ifi);
        i=i+1;
    end
    
end


fprintf(2,'Finished at %s\n**********\n\n',datestr(now))


sca












