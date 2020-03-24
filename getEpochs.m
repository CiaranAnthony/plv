function [leftEpochs, rightEpochs, bimanualEpochs] = getEpochs(subject) 

% Navigate to brainstorm database containing pre-processed data
cd(['C:\Users\2027775m\Documents\brainstorm_db\myData\data\',char(subject)]);

% Adjust variables for inconsitencies between subject file names
if any(contains(subject, 'Ailis')) == 1 || any(contains(subject, 'Radha')) == 1
    raw = dir('adjusted*'); raw = raw.name;
    z = 0;
else
    raw = dir('Session*'); raw = raw.name;
    z = 0;
end

cd(['C:\Users\2027775m\Documents\brainstorm_db\myData\data\',char(subject),'\',char(raw)]);

load('brainstormstudy', 'BadTrials');
if isempty(BadTrials) == 1
    BadTrials = {};
end

leftlist = dir('**\*Left*');
rightlist = dir('**\*Right*');
bimanuallist = dir('**\*Bimanual*');

% Get leftEpochs
n=0;
for i = 1 : length(leftlist)
    if any(contains(BadTrials, leftlist(i).name)) == 0 && any(contains(leftlist(i).name,'interpbad.mat')) == z
        n=n+1;
        load([leftlist(i).folder,'\',leftlist(i).name],'F')
        if size(F,1) == 64
        leftEpochs(:,:,n) = permute ( F(1:end,:) , [2 1] );
        elseif size(F,1) == 66
        leftEpochs(:,:,n) = permute ( F(2:end-1,:) , [2 1] );    
        end
        clear F
    end    
end
% Get rightEpochs
n=0;        
for i = 1 : length(rightlist)
    if any(contains(BadTrials, rightlist(i).name)) == 0 && any(contains(rightlist(i).name,'interpbad.mat')) == z
        n=n+1;
        load([rightlist(i).folder,'\',rightlist(i).name],'F')        
        if size(F,1) == 64
        rightEpochs(:,:,n) = permute ( F(1:end,:) , [2 1] );
        elseif size(F,1) == 66
        rightEpochs(:,:,n) = permute ( F(2:end-1,:) , [2 1] );    
        end
        clear F
    end    
end   
% Get bimanualEpochs
n=0;        
for i = 1 : length(bimanuallist)
    if any(contains(BadTrials, bimanuallist(i).name)) == 0 && any(contains(bimanuallist(i).name,'interpbad.mat')) == z
        n=n+1;
        load([bimanuallist(i).folder,'\',bimanuallist(i).name],'F')        
        if size(F,1) == 64
        bimanualEpochs(:,:,n) = permute ( F(1:end,:) , [2 1] );
        elseif size(F,1) == 66
        bimanualEpochs(:,:,n) = permute ( F(2:end-1,:) , [2 1] );    
        end
        clear F
    end    
end 

return;