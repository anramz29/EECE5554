% Runs MinMax, Magcal, and Kalman calibration on all datasets
% Add new datasets by adding rows to the 'datasets' cell array
addpath('functions');

% Configuration
expectedField = 52.0;   % Boston Earth field magnitude (uT)
algorithms    = {'MinMax', 'Magcal', 'Kalman'};

%% Dataset Definitions %%
% Format: {filepath, sensor_type, label}
% sensor_type: 'iphone' or 'vn100'
datasets = {
    'data/SLACleanMagnetometerUncalibrated.csv',    'iphone', 'iPhone Clean';
    'data/SLA7HSMagnetometerUncalibrated.csv',   'iphone', 'iPhone 7cm Hard/Soft';
    'data/SLA7HardMagnetometerUncalibrated.csv',  'iphone', 'iPhone 7cm Hard';
    'data/SLA7SoftMagnetometerUncalibrated.csv',  'iphone', 'iPhone 7cm Soft';
    'data/SLA30HSMagnetometerUncalibrated.csv','iphone', 'iPhone 30cm Hard/Soft';
    'data/SLA30HardMagnetometerUncalibrated.csv', 'iphone', 'iPhone 30cm Hard';
    'data/SLA30SoftMagnetometerUncalibrated.csv', 'iphone', 'iPhone 30cm Soft';
    'data/clearIMU.csv',     'vn100',  'VN-100 Clean';
    'data/vn7HS.csv',    'vn100',  'VN-100 7cm Hard/Soft';
    'data/vn7Hard.csv',   'vn100',  'VN-100 7cm Hard';
    'data/vn7Soft.csv',   'vn100',  'VN-100 7cm Soft';
    'data/vn30HS.csv', 'vn100',  'VN-100 30cm Hard/Soft';
    'data/vn30Hard.csv',  'vn100',  'VN-100 30cm Hard';
    'data/vn30Soft.csv',  'vn100',  'VN-100 30cm Soft';
};

nDatasets   = size(datasets, 1);
nAlgorithms = length(algorithms);

% Preallocate results
allMetrics = cell(nDatasets, nAlgorithms);

%% Runs All Algorithms On All Datasets %%
for i = 1:nDatasets

    filepath   = datasets{i,1};
    sensorType = datasets{i,2};
    label      = datasets{i,3};

    fprintf('\n========================================\n');
    fprintf('Dataset %d/%d: %s\n', i, nDatasets, label);
    fprintf('========================================\n');

    % Load data
    [magX, magY, magZ, fs] = loadSensorData(filepath, sensorType);

    % MinMax
    tic;
    mmResult    = runMinMax(magX, magY, magZ);
    tMinMax     = toc;
    mmMetrics   = computeMetrics(mmResult, expectedField);
    mmMetrics.runtime = tMinMax;
    allMetrics{i,1}   = mmMetrics;
    printResults(mmResult, mmMetrics, tMinMax);

    % Magcal
    tic;
    mcResult    = runMagcal(magX, magY, magZ);
    tMagcal     = toc;
    mcMetrics   = computeMetrics(mcResult, expectedField);
    mcMetrics.runtime = tMagcal;
    allMetrics{i,2}   = mcMetrics;
    printResults(mcResult, mcMetrics, tMagcal);

    % Kalman Filter
    fprintf('\n--- Kalman Filter Initialization ---\n');
    tic;
    kfResult    = runKalmanFilter(magX, magY, magZ);
    tKalman     = toc;
    kfMetrics   = computeMetrics(kfResult, expectedField);
    kfMetrics.runtime = tKalman;
    allMetrics{i,3}   = kfMetrics;
    printResults(kfResult, kfMetrics, tKalman);

    % --- Per-dataset cost summary ---
    fprintf('\n--- Computational Cost: %s ---\n', label);
    fprintf('MinMax:  %.4f s | Magcal: %.4f s | Kalman: %.4f s\n', ...
        tMinMax, tMagcal, tKalman);
end

%% Summary Figures %%
allLabels = datasets(:,3);
plotSummary(allMetrics, allLabels, algorithms);

fprintf('\n========================================\n');
fprintf('Analysis complete.\n');
fprintf('Datasets: %d | Algorithms: %d | Total results: %d\n', ...
    nDatasets, nAlgorithms, nDatasets*nAlgorithms);
fprintf('========================================\n');