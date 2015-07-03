%% Procedure for retrieving LFP data from Tanks

cfg = [];
cfg.tank  = char(TDT_TankSelect);
[cfg.TT,~,TDTfig] = TDT_SetupTT;

% cfg.block = cfg.TT.GetHotBlock;
cfg.block = 5;
cfg.usemym   = false;
cfg.downfs   = 600;
cfg.datatype = 'BlockInfo';
binfo = getTankData(cfg);

cfg.datatype = 'Waves';
data = getTankData(cfg);

delete(cfg.TT)
close(TDTfig)

Fs = data.fsample;

%% Filter different frequency bands

% % theta band [4 8]
% Fstop1 = 2;          % First Stopband Frequency
% Fpass1 = 4;          % First Passband Frequency
% Fpass2 = 8;          % Second Passband Frequency
% Fstop2 = 16;         % Second Stopband Frequency
% Astop1 = 60;          % First Stopband Attenuation (dB)
% Apass  = 1;           % Passband Ripple (dB)
% Astop2 = 80;          % Second Stopband Attenuation (dB)
% match  = 'stopband';  % Band to match exactly

% Gamma band [20 80]
Fstop1 = 15;          % First Stopband Frequency
Fpass1 = 20;          % First Passband Frequency
Fpass2 = 80;          % Second Passband Frequency
Fstop2 = 100;         % Second Stopband Frequency
Astop1 = 60;          % First Stopband Attenuation (dB)
Apass  = 1;           % Passband Ripple (dB)
Astop2 = 80;          % Second Stopband Attenuation (dB)
match  = 'stopband';  % Band to match exactly

% High Gamma band [100 150]
% Fstop1 = 50;          % First Stopband Frequency
% Fpass1 = 100;          % First Passband Frequency
% Fpass2 = 150;          % Second Passband Frequency
% Fstop2 = 200;         % Second Stopband Frequency
% Astop1 = 60;          % First Stopband Attenuation (dB)
% Apass  = 1;           % Passband Ripple (dB)
% Astop2 = 80;          % Second Stopband Attenuation (dB)
% match  = 'stopband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

fprintf('Filtering ...')
data.waves = filter(Hd,data.waves);
fprintf(' done\n')


%% Reorganize by freq/level
n = size(data.waves,1);
win = [0 0.5];

i = strcmpi('freq',binfo.paramspec); freqs = binfo.epochs(:,i);
i = strcmpi('levl',binfo.paramspec); levls = binfo.epochs(:,i);
ufreq = unique(freqs);
ulevl = unique(levls);
stmon = binfo.epochs(:,end);
stmonsamps = round(stmon * Fs);

svec = round(win(1)*Fs):round(win(2)*Fs);

% Trial-based LFP dims: samples x channels x trials
tLFP = zeros(length(svec),size(data.waves,2),length(stmonsamps));
for i = 1:length(stmonsamps)
    sind = stmonsamps(i) + svec;
    tLFP(:,:,i) = data.waves(sind,:);
end

tvec = svec/Fs;

%% LFP map
mLFP = zeros(size(tLFP,2),length(ulevl),length(ufreq));
for F = 1:length(ufreq)
    for L = 1:length(ulevl)
        ind = ufreq(F) == freqs & ulevl(L) == levls;
        mLFP(:,L,F) = mean(squeeze(std(tLFP(:,:,ind))),2);
    end
end


%% Optionally map out electrode sites and save in electrode strucuture
ctxpath = 'D:\Work\PROJECTS\Electrophysiology\Mel''s DZ';
ctximfn = 'ECoG_Block5_cropped.png';

ctxfn = fullfile(ctxpath,ctximfn);
ctx = imread(ctxfn);

figure('WindowStyle','docked');
imshow(ctx)

nch = 32;
el_pos = zeros(nch,2);
hold on
for i = 1:nch
    fprintf('Click on electrode channel %d ...\n',i)
    [el_pos(i,1),el_pos(i,2),button] = ginput(1);
    if isequal(button,3), break; end
    plot(el_pos(i,1),el_pos(i,2),'xb');
end
hold off


%% Artifical electrode spacing
elmod = 'E32-1000-30-200';
elpath = 'C:\MATLAB\work\ephys\analysis\electrode_maps';
elfn = fullfile(elpath,[elmod,'.mat']);
load(elfn); % load 'electrode' structure




%% Use el_map to plot FRFs
% elmod = 'E32-1000-30-200_Skyy5';
% elpath = 'C:\MATLAB\work\ephys\analysis\electrode_maps';
% elfn = fullfile(elpath,[elmod,'.mat']);
% load(elfn); % load 'electrode' structure

% bad channels
% badchannels = [15 16 29 30 31 32];
badchannels = [16 30];

badchanind = ismember([electrode.channel],badchannels);

figure('windowstyle','docked');
set(gcf,'units','normalized');


normx = [electrode.xcoord] / max(abs([electrode.xcoord]));
normy = 1-([electrode.ycoord] / max(abs([electrode.ycoord])));
xmin = min(normx);
ymin = min(normy);
lowleftidx = find(normx==xmin & normy==ymin);
normx = normx - xmin * 0.7;
normy = normy - ymin * 0.7;



% would be nice to somehow copmute these values from x,y coordinates
opW = 0.08; 
opH = 0.15;


n = length(electrode);

ax = zeros(size(electrode));
for i = 1:n
    opL = normx(i);
    opB = normy(i);
    
    ax(i) = axes('Position',[opL opB opW opH],'xtick',[],'ytick',[]);
    
    c = electrode(i).channel;
    
    if ~any(c == badchannels) 
        surf(ufreq,ulevl,sgsmooth2d(squeeze(mLFP(c,:,:))),'parent',ax(i));
        shading interp
        view(2)
        axis tight
    end
    box on
