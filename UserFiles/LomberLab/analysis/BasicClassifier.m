function varargout = BasicClassifier(D,nReps,func)
% R = BasicClassifier(D)
% R = BasicClassifier(D,nReps)
% R = BasicClassifier(D,nReps,func)
% [R,Rshuff] = BasicClassifier(D,...)
%
% D is an MxNxP data matrix with M samples from N observations in P
% categories.
%
% Optionally, the number of repetitions can be specified by the second
% input, nReps (default: nReps = 500).  Note that the randomization is
% reproducible if setting the seed number prior to calling this function
% (see help on the rng function for more info).
%
% The default function for classification is SUM, but this can be specified
% as any function that works along the first dimension of the data matrix,
% D, such as MEAN, VAR, etc. 
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
    varargout{2} = doclassify(Dperm,nReps,func);
end






function result = doclassify(D,nReps,func)
[~,N,P] = size(D);

S = squeeze(feval(func,D));

trialidvec = 1:N;
Levels     = 1:P;


template_data = zeros(1,P);
test_data     = zeros(N-1,P);
assignments   = zeros(N-1,1);
result        = zeros(nReps,P);


for X = 1:nReps
    
    for C = 1:P % Categories
        
        % Randomly select a spike train as the template
        template_ID = randi(N,1,P);
        
        for j = 1:P
            tind = template_ID(j) == trialidvec;
            template_data(j) = S( tind,j); % template spike trains
            test_data(:,j)   = S(~tind,j); % all other spike trains
        end
        
        
        % absolute distance between test data and template data
        adist = abs(test_data - repmat(template_data,N-1,1));
        
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
            
            assignments(j) = mindistidx;
        end
        
        % calculate percent correct for spike train assignments to each
        % category
        result(X,C) = sum(assignments == C) / (N-1);
    end
    
end


