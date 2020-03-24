function [s_plv] = st_plv(eegData, srate, filtSpec, cT )

numChannels = size(eegData, 2);
t1 = ceil(cT(1)*srate);
t2 = ceil(cT(2)*srate);

disp('Filtering data...');
% filtPts = fir1(filtSpec.order, 2/srate*filtSpec.range);
% filteredData = filter(filtPts, 1, eegData, [], 2);

% [b,a] = butter(5,filtSpec.range/(srate/2),'bandpass');
% filteredData = filtfilt(b,a,eegData);

for channelCount = 1:numChannels
    eegData(:,channelCount) = angle(hilbert(squeeze(eegData(:,channelCount))));
end

s_plv = zeros(numChannels, numChannels);
for channelCount = 1:numChannels-1
    channelData = squeeze(eegData(t1:t2,channelCount))';
    for compareChannelCount = channelCount+1:numChannels
        compareChannelData = squeeze(eegData(t1:t2,compareChannelCount))';
        s_plv(channelCount, compareChannelCount) = abs(sum(exp(1i*(channelData - compareChannelData)), 2))/length(channelData);
    end
end
s_plv = squeeze(s_plv);
return;

% figure, plot(eegData(:,1))
% hold on
% plot(filteredData(:,1))
% figure, plot(channelData);hold on; plot(compareChannelData);hold on; 
% figure, plot(channelData - compareChannelData);
