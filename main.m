%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clayton Kramp and Katrina Steinman
% CSCI 507 Final Project
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all

I=rgb2gray(imread('images/D234.png'));
I = imresize(I, 0.5);
imshow(I)
%I = imcomplement(I);
I =~im2bw(I,0.4);
I = bwareaopen(I,10);
numSymbols = 1;
symbolsExtracted = {};

[Labels numConnectedComponents]=bwlabel(I);
props = regionprops(Labels,'BoundingBox');

hold on
for n=1:size(props,1)
    rectangle('Position',props(n).BoundingBox,'EdgeColor','r','LineWidth',2)
end
hold off

pause

path = 'Data/';

tempTrainImages = loadMNISTImages(strcat(path,'Train/train-images-idx3-ubyte'));
TrainImages = zeros(28, 28, 1, size(tempTrainImages, 2), 'single');
for i = 1:size(tempTrainImages, 2)
    TrainImages(:,:,1,i) = reshape(tempTrainImages(1:784, i), [28 28]);
end
TrainLabels = loadMNISTLabels(strcat(path,'Train/train-labels-idx1-ubyte'));

tempTestImages = loadMNISTImages(strcat(path,'Test/t10k-images-idx3-ubyte'));
TestImages = zeros(28, 28, 1, size(tempTestImages, 2), 'single');
for i = 1:size(tempTestImages, 2)
    TestImages(:,:,1,i) = reshape(tempTestImages(1:784, i), [28 28]);
end
TestLabels = loadMNISTLabels(strcat(path, 'Test/t10k-labels-idx1-ubyte'));

[trainSymbols, testSymbols, trainSymLabels, testSymLabels] = ...
    processSymbols('Data/Symbols/');

symbolLayers = [ imageInputLayer([28 28 1])
            convolution2dLayer(5,20)
            reluLayer
            maxPooling2dLayer(2, 'Stride', 2)
            fullyConnectedLayer(3)
            softmaxLayer
            classificationLayer() ];
        
batch = 15;
trainOptions = trainingOptions( 'sgdm',...
    'MiniBatchSize', batch,...
    'Plots', 'training-progress',...
    'MaxEpochs',20);
nnSymbol = trainNetwork(trainSymbols, trainSymLabels, symbolLayers, trainOptions);
testing = nnSymbol.classify(testSymbols);
testAccuracy = sum(testing == testSymLabels) / numel(testSymLabels);
fprintf("Test Accuracy for Symbols is %f\n", testAccuracy);

layers = [  imageInputLayer([28 28 1])
            convolution2dLayer(5,20)
            reluLayer
            maxPooling2dLayer(2, 'Stride', 2)
            fullyConnectedLayer(10)
            softmaxLayer
            classificationLayer()   ];
        
batch = 50;
trainOptions = trainingOptions( 'sgdm',...
    'MiniBatchSize', batch,...
    'Plots', 'training-progress',...
    'MaxEpochs',1);
nn = trainNetwork(TrainImages, categorical(TrainLabels), layers, trainOptions);
testing = nn.classify(TestImages);
testAccuracy = sum(testing == categorical(TestLabels)) / numel(TestLabels);
fprintf("Test Accuracy is for numerics is %f\n", testAccuracy);

for i=1:numConnectedComponents
    [row,col] = find(Labels == i);
    symbol = zeros(28, 28, 1, 1);
    newImg = imgaussfilt(single(I(min(row):max(row),min(col):max(col))),1);
    symbol(:,:,1,1) = padarray(imresize(newImg, [18 18]),[5 5],0,'both');
    if i == 1
        [prediction, score] = nnSymbol.classify(symbol);
        symbolsExtracted(numSymbols) = {char(prediction)};
    else
        [prediction, score] = nn.classify(symbol);
        symbolsExtracted(numSymbols) = {str2num(char(prediction))};
    end
    numSymbols = numSymbols + 1;
end
symbolsExtracted   