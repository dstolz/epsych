% Calculates bivariate van Rossum-Distance using kernels and markage vectors
% x_spikes and y_spikes are matrices with the same number of spike trains (rows)
% rsd_tc: exponential decay (time scale parameter)
%
% For a detailed description of the methods please refer to:
%
% Houghton C, Kreuz T:
% On the efficient calculation of van Rossum distances.
% Network: Computation in Neural Systems, submitted (2012).
%
% Copyright:  Thomas Kreuz, Conor Houghton, Charles Dillon
%
%

function D = vanRossum(x_spikes,y_spikes,rsd_tc)

D =0;
x_num_spikes = length(x_spikes);
y_num_spikes = length(y_spikes);

if rsd_tc ~=Inf
    
    exp_x_spikes = exp(x_spikes/rsd_tc);
    exp_y_spikes = exp(y_spikes/rsd_tc);
    inv_exp_x_spikes = 1./exp_x_spikes;
    inv_exp_y_spikes = 1./exp_y_spikes;
    
    x_markage = ones(1,x_num_spikes);
    for sc=2:x_num_spikes
        x_markage(sc)=1+x_markage(sc-1)*exp_x_spikes(sc-1)*inv_exp_x_spikes(sc);
    end
    y_markage = ones(1,y_num_spikes);
    for sc=2:y_num_spikes
        y_markage(sc)=1+y_markage(sc-1)*exp_y_spikes(sc-1)*inv_exp_y_spikes(sc);
    end
    
    xmat=bsxfun(@rdivide,exp_x_spikes,exp_x_spikes');
    D=D+x_num_spikes+2*sum(sum(tril(xmat,-1)));
    ymat=bsxfun(@rdivide,exp_y_spikes,exp_y_spikes');
    D=D+y_num_spikes+2*sum(sum(tril(ymat,-1)));
    
    D=D-2*f_altcor_exp2(exp_x_spikes,exp_y_spikes,inv_exp_x_spikes,inv_exp_y_spikes,x_markage,y_markage);

    D = sqrt(2/rsd_tc*D);
    
else                                                                   % rsd_tc = Inf --- pure rate code
    
    D = x_num_spikes * (x_num_spikes - y_num_spikes) + y_num_spikes * (y_num_spikes-x_num_spikes);
    
end


function Dxy = f_altcor_exp2(exp_x_spikes,exp_y_spikes,inv_exp_x_spikes,inv_exp_y_spikes,x_markage,y_markage)

x_num_spikes = length(exp_x_spikes);
y_num_spikes = length(exp_y_spikes);

Dxy=0;
for i=1:x_num_spikes
    dummy=find(exp_y_spikes<=exp_x_spikes(i),1,'last');
    if ~isempty(dummy)
        Dxy = Dxy + exp_y_spikes(dummy)*inv_exp_x_spikes(i)*y_markage(dummy);
    end
end

for i=1:y_num_spikes
    dummy=find(exp_x_spikes<exp_y_spikes(i),1,'last');
    if ~isempty(dummy)
        Dxy = Dxy + exp_x_spikes(dummy)*inv_exp_y_spikes(i)*x_markage(dummy);
    end
end