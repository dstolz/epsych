
function Spikes = pp_save_manual_sort(Pname,subject,session,Spikes,channel,spikes )
%
%  pp_save_manual_sort( subject, session, Spikes, channel, spikes )
%    Incorporates the manual changes from splitmerge tool into the Spikes
%    struct, changes flag to indicate channel has been sorted, and saves
%    the updated file.
%    The final clus are printed to the command window.
%
%  KP, 2016-04; last updated 2016-04-21 JDY
% 
Spikes.sorted(channel)	=	spikes;
Spikes.man_sort(channel) = 1;

%Save Spikes structure
% savedir	=	'/Users/kpenikis/Documents/SanesLab/Data/processed_data';
% savedir	=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/processed_data';
savedir		=	Pname;
fprintf('\nsaving data...\n')
savename = sprintf('%s_sess-%s_Spikes',subject,session);
save(fullfile(savedir,subject,savename),'Spikes','-v7.3');

%Print clu labels on screen to facilitate record keeping
fprintf('Manual sorts saved for channel %i. \n', channel)
SU = Spikes.sorted(channel).labels(Spikes.sorted(channel).labels(:,2)==2,1)';
MU = Spikes.sorted(channel).labels(Spikes.sorted(channel).labels(:,2)==3,1)';
fprintf('SU clus: \n')
for cl=SU
    fprintf(' %i \n',SU(SU==cl))
end
fprintf('MU clus: \n')
for cl=MU
    fprintf(' %i \n',MU(MU==cl))
end


end

