%% Load in data  
% Navigate to brainstorm database containing pre-processed data
clear all
subject = 'Ina';
[leftEpochs, rightEpochs, bimanualEpochs] = getEpochs(subject);
load('S:\CRE\People\Ciaran\chanLocs64coords')

%% Separate data into train and test sets and equalise the number of trials

allTrials = cat( 3, leftEpochs, rightEpochs, bimanualEpochs );
allLabels = [ones(size(leftEpochs,3),1); ones(size(rightEpochs,3),1)*2;  ones(size(bimanualEpochs,3),1)*3];

[allTrials,order] = shuffle(allTrials,3);
allLabels = allLabels(order);
 
cT = [3 5]; % centre of time window, seconds
srate = 256;
filtSpec.range = [6 12];

% s_plv_train = zeros(64,64, size(allTrials, 3));
for trial = 1 : size (allTrials , 3)
    s_plv_train(:,:,trial) = st_plv(allTrials(:,:,trial) , srate, filtSpec, cT ) ;
end

%  Get the PLV for every single-trial pair
chans = (1:64); allPairs = nchoosek(chans,2);

for pair = 1 : size(allPairs,1)
        st_pairs(:,pair)  = squeeze ( s_plv_train( allPairs(pair,1), allPairs(pair,2), : ) ) ;    
end

left = st_pairs(allLabels == 1,:);
leftLab = allLabels(allLabels==1);
right = st_pairs(allLabels == 2,:);
rightLab = allLabels(allLabels==2);

leftright = [left; right];
leftrightLab = [leftLab;rightLab];

for f = 1 : size(leftright,2)
    I4(f) = mutinfo(leftright(:,f)',leftrightLab');     % Left
end

[I4,index4] = sort(I4,2,'descend'); % Left
    
% plot(I4)

cp = cvpartition(leftrightLab,'kfold',5);

for fold = 1 : 5
    for k = 1 : 1 : 2016
        Mdl = fitcdiscr(leftright(cp.training(fold),index4(1:k)),leftrightLab(cp.training(fold)));
        acc(fold,k)= sum( leftrightLab(cp.test(fold)) == predict(Mdl,leftright(cp.test(fold),index4(1:k))) ) / cp.TestSize(fold) * 100;
    end
end

idx = fscmrmr(leftright,leftrightLab)

acc1= mean(acc,1);
figure(2), plot([1:1:2016],acc1)
%%
%     min_err = 1-max(validationAccuracy);
%     
%     if min_err < BestFreqErr
%         BestFreqErr = min_err;
%         BestFeatures = F;
%         bestF = [low high];
%     end
%     
%     fprintf('Min error: %d\n\n',min_err);
%     fprintf('Current best frequency band: %d-%d Hz. Min error:%d.\n\n',bestF(1),bestF(2),BestFreqErr);
%     
% end
%%
cvp = cvpartition(allLabels,'holdout',56)

Xtrain = st_pairs(cvp.training,:);
ytrain = allLabels(cvp.training,:);
Xtest  = st_pairs(cvp.test,:);
ytest  = allLabels(cvp.test,:);

nca = fscnca(Xtrain,ytrain,'FitMethod','none');
L = loss(nca,Xtest,ytest)

nca = fscnca(Xtrain,ytrain,'FitMethod','exact','Lambda',0,...
      'Solver','sgd','Standardize',true);
L = loss(nca,Xtest,ytest)

cvp = cvpartition(ytrain,'kfold',5);
numvalidsets = cvp.NumTestSets;

n = length(ytrain);
lambdavals = linspace(0,20,20)/n;
lossvals = zeros(length(lambdavals),numvalidsets);

for i = 1:length(lambdavals)
    for k = 1:numvalidsets
        X = Xtrain(cvp.training(k),:);
        y = ytrain(cvp.training(k),:);
        Xvalid = Xtrain(cvp.test(k),:);
        yvalid = ytrain(cvp.test(k),:);

        nca = fscnca(X,y,'FitMethod','exact', ...
             'Solver','sgd','Lambda',lambdavals(i), ...
             'IterationLimit',30,'GradientTolerance',1e-4, ...
             'Standardize',true);
                  
        lossvals(i,k) = loss(nca,Xvalid,yvalid,'LossFunction','classiferror');
    end
end

meanloss = mean(lossvals,2);

figure()
plot(lambdavals,meanloss,'ro-')
xlabel('Lambda')
ylabel('Loss (MSE)')
grid on

[~,idx] = min(meanloss) % Find the index
bestlambda = lambdavals(idx) % Find the best lambda value
bestloss = meanloss(idx)

nca = fscnca(Xtrain,ytrain,'FitMethod','exact','Solver','sgd',...
    'Lambda',bestlambda,'Standardize',true,'Verbose',1);

figure()
plot(nca.FeatureWeights,'ro')
xlabel('Feature index')
ylabel('Feature weight')
grid on

tol    = 0.02;
selidx = find(nca.FeatureWeights > tol*max(1,max(nca.FeatureWeights)))

L = loss(nca,Xtest,ytest)

features = Xtrain(:,selidx);
% svmMdl = fitcsvm(features,ytrain);
% L = loss(svmMdl,Xtest(:,selidx),ytest)

trainss = table(features,ytrain);
traintest = table(Xtest(:,selidx),ytest);

chans = extractfield(chanLocs64coords,'labels')';
best = [char(chans(allPairs(selidx,1))) char(chans(allPairs(selidx,2)))]