%     title(c)
end

lowleftax = ax(lowleftidx);

ax = ax(~ismember([electrode.channel],badchannels));

set(ax,'xscale','log');
set(ax,'climmode','auto');
% c = cell2mat(get(ax,'clim'));
% set(ax,'clim',[min(c(:)) max(c(:))]);
set(ax,'xtick',[],'ytick',[])

set(lowleftax,'xtickMode','auto','ytickMode','auto');


%% 2D kCSD parallel
% Time slices
% tslice = find(tvec>0.05,1); % for computing 2D kCSD
tslice = 1:10:length(tvec);

el_pos = [[electrode.xcoord]',[electrode.ycoord]'];
ep = el_pos(~badchanind,:);

if matlabpool('size') == 0, matlabpool 8; end % for parrallel processing

tic;
fprintf('Beginning kCSD computing at %s\n',datestr(now,'HH:MM:SS PM'))

TkCSD = cell(size(tslice));
for t = 1:length(tslice)
    fprintf('\tTime Slice %d of %d\t%0.3f sec\n',t,length(tslice),tvec(tslice(t)))
    kLFP = squeeze(tLFP(tslice(t),~badchanind,:));
    pots = zeros(size(kLFP,1),length(ufreq)*length(ulevl));
    kCSD = zeros(101,101,size(pots,2));
    
    % tic
    i = 1;
    for F = 1:length(ufreq)
        ind = ufreq(F) == freqs;
        for L = 1:length(ulevl)
            tind = ind & ulevl(L) == levls;
            pots(:,i) = mean(kLFP(:,tind),2);
            i = i + 1;
        end
    end
    
    % Comptue kCSD for each trial in parallel
    parfor i = 1:size(pots,2)
        k = kcsd2d(ep, pots(:,i),'manage_data',0);
        kCSD(:,:,i) = k.CSD_est;
    end
    
    kFRF = zeros(size(kCSD,1),size(kCSD,2),length(ufreq),length(ulevl));
    i = 1;
    for F = 1:length(ufreq)
        for L = 1:length(ulevl)
            kFRF(:,:,F,L) = kCSD(:,:,i);
            i = i + 1;
        end
    end
    % kFRF = reshape(kCSD,size(kCSD,1),size(kCSD,2),length(ufreq),length(ulevl));
    
    TkCSD{t} = kFRF;
end
clear kFRF
fprintf('Completed computation at %s\n\ttotal compute time = %0.2f hours\n',...
    datestr(now,'HH:MM:SS PM'),toc/3600)

%% contour plots
ctxpath = 'D:\Work\PROJECTS\Electrophysiology\Mel''s DZ';
ctximfn = 'ECoG_Block5_cropped.png';
ctxfn = fullfile(ctxpath,ctximfn);
ctx = imread(ctxfn);

fh = min(ufreq)*2.^(0:log2(max(ufreq)/min(ufreq))-1);
fmap = jet(length(fh));

clf

lidx = 9;

nval = abs(cell2mat(TkCSD));
nval = nval(:,:,:,lidx);
nval = max(abs(nval(:)));

x = [electrode.xcoord];
y = [electrode.ycoord];

minx = min(x)-0.5;  maxx = max(x)+0.5;
miny = min(y)-0.5;  maxy = max(y)+0.5;

s = 1;
clear mval midx
for i = 1:length(TkCSD)
    if i > 30, break; end
    subplot(5,6,s)
%     imshow(ctx(:,:,1));
%     [imy,imx,~] = size(ctx);
%     imy = linspace(imy,1,size(TkCSD{i},2)); % because image is displayed upside down
%     imx = linspace(1,imx,size(TkCSD{i},2));
    % plot electrode sites
    plot(x,y,'o','color',[0.4 0.4 0.4],'markerfacecolor',[0.6 0.6 0.6],'markersize',3)
    
    
    hold on
    for F = 1:size(TkCSD{i},3)
        k = squeeze(TkCSD{i}(:,:,F,lidx) / nval)';
        cc = find(fh<=ufreq(F),1,'last');
        imx = linspace(minx,maxx,size(k,2));
        imy = linspace(miny,maxy,size(k,1));
        [~,h] = contourf(imx,imy,k,[1 0.6]);
        ch = get(h,'children');
        set(ch,'facecolor',fmap(cc,:),'facealpha',0.5, ...
            'linestyle','-','edgecolor',fmap(cc,:));
    end
    box on
    title(sprintf('%0.0f',1000*tvec(tslice(i))));
    hold off
    drawnow
    
    s = s + 1;
end
ax = get(gcf,'children');
set(ax,'xtick',[],'ytick',[],'ylim',[miny maxy],'xlim',[minx maxx]);

%% Frequency maps
ctxpath = 'D:\Work\PROJECTS\Electrophysiology\Mel''s DZ';
ctximfn = 'ECoG_Block5_cropped.png';
ctxfn = fullfile(ctxpath,ctximfn);
ctx = imread(ctxfn);

fh = min(ufreq)*2.^(0:log2(max(ufreq)/min(ufreq))-1);
fmap = jet(length(fh));

clf

lidx = 9;

x = [electrode.xcoord];
y = [electrode.ycoord];

minx = min(x)-0.5;  maxx = max(x)+0.5;
miny = min(y)-0.5;  maxy = max(y)+0.5;

s = 1;
clear mval midx
for i = 1:length(TkCSD)
    
    for F = 1:size(TkCSD{i},3)
        k = squeeze(TkCSD{i}(:,:,F,lidx) / nval)';
    end
end













