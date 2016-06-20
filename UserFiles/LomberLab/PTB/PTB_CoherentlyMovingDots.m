%% Coherent moving dots
%
% Daniel.Stolzberg@gmail.com 2016

sca

num_coh_dots = 50; % number of coherently moving dots
dir_coh_dots = 0:20:340; % direction of coherently moving dots (clockwise starting from left in degrees)
num_dots     = 50; % number of randomly moving dots
dot_size     = 1; % degrees
dot_color    = 1;
dot_speed    = 50; % degrees/second
duration     = 10; % seconds


mon_width = 59.69; % cm
v_dist = 20; % cm

[w,rect,fps] = PTB_NormalExpt_Startup(0,1);

IFI = 1/fps;

Screen('BlendFunction',w,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

    
ppd = pi * (rect(3)-rect(1)) / atan(mon_width/v_dist/2) / 360;    % pixels per degree
pfs = dot_speed * ppd / fps;                            % dot speed (pixels/frame)
s = dot_size * ppd;                                        % dot size (pixels)


% randomly moving dots
xy = rand(2,num_dots);
xy = [xy(1,:) * rect(3); xy(2,:) * rect(4)];
mdir = sign(randn(1,num_dots));    % motion direction for each dot
dr = pfs * mdir;                   % change in radius per frame (pixels)
t = 2*pi*rand(1,num_dots);         % theta polar coordinate
cs = [cos(t); sin(t)];
dxdy = [dr; dr] .* cs;             % change in x and y per frame (pixels)

for i = 1:length(dir_coh_dots)
    
    % coherently moving dots
    cxy = rand(2,num_coh_dots);
    cxy = [cxy(1,:) * rect(3); cxy(2,:) * rect(4)];
    t = pi/180*dir_coh_dots(i);                      % theta polar coordinate
    cs = [cos(t); sin(t)];
    cdxdy = [pfs; pfs] .* cs;                       % change in x and y per frame (pixels)
    cdxdy = repmat(cdxdy,1,num_coh_dots);
    
    xoffset = cos(t+pi)*rect(3);
    yoffset = sin(t+pi)*rect(4);
    
    cxy = [cxy(1,:); cxy(2,:)];
    
    [minsmooth,maxsmooth] = Screen('DrawDots', w);
    s = min(max(s, minsmooth), maxsmooth);
    
    
    vbl = Screen('Flip',w);
    stopvbl = vbl + duration;
    
    BitsTrigger(w,vbl+IFI); % mark trial onset
    while vbl < stopvbl
        
        Screen('DrawDots', w, [xy cxy], s, dot_color, [0, 0], 2);  % change 1 to 0 or 4 to draw square dots
        Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
        
        vbl = Screen('Flip',w,vbl+IFI);
        
        xy  = xy  + dxdy; % move dots
        cxy = cxy + cdxdy;
        
        out_ind = xy < 0 | [xy(1,:) > rect(3); xy(2,:) > rect(4)];
        if any(out_ind(:))
            saind = sum(any(out_ind));
            newxy = rand(2,saind);
            xy(:,any(out_ind)) = [newxy(1,:)*rect(3); newxy(2,:)*rect(4)];
            
            mdir = sign(randn(1,saind));    % motion direction for each dot
            dr = pfs * mdir;                % change in radius per frame (pixels)
            t = 2*pi*rand(1,saind);         % theta polar coordinate
            cs = [cos(t); sin(t)];
            dxdy(:,any(out_ind)) = [dr; dr] .* cs;             % change in x and y per frame (pixels)
        end
        
        out_ind = cxy < 0 | [cxy(1,:) > rect(3); cxy(2,:) > rect(4)];
        if any(out_ind(:))
            saind = sum(any(out_ind));
            newxy = rand(2,sum(any(out_ind)));
            newxy = [xoffset+newxy(1,:)*rect(3); yoffset+newxy(2,:)*rect(4)];
            cxy(:,any(out_ind)) = newxy;
        end
    end
    
    % keep moving random dots between trials
    BitsTrigger(w,vbl+IFI); % Mark trial offset
    
    while ~isempty(cxy) % keep going until all coherently moving dots are disappeared
        
        Screen('DrawDots', w, [xy cxy], s, dot_color, [0, 0], 2);  % change 1 to 0 or 4 to draw square dots
        Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
        
        vbl = Screen('Flip',w,vbl+IFI);
        
        xy  = xy  + dxdy; % move dots
        cxy = cxy + cdxdy; % keep coherent dots moving until they are off of the screen

        out_ind = xy < 0 | [xy(1,:) > rect(3); xy(2,:) > rect(4)];
        if any(out_ind(:))
            saind = sum(any(out_ind));
            newxy = rand(2,saind);
            xy(:,any(out_ind)) = [newxy(1,:)*rect(3); newxy(2,:)*rect(4)];
            
            mdir = sign(randn(1,saind));    % motion direction for each dot
            dr = pfs * mdir;                % change in radius per frame (pixels)
            t = 2*pi*rand(1,saind);         % theta polar coordinate
            cs = [cos(t); sin(t)];
            dxdy(:,any(out_ind)) = [dr; dr] .* cs;             % change in x and y per frame (pixels)
        end
        
        % keep going until all 
        out_ind = cxy < 0 | [cxy(1,:) > rect(3); cxy(2,:) > rect(4)];
        cxy(:,any(out_ind)) = [];
        cdxdy(:,any(out_ind)) = [];
        
    end
end

sca


































