function [Hits,FA] = Population_Decoder_SVM_PSTH_v2(Data1,Data2,tau,prop_trials,convolve)
if nargin < 3
	tau			=	10;
	prop_trials	=	0.80;
	convolve	=	0;
end
if nargin < 4
	prop_trials	=	0.80;
	convolve	=	0;
end
if nargin < 5
	convolve	=	0;
end

Nogo			=	Data1;
Go				=	Data2;

num_iterations	=	250; % number of decoder iterations for each stimulus
Class			=	nan(num_iterations,2);

for i = 1:num_iterations
	
	%---Go trials---%
	nGos	=	size(Go,1);
	xmax	=	round(nGos);
% 	xmax	=	round(round(nGos)*0.90);
	Gidx	=	randsample(1:1:nGos,xmax);
	GO		=	Go(Gidx,:);
	%---Nogo trials---%
	nNogos	=	size(Nogo,1);
	xmax	=	round(nNogos);
% 	xmax	=	round(round(nNogos)*0.90);
	Nidx	=	randsample(1:1:nNogos,xmax);
	NOGO	=	Nogo(Nidx,:);
	
	%---Get Templates (Training Set)---%
	%-Go-%
	Gnum_trials		=	size(GO,1);
	n				=	round(Gnum_trials*prop_trials);	
	gidx			=	randsample(1:1:Gnum_trials,n);	
	Gotemplate		=	nanmean(GO(gidx,:));
% 	Gotemplate		=	GO(gidx,:);

	if( convolve )
		Gotemplate		=	ConvolveSpikeTrain(Gotemplate,tau);
	end
	%-Nogo-%
	Nnum_trials		=	size(NOGO,1);
	n				=	round(Nnum_trials*prop_trials);
	nidx			=	randsample(1:1:Nnum_trials,n);
	Nogotemplate	=	nanmean(NOGO(nidx,:));
% 	Nogotemplate	=	NOGO(nidx,:);
	if( convolve )
		Nogotemplate	=	ConvolveSpikeTrain(Nogotemplate,tau);
	end
	%---Training Data Set---%
	train1		=	Nogotemplate;
	var1		=	repmat({'Nogo'},size(train1,1),1);
	train2		=	Gotemplate;
	var2		=	repmat({'Go'},size(train2,1),1);
	Train		=	[train1;train2];
	grp			=	[var1;var2];
	
	options.MaxIter	=	10^6;
	SVMStruct	=	svmtrain(Train,grp,'kernel_function','linear',...
		'kktviolationlevel',0.05,'tolkkt',1e-8,'boxconstraint',1,'Options',options);
	
	%---Get Test---%
	%-Go-%
	Tgidx			=	ismember(1:1:Gnum_trials,gidx);
	GoTM			=	GO(~Tgidx,:);
	xmax			=	size(GoTM,1);
	idx				=	randi(xmax);
% 	Gotest			=	GoTM(idx,:);
% 	Gotest			=	GoTM;
	Gotest			=	nanmean(GoTM);
	if( convolve )
		Gotest			=	ConvolveSpikeTrain(Gotest,tau);
	end
	%-Nogo-%
	Tnidx			=	ismember(1:1:Nnum_trials,nidx);
	NogoTM			=	NOGO(~Tnidx,:);
	xmax			=	size(NogoTM,1);	
	idx				=	randi(xmax);
% 	Nogotest		=	NogoTM(idx,:);
% 	Nogotest		=	NogoTM;
	Nogotest		=	nanmean(NogoTM);
	if( convolve )
		Nogotest		=	ConvolveSpikeTrain(Nogotest,tau);
	end
	
	%---Test Data Set---%
	test1		=	Nogotest;
	test2		=	Gotest;
	Test		=	[test1;test2];
	
% 	preGroup	=	[zeros(length(test1),1); ones(length(test2),1)];
% 	preGroup	=	[repmat({'Nogo'},size(test1,1),1); repmat({'Go'},size(test2,1),1)];
	preGroup	=	[{'Nogo'};{'Go'}];
	
	Group		=	svmclassify(SVMStruct,Test);
    
	Class(i,:)	=	calculatecorrect(preGroup,Group);
% 	Class(i,:)	=	calculatecorrect2(preGroup,Group);
	
end
Hits			=	Class(:,1);
FA				=	Class(:,2);

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
		try
        decay((t(end)+1:end)) = exp(-t/tau);
		catch
			keyboard
		end
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

function Class = calculatecorrect(pretest,test)
%---Hits---%
remov	=	strcmp(test,'');
pt		=	pretest(~remov);
t		=	test(~remov);
idx		=	strcmp(pt(2),'Go') & strcmp(t(2),'Go');
Hit		=	sum(idx)/length(idx);

%---FA---%
idxx	=	strcmp(pt(1),'Nogo') & strcmp(t(1),'Go');
FA		=	sum(idxx)/length(idxx);

Class	=	[Hit FA];

function Class = calculatecorrect2(pretest,test)
%---Hits---%
idx		=	strcmp(pretest,'Go') & strcmp(test,'Go');
Hit		=	sum(idx)/length(idx);

%---FA---%
idxx	=	strcmp(pretest,'Nogo') & strcmp(test,'Go');
FA		=	sum(idxx)/length(idxx);

Class	=	[Hit FA];