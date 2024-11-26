
%/ Cut from SDO Analysis Toolkit

function plotNormErrorRate(obj)
arguments
    %obj STA.predict.predictionError
    obj
end

nSpikes = length(obj.errorStruct(1).x0States); 

n_HH_Tests = length(obj.errorSig_HH); 

nRows = ceil(sqrt(n_HH_Tests));
nCols = ceil(n_HH_Tests/nRows); 

figure;
tiledlayout(nRows, nCols); 
nexttile; 

for h = 1:n_HH_Tests
    y = obj.errorSig_HH{h}.bootstrap_mean/nSpikes; 

    y_err = obj.errorSig_HH{h}.bootstrap_std/nSpikes; 

    bar(y); 
    hold on; 
    errorbar(y, y_err, 'LineStyle','none'); 

    nexttile; 

end

1; 

end