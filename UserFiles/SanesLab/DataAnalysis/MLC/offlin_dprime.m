%Offline dprime calculation


%Initialize
hitrates = [];

%Pull out stimuli and response codes
Depths = [Data.AMdepth]';
Resps = [Data.ResponseCode]';


%Remove reminder trials
startInd =find(Depths ~= 1, 1,'first');
Depths = Depths(startInd:end);
Resps = Resps(startInd:end);
Stimuli = unique(Depths);


%Convert response codes ( 1 = hit, 2 = fa) and compile data
hitbit = Info.Bits.hit;
fabit = Info.Bits.fa;

hits = bitget(Resps,hitbit);
fas = bitget(Resps,fabit);
fas = fas*2;

Responses = hits + fas;

d = [Depths,Responses];


%For each stimulus...
for i = 1:numel(Stimuli)
   
    %Pull out data for one stimulus value
    stimdata = d(d(:,1) == Stimuli(i),:);
    ntrials = size(stimdata,1);
    
    %If stimulus was a GO, calculate hit rate
    if Stimuli(i) > 0
        hits = numel(find(stimdata(:,2) == 1));
        hr = hits/ntrials;
        hitrates = [hitrates;Stimuli(i),hr];
        
    %If Stimulus was a NOGO, calculate FA rate    
    else
        fas = numel(find(stimdata(:,2) == 2));
        farate = fas/ntrials;
        
    end
    
end

%Correct floor and ceiling
hitrates(hitrates(:,2)<0.05,2) = 0.05;
hitrates(hitrates(:,2)>0.95,2) = 0.95;
if farate <0.05
    farate = 0.05;
end

if farate > 0.95
    farate = 0.95;
end

dprimes = [hitrates(:,1),norminv(hitrates(:,2)) - norminv(farate)];



