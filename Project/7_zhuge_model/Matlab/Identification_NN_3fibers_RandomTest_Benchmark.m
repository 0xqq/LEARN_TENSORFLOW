clear all;
close all;
% % construct input and output

NLpower = [];
fiberType = [];
CDprecomp = [];
spanLength = [];
powerVariation = [];
Cmatrix = [];


DataBase_Fiber = load(['ciena10000.csv']);%read the file
    
NLpower = [NLpower; DataBase_Fiber.NLpower];
fiberType = [fiberType; DataBase_Fiber.fiberType];
CDprecomp = [CDprecomp; DataBase_Fiber.fiberType];
spanLength = [spanLength; DataBase_Fiber.spanLength];
Cmatrix = [Cmatrix DataBase_Fiber.Cmatrix];
powerVariation = [powerVariation; DataBase_Fiber.powerVariation];


index = 1:length(NLpower(:,1));%get the dataset lines
%[index,~]=size(DataBase_Fiber)

C_feature = zeros(index(end),3100);


NLpower = NLpower(index,:);
fiberType = fiberType(index,:);
CDprecomp = CDprecomp(index,:);
spanLength = spanLength(index,:);
powerVariation = powerVariation(index,:);


for i = index
    
    aaa = squeeze(Cmatrix{i}(1:1:20,:,:));
    C_feature(i,:) = [aaa(:)];
    
end





%%
hiddenLayerSize = [50 40 30];

C_Input = [real(C_feature) imag(C_feature)];

[CoefPCA,~,~,~,EXPLAINED] = pca(C_Input(1:10000,:));

C_Input_PCA = C_Input*CoefPCA(:,1:200);

