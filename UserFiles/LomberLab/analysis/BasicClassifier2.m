function varargout = BasicClassifier2(D,nReps,func)
% R = BasicClassifier2(D)
% R = BasicClassifier2(D,nReps)
% R = BasicClassifier2(D,nReps,func)
% [R,Rshuff] = BasicClassifier2(D,...)
%
% D is an MxNxP data matrix with M samples from N observations in P
% categories.
%
% Optionally, the number of repetitions can be specified by the second
% input, nReps (default: nReps = 500).  Note that the randomization is
% reproducible if setting the seed number prior to calling this function
% (see help on the rng function for more info).
%
% Unlike BatchClassifier, this version compares each observation directly
% with the templates using some arbitrary function (ex: SchreiberCorr).
%
% Returns a matrix R with size nReps x P, where nReps is each repetition
% specified by the nReps input parameter and P is the number of categories
% in the data matrix, D.
%
% A secound output can be returned with the results from classifying a
% shuffled version of D.  Observations in the data matrix D are shuffled
% across categories.
%
% Daniel.Stolzberg@gmail.com    2015


if nargin == 1, nReps = 500; end
if nargin < 3 || isempty(func)
    func = @sum;
end


varargout{1} = doclassify(D,nReps,func);

if nargout > 1
    [M,N,P] = size(D);
    Dperm = reshape(D, [M N*P]);
    Dperm = reshape(Dperm(:,randperm(N*P)), [M,N,P]);
    fprintf(' shuffling ')
    varargout{2} = doclassify(Dperm,nReps,func);
end

fprintf(' done\n')




function result = doclassify(D,nReps,func)
[M,N,P] = size(D);

trialidvec = 1:N;
Levels     = 1:P;


template_data = zeros(M,P);
test_data     = zeros(M,N-1,P);
assignments   = zeros(1,N-1);
Rcorr         = NaN(P,N-1);
result        = zeros(nReps,P);

d = nReps/10;
for X = 1:nReps
    if mod(X,d) == 0, fprintf('.'); end
    
    for C = 1:P % Categories
        
        % Randomly select a spike train as the template
        template_ID = randi(N,1,P);
        
        for j = 1:P
            tind = template_ID(j) == trialidvec;
            template_data(:,j) = D(:, tind,j); % template spike trains
            test_data(:,:,j)   = D(:,~tind,j); % all other spike trains
        end
        
        
        % apply function to compare test data against each template
        for j = 1:P
            if ~any(template_data(:,j)), continue; end
            for n = 1:N-1
                if ~any(test_data(:,n,C)), continue; end
                Rcorr(j,n) = feval(func,[template_data(:,j) test_data(:,n,C)]);
            end
        end
        
        
        % find maximum Rcorr
        maxRcorr = max(Rcorr);
        
        for n = 1:N-1
            maxRidx = find(Rcorr(:,n)==maxRcorr(n));
            
            if numel(maxRidx) > 1
                % Randomly select one of the index values to make the
                % assignment
                r = randi(numel(maxRidx),1);
                maxRidx = maxRidx(r);
                
            elseif isempty(maxRidx) || isnan(maxRidx)
                % Make a random assignment
                maxRidx = randi(length(Levels),1);
                
            end
            
            assignments(n) = maxRidx;
            
        end
        
        
        % calculate percent correct for spike train assignments to each
        % category
        result(X,C) = sum(assignments == C) / (N-1);
    end
    
end


