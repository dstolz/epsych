function Y = signalPath(signal,modpath,C,gw_alpha,upsample)
% Y = signalPath(signal,modpath,C,[gw_alpha],[upsample])
%
% Apply gaussian kernel across channels following any arbitrary path.
%
% Input:
%   signal  ...  1xN signal to be spread across nChan channels
%   modpath ...  1XN signal modulating signal across nChan channels.
%                modpath must be between [-1 1];
%   C       ...  1x1 scalar value with the number of channels (scalar integer)
%   gw_alpha = 7; % 1/std of gaussian kernel
%   upsample = 4; % upsample signal across channels when applying path 
%
% Output:
%   Y       ...  CxN matrix with modulated signal path.
%
% Daniel.Stolzberg@gmail.com 2016

narginchk(3,5);
nargoutchk(1,2);

% check inputs and set default values
if nargin < 5 || isempty(gw_alpha), gw_alpha = 7; end
if nargin < 6 || isempty(upsample), upsample = 4; end
assert(upsample==fix(upsample),'upsample must be an integer value')

if size(signal,1) > 1,  signal = signal';   end % conform to 1xN
if size(modpath,1) > 1, modpath = modpath'; end % conform to 1xN

nTime = length(signal);

% ensure the length of our gaussian window is odd
gwlength = C*upsample;
if ~rem(gwlength,2), gwlength = gwlength + 1; end


% Scale signal_mod to number of channels
modpath = (modpath+1)/2; % [-1 1] -> [0 1]
modpath = modpath*(gwlength-1)+1; % [0 1] -> [1 nChan*upsample]

% Use modpath to direct gaussian envelope moving across speakers
gw = gausswin(gwlength,gw_alpha);

cvec = -gwlength/2:gwlength/2-1;
x = repmat(cvec',1,nTime) + repmat(modpath,gwlength,1);
indl = x < 1;
indu = x > gwlength;
clear x cvec

Y = zeros(gwlength,nTime);

for i = 1:nTime
    if any(indl(:,i))
        Y(:,i) = [gw(~indl(:,i)); zeros(sum(indl(:,i)),1)];
    else
        Y(:,i) = [zeros(sum(indu(:,i)),1); gw(~indu(:,i))];
    end 
end


Y = bsxfun(@times,Y,signal); % Y = Y.*repmat(signal,gwlength,1);


Y = Y/max(abs(Y(:)));

% downsample across channels
ds = floor(gwlength/C);
ofs = ds/2;
idx = ofs:ds:gwlength-ofs;
Y = Y(idx,:);













