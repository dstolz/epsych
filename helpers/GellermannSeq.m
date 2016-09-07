function G = GellermannSeq(plot)
% G = GellermannSeq([plot])
%
% Generate a sequence of trials for a two-alternative task based on the
% rules outlined by Gellermann, L.W. Chance orders of alternatig stimuli in
% visual discrimination experiments. J. Gen. Psychol. 42: 206-208, 1933
%
% Optionally plot data
%
% Daniel.Stolzberg@gmail.com 2016


if ~nargin, plot = false; end

n = 10;
p = zeros(2^14,n);
for i = 1:n
    p(:,i) = randperm(2^14);
end

m = [-ones(2^12,n); ones(2^12,n)];
m = unique(m(p),'rows'); clear p
if plot, imagesc(m); title(sprintf('n = %d',size(m,1))); pause(2); end

% rule 1
ind = sum(m,2) ~= 0;
m(ind,:) = [];
if plot, imagesc(m); title(sprintf('n = %d',size(m,1))); pause(2); end

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
if plot, imagesc(m); title(sprintf('n = %d',size(m,1))); pause(2); end

% rule 3
ind = abs(sum(m(:,1:n/2),2))>1;
ind = ind | abs(sum(m(:,n/2+1:end),2))>1;
m(ind,:) = [];
if plot, imagesc(m); title(sprintf('n = %d',size(m,1))); pause(2); end

% rule 4
dm = diff(m,1,2)/2;
ind = sum(abs(dm),2) ~= n/2;
m(ind,:) = [];
if plot, imagesc(m); title(sprintf('n = %d',size(m,1))); pause(2); end

% rule 5
% rule 5 is implied (?)

% Construct trial sequence
a = m(1:size(m,1)/2,:);
b = m(size(m,1)/2+1:end,:);

ridx = randperm(size(a,1)); a = a(ridx,:);
ridx = randperm(size(b,1)); b = b(ridx,:);

m = [a fliplr(b)];

G = reshape(m',1,numel(m));










