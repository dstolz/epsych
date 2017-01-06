%% Create folder structure


S = {'BASS','BLACKFOREST','CC','LEIA','LUKE','MARIE','MINNOW','PAUL','HALIBUT','GEORGE','TROUT','BISCOTTI'};

G = {'NH' 'ED' 'ED' 'ED' 'NH' 'NH' 'NH' 'NH' 'ED' 'ED' 'ED' 'ED'}; % groups

C = {'RSS'}; % conditions

for i = 1:numel(S)
    r = [G{i} '-' S{i}];
    if ~isdir(r), mkdir(r); end
    
    s = fullfile(r,'structurals');
    if ~isdir(s), mkdir(s); end
    
    s = fullfile(r,'NII');
    if ~isdir(s), mkdir(s); end
    
    for c = C(:)'
        s = fullfile(r,char(c));
        if ~isdir(s), mkdir(s); end
    end
end



disp('done')