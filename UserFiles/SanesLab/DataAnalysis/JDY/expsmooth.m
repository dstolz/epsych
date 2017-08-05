function X  = expsmooth( X, fs, tau )
% EXPSMOOTH Exponential smoothing. 
%
%   Y=EXPSMOOTH(X,FS,TAU) for a given input sequence X sampled 
%   at FS Hertz and for time constant TAU given in milliseconds
%   returns exponentially smoothed output sequence Y.
%
%   Inputs
%           X input signal as a column vector, or matrix
%             of input signals as column vectors.
%
%           FS sampling frequency (Hz).
%
%           TAU time constant (ms), i.e., the time it takes for 
%               the step response of the exponential smoother
%               to reach 63.21% of its final (asymptotic) value,
%               i.e., 1-exp(-[TIME=TAU]/TAU)=0.6321. Similarly, 
%               at TIME=5*TAU the output will reach 99.33% 
%               of its final value [1]: 1-exp(-5)=0.9933. The
%               following inline functions may be useful:
%
%                   tau2alpha = @(TAU,T)( exp(-T/TAU) );
%                   alpha2tau = @(ALPHA,T)( -T/log(ALPHA) );
%                   ratesteady = @(TIME,TAU)( 1-exp(-TIME/TAU) );
%
%               where T is the sampling period (T=1/FS) and 
%               ALPHA is a smoothing constant.
%
%   Outputs 
%           Y exponentially smoothed signal(s) as column vectors,
%             such that:
%
%                   Y(n) = ALPHA*Y(n-1) + (1-ALPHA)*X(n)
%
%           where n is discrete-time index.
%
%   Reference
%           [1] Greg Stanley, 2011, "Exponential filtering", 
%               url: http://tinyurl.com/exponential-filtering
%
%   Example
%           % define sampling frequency (Hz)
%           fs = 8E3;
%
%           % define signal duration (s)
%           duration = 0.1;
%
%           % get signal length (samples)
%           N = round( fs*duration );
%
%           % generate signal time vector (s)
%           time = [0:N-1]/fs;
%
%           % generate input signals (sinusoids in noise)
%           X = 0.5*randn( N, 2 ) + [ sin(2*pi*50*time+pi/9); sin(2*pi*10*time+pi/3) ].';
%
%           % time constant (ms)
%           tau = 5;
%           
%           % apply exponential smoothing 
%           Y = expsmooth( X, fs, tau );
%
%           % plot the results
%           figure('Position', [10 10 500 350], 'PaperPositionMode', 'auto', 'Visible', 'on', 'color', 'w'); 
%
%           subplot(211); 
%           plot( time, X ); 
%           xlabel( 'Time (s)' );
%           ylabel( 'Amplitude' );
%           title( 'Noisy signals' );
%           set( gca, 'box', 'off' );
%           axis( [min(time) max(time) min(X(:))-0.1*max(X(:)) 1.1*max(X(:))] );
%
%           subplot(212); 
%           plot( time, Y );
%           xlabel( 'Time (s)' );
%           ylabel( 'Amplitude' );
%           title( 'Smoothed signals' );
%           set( gca, 'box', 'off' );
%           axis( [min(time) max(time) min(Y(:))-0.1*max(Y(:)) 1.1*max(Y(:))] );
%
%           % print results to png file
%           print( '-dpng', 'expsmooth.png' );

%   Author: Kamil Wojcicki, UTD, January 2012.


    % check for correct number of input arguments
    if( nargin~=3 ), error( sprintf('Incorrect number of input arguments.\nType "help %s" for usage help.\n', mfilename) ); end;

    % T sampling period (ms)
    T = 1E3/fs;

    % compute the smoothing constant
    alpha = exp( -T/tau );

    % get number of column vector signals (M) and their lengths (N)
    [ N, M ] = size( X );

    % for each column vector signal
    for m = 1:M

        % for each sample
        for n = 2:N

            % apply the exponential smoother [1]
            X(n,m) = alpha*X(n-1,m) + (1-alpha)*X(n,m);
        end

    end


% EOF 