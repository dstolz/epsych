function [handles,xmin,xmax,varargout] = update_TTLhistory_SanesLab(handles,starttime,event)
%Custom function for SanesLab epsych
%
%This function updates the TTL history for plotting purposes
%
%Inputs: 
%   handles: GUI handles
%   starttime: experiment start time
%   event: event time
%
%Outputs:
%   varargout{1} = timestamps;
%   varargout{2} = trial_hist;
%   varargout{3} = spout_hist;
%   varargout{4} = type_hist;
%   varargout{5} = poke_hist;
%   varargout{6} = water_hist;
%   varargout{7} = sound_hist;
%   varargout{8} = response_hist;
%   varargout{9} = light_hist;
%
%
%Example usage: [timestamps,trial_hist,spout_hist] = update_TTLHist_SanesLab(handles,starttime,event)
%
%Written by ML Caras 7.25.2016

global PERSIST
persistent timestamps spout_hist trial_hist type_hist poke_hist sound_hist water_hist response_hist light_hist

%If this is a fresh run, clear persistent variables 
if PERSIST == 1
    timestamps = [];
    spout_hist = [];
    trial_hist = [];
    type_hist = [];
    poke_hist = [];
    sound_hist = [];
    water_hist = [];
    response_hist = [];
    light_hist = [];
    
    PERSIST = 2;
end

%Determine current time
currenttime = etime(event.Data.time,starttime);

%Update timetamp
timestamps = [timestamps;currenttime];

%Update Poke History
poke_hist = updateHist_SanesLab('Poke_TTL',poke_hist,handles);

%Update Spout History
spout_hist = updateHist_SanesLab('Spout_TTL',spout_hist,handles);

%Update Water History
water_hist = updateHist_SanesLab('Water_TTL',water_hist,handles);

%Update Sound History
sound_hist = updateHist_SanesLab('Sound_TTL',sound_hist,handles);

%Update Response History
response_hist = updateHist_SanesLab('RespWin_TTL',response_hist,handles);

%Update trial TTL history
trial_hist = updateHist_SanesLab('InTrial_TTL',trial_hist,handles);

%Update trial type history
type_hist = updateHist_SanesLab('TrialType',type_hist,handles);

%Update room light history
light_hist = updateHist_SanesLab('Light_TTL',light_hist,handles);

%Limit matrix size
xmin = timestamps(end)- 10;
xmax = timestamps(end)+ 10;
ind = find(timestamps > xmin+1 & timestamps < xmax-1);


timestamps = timestamps(ind);

if ~isempty(trial_hist)
    trial_hist = trial_hist(ind);
end

if ~isempty(spout_hist)
    spout_hist = spout_hist(ind);
end

if ~isempty(type_hist)
    type_hist = type_hist(ind);
end

if ~isempty(poke_hist)
    poke_hist = poke_hist(ind);
end

if ~isempty(water_hist)
    water_hist = water_hist(ind);
end

if ~isempty(sound_hist)
    sound_hist = sound_hist(ind);
end

if ~isempty(response_hist)
    response_hist = response_hist(ind);
end

if ~isempty(light_hist)
    light_hist = light_hist(ind);
end


%Pass to output variables
varargout{1} = timestamps;
varargout{2} = trial_hist;
varargout{3} = spout_hist;
varargout{4} = type_hist;
varargout{5} = poke_hist;
varargout{6} = water_hist;
varargout{7} = sound_hist;
varargout{8} = response_hist;
varargout{9} = light_hist;




