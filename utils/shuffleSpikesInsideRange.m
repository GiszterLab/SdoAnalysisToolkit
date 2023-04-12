%% shuffleSpikesInsideRange
% Performs N_DRAWS double-random shuffling of interspike intervals of
% provided spikes between range given by T_START and T_STOP. 
% Spike time, start time, and end time should be in the same units. 

%  Maryam 

% TS Edits, comments, and Standardization

function shuff_timeStamps=shuffleSpikesInsideRange(timeStamps,T_START,T_STOP,N_DRAWS)
%% Maryam Function
%// rand generates random, equally spaced numbers between 0-1.
%Method uses this to pass default 1000; i.e. return 1000x random numbers
%equally spaced between 0 and 1. She then sorts these in ascending order.

%//Method randomly defines a starting point before the first time stamp,
%and then uses randomly generated indices lists (indx) to append, and then
%cumulatively sum random interspike intervals together to generate a
%random random shuffled spiketrain (within the bounds of the overall trial interval).

N_SPIKES = length(timeStamps); 

timeStamps  = reshape(timeStamps,1,N_SPIKES); %//convert to vector
timeStamps  = timeStamps(timeStamps<=T_STOP & timeStamps>=T_START); %//only take timestamps within range1:range2
delT        = diff(timeStamps); % ISIs
[~, indx]   = sort(rand(N_DRAWS,length(delT)),2); %// generate random indices between these two ranges
Interval    = T_STOP-T_START-sum(delT); % the first spike is allowed to be anywhere in this interval since we are shuffling their time differences
initPoint   = floor(rand(N_DRAWS,1)*Interval)+T_START;
initPoint(initPoint<T_START) = T_START; %// set not values of time less than 0
shuff_timeStamps = cumsum([initPoint delT(indx)],2); %sum over ISIs = spiketime

end