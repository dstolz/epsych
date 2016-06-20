%     Screen('Preference','SkipSyncTests', true);
    
    win = 2;
    w = Screen('OpenWindow',win, 128);
    ScreenRect=Screen('Rect',w);

    black = BlackIndex(w);
    white = WhiteIndex(w);
    
    vbl = [];


% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', w);

% Enable alpha blending for anti-aliasing
 Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Query the frame duration
ifi = Screen('GetFlipInterval', w);

% Calculate the number of dots
numDots = 100;

% Create our base dot coordinates
x = (-0.5 + rand(1,numDots)) * screenXpixels;
y = (-0.5 + rand(1,numDots)) * screenYpixels;

% % Scale this by the distance in pixels we want between each dot
% pixelScale = screenYpixels / (dim * 2 + 2);
% x = x .* pixelScale;
% y = y.* pixelScale;

% % Make the matrix of positions for the dots into two vectors
% xPosVector = reshape(x, 1, numDots);
% yPosVector = reshape(y, 1, numDots);

% We can define a center for the dot coordinates to be relaitive to. Here
% we set the centre to be the centre of the screen
dotCenter = [screenXpixels / 2 screenYpixels / 2];

% Set the size of the dots randomly between 10 and 30 pixels
dotSizes = 20;
 
% % Our grid will oscilate with a sine wave function to the left and right
% % of the screen. These are the parameters for the sine wave
% % See: http://en.wikipedia.org/wiki/Sine_wave
% amplitude = screenYpixels * 0.25;
% frequency = 0.2;
% angFreq = 2 * pi * frequency;
% startPhase = 0;
% time = 0;

% Sync us and get a time stamp
vbl = Screen('Flip', w);
waitframes = 1;

% Set fraction of dots to go in a specific direction (between 0 and 1)
fracDelibDots = 0.2;

% Set deliberate direction movement vectors (think of the screen as a cart-
% esian plane, magnitude of number is the speed of the dot)
numDelibDots = numDots * fracDelibDots;
xdir = 5;
ydir = 5;
delibxV = repmat(xdir,1, numDelibDots);
delibyV = repmat(ydir,1, numDelibDots);

% Set random direction movement vectors
numRandDots = numDots - numDelibDots ;
randxV = -5 + (10).*rand(1,numRandDots);
randyV = -5 + (10).*rand(1,numRandDots);

% Create movement matrix
xV = [randxV,delibxV];
yV = [randyV,delibyV];

% Set the initial time
time = 0;

% Loop the animation until a key is pressed
while ~KbCheck

%     % Position of the square on this frame
%     gridPos = amplitude * sin(angFreq * time + startPhase);
    
    % Position of each dot this frame
    x = x + xV;
    y = y + yV;
    dotPos = [x;y];
    
    % Make more dots
    morex = (-0.5 + rand(1,round(numDots/25))) * screenXpixels;
    morey = (-0.5 + rand(1,round(numDots/25))) * screenYpixels;
    x = [x,morex];
    y = [y,morey];
    
    % Make more movement vectors for new dots
    moreDelibxV = repmat(xdir,1,round(numDelibDots/25));
    moreDelibyV = repmat(ydir,1,round(numDelibDots/25));
    moreRandxV = -5 + (10).*rand(1,round(numRandDots/25));
    moreRandyV = -5 + (10).*rand(1,round(numRandDots/25));
    xV = [xV,moreDelibxV];
    yV = [yV,moreDelibyV];
    xV = [xV,moreRandxV];
    yV = [yV,moreRandyV];
    
    % Draw all of our dots to the screen in a single line of code
    Screen('DrawDots', w, dotPos,...
        dotSizes, [], dotCenter, 2);

    % Flip to the screen
    vbl  = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);

    % Increment the time
    time = time + ifi;

end

sca
% if numel(C.OPTIONS.ISI) == 2
%     ISI = round(C.OPTIONS.ISI(1)+diff(C.OPTIONS.ISI)*rand(1))/1000;
% else
%     ISI = C.OPTIONS.ISI/1000;
% end
% 
% % Show the checker board with a photodiode marker
% Screen('DrawTexture',w,CheckTex);
% PhotodiodeMarker(w,true);
% 
% % this sets the inter-trigger-interval since it is using OperationalTrigger
% % mode.
% vbl = Screen('Flip',w,vbl + ISI - 0.007); % -0.007 is an empirically derived offset value
% 
% 
% % Maintain the checkerboard and turn off photodiode marker
% % ... for some reason, the 'dontclear' flag is not working in
% % Screen('Flip', ...), so just redraw the same checker board
% Screen('DrawTexture',w,CheckTex);
% PhotodiodeMarker(w,false);
% Screen('Flip',w,vbl+0.1);
