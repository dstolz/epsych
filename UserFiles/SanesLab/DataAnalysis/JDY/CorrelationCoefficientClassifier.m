function [Hits,FAs] = CorrelationCoefficientClassifier(Data1,Data2,prop_trials)
Nogo			=	Data1;
Go				=	Data2;

num_iterations	=	250; % number of decoder iterations for each stimulus
Hits			=	nan(num_iterations,1);
FAs				=	nan(num_iterations,1);

for i = 1:num_iterations
	
	%---Go trials---%
	nGos	=	size(Go,1);
% 	xmax	=	round(nGos/2);
	xmax	=	round(nGos);
	Gidx	=	randsample(1:1:nGos,xmax);
	GO		=	Go(Gidx,:);
	%---Nogo trials---%
	nNogos	=	size(Nogo,1);
% 	xmax	=	round(nNogos/2);
	xmax	=	round(nNogos);
	Nidx	=	randsample(1:1:nNogos,xmax);
	NOGO	=	Nogo(Nidx,:);
	
	%---Get Templates (Training Set)---%
	%---Remove # trial for Go test---%
	Gnum_trials		=	size(GO,1);
	xmax			=	round(round(Gnum_trials)*prop_trials);
% 	xmax			=	1;
	gidx			=	randsample(1:1:Gnum_trials,xmax);
	Gotest			=	nanmean(Go(gidx,:));
% 	Gotest			=	Go(gidx,:);
	%---Go Template---%
	Gidx			=	ismember(1:1:Gnum_trials,gidx);
	Gotemplate		=	nanmean(GO(~Gidx,:));
	
	%---Remove # trial for Nogo test---%
	Nnum_trials		=	size(NOGO,1);
	xmax			=	round(round(Nnum_trials)*prop_trials);
% 	xmax			=	1;
	nidx			=	randsample(1:1:Nnum_trials,xmax);
	Nogotest		=	nanmean(NOGO(nidx,:));
% 	Nogotest		=	NOGO(nidx,:);
	%---Nogo Template---%
	Nidx			=	ismember(1:1:Nnum_trials,nidx);
	Nogotemplate	=	nanmean(NOGO(~Nidx,:));
	
% 	%---Convolve Spike Trains---%
% 	Gotest			=	ConvolveSpikeTrain(Gotest,10);
% 	Nogotest		=	ConvolveSpikeTrain(Nogotest,10);
% 	Gotemplate		=	ConvolveSpikeTrain(Gotemplate,10);
% 	Nogotemplate	=	ConvolveSpikeTrain(Nogotemplate,10);

	%---Check if Hit: Go test matches Go template---%
	Gotemp			=	Gotemplate;
	%---Go test versus Go template---%
	corrHit			=	corrcoef(Gotemp,Gotest);
	corrHit			=	corrHit(1,2);
	%---Go test versus Nogo template---%
	Nogotemp		=	Nogotemplate;
	corrMiss		=	corrcoef(Nogotemp,Gotest);
	corrMiss		=	corrMiss(1,2);
	likelihood		=	abs([corrHit corrMiss]);
	MLE				=	max(likelihood);
	Hits(i,:)		=	likelihood(1) == MLE;
	
	%---Check if FA: Nogo test matches Go template---%
	%---Nogo test versus Nogo template---%
	corrCR			=	corrcoef(Nogotemp,Nogotest);
	corrCR			=	corrCR(1,2);
	%---Nogo test versus Go template---%
	corrFA			=	corrcoef(Gotemp,Nogotest);
	corrFA			=	corrFA(1,2);
	FA_likelihood	=	abs([corrCR corrFA]);
	MLE				=	max(FA_likelihood);
	FAs(i,:)		=	FA_likelihood(2) == MLE;
	
end

%---Locals---%
function sptrainConv = ConvolveSpikeTrain(sptrain,tau,filtType,fs)
% Convolve spike train with a decaying exponential
% Set up the inputs
if nargin == 2,
    filtType = 'exp';
    fs = 1000;
elseif nargin == 3,
    fs = 1000;
end
tau = tau*fs/1000;
% Set up the filter
switch filtType
    case 'exp'
        t = 0:(1.5*fs);
        decay = zeros(1,2*length(t)-1);
        decay((t(end)+1:end)) = exp(-t/tau);
    case 'hanning'
        if mod(tau,2) == 0,
            tau = tau + 1;
        end
        decay = hanning(tau);
    case 'square'
        if mod(tau,2) == 0,
            tau = tau + 1;
        end
        decay = [zeros(1,tau) ones(1,tau) zeros(1,tau)];
    case 'gauss'
        t = (-0.75*fs):(0.75*fs);
        decay = zeros(1,2*length(t)-1);
        decay(t(end)+1:length(t)+t(end)) = exp(-(t).^2/(2*tau.^2))/sum(exp(-(t).^2/(2*tau.^2)));
end
decay = decay/sum(decay);
starter = (length(decay)+1)/2;
stopper = (length(decay)-1)/2;
% Convolve spike train with a decaying exponential
sptrainConv = zeros(size(sptrain));
for i = 1:size(sptrain,1)
    sptemp = conv(sptrain(i,:),decay);
    sptrainConv(i,:) = sptemp(starter:(length(sptemp)-stopper));
    
    %Debugging: Plotting smoothed functions
%     figure
%     h = plot(sptrainConv(i,:),'k-');
%     hold on;
%     h2 = plot(sptrain(i,:)-0.5,'k+');
%     xh = xlabel('Samples');
%     yh = ylabel('Spike Count/Smoothed Spiketrain');
%     th = title('Smoothed Spiketrain');
%     set(gca,'ylim',[0 2])
%     myformat(gca,xh,yh,th)
    
    clear sptemp
end