NN_Input = [C_Input_PCA.';CDprecomp(:,end).';spanLength.';powerVariation.';];
%         NN_Output = [fiberType(aa,iSpan).'];

   %%
   
for iSpan = 10:10
    
    NN_Output = [fiberType(:,iSpan).'];
    
 
    
    % Solve an Input-Output Fitting problem with a Neural Network
    % Script generated by Neural Fitting app
    % Created Wed Aug 10 14:26:08 EDT 2016
    %
    % This script assumes these variables are defined:
    %
    %   b - input data.
    %   c - target data.
    
    x = NN_Input;
    t = NN_Output;
    
    % Choose a Training Function
    % For a list of all training functions type: help nntrain
    % 'trainlm' is usually fastest.
    % 'trainbr' takes longer but may be better for challenging problems.
    % 'trainscg' uses less memory. NFTOOL falls back to this in low memory situations.
    trainFcn = 'trainscg';  % Bayesian Regularization
    
    % Create a Fitting Network
    %         hiddenLayerSize = hiddenLayerSize_mat(iLayerSize);
    net = fitnet(hiddenLayerSize,trainFcn);
    
    % Choose Input and Output Pre/Post-Processing Functions
    % For a list of all processing functions type: help nnprocess
    net.input.processFcns = {'removeconstantrows','mapminmax'};
    net.output.processFcns = {'removeconstantrows','mapminmax'};
    
    % Setup Division of Data for Training, Validation, Testing
    % For a list of all data division functions type: help nndivide
    net.divideFcn = 'dividerand';  % Divide data randomly
    net.divideMode = 'sample';  % Divide up every sample
    net.divideParam.trainRatio = 85/100;
    net.divideParam.valRatio = 0/100;
    net.divideParam.testRatio = 15/100;
    
    % Choose a Performance Function
    % For a list of all performance functions type: help nnperformance
    net.performFcn = 'mse';  % Mean squared error
    
    % Choose Plot Functions
    % For a list of all plot functions type: help nnplot
    net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
        'plotregression', 'plotfit'};
    
    % Train the Network
    net.trainParam.min_grad = 1e-6;
    net.trainParam.epochs = 10000;
    net.trainParam.max_fail = 20;
    [net,tr] = train(net,x,t,'useGPU','yes','showResources','yes');
    
    
    % Test the Network
    y = net(x);
    e = gsubtract(t,y);
    performance = perform(net,t,y)
    
    % Recalculate Training, Validation and Test Performance
    trainTargets = t .* tr.trainMask{1};
    valTargets = t  .* tr.valMask{1};
    testTargets = t  .* tr.testMask{1};
    trainPerformance = perform(net,trainTargets,y)
    valPerformance = perform(net,valTargets,y)
    testPerformance = perform(net,testTargets,y)
    
    % View the Network
    % view(net)

    
    % Deployment
    % Change the (false) values to (true) to enable the following code blocks.
    if (false)
        % Generate MATLAB function for neural network for application deployment
        % in MATLAB scripts or with MATLAB Compiler and Builder tools, or simply
        % to examine the calculations your trained neural network performs.
        genFunction(net,'myNeuralNetworkFunction');
        y = myNeuralNetworkFunction(x);
    end
    if (false)
        % Generate a matrix-only MATLAB function for neural network code
        % generation with MATLAB Coder tools.
        genFunction(net,'myNeuralNetworkFunction','MatrixOnly','yes');
        y = myNeuralNetworkFunction(x);
    end
    if (false)
        % Generate a Simulink diagram for simulation or deployment with.
        % Simulink Coder tools.
        gensim(net);
    end
    
    
    
    % results
    
    x_train = x(:,isfinite(tr.trainMask{1}));
    t_train = t(isfinite(tr.trainMask{1}));
    
    y = net(x_train);
    y = round(y);
    y(y>2) = 2;
    y(y<0) = 0;
    
    
    Training_FTER(iLayerSize, iSpan) = sum((abs(y(:)-t_train(:))>0))/length(y(:));
    Training_FTER_NDSF2ELEAF(iLayerSize, iSpan) = sum(y(t_train==0)==1)/length(t_train(t_train==0));
    Training_FTER_NDSF2TWC(iLayerSize, iSpan) = sum(y(t_train==0)==2)/length(t_train(t_train==0));
    Training_FTER_ELEAF2NDSF(iLayerSize, iSpan) = sum(y(t_train==1)==0)/length(t_train(t_train==1));
    Training_FTER_ELEAF2TWC(iLayerSize, iSpan) = sum(y(t_train==1)==2)/length(t_train(t_train==1));
    Training_FTER_TWC2NDSF(iLayerSize, iSpan) = sum(y(t_train==2)==0)/length(t_train(t_train==2));
    Training_FTER_TWC2ELEAF(iLayerSize, iSpan) = sum(y(t_train==2)==1)/length(t_train(t_train==2));
    
    fprintf('Training: %f\n',               Training_FTER(iLayerSize, iSpan))
    fprintf('Training NDSF to ELEAF: %f\n', Training_FTER_NDSF2ELEAF(iLayerSize, iSpan))
    fprintf('Training NDSF to TWC: %f\n',   Training_FTER_NDSF2TWC(iLayerSize, iSpan))
    fprintf('Training ELEAF to NDSF: %f\n', Training_FTER_ELEAF2NDSF(iLayerSize, iSpan))
    fprintf('Training ELEAF to TWC: %f\n',  Training_FTER_ELEAF2TWC(iLayerSize, iSpan))
    fprintf('Training TWC to NDSF: %f\n',   Training_FTER_TWC2NDSF(iLayerSize, iSpan))
    fprintf('Training TWC to ELEAF: %f\n',  Training_FTER_TWC2ELEAF(iLayerSize, iSpan))
    
    
    x_test = x(:,isfinite(tr.testMask{1}));
    t_test = t(isfinite(tr.testMask{1}));
    
    y = net(x_test);
    y = round(y);
    y(y>2) = 2;
    y(y<0) = 0;
    
    
    Testing_FTER(iLayerSize, iSpan) = sum((abs(y(:)-t_test(:))>0))/length(y(:));
    Testing_FTER_NDSF2ELEAF(iLayerSize, iSpan) = sum(y(t_test==0)==1)/length(t_test(t_test==0));
    Testing_FTER_NDSF2TWC(iLayerSize, iSpan) = sum(y(t_test==0)==2)/length(t_test(t_test==0));
    Testing_FTER_ELEAF2NDSF(iLayerSize, iSpan) = sum(y(t_test==1)==0)/length(t_test(t_test==1));
    Testing_FTER_ELEAF2TWC(iLayerSize, iSpan) = sum(y(t_test==1)==2)/length(t_test(t_test==1));
    Testing_FTER_TWC2NDSF(iLayerSize, iSpan) = sum(y(t_test==2)==0)/length(t_test(t_test==2));
    Testing_FTER_TWC2ELEAF(iLayerSize, iSpan) = sum(y(t_test==2)==1)/length(t_test(t_test==2));
    
    fprintf('Testing: %f\n',               Testing_FTER(iLayerSize, iSpan))
    fprintf('Testing NDSF to ELEAF: %f\n', Testing_FTER_NDSF2ELEAF(iLayerSize, iSpan))
    fprintf('Testing NDSF to TWC: %f\n',   Testing_FTER_NDSF2TWC(iLayerSize, iSpan))
    fprintf('Testing ELEAF to NDSF: %f\n', Testing_FTER_ELEAF2NDSF(iLayerSize, iSpan))
    fprintf('Testing ELEAF to TWC: %f\n',  Testing_FTER_ELEAF2TWC(iLayerSize, iSpan))
    fprintf('Testing TWC to NDSF: %f\n',   Testing_FTER_TWC2NDSF(iLayerSize, iSpan))
    fprintf('Testing TWC to ELEAF: %f\n',  Testing_FTER_TWC2ELEAF(iLayerSize, iSpan))
    

end

