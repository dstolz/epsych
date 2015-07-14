function varargout = BasicClassifier(D,nReps,par)
% R = BasicClassifier(D)
% R = BasicClassifier(D,nReps)
% R = BasicClassifier(D,nReps,par)
% [R,Rshuff] = BasicClassifier(D,...)
%
% D is an MxN data matrix with M observations in N
% categories.
%
% Optionally, the number of repetitions can be specified by the second
% input, nReps (default: nReps = 500).  Note that the randomization is
% reproducible if setting the seed number prior to calling this function
% (see help on the rng function for more info).
%
% If par is true, then the Parallel Processing Toolbox will be used.
% (default = false).
%
% Returns a matrix R with size nReps x N, where nReps is each repetition
% specified by the nReps input parameter and N is the number of categories
% in the data matrix, D.
%
% A secound output can be returned with the results from classifying a
% shuffled version of D.  Observations in the data matrix D are shuffled
% across categories.
%
% See also, BasicClassifier2
%
% Daniel.Stolzberg@gmail.com    2015


if nargin == 1, nReps = 500; end
if nargin < 3,  par   = false; end

if par
    varargout{1} = doclassify_par(D,nReps);
else
    varargout{1} = doclassify(D,nReps);
end

if nargout > 1
    [M,N] = size(D);
    Dperm = reshape(D(randperm(M*N)), [M N]);
    if par
        varargout{2} = doclassify_par(Dperm,nReps);
    else
        varargout{2} = doclassify(Dperm,nReps);
    end
end






function result = doclassify(D,nReps)
[N,P] = size(D);

trialidvec = 1:N;
Levels     = 1:P;
cats       = repmat(Levels,N-1,1);

template_data = zeros(1,P);
test_data     = zeros(N-1,P);
result        = zeros(nReps,P);


for X = 1:nReps
        assignments = zeros(N-1,P);

        % Randomly select a spike train as the template
        template_ID = randi(N,1,P);
        
        for k = 1:P
            tind = template_ID(k) == trialidvec;
            template_data(k) = D( tind,k); % template spike trains
            test_data(:,k)   = D(~tind,k); % all other spike trains
        end
        
        for k = 1:P
            % absolute distance between test data and template data
            adist = abs(test_data - template_data(k));
            
            % classify into minimum absolute distance
            mindist = min(adist,[],2);
            
            for j = 1:N-1
                % find all categories that are at the minimum distance from the
                % current template
                mindistidx = find(mindist(j) == adist(j,:));
                
                if numel(mindistidx) > 1
                    % Randomly select one of the index values to make the
                    % assignment
                    r = randi(numel(mindistidx),1);
                    mindistidx = mindistidx(r);
                end
                
                assignments(j,k) = mindistidx;
            end
            
            
        end
        
        % Add up hits for spike train assignments to each category
        result(X,:) = sum(assignments == cats);
        
end

% Mean hit rate for each category
result = result / (N-1);






function result = doclassify_par(D,nReps)
[N,P] = size(D);

trialidvec = 1:N;
Levels     = 1:P;
cats       = repmat(Levels,N-1,1);

result        = zeros(nReps,P);


parfor X = 1:nReps
    template_data = zeros(1,P);
    test_data     = zeros(N-1,P);    
    assignments   = zeros(N-1,P);
    
    % Randomly select a spike train as the template
    template_ID = randi(N,1,P);
    
    for k = 1:P
        tind = template_ID(k) == trialidvec;
        template_data(k) = D( tind,k); % template spike trains
        test_data(:,k)   = D(~tind,k); % all other spike trains
    end
    
    for k = 1:P
        % absolute distance between test data and template data
        adist = abs(test_data - template_data(k));
        
        % classify into minimum absolute distance
        mindist = min(adist,[],2);
        
        for j = 1:N-1
            % find all categories that are at the minimum distance from the
            % current template
            mindistidx = find(mindist(j) == adist(j,:));
            
            if numel(mindistidx) > 1
                % Randomly select one of the index values to make the
                % assignment
                r = randi(numel(mindistidx),1);
                mindistidx = mindistidx(r);
                
            elseif isempty(mindistidx)
                % Make a random assignment
                mindistidx = randi(length(Levels),1);
                
            end
            
            assignments(j,k) = mindistidx;
        end
        
        
    end
    
    % Add up hits for spike train assignments to each category
    result(X,:) = sum(assignments == cats);
    
end

% Mean hit rate for each category
result = result / (N-1);



