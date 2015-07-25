function NextTrialID = TwoChoice_GellermannRand(TRIALS)
% NextTrialID = TwoChoice_GellermannRand(TRIALS)
%
%  Use Gellermann's rules for two alternative choice task trial sequences
%  (Gllermann, 1933).
%
%  DJS (c) 2011
%  Converted for Epsych 6/2015

persistent GSEQ GSEQseed schidx

global AX RUNTIME

try
    if isempty(GSEQ)
        % Generate Gellermann (1933) randomized sequence of trials
        % Gellermann, J1933
        n = 10;
        p = zeros(2^14,n);
        for i = 1:n
            p(:,i) = randperm(2^14);
        end
        
        m = [-ones(2^12,n); ones(2^12,n)];
        m = unique(m(p),'rows'); clear p
        %     imagesc(m); title(sprintf('n = %d',size(m,1)));
        
        % rule 1
        ind = sum(m,2) ~= 0;
        m(ind,:) = [];
        %     imagesc(m); title(sprintf('n = %d',size(m,1)));
        
        % rule 2
        tm1 = m > 0;
        tm2 = m < 0;
        for i = 1:n-4
            ind = sum(tm1(:,i:i+3),2) > 3;
            ind = ind | sum(tm2(:,i:i+3),2) > 3;
            tm1(ind,:) = [];
            tm2(ind,:) = [];
            m(ind,:)   = [];
        end
        
        %
        ind = false(size(m,1),n-2);
        tm1 = m > 0;
        tm2 = m < 0;
        for i = 1:n-2
            ind(:,i) = sum(tm1(:,i:i+2),2) == 3;
            ind(:,i) = ind(:,i) | sum(tm2(:,i:i+2),2) == 3;
        end
        ind = sum(ind,2) >= 2;
        m(ind,:) = [];
        %     imagesc(m); title(sprintf('n = %d',size(m,1)));
        
        % rule 3
        ind = abs(sum(m(:,1:n/2),2))>1;
        ind = ind | abs(sum(m(:,n/2+1:end),2))>1;
        m(ind,:) = [];
        %     imagesc(m); title(sprintf('n = %d',size(m,1)));
        
        % rule 4
        dm = diff(m,1,2)/2;
        ind = sum(abs(dm),2) ~= n/2;
        m(ind,:) = [];
        %     imagesc(m); title(sprintf('n = %d',size(m,1)));
        
        % rule 5
        % rule 5 is implied
        
        % Construct trial sequence
        a = m(1:size(m,1)/2,:);
        b = m(size(m,1)/2+1:end,:);
        
        ridx = randperm(size(a,1)); a = a(ridx,:);
        ridx = randperm(size(b,1)); b = b(ridx,:);
        
        m = [a fliplr(b)];
        
        GSEQ = reshape(m',1,numel(m));
        
        
    end
    
    
    
    
    boxid = TRIALS.Subject.BoxID;    
    
    
    if TRIALS.TrialIndex == 1 % First trial
        % Start from random position within sequence
        % Since Gellermann rules for randomization only allow for 44 sequences
        % of 10 trials yield 440 trials total, limit seed to first 100 trials
        % in the sequence.
        GSEQseed(boxid) = randi(100,1);
        schidx(:,boxid) = zeros(size(TRIALS.trials,1),1);

    else
        
        % Test if previous trial was aborted.  If so, then repeat the same
        % parameters.
        LastRespCode = TRIALS.DATA(end).ResponseCode;
        LastTrialAborted = bitget(LastRespCode,5);
        if LastTrialAborted
            NextTrialID = RUNTIME.TRIALS.NextTrialID;
            return
        end
    end
    
    
    % correct side: -1 Left; 1 Right
    csidx = findincell(strfind(TRIALS.writeparams,'CorrSide'));
    
    corrside = cell2mat(TRIALS.trials(:,csidx));
    subcorrside = find(corrside == GSEQ(GSEQseed(boxid) + TRIALS.TrialIndex-1));
    
    
    % give priority to least chosen trials
    i = min(schidx(subcorrside,boxid));
    i = find(schidx(subcorrside,boxid) == i);
    r = randperm(length(i));
    NextTrialID = subcorrside(i(r(1)));

    schidx(NextTrialID,boxid) = schidx(NextTrialID,boxid) + 1;
    
    % look for RewardRate parameter
    rridx = findincell(strfind(TRIALS.writeparams,'RewardRate'));
    ttidx = findincell(strfind(TRIALS.writeparams,'TrialType')); %MT
    tt = TRIALS.trials{NextTrialID,ttidx};                              %MT
    if ~isempty(rridx)
        if TRIALS.TrialIndex > 10 % first 10 trials are always rewarded.
            %r = rand <= NextTrialID.trials{NextTrialID,rridx}/100;
            rw = randi(100,1) <= TRIALS.trials{NextTrialID,rridx};
        else
            if tt == 1 %MT
                rw = randi(100,1) <= TRIALS.trials{NextTrialID,rridx}; % MT except quiet
            else  rw = 1;
            end %MT
        end
        ststr = sprintf('*RewardTrial~%d',boxid);
        if RUNTIME.UseOpenEx
            AX.SetTargetVal(['Behavior.' ststr],rw);
        else
            AX.SetTagVal(ststr,rw);
        end
               
    end
    
    
    
catch
    disp('DOH!')
end

