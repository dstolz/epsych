function C = TrialFcn_DoubleWavBuffer(C)
% C = TrialFcn_DoubleWavBuffer(C)
%
% Daniel.Stolzberg@gmail.com 2015



global G_DA
 
persistent buffer bufferSize startidx smallBufferSize lastID



if C.tidx == 1 % setup
    lastID = 0;
    startidx = 1;
%     StimFile = 'TEST_DMR.wav';
    StimFile = 'TEST_RAMPS.wav';
    fprintf('Loading stimulus file: ''%s'' ...',StimFile)
    [buffer,Fs] = audioread(StimFile);
    buffer = single(buffer); % double -> single
    buffer = buffer(:)'; % make sure buffer is a row vector
    fprintf(' done\n')
    
    bufferSize = length(buffer);
    
    % It takes ~160 ms to write one second of data at ~100 kHz sampling
    % rate.  
    smallBufferSize = floor(Fs*10); % size of the small buffer
    
    
    % set buffer size
    G_DA.SetTargetVal('Stim.Buffer1Size',smallBufferSize);
    G_DA.SetTargetVal('Stim.Buffer2Size',smallBufferSize);

    
    BufferID = 1;
    
    G_DA.ZeroTarget('Stim.Buffer1Data');
    G_DA.ZeroTarget('Stim.Buffer2Data');

    
else
    
    % Check which buffer is currently playing and write to the other one
    if      G_DA.GetTargetVal('Stim.Buffer1Playing')
        BufferID = 2;
        
    elseif  G_DA.GetTargetVal('Stim.Buffer2Playing')
    	BufferID = 1;
    else
        error('NEITHER BUFFER IS PLAYING!')
        
    end
%     fprintf('Buffer %d is not playing\n',BufferID)
end





if lastID == BufferID, return; end % already wrote to this buffer


if startidx + smallBufferSize > bufferSize
    smallBufferSize = bufferSize - startidx;
    
    % reset buffer size
    G_DA.SetTargetVal(sprintf('Stim.Buffer%dSize',BufferID),smallBufferSize);
end


% fprintf('Buffer %d value before = %0.20f\t',BufferID, ...
%     G_DA.GetTargetVal(sprintf('Stim.PROBE%d',BufferID)))
% write next small buffer while the other one is playing
% tic
e = G_DA.WriteTargetVEX(sprintf('Stim.Buffer%dData',BufferID), ...
    0, 'F32', buffer(startidx:startidx+smallBufferSize-1));
% toc
% fprintf('after = %0.20f\n',G_DA.GetTargetVal(sprintf('Stim.PROBE%d',BufferID)))

if e
    fprintf('Trigger index % 5d updated BufferID %d from % 9d to % 9d\n', ...
        C.tidx,BufferID,startidx,startidx+smallBufferSize-1)
else
    error('Unable to update BufferID %d\n',BufferID)
end





startidx = startidx + smallBufferSize;

lastID = BufferID;


if C.tidx == 1   
    G_DA.SetTargetVal('Stim.Enable1',1);

    G_DA.SetTargetVal('Stim.StartPlaying',1);
    pause(0.001);
    G_DA.SetTargetVal('Stim.StartPlaying',0);
    

    G_DA.SetTargetVal('Stim.Enable2',1);
    
%     G_DA.WriteTargetVEX('Stim.Buffer2Data', ...
%         0, 'F32', buffer(startidx:startidx + smallBufferSize));
%     G_DA.WriteTargetV('Stim.Buffer2Data',0,buffer(startidx:startidx + smallBufferSize));
%     G_DA.SetTargetVal('Stim.Enable2',1);

%     startidx = startidx + smallBufferSize + 1;
%     lastID = 2;
end


















