function varargout = BasicClassifier2(D,nReps,func,par)
% R = BasicClassifier2(D)
% R = BasicClassifier2(D,nReps)
% R = BasicClassifier2(D,nReps,func)
% R = BasicClassifier2(D,nReps,func,par)
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
% If par is true, then the Parallel Processing Toolbox will be used.
% (default = false).
%
% Returns a matrix R with size nReps x P, where nReps is each repetition
% specified by the nReps input parameter and P is the number of categories
% in the data matrix, D.
%
% A secound output can be returned with the results from classifying a
% shuffled version of D.  Observations in the data matrix D are shuffled
% across categories.
%
% See also, BasicClassifier
%
% Daniel.Stolzberg@gmail.com    2015


if nargin == 1, nReps = 500; end
if nargin < 3 || isempty(func)
    func = @sum;
end
if nargin < 4, par = false; end

if par
    varargout{1} = doclassify_par(D,nReps,func);
else
    varargout{1} = doclassify(D,nReps,func);
end

if nargout > 1
    [M,N,P] = size(D);
    Dperm = reshape(D, [M N*P]);
    Dperm = reshape(Dperm(:,randperm(N*P)), [M,N,P]);
    if par
        varargout{2} = doclassify_par(Dperm,nReps,func);
    else
        varargout{2} = doclassify(Dperm,nReps,func);
    end
end





function result = doclassify(D,nReps,func)
[M,N,P] = size(D);

trialidvec = 1:N;

template_data = zeros(M,P);
test_data     = zeros(M,N-1,P);
assignments   = zeros(N-1,1);
result        = zeros(nReps,P);

for X = 1:nReps
    
    R = NaN(N-1,P); % Reset Rcorr
    
    % Randomly select a spike train as the template
    template_ID = randi(N,1,P);
    
    for k = 1:P
        tind = template_ID(k) == trialidvec;
        template_data(:,k) = D(:, tind,k); % template spike trains
        test_data(:,:,k)   = D(:,~tind,k); % all other spike trains
    end
    
    
    % apply function to compare test data against each template
    for k = 1:P
        % Skip templates with no spikes
        if ~any(template_data(:,k)), continue; end
        for j = 1:N-1
            R(j,k) = feval(func,[template_data(:,k) test_data(:,j,k)]);
        end
    end
    
    R(isnan(R)) = 0;
    
    % find maximum Rcorr
    maxRcorr = max(R,[],2);
    
    for j = 1:N-1
        maxRidx = find(R(j,:)==maxRcorr(j));
        
        if numel(maxRidx) > 1
            % Randomly select one of the index values to make the
            % assignment
            r = randi(numel(maxRidx),1);
            maxRidx = maxRidx(r);            
        end
        
        assignments(j) = maxRidx;
    end
    
    % calculate percent correct for spike train assignments to each
    % category
    for k = 1:P
        result(X,k) = sum(assignments == k);
    end
    
end

result = result / (N-1);






function result = doclassify_par(D,nReps,func)
[M,N,P] = size(D);

cats = repmat(1:P,N-1,1);
trialidvec = 1:N;

result = zeros(nReps,P);

parfor X = 1:nReps
    template_data = zeros(M,P);
    test_data     = zeros(M,N-1,P);
    assignments   = zeros(N-1,1);
    
    R = NaN(N-1,P); % Reset Rcorr
    
    % Randomly select a spike train as the template
    template_ID = randi(N,1,P);
    
    for k = 1:P
        tind = template_ID(k) == trialidvec;
        template_data(:,k) = D(:, tind,k); % template spike trains
        test_data(:,:,k)   = D(:,~tind,k); % all other spike trains
    end
    
    
    % apply function to compare test data against each template
    for k = 1:P
        % Skip templates with no spikes
        if ~any(template_data(:,k)), continue; end
        for j = 1:N-1
            R(j,k) = feval(func,[template_data(:,k) test_data(:,j,k)]);
        end
    end
    
    R(isnan(R)) = 0;
    
    % find maximum Rcorr
    maxRcorr = max(R,[],2);
    
    for j = 1:N-1
        maxRidx = find(R(j,:)==maxRcorr(j));
        
        if numel(maxRidx) > 1
            % Randomly select one of the index values to make the
            % assignment
            r = randi(numel(maxRidx),1);
            maxRidx = maxRidx(r);            
        end
        
        assignments(j) = maxRidx;
    end
    
    % calculate percent correct for spike train assignments to each
    % category
    result(X,:) = sum(repmat(assignments,1,P) == cats);
    
    
end

result = result / (N-1);